## Useful links:
- Lima
    - Home project: "Linux virtual machines (on macOS, in most cases)": https://github.com/lima-vm/lima
    - FAQ: https://github.com/lima-vm/lima#faqs--troubleshooting
    - Default YAML config: https://github.com/lima-vm/lima/blob/master/pkg/limayaml/default.yaml
    - Kind config: https://github.com/afbjorklund/lima/blob/kind/examples/kind.yaml
- Colima - "Container runtimes, kubernetes on macOS (and Linux) with minimal setup.": https://github.com/abiosoft/colima

## Instructions

Install using brew lima on macos
```bash
brew install lima
```
Create next a VM on the machine using the `kind.yml` config file, or an URL
```bash
limactl start kind.yml
or
limactl start https://raw.githubusercontent.com/snowdrop/k8s-infra/main/lima/kind.yml
```

**NOTE**: You can look to the collection of the examples to install docker, fedora, k3d, podman ... - [see](https://github.com/lima-vm/lima/tree/master/examples)

## Kind created on docker VM

```bash
limactl start https://raw.githubusercontent.com/afbjorklund/lima/master/examples/docker.yaml
...
INFO[0165] READY. Run `limactl shell docker` to open the shell. 
INFO[0165] To run `docker` on the host (assumes docker-cli is installed): 
INFO[0165] $ export DOCKER_HOST=unix:///Users/cmoullia/.lima/docker/sock/docker.sock 
INFO[0165] $ docker ...    
```
- Next, configure your local docker client to access the `DOCKER_HOST` and execute the `kind-red-ingress.sh` script to deploy kind
  ```bash
  export DOCKER_HOST=unix:///Users/cmoullia/.lima/docker/sock/docker.sock
  kind-reg-ingress.sh 
  Do you want to delete the kind cluster (yes|no) - Default: no ? yes
  Which kubernetes version should we install (1.14 .. 1.22) - Default: 1.22 ? 
  What logging verbosity do you want (0..9) - A verbosity setting of 0 logs only critical events - Default: 0 ? 
  Deleting kind cluster ...
  Deleting cluster "kind" ...
  Creating a Kind cluster with Kubernetes version : v1.22.4 and logging verbosity: 0
  Creating cluster "kind" ...
  ⠈⠱ Ensuring node image (kindest/node:v1.22.4) 🖼 
  ```

## Additional commands

To stop and/or delete it
```bash
limactl stop -f kind
limactl delete kind
```

Next you can ssh to access the k8s cluster 
```bash

```


or perform the command remotely
```bash

```


