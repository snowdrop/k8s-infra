#!/usr/bin/env bash

images="docker.io/automationbroker/automation-broker-apb:v3.10\
 docker.io/openshift/origin-cli:v3.10\
 docker.io/openshift/origin-control-plane:v3.10\
 docker.io/openshift/origin-deployer:v3.10\
 docker.io/openshift/origin-docker-builder:v3.10\
 docker.io/openshift/origin-docker-registry:v3.10\
 docker.io/openshift/origin-haproxy-router:v3.10\
 docker.io/openshift/origin-hyperkube:v3.10\
 docker.io/openshift/origin-hypershift:v3.10\
 docker.io/openshift/origin-node:v3.10\
 docker.io/openshift/origin-pod:v3.10\
 docker.io/openshift/origin-service-catalog:v3.10\
 docker.io/openshift/origin-web-console:v3.10\
 quay.io/coreos/etcd:v3.3"

declare -a array_images=($images)

for i in "${array_images[@]}"
do
   echo "$i"
   docker pull $i
done
