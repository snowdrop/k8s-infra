#!/usr/bin/env bash

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

# Delete and create the Hetzner Cloud server
. $BASH_SCRIPTS_DIR/create-hcloud-server.sh

# Execute playbooks to :
# - Generate inventory file with IP address
# - Install K8s cluster
# - Create local KUBECONFIG file
# - Install the Ingress Router
# - Deploy the Kubernetes Dashboard
cd $BASH_SCRIPTS_DIR/../../ansible
ansible-playbook playbook/generate_inventory.yml \
   -e ssh_private_key_path=~/.ssh/id_hetzner_snowdrop \
   -e ip_address=$IP_HETZNER \
   -e type=hetzner

cp inventory/hetzner_host inventory/${VM_NAME}_host

ansible-playbook -i inventory/${VM_NAME}_host \
    playbook/k8s.yml \
    --tags k8s_cluster \
    -e ip_address=$IP_HETZNER

ansible-playbook -i inventory/${VM_NAME}_host \
    playbook/k8s.yml \
    --tags k8s_config \
    -e k8s_config_filename=${VM_NAME}_k8s_config.yml

ansible-playbook -i inventory/${VM_NAME}_host \
    playbook/k8s.yml \
    --tags ingress

ansible-playbook -i inventory/${VM_NAME}_host \
    playbook/k8s.yml \
    --tags k8s_dashboard

echo "#######################################"
echo "Execute the following command within a terminal to ssh to the vm"
echo "alias ssh-${VM_NAME}=\"ssh -i ~/.ssh/id_hetzner_snowdrop root@${IP_HETZNER}\""
