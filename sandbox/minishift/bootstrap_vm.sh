#!/usr/bin/env bash

#
# Command Usage
# ./bootstrap_vm.sh [COMMANDS]
#
# where commands are:
# imageCache          Enable or disable to use docker images cached on the local user's disk. Default is false
# ocp version         Version of OpenShift Origin. Default to : 3.10.0
#
# ./bootstrap_vm.sh true 3.10.0
#

DEMO_PROFILE_DIR="$HOME/.minishift/profiles/demo"
IMAGE_CACHE=${1:-false}
OCP_VERSION=${2:-3.10.0}

docker_images=(
  openshift/origin-docker-registry:v$OCP_VERSION
  openshift/origin-haproxy-router:v$OCP_VERSION
  openshift/origin-deployer:v$OCP_VERSION
  openshift/origin:v$OCP_VERSION
  openshift/origin-pod:v$OCP_VERSION
  openshift/origin-sti-builder:v$OCP_VERSION
  registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift:latest
)
IMAGES=$(printf "%s " "${docker_images[@]}")

if [ ! -d "minishift-addons" ]; then
  git clone https://github.com/minishift/minishift-addons.git
fi

if [ ! -d "$demo_PROFILE_DIR" ]; then
  minishift profile set demo
  minishift --profile demo addons install minishift-addons/add-ons/ansible-service-broker
  minishift --profile demo config set iso centos
  minishift --profile demo config set memory 6GB
  minishift --profile demo config set cpus 4
  minishift --profile demo config set openshift-version v$OCP_VERSION
  minishift --profile demo config set vm-driver xhyve
  minishift --profile demo addon enable admin-user
  minishift --profile demo addon enable ansible-service-broker
fi

minishift config set image-caching true

if [ "$IMAGE_CACHE" = true ] ; then
  minishift image cache-config add $IMAGES
fi

MINISHIFT_ENABLE_EXPERIMENTAL=y minishift start --profile demo --service-catalog --iso-url centos

if [ "$IMAGE_CACHE" = true ] ; then
  # Export images to be sure to have a backup locally
  minishift image export
fi

echo "Log to OpenShift using admin user"
oc login -u system:admin
oc adm policy add-cluster-role-to-user cluster-admin admin
oc login -u admin -p admin
