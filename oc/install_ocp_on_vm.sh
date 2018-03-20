#!/usr/bin/env bash


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scp ${DIR}/install_ocp.sh root@192.168.99.50:/tmp
ssh root@192.168.99.50 "/tmp/install_ocp.sh"

