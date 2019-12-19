#!/bin/bash

# Command
# ./scripts/post-installation.sh IP_ADDRESS

ip_address=$1
temp_dir=/tmp/infra

echo "Cloning Snowdrop Infra Playbook"
git clone https://github.com/snowdrop/k8s-infra.git ${temp_dir} 2>&1

echo "Generating the Ansible inventory file for - local machine"
echo -e "[masters]\nlocalhost ansible_connection=local ansible_user=root public_ip_address=${ip_address}" > /tmp/infra/ansible/inventory/localhost_vm

echo "Cat Inventory file"
cat /tmp/infra/ansible/inventory/localhost_vm

cd ${temp_dir}/ansible
echo "Play the k8s_cluster role"
ansible-playbook -i inventory/localhost_vm playbook/post_installation.yml --tags k8s_cluster -e install_docker=true

exit 0
