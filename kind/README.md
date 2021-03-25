# How to create a Kubernetes cluster locally

## Prerequisite

- jq: https://stedolan.github.io/jq/download/
- Kind: https://github.com/kubernetes-sigs/kind/releases
- Docker desktop: https://www.docker.com/products/docker-desktop

## How to install/uninstall the cluster

The following bash script [kind-reg-ingress.sh](./kind-reg-ingress.sh) allows to :
- Create/delete a Kubernetes cluster using the latest cluster version of the one you specify, 
- Launch a local container registry using the port `5000`,
- Set up an Ingress controller to route the traffic.

**Remark**: The list of the `kind - kubernetes` images/versions to be used such as (1.14.x, 1.15.y,...) is available [here](https://registry.hub.docker.com/v1/repositories/kindest/node/tags)

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
