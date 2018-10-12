#!/usr/bin/env bash

version=${1:-3.11}
images="docker.io/ansibleplaybookbundle/origin-ansible-service-broker:v${version}\
 docker.io/automationbroker/automation-broker-apb:v${version}\
 docker.io/openshift/origin-cli:v${version}\
 docker.io/openshift/origin-control-plane:v${version}\
 docker.io/openshift/origin-deployer:v${version}\
 docker.io/openshift/origin-docker-builder:v${version}\
 docker.io/openshift/origin-docker-registry:v${version}\
 docker.io/openshift/origin-haproxy-router:v${version}\
 docker.io/openshift/origin-hyperkube:v${version}\
 docker.io/openshift/origin-hypershift:v${version}\
 docker.io/openshift/origin-node:v${version}\
 docker.io/openshift/origin-pod:v${version}\
 docker.io/openshift/origin-service-catalog:v${version}\
 docker.io/openshift/origin-web-console:v${version}\
 docker.io/openshift/origin-service-serving-cert-signer:v${version}\
 quay.io/coreos/etcd:v3.3"

declare -a array_images=($images)

for i in "${array_images[@]}"
do
   echo "$i"
   docker pull $i
done
