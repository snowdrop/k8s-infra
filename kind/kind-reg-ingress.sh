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
# Dec 8th 2022:
#
# - Add a new parameter api_server_ip to configure the API IP address listening to
#
# Nov 16th 2022:
# - Adding the parameter watchIngressWithoutClass to the helm chart to avoid to have to define the ingressClassName which is mandatory
# - Support to pass arguments "./kind-reg-ingress.sh y latest 0" if we do not want to use user input
#
# Sep 15th 2022:
#  - Switched to use the images.json file containing the sha of the kindest/node images supported by kind for the different k8s distro
#  - Review the logic to use as default the latest image
# 
# Sep 14th 2022:
# - Bump version to k8s 1.25
# - Switch docker API from v1 to v2 (see https://github.com/snowdrop/k8s-infra/issues/270)
# - Use jq to get the version of the client returned by "kubectl version"
#
# July 1st 2022:
# - Test if kind, kubectl, helm are installed with needed versions
# - Change the range from 1.18 to 1.24 as this is what kind 0.14 supports
# - Bump the k8s default version to: 1.22
# - Rename yes/no to y/n
# - Use helm to install the ingress controller
#
# June 2nd: 
# - Bump version of k8s to 1.21. Check then locally that you have installed kind 0.11
# - Fix k8s_minor_version from 1.20 to 1.21
# - Add 2 external NodePort: 30000, 31000 which could be used instead using K8s Service instead of Ingress
#
# Aug 20
# - Change the URL to install nginx ingress - https://github.com/snowdrop/k8s-infra/issues/212
# - Mention v1.22. Still use as default v1.21

reg_name='kind-registry'
reg_port='5000'

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

if [[ "$1" = "y" ||  "$1" = "yes" ]]; then
  cluster_delete=$1
else
  read -p "Do you want to delete the kind cluster (y|n) - Default: no ? " cluster_delete
  cluster_delete=${cluster_delete:-n}
fi

if [[ "$2" != "" ]]; then
  version=$2
else
  read -p "Which kubernetes version should we install (1.18 .. 1.25) - Default: latest ? " version
  version=${version:-latest}
fi

if [[ "$3" != "" ]]; then
  logging_verbosity=$3
else
  read -p "What logging verbosity do you want (0..9) - A verbosity setting of 0 logs only critical events - Default: 0 ? " logging_verbosity
  logging_verbosity=${logging_verbosity:-0}
fi

if [[ "$4" != "" ]]; then
  api_server_ip=$4
else
  read -p "What should be the IP address to be used - Default: 127.0.0.1 ? " api_server_ip
  api_server_ip=${api_server_ip:-127.0.0.1}
fi

kindCmd="kind -v ${logging_verbosity} create cluster"

# Kind cluster config template
kindCfg=$(cat <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  apiServerAddress: "${api_server_ip}"
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
    endpoint = ["http://${reg_name}:${reg_port}"]
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
        authorization-mode: "AlwaysAllow"
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

if [ "$cluster_delete" == "y" ]; then
  echo "Deleting kind cluster ..."
  kind delete cluster
fi

echo "=== Get the tag version of the image to be installed for the kubernetes version: ${version} ..."
if [ ${version} == "latest" ]; then
  kindCmd+=""
else
  kind_image_sha=$(wget -q https://raw.githubusercontent.com/snowdrop/k8s-infra/main/kind/images.json -O - | \
  jq -r --arg VERSION "$version" '.[] | select(.k8s == $VERSION).sha')
  kindCmd+=" --image ${kind_image_sha}"
fi

echo "Creating a Kind cluster using kindest/node: ${version} and logging verbosity: ${logging_verbosity}"
echo "${kindCfg}" | ${kindCmd} --config=-

# Start a local Docker registry (unless it already exists)
running="$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)"
if [ "${running}" != 'true' ]; then
  docker run \
    -d --restart=always -p "${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi

# Connect the local Docker registry with the kind network
docker network connect "kind" "${reg_name}" > /dev/null 2>&1 &

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

#
# Install the ingress nginx controller using helm
# Set the Service type as: NodePort (needed for kind)
#
echo "Installing the ingress controller using Helm within the namespace: ingress"
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.hostPort.enabled=true \
  --set controller.watchIngressWithoutClass=true

echo "###############################################"
echo "To test ingress, execute the following commands:"
echo "kubectl create deployment demo --image=httpd --port=80; kubectl expose deployment demo"
echo "kubectl create ingress demo --class=nginx \\"
echo "   --rule=\"demo.<VM_IP>.nip.io/*=demo:80\""
echo "curl http://demo.<VM_IP>.nip.io"
echo "<html><body><h1>It works!</h1></body></html>"


