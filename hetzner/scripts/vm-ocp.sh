#!/usr/bin/env bash


VM_NAME=halkyon
hcloud server delete $VM_NAME
./scripts/create-user-data.sh

hcloud server create --name $VM_NAME --type cx41 --image centos-7 --ssh-key dabou --user-data-from-file ./scripts/user-data

IP_HETZNER=$(hcloud server describe $VM_NAME  -o json | jq -r .public_net.ipv4.ip)
ssh-keygen -R $IP_HETZNER
while ! nc -z $IP_HETZNER 22; do echo "Wait till we can ssh to the $VM_NAME vm ..."; sleep 10; done
ssh -o StrictHostKeyChecking=no root@$IP_HETZNER 'bash -s' < ./scripts/post-installation.sh

cd ../ansible
ansible-playbook playbook/generate_inventory.yml -e ip_address=$IP_HETZNER -e type=hetzner
ansible-playbook -i inventory/hetzner_host playbook/cluster.yml \
   -e public_ip_address=$(hcloud server describe $VM_NAME -o json | jq -r .public_net.ipv4.ip) \
   -e ansible_os_family="RedHat" \
      --tags "up"
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
