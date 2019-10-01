#!/bin/bash

ip=$(ip -f inet a show eth0| grep inet| awk '{ print $2}' | cut -d/ -f1)

/usr/local/bin/oc cluster up \
     --public-hostname=$ip \
     --tag=v3.11.0 \
     --base-dir=/var/lib/origin/openshift.local.clusterup/ \
     --routing-suffix=$ip.nip.io \
     --server-loglevel=1 \
     --write-config=False \
     --v=0
