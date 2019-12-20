#!/bin/bash

#
# The following bash script allows to run the playbooks of the project k8s-infra within a Hetzner cloud vm created
# where ansible, git have already been installed
# To use it, pass the IP address of the VM as parameter like the boot token: public key and secret
#
# ./scripts/post-installation.sh IP_ADDRESS BOOT_TOKEN_PUBLIC BOOT_TOKEN_SECRET
#

ip_address=$1
boot_token_public=$2
boot_token_secret=$3

temp_dir=/tmp/infra

echo "Cloning Snowdrop Infra Playbook"
git clone https://github.com/snowdrop/k8s-infra.git ${temp_dir} 2>&1

echo "Generating the Ansible inventory file for - local machine"
echo -e "[masters]\nlocalhost ansible_connection=local ansible_user=root public_ip_address=${ip_address}" > /tmp/infra/ansible/inventory/localhost_vm

echo "Cat Inventory file"
cat /tmp/infra/ansible/inventory/localhost_vm

cd ${temp_dir}/ansible
echo "Play the k8s_cluster role"
ansible-playbook -i inventory/localhost_vm playbook/post_installation.yml --tags k8s_cluster -e remove=false -e install_docker=true -e remote=false

ansible-playbook -i inventory/localhost_vm playbook/post_installation.yml --tags ingress
ansible-playbook -i inventory/localhost_vm playbook/post_installation.yml --tags cert_manager -e isOpenshift=false
ansible-playbook -i inventory/localhost_vm playbook/post_installation.yml --tags k8s_dashboard -e k8s_dashboard_token_public=${boot_token_public} -e k8s_dashboard_token_secret=${boot_token_secret}

exit 0
