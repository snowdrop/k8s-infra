#!/usr/bin/env bash

sudo yum -y install epel-release "kernel-devel-$(uname -r)" gcc dkms make perl bzip2 wget tar "kernel-headers-$(uname -r)"
