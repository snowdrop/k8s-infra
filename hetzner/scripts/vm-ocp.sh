#!/usr/bin/env bash

# Script to be executed under Hetzner folder path in order
# to create a new Hetzner VM using hcloud tool
#

# ./scripts/vm-ocp.sh VM_NAME VM_TYPE VM_IMAGE SALT_TEXT USER_GENERATED_PWD
# e.g
# ./scripts/vm-ocp.sh halkyon cx31 centos-7 <SALT_TEXT> <USER_GENERATED_PWD>

VM_NAME=${1:-halkyon}
VM_TYPE=${2:-cx31}
VM_IMAGE=${3:-centos-7}
SALT_TEXT=$4
USER_PASSWORD=$5

BASH_SCRIPTS_DIR=$(dirname $0)

# Delete and create the Hetzner Cloud server
. create-hcloud-server.sh

# Execute playbooks to :
# - Generate inventory file with IP address
# - Create oc cluster up configuration
# - Register it as systemctl okd service but don't start it
cd $BASH_SCRIPTS_DIR/../../ansible
ansible-playbook playbook/generate_inventory.yml \
   -e ssh_private_key_path=~/.ssh/id_hetzner_snowdrop \
   -e ip_address=${IP_HETZNER} \
   -e filename=${IP_HETZNER}_host \
   -e type=hetzner
ansible-playbook -i inventory/hetzner_host playbook/cluster.yml \
   -e public_ip_address=${IP_HETZNER} \
   -e cluster_write_config=true \
   -e ansible_os_family="RedHat" \
   --tags "up"
