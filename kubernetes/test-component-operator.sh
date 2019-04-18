#!/usr/bin/env bash

git clone https://github.com/snowdrop/component-operator.git
kubectl create ns component-operator
kubectl create -f component-operator/deploy/sa.yaml -n component-operator
kubectl create -f component-operator/deploy/cluster-rbac.yaml -n component-operator
kubectl create -f component-operator/deploy/crds/crd.yaml
kubectl create -f component-operator/deploy/operator.yaml -n component-operator

kubectl create ns demo
cat <<EOF | kubectl create -f -
---
apiVersion: "v1"
kind: "List"
items:
- apiVersion: "component.k8s.io/v1alpha1"
  kind: "Component"
  metadata:
    name: "fruit-backend-sb"
    namespace: demo
    annotations:
      app.openshift.io/artifact-copy-args: '*.jar'
      app.openshift.io/component-name: fruit-backend-sb
      app.openshift.io/git-dir: fruit-backend-sb
      app.openshift.io/git-ref: master
      app.openshift.io/git-uri: 'https://github.com/snowdrop/component-operator-demo.git'
      app.openshift.io/java-app-jar: fruit-backend-sb-0.0.1-SNAPSHOT.jar
      app.openshift.io/runtime-image: fruit-backend-sb
  spec:
    runtime: spring-boot
    version: 1.5.15.RELEASE
    deploymentMode: "innerloop"
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
