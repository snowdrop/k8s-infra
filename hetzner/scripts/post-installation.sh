#!/bin/bash

version=3.11
hostIP=$(hostname -I | awk '{print $1}')

echo "Install needed yum packages: docker git wget ansible NetworkManager"
yum install -y -q docker git wget ansible NetworkManager

echo "Enable docker and Network manager"
systemctl enable NetworkManager
systemctl start NetworkManager

systemctl enable docker
systemctl start docker

until [ "$(systemctl is-active docker)" = "active" ]; do echo "Wait till docker daemon is running"; sleep 10; done;

echo "Cloning Snowdrop Infra Playbook"
git clone https://github.com/snowdrop/openshift-infra.git /tmp/infra 2>&1

echo "Creating Ansible inventory file"
echo -e "[masters]\nlocalhost ansible_connection=local ansible_user=root" > /tmp/infra/ansible/inventory/hetzner_vm

exit 0
