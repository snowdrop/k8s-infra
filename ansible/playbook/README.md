
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


# Generate inventory

Clean existing inventory.

```bash
$ pass rm snowdrop/hetzner/h01-k8s-116 -rf 
$ rm -f ~/.ssh/id_rsa_snowdrop_hetzner_h01-k8s-116* 
$ rm ansible/inventory/host_vars/h01-k8s-116 
```

Generate a new inventory record for a machine.

```bash
$ ansible-playbook ansible/playbook/passstore_controller_inventory.yml -e vm_name=h01-k8s-116  
```

Extra variables that can be passed to the playbook:

| Env variable | Required | Default | Comments |
| --- | :---: | --- | --- |
| pass_db_name | | snowdrop | The 1st level on the pass folder |
| host_provider | | hetzner | The 2nd level on the pass folder which identifies the host provider for information purposes. |
| vm_name | x | | Name of the host in the inventory with no spaces. Could be something like `h01-k8s-116`  |
