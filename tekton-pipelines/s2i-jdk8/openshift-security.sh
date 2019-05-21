#!/usr/bin/env bash

oc adm policy add-scc-to-user privileged -z build-bot
oc adm policy add-role-to-user edit -z build-bot
