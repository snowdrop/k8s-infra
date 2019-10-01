#!/usr/bin/env bash

# Script to be executed under Hetzner folder path
# ./scripts/vm-ocp.sh

VM_NAME=halkyon

# Delete cloud server and key
hcloud server delete $VM_NAME
hcloud ssh-key delete snowdrop
hcloud ssh-key create --name snowdrop --public-key-from-file ~/.ssh/id_hetzner_snowdrop.pub

# Create the cloud init file using user private key
./scripts/create-user-data.sh

# Create cloud instance - centos7
hcloud server create --name $VM_NAME --type cx41 --image centos-7 --ssh-key snowdrop --user-data-from-file ./scripts/user-data

# Get IP address and wait till we can SSH
IP_HETZNER=$(hcloud server describe $VM_NAME  -o json | jq -r .public_net.ipv4.ip)
ssh-keygen -R $IP_HETZNER
while ! nc -z $IP_HETZNER 22; do echo "Wait till we can ssh to the $VM_NAME vm ..."; sleep 10; done
ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_hetzner_snowdrop root@$IP_HETZNER 'bash -s' < ./scripts/post-installation.sh

# Execute playbooks to :
# - Generate inventory file with IP address
# - Create oc cluster up and register it as systemctl okd service
cd ../ansible
ansible-playbook playbook/generate_inventory.yml \
   -e ssh_private_key_path=~/.ssh/id_hetzner_snowdrop \
   -e ip_address=$IP_HETZNER \
   -e type=hetzner
ansible-playbook -i inventory/hetzner_host playbook/cluster.yml \
   -e public_ip_address=$IP_HETZNER \
   -e ansible_os_family="RedHat" \
   --tags "up"
