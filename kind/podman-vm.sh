#!/bin/sh

set -o errexit

read -p "What should be the name of the vm - Default: myvm ? " vm_name
vm_name=${vm_name:-myvm}

podman machine list

podman machine stop ${vm_name}
#podman machine rm ${vm_name}


