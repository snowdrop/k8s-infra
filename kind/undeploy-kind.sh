#!/bin/sh

#
# Script creating a Kubernetes cluster using kind tool
# deploying a private docker registry and kourier to route the traffic
#
# Creation: March 8 Feb - 2023
#
# Add hereafter changes done post creation date as backlog
#
# Feb 8th 2023:
#
# -
#

set -o errexit

log_message() {
    if [ "${LOGGING_VERBOSITY}" -ge "$1" ]; then
        echo "$2"
    fi
}

show_usage() {
    log_message "0" "Usage: "
    log_message "0" "  ./undeploy-kind.sh [parameters,...]"
    log_message "0" ""
    log_message "0" "Parameters: "
    log_message "0" "  --help: This help message"
    log_message "0" ""
    log_message "0" "  --cluster-name <name>                 Name of the cluster. Default: kind"
}

delete_kind_cluster() {
  log_message "5" "kindCfg: Deleting kind cluster ${CLUSTER_NAME}..."
  kind delete cluster -n ${CLUSTER_NAME}
  docker container rm kind-registry -f
}

###### /Command Line Parser
CLUSTER_NAME="kind"
LOGGING_VERBOSITY="0"

while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]];
  then
    param="${1/--/}";
    case $1 in
      --help) SHOW_HELP="y"; break 2 ;;
      --cluster-name) CLUSTER_NAME="$2"; shift ;;
      --verbosity) LOGGING_VERBOSITY="$2"; shift ;;
      *) UNMANAGED_PARAMS="${UNMANAGED_PARAMS} $1 $2" ;;
    esac;
  fi
  shift
done

###### Execution

delete_kind_cluster
