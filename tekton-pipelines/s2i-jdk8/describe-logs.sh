#!/usr/bin/env bash

kubectl describe pod -n kube-system -l tekton.dev/task=s2i-jdk8

kubectl logs -n kube-system -l tekton.dev/task=s2i-jdk8 -c build-step-build
kubectl logs -n kube-system -l tekton.dev/task=s2i-jdk8 -c build-step-push
