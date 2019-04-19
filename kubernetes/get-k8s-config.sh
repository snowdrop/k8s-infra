#!/usr/bin/env bash

ip=${1:-10.8.250.104}

SERVER=https://${ip}:6443
SECRET_NAME=$(kubectl -n kube-system get secret | grep default-token | awk '{print $1}')
KUBE_CMD="kubectl -n kube-system get secret/$SECRET_NAME"

CA=$($KUBE_CMD -o jsonpath='{.data.ca\.crt}')
TOKEN=$($KUBE_CMD -o jsonpath='{.data.token}' | base64 -d)
NAMESPACE=$($KUBE_CMD -o jsonpath='{.data.namespace}' | base64 -d)

echo "
apiVersion: v1
kind: Config
clusters:
- name: default-cluster
  cluster:
    certificate-authority-data: ${CA}
    server: ${SERVER}
contexts:
- name: default-context
  context:
    cluster: default-cluster
    namespace: ${NAMESPACE}
    user: default-user
current-context: default-context
users:
- name: default-user
  user:
    token: ${TOKEN}
"
