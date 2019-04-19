#!/usr/bin/env bash

mkdir -p ~/go/{bin,pkg,src}
echo 'export GOPATH="$HOME/go"' >> ~/.bashrc
echo 'export PATH="$PATH:${GOPATH//://bin:}/bin"' >> ~/.bashrc
source ~/.bashrc

console_dir=/home/centos/go/src/github.com/openshift/console
if [[ ! -e $console_dir ]]; then
    mkdir -p $console_dir
    go get github.com/openshift/console && cd /home/centos/go/src/github.com/openshift/console
    ./build.sh
else
    echo "Directory exists"
fi

cd $console_dir
export KUBECONFIG=/root/.kube/config
source ./contrib/environment.sh
./bin/bridge
