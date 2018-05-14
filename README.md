Table of Contents
=================

   * [Table of Contents](#table-of-contents)
   * [Instructions to install OpenShift and Cloud Native Features](#instructions-to-install-openshift-and-cloud-native-features)
      * [Become a Docker Machine](#become-a-docker-machine)
         * [Mac OSX](#mac-osx)
            * [Docker machine](#docker-machine)
            * [Vagrant](#vagrant)
         * [Linux](#linux)
      * [Provision OpenShift](#provision-openshift)
         * [Option 1 : Local - Minishift](#option-1--local---minishift)
         * [Option 2 : Local - Customized Linux VM](#option-2--local---customized-linux-vm)
            * [Create vdi file from Cloud ISO file](#create-vdi-file-from-cloud-iso-file)
            * [Create CentOS vm on VirtualBox](#create-vm-on-virtualbox)
         * [Option 3 : Public Cloud Provider - Hetzner](#option-3--public-cloud-provider---hetzner)
         * [Option 4 : Private Cloud Provider - Openstack](#option-4--private-cloud-provider---openstack)
         * [OpenShift Deployment](#openshift-deployment)
   * [Turn on your OpenShift machine into a Cloud Native Dev environment](#turn-on-your-openshift-machine-into-a-cloud-native-dev-environment)
      * [Bash script (minishift only)](#bash-script-minishift-only)
      * [Ansible playbooks](#ansible-playbooks)


# Instructions to install OpenShift and Cloud Native Features

This project details the prerequisites and steps necessary to convert a machine / environment into a Cloud Development Platform using using Linux Container as a foundation and OpenShift as the
orchestration and management platform of the those containers.

The documentation has been designed around the following topics 

- Become a Docker machine
- Next, to provision OpenShift and
- Finally to turn it on into a Cloud Native Developer Box !

## Become a Docker Machine

### Mac OSX

As the MacOS operating system doesn't natively support `Linux container`, it is then required to run a `Linux` vm using either `Virtualbox` or `Xhyve` as the
hypervisor which is able to manage virtual machine locally.

Various tools, approaches exist to turn your mac into a `Containerized` platform and are presented hereafter.

#### Docker machine

Docker machine is a client Tool communicating with the `Virtualbox` hypervisor and able to manage Linux VMs.
Using docker-machine commands, you can start, inspect, stop, and restart a managed host, upgrade the Docker client and daemon, and configure a Docker client to talk to your host.

- Why or when to use it ? 
  - For linux container development and testing
  - To bootstrap `OpenShift` using the `oc cluster up` command. This approach is not recommended and the [Minishift tool]() should then be used for that purpose.

- Prerequisites 
  * [Virtualbox](https://www.virtualbox.org/wiki/Downloads)

- Follow installation instructions for Docker machine at https://docs.docker.com/machine/install-machine/ or execute the following commands
  within a terminal. 
  
  **WARNING**: Change the version of the `docker-machine` according to the latest version published [here](https://github.com/docker/machine/releases/)

  ```bash
  base=https://github.com/docker/machine/releases/download/v0.14.0 &&
  curl -L $base/docker-machine-$(uname -s)-$(uname -m) >/usr/local/bin/docker-machine &&
  chmod +x /usr/local/bin/docker-machine
  ```

- Alternatively, if you prefer to install `Docker` using the docker package that you can download from [here](https://download.docker.com/mac/stable/Docker.dmg), then the following tools including docker machine
  will be also installed :
  - Docker client
  - Docker compose
  - Docker machine
  - Docker credential osxkeychain

- To verify, validate if docker machine works with Virtualbox, then execute this command to create a vm named `default` using a lightweight linux distribution - [boot2docker](https://github.com/boot2docker/boot2docker) 

  ```bash
  docker-machine create --driver virtualbox default
  ```

#### Vagrant

Vagrant is a Ruby tool for building and managing Linux virtual machine environments. It offers more flexibility than `docker machine` as you can select the Linux OS that you would like to run locally, 
can work with different hypervisors and can better automate the process to bootstrap a Linux vm, configure it and execute post installations tasks. 

- Prerequisites 
  * [Virtualbox](https://www.virtualbox.org/wiki/Downloads)
  * [Vagrant](https://releases.hashicorp.com/vagrant/2.0.4/vagrant_2.0.4_x86_64.dmg)
  
- Why or when to use it ? 
  - To select the Linux OS to be tested
  - To customize your Linux vm with your needed/requested packages
  
- How To
 
1. Configure a private network between the guest and the host

   This private network will be used between your machine and the Linux vm and will let you to ssh to it
   
   ```
   vboxmanage hostonlyif create
   vboxmanage hostonlyif ipconfig vboxnet0 --ip 192.168.99.1 --netmask 255.255.255.0
   vboxmanage dhcpserver add --ifname vboxnet0 --ip 192.168.99.20 --netmask 255.255.255.0 --lowerip 192.168.99.50 --upperip 192.168.99.50
   vboxmanage dhcpserver modify --ifname vboxnet0 --enable
   ```

2. Create a Vagrant file

  ```
  cat > Vagrantfile << 'EOF'
  Vagrant.configure(2) do |config|
    config.vm.box = "centos/7"
  
    config.vm.provider "virtualbox" do |v, override|
      v.name = "centos-7-docker"
      v.memory = 6144
      v.customize ["modifyvm", :id, "--cpus", "4"]
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    end
    
    # Add private network
    config.vm.network "private_network", ip: "192.168.99.50"
    
    # Execute post installation
    config.vm.provision :shell, path: "post-installation.sh"
  end    
  EOF
  ```
  
3. Create a bash script containing the commands to be executed to install docker and condigure it
  ```
  mkdir vagrant-centos && vagrant-centos
  
  cat > post-installation.sh << 'EOF'
  #!/bin/bash
  
  echo "Install docker, wget packages"
  sudo yum install -y git docker wget python-rhsm-certificates
  
  echo "Configure docker"
  sudo bash -c "cat > /etc/docker/daemon.json" << 'EOFILE'
    {
      "insecure-registries" : [ "172.30.0.0/16" ],
      "hosts" : [ "unix://", "tcp://0.0.0.0:2376" ]
    }
  EOFILE
  
  echo "Start and enable docker service"
  sudo groupadd docker
  sudo usermod -aG docker vagrant
  sudo systemctl enable docker
  sudo systemctl start docker
  
  sudo sysctl -w vm.max_map_count=262144
  EOF
  ```  

4. Start Vagrant VM
  ```
  vagrant plugin install ssh
  vagrant up
  ```

5. ssh to the vm
  ```
  vagrant ssh
  ```  
  
### Linux

When using a Linux operating system, it is not by necessary to use a hypervisor and `docker` can be installed directly using 
the corresponding package.

- CentOS/Fedora

1. Install Atomic docker package (if not yet done):

    ```bash
    yum install docker
    systemctl enable docker
    systemctl start docker
    ```

2. Edit the file “/etc/docker/daemon.json” to specify the IP Address and the PORT on which the server can be access from the HOST:

   ```json
   {
   "insecure-registries" : [ "172.30.0.0/16" ],
   "hosts" : [ "unix://", "tcp://0.0.0.0:2376" ]
   }
   ```

3. Define the `DOCKER_HOST` env var within the HOST machine

   ```bash
   export DOCKER_HOST=tcp://ETHERNET_IP_ADDRESS:2376
   ```

- Ubuntu

1. Follow installation instructions for Docker CE at https://docs.docker.com/install/linux/docker-ce/ubuntu/
2. Create the following file (and directories, if necessary)

   ```
   /etc/systemd/system/docker.service.d/overlay.conf
   [Service]
   ExecStart=
   ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2376 -H unix:///var/run/docker.sock --label provider=generic --insecure-registry 172.30.0.0/16
   Environment=
   ```

3. Run the following commands
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart docker
   ```

## Provision OpenShift

As different tools / bootstrapping methods are available and serve different purposes to install `OpenShift`, the following table 
summarize and present the possibilities offered:

| Option  | Cloud Provider             | Purpose                                              | Tool        | ISO                     |  Hypervisor       |
| ------: | ---------------------------| ---------------------------------------------------- | ----------- | ------------------------| :---------------: |
| 1       | Local Machine              | Local dvlpt                                          | Minishift   | CentOS or boot2docker   | Xhyve, Virtualbox |
| 2       | Local Machine              | Local dvlpt, test new oc release, validate playbooks | Ansible     | CentOS                  | Virtualbox        |
| 3       | Remote Public  - Hetzner   | Demo, Hands On Lab machine                           | Ansible     | CentOS, Fedora, RHEL    | -                 |
| 4       | Remote Private - OpenStack | Testing, Productization                              | Ansible     | CentOS, Fedora, RHEL    | -                 |

**NOTE**: 
- Aside from `option 1` where the `Minishift` tool manages the whole process to create the vm and next install the docker server, the other `options` only require a Linux VM and Docker server.
- For `option 3 and 4`, the Linux VM must be accessible using `ssh`
- The `option 2, 3 & 4` can also performed using `fedora`, `rhel` or `ubuntu` operating system but they haven't been tested and will not be presented here.

### Option 1 : Local - Minishift

`Minishift` is a tool that helps you to run `OpenShift` locally by launching a single-node `OpenShift` cluster inside a virtual machine.

- Why or when to use it ? 
  - To try out `OpenShift` or develop with it, day-to-day, on your local machine
  - `ansible playbooks` can't be use to perform post installation tasks
  - `addons` exist to install additional features but syntax is very basic

- Prerequisites
  - [Xhyve](https://docs.openshift.org/latest/minishift/getting-started/setting-up-virtualization-environment.html#setting-up-xhyve-driver) OR 
  - [Virtualbox](https://docs.openshift.org/latest/minishift/getting-started/setting-up-virtualization-environment.html#setting-up-virtualbox-driver) OR 
  - [Hyperkit](https://docs.openshift.org/latest/minishift/getting-started/setting-up-virtualization-environment.html#setting-up-hyperkit-driver) hypervisor is installed

- How To

  1. Download and [install](https://docs.openshift.org/latest/minishift/getting-started/installing.html) `Minishift` using latest release available
  
  2. Start it locally
  
     ```bash
     minishift start
     ```
 
  3. For a more complex scenario where additional features are required, then you can (re)use the following bash script - `bootstrap_vm.sh <image_cache_boolean> <ocp_version>`. 
     It will create a `centos7` vm using `xhyve` hypervisor and next execute this list of tasks
  
     - Create a MiniShift `demo` profile
     - Git clone `MiniShift addons` repo to install the `ansible-service-broker`
     - Enable/disable `MiniShift` cache (according to the `boolean` parameter)
     - Install the docker images within the OpenShift registry, according to the ocp version defined
     - Start `MiniShift` using the experimental features
     
     ```bash
     cd minishift    
     ./bootstrap_vm.sh true 3.9.0
     ```
     
     **NOTE** : The caching option can be used in order to export the docker images locally, which will speed up the bootstrap process next time you recreate the OpenShift virtual machine / installation.
     
     **NOTE** : The user to use to access the OpenShift installation is `admin` with the password `admin`. This user has been granted the OpenShift Cluster Admin role.
     
     **NOTE** : Once the virtual machine has been created, it can be stopped/started using the commands `minishift stop|start --profile demo`.

### Option 2 : Local - Customized Linux VM

While we can use Vagrant in combination with Virtualbox to install easily one of the vagrant boxes available such as `CentOS`, `Fedora`, `Ubuntu`, the iso image used (and its packaging)
doesn't necessarily fit the requirements that you need.

This is specifically true when you are interested in validating a new version of `OpenShift` using `ansible-playbooks` as the deployment tool.
The `Ansible playooks` requires some `prerequisites` in addition to having a
primary ethernet adapter, the one to be used by the OpenShift Master API (which is the Kubernetes controller, ....).

For such an environment, it makes sense to customize a Linux ISO image and to perform post-installation tasks to make it ready for your needs

The following section explains how you can create a customized Generic Cloud image, repackaged as a `vdi` file for Virtualbox.

#### Create vdi file from Cloud ISO

In order to customize the Linux VM for the cloud, we are using the [cloud-init](http://cloudinit.readthedocs.io/en/latest) tool which is a set of python scripts and utilities 
able to perform tasks as defined hereafter : 

- Configure the Network adapters (NAT, vboxnet),
- Add a `root` user and configure its password
- Additionally add non root user
- Import your public ssh key and authorize it, 
- Install `docker, ansible, networkManager` packages using yum

**Note** : Centos 7 ISO includes the `cloud-init` tool by default (version `0.7.9`). 

To create from the Centos ISO file a VirtualDisk that Virtualbox can use, you will have to execute the following bash script `./new-iso.sh`, which will perform the following tasks :

- Add your SSH public key within the `user-data` file using as input the `user-data.tpl` file 
- Package the files `user-data` and `meta-data` within an ISO file created using `genisoimage` application
- Download the CentOS Generic Cloud image and save it under `/PATH/TO/IMAGES/DIR`
- Convert the `raw` Centos ISO image to `vdi` file format
- Save the `vdi` file under `/PATH/TO/IMAGES/DIR`

**WARNING** : The following tools `virtualbox, mkisofs, wget` are required on your machine before to execute the bash script !

Execute this bash script where you pass as parameter, the directory containing the ISO, vdi files `</LOCAL/HOME/DIR>` and the name of the Generic Cloud file `<IMAGE_NAME>` to be downloaded
and next repackaged

```bash
./new-iso.sh </PATH/TO/IMAGES/DIR> <IMAGE_NAME>
```

Example:
```bash
./new-iso.sh /Users/dabou/images CentOS-7-x86_64-GenericCloud
#### 1. Add ssh public key and create user-data file
#### 2. http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.raw.tar.gz is already there
#### 3. Untar the cloud ra.tar.gz file
x CentOS-7-x86_64-GenericCloud-1802.raw
#### 4. Generating ISO file containing user-data, meta-data files and used by cloud-init at bootstrap
Total translation table size: 0
Total rockridge attributes bytes: 331
Total directory bytes: 0
Path table size(bytes): 10
Max brk space used 0
64 extents written (0 Mb)
#### 5. Converting ISO to VDI format
Converting from raw image file="/Users/dabou/images/CentOS-7-x86_64-GenericCloud-1802.raw" to file="/Users/dabou/images/centos7.vdi"...
Creating dynamic image with size 8589934592 bytes (8192MB)...
Done
```
The `vdi` file is then created on your machine under the directory passed as parameter `</PATH/TO/IMAGES/DIR>`
```bash
ls -la $HOME/images
-rw-r--r--    1 dabou  staff  8589934592 Mar  7 22:15 CentOS-7-x86_64-GenericCloud-1802.raw
-rw-r--r--@   1 dabou  staff   380383665 Mar  7 22:15 CentOS-7-x86_64-GenericCloud.raw.tar.gz
-rw-r--r--@   1 dabou  staff   648761897 Mar 15 18:07 CentOS-Atomic-Host-7-GenericCloud.qcow2.gz
-rw-------    1 dabou  staff   905969664 May  4 14:43 centos7.vdi
-rw-r--r--    1 dabou  staff      131072 May  4 14:43 vbox-config.iso
```

#### Create VM on VirtualBox

To automate the process to create a vm top of `Virtualbox`, you will then execute the following script `create_vm.sh`.

This script will perform the following tasks:

- Power off the virtual machine if it is running
- Unregister the vm `$VIRTUAL_BOX_NAME` and delete it
- Rename Centos `vdi` to `disk.vdi`
- Resize the `vdi` disk to `15GB`
- Create `vboxnet0` network and set dhcp server IP : `192.168.99.50/24`
- Create Virtual Machine
- Define NIC adapters; NAT accessing internet and `vboxnet0` to create a private network between the host and the guest
- Customize vm; ram, cpu, ...
- Create IDE Controller, attach iso dvd and vdi disk
- Start vm and configure SSH Port forward
- Create an ansible inventory file (of type `simple`) that can be used to execute the project's playbooks against the newly created vm (this is only done if Ansible is installed) 

```bash
cd virtualbox
./create-vm.sh </PATH/TO/IMAGES/DIR>
```
Example:
```bash
./create-vm.sh /Users/dabou/images 
######### Poweroff machine if it runs
VBoxManage: error: Machine 'CentOS-7' is not currently running
######### .............. Done
######### unregister vm CentOS-7 and delete it
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
######### Copy disk.vdi created
######### Create vboxnet0 network and set dhcp server : 192.168.99.0/24
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Interface 'vboxnet0' was successfully created
######### Create VM
Virtual machine 'CentOS-7' is created and registered.
UUID: ac99a6b7-0415-41b3-82ff-46f1b9dc4fec
Settings file: '/Users/dabou/VirtualBox VMs/CentOS-7/CentOS-7.vbox'
######### Define NIC adapters; NAT and vboxnet0
######### Customize vm; ram, cpu, ....
######### Resize VDI disk to 15GB
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
######### Create IDE Controller, attach vdi disk and iso dvd
######### start vm and configure SSH Port forward
Waiting for VM "CentOS-7" to power on...
VM "CentOS-7" has been successfully started.
######### Generating Ansible inventory file
 [WARNING]: Unable to parse /etc/ansible/hosts as an inventory source

 [WARNING]: No inventory was parsed, only implicit localhost is available

 [WARNING]: provided hosts list is empty, only localhost is available. Note that the implicit localhost does not match 'all'


PLAY [localhost] ********************************************************************************************************************************************************************************************************

TASK [generate_inventory : set_fact] ************************************************************************************************************************************************************************************
ok: [localhost]

TASK [generate_inventory : Create Ansible Host file] ********************************************************************************************************************************************************************
ok: [localhost]

TASK [generate_inventory : command] *************************************************************************************************************************************************************************************
changed: [localhost]

TASK [generate_inventory : Show inventory file location] ****************************************************************************************************************************************************************
ok: [localhost] => {
    "msg": "Inventory file created at : /Users/dabou/Code/snowdrop/openshift-infra/ansible/inventory/simple_host"
}

PLAY RECAP **************************************************************************************************************************************************************************************************************
localhost                  : ok=4    changed=1    unreachable=0    failed=0  
```

**Note** : VirtualBox will fail to unregister and remove the vm the first time you execute the script; warning messages will be displayed!

Test if you can ssh to the newly created vm using the private address `192.168.99.50`!
```bash
ssh root@192.168.99.50     
The authenticity of host '192.168.99.50 (192.168.99.50)' can't be established.
ECDSA key fingerprint is SHA256:0yyu8xv/SD++5MbRFwc1QKXXgbV1AQOQnVf1YjqQkj4.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '192.168.99.50' (ECDSA) to the list of known hosts.

[root@cloud ~]# 
```

- Move to `OpenShift deployment` [section](#openshift-deployment) to see how to provision the local VM.

### Option 3 : Public Cloud Provider - Hetzner

- See [hetzner](hetzner/README.md) page explaining how to create a cloud vm.
- Move to `OpenShift deployment` [section](#openshift-deployment) to see how to provision the local VM.

### Option 4 : Private Cloud Provider - Openstack

- See [OpenStack](openstack/README.md) page explaining how to create an OpenStack cloud vm.
- Move to `OpenShift deployment` [section](#openshift-deployment) hereafter to see how to provision the local VM.

### OpenShift Deployment

As the vm is now running and the docker daemon is up, you can install `OpenShift` using either one of the following approaches :

- Simple using the `oc` binary tool and the command [oc cluster up](https://github.com/openshift/origin/blob/master/docs/cluster_up_down.md) within the vm
- More elaborated using `Ansible` tool with our `cluster` [role](ansible/README-oc.md) or with the `openshift-ansible` all-in-one playbook as described [here](ansible/README-cloud.md)

# Turn on your OpenShift machine into a Cloud Native Dev environment 

Independent of the approach you choose before, you'll be able to install or configure OpenShift
to play with the Hands On Lab, run local demos, or simply test one of the following features:

- Create list of users/passwords and their corresponding project
- Grant Cluster admin role to an OpenShift user 
- Set the Master-configuration of Openshift to use `htpasswd` as its identity provider
- Enable Persistence using `hotPath` as `persistenceVolume`
- Install Nexus Repository Server
- Install Jenkins and configure it to handle `s2i` builds started within an OpenShift project
- Install Distributed Tracing - Jaeger
- Install ServiceMesh - Istio
- Deploy the [Ansible Service Broker](http://automationbroker.io/)
- Install and enable the Fabric8 [Launcher](http://fabric8-launcher)

## Bash script (minishift only)

**NOTE**: Due to some limitations we are currently facing with `minishift|cdk`, where
we can't use Ansible Playbooks to provision our different features once OpenShift is installed, we will instead use 
bash script, manual `oc` commands or `Minishift` addons to install some of the features.  

We will then use the following bash script - `deploy_launcher_minishift.sh` instead to install the `Fabric8 launcher` and play with missions / boosters.
Using this script, you will have to specify your OpenShift account user/password and also your github user and API access token ([get an access token here](https://github.com/settings/tokens)).
This will enable you to use the `git flow` when running missions / boosters, rather than downloading boosters as zip files and deploying them manually.

```bash
cd minishift 
./deploy_launcher_minishift.sh -p projectName -i username:password -g myGithubUser:myGithubToken 

E.g ./deploy_launcher_minishift.sh -p devex -g myGithubUser:myGithubToken
```

## Ansible playbooks

See [Ansible post installation](ansible/README-post-installation.md) file to provision OpenShift with one of the Cloud Development features.
 
