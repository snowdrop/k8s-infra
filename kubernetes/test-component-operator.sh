#!/usr/bin/env bash

#
# Bash script deploying 2 Components - Microservices where the fruit-client-sb will call a fruit-backend-sb spring boot application
# where also a PostGreSQL database is created using the OABroker
#
git_component_dir=/home/centos/component-operator
if [[ ! -e $git_component_dir ]]; then
  git clone https://github.com/snowdrop/component-operator.git
else
  echo "Component Operator Demo git repo already exists"
fi

kubectl create ns component-operator --dry-run=true -o yaml | kubectl apply -f -
kubectl create -f component-operator/deploy/sa.yaml -n component-operator  --dry-run=true -o yaml | kubectl apply -f -
kubectl create -f component-operator/deploy/cluster-rbac.yaml -n component-operator --dry-run=true -o yaml | kubectl apply --validate=false -f -
kubectl create -f component-operator/deploy/crds/crd.yaml --dry-run=true -o yaml | kubectl apply -f -
kubectl create -f component-operator/deploy/operator.yaml -n component-operator --dry-run=true -o yaml | kubectl apply -f -

kubectl create ns demo --dry-run=true -o yaml | kubectl apply -f -
cat <<EOF | kubectl create -n demo -f -
---
apiVersion: "v1"
kind: "List"
items:
- apiVersion: "component.k8s.io/v1alpha1"
  kind: "Component"
  metadata:
    annotations:
      app.openshift.io/java-app-jar: "fruit-backend-sb-0.0.1-SNAPSHOT.jar"
      app.openshift.io/runtime-image: "fruit-backend-sb"
      app.openshift.io/git-ref: "master"
      app.openshift.io/git-dir: "fruit-backend-sb"
      app.openshift.io/artifact-copy-args: "'*.jar'"
      app.openshift.io/component-name: "fruit-backend-sb"
      app.openshift.io/git-uri: "'https://github.com/snowdrop/component-operator-demo.git'"
    labels:
      app: "fruit-backend-sb"
      version: "0.0.1-SNAPSHOT"
      group: "dabou"
    name: "fruit-backend-sb"
  spec:
    deploymentMode: "innerloop"
    runtime: "spring-boot"
    version: "1.5.15.RELEASE"
    exposeService: true
    envs:
    - name: "SPRING_PROFILES_ACTIVE"
      value: "openshift-catalog"
    links:
    - kind: "Secret"
      name: "Secret to be injected as EnvVar using Service's secret"
      targetComponentName: "fruit-backend-sb"
      ref: "postgresql-db"
    services:
    - name: "postgresql-db"
      class: "dh-postgresql-apb"
      plan: "dev"
      secretName: "postgresql-db"
      parameters:
      - name: "postgresql_user"
        value: "luke"
      - name: "postgresql_password"
        value: "secret"
      - name: "postgresql_database"
        value: "my_data"
      - name: "postgresql_version"
        value: "9.6"
EOF

cat <<EOF | kubectl create -n demo -f -
---
apiVersion: "v1"
kind: "List"
items:
- apiVersion: "component.k8s.io/v1alpha1"
  kind: "Component"
  metadata:
    name: "fruit-client-sb"
  spec:
    deploymentMode: "innerloop"
    runtime: "spring-boot"
    version: "1.5.15.RELEASE"
    exposeService: true
    links:
    - kind: "Env"
      name: "Env var to be injected within the target component -> fruit-backend"
      targetComponentName: "fruit-client-sb"
      envs:
      - name: "OPENSHIFT_ENDPOINT_BACKEND"
        value: "http://fruit-backend-sb:8080/api/fruits"
      ref: ""
EOF
