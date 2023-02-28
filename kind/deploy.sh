#!/usr/bin/env bash

UNMANAGED_PARAMS=""
CLUSTER_NAME="kind"
DELETE_KIND_CLUSTER="n"
INGRESS="nginx"
KNATIVE_VERSION="1.9.0"
KUBERNETES_VERSION="latest"
LOGGING_VERBOSITY="0"
REGISTRY_IMAGE_VERSION="2.6.2"
REGISTRY_PORT="5000"
SECURE_REGISTRY="n"
SERVER_IP="127.0.0.1"
SHOW_HELP="n"

while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]];
  then
    param="${1/--/}";
    case $1 in
      --help) SHOW_HELP="y"; break 2 ;;
      --cluster-name) CLUSTER_NAME="$2"; shift ;;
      --delete-kind-cluster) DELETE_KIND_CLUSTER="y" ;;
      --ingress) INGRESS="$2"; shift ;;
      --knative-version) KNATIVE_VERSION="$2"; shift ;;
      --kubernetes-version) KUBERNETES_VERSION="$2"; shift ;;
      --registry-image-version) REGISTRY_IMAGE_VERSION="$2"; shift ;;
      --registry-port) REGISTRY_PORT="$2"; shift ;;
      --secure-registry) SECURE_REGISTRY="y" ;;
      --server-ip) SERVER_IP="$2"; shift ;;
      --verbosity) LOGGING_VERBOSITY="$2"; shift ;;
      *) UNMANAGED_PARAMS="${UNMANAGED_PARAMS} $1 $2" ;;
    esac;
  #elif [[ $1 == "-D"* ]];
  #then
  #  UNMANAGED_PARAMS="${UNMANAGED_PARAMS} $1";
  fi
  shift
done

# Validations:
# if ingress is wither knative or nginx

export UNMANAGED_PARAMS
export CLUSTER_NAME
export DELETE_KIND_CLUSTER
export INGRESS
export KNATIVE_VERSION
export KUBERNETES_VERSION
export REGISTRY_IMAGE_VERSION
export REGISTRY_PORT
export SECURE_REGISTRY
export SERVER_IP
export LOGGING_VERBOSITY
export SHOW_HELP

if [[ "$SHOW_HELP" == "y" ]]; then
  echo "Usage: "
  echo "  ./deploy.sh [parameters,...]"
  echo ""
  echo "Parameters: "
  echo "  --help: This help message"
  echo ""
  echo "  --cluster-name <name>                 Name of the cluster. Default: kind"
  echo "  --delete-kind-cluster                 Deletes the Kind cluster prior to creating a new one."
  echo "  --ingress [nginx,knative]             Ingress to be deployed. One of nginx,knative. Default: nginx"
  echo "  --knative-version <version>           KNative version to be used. Default: 1.9.0"
  echo "  --kubernetes-version <version>        Kubernetes version to be install"
  echo "                                        Default: latest"
  echo "  --registry-image-version <version>    Version of the registry container to be used. Default: 2.6.2"
  echo "  --registry-port <port>                Port to publish the registry. Default: 5000"
  echo "  --server-ip <ip-address>              IP address to be used. Default: 127.0.0.1"
  echo "  --verbosity <value>                   Logging verbosity (0..9)"
  echo "                                        A verbosity setting of 0 logs only critical events."
  echo "                                        Default: 0"
else
  ./pre-reqs.sh
  ./kind-reg.sh
fi
