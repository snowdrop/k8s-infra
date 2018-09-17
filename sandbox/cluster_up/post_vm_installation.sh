#!/usr/bin/env bash

echo "==============================="
echo "Install missing utility tools"
echo "==============================="
sudo yum -y install bzip2 wget tar

echo "==============================="
echo "Download oc client, untar it"
echo "==============================="
wget -O- https://github.com/openshift/origin/releases/download/v3.10.0/openshift-origin-client-tools-v3.10.0-dd10d17-linux-64bit.tar.gz | tar vxz
sudo cp openshift-origin-client-tools-v3.10.0-dd10d17-linux-64bit/oc /usr/bin

echo "==============================="
echo "Configure docker to be insecure"
echo "==============================="
echo -e '{ \n   "insecure-registries" : [ "172.30.0.0/16" ],\n   "hosts" : [ "unix://", "tcp://0.0.0.0:2376" ]\n}' > /etc/docker/daemon.json
systemctl restart docker
