#!/usr/bin/env bash

sudo yum update && sudo yum -y install "kernel-devel-$(uname -r)" gcc dkms make perl bzip2 wget tar kernel-headers

wget http://download.virtualbox.org/virtualbox/5.2.18/VBoxGuestAdditions_5.2.18.iso -P /tmp
sudo mount -o loop /tmp/VBoxGuestAdditions_5.2.18.iso /mnt

export KERN_DIR=/usr/src/kernels/$(uname -r)
sudo sh -x /mnt/VBoxLinuxAdditions.run
