#!/bin/bash

version=3.11
hostIP=$(hostname -I | awk '{print $1}')

echo "Cloning Snowdrop Infra Playbook"
git clone https://github.com/snowdrop/openshift-infra.git /tmp/infra 2>&1

echo "Creating Ansible inventory file"
echo -e "[masters]\nlocalhost ansible_connection=local ansible_user=root" > /tmp/infra/ansible/inventory/hetzner_vm

echo "Starting playbook"
cd /tmp/infra/ansible
# ansible-playbook --connection=local --inventory 127.0.0.1, playbook/cluster.yml \
ansible-playbook -i ./inventory/hetzner_vm playbook/cluster.yml \
    -e openshift_release_tag_name=v3.11.0 \
    --tags "up" \
    2>&1

exit 0
