#!/usr/bin/env bash

die () {
    echo >&2 "$@"
    exit 1
}

VM_PROVIDER=$1
VM_NAME=$2
PASSWORD_STORE_DIR=$3
SSH_KEY=~/.ssh/id_rsa_snowdrop_${VM_PROVIDER}_${VM_NAME}

[ "$#" -ge 3 ] || die "3 arguments required, $# provided"

if [ "${VM_PROVIDER}" != 'hetzner' ] && [ "${VM_PROVIDER}" != 'openstack' ]; 
then 
  die "\$1: Provider must be one of [hetzner,openstack], ${VM_PROVIDER} provided"; 
fi

if [ ! -d ${PASSWORD_STORE_DIR} ]; 
then
  die "Pass store directory ${PASSWORD_STORE_DIR} doesn't exist"
fi

if [ ! -f ${SSH_KEY} ]; 
then
  SSH_KEY=~/.ssh/id_rsa_snowdrop_${VM_PROVIDER}
  if [ ! -f ${SSH_KEY} ]; 
  then
    SSH_KEY=~/.ssh/id_rsa_snowdrop
    if [ ! -f ${SSH_KEY} ]; 
    then
      die "Missing SSH key file."
    fi
  fi
fi
chmod 600 ${SSH_KEY}

IP=$(pass show ${VM_PROVIDER}/${VM_NAME}/ansible_ssh_host | awk 'NR==1{print $1}')
PORT=$(pass show ${VM_PROVIDER}/${VM_NAME}/ansible_ssh_port | awk 'NR==1{print $1}')
USER=$(pass show ${VM_PROVIDER}/${VM_NAME}/os_user | awk 'NR==1{print $1}')

echo "### SSH COMMAND: ssh -i ${SSH_KEY} ${USER}@${IP} -p ${PORT} ${@:4}"
ssh -i ${SSH_KEY} ${USER}@${IP} -p ${PORT} "${@:4}"
