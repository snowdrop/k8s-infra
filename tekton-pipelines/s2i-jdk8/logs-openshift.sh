#!/usr/bin/env bash

# kubectl logs -l tekton.dev/task=s2i-jdk8

echo "#### Build step"
echo "kubectl logs -l tekton.dev/task=s2i-jdk8 -c build-step-s2ibuild"
kubectl logs -l tekton.dev/task=s2i-jdk8 -c build-step-s2ibuild

echo "#### Push step"
echo "kubectl logs -l tekton.dev/task=s2i-jdk8 -c build-step-docker-push"
kubectl logs -l tekton.dev/task=s2i-jdk8 -c build-step-docker-push
