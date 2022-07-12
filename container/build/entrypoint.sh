#!/bin/bash

if [[ -v SSH_ID_KEY ]] && [[ -d "${HOME}/.ssh" ]]; then
  echo "Configuring ssh-agent..."
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/${SSH_ID_KEY}
fi

if [ ! -d "/opt/volumes/k8s-infra" ]; then
  echo "/opt/volumes/k8s-infra volume is missing, fetching from the GitHub repository..."
  pushd /opt/volumes
  git clone --quiet git@github.com:snowdrop/k8s-infra.git
  popd
  # exit 1
fi

if [ ! -d "/opt/volumes/pass" ]; then
  echo "/opt/volumes/pass volume is missing, fetching from the GitHub repository..."
  pushd /opt/volumes
  git clone --quiet git@github.com:snowdrop/pass.git
  popd
  # exit 1
fi

if [ ! -d "/opt/volumes/gnupg" ]; then
  echo "/opt/volumes/gnupg volume is missing"
  exit 1
fi

if [ ! -d "${HOME}/.ssh" ]; then 
  echo "SSH folder is missing (${HOME}/.ssh). Mount the corresponding volume from the host."
  exit 1
fi

pushd /opt/volumes/k8s-infra/container/scripts

./ansibleRun.sh
