#!/usr/bin/env bash

kubectl delete taskruns --all -n demo
kubectl delete tasks --all -n demo

kubectl delete secret --all -n demo
kubectl delete sa --all -n demo
kubectl delete deployment --all -n demo
