#!/bin/bash

ip=$(ip -f inet a show eth0| grep inet| awk '{ print $2}' | cut -d/ -f1)

/usr/local/bin/oc cluster up \
     --public-hostname=$ip \
     --base-dir=/var/lib/origin/openshift.local.clusterup/ \
     --loglevel=1
