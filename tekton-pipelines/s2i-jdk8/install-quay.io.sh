#!/usr/bin/env bash

oc delete taskruns --all
oc delete tasks --all
oc delete serviceaccount --all
oc delete deploymemt --all

# s2i build as dockerfile -> buildah bud -> buildah push
# Using external quay.io registry
kubectl create namespace demo

kubectl apply -f resources/docker-secret.yml -n demo
kubectl apply -f resources/sa-secret.yml -n demo

kubectl apply -f tasks/buildah-push.yml -n demo
kubectl apply -f runtasks/buildah-push-quay.io.yml -n demo

