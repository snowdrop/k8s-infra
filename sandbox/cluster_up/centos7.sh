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
git
echo "============================================="
echo "Execute shell script to perform oc cluster up"
echo "============================================="

if [ "$1" == "create" ]; then
  create_vm
fi

ssh -o StrictHostKeyChecking=no root@$PUBLIC_IP 'bash -s' < sandbox/cluster_up/up.sh
