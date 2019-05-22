#!/usr/bin/env bash

kubectl delete taskruns --all -n demo
kubectl delete tasks --all -n demo
kubectl delete serviceaccount --all -n demo
kubectl delete deploymemt --all -n demo

# s2i build as dockerfile -> buildah bud -> buildah push
# Using external quay.io registry
kubectl create namespace demo

kubectl apply -f resources/docker-secret.yml -n demo
kubectl apply -f resources/sa-secret.yml -n demo

kubectl apply -f tasks/buildah-push.yml -n demo
kubectl apply -f runtasks/buildah-push-quay.io.yml -n demo

