#!/bin/bash

version=3.11
hostIP=$(hostname -I | awk '{print $1}')

echo "Cloning Snowdrop Infra Playbook"
git clone https://github.com/snowdrop/openshift-infra.git /tmp/infra 2>&1

echo "Creating Ansible inventory file"
echo -e "[masters]\nlocalhost ansible_connection=local ansible_user=root" > /tmp/infra/ansible/inventory/hetzner_vm

echo "Pulling docker images"
sudo docker pull quay.io/openshift/origin-node:v${version}
sudo docker pull quay.io/openshift/origin-control-plane:v${version}
sudo docker pull quay.io/openshift/origin-haproxy-router:v${version}
sudo docker pull quay.io/openshift/origin-hyperkube:v${version}
sudo docker pull quay.io/openshift/origin-deployer:v${version}
sudo docker pull quay.io/openshift/origin-pod:v${version}
sudo docker pull quay.io/openshift/origin-hypershift:v${version}
sudo docker pull quay.io/openshift/origin-cli:v${version}
sudo docker pull quay.io/openshift/origin-docker-registry:v${version}
sudo docker pull quay.io/openshift/origin-web-console:v${version}
sudo docker pull quay.io/openshift/origin-service-serving-cert-signer:v${version}

echo "Starting playbook"
cd /tmp/infra/ansible
ansible-playbook -i ./inventory/hetzner_vm playbook/cluster.yml \
    -e openshift_release_tag_name="v${version}.0" \
    -e public_ip_address="${hostIP}" \
    --tags "up" \
    2>&1

echo "Enable cluster-admin role for admin user"
ansible-playbook -i ./inventory/hetzner_vm playbook/post_installation.yml \
     -e openshift_admin_pwd=admin \
     --tags "enable_cluster_role"

exit 0
