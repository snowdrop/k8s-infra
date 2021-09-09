# Table of Contents

   * [Introduction](#introduction)
      * [Scope](#scope)
   * [Requirements](#requirements)
      * [Install hcloud CLI](#install-hcloud-cli)
   * [Hetzner Cloud](#hetzner-cloud)
      * [Init the hetzner context](#init-the-hetzner-context)
   * [The inventory](#the-inventory)
   * [The VM](#the-vm)
      * [Create the hetzner vm](#create-the-hetzner-vm)
      * [Delete a hetzner server](#delete-a-hetzner-server)
   * [Next steps](#next-steps)
      * [Steps to create a k8s / okd cluster](#steps-to-create-a-k8s--okd-cluster)

# Introduction

This document describes the requirements and the process to execute the provisioning of a Cloud VM on hetzner.

## Scope

Describe the steps to install the hetzner client and provision hetzner cloud VMs.

# Requirements

First of all follow the instructions in the [Ansible Installation Guide section](../ansible/playbook/README.md#installation-guide).

Next, Install the `hcloud CLI` as covered hereafter.

## Install hcloud CLI

For more information on installing Hetzner CLI, check the [Installation section](https://github.com/hetznercloud/cli#installation).
 
In MacOS you can install using the following brew command `brew install hcloud`.

For Linux installation, binaries are available at [releases](https://github.com/hetznercloud/cli/releases). Download `hcloud-linux-amd64.tar.gz` and extract the `hcloud` 
file into the `~/bin` directory. 

That's it, the CLI is installed and ready to use.

# Hetzner Cloud

The following guide details how to provision a Hetzner VM using the [Hetzner Cloud APi](https://docs.hetzner.cloud/#overview) or the  [Hetzner Cloud client](https://github.com/hetznercloud/cli).

All Ansible playbooks must be launched from the root of the project, at `k8s-infra`.

## Init the hetzner context

To getting started, you must get a Token for your API as described [here](https://docs.hetzner.cloud/#overview-getting-started).

Then init the hetzner context using the available `hetzner-init-context` ansible playbook.

```bash
$ ansible-playbook hetzner/ansible/hetzner-init-context.yml
```

This playbook has the following variables.

| Variable | Required | Prompt | Meaning |
| --- | :---: | :---: | --- |
| hetzner_context_name | x | x | context name |
| hetzner_token | x | x | The token to register with Hetzner. |

Each of the Ansible prompts can be replaced by defining it's value as an extra variable of the playbook.

```bash
$ ansible-playbook hetzner/ansible/hetzner-init-context.yml -e hetzner_context_name=mycontext -e hetzner_token=mytoken 
```

The context can be verified reviewing the configuration file.

```bash
$ cat  ~/.config/hcloud/cli.toml

active_context = "mycontext"

[[contexts]]
  name = "mycontext"
  token = "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
```

# The inventory

Prior to launching the creation of the VMS the Ansible inventory must be in place. For this check the documentation regarding [initializing a host](../ansible/playbook/README.md#user-guide)

> NOTE: Upon installation, Ansible will use the default SSH port to apply security scripts. One of this scripts is changing the ssh port to a non default one. 
> See the corresponding [README](../ansible/playbook/README.md).

The `ansible_ssh_private_key_file` is obtained from the `passstore` using `pass get snowdrop/hetzner/<ansible_hostname>/id_rsa | tee ~/.ssh/id_rsa_snowdrop_hetzner_<ansible_hostname>`. 
It's used so Ansible can connect to the server without requiring password.  

# The VM

## Create the hetzner vm

The task of creating the hetzner context is also available through an Ansible playbook.

```bash
$ ansible-playbook hetzner/ansible/hetzner-create-server.yml
```

This will present some prompts which can be replaced by environment variables. 

| Variable | Required | Default | Prompt | Meaning |
| --- | :---: | :---: | :---: | --- |
| hetzner_context_name | x | snowdrop | | Context name for hcloud. |
| override_public_key |  | |  | Use a *local custom key* instead the default one. |
| salt_text | x | | x | Salt and pepper. |
| server_type | | cx31 |  | Server type. The list can be obtained using `hcloud server-type list`. Usually cx31 |
| vm_image | | centos-7 |  | Hetzner image to be used as source (centos-7,...) | 
| vm_name | x | | x | Name of the VM to be created at hetzner. |

Each of the Ansible prompts can be replaced by defining it's value as an extra variable of the playbook.

```bash
$ ansible-playbook hetzner/ansible/hetzner-create-server.yml -e vm_name=${VM_NAME} \
-e salt_text=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1) \
-e hetzner_context_name=snowdrop
```
**REMARK**: For mac's users, please execute the following command before `export LC_ALL=C`

Once this task is finished it's mandatory to launch server securization, see the [Next steps](#next-steps) section.

## Delete a hetzner server

Delete a hetzner server vm.

| Variable | Required | Default | Prompt | Meaning |
| --- | :---: | :---: | :---: | --- |
| hetzner_context_name | x | snowdrop | | Context name for hcloud. |
| vm_name | x | | x | Name of the VM to be deleted from hetzner. |

```bash
$ ansible-playbook hetzner/ansible/hetzner-delete-server.yml -e vm_name=my-name -e hetzner_context_name=snowdrop
```

After that, remove the pass entries for the server.

```bash
$ pass rm hetzner/my-name -rf
```

# Next steps

Once the server is created it must be secured before installing other software. For that check [this README file](../ansible/playbook/README.md).

## Steps to create a k8s / okd cluster

Check [the corresponding README file](../kubernetes/README.md). 

