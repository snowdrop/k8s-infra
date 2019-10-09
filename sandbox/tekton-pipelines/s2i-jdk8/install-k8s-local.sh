#!/usr/bin/env bash

# OpenShift
# s2i build as dockerfile -> buildah bud -> buildah push
# Internal Docker registry
#

kubectl delete taskruns --all -n demo
kubectl delete tasks --all -n demo
kubectl delete serviceaccount --all -n demo
kubectl delete deploymemt --all -n demo

kubectl create namespace demo
kubectl apply -f resources/sa.yml -n demo
kubectl apply -f tasks/buildah-push.yml -n demo
kubectl apply -f runtasks/buildah-push-local-registry.yml -n demo
