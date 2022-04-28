## Kubernetes Cluster API

The project [CAPI](https://cluster-api.sigs.k8s.io/) is a Kubernetes sub-project focused on providing declarative APIs and tooling to simplify provisioning, upgrading, and operating multiple Kubernetes clusters.

Started by the Kubernetes Special Interest Group (SIG) Cluster Lifecycle, the Cluster API project uses Kubernetes-style APIs and patterns to automate cluster lifecycle management for platform operators. 

The supporting infrastructure, like virtual machines, networks, load balancers, and VPCs, as well as the Kubernetes cluster configuration are all defined in the same way that application developers operate deploying and managing their workloads. 

This enables consistent and repeatable cluster deployments across a wide variety of infrastructure environments.

**NOTE**: As the Cluster API supports to create a K8s clusters against different [providers](https://cluster-api.sigs.k8s.io/reference/providers.html), this project could help us to simplify how we provision k8s on Hetzner, IBMCloud and OpenStack.

## Prerequisites

- Kind, kubectl & docker
- Install the clusterctl [client](https://cluster-api.sigs.k8s.io/user/quick-start.html#install-clusterctl) using `brew install clusterctl` or check the installation page
  to install it on linux, Windows.

## Instructions


Execute next the following instructions which have been created from the [Quick Start](https://cluster-api.sigs.k8s.io/user/quick-start.html#install-clusterctl)
```bash
kind delete cluster
docker rm -f $(docker ps -a -q)
docker network rm kind
docker system prune -a --volumes -f

cat <<EOF > extramounts.yml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraMounts:
    - hostPath: /var/run/docker.sock
      containerPath: /var/run/docker.sock
      EOF
      kind create cluster --config extramounts.yml

clusterctl init --infrastructure docker
clusterctl generate cluster toto --kubernetes-version v1.21.10 --flavor development > my-cluster.yml
kubectl apply -f my-cluster.yml

echo "Get the POD name of the CAPI - Control Manager installed to check its log"
CAPD=$(kc get po -lcontrol-plane=controller-manager -n capd-system --template '{{range .items}}{{.metadata.name}}{{end}}')
kc -n capd-system logs $CAPD

echo "Next, wait till the cluster is provisioned and that see INITIALIZED status of the kubeadmcontrolplane is TRUE"
kubectl get cluster/toto
kubectl get kubeadmcontrolplane
```

When the cluster has been provisioned, you can access it
```bash
clusterctl get kubeconfig toto > toto.cfg
kubectl --kubeconfig=toto.cfg apply -f https://docs.projectcalico.org/v3.21/manifests/calico.yaml
kubectl --kubeconfig=./toto.cfg get nodes
kubectl --kubeconfig=./toto.cfg get po -A

NAMESPACE     NAME                                               READY   STATUS    RESTARTS   AGE
kube-system   calico-kube-controllers-fd5d6b66f-cmhfh            1/1     Running   0          2m1s
kube-system   calico-node-bgj6c                                  1/1     Running   0          2m1s
kube-system   coredns-558bd4d5db-j8q2j                           1/1     Running   0          11m
kube-system   coredns-558bd4d5db-nndq9                           1/1     Running   0          11m
kube-system   etcd-toto-control-plane-5hw4v                      1/1     Running   0          11m
kube-system   kube-apiserver-toto-control-plane-5hw4v            1/1     Running   0          11m
kube-system   kube-controller-manager-toto-control-plane-5hw4v   1/1     Running   0          11m
kube-system   kube-proxy-hdb69                                   1/1     Running   0          11m
kube-system   kube-scheduler-toto-control-plane-5hw4v            1/1     Running   0          11m
```

To check the list of the providers
```bash
clusterctl config repositories
```
