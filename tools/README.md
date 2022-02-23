Table of Contents
=================

* [Introduction](#introduction)
* [ssh-vm](#ssh-vm)
   * [Requirements](#requirements)
   * [Usage](#usage)
   * [The passwordstore database](#the-passwordstore-database)


# Introduction

Auxiliary tools for the `k8s_infra` project.

# ssh-vm

Shell script that allows connecting to a host that's added to the passwordstore database.

## Requirements

1. pass installed on the computer (https://www.passwordstore.org/)
    * Fedora: 
    ```bash
    $ dnf install pass
    ```
    * RHEL
    ```bash
    $ yum install pass
    ```
2. team's pass database updated on the computer
    * check the project documentation

## Usage

Parameters:
1. VM_PROVIDER: Provider where the VM is deployed [hetzner,openstack]
2. VM_NAME: Name of the VM
3. PASSWORD_STORE_DIR: Folder location of the pass database
4. SSH COMMAND (optional): command to be executed on remote host. If none, the ssh connection is returned to the user.

Connect to a remote host.

```bash
k8s_infra] $ ./tooling/passstore-vm-ssh.sh hetzner h01-116 ~/github/snowdrop/pass/
```

As output the script will print the `ssh` command to be executed and also launch it. For instance, 
the output of the previous command would be something like the following.

```bash
### SSH COMMAND: ssh -i /home/johndoe/.ssh/id_rsa_snowdrop_hetzner_h01-116 loginuser@xxx.xxx.xxx.xxx -p 22
[loginuser@h01-116 ~]
```

Execute a command on the remote host.

```bash
k8s_infra] $ ./tooling/passstore-vm-ssh.sh hetzner h01-116 ~/github/snowdrop/pass/ ls
```

As output the script will print the `ssh` command to be executed and also launch it. For instance, 
the output of the previous command would be something like the following.

```bash
### SSH COMMAND: ssh -i /home/johndoe/.ssh/id_rsa_snowdrop_hetzner_h01-116 loginuser@xxx.xxx.xxx.xxx -p 22 ls
Documents
```

## The passwordstore database

The script gathers from the passwordstore database the following information for using on the connection.

* rsa secret key (id_rsa)
* host IP (ansible_ssh_host)
* ssh port (ansible_ssh_port)
* os user (os_user)

The RSA Secret Key contents are used to generate the ssh identity file at `~/.ssh/`, if that file doesn't already exist.
