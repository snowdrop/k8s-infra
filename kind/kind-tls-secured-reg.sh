#!/bin/sh

set -o errexit

reg_name='kind-registry'
reg_server='localhost'
reg_port='5000'
reg_image_version='2.6.2'

current_dir=$(pwd)
temp_cert_dir=$(mktemp -d 2>/dev/null || mktemp -d -t 'temp_cert_dir')

. ./functions/openssl.sh

echo "==== Deleting kind cluster ..."
kind delete cluster
echo "==== Deleting kind docker network ..."
docker network rm kind || true

pushd $temp_cert_dir
echo "==== Generate a self-signed certificate and user/pwd to secure the local registry"
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

kindCfg=$(cat <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  #[plugins."io.containerd.grpc.v1.cri".registry]
  #  config_path = "/etc/containerd/certs.d"
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
    # Issue 219 due to this definition --> endpoint = ["https://localhost:${reg_port}"]
    endpoint = ["https://${reg_name}:${reg_port}"]
  [plugins."io.containerd.grpc.v1.cri".registry.configs."localhost:${reg_port}".tls]
    #insecure_skip_verify = true
    cert_file = "/etc/docker/certs.d/${reg_server}/client.crt"
    key_file  = "/etc/docker/certs.d/${reg_server}/client.key"
nodes:
- role: control-plane
  extraMounts:
    #- containerPath: /etc/containerd/certs.d/kind-registry
    #  hostPath: $(pwd)/certs/kind-registry
    - containerPath: /etc/docker/certs.d/${reg_server}
      hostPath: $(pwd)/certs/${reg_server}
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
)

#echo "==== Config cluster"
#echo $kindCfg

echo "==== Creating a Kind cluster"
echo "${kindCfg}" | kind create cluster --config=-

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

echo "==== Stopping the container registry"
docker stop ${reg_name} || true && docker rm ${reg_name} || true

echo "==== Creating a new container registry"
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
docker network connect kind "${reg_name}"

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

# Copy the client.cert to $HOME directory
echo "==== Copy the client.cert generated for the docker registry to $HOME/local-registry.crt"
cp ${certfile} $HOME/local-registry.crt

popd

# Deploy the nginx Ingress controller on k8s >= 1.19
# echo "==== Deploy the nginx Ingress controller"
# VERSION=$(curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/stable.txt)
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/$VERSION/deploy/static/provider/kind/deploy.yaml
