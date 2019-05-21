#!/usr/bin/env bash

oc apply -f resources/sa-secret.yml
oc adm policy add-scc-to-user privileged -z build-bot
oc adm policy add-role-to-user edit -z build-bot

oc apply -f tasks/clone-build-push.yml
oc apply -f runtasks/build-push.yml
