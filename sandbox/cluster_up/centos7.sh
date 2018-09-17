#!/usr/bin/env bash

#
# Command to provision a centos7 vm using virtualbox driver
# with oc cluster up
#
PUBLIC_IP=192.168.99.50
PWD=$2

docker_tar_file="./okd-v3.10.tar"

function test () {
    echo "Hello $1"
}

function create_vm {
  echo "=================="
  echo "Reset ssh key"
  echo "=================="
  ssh-keygen -R $PUBLIC_IP

  echo "===================="
  echo "Create Virtualbox VM"
  echo "===================="
  ./virtualbox/create-vm.sh -i ~/images -m 5000 -n okd-3.10

  echo "==================================================================================================="
  echo "Sleep till the VM is ready as packages are currently installed by cloud init process -> yum install"
    echo "================================================================================================="
  for i in {1..25}
  do
    echo "Waiting $i of 25"
    sleep 6s
  done
}

function install_guest {
  echo "============================================="
  echo " Install and build Guest Virtualbox Addition "
  echo "============================================="

  echo "### Upgrading Centos"
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP  "sudo yum -y update"

  echo "### Rebooting the VM to use the new kernel updated otherwise the headers version will not match the kernel version"
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP 'sudo shutdown -r now'
  sleep 5
  echo "### Waiting for machine to reboot ..."
  ping_cancelled=false                                          # Keep track of whether the loop was cancelled, or succeeded
  while ! ping -c1 $PUBLIC_IP &>/dev/null; do sleep 5; done &   # The "&" backgrounds it
  trap "kill $!; ping_cancelled =true" SIGINT
  wait $!                                                       # Wait for the loop to exit, one way or another
  trap - SIGINT                                                 # Remove the trap, now we're done with it

  echo "### Installing deps needed to compile vboxguest addon..."
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP 'bash -s' < sandbox/cluster_up/install_deps.sh

  echo "### Done pinging"
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP 'bash -s' < sandbox/cluster_up/guest_addition.sh
}

function pull_save_images () {
  echo "============================================="
  echo " Pull images                                "
  echo "============================================="
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP 'bash -s' < sandbox/cluster_up/docker_pull_images.sh

  echo "============================================="
  echo " Backup images : $docker_tar_file                   "
  echo "============================================="
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP 'bash -s' < sandbox/cluster_up/docker_save_images.sh $docker_tar_file
}

function cluster_up {
  echo "============================================="
  echo " oc cluster up                               "
  echo "============================================="
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP 'bash -s' < sandbox/cluster_up/up.sh
}

function load_images {
  echo "============================================="
  echo " Load docker images for origin 3.10          "
  echo "============================================="
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP "docker load -i /media/sf_shared/origin-v3.10.tar"
}

function install_catalog {
  echo "============================================="
  echo " oc cluster up                               "
  echo "============================================="
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP "oc cluster add --base-dir=/var/lib/origin/openshift.local.clusterup service-catalog"
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP "oc cluster add --base-dir=/var/lib/origin/openshift.local.clusterup automation-service-broker"
}

if [ "$1" == "all" ]; then
  create_vm
  pull_save_images
  cluster_up
fi

if [ "$1" == "cluster_only" ]; then
  load_images
  cluster_up
fi

if [ "$1" == "create_vm" ]; then
  create_vm
fi

if [ "$1" == "pull_save_images" ]; then
  pull_save_images
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP "sshpass -p $PWD scp -o StrictHostKeyChecking=no ./origin-v3.10.tar dabou@192.168.99.1:/Users/dabou/Temp"
fi

if [ "$1" == "load_images" ]; then
  load_images
fi

if [ "$1" == "cluster_up" ]; then
  cluster_up
fi

if [ "$1" == "install_catalog" ]; then
  install_catalog
fi


if [ "$1" == "install_deps" ]; then
  install_deps
fi

if [ "$1" == "install_guest" ]; then
  install_guest
fi

if [ "$1" == "test" ]; then
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP 'bash -s' < sandbox/cluster_up/docker_save_images.sh $docker_tar_file
fi


