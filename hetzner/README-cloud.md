# Hetzner Cloud

The following guide details how to provision a Hetzner VM using the [Hetzner Cloud APi](https://docs.hetzner.cloud/#overview) or the  [Hetzner Cloud client](https://github.com/hetznercloud/cli) that you can install using the 
following brew command `brew install hcloud`
To getting started, you must get a Token for your API as described [here](https://docs.hetzner.cloud/#overview-getting-started).

In order to create a vm and next access it, you must first import your ssh public key using this command
```bash
hcloud ssh-key create --name USER_KEY_NAME --public-key-from-file ~/.ssh/id_rsa.pub
```

## Using Ansible playbook

### Steps to create a k8s cluster

```bash
cd ansible
../hetzner/scripts/vm-k8s.sh <vm_name> <vm_flavor> <vm_os_type> <SALT_TEXT> <PASSWORD>

IP=$(hcloud server describe k8s-115 -o json | jq -r .public_net.ipv4.ip)
alias ssh-k8s-115="ssh -i ~/.ssh/id_hetzner_snowdrop root@${IP}"
export KUBECONFIG=~/k8s-infra/ansible/inventory/${IP}-k8s-config.yml

ansible-playbook -i inventory/${IP}_host playbook/post_installation.yml --tags ingress
ansible-playbook -i inventory/${IP}_host playbook/post_installation.yml --tags cert_manager \
    -e isOpenshift=false
ansible-playbook -i inventory/${IP}_host playbook/post_installation.yml --tags k8s_dashboard \
    -e k8s_dashboard_version=v2.0.0-rc5 \
    -e k8s_dashboard_token_public="<token_public>" \
    -e k8s_dashboard_token_secret="<token_secret>"
```

### Steps to create an okd cluster

The following all-in one bash script will create a:
- Hetzner cloud vm
- Generate an inventory file 
- Deploy the okd cluster using the playbook cluster
 
```bash
cd ansible
VM=okd3-halkyon
../hetzner/scripts/vm-ocp.sh ${VM} cx31 centos-7  <SALT_TEXT> <PASSWORD>

IP=$(hcloud server describe ${VM} -o json | jq -r .public_net.ipv4.ip)
alias ${VM}="ssh -i ~/.ssh/id_hetzner_snowdrop root@${IP}"
```
