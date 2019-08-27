#!/bin/bash

# Command
# ./scripts/post-installation.sh true
# where boolean is used to specify if we run Ansible locally or remotely

IS_ANSIBLE_LOCAL=${1:-true}

echo "Install needed yum packages: docker git wget ..."
if [ "$IS_ANSIBLE_LOCAL" = true ]; then
  yum install -y -q docker git wget
else
  yum install -y -q docker git wget ansible
fi

# echo "Enable Network manager"
# yum install -y -q NetworkManager
# systemctl enable NetworkManager
# systemctl start NetworkManager

systemctl enable docker
systemctl start docker

until [ "$(systemctl is-active docker)" = "active" ]; do echo "Wait till docker daemon is running"; sleep 10; done;

if [ "$IS_ANSIBLE_LOCAL" = false ] ; then
  echo "Cloning Snowdrop Infra Playbook"
  git clone https://github.com/snowdrop/openshift-infra.git /tmp/infra 2>&1

  echo "Creating Ansible inventory file"
  echo -e "[masters]\nlocalhost ansible_connection=local ansible_user=root" > /tmp/infra/ansible/inventory/hetzner_vm
fi

exit 0
