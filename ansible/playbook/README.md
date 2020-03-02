
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
$ pass rm snowdrop/hetzner/${VM_NAME} -rf 
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
