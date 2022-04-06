# Table of Contents

* [Introduction](#introduction)
* [Prerequisites](#prerequisites)
* [Provision a VM on OpenStack](#provision-a-vm-on-openstack)
   * [Delete a VM](#delete-a-vm)
   * [Connect to the new instance](#connect-to-the-new-instance)
   * [Choose an image](#choose-an-image)
   
# Introduction

This document describes the requirements and the process to execute the provisioning of a Cloud VM on Openstack.

# Prerequisites

You need to have both the `decorator` and `openstacksdk` pip packages installed.
Depending on the existing state of your machine, you might need to do:

```bash
[sudo] pip install [--upgrade] decorator
[sudo] pip install [--upgrade] openstacksdk
```

Install openstack.cloud Ansible collection.

```bash
$ ansible-galaxy collection install openstack.cloud
```

# Provision a VM on OpenStack

> **IMPORTANT** : The Ansible commands should be executed within the ansible folder !

The first thing that needs to be done is to provision a fairly large CentOS virtual machine top of the Cloud operating system OpenStack.

This can of course be done via the OpenStack UI or can be automated using our Ansible openstack playbook. For the sake of the examples, and since the VM name will be used around several steps, the `VM_NAME` env variable will store the vm name.

```bash
$ VM_NAME=vm20210221-t01
```

```bash
$ ansible-playbook playbook/openstack_vm_create_aggregate.yml -e k8s_type=masters -e k8s_version=121 -e '{"openstack": {"vm": {"network": "provider_net_shared"}}}' -e vm_name=${VM_NAME} --tags create
```

This playbook should finish with something like:

```
PLAY RECAP **********************************************************************************************************************************************************************************************************************
localhost                  : ok=68   changed=20   unreachable=0    failed=0    skipped=13   rescued=0    ignored=1   
vm20210221-t01             : ok=32   changed=20   unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   

Monday 21 February 2022  13:01:53 +0100 (0:00:05.011)       0:12:51.042 ******* 
=============================================================================== 
openstack/init_vm : Upgrade all packages ------------------------------------------------- 305.39s
openstack/vm : Create VM instance -------------------------------------------------------- 121.94s
sec/firewalld : Install firewalld --------------------------------------------------------- 47.60s
openstack/init_vm : Install packages ------------------------------------------------------ 47.22s
openstack/init_vm : Reboot instance ------------------------------------------------------- 32.76s
Refresh the inventory so the newly added host is available -------------------------------- 21.10s
sec/sshd_port : Change SELINUX settings to allow connections to the new port --------------- 9.14s
sec/motd : Config | Install custom `/etc/motd` file ---------------------------------------- 8.24s
sec/audit : Apply auditd configuration ----------------------------------------------------- 8.06s
openstack/vm : Gather information about a previously created image with same name ---------- 7.85s
Wait for connection to host ---------------------------------------------------------------- 7.02s
openstack/vm : Wait for boot --------------------------------------------------------------- 6.55s
Gathering Facts ---------------------------------------------------------------------------- 5.77s
sec/firewalld : Enable and start firewalld ------------------------------------------------- 5.53s
Gathering Facts ---------------------------------------------------------------------------- 5.08s
sec/update : Update all packages ----------------------------------------------------------- 5.01s
sec/firewalld : firewalld - Manage firewall ports ------------------------------------------ 4.96s
sec/sshd_port : Change the ssh port number ------------------------------------------------- 4.60s
sec/firewalld : firewalld - Manage firewall services --------------------------------------- 4.58s
sec/firewalld : Restart firewalld ---------------------------------------------------------- 4.51s
```

The playbook also uses the variables defined in `roles/openstack/vm/defaults/main.yml`. Those variables can also be overridden using the syntax above.

For example to override the VM flavor, network and security group, one would execute the following command:

```
ansible-playbook playbook/openstack.yml \
   -e vm_name=${VM_NAME} \
   -e type=cloude \
   -e '{"state": "present", "hostname": "somehostname", "openstack": {"timeout": "600","os_username": "username", "os_password": "password", "os_domain": "domain", "os_auth_url": "https://somehost:13000/v3", "os_project_id": "someprojectid", "vm": {"network": "some_network", "security_group": "some_security_group", "flavor": "m1.medium"}}}'`
```

## Delete a VM

To delete a VM, simply execute the `openstack_vm_remove_aggregate` playbook.

```bash
$ ansible-playbook playbook/openstack_vm_remove_aggregate.yml -e vm_name=${VM_NAME}
```

```
PLAY RECAP **********************************************************************************************************************************************************************************************************************
localhost                  : ok=17   changed=5    unreachable=0    failed=0    skipped=1    rescued=0    ignored=2   

Monday 21 February 2022  13:07:58 +0100 (0:00:02.485)       0:00:30.900 ******* 
=============================================================================== 
openstack/vm : Gather information about a previously created image named  ------------------ 8.16s
openstack/vm : Delete  --------------------------------------------------------------------- 3.91s
openstack/vm : Delete VM volume ------------------------------------------------------------ 3.41s
openstack/vm : Delete key  from server ----------------------------------------------------- 2.93s
Push changes to the pass git database ------------------------------------------------------ 2.49s
Pull pass git database --------------------------------------------------------------------- 2.16s
openstack/vm : Set pass facts from passwordstore ------------------------------------------- 1.70s
openstack/vm : Remove existing SSH key to use with instance -------------------------------- 1.55s
openstack/vm : Find admin user home folder ------------------------------------------------- 0.98s
openstack/vm : Remove the host from the known_hosts file ----------------------------------- 0.95s
openstack/vm : stat ------------------------------------------------------------------------ 0.88s
Remove passstore entries ------------------------------------------------------------------- 0.74s
Remove local ssh keys ---------------------------------------------------------------------- 0.57s
openstack/vm : include_tasks --------------------------------------------------------------- 0.14s
Validate required variables ---------------------------------------------------------------- 0.08s
openstack/vm : Print Openstack output ------------------------------------------------------ 0.07s
openstack/vm : include_tasks --------------------------------------------------------------- 0.07s
```

## Connect to the new instance

Since all the information related to the host will be managed by our ansible passwordstore roles, which also stores the ssh public and secret keys locally on the `~/.ssh` folder, to login to the newly created VM is as simple as launching the following command.

```bash
$ ssh -i ~/.ssh/id_rsa_snowdrop_openstack_${VM_NAME} `pass show openstack/${VM_NAME}/os_user | head -n 1`@`pass show openstack/${VM_NAME}/ansible_ssh_host | head -n 1` -p `pass show openstack/${VM_NAME}/ansible_ssh_port | head -n 1`
```

This should connect ot the newly created VM.

```
Last login: Thu Jan 1 00:00:00 1970 from x.x.x.x
------------------

This machine is property of RedHat.
Access is forbidden to all unauthorized person.
All activity is being monitored.

Welcome to vm20210221-t01..
```

## Choose an image

Different OS images are available on Openstack.

e.g.
* CentOS-7-x86_64-GenericCloud-released-latest
* CentOS-8-x86_64-GenericCloud-released-latest

To select a specific image use the `openstack.vm.image` variable override.

```bash
$ ansible-playbook playbook/openstack_vm_create_aggregate.yml -e k8s_type=masters -e k8s_version=121 -e '{"openstack": {"vm": {"image": "CentOS-8-x86_64-GenericCloud-released-latest", "network": "provider_net_shared"}}}' -e vm_name=${VM_NAME} --tags create
```

## Choose a flavor

| Flavor | VCPUS | RAM | Total Disks | Root Disk | Ephmeral Disk |
| --- | --- | --- | --- | --- | --- |
| m1.medium | 2 | 4 GB | 40 GB | 40 GB | 0 GB |
| ci.m1.medium | 2 | 4 GB | 40 GB | 40 GB | 0 GB |
| ci.m1.medium.large	| 4	| 4 GB | 16 GB | 16 GB | 0 GB |
| ci.m5.large | ??? | ??? | ??? | ??? | ??? |

To select a specific flavor use the `openstack.vm.flavor` variable override.

```bash
$ ansible-playbook playbook/openstack_vm_create_aggregate.yml -e k8s_type=masters -e k8s_version=121 -e '{"openstack": {"vm": {"flavor": "m1.medium", "network": "provider_net_shared"}}}' -e vm_name=${VM_NAME} --tags create
```
