#!/bin/bash

LOCAL_HOME_DIR=$1
CENTOS_QCOW2=$2
RESIZE=${3:-false}
CENTOS_ISO_SERVER=http://cloud.centos.org/centos/7/images/
IMAGE_DIR=${LOCAL_HOME_DIR}/images
OS_NAME="centos7"

##
## Add public key
##
add_ssh_key(){
    echo "##### 1. Add ssh public key and create user-data file"
    YOUR_SSH_KEY=$(cat ${LOCAL_HOME_DIR}/.ssh/id_rsa.pub)
    sed "s|SSH_PUBLIC_KEY|${YOUR_SSH_KEY}|g" user-data.tpl > user-data
}

##
## Generate the config-drive iso
##
gen_iso(){
    echo "##### 2. Generating ISO file containing user-data, meta-data files and used by cloud-init at bootstrap"
    genisoimage -output ${IMAGE_DIR}/vbox-config.iso -volid cidata -joliet -r meta-data user-data
}

##
## Download Centos Generic cloud image
##
wget_centos_qcow() {
    if [ ! -f "${IMAGE_DIR}/${CENTOS_QCOW2}" ]; then
       echo "#### 3. Downloading  ${CENTOS_ISO_SERVER}/${CENTOS_QCOW2} ...."
       wget --progress=bar -O ${IMAGE_DIR}/${CENTOS_QCOW2} ${CENTOS_ISO_SERVER}/${CENTOS_QCOW2}
    fi
}


##
## Resize qcow2 with +20G
##
resize(){
    echo "#### Optional - Resizing qcow2 Image - +20G"
    qemu-img resize ${IMAGE_DIR}/${CENTOS_QCOW2} +20G
}

##
## Convert qcow to vmdk
##
make_vmdk(){
    echo "#### 4. Converting QCOW to VMDK format"
    if [ -f "${IMAGE_DIR}/${OS_NAME}.vmdk" ]; then
      rm ${IMAGE_DIR}/${OS_NAME}.vmdk
    fi
    touch ${IMAGE_DIR}/${OS_NAME}.vmdk
    qemu-img convert -p -f qcow2 ${IMAGE_DIR}/${CENTOS_QCOW2} -O vmdk ${IMAGE_DIR}/${OS_NAME}.vmdk
}

mkdir -p ${IMAGE_DIR}
add_ssh_key
gen_iso
wget_centos_qcow
if $RESIZE; then resize; fi
make_vmdk
echo "Done"
