# Table of Contents

   * [Introduction](#introduction)
   * [Installation guide](#installation-guide)
   * [Ansible Inventory](#ansible-inventory)
      * [Updating and retrieving the inventory](#updating-and-retrieving-the-inventory)
      * [Groups](#groups)
   * [Provision server](#provision-server)
      * [Host management in Ansible](#host-management-in-ansible)
         * [Create a host](#create-a-host)
         * [Remove a host](#remove-a-host)
         * [Import a host](#import-a-host)
      * [Create Server](#create-server)
      * [Secure host](#secure-host)
      * [Install software](#install-software)
         * [k8s](#k8s)
   * [Playbooks](#playbooks)
      * [passstore_controller_inventory](#passstore_controller_inventory)
      * [passstore_controller_inventory_remove](#passstore_controller_inventory_remove)
      * [sec_host](#sec_host)
      * [passstore_manage_host_groups](#passstore_manage_host_groups)

# Introduction

This document describes the Ansible implementation in the Snowdrop project.

When in this document it refers to the `controller` it means the machine that executes the Ansible playbooks and roles and that owns the inventory, *i.e.*, the 
machine that clones this project.

The `hosts` are the machines where the playbooks and roles are executed against. 

The exception goes to the playbooks that are executed against `localhost`. This special host is referred to the `controller`. 

# Installation guide

To install a fully functional project the following is required:

* Install Ansible version 2.8 or later
  * For more installation check the [Ansible Installation Guide](https://docs.ansible.com/ansible/latest/installation_guide/index.html)
  * Ansible uses Python, so check the Ansible [Python 3 Support](https://docs.ansible.com/ansible/latest/reference_appendices/python_3_support.html) page for more information.
* Install passwordstore
  * This project uses [pass](https://www.passwordstore.org/) to store passwords and certificates related to the project itself.
  * More information on installing pass in the Download section of the [passwordstore web page](https://www.passwordstore.org/)
* Clone the `passstore` project from GitLab.

> **NOTE**: Since passwordstore is integrated with [git](https://git-scm.com/), all changes made locally to a pass repository are automatically commited to the local git repo.
> Don't forget to `git push` and `git pull` often in order to have your local repository synchronized with other team members as well as publish to the team your changes. 

# Ansible Inventory

Ansible works against multiple systems in an infrastructure, called “hosts”, at the same time, using a list or group of lists know as inventory. 
Once the inventory is defined, you use patterns to select the hosts or groups you want Ansible to run against.

The inventory is comprised of several files and scripts based at the `k8s-infra/ansible/inventory` folder.
* `hosts.yml`: YAML file with group structure information as well as group variable assignment
* `pass_inventory.py`: Python script that dynamically builds the inventory from the `passwordstore` project for use in the Ansible Playbooks. This task is done automatically when Ansible is executed. 

For more information on the `passwordstore` project check gitlab.

More information on the Ansible Inventory and how to build it in the [Ansible User Guide](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html).

# `hosts.yml`

This file contains static information for the inventory such as:
* Group 
* Group hierarchy
* Group variables
* Host-Group assignment - although we won't use it in this project

Several files can exist in the inventory folder. 

This is a sample *hosts yaml* file. 

```yaml
all: # keys must be unique, i.e. only one 'hosts' per group
    hosts:
        host1:
        host2:
            host_var: value
    vars: # variables for group all (i.e. variables that will be inherited from all hosts) 
        group_all_var: value 
    children: # child groups. key order does not matter, indentation does
        other_group: # other_group is a child of the all group
            children: # group hierarchy can go on...
                group_x: 
                    hosts:
                        host5:
                group_y:
                    hosts:
                        host6:
            vars:
                g2_var2: value3
            hosts:
                host4:
                    ansible_host: 127.0.0.1
        last_group:
            hosts:
                host1:
            vars:
                group_last_var: value
```

More information on these documents:
* [yaml – Uses a specific YAML file as an inventory source](https://docs.ansible.com/ansible/latest/plugins/inventory/yaml.html)
* [How to build your inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html)

This system already includes a static inventory.

## Updating and retrieving the inventory

Because `passwordstore` is integrated with git, whenever a statement that changes any of the entries in the database is issued, a commit is automatically generated by pass itself.

With this in mind, whenever any statement that manages pass is executed, the corresponding `git push` must be manually issued by the user.

For information regarding retrieving the existing inventory to the local controller check [Import a host](#Import-a-host)

## Groups

Ansible hosts can be grouped into...well groups. This allows the execution of playbooks and the definition of variables in a common matter for different hosts.

Group definition is done inside the `ansible/inventory/hosts.yml` file using `yaml` format. In this file are the definitions of groups as well as the variable 
values assigned to each group. 

Host group assignment is made in `passstore` by managing entries in the `provider/host/groups` folder being each entry a group to which the host belongs. 

```text
├── provider
|   ├── host_1
│   │   ├── groups
│   │   │   ├── group_1
│   │   │   ├── group_2
│   │   │   ├── group_3
|   ├── host_2
│   │   ├── groups
│   │   │   ├── group_2
│   │   │   ├── group_3
```

For instance, we wanted to define the ports that a k8s master needs to open. This has been done in the `hosts.yml` file having the following varaible assigned to 
the `masters` group, which is also inside a group structure so other variables are inherited. 

```
firewalld_public_ports:
  - 6443/tcp
  - 10250/tcp
  - 10255/tcp
  - 8472/udp
  - 30000-32767/tcp
```

For information regarding actually managing host-group assignment check the [`passstore_manage_host_groups` section](#passstore_manage_host_groups). 

# Provision server

Provisioning a server requires several steps, each of which will be covered in this section

1. Generate Ansible Inventory records [...](#host-management-in-ansible)
1. Create Server in Cloud Provider [...](#create-server)
1. Secure Host [...](#secure-host)
1. Install Software [...](#install-software)

## Host management in Ansible

The section describes how to maintain hosts in Ansible and their use. It's execution goes against the `controller`.

### Create a host

To perform actions against a host, first the host must be added to the Ansible inventory. 

This is done using the `passstore_controller_inventory` playbook. More information on how to use this playbook in the [`passstore_controller_inventory` section](#passstore_controller_inventory).

> NOTE: ATTOW the only supported provider is `hetzner`. 

### Remove a host 

This is done using the `passstore_controller_inventory_remove` playbook. More information on how to use this playbook in the [`passstore_controller_inventory_remove` section](#passstore_controller_inventory_remove).

```bash
$ ansible-playbook ansible/playbook/passstore_controller_inventory_remove.yml -e vm_name=<vm_name> -e pass_provider=<provider>
```

> NOTE: ATTOW the only provider tested is `hetzner`. 

### Import a host

If a host has already been created it can be imported to the controller using:

```bash
$ ansible-playbook ansible/playbook/passstore_controller_inventory.yml -e vm_name=<vm_name> -e pass_provider=<provider>
```

It's the same as the previous statement but without the `create` *tag*.

## Create Server

Once the inventory is defined the server can be provisioned, if it isn't.

There should be different playbooks for each of the providers so check the corresponding provider:

* [Hetzner](../../hetzner/README-cloud.md)

Once the server is created it must be securized. More information on the next section.

## Secure host

Host securization is of utmost importance. For this reason a specific playbook and roles have been generated to perform this task.

For the execution of the securization check the [`sec_host` playbook section](#sec_host).  

## Install software

### k8s

For information on k8s playbooks and roles check [here](../../kubernetes/README.md)

# Playbooks

List, description and usage of the implemented playbooks.

## `passstore_controller_inventory`

This playbook generates the local inventory for the host.

Variables:

| Var Name | Possible Values | Default Value | Meaning |
| --- | --- | --- | --- |
| vm_name | | | Name that will be assigned to  the host | 
| pass_provider | [hetzner] | hetzner | Cloud or BereMetal provider that will host the VM |
| k8s_type | [masters,nodes] | | k8s component, see the [k8s README](../../kubernetes/README.md#ansible-inventory) |
| k8s_version | [115,116] | | k8s version to be installed, see the [k8s README](../../kubernetes/README.md#ansible-inventory) |

This playbook will create a passwordstore folder structure that will be the base for the Ansible Inventory.

An example:

```bash
$ ansible-playbook ansible/playbook/passstore_controller_inventory.yml -e vm_name=my-host -e pass_provider=hetzner -e k8s_type=masters -e k8s_version=115 --tags create
```

This execution would generate the following `pass` structure:

```
├── hetzner
|   ├── my-host
│   │   ├── ansible_ssh_port
│   │   ├── groups
│   │   │   ├── k8s_115
│   │   │   └── masters
│   │   ├── id_rsa
│   │   ├── id_rsa.pub
│   │   ├── os_password
│   │   ├── os_user
│   │   └── ssh_port
```

...and would also create the following ssh keys:

```bash
$ ls -l ~/.ssh/
-rw-------. 1 me me  3242 jan 1 00:00 id_rsa_snowdrop_hetzner_my-host
-rw-------. 1 me me   724 jan 1 00:00 id_rsa_snowdrop_hetzner_my-host.pub
```


## `passstore_controller_inventory_remove`

This playbook will remove the records and files created by the [`passstore_controller_inventory`](#passstore_controller_inventory) playbook.

```bash
$ ansible-playbook ansible/playbook/passstore_controller_inventory_remove.yml -e vm_name=my-host -e pass_provider=hetzner
```

Variables:

| Var Name | Possible Values | Default Value | Meaning |
| --- | --- | --- | --- |
| vm_name | | | Name that will be assigned to  the host | 
| pass_provider | [hetzner] | hetzner | Cloud or BereMetal provider that will host the VM |

## `sec_host`

This playbook executes several tasks regarding the security of hosts.

1. Install `firewalld` and close ports
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
1. Configures `journal` so messages will persist between reboots.
1. Install `auditd`
1. Changes default ssh port 
1. Update all packages

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

Variables:

| Var Name | Possible Values | Default Value | Meaning |
| --- | --- | --- | --- |
| vm_name | | | Name of the host that must already exist in the Ansible inventory. | 
| provider | [hetzner] |  | Cloud or BereMetal provider that hosts the VM |

## `passstore_manage_host_groups`

This playbook allows to easily add and remove hosts from a ansible group.

```bash
$ ansible-playbook ansible/playbook/passstore_manage_host_groups.yml -e operation=add -e group_name=<my_group> -e vm_name=<my_host>
```

For instance, adding a host named `n01-k115` to the `k8s_115` group would be done the following way:

```bash
$ ansible-playbook ansible/playbook/passstore_manage_host_groups.yml -e operation=add -e group_name=k8s_115 -e vm_name=n01-k115
```

To remove the host from the group just remove the entry from the group folder as following...

```bash
$ ansible-playbook ansible/playbook/passstore_manage_host_groups.yml -e operation=remove -e group_name=<my_group> -e vm_name=<my_host>
```

For instance, to undo the previous host operation:

```bash
$ ansible-playbook ansible/playbook/passstore_manage_host_groups.yml -e operation=remove -e group_name=k8s_115 -e vm_name=n01-k115
```
