#!/usr/bin/env bash

# Script to be executed under Hetzner folder path in order
# to create a new Hetzner VM using hcloud tool
#

# ./scripts/vm.sh VM_NAME VM_TYPE VM_IMAGE SALT_TEXT USER_PWD
# e.g
# ./scripts/vm.sh cloud1 cx31 centos-7 <SALT_TEXT> <USER_GENERATED_PWD>

VM_NAME=${1:-cloud1}
VM_TYPE=${2:-cx31}
VM_IMAGE=${3:-centos-7}
SALT_TEXT=$4
USER_PASSWORD=$5

BASH_SCRIPTS_DIR=$(dirname $0)

# Delete and create the Hetzner Cloud vm
. $BASH_SCRIPTS_DIR/create-hcloud-server.sh

echo "#######################################"
echo "Execute the following command within a terminal to ssh to the vm"
echo "alias ssh-${VM_NAME}=\"ssh -i ~/.ssh/id_hetzner_snowdrop root@${IP_HETZNER}\""
