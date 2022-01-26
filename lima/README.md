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
Create next a VM on the machine
```bash
limactl start kind.yml
or
limactl start https://raw.githubusercontent.com/snowdrop/k8s-infra/main/lima/kind.yml
```
To stop and/or delete it
```bash
limactl stop -f kind
limactl delete kind
```

Next you can ssh to access the K8s cluster 
```bash

```


or perform the command remotely
```bash

```


