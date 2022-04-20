#!/bin/bash

./setEnv.sh

if [ ! -d "/opt/volumes/k8s-infra" ]; then
  echo "/opt/volumes/k8s-infra volume is missing"
  exit 1
fi

if [ ! -d "/opt/volumes/pass" ]; then
  echo "/opt/volumes/pass volume is missing"
  exit 1
fi

if [ ! -d "/opt/volumes/gnupg" ]; then
  echo "/opt/volumes/gnupg volume is missing"
  exit 1
fi

if [ ! -d "${HOME}/.ssh" ]; then 
  echo "SSH folder is missing (${HOME}/.ssh). Mount the corresponding volume from the host."
  exit 1
fi

if [[ -v OVPN_HOST ]] && [[ -v OVPN_USER ]] && [[ -v OVPN_PW ]] && [ -d "/opt/volumes/openvpn" ]; then
  touch /etc/openvpn/credentials
  printf '%s\n' "'${OVPN_USER}'" "'${OVPN_PW}'" > /etc/openvpn/credentials
  openvpn --config /opt/volumes/openvpn/vpn.ovpn
fi

pushd /opt/volumes/k8s-infra/ansible

case $ANSIBLE_ACTION in
  vm_create)
    ANSIBLE_PLAYBOOK_FILE=playbook/${CLOUD_PROVIDER}_${ANSIBLE_ACTION}_aggregate.yml;
    ANSIBLE_PLAYBOOK_PARAMETERS=" -e "
    ANSIBLE_PLAYBOOK_PARAMETERS+=$( jq -cn \
                  --arg vm_name "${VM_NAME}" \
                  --arg vm_flavor "${VM_FLAVOR}" \
                  --arg vm_image "${VM_IMAGE}" \
                  --arg k8s_version "${K8S_VERSION}" \
                  '{vm_name: $vm_name, k8s_type=masters, k8s_version: $k8s_version, openstack: {vm: {network: "provider_net_shared" , flavor: $vm_flavor, image: $vm_image }}}' );
    ANSIBLE_PLAYBOOK_PARAMETERS+=" --tags create";;
  vm_remove)
    ANSIBLE_PLAYBOOK_FILE=playbook/${CLOUD_PROVIDER}_${ANSIBLE_ACTION}_aggregate.yml;
    ANSIBLE_PLAYBOOK_PARAMETERS=" -e '";
    ANSIBLE_PLAYBOOK_PARAMETERS+=$( jq -cn \
                  --arg vm_name "${VM_NAME}" \
                  '{vm_name: $vm_name}' );
    ANSIBLE_PLAYBOOK_PARAMETERS+="' '";;
  k8s_install)
    echo "K8S_INSTALL!!!";;
  *) 
    echo "The select ${ANSIBLE_ACTION} action is not available.";
    echo "Allowed actions are:";
    echo "  vm_create - create a new VM";
    echo "  vm_remove - remove an existing VM";
    echo "  k8s_install - Install k8s";; 
esac

echo "ANSIBLE_PLAYBOOK_FILE: ${ANSIBLE_PLAYBOOK_FILE}"
echo "ANSIBLE_PLAYBOOK_PARAMETERS: ${ANSIBLE_PLAYBOOK_PARAMETERS}"
ansible-playbook ${ANSIBLE_PLAYBOOK_FILE} ${ANSIBLE_PLAYBOOK_PARAMETERS}
