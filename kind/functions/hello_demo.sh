#!/usr/bin/env bash

pull_push_hello() {
  echo "==== Pull, tag and push to kind-registry:5000 the hello-app"
  docker pull gcr.io/google-samples/hello-app:1.0
  docker tag gcr.io/google-samples/hello-app:1.0 ${reg_server}:${reg_port}/hello-app:1.0
  docker push ${reg_server}:${reg_port}/hello-app:1.0
}

deploy_hello() {
  reg_username=${reg_username:-admin}
  reg_password=${reg_password:-snowdrop}

  kubectl delete secret local-registry -n default
  kubectl create secret docker-registry local-registry \
    -n default \
    --docker-server='"https://${reg_name}:5000/' \
    --docker-username=$reg_username \
    --docker-password=$reg_password

  kubectl delete deployment/hello-app -n default
  kubectl create deployment hello-app --image=${reg_server}:${reg_port}/hello-app:1.0 --replicas=1 -n default
  kubectl patch deployment hello-app -n default -p '{"spec": {"template": {"spec": {"imagePullSecrets": [{"name": "local-registry"}]}}}}'

  watch "kubectl -n default describe pod -l app=hello-app | grep -A20 Events"
}
