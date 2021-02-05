#!/bin/bash

# sudo yum list --showduplicates kubeadm --disableexcludes=kubernetes
declare -a Versions=("1.14.10" "1.15.12" "1.16.15" "1.17.17" "1.18.15" "1.19.7" "1.20.2")
#declare -a Versions=("1.19.7" "1.20.2")
MASTER=centos7.localdomain

for VERSION in ${Versions[@]}; do
   echo "#######################################################"
   echo "##### K8s version to be upgraded to : $VERSION ########"
   echo "#######################################################"
   sudo yum install -y kubeadm-$VERSION --disableexcludes=kubernetes
   sudo kubeadm upgrade apply v$VERSION
   sudo kubectl --kubeconfig=.kube/config drain $MASTER --ignore-daemonsets --delete-local-data
   sudo yum install -y kubelet-$VERSION kubectl-$VERSION --disableexcludes=kubernetes
   sudo systemctl daemon-reload
   sudo systemctl restart kubelet
   sudo kubectl --kubeconfig=.kube/config uncordon $MASTER
done
