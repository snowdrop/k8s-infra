Table of Contents
=================

 * [Mac OSX](#mac-osx)
    * [Docker Desktop](#docker-desktop)
    * [Docker machine](#docker-machine)
    * [Vagrant](#vagrant)
 * [Linux](#linux)

## Mac OSX

As the MacOS operating system doesn't natively support `Linux container`, it is then required to run a `Linux` vm using either `Virtualbox`, `Xhyve` or `Hyperkit` as 
hypervisor.

Various tools, approaches exist to turn your mac into a `Containerized` platform and are presented hereafter.

### Docker Desktop

The new `Docker Machine` tool is available now as a `Client desktop` which can be installed as described here: https://docs.docker.com/docker-for-mac/install/
This new client replaces `docker-machine or docker tools` and uses natively `Hyperkit` which is lightweight macOS virtualization solution built on top of `Hypervisor.framework` in macOS.
Docker Desktop does not use [docker-machine](https://docs.docker.com/docker-for-mac/docker-toolbox/) to provision its VM. The Docker Engine API is exposed on a socket available to the Mac host at /var/run/docker.sock

### Docker machine

Deprecated !

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

### Vagrant

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
  
3. Create a bash script containing the commands to be executed to install docker and configure it
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
  
## Linux

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
