# Instructions to install OpenShift 

This project details how to provision a vm with OpenShift Origin and to install different applications that we propose and which are required
to play with Hands On Lab, do local demo or simply to test.

List of features available 

- Persistence using `hotPath` as `persistenceVolume`
- Nexus Repository Server
- Jenkins
- Distributed Tracing - Jaeger
- [Ansible Service Broker](http://automationbroker.io/)
- [Launcher with customized catalog](fabric8-launcher)

Different provisioning modes are proposed due to some limitations that we are currently faced. By example, top of `minishift|cdk`,
we can't use Ansible Playbooks to provision post OpenShift installation our different features as the partitioning on the vm's filesystem doesn't allow to install easily packages.
Bash script, execution of manual `oc` commands will then be required.  

Table of Contents
=================

   * [Minishift](#minishift)
   * [Virtualbox](#virtualbox)
      * [MacOS's users only](#macoss-users-only)
      * [Common steps](#common-steps)
      * [Create CentOS vm on Virtualbox](#create-centos-vm-on-virtualbox)
   * [Cloud - Hetzner](#cloud---hetzner)
      * [OS Installation on Hetzner Cloud Machine](#os-installation-on-hetzner-cloud-machine)
      * [Install Fedora on Machine](#install-fedora-on-machine)
      * [Copy ssh key to machine](#copy-ssh-key-to-machine)

## Minishift

To provision MiniShift with OpenShift Origin 3.9.0 and install :

- Ansible Service Broker
- Fabric8 Launcher,
 
then use the following bash script `bootstrap_vm.sh <image_cache_boolean> <ocp_version>`. 

It will then create a `centos7` vm using `xhyve` as hypervisor

Here is a resume about what the script currently do

- Create a MiniShift `demo` profile
- Git clone `MiniShift addons` repo to install `ansible-service-broker`
- Enable/disable `MiniShift` cache (according to the `boolean` parameter)
- Install the docker images within the OpenShift registry according to the ocp version defined
- Start `MiniShift` using the experimental features

```bash
cd minishift    
./bootstrap_vm.sh true 3.9.0
```

**NOTE** : The caching option can be used in order to export on your local file system the docker images to bootsrtrap the process to recrete next time the vm.
**NOTE** : The user to use to access the vm is `admin` with the password `admin`. This user has been granted with the Openshift Cluster Admin role.
**NOTE** : When the vm has been created, then it can be stopped/started using the commands `minishift stop|start --profile demo`.

To install the Fabric8-launcher, then use this `deploy_launcher_minishift.sh` bash script. You can specify as parameters
the user/password to be used to access OpenShift like also your github user and token to play with the Launcher - `git flow`.

```bash
cd minishift 
./deploy_launcher_minishift.sh -p projectName -i username:password -g myGithubUser:myGithubToken 
```

## Virtualbox

The following section explains how you can create a customized CentOS Generic Cloud qcow2 image and repackaged it as `vmdk` file for Virtualbox.

### MacOS's users only

As MacOS users can't execute natively all the linux commands, part of the different bash scripts, then it is required to create a Linux vm on virtualbox

- Create and start a vm on virtualbox
```bash
cd virtualbox/build-centos-iso
vagrant plugin install vagrant-vbguest
vagrant plugin install sshd
vagrant up
vagrant ssh
```

- Move to the `install` directory mounted into the vm by vagrant
```bash
cd install 
```

### Common steps

In order to prepare the Centos VM for the cloud we are using the [cloud-init](http://cloudinit.readthedocs.io/en/latest) tool which is a
set of python scripts and utilities to make your cloud images be all they can be! 

This tool will be then used to add to the Cloud image that we will install on Virtualbox, your own parameters such as :

- Network configuration (NAT, vboxnet),
- User : `root`, pwd : `centos`
- Additionally add non root user, user, password, ssh authorized key, 
- yum packages, ...


Remark : Centos 7 ISO packages by default use version `0.7.9` of the `cloud-init` tool 

To prepare your CentOS image as well as the `iso` file that Virtualbox will use to bootstrap your vm, you will have to execute the following script. It will perform the following tasks :

- Add your SSH public key within the `user-data` file using as input the `user-data.tpl` file 
- Package the files `user-data` and `meta-data` within an ISO file created using `genisoimage` application
- Download the CentOS Generic Cloud image and save it under `/LOCAL/HOME/DIR/images`
- Convert the `qcow2` Centos ISO image to `vmdk` file format
- Save the vmdk image under `/LOCAL/HOME/DIR/images`

Execute this bash script to repackage the CentOS ISO image and pass as parameter your `</LOCAL/HOME/DIR>` and the name of the Generic Cloud Centos file `<QCOW2_IMAGE_NAME>` which the script downloads
from `http://cloud.centos.org/centos/7/images/`

```bash
cd virtualbox/build-centos-iso/cloud-init
./new-iso.sh </LOCAL/HOME/DIR> <QCOW2_IMAGE_NAME> <BOOLEAN_RESIZE_QCOQ_IMAGE>

e.g
./new-iso.sh /Users/dabou CentOS-7-x86_64-GenericCloud.qcow2c true
##### 1. Add ssh public key and create user-data file
##### 2. Generating ISO file containing user-data, meta-data files and used by cloud-init at bootstrap
Total translation table size: 0
Total rockridge attributes bytes: 331
Total directory bytes: 0
Path table size(bytes): 10
Max brk space used 0
183 extents written (0 MB)
#### 3. Downloading  http://cloud.centos.org/centos/7/images//CentOS-7-x86_64-GenericCloud.qcow2c ....
--2018-03-15 08:55:14--  http://cloud.centos.org/centos/7/images//CentOS-7-x86_64-GenericCloud.qcow2c
Resolving cloud.centos.org (cloud.centos.org)... 162.252.80.138
Connecting to cloud.centos.org (cloud.centos.org)|162.252.80.138|:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 394918400 (377M)
Saving to: '/Users/dabou/images/CentOS-7-x86_64-GenericCloud.qcow2c'

100%[==========================================================================================================================================================================================================>] 394,918,400 1.15MB/s   in 3m 54s 

2018-03-15 08:59:08 (1.61 MB/s) - '/Users/dabou/images/CentOS-7-x86_64-GenericCloud.qcow2c' saved [394918400/394918400]

#### Optional - Resizing qcow2 Image - +20G
Image resized.
#### 4. Converting QCOW to VMDK format
    (100.00/100%)
Done
```
The new ISO image is created locally on your machine under the directory `$HOME/images`
```bash
ls -la $HOME/images
-rw-r--r--@   1 dabou  staff         6148 Mar 15 09:06 .DS_Store
-rw-r--r--    1 dabou  staff     61675897 Mar 15 09:06 CentOS-7-x86_64-GenericCloud.qcow2c
-rw-r--r--    1 dabou  staff            0 Mar 15 09:06 centos7.vmdk
-rw-r--r--    1 dabou  staff       374784 Mar 15 09:06 vbox-config.iso
```

### Create CentOS vm on Virtualbox

To create automatically a new Virtualbox VM using the CentOS ISO image customized, the iso file including the `cloud-init` config files, then execute the
following script `create_vm.sh` on the machine running virtualbox. This script will perform the following tasks:

- Poweroff machine if it runs
- Unregister vm "$VIRTUAL_BOX_NAME" and delete it
- Rename Centos vmdk to disk.vmdk
- Create vboxnet0 network and set dhcp server : 192.168.99.50/24
- Create VM
- Define NIC adapters; NAT accessing internet and vboxnet0 to create a private network between the host and the guest
- Customize vm; ram, cpu, ...
- Create IDE Controller, attach iso dvd and vmdk disk
- Start vm and configure SSH Port forward

```bash
cd virtualbox/build-centos-iso/cloud-init 
./create-vm.sh </LOCAL/HOME/DIR>

e.g
./create-vm.sh /Users/dabou
######### Poweroff machine if it runs
VBoxManage: error: Could not find a registered machine named 'CentOS-7'
VBoxManage: error: Details: code VBOX_E_OBJECT_NOT_FOUND (0x80bb0001), component VirtualBoxWrap, interface IVirtualBox, callee nsISupports
VBoxManage: error: Context: "FindMachine(Bstr(a->argv[0]).raw(), machine.asOutParam())" at line 383 of file VBoxManageControlVM.cpp
######### .............. Done
######### unregister vm CentOS-7 and delete it
VBoxManage: error: Could not find a registered machine named 'CentOS-7'
VBoxManage: error: Details: code VBOX_E_OBJECT_NOT_FOUND (0x80bb0001), component VirtualBoxWrap, interface IVirtualBox, callee nsISupports
VBoxManage: error: Context: "FindMachine(Bstr(VMName).raw(), machine.asOutParam())" at line 153 of file VBoxManageMisc.cpp
No VM by name CentOS-7
######### Copy disk.vmdk created
######### Create vboxnet0 network and set dhcp server : 192.168.99.0/24
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Interface 'vboxnet0' was successfully created
######### Create VM
Virtual machine 'CentOS-7' is created and registered.
UUID: e5ca6778-2405-40cf-ba4b-5843f2da802a
Settings file: '/Users/dabou/VirtualBox VMs/CentOS-7/CentOS-7.vbox'
######### Define NIC adapters; NAT and vboxnet0
######### Customize vm; ram, cpu, ....
######### Create IDE Controller, attach vmdk disk and iso dvd
######### start vm and configure SSH Port forward
Waiting for VM "CentOS-7" to power on...
VM "CentOS-7" has been successfully started.
```

Remarks: As virtualbox is unable to unregister, remove the vm the first time you will execute the script, then warning messages will be displayed !

Test if you can ssh to the newly created vm using the private address `192.168.99.50`!
```bash
ssh root@192.168.99.50     
The authenticity of host '192.168.99.50 (192.168.99.50)' can't be established.
ECDSA key fingerprint is SHA256:0yyu8xv/SD++5MbRFwc1QKXXgbV1AQOQnVf1YjqQkj4.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '192.168.99.50' (ECDSA) to the list of known hosts.

[root@cloud ~]# 
```

### Experimental : Atomic Centos and Ansible

See : http://www.projectatomic.io/docs/quickstart/

- Create the vm as we did before but use this qcow file instead `CentOS-Atomic-Host-7-GenericCloud.qcow2`
- Execute these commands to resize the atomic partition, import your private key, inventory file and install the service `ose-ansible`

```bash
./create-vm.sh /Users/dabou
ssh-keygen -R "192.168.99.50"

echo "##### Resize atomic-root partition = +8G"
ssh root@192.168.99.50 "lvresize --size=+8g --resizefs atomicos/root"

echo "#### Secure copy the inventory file to the host machine"
scp /Users/dabou/Code/rhoar/cloud-native/infra/virtualbox/inventory-atomic root@192.168.99.50:/root/inventory
# scp /Users/dabou/.ssh/id_rsa root@192.168.99.50:/root/my_key.rsa

echo "#### Install ose ansible installer"
ssh root@192.168.99.50 "atomic install --system --storage=ostree --set INVENTORY_FILE=/root/inventory registry.access.redhat.com/openshift3/ose-ansible"   

echo "#### Restart service and check status"
ssh root@192.168.99.50 "systemctl start ose-ansible"
ssh root@192.168.99.50 "systemctl status ose-ansible"
ssh root@192.168.99.50 "cat /var/log/ansible.log"
```

## Cloud - Hetzner

### OS Installation on Hetzner Cloud Machine

You first need to login to Hetzner robot
at `https://robot.your-server.de/server`

### Install Fedora on Machine

* Initiate VNC connection from VNC tab
    - Select Fedora OS
    - Note the `ip address` and `password` on the console
* Reset machine
* Login to machine via a VNC client using the `ip address` and `password` for one of the previous steps
* In order to install the Fedora, space need to be reclaimed on Disk(s)
    - The only way I got this to work, was to delete the largest the partition on disk(s), while leaving the other ones intact
* Select Fedora Cloud in Software

### Copy ssh key to machine

You need to perform `ssh-copy-id root@ipaddress` in order to later perform password-less login
The root password is supplied via `email` when the Hetzner machine is initially created

