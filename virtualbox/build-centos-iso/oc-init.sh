#!/bin/bash
set +e

version=3.11
hostIP=$(hostname -I | awk '{print $1}')
echo -e '{ \n   "insecure-registries" : [ "172.30.0.0/16" ],\n   "hosts" : [ "unix://", "tcp://0.0.0.0:2376" ]\n}' > /etc/docker/daemon.json
rm -rf /etc/docker/certs.d/registry.access.redhat.com
systemctl enable docker
systemctl restart docker

wget https://github.com/openshift/origin/releases/download/v${version}.0/openshift-origin-client-tools-v${version}.0-0cbc58b-linux-64bit.tar.gz
tar -vxf openshift-origin-client-tools-v${version}.0-0cbc58b-linux-64bit.tar.gz
sudo cp openshift-origin-client-tools-v${version}.0-0cbc58b-linux-64bit/oc /usr/local/bin

echo "Launching oc startup using version 3.11"
oc cluster up \
  --tag="v${version}" \
  --base-dir="/var/lib/origin/openshift.local.clusterup" \
  --public-hostname="${hostIP}" \
  --skip-registry-check=true \
  --enable=[-sample-templates] \
  --v=5 \
  2>&1

exit 0
