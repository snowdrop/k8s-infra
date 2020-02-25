# Installation of k8s 


Required variables:

| Variable | Rec. Location | Comments |
| --- | --- | --- |
| k8s_version | host_vars | Version of k8s to be installed |

```bash
$ ansible-playbook kubernetes/ansible/k8s.yml --limit k8s-116
```


## Steps to create a k8s cluster

The VM is created using an 

```bash
cd ansible
../hetzner/scripts/vm-k8s.sh k8s-115 cx31 centos-7 snowdrop YaV2PyLqJzssh

IP=$(hcloud server describe k8s-115 -o json | jq -r .public_net.ipv4.ip)
alias ssh-k8s-115="ssh -i ~/.ssh/id_hetzner_snowdrop root@${IP}"
export KUBECONFIG=/Users/dabou/Code/snowdrop/k8s-infra/ansible/inventory/${IP}-k8s-config.yml

ansible-playbook -i inventory/${IP}_host playbook/post_installation.yml --tags ingress
ansible-playbook -i inventory/${IP}_host playbook/post_installation.yml --tags cert_manager \
    -e isOpenshift=false
ansible-playbook -i inventory/${IP}_host playbook/post_installation.yml --tags k8s_dashboard \
    -e k8s_dashboard_version=v2.0.0-rc5 \
    -e k8s_dashboard_token_public="pubtkn" \
    -e k8s_dashboard_token_secret="verysecrettoken1"
```

## Steps to create an okd cluster

The following all-in one bash script will create a:
- Hetzner cloud vm
- Generate an inventory file 
- Deploy the okd cluster using the playbook cluster
 
```bash
cd ansible
VM=okd3-halkyon
../hetzner/scripts/vm-ocp.sh ${VM} cx31 centos-7 snowdrop complexpasswd

IP=$(hcloud server describe ${VM} -o json | jq -r .public_net.ipv4.ip)
alias ${VM}="ssh -i ~/.ssh/id_hetzner_snowdrop root@${IP}"
```
