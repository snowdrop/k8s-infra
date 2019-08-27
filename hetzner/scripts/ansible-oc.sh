#!/bin/bash

hostIP=$(hostname -I | awk '{print $1}')

echo "Starting playbook"
cd /tmp/infra/ansible
ansible-playbook -i ./inventory/hetzner_vm playbook/cluster.yml \
    -e openshift_release_tag_name="v3.11.0" \
    -e public_ip_address="${hostIP}" \
    --tags "up" \
    2>&1

echo "Enable cluster-admin role for admin user"
ansible-playbook -i ./inventory/hetzner_vm playbook/post_installation.yml \
     -e openshift_admin_pwd=admin \
     --tags "enable_cluster_role"

exit 0
