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
ansible-playbook ${ANSIBLE_PLAYBOOK_FILE} ${ANSIBLE_PLAYBOOK_PARAMETERS}
