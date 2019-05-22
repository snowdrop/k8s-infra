#!/usr/bin/env bash

# s2i build as dockerfile -> buildah bud -> buildah push
# Using external quay.io registry
kubectl apply -f resources/docker-secret.yml
kubectl apply -f resources/sa-secret.yml

kubectl apply -f tasks/buildah-push.yml
kubectl apply -f runtasks/buildah-push.yml

