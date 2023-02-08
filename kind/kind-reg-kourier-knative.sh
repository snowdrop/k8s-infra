#!/bin/sh

set -o errexit

#
# Script creating a Kubernetes cluster using kind tool
# deploying a private docker registry and kourier to route the traffic
#
# Creation: March 8 Feb - 2023
#
# Add hereafter changes done post creation date as backlog
#
# Feb 8th 2023:
#
# -
#

reg_name='kind-registry'
reg_port='5000'
knative_version='1.9.0'

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
  SERVER_IP=$4
else
  read -p "What should be the IP address to be used - Default: 127.0.0.1 ? " SERVER_IP
  SERVER_IP=${SERVER_IP:-127.0.0.1}
fi

kindCmd="kind -v ${logging_verbosity} create cluster"

# Kind cluster config template
kindCfg=$(cat <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  apiServerAddress: "${SERVER_IP}"
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
  - containerPort: 31080
    hostPort: 80
    protocol: TCP
  - containerPort: 31443
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

echo "Install the required custom resources of knative"
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v${knative_version}/serving-crds.yaml

echo "Install the core components of Knative Serving"
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v${knative_version}/serving-core.yaml

echo "Install the Knative Kourier controller"
kubectl apply -f https://github.com/knative/net-kourier/releases/download/knative-v${knative_version}/kourier.yaml

echo "Configure Knative Serving to use Kourier by default"
kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'

echo "Configure the Knative domain to use: $SERVER_IP.nip.io"
KNATIVE_DOMAIN="${SERVER_IP}.nip.io"
kubectl patch configmap -n knative-serving config-domain -p "{\"data\": {\"$KNATIVE_DOMAIN\": \"\"}}"

echo "Patching the kourier service to use the nodePort 31080 and type: nodePort"
kubectl patch -n kourier-system svc kourier --type='json' -p='[{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 31080}]'
kubectl patch -n kourier-system svc kourier --type='json' -p='[{"op": "replace", "path": "/spec/ports/1/nodePort", "value": 31443}]'
kubectl patch -n kourier-system svc kourier --type='json' -p='[{"op": "replace", "path": "/spec/type", "value": "NodePort"}]'

echo "To test, execute the following commands: "
knCmd="kn service create hello \
  --image gcr.io/knative-samples/helloworld-go \
  --port 8080 \
  --env TARGET=Knative"

echo "$knCmd"

