# How to create a Kubernetes cluster locally

The goal of this project is to simplify our life when we use kubernetes on a laptop. It currently supports the following features:
- Create/delete a K8s cluster using the latest cluster version<sup>[1](#version-note)</sup>, or the one you specify,
- Launch a local container registry exposed on port `localhost:5000`,
- Set up an Ingress controller to route the traffic.
- Provide 2 additional NodePorts (30000, 31000)

2 bash scripts have been developed supporting the installation of a docker registry according to the following options:
- [Unsecure](#unsecure) plain HTTP
- [Secured](#secured-and-tls) and HTTP/HTTPS endpoints available

## Prerequisite

- jq: https://stedolan.github.io/jq/download/
- Kind: https://github.com/kubernetes-sigs/kind/releases
- Docker desktop: https://www.docker.com/products/docker-desktop
- openssl

### Secured and TLS

Once the tools have been installed, you can download and move the script on your machine under a bin executable folder
```bash
wget https://raw.githubusercontent.com/snowdrop/k8s-infra/master/kind/kind-tls-secured-reg.sh
chmod +x ./kind-tls-secured-reg.sh
mv kind-tls-secured-reg.sh /usr/local/bin
```

Next, launch it:
```bash
$ kind-tls-secured-reg

Welcome to our
                                                                   
   _____                                  _                        
  / ____|                                | |                       
 | (___    _ __     ___   __      __   __| |  _ __    ___    _ __  
  \___ \  | '_ \   / _ \  \ \ /\ / /  / _  | |  __|  / _ \  | \ _ \ 
  ____) | | | | | | (_) |  \ V  V /  | (_| | | |    | (_) | | |_) |
 |_____/  |_| |_|  \___/    \_/\_/    \__,_| |_|     \___/  |  __/ 
                                                            | |    
                                                            |_|    
 Kind installation script

- Deploying a local secured (using htpasswd) docker registry
- Generating a selfsigned certificate (using openssl) to expose the registry as a HTTP/HTTPS endpoint
- Setting a docker network between the containers: kind and registry and alias "registry.local"
- Allowing to access the repository using as address "registry.local:5000" within a pod, from laptop or when a pod is created
- Exposing 2 additional NodePort: 30000 and 31000
- Deploying an ingress controller
- Copying the generated certificate here: /Users/cmoullia/local-registry.crt

Do you want to delete the kind cluster (y|n) - Default: y ? 
Which kubernetes version should we install (1.14 .. 1.21 (= default) .. 1.22) - Default: default ? 
What logging verbosity do you want to use with kind (0..9) - A verbosity setting of 0 logs only critical events - Default: 0 ? 
```
When the cluster is created, add to your `/etc/hosts` file a new entry to map the `localhost ip` address with the name of the registry
```
::1 
127.0.0.1 registry.local kind-registry
```
The certificate generated is available here `$HOME/local-registry.crt`

You can log on to the registry using the user `admin` and password `snowdrop`
```bash
docker login -u admin -p snowdrop registry.local:5000
```

**REMARK**: If needed by the tools such as podman, crt, crictl, ... move the file of the certificate under by example `/etc/docker/certs.d/kind-registry:5000/client.cert`

### Unsecure

To install the bash script on your laptop, execute the following commands: 
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

---
**<a name="version-note">1</a>**: The kubernetes `default version` depends on the version of the kind tool installed (e.g. 1.20.2 corresponds to kind 0.10.0).
See the release note to find such information like the list of the [supported images](https://github.com/kubernetes-sigs/kind/releases).
The list of the `kind - kubernetes` images and their version (1.14.x, 1.15.y,...) can be consulted [here](https://registry.hub.docker.com/v1/repositories/kindest/node/tags)
