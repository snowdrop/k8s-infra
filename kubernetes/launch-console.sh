#!/usr/bin/env bash

mkdir -p ~/go/{bin,pkg,src}
echo 'export GOPATH="/home/centos/go"' >> ~/.bashrc
echo 'export PATH="$PATH:${GOPATH//://bin:}/bin"' >> ~/.bashrc
source ~/.bashrc
sudo chown -R centos:centos /home/centos

console_dir=/home/centos/go/src/github.com/openshift/console
if [[ ! -e $console_dir ]]; then
    mkdir -p $console_dir
    git clone https://github.com/openshift/console.git /home/centos/go/src/github.com/openshift/console && cd /home/centos/go/src/github.com/openshift/console
    ./build.sh
else
    echo "Directory exists. No need to clone again the Openshift Console"
fi

cd $console_dir
export KUBECONFIG=/root/.kube/config
source ./contrib/environment.sh
nohup ./bin/bridge &>/dev/null &
