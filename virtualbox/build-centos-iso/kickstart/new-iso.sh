#!/usr/bin/env bash

LOCAL_HOST="/Users/dabou/images"
CENTOS_ISO="CentOS-7-x86_64-Minimal-1708.iso"
ISO_NAME="centos7.iso"
ISO="$LOCAL_HOST/$CENTOS_ISO"

echo "##### Create our own ISO ....."

echo "##### Remove bootiso, bootisokf folders"
rm -rf /tmp/{bootiso,bootisoks}

echo "##### Make bootiso dir and mount the ISO file"
mkdir /tmp/bootiso
sudo mount -o loop $LOCAL_HOST/$CENTOS_ISO /tmp/bootiso
mkdir /tmp/bootisoks

echo "##### Copy extracted files to bootisoks"
cp -r /tmp/bootiso/* /tmp/bootisoks/
sudo umount /tmp/bootiso && rmdir /tmp/bootiso
chmod -R u+w /tmp/bootisoks

echo "##### Copy ks.cfg, isolinux files"
# TODO : Fix sed issue
# sed -i 's/append\ initrd\=initrd.img$/append initrd=initrd.img\ ks\=cdrom:\/ks.cfg/' /tmp/bootisoks/isolinux/isolinux.cfg
cp config/isolinux.cfg /tmp/bootisoks/isolinux/isolinux.cfg
cp config/centos-7.ks /tmp/bootisoks/isolinux/ks.cfg

echo "##### Make new ISO file"
cd /tmp/bootisoks && mkisofs -o /tmp/boot.iso -b isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -V "CentOS 7 x86_64" -R -J -v -T isolinux/. .

echo "##### Ad md5 signature"
implantisomd5 "/tmp/boot.iso"

echo "##### Copy iso file to your local_host : $LOCAL_HOST/$ISO_NAME"
cp /tmp/boot.iso $LOCAL_HOST/$ISO_NAME
