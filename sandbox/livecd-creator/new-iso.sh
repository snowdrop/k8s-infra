#!/usr/bin/env bash

LOCAL_HOST="/Users/dabou/images"
ISO_NAME="centos7"
KS_FILE=centos-7.2.ks
BUILD_DIR=/tmp/build
CACHE_DIR=/tmp/cache
HOME_INSTALL=$(pwd)

echo "##### Create our own ISO ....."
echo "##### using $HOME_INSTALL/new-iso-2.sh script"

echo "##### Remove build folder"
rm -rf /tmp/build

echo "##### Make build directory"
mkdir /tmp/build

echo "##### Create ISO image using live-cdcreator and our customized kickstart config file"
cd ${BUILD_DIR}

sudo livecd-creator -v --tmpdir=${BUILD_DIR}/temp \
                       --cache=${CACHE_DIR} \
                       --config $HOME_INSTALL/config/${KS_FILE} \
                       --logfile=${BUILD_DIR}/livecd-creator.log \
                       --fslabel ${ISO_NAME}

echo "##### Copy iso file to your local_host : $LOCAL_HOST/${ISO_NAME}.iso"
cp ${BUILD_DIR}/${ISO_NAME}.iso $LOCAL_HOST/${ISO_NAME}.iso
