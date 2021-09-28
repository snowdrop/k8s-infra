#!/usr/bin/env bash

set -e -o pipefail; [[ -n "$DEBUG" ]] && set -x

CERT_DIR="${CERT_DIR:-"/usr/local/share/ca-certificates"}"

function usage() {
  echo "Usage: $(basename "$0") [-n name] certflie ..." >&2
}

while getopts n: OPT; do
  case $OPT in
    n) name="$OPTARG"
       ;;
    *) usage
       exit 1
       ;;
  esac
done
shift "$((OPTIND - 1))"

name="${name:-"kind"}"

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

containers="$(kind get nodes --name="$name" 2>/dev/null)"
if [[ "$containers" == "" ]]; then
  echo "No kind nodes found for cluster \"$name\"" >&2
  exit 1
fi

while IFS= read -r container; do
  for certfile in "$@"; do
    echo "Copying ${certfile} to ${container}:${CERT_DIR}"
    docker cp "$certfile" "${container}:${CERT_DIR}"
  done

  echo "Updating CA certificates in ${container}..."
  docker exec "$container" update-ca-certificates

  echo "Restarting containerd"
  docker exec "$container" systemctl restart containerd
done <<< "$containers"
