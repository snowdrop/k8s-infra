#!/usr/bin/env bash

# OpenShift
# s2i build as dockerfile -> buildah bud -> buildah push
# Internal Docker registry
#

oc delete taskruns --all
oc delete tasks --all
oc delete serviceaccount --all
oc delete deploymemt --all

oc adm policy add-scc-to-group anyuid system:authenticated
oc apply -f resources/sa.yml
# oc adm policy add-scc-to-user anyuid system:serviceaccount:build-bot:tekton-pipelines-controller
oc adm policy add-scc-to-user privileged -z build-bot
oc adm policy add-role-to-user edit -z build-bot

oc new-project demo
oc apply -f tasks/buildah-push.yml
oc apply -f runtasks/buildah-push-local-registry.yml

