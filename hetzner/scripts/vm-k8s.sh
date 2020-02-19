#!/usr/bin/env bash

set -e

# Script to be executed under Hetzner folder path in order
# to create a new Hetzner VM using hcloud tool
#

# ./scripts/vm-k8s.sh VM_NAME VM_TYPE VM_IMAGE SALT_TEXT USER_PWD
# e.g
# ./scripts/vm-k8s.sh halkyon cx41 centos-7 <SALT_TEXT> <USER_GENERATED_PWD>

VM_NAME=${1:-halkyon}
VM_TYPE=${2:-cx31}
VM_IMAGE=${3:-centos-7}
SALT_TEXT=$4
USER_PASSWORD=$5

BASH_SCRIPTS_DIR=$(dirname $0)

# Delete and create the Hetzner Cloud vm
# TODO : Add playbook command
# . $BASH_SCRIPTS_DIR/create-hcloud-server.sh

# Execute playbooks to :
# - Generate inventory file with IP address
# - Install K8s cluster
# - Create local KUBECONFIG file
cd $BASH_SCRIPTS_DIR/../../ansible
ansible-playbook playbook/generate_inventory.yml \
   -e ssh_private_key_path=~/.ssh/id_hetzner_snowdrop \
   -e ip_address=${IP_HETZNER} \
   -e filename=${IP_HETZNER}_host \
   -e type=hetzner

ansible-playbook -i inventory/${IP_HETZNER}_host \
    playbook/k8s.yml \
    --tags k8s_cluster \
    -e k8s_version=1.15.9 \
    -e ip_address=${IP_HETZNER}

ansible-playbook -i inventory/${IP_HETZNER}_host \
    playbook/k8s.yml \
    --tags k8s_config \
    -e k8s_config_filename=${IP_HETZNER}-k8s-config.yml

echo "#######################################"
echo export KUBECONFIG="$BASH_SCRIPTS_DIR/../../ansible/inventory/${IP_HETZNER}-k8s-config.yml"
echo "#######################################"
echo "Execute the following command within a terminal to ssh to the vm"
echo "alias ssh-${VM_NAME}=\"ssh -i ~/.ssh/id_hetzner_snowdrop root@${IP_HETZNER}\""
