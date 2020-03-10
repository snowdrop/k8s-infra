
# Introduction

This document describes the Ansible implementation in the Snowdrop project.

When in this document it refers to the `controller` it means the machine that executes the Ansible playbooks and roles and that owns the inventory, *i.e.*, the 
machine that clones this project.

The `hosts` are the machines where the playbooks and roles are executed against. 

The exception goes to the playbooks that are executed against `localhost`. This special host is referred to the `controller`. 

# Ansible Inventory

Ansible inventory manages access to hosts using Ansible.

The inventory is comprised of several files and scripts based at the `k8s-infra/ansible/inventory` folder.

The inventory is built from the `passwordstore` project using the `pass_inventory.py` python script. This task is done automatically when Ansible is executed.

## Groups

Ansible hosts can be grouped into...well groups. This allows the excecution of playbooks and the definition of variables in a common matter for different hosts. 

To assign variables to a group of hosts a file must be created in the  `k8s-infra/ansible/inventory/group_vars` folder. The name of the file must be the same
as the name of the Ansible group.

So if we want to define the ports that a k8s master should have open we can create a file named `masters` for instance in the `group_vars` folder and add there
every definition required such as:

```
firewalld_public_ports:
  - 6443/tcp
  - 10250/tcp
  - 10255/tcp
  - 8472/udp
  - 30000-32767/tcp
```

The assignment of hosts to groups is done in the passwordstore by adding an entry with the name of the host to a folder with the name of the group:

```bash
$ pass generate ansible/inventory/k8s_115/n01-k115 5
```

To remove the host from the group.

```bash
$ pass rm ansible/inventory/k8s_115/h01-k115
```

# Host management in Ansible

The section describes how to maintain hosts in Ansible and their use. It's execution goes against the `controller`.

## Create a host

To create a host first the host must be added to the Ansible inventory. This is done using the following statement:

```bash
$ ansible-playbook ansible/playbook/passstore_controller_inventory.yml -e vm_name=<vm_name> -e pass_provider=<provider> --tag "create"
```

The VM name is the name that the host will have in the inventory and the provider is the cloud provider. 

> NOTE: ATTOW the only provider tested is `hetzner`. 

## Remove a Ansible 

```bash
$ ansible-playbook ansible/playbook/passstore_controller_inventory_remove.yml -e vm_name=<vm_name> -e pass_provider=<provider>
```

> NOTE: ATTOW the only provider tested is `hetzner`. 

## Import a host

If a host has already been created it can be imported to the controller using:

```bash
$ ansible-playbook ansible/playbook/passstore_controller_inventory.yml -e vm_name=<vm_name> -e pass_provider=<provider>
```

It's the same as the previous statement but without the `create` *tag*.

# Provision server

Once the inventory is defined the server can be provisioned, if it isn't.

There should be different playbooks for each of the providers so check the corresponding provider:

* [Hetzner](../../hetzner/README-cloud.md)

Once the server is created it must be securized. More information on the next section.

# sec_host

This playbook executes several tasks regarding the security of hosts.

1. Updates all packages
1. Applies `sysctl` rules as described [here](https://linoxide.com/how-tos/linux-sysctl-tuning/)
    ```yaml
    # ignore ICMP packets (ping requests)
    net.ipv4.icmp_echo_ignore_all=1
    
    # This "sanity checking" helps against spoofing attack.
    net.ipv4.conf.all.rp_filter=1
    
    # Syn Flood protection
    net.ipv4.tcp_syncookies = 1
    ```
1. Sets the welcome message with proprietary information.
1. Changes default ssh port 
1. Installs lsof

The securization is executed using:

```bash
$  ansible-playbook ansible/playbook/sec_host.yml -e vm_name=<vm_name> -e provider=<provider>
```

Take into consideration that at the end of the securization the SSH port might be different that the default 22. This can be checked using:

```bash
$ pass show <path/to_host>/ansible_ssh_port
```

...such as...

```bash
$ pass show hetzner/my_host/ansible_ssh_port
```













```bash
ansible-playbook ansible/playbook/passstore_controller_inventory.yml -e vm_name=${VM_NAME} --tag "create"
```

Clean existing inventory.

```bash
$ VM_NAME=h01-k8s-116
$ pass rm hetzner/${VM_NAME} -rf 
$ rm -f ~/.ssh/id_rsa_snowdrop_hetzner_${VM_NAME}* 
$ rm ansible/inventory/host_vars/${VM_NAME}
```

Generate a new inventory record for a machine. This playbook will either build the inventory from pass or create a new one from scratch if it doesn't exist in pass.

```bash
$ ansible-playbook ansible/playbook/passstore_controller_inventory.yml -e vm_name=${VM_NAME}
```

Extra variables that can be passed to the playbook:

| Env variable | Required | Default | Comments |
| --- | :---: | --- | --- |
| pass_db_name | | snowdrop | The 1st level on the pass folder |
| host_provider | | hetzner | The 2nd level on the pass folder which identifies the host provider for information purposes. |
| vm_name | x | | Name of the host in the inventory with no spaces. Could be something like `h01-k8s-116`  |
| vm_user |  | snowdrop | OS user |
| vm_custom_ssh_port | | 47286 | Custom SSH port to be used for connections. |

Extra tags:

| Tag | Meaning |
| --- | --- |
| vm_delete | Deletes the VM prior to creating it. |


# k8s

The kubernetes install process required that hosts are added to the corresponding group.

Existing groups:

| Group name | Meaning |
| --- | --- |
| k8s_115 | Variables for kubernetes 1.15 |
| k8s_116 | Variables for kubernetes 1.16 |
| masters | Variables for kubernetes masters, such as firewall ports to be open |
| hetzner | Identification of the pass provider name (1st level folder in the pass data structure |

Example for installing a k8s server from scratch using a hetzner host.
 
```bash
$ VM_NAME=h01-k8s-115 \
  ; ansible-playbook hetzner/ansible/hetzner-delete-server.yml -e vm_name=${VM_NAME} -e hetzner_context_name=snowdrop  \
  ; ansible-playbook ansible/playbook/passstore_controller_inventory_remove.yml -e vm_name=${VM_NAME} -e pass_provider=hetzner \
  && ansible-playbook ansible/playbook/passstore_controller_inventory.yml -e vm_name=${VM_NAME} -e pass_provider=hetzner --tag "create" \
  && ansible-playbook hetzner/ansible/hetzner-create-server.yml -e vm_name=${VM_NAME} -e salt_text=$( gpg --gen-random --armor 1 20) -e hetzner_context_name=snowdrop \
  ; ansible-playbook ansible/playbook/sec_host.yml -e vm_name=${VM_NAME} -e provider=hetzner \
  && ansible-playbook ansible/playbook/k8s_installation.yml --limit ${VM_NAME}
```
