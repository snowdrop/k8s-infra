#!/usr/bin/env bash

die () {
    echo ""
    echo >&2 "$@"
    echo ""
    echo "Required parameters:"
    echo "  1 - VM_PROVIDER: Provider which must be one of [hetzner,openstack]"
    echo "  2 - VM_NAME: Name of the vm to connect to"
    echo ""
    echo "Optional parameters:"
    echo "  3 - PASSWORD_STORE_DIR: If required if PASSWORD_STORE_DIR env var is not already defined."
    echo ""
    exit 1
}

VM_PROVIDER=$1
VM_NAME=$2
SSH_KEY=~/.ssh/id_rsa_snowdrop_${VM_PROVIDER}_${VM_NAME}

if [ -z ${PASSWORD_STORE_DIR+x} ];
then 
  [ "$#" -ge 3 ] || die "ERROR: 3 arguments required, $# provided"
  PASSWORD_STORE_DIR=$3
else
  [ "$#" -ge 2 ] || die "ERROR: 2 arguments required, $# provided"
fi


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
      echo "pass show ${VM_PROVIDER}/${VM_NAME}/id_rsa)" > ${SSH_KEY}
      chmod 600 ${SSH_KEY}
    fi
  fi
fi

IP=$(pass show ${VM_PROVIDER}/${VM_NAME}/ansible_ssh_host | awk 'NR==1{print $1}')
PORT=$(pass show ${VM_PROVIDER}/${VM_NAME}/ansible_ssh_port | awk 'NR==1{print $1}')

if [ "$PORT" = "" ];
then
    PORT=22
fi

USER=$(pass show ${VM_PROVIDER}/${VM_NAME}/os_user | awk 'NR==1{print $1}')

if [ "$USER" = "" ];
then
    USER=$(pass show ${VM_PROVIDER}/${VM_NAME}/ansible_user | awk 'NR==1{print $1}')
fi


echo "### SSH COMMAND: ssh -i ${SSH_KEY} ${USER}@${IP} -p ${PORT} ${@:4}"
ssh -i ${SSH_KEY} ${USER}@${IP} -p ${PORT} "${@:4}"
