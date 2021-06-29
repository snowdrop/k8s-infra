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

reg_name='kind-registry'
reg_port='5000'

read -p "Do you want to delete the kind cluster (yes|no) - Default: no ? " cluster_delete
cluster_delete=${cluster_delete:-no}
read -p "Which kubernetes version should we install (1.14 .. 1.21) - Default: 1.21 ? " version
k8s_minor_version=${version:-1.21}
read -p "What logging verbosity do you want (0..9) - A verbosity setting of 0 logs only critical events - Default: 0 ? " logging_verbosity
logging_verbosity=${logging_verbosity:-0}

kindCmd="kind -v ${logging_verbosity} create cluster"

# Kind cluster config template
kindCfg=$(cat <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
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

if [ "$cluster_delete" == "yes" ]; then
  echo "Deleting kind cluster ..."
  kind delete cluster
fi

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

echo "Creating a Kind cluster with Kubernetes version : ${k8s_version} and logging verbosity: ${logging_verbosity}"
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

# Deploy the nginx Ingress controller
# Due to ingress API change and webhook admission error: https://github.com/snowdrop/k8s-infra/issues/211
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.47.0/deploy/static/provider/cloud/deploy.yaml
