#!/usr/bin/env bash

#
# Command to provision a centos7 vm using virtualbox driver
# with oc cluster up
#
PUBLIC_IP=192.168.99.50
CREATE_VM=$1

function create_vm {
  echo "=================="
  echo "Reset ssh key"
  echo "=================="
  ssh-keygen -R $PUBLIC_IP

  echo "===================="
  echo "Create Virtualbox VM"
  echo "===================="
  ./virtualbox/create-vm.sh -i ~/images -m 5000 -n okd-3.10

  echo "===================="
  echo "Sleep till the VM is ready"
    echo "===================="
  for i in {1..25}
  do
    echo "Waiting $i of 25"
    sleep 6s
  done
}

function install_vboxfs {
  echo "============================================="
  echo " Install and build Guestaddition             "
  echo "============================================="
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP 'bash -s' < sandbox/cluster_up/guest_addition.sh
}

function pull_backup_images {
  echo "============================================="
  echo " Pull images                                "
  echo "============================================="
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP 'bash -s' < sandbox/cluster_up/docker_pull_images.sh

  echo "============================================="
  echo " Backup images as tar file                   "
  echo "============================================="
  ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP 'bash -s' < sandbox/cluster_up/docker_save_images.sh
}

echo "============================================="
echo "Execute shell script to perform oc cluster up"
echo "============================================="

if [ "$1" == "create" ]; then
  create_vm
  install_vboxfs
fi

echo "============================================="
echo " Load docker images for origin 3.10          "
echo "============================================="
# ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP "docker load -i /media/sf_share/origin-v3.10.tar"

echo "============================================="
echo " oc cluster up                               "
echo "============================================="
ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP 'bash -s' < sandbox/cluster_up/up.sh
