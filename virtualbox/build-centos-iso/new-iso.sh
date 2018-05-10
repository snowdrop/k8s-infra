#!/bin/bash

set -e

IMAGE_DIR=$1
CENTOS_NAME=${2:-CentOS-7-x86_64-GenericCloud}
CENTOS_ISO_SERVER=http://cloud.centos.org/centos/7/images
OS_NAME="centos7"

SCRIPT_ABSOLUTE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


get_host_timezone(){
  if [[ "$OSTYPE" == "linux-gnu" ]]; then
    echo "$(cat /etc/timezone)"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "from time import gmtime, strftime\nprint strftime('%Z', gmtime())" | python
  else # just return UTC since we don't know how to extract the host timezone
     echo "UTC"
  fi
}

create_user_data(){
    echo "#### 1. Create user-data file"
    YOUR_SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
    HOST_TIMEZONE=$(get_host_timezone)
    sed "s|SSH_PUBLIC_KEY|${YOUR_SSH_KEY}|g" "${SCRIPT_ABSOLUTE_DIR}"/user-data.tpl > "${SCRIPT_ABSOLUTE_DIR}"/user-data.tmp
    sed "s|TIMEZONE|${HOST_TIMEZONE}|g" "${SCRIPT_ABSOLUTE_DIR}"/user-data.tmp > "${SCRIPT_ABSOLUTE_DIR}"/user-data
    rm "${SCRIPT_ABSOLUTE_DIR}"/user-data.tmp
}

##
## Download Centos7 Generic cloud image and extract it
##
wget_centos() {
    if [ ! -f "${IMAGE_DIR}/${CENTOS_NAME}.raw.tar.gz" ]; then
       echo "#### 2. Downloading  ${CENTOS_ISO_SERVER}/${CENTOS_NAME}.raw.tar.gz ...."
       wget --progress=bar -O ${IMAGE_DIR}/${CENTOS_NAME}.raw.tar.gz ${CENTOS_ISO_SERVER}/${CENTOS_NAME}.raw.tar.gz
    else
        echo "#### 2. ${CENTOS_ISO_SERVER}/${CENTOS_NAME}.raw.tar.gz is already there"
    fi
}

##
## Untar the cloud ra.tar.gz file
##
untar() {
    echo "#### 3. Untar the cloud ra.tar.gz file"
    tar -xvzf ${IMAGE_DIR}/${CENTOS_NAME}.raw.tar.gz -C ${IMAGE_DIR}
}

##
## Generate the config-drive iso
##
gen_iso(){
    echo "#### 4. Generating ISO file containing user-data, meta-data files and used by cloud-init at bootstrap"
    mkisofs -output ${IMAGE_DIR}/vbox-config.iso -volid cidata -joliet -r "${SCRIPT_ABSOLUTE_DIR}"/meta-data "${SCRIPT_ABSOLUTE_DIR}"/user-data
}

##
## Convert ISO to vmdk
##
make_vmdk(){
    echo "#### 5. Converting ISO to VDI format"
    if [ -f "${IMAGE_DIR}/${OS_NAME}.vdi" ]; then
      rm ${IMAGE_DIR}/${OS_NAME}.vdi
    fi
    VBoxManage convertfromraw ${IMAGE_DIR}/${CENTOS_NAME}*.raw ${IMAGE_DIR}/${OS_NAME}.vdi --format VDI
}

create_user_data
wget_centos
untar
gen_iso
make_vmdk
echo "Done"
