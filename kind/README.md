# How to create a Kubernetes cluster locally

## Prerequisite

- jq: https://stedolan.github.io/jq/download/
- Kind: https://github.com/kubernetes-sigs/kind/releases
- Docker desktop: https://www.docker.com/products/docker-desktop

## How to install/uninstall the cluster

The following bash script [kind-reg-ingress.sh](./kind-reg-ingress.sh) allows to :
- Create/delete a Kubernetes cluster using the latest cluster version<sup>[1](#version-note)</sup>, or the one you specify, 
- Launch a local container registry using the port `5000`,
- Set up an Ingress controller to route the traffic.

**<a name="version-note">1</a>**: The kubernetes `default version` depends on the version of the kind tool installed (e.g. 1.20.2 corresponds to kind 0.10.0). See the release note to find such information like the list of the [supported images](https://github.com/kubernetes-sigs/kind/releases).
The list of the `kind - kubernetes` images and their version (1.14.x, 1.15.y,...) can be consulted [here](https://registry.hub.docker.com/v1/repositories/kindest/node/tags)

Once the tools have been installed, you can download and move the script on your machine under a bin executable folder
```bash
wget https://raw.githubusercontent.com/snowdrop/k8s-infra/master/kind/kind-reg-ingress.sh
chmod +x ./kind-reg-ingress.sh
mv kind-reg-ingress.sh /usr/local/bin
```

Next, launch it:
```bash
kind-reg-ingress.sh
```
You can accept the `defaults` proposed or change the values as proposed hereafter:
```bash
kind-reg-ingress.sh 
Do you want to delete the kind cluster (yes|no) - Default: no ? 
Which kubernetes version should we install (1.14 .. 1.20) - Default: 1.20 ? 
What logging verbosity do you want (0..9) - A verbosity setting of 0 logs only critical events - Default: 0 ? 
...
Creating a Kind cluster with Kubernetes version : v1.20. and logging verbosity: 0
```
## How to check

To verify if the ingress route is working, use the following example part of the [kind](https://kind.sigs.k8s.io/docs/user/ingress/#using-ingress) documentation
like [this page](https://kind.sigs.k8s.io/docs/user/local-registry/#using-the-registry) too to tag/push a container image to the `localhost:5000` registry
