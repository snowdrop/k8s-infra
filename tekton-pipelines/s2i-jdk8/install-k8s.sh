#!/usr/bin/env bash

# s2i build using docker
#kubectl apply -f resources/sa.yml
#kubectl apply -f tasks/clone-build.yml
#kubectl apply -f tasks/clone-build-push.yml
#kubectl apply -f runtasks/build.yml
# kubectl apply -f runtasks/buildah.yml

# s2i build as dockerfile -> buildah bud -> buildah push
kubectl apply -f resources/docker-secret.yml
kubectl apply -f resources/sa-secret.yml

kubectl apply -f tasks/buildah.yml
kubectl apply -f tasks/buildah-push.yml

kubectl apply -f runtasks/buildah-push.yml

