#!/bin/bash

version=3.11
hostIP=$(hostname -I | awk '{print $1}')

echo "Cloning Snowdrop Infra Playbook"
git clone https://github.com/snowdrop/openshift-infra.git /tmp/infra 2>&1

echo "Creating Ansible inventory file"
echo -e "[masters]\n ${hostIP} public_ip_address==${hostIP} ansible_user=root" > /tmp/infra/ansible/inventory/${hostIP}

echo "Starting playbook"
cd /tmp/infra/ansible
ansible-playbook -i inventory playbook/cluster.yml \
    -e openshift_release_tag_name=v3.11.0 \
    --tags "up" \
    2>&1

exit 0
