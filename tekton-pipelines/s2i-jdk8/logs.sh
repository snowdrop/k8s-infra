#!/usr/bin/env bash

# kubectl describe pod -n kube-system -l tekton.dev/task=s2i-jdk8

kubectl logs -n kube-system -l tekton.dev/task=s2i-jdk8

echo "#### Build step"
echo "kubectl logs -n kube-system -l tekton.dev/task=s2i-jdk8 -c build-step-s2ibuild"
kubectl logs -n kube-system -l tekton.dev/task=s2i-jdk8 -c build-step-s2ibuild

echo "#### Push step"
echo "kubectl logs -n kube-system -l tekton.dev/task=s2i-jdk8 -c build-step-docker-push"
kubectl logs -n kube-system -l tekton.dev/task=s2i-jdk8 -c build-step-docker-push
