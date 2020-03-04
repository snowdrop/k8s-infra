
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


# Ansible Inventory

Ansible inventory manages access to hosts using Ansible.

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
  ; ansible-playbook hetzner/ansible/hetzner-delete-server.yml -e vm_name=${VM_NAME} -e hetzner_context_name=snowdrop --tag "vm_delete" \
  ; ansible-playbook ansible/playbook/clear_local_inventory_configuration.yml -e vm_name=${VM_NAME} \
  && ansible-playbook ansible/playbook/passstore_controller_inventory.yml -e vm_name=${VM_NAME} \
  && ansible-playbook hetzner/ansible/hetzner-create-server.yml -e vm_name=${VM_NAME} -e salt_text=$( gpg --gen-random --armor 1 20) -e hetzner_context_name=snowdrop \
  ; ansible-playbook ansible/playbook/sec_host.yml -e vm_name=${VM_NAME} -e provider=hetzner \
  && ansible-playbook ansible/playbook/k8s_installation.yml --limit ${VM_NAME}
```
