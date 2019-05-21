#!/usr/bin/env bash


kubectl delete taskrun.tekton.dev/s2i-springboot-example
kubectl delete task.tekton.dev/s2i-jdk8
