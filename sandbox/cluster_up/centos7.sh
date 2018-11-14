#!/usr/bin/env bash

#
# Command to provision a centos7 vm using virtualbox driver
# with oc cluster up
#

version=${2:-3.11}
password=$3

SECONDS=0
PUBLIC_IP=192.168.99.50
docker_tar_file="./okd-v${version}.tar"
host=dabou@192.168.99.1
target_dir="/Users/dabou/images"
SCRIPT=$BASH_SOURCE
SCRIPT_PATH=$(dirname $SCRIPT)

source $SCRIPT_PATH/var.sh
images="images${version//.}"

check_process() {
  [ `pgrep -n $1` ] && return 1 || return 0
}

function check_ssh {
    status="nok"
    until [ "$status" = "ok" ]; do
      echo "VM is still starting and ssh is not available"
      sleep 5
      status=$(ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=1 root@$PUBLIC_IP echo ok 2>&1)
      echo "Status : $status"
    done
    echo "#################################"
}

function check_file_wait {
   result="true"
   until [ "$result" = "false" ]; do
     echo "Yum process is working, we wait before to continue : ..."
     sleep 5
     result=$(ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP test -f /var/run/yum.pid && echo "true" || echo "false")
     echo "Is /var/run/yum.pid there ? $result"
   done
   echo "#################################"
}

function create_vm {
  echo "=================="
  echo "Reset ssh key"
  echo "=================="
  ssh-keygen -R $PUBLIC_IP

  echo "===================="
  echo "Create Virtualbox VM"
  echo "===================="
  $HOME/Code/snowdrop/openshift-infra/virtualbox/create-vm.sh -i ~/images -m 5000 -n okd-${version}
}

function post_vm_installation () {
  echo "============================================="
  echo " Post VM installation steps                  "
  echo "============================================="
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP 'bash -s' < $SCRIPT_PATH/post_vm_installation.sh $version
}

function pull_save_images () {
  echo "============================================="
  echo " Pull images                                 "
  echo "============================================="
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP 'bash -s' < $SCRIPT_PATH/docker_pull_images.sh "${!images}"
  save_images
}

function save_images () {
  echo "============================================="
  echo " Backup images : $docker_tar_file            "
  echo "============================================="
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP 'bash -s' < $SCRIPT_PATH/docker_save_images.sh $docker_tar_file "${!images}"
}

function cluster_up {
  echo "============================================="
  echo " oc cluster up                               "
  echo "============================================="
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP 'bash -s' < $SCRIPT_PATH/up.sh $version
}

function export_images () {
  echo "============================================="
  echo " Export docker images - tar file to the host "
  echo "============================================="
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP "sshpass -p $password scp -o StrictHostKeyChecking=no $docker_tar_file $host:$target_dir"
}

function load_images () {
  echo "========================================================"
  echo " Import and Load docker images from $docker_tar_file    "
  echo "========================================================"
  scp -o StrictHostKeyChecking=no $target_dir/$docker_tar_file root@$PUBLIC_IP:/root
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP "docker load -i $docker_tar_file"
}

function install_catalog {
  echo "============================================="
  echo " oc cluster up                               "
  echo "============================================="
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP "oc cluster add --base-dir=/var/lib/origin/openshift.local.clusterup service-catalog"
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP "oc cluster add --base-dir=/var/lib/origin/openshift.local.clusterup automation-service-broker"
}

# Commands to be used to create vm, do a cluster up or install catalog addons
if [ "$1" == "post_vm_installation" ]; then
  post_vm_installation $2
fi

if [ "$1" == "create_vm" ]; then
  SECONDS=0
  ssh-keygen -R $PUBLIC_IP
  create_vm $version
  echo "########### Check SSH connection ################"
  check_ssh
  ssh-keygen -R $PUBLIC_IP
  echo "########### Check Yum process ################"
  check_file_wait
  echo "Yum process is not working, we continue"
  post_vm_installation $version
  duration=$SECONDS
  echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
fi

if [ "$1" == "cluster_up" ]; then
  SECONDS=0
  cluster_up
  duration=$SECONDS
  echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
fi

if [ "$1" == "install_catalog" ]; then
  install_catalog
fi

# Commands to pull, save docker images and export them within a tar file
if [ "$1" == "pull_save_images" ]; then
  pull_save_images $2
fi

if [ "$1" == "save_images" ]; then
  save_images
fi

if [ "$1" == "export_images" ]; then
  export_images $3
fi

# Load images from the tar's docker image file
if [ "$1" == "load_images" ]; then
  SECONDS=0
  load_images $2
  duration=$SECONDS
  echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
fi





# NON USED AS PROCESS TO INSTALL VIRTUAL GUEST ADDITION ISO AND COMPILE IT IS TOO LONG
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
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP 'bash -s' < $SCRIPT_PATH/install_deps.sh

  echo "### Done pinging"
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP 'bash -s' < $SCRIPT_PATH/guest_addition.sh
}

if [ "$1" == "install_deps" ]; then
  install_deps
fi

if [ "$1" == "install_guest" ]; then
  install_guest
fi

