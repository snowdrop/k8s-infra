#!/usr/bin/env bash

echo "#### Download VBoxGuestAdditions_5.2.18.iso and mount it under /mnt"
wget -q http://download.virtualbox.org/virtualbox/5.2.18/VBoxGuestAdditions_5.2.18.iso -P /tmp
sudo mount -o loop /tmp/VBoxGuestAdditions_5.2.18.iso /mnt

echo "#### Export kernel directory and compile"
export KERN_DIR=/usr/src/kernels/$(uname -r)
sudo sh -x /mnt/VBoxLinuxAdditions.run
