#!/bin/sh

set -o errexit

#
# Script creating a Kubernetes cluster using kind tool and :
# - Deploying a local secured (using htpasswd) docker registry
# - Generating a selfsigned certificate (using openssl) to expose the registry as a HTTP/HTTPS endpoint
# - Setting a docker network between the 2 containers: kind and registry and alias "registry.local"
# - Allowing to access the repository using as address "registry.local:5000" within a pod, from laptop or when a pod is created
# - Exposing 2 additional NodePort: 30000 and 31000
# - Deploying an ingress controller
# - Copying the generated certificate here: $HOME/local-registry.crt
#
# Remark: Please add to your /etc/hosts file --> "127.0.0.1 registry.local kind-registry
#
# Creation: September 30th - 2021
#
# Add hereafter changes done post creation date as backlog
#
# Feb 8th 2023:
#  - Fix issue with tmpDir
#  - Skip the execution of the command "sudo service" on macos
#  - Fix wrong default IP: 127.0.1 -> 127.0.0.1
#  - Checking the var install_ingress to install ingress controller
# Oct 19th 2022:
#  - Backport here changed done on kind-reg-ingress script
#  - Add alias k=kubectl
#  - Remove '' around EOF as var was not extrapolated
#  - Use a relative path _tmp directory

shopt -s expand_aliases
alias k='kubectl'

reg_name='kind-registry'
reg_server='localhost'
reg_port='5000'
reg_image_version='2.6.2'

if ! command -v kind &> /dev/null; then
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo "kind is not installed"
  echo "Use a package manager (i.e 'brew install kind') or visit the official site https://kind.sigs.k8s.io"
  exit 1
fi

if ! command -v kubectl &> /dev/null; then
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo "Please install kubectl 1.15 or higher"
  exit 1
fi

if ! command -v helm &> /dev/null; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "Helm could not be found. To get helm: https://helm.sh/docs/intro/install/"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi

HELM_VERSION=$(helm version 2>&1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+') || true
if [[ ${HELM_VERSION} < "v3.0.0" ]]; then
  echo "Please upgrade helm to v3.0.0 or higher"
  exit 1
fi

KUBE_CLIENT_VERSION=$(kubectl version -o json 2> /dev/null | jq -r '.clientVersion.gitVersion' | cut -d. -f2) || true
if [[ ${KUBE_CLIENT_VERSION} -lt 14 ]]; then
  echo "Please update kubectl to 1.15 or higher"
  exit 1
fi


current_dir=$(pwd)
temp_cert_dir=$(mktemp -d 2>/dev/null || mktemp -d -t '_tmpdir')

echo ""
echo "Welcome to our"
echo "                                                                   "
echo "   _____                                  _                        "
echo "  / ____|                                | |                       "
echo " | (___    _ __     ___   __      __   __| |  _ __    ___    _ __  "
echo "  \___ \  | '_ \   / _ \  \ \ /\ / /  / _  | |  __|  / _ \  | \ _ \ "
echo "  ____) | | | | | | (_) |  \ V  V /  | (_| | | |    | (_) | | |_) |"
echo " |_____/  |_| |_|  \___/    \_/\_/    \__,_| |_|     \___/  |  __/ "
echo "                                                            | |    "
echo "                                                            |_|    "
echo " Kind installation script"
echo ""
echo "- Deploying a local secured (using htpasswd) docker registry"
echo "- Generating a selfsigned certificate (using openssl) to expose the registry as a HTTP/HTTPS endpoint"
echo "- Setting a docker network between the containers: kind and registry and alias \"registry.local\""
echo "- Allowing to access the repository using as address \"registry.local:5000\" within a pod, from laptop or when a pod is created"
echo "- Exposing 2 additional NodePort: 30000 and 31000"
echo "- Deploying an ingress controller"
echo "- Copying the generated certificate here: $HOME/local-registry.crt"
echo ""

read -p "IP address of the VM running docker - Default: 127.0.0.1 ? " VM_IP
VM_IP=${VM_IP:-127.0.0.1}
read -p "Do you want to delete the kind cluster (y|n) - Default: y ? " cluster_delete
cluster_delete=${cluster_delete:-y}
read -p "Do you want install ingress nginx (y|n) - Default: y ? " install_ingress
install_ingress=${install_ingress:-y}
read -p "Which kubernetes version should we install (1.18 .. 1.25) - Default: latest ? " version
version=${version:-latest}
read -p "What logging verbosity do you want to use with kind (0..9) - A verbosity setting of 0 logs only critical events - Default: 0 ? " logging_verbosity
logging_verbosity=${logging_verbosity:-0}

kindCmd="kind -v ${logging_verbosity} create cluster"

create_openssl_cfg() {
CFG=$(cat <<EOF
[req]
distinguished_name = subject
x509_extensions    = x509_ext
prompt             = no

[subject]
C  = BE
ST = Namur
L  = Florennes
O  = Red Hat
OU = Snowdrop
CN = localhost

[x509_ext]
basicConstraints        = critical, CA:TRUE
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always, issuer:always
keyUsage                = critical, cRLSign, digitalSignature, keyCertSign
nsComment               = "OpenSSL Generated Certificate"
subjectAltName          = @alt_names

[alt_names]
DNS.1 = kind-registry
DNS.2 = localhost
DNS.3 = registry.local
DNS.4 = ${VM_IP}.sslip.io
EOF
)
echo "$CFG"
}

if [ "${cluster_delete}" == "y" ]; then
  echo "==== Deleting kind cluster ..."
  kind delete cluster

  echo "==== Stopping the container registry"
  docker stop ${reg_name} || true && docker rm ${reg_name} || true

  echo "==== Deleting the "kind" docker network ..."
  docker network rm kind || true
fi

echo "=== Get the tag version of the image to be installed for the kubernetes version: ${version} ..."
if [ ${version} == "latest" ]; then
  kindCmd+=""
else
  kind_image_sha=$(wget -q https://raw.githubusercontent.com/snowdrop/k8s-infra/main/kind/images.json -O - | \
  jq -r --arg VERSION "$version" '.[] | select(.k8s == $VERSION).sha')
  kindCmd+=" --image ${kind_image_sha}"
fi

# Generate the Self signed certificate using openssl
pushd $temp_cert_dir
mkdir -p certs/${reg_server}

echo "==== Generate the openssl config"
create_openssl_cfg > req.cnf

echo "==== Create the self signed certificate certificate and client key files"
openssl req -x509 \
  -nodes \
  -days 365 \
  -newkey rsa:4096 \
  -keyout certs/${reg_server}/client.key \
  -out certs/${reg_server}/client.crt \
  -config req.cnf \
  -sha256

# Kind configuration
kindCfg=$(cat <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.local:${reg_port}"]
    endpoint = ["https://registry.local:${reg_port}"]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."${VM_IP}.sslip.io:${reg_port}"]
    endpoint = ["https://${VM_IP}.sslip.io:${reg_port}"]
  [plugins."io.containerd.grpc.v1.cri".registry.configs."registry.local:${reg_port}".tls]
    cert_file = "/etc/docker/certs.d/${reg_server}/client.crt"
    key_file  = "/etc/docker/certs.d/${reg_server}/client.key"
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
        authorization-mode: "AlwaysAllow"
  extraMounts:
    - containerPath: /etc/docker/certs.d/${reg_server}
      hostPath: $(pwd)/certs/${reg_server}
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
    listenAddress: "0.0.0.0"
  - containerPort: 443
    hostPort: 443
    protocol: TCP
    listenAddress: "0.0.0.0"
  - containerPort: 30000
    hostPort: 30000
    protocol: tcp
  - containerPort: 31000
    hostPort: 31000
    protocol: tcp
EOF
)

