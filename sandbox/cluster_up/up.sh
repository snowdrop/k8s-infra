#!/usr/bin/env bash

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

echo "==============================="
echo "Bootstrap oc"
echo "==============================="
PUBLIC_IP=$(ifconfig enp0s3 | sed -En 's/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
oc cluster up \
  --base-dir="/var/lib/origin/openshift.local.clusterup" \
  --public-hostname=${PUBLIC_IP}

echo "==============================="
echo "Grant cluster-admin role to admin's user"
echo "==============================="
oc login -u system:admin
oc adm policy  add-cluster-role-to-user cluster-admin admin
oc login -u admin -p admin
