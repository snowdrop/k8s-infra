#!/usr/bin/env bash

#
# Command to provision a centos7 vm using virtualbox driver
# with oc cluster up
#
../virtualbox/create-vm.sh -i ~/images -m 5000 -n dummy
ssh root@192.168.99.50 'bash -s' < sandbox/cluster_up.sh
