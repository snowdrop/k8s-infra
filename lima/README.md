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



