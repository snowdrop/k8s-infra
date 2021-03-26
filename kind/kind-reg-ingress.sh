#!/bin/sh

set -o errexit

#
# Script creating a Kubernetes cluster using kind tool
# deploying a private docker registry and ingress to route the traffic
#
# Creation: March 17th - 2021
# Add hereafter changes done post creation date as a backlog
#

reg_name='kind-registry'
reg_port='5000'

read -p "Do you want to delete the kind cluster (yes|no) - Default: no ? " cluster_delete
cluster_delete=${cluster_delete:-no}
read -p "Which kubernetes version should we install (1.14 .. 1.20) - Default: 1.20 ? " version
k8s_minor_version=${version:-1.20}
read -p "What logging verbosity do you want (0..9) - A verbosity setting of 0 logs only critical events - Default: 0 ? " logging_verbosity
logging_verbosity=${logging_verbosity:-0}

kindCmd="kind -v ${logging_verbosity} "
containerCmd="docker exec -it kubetools "
container_name=kubetools


# Kind cluster config template
cat <<EOF > cfgFile
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
EOF

# Detect the OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
   dockerVolumeSuffix=":z"
elif [[ "$OSTYPE" == "darwin"* ]]; then
   dockerVolumeSuffix=""
fi

# Check if docker client is installed
if ! command -v docker &> /dev/null
then
    echo "docker client could not be found"
    exit
fi

echo "Delete the kubetools container if it runs"
if [ "$( docker container inspect -f '{{.State.Running}}' $container_name )" == "true" ]; then
  echo "We are deleting the '$container_name' ..."
  docker rm --force $container_name
else
  echo "'$container_name' does not exist."
fi

echo "Download the kubetools image & launch it as container"
docker run -it -d \
   --net host --name $container_name \
   -v ~/.kube:/root/.kube \
   -v /var/run/docker.sock:/var/run/docker.sock${dockerVolumeSuffix} \
   -v $(pwd)/cfgFile:/config/cfgFile${dockerVolumeSuffix} \
   quay.io/snowdrop/kubetools

if [ "$cluster_delete" == "yes" ]; then
  echo "Deleting the kind cluster ..."
  ${containerCmd} kind -v ${logging_verbosity} delete cluster
fi

# Create a kind cluster
# - Configures containerd to use the local Docker registry
# - Enables Ingress on ports 80 and 443
if [ "$k8s_minor_version" != "default" ]; then
  # See how to pipe commands here: https://gist.github.com/ElijahLynn/72cb111c7caf32a73d6f#file-pipe_to_docker_examples-L7
  fetchTags="wget -q https://registry.hub.docker.com/v1/repositories/kindest/node/tags -O - | jq -r '.[].name' | grep -E \"^v${k8s_minor_version}.[0-9]+$\" | cut -d. -f3 | sort -rn | head -1"
  patch_version=$(echo $fetchTags | docker exec --interactive kubetools /bin/bash -)
  k8s_version="v${k8s_minor_version}.${patch_version}"
  kindCmd+="create cluster --image kindest/node:${k8s_version}"
else
  k8s_version=$k8s_minor_version
fi

echo "Creating a Kind cluster with Kubernetes version : ${k8s_version} and logging verbosity: ${logging_verbosity}"
${containerCmd} ${kindCmd} --config /config/cfgFile

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
${containerCmd} kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml

# Install the Kubernetes dashboard

while [[ $(${containerCmd} kubectl get pods -n ingress-nginx -lapp.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/component=controller -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod" && sleep 5; done

cat <<EOF | docker exec --interactive kubetools sh
kubectl create ns console

helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard

helm repo update && helm uninstall k8s-dashboard -n console

helm install k8s-dashboard kubernetes-dashboard/kubernetes-dashboard \
--namespace console \
--set ingress.enabled=true

kubectl create clusterrolebinding kubernetes-dashboard \
--clusterrole=cluster-admin \
--serviceaccount=console:k8s-dashboard-kubernetes-dashboard
EOF

echo "****************************************************************************************************"
echo "Copy/paste the following token when you will log in: https://k8s-dashboard.127.0.0.1.nip.io/#/login "
echo "****************************************************************************************************"
cat <<EOF | docker exec --interactive kubetools sh
kubectl -n console get sa/k8s-dashboard-kubernetes-dashboard \
  -o=jsonpath='{.secrets[0].name}' | xargs kubectl -n console get secret \
  -o=jsonpath='{.data.token}' | base64 -d
EOF

echo ""
echo "**************************************************"
echo "Enjoy to play with your K8s cluster and dashboard"
echo "**************************************************"
