# Hetzner Cloud

The following guide details how to provision a Hetzner VM using the [Hetzner Cloud APi](https://docs.hetzner.cloud/#overview) or the  [Hetzner Cloud client](https://github.com/hetznercloud/cli) that you can install using the 
following brew command `brew install hcloud`.

For Linux installation, binaries are available at [releases](https://github.com/hetznercloud/cli/releases). Download `hcloud-linux-amd64.tar.gz` and extract the `hcloud` 
file into the `~/bin` directory. 

All Ansible playbooks must be launched from the root of the project, at `k8s-infra`.

## Init the hetzner context

To getting started, you must get a Token for your API as described [here](https://docs.hetzner.cloud/#overview-getting-started).

In order to create a vm and next access it, you must first import your ssh public key using this command
```bash
hcloud ssh-key create --name USER_KEY_NAME --public-key-from-file ~/.ssh/id_rsa.pub
```

Then init the hetzner context using the available `hetzner-init-context` ansible playbook.

```bash
$ ansible-playbook hetzner/ansible/hetzner-create-hcloud-server.yml
```

This playbook has the following variables.

| Variable | Required | Prompt | Meaning |
| --- | :---: | :---: | --- |
| hetzner_context_name | x | x | context name |
| hetzner_token | x | x | The token to register with Hetzner. |

Each of the Ansible prompts can be replaced by defining it's value as an extra variable of the playbook.

```bash
$ ansible-playbook hetzner/playbook/hetzner-create-hcloud-server.yml -e hetzner_context_name=mycontext -e hetzner_token=mytoken 
```

## Create the hetzner vm

The task of creating the hetzner context is also available through an Ansible playbook.

```bash
$ ansible-playbook hetzner/playbook/hetzner-create-hcloud-server.yml
```

This will present some prompts which can be replaced by environment variables. 

| Variable | Required | Default | Prompt | Meaning |
| --- | :---: | :---: | :---: | --- |
| vm_name | x | | x | Name of the VM to be created at hetzner. |
| server_type | | cx31 |  | Server type. The list can be obtained using `hcloud server-type list`. Usually cx31 |
| vm_image | | centos-7 |  | Hetzner image to be used as source (centos-7,...) | 
| salt_text | x | | x | Salt and pepper. |
| password_text | x | | x | Password of the created user. |
| hetzner_context_name | x | | x | Context name for hcloud. |
| vm_delete |  | False |  | Deletes the VM prior to creating it. |

Each of the Ansible prompts can be replaced by defining it's value as an extra variable of the playbook.

```bash
$ ansible-playbook hetzner/playbook/hetzner-create-hcloud-server.yml -e '{ "vm_name": "my-name" }' -e '{ "salt_text": "<my salt>" }' -e '{ "password_text": "<my password>" }' -e '{ "hetzner_context_name": "<context name>" }' -e '{ "vm_delete": True }' -e '{ "pass_store_dir": "/home/<my home>/.my-password-store" }'
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
    -e k8s_dashboard_token_public="siqyah" \
    -e k8s_dashboard_token_secret="tv231i6itqiems9y"
```

## Steps to create an okd cluster

The following all-in one bash script will create a:
- Hetzner cloud vm
- Generate an inventory file 
- Deploy the okd cluster using the playbook cluster
 
```bash
cd ansible
VM=okd3-halkyon
../hetzner/scripts/vm-ocp.sh ${VM} cx31 centos-7 snowdrop YaV2PyLqJzssh

IP=$(hcloud server describe ${VM} -o json | jq -r .public_net.ipv4.ip)
alias ${VM}="ssh -i ~/.ssh/id_hetzner_snowdrop root@${IP}"
```
