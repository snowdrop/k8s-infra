#!/usr/bin/env bash


# This script is for installing OLM from a GitHub release

set -e

if [[ ${#@} -ne 1 ]]; then
    echo "Usage: $0 version"
    echo "* version: the github release version"
    exit 1
fi

release=$1
url=https://github.com/operator-framework/operator-lifecycle-manager/releases/download/${release}
namespace=olm

kubectl delete --ignore-not-found=true -f ${url}/crds.yaml
kubectl delete --ignore-not-found=true -f ${url}/olm.yaml
kubectl delete --ignore-not-found=true namespace ${namespace}