#!/usr/bin/env bash

export DOCKER_TLS_VERIFY=
export DOCKER_HOST=tcp://192.168.99.50:2376

KUBEDB_VERSION=0.12.0
IMAGE="v1.13.10@sha256:2f5f882a6d0527a2284d29042f3a6a07402e1699d792d0d5a9b9a48ef155fa2a"
# IMAGE="v1.14.6@sha256:464a43f5cf6ad442f100b0ca881a3acae37af069d5f96849c1d06ced2870888d"

kind delete cluster --name halkyon
kind create cluster --name halkyon \
  --config kind-config.yml \
  --image kindest/node:${IMAGE}
export KUBECONFIG="$(kind get kubeconfig-path --name="halkyon")"
kubectl cluster-info

helm init
until kubectl get pods -n kube-system -l name=tiller | grep 1/1; do sleep 1; done
kubectl create clusterrolebinding tiller-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default

helm repo add appscode https://charts.appscode.com/stable/
helm repo update
helm install appscode/kubedb \
   --name kubedb-operator \
   --version ${KUBEDB_VERSION} \
   --namespace kubedb \
   --set apiserver.enableValidatingWebhook=false,apiserver.enableMutatingWebhook=false

TIMER=0
until kubectl get crd elasticsearchversions.catalog.kubedb.com memcachedversions.catalog.kubedb.com mongodbversions.catalog.kubedb.com mysqlversions.catalog.kubedb.com postgresversions.catalog.kubedb.com redisversions.catalog.kubedb.com || [[ ${TIMER} -eq 60 ]]; do
  sleep 10
  TIMER=$((TIMER + 1))
done

helm install appscode/kubedb-catalog \
  --name kubedb-catalog \
  --version ${KUBEDB_VERSION} \
  --namespace kubedb \
  --set catalog.postgres=true,catalog.elasticsearch=false,catalog.etcd=false,catalog.memcached=false,catalog.mongo=false,catalog.mysql=false,catalog.redis=false
