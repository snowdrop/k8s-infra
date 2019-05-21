#!/usr/bin/env bash

kubectl apply -f resources/docker-secret.yml
kubectl apply -f resources/sa.yml
kubectl apply -f tasks/clone-build.yml
kubectl apply -f runtasks/springboot-example.yml