#echo "==== Config cluster"
#echo $kindCfg

# The kind released version available are: https://github.com/kubernetes-sigs/kind/releases
echo "Creating a Kind cluster using as version: ${k8s_version} and logging verbosity: ${logging_verbosity}"
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

echo "==== Create the htpasswd file where user: admin and password: snowdrop"
mkdir -p auth
docker run --entrypoint htpasswd registry:2.7.0 -Bbn admin snowdrop > auth/htpasswd

echo "==== Creating a docker registry"
docker run -d \
  -p 5000:5000 \
  --restart=always \
  --name ${reg_name} \
  -v $(pwd)/auth:/auth \
  -v $(pwd)/certs/${reg_server}:/certs \
  -e REGISTRY_AUTH=htpasswd \
  -e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/client.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/client.key \
  registry:${reg_image_version}

# connect the container registry to the cluster network
# (the network may already be connected)
docker network connect kind "${reg_name}" --alias registry.local || true

# Upload the self-signed certificate to the kind container
name="${name:-"kind"}"
containers="$(kind get nodes --name="$name" 2>/dev/null)"
if [[ "$containers" == "" ]]; then
  echo "No kind nodes found for cluster \"$name\"" >&2
  exit 1
fi

CERT_DIR=/usr/local/share/ca-certificates
certfile="certs/${reg_server}/client.crt"

while IFS= read -r container; do
  echo "==== Copying ${certfile} to ${container}:${CERT_DIR}"
  docker cp "$certfile" "${container}:${CERT_DIR}"

  echo "==== Updating CA certificates in ${container}..."
  docker exec "$container" update-ca-certificates

  echo "==== Restarting containerd"
  docker exec "$container" systemctl restart containerd
done <<< "$containers"

echo "Copy the client.crt to the docker cert.d folder"
sudo mkdir -p /etc/docker/certs.d/${VM_IP}.sslip.io:5000
sudo cp $certfile /etc/docker/certs.d/${VM_IP}.sslip.io:5000/ca.crt
if [[ "$OSTYPE" != "darwin"* ]]; then
  sudo service docker restart
fi

echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "Log on to the docker registry using the address and user/password"
echo "docker login ${VM_IP}.sslip.io:5000 -u admin -p snowdrop"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"

popd

if [ "${install_ingress}" == "y" ]; then
#
# Install the ingress nginx controller using helm
# Set the Service type as: NodePort (needed for kind)
#
echo "Installing the ingress controller using Helm within the namespace: ingress"
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.hostPort.enabled=true

echo "###############################################"
echo "To test ingress, execute the following commands:"
echo "kubectl create deployment demo --image=httpd --port=80; kubectl expose deployment demo"
echo "kubectl create ingress demo --class=nginx \\"
echo "   --rule=\"demo.${VM_IP}.sslip.io/*=demo:80\""
echo "curl http://demo.${VM_IP}.sslip.io"
echo "<html><body><h1>It works!</h1></body></html>"

fi
