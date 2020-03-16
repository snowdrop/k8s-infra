# Table of Contents

   * [Installation of k8s](#installation-of-k8s)
      * [Introduction](#introduction)
      * [Scope](#scope)
   * [Requirements](#requirements)
   * [Installation](#installation)
   * [Deprecated documentation](#deprecated-documentation)
      * [Steps to create a k8s cluster](#steps-to-create-a-k8s-cluster)
      * [Steps to create an okd cluster](#steps-to-create-an-okd-cluster)


# Installation of k8s

## Introduction

This document describes the requirements and the process to execute to install k8s on a host. The installation will be done using Ansible.

## Scope

Describe the steps to execute to install k8s on a host.

# Requirements

In order to execute the installation of k8s several variables must be provided. More information on the variables [here](../ansible/roles/k8s_cluster/README.md).

To populate these variables, some groups, with the corresponding group variables, have been created. Information for each group exists in a single located at 
`ansible/inventory/group_vars`. 

The following table shows the existing groups for k8s.

| Group Name | Description |
| --- | --- |
| masters | Kubernetes masters. Includes information such as firewall ports to be open. |
| k8s_nodes | Kubernetes nodes. |
| k8s_116 | Information v 1.16 specific |
| k8s_115 | Information v 1.15 specific |

More information on actually adding and removing hosts from groups [here](../ansible/playbook/README.md#Groups).

# Installation

Once the host is defined in the inventory and also provisioned, execute the k8s creation playbook.

```bash
$ ansible-playbook ansible/playbook/k8s_installation.yml --limit <host_name>
```  

The `limit` tells ansible to only execute the playbook to the hosts limited in the statement.

Example for installing a k8s server from scratch using a hetzner host.
 
```bash
$ VM_NAME=xXx \
  ; ansible-playbook hetzner/ansible/hetzner-delete-server.yml -e vm_name=${VM_NAME} -e hetzner_context_name=snowdrop  \
  ; ansible-playbook ansible/playbook/passstore_controller_inventory_remove.yml -e vm_name=${VM_NAME} -e pass_provider=hetzner \
  && ansible-playbook ansible/playbook/passstore_controller_inventory.yml -e vm_name=${VM_NAME} -e pass_provider=hetzner --tag "create" \
  && ansible-playbook hetzner/ansible/hetzner-create-server.yml -e vm_name=${VM_NAME} -e salt_text=$( gpg --gen-random --armor 1 20) -e hetzner_context_name=snowdrop \
  && ansible-playbook ansible/playbook/sec_host.yml -e vm_name=${VM_NAME} -e provider=hetzner \
  && ansible-playbook ansible/playbook/k8s_installation.yml --limit ${VM_NAME}
```
