#!/usr/bin/env bash

version=${1:-3.11}

if ! [ -x "$(command -v oc)" ]; then
  echo 'Error: oc is not installed.' >&2
  exit 1
fi

echo "==============================="
echo "Bootstrap oc"
echo "==============================="
PUBLIC_IP=$(ifconfig enp0s3 | sed -En 's/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
oc cluster up \
  --tag=v${version} \
  --base-dir="/var/lib/origin/openshift.local.clusterup" \
  --public-hostname=${PUBLIC_IP}

echo "==============================="
echo "Grant cluster-admin role to admin's user"
echo "==============================="
oc login -u system:admin
oc adm policy  add-cluster-role-to-user cluster-admin admin
oc login -u admin -p admin
