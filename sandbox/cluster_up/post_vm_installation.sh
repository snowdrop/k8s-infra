#!/usr/local/bin/bash

version=${1:-3.11}
declare -A releases
releases=( ["3.10"]="dd10d17" ["3.11"]="0cbc58b")
release_url="https://github.com/openshift/origin/releases/download/v${version}.0/openshift-origin-client-tools-v${version}.0-${releases[$version]}-linux-64bit.tar.gz"

echo "==============================="
echo "Download oc client, untar it"
echo "==============================="
wget -O- ${release_url}| tar vxz
sudo cp openshift-origin-client-tools-v${version}.0-*/oc /usr/bin

echo "==============================="
echo "Configure docker to be insecure"
echo "==============================="
echo -e '{ \n   "insecure-registries" : [ "172.30.0.0/16" ],\n   "hosts" : [ "unix://", "tcp://0.0.0.0:2376" ]\n}' > /etc/docker/daemon.json
systemctl restart docker
