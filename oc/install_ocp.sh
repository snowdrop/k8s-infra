#!/usr/bin/env bash

echo "### Create daemon.json file to define extra docker parameters such as insecure-registries"
cat << EOF > /etc/docker/daemon.json
{
  "insecure-registries" : [ "172.30.0.0/16" ]
 }
EOF

echo "### Reload systemctl daemon and restart docker service."
systemctl daemon-reload
systemctl enable docker
systemctl restart docker

echo "## Create origin folder where we will download the oc binary and next install it under /usr/local/bin"
mkdir -p origin && cd origin
RELEASE="v3.7.0"
VERSION="v3.7.0-7ed6862"
URL="https://github.com/openshift/origin/releases/download/$RELEASE/openshift-origin-server-$VERSION-linux-64bit.tar.gz"
wget -O origin-server-$VERSION-linux-64bit.tar.gz ${URL}
tar -vxf origin-server-$VERSION-linux-64bit.tar.gz
mv openshift-origin-server-$VERSION-linux-64bit openshift-$RELEASE
cd openshift-$RELEASE/
export PATH="$(pwd)":$PATH

echo "#### Copy oc, kubectl binaries under /usr/local/bin"
yes | cp -rf oc /usr/local/bin
yes | cp -rf kubectl /usr/local/bin

echo "### Create a symbolic link between folders of Openshift and /etc/origin as this one is used by the ansible playbook to access master.yml config file"
ln -s /var/lib/openshift/config/ /etc/origin

echo "### Create Systemctl OpenShift service."
echo "### Parameters defined are :"
echo "### --version=v3.7.0"
echo "### --host-config-dir=/var/lib/openshift/config"
echo "### --host-data-dir=/var/lib/openshift/data"
echo "### --host-pv-dir=/tmp"
echo "### --host-volumes-dir=/var/lib/openshift/volumes"
echo "### --use-existing-config=true"
echo "### --public-hostname=192.168.99.50"
echo "### --routing-suffix=192.168.99.50.nip.io"
echo "### --loglevel=1"

cat > /etc/systemd/system/openshift.service << 'EOF'
[Unit]
Description=OpenShift oc cluster up Service
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/local/bin/oc cluster up --version=v3.7.0 --host-config-dir=/var/lib/openshift/config --host-data-dir=/var/lib/openshift/data --host-pv-dir=/tmp --host-volumes-dir=/var/lib/openshift/volumes --use-existing-config=true --public-hostname=192.168.99.50 --routing-suffix=192.168.99.50.nip.io --loglevel=1
ExecStop=/usr/local/bin/oc cluster down
WorkingDirectory=/var/lib/openshift
Restart=no
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=occlusterup
User=root
Type=oneshot
RemainAfterExit=yes
TimeoutSec=300

[Install]
WantedBy=multi-user.target
EOF

echo "### Create /var/lib/openshift/ folders"
mkdir -p /var/lib/openshift/{config,pv,data,volumes}
ln -s /var/lib/openshift/config/ /etc/origin

echo "### Disable selinux - required for persistent pod"
setenforce 0

echo "### Register OpenShift as a Systemctl service and start it !!!!!!"
systemctl enable openshift.service
systemctl start openshift.service