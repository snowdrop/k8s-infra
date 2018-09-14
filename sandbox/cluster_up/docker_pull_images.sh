#!/usr/bin/env bash

declare -a images=("quay.io/coreos/etcd:v3.3"
                   "docker.io/openshift/origin-service-catalog:v3.10"
                   "quay.io/coreos/etcd:v3.3"
                   "docker.io/automationbroker/automation-broker-apb:latest"
                   "openshift/origin-service-catalog:v3.10"
                   "openshift/origin-node:v3.10"
                   "openshift/origin-docker-builder:v3.10"
                   "openshift/origin-haproxy-router:v3.10"
                   "openshift/origin-deployer:v3.10"
                   "openshift/origin-control-plane:v3.10"
                   "openshift/origin-hypershift:v3.10"
                   "openshift/origin-hyperkube:v3.10"
                   "openshift/origin-pod:v3.10"
                   "openshift/origin-web-console:v3.10"
                   "openshift/origin-docker-registry:v3.10"
                   "openshift/origin-cli:v3.10")

for i in "${images[@]}"
do
   echo "$i"
   docker pull $i
done
