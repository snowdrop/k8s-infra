#!/bin/sh

set -o errexit

#
# Script creating a Kubernetes cluster using kind tool
# deploying a private docker registry and ingress to route the traffic
#
# Creation: March 17th - 2021
#
# Add hereafter changes done post creation date as backlog
#
# June 2nd: 
# - Bump version of k8s to 1.21. Check then locally that you have installed kind 0.11
# - Fix k8s_minor_version from 1.20 to 1.21 
# - Add 2 external NodePort: 30000, 31000 which could be used instead using K8s Service instead of Ingress
# Aug 20
# - Change the URL to install nginx ingress - https://github.com/snowdrop/k8s-infra/issues/212
# - Mention v1.22. Still use as default v1.21
# Sep 27
# - Extend the script to secure the local registry using htpasswd
# - Add more echo commands

reg_name='kind-registry'
reg_port='5000'
reg_image_version='2.6.2'

current_dir=$(pwd)
temp_cert_dir=$(mktemp -d 2>/dev/null || mktemp -d -t 'temp_cert_dir')

read -p "Do you want to delete the kind cluster (y|n) - Default: n ? " cluster_delete
cluster_delete=${cluster_delete:-no}
read -p "Which kubernetes version should we install (1.14 .. 1.22) - Default: 1.21 ? " version
k8s_minor_version=${version:-1.21}
read -p "What logging verbosity do you want (0..9) - A verbosity setting of 0 logs only critical events - Default: 0 ? " logging_verbosity
logging_verbosity=${logging_verbosity:-0}

kindCmd="kind -v ${logging_verbosity} create cluster"

generate_certificate() {
  echo "==== Generate a self-signed certificate and user/pwd to secure the local registry"
  mkdir -p certs/localhost

  cat <<EOF > req.cnf
  [req]
  distinguished_name = req_distinguished_name
  x509_extensions = v3_req
  prompt = no
  [req_distinguished_name]
  C = BE
  ST = Namur
  L = Florennes
  O = Red Hat
  OU = Snowdrop
  CN = localhost
  [v3_req]
  keyUsage = critical, digitalSignature, keyAgreement
  extendedKeyUsage = serverAuth
  subjectAltName = @alt_names
  [alt_names]
  DNS.1 = localhost
  DNS.2 = kind-registry
  DNS.3 = localhost:5000
  DNS.4 = kind-registry:5000
EOF

  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout certs/localhost/localhost.key \
      -out certs/localhost/localhost.crt \
      -config req.cnf \
      -sha256
  echo "==== Copy the localhost.crt and key files to the dir: $current_dir"
  mkdir -p $current_dir/localhost
  cp certs/localhost/localhost.* $current_dir/localhost
}

populate_htpasswd() {
  echo "==== Create the htpasswd file where user: admin and password: snowdrop"
  mkdir auth
  docker run --entrypoint htpasswd registry:2.7.0 -Bbn admin snowdrop > auth/htpasswd
  echo "==== Copy the generated htpasswd to the dir: $current_dir"
  cp auth/htpasswd $current_dir/
}

if [ "$cluster_delete" == "y" ]; then
  echo "==== Deleting kind cluster ..."
  kind delete cluster
  echo "==== Deleting local registry ..."
  docker stop ${reg_name} || true && docker rm ${reg_name} || true
fi

pushd $temp_cert_dir

populate_htpasswd
# generate_certificate

# Start a local Docker registry (unless it already exists)
running="$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)"
if [ "${running}" != 'true' ]; then
  echo "==== Launch the container registry ps"
  docker run -d \
    -v `pwd`/auth:/auth \
    -v `pwd`/certs:/certs \
    -e REGISTRY_AUTH=htpasswd \
    -e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" \
    -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
    -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/localhost.crt \
    -e REGISTRY_HTTP_TLS_KEY=/certs/localhost.key \
    --restart=always \
    -p "${reg_port}:5000" \
    --name "${reg_name}" \
    registry:${reg_image_version}
fi

# docker run -d \
#   -v `pwd`/auth:/auth \
#   -v `pwd`/certs:/certs \
#   -e REGISTRY_AUTH=htpasswd \
#   -e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" \
#   -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
#   -e REGISTRY_HTTP_ADDR=0.0.0.0:${reg_port} \
#   -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/localhost.crt \
#   -e REGISTRY_HTTP_TLS_KEY=/certs/localhost.key \
#   --restart=always \
#   -p "${reg_port}:5000" \
#   --name "${reg_name}" \
#   registry:${reg_image_version}

echo "==== Connect the local Docker registry with the kind network"
docker network connect "kind" "${reg_name}" > /dev/null 2>&1 &

# Create a kind cluster
# - Configures containerd to use the local Docker registry
# - Enables Ingress on ports 80 and 443
if [ "$k8s_minor_version" != "default" ]; then
  patch_version=$(wget -q https://registry.hub.docker.com/v1/repositories/kindest/node/tags -O - | \
  jq -r '.[].name' | grep -E "^v${k8s_minor_version}.[0-9]+$" | \
  cut -d. -f3 | sort -rn | head -1)
  k8s_version="v${k8s_minor_version}.${patch_version}"
  kindCmd+=" --image kindest/node:${k8s_version}"
else
  k8s_version=$k8s_minor_version
fi

# Kind cluster config template
kindCfg=$(cat <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
    endpoint = ["http://${reg_name}:${reg_port}"]
  [plugins."io.containerd.grpc.v1.cri".registry.configs."localhost:${reg_port}".tls]
    cert_file = "/etc/docker/certs.d/localhost/localhost.crt"
    key_file  = "/etc/docker/certs.d/localhost/localhost.key"
nodes:
- role: control-plane
  extraMounts:
    - containerPath: /etc/docker/certs.d/localhost
      hostPath: ${current_dir}/localhost
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 30000
    hostPort: 30000
    protocol: tcp
  - containerPort: 31000
    hostPort: 31000
    protocol: tcp
EOF
)

echo "==== Creating a Kind cluster with Kubernetes version : ${k8s_version} and logging verbosity: ${logging_verbosity}"
echo "${kindCfg}" | ${kindCmd} --config=-

# Document the local registry
# https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

# Deploy the nginx Ingress controller on k8s >= 1.19
# echo "==== Deploy the nginx Ingress controller"
# VERSION=$(curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/stable.txt)
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/$VERSION/deploy/static/provider/kind/deploy.yaml

popd
