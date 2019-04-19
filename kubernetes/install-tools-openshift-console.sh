#!/usr/bin/env bash

echo "##############"
echo "Install Golang"
echo "##############"
rpm --import https://mirror.go-repo.io/centos/RPM-GPG-KEY-GO-REPO
curl -s https://mirror.go-repo.io/centos/go-repo.repo | tee /etc/yum.repos.d/go-repo.repo
yum -y install wget golang

echo "##############"
echo "Configure \$GOPATH, ..."
echo "##############"
mkdir -p ~/go/{bin,pkg,src}
echo 'export GOPATH="$HOME/go"' >> ~/.bashrc
echo 'export PATH="$PATH:${GOPATH//://bin:}/bin"' >> ~/.bashrc
source ~/.bashrc

echo "#########################"
echo "Install yarn, nodejs, jq"
echo "#########################"
curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
curl --silent --location https://rpm.nodesource.com/setup_8.x | sudo bash -
yum -y install yarn

wget -O jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod +x ./jq
mv jq /usr/bin
