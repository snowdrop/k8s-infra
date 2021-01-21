# Table of Contents

   * [Introduction](#introduction)
      * [Scope](#scope)
   * [Requirements](#requirements)
      * [Ansible Inventory](#ansible-inventory)
      * [Host provisioning](#host-provisioning)
      * [Host-Group Association](#host-group-association)
   * [Installation](#installation)

# Introduction

This document describes the requirements, and the process to execute to install a k8s cluster on a host. The installation will be done using Ansible.

## Scope

Describe the steps to execute to install k8s on a host.

# Requirements

First of all follow the instructions in the [Ansible Installation Guide section](../ansible/playbook/README.md#installation-guide).

## Ansible Inventory

In order to execute the installation of k8s several variables must be provided. To standardize the installation several Ansible Groups have been created for different installations.

To populate these variables, some groups, with the corresponding group variables, have been created in the [`hosts.yml`](../ansible/inventory/hosts.yml) inventory file.

The following table shows the existing groups for k8s.

| Group Type| Group Name | Description |
| --- | --- | --- |
| Components | masters | Kubernetes control plane. Includes information such as firewall ports and services to be open as well as internal subnet information. |
| Components | nodes | Kubernetes node. Similar to masters but for k8s nodes. |
| Versions | k8s_116 | Information v 1.16 specific |
| Versions | k8s_115 | Information v 1.15 specific |

Installing kubernetes requires a host to be assigned to 2 groups, identified from the previous table as *Group Type*, a k8s component and a k8s version.

## Host provisioning

Provisioning a host is done using the appropriate Ansible Playbooks. 

First create the Ansible Inventory records as indicated in the [Create a host](../ansible/playbook/README.md#create-a-host) section of the ansible playbook documentation.

In this example we create the inventory for a new vm to be provisioned in the hetzner provider.

```bash
$ ansible-playbook ansible/playbook/passstore_controller_inventory.yml -e vm_name=my-host -e pass_provider=hetzner -e k8s_type=masters -e k8s_version=115 --tags create
``` 

In the pass database we can now see the following structure.

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

This host has already been added to the `masters` and `k8s_115` groups as parte of the script.

To remove the host from the inventory...

```bash
$ ansible-playbook ansible/playbook/passstore_controller_inventory_remove.yml -e vm_name=my-host -e pass_provider=hetzner
``` 

## Host-Group Association

Once the host is in the inventory it can be associated with groups.
 
For instance, to install k8s control plane for version 1.15 in a newly created host (`my-host` in this example) we have to to add that host to the `masters` and `k8s_115` groups. 
To perform this operation use the `passstore_manage_host_groups.yml` playbook, as shown in the following example.

Add a host to the `masters` group and to the `k8s_115` group.

```bash
$ ansible-playbook ansible/playbook/passstore_manage_host_groups.yml -e operation=add -e group_name=masters -e vm_name=my-host
$ ansible-playbook ansible/playbook/passstore_manage_host_groups.yml -e operation=add -e group_name=k8s_115 -e vm_name=my-host
``` 

To remove a host from the `k8s_115` group...

```bash
$ ansible-playbook ansible/playbook/passstore_manage_host_groups.yml -e operation=remove -e group_name=k8s_115 -e vm_name=my-host
``` 

More information on how hosts are assigned to groups and actually adding and removing hosts from groups [here](../ansible/playbook/README.md#groups).

# Installation

Once the host is defined in the inventory and also provisioned, execute the k8s creation playbook.

```bash
$ ansible-playbook kubernetes/ansible/k8s.yml --limit <host_name>
```  

The `limit` option tells ansible to only execute the playbook to the hosts limited in the statement.

Example for installing a k8s server from scratch using a hetzner host.
 
```bash
$ VM_NAME=xXx \
  ; ansible-playbook hetzner/ansible/hetzner-delete-server.yml -e vm_name=${VM_NAME} -e hetzner_context_name=snowdrop \
  ; ansible-playbook ansible/playbook/passstore_controller_inventory_remove.yml -e vm_name=${VM_NAME} -e pass_provider=hetzner \
  && ansible-playbook ansible/playbook/passstore_controller_inventory.yml -e vm_name=${VM_NAME} -e pass_provider=hetzner -e k8s_type=masters -e k8s_version=115 --tags create \
  && ansible-playbook hetzner/ansible/hetzner-create-server.yml -e vm_name=${VM_NAME} -e salt_text=$( gpg --gen-random --armor 1 20) -e hetzner_context_name=snowdrop \
  && ansible-playbook ansible/playbook/sec_host.yml -e vm_name=${VM_NAME} -e provider=hetzner \
  && ansible-playbook kubernetes/ansible/k8s.yml --limit ${VM_NAME}
```

> NOTE: Both kubernetes playbooks (`k8s` and `k8s-misc`) can have it's host overriden using the `override_host` variable, e.g., `-e override_host=localhost` to launch it on the controller itself.

# Troublehsooting

## Expired k8s certificate

### Problem

- kubelet service shows connection errors. 
- The docker container running the k8s API server cannot be started

### Cause

```bash
$ docker logs xxxxxxxxxxxx
...
W0121 11:09:31.447982       1 clientconn.go:1251] grpc: addrConn.createTransport failed to connect to {127.0.0.1:2379 0  <nil>}. Err :connection error: desc = "transport: authentication handshake failed: x509: certificate has expired or is not yet valid". Reconnecting...
```

```bash
$ openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -text |grep ' Not '
```

### Solution

Renew the certificate.

Reference: https://www.ibm.com/support/knowledgecenter/SSCKRH_1.1.0/platform/t_certificate_renewal.html

```bash
$ kubeadm alpha certs renew all
```

## Cannot login using kubelet

### Problem

```bash
$ kubectl get pods
error: You must be logged in to the server (Unauthorized)
```

This might happen for instance after renewing the certificates.

### Cause

The `~/.kube/config` is not correctly updated.

### Solution

```bash
$ cd /etc/kubernetes
$ sudo kubeadm alpha kubeconfig user --org system:nodes --client-name system:node:$(hostname) > kubelet.conf
$ diff $HOME/fcik8s-old-certs/kubelet.conf /etc/kubernetes/kubelet.conf
```


