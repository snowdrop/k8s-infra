#!/usr/bin/env bash

# Install Docker CE
## Set up the repository
### Install required packages.
yum -y install yum-utils device-mapper-persistent-data lvm2

### Add Docker repository.
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

## Install Docker CE.
yum -y install docker-ce-18.06.2.ce

## Create /etc/docker directory.
mkdir -p /etc/docker

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=cgroupfs"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart Docker
systemctl daemon-reload
systemctl enable docker.service
systemctl restart docker
