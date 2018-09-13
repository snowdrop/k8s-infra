
# Command to provision with oc cluster up 
# 
# cd openshift-infra
# ./virtualbox/create-vm.sh -i ~/images -m 5000
# ssh root@192.168.99.50 'bash -s' < sandbox/cluster_up.sh

echo "==============================="
echo "Download oc client, untar it"
echo "==============================="
wget -O- https://github.com/openshift/origin/releases/download/v3.10.0/openshift-origin-client-tools-v3.10.0-dd10d17-linux-64bit.tar.gz | tar vxz
cd openshift-origin-client-tools-v3.10.0-dd10d17-linux-64bit/
export PATH=$(pwd):$PATH

echo "==============================="
echo "Configure docker to be insecure"
echo "==============================="
echo -e '{ \n   "insecure-registries" : [ "172.30.0.0/16" ],\n   "hosts" : [ "unix://", "tcp://0.0.0.0:2376" ]\n}' > /etc/docker/daemon.json
systemctl restart docker

echo "==============================="
echo "Bootstrap oc"
echo "==============================="
oc cluster up --public-hostname=192.168.99.50

echo "==============================="
echo "Grant cluster-admin role to admin's user"
echo "==============================="
oc login -u system:admin
oc adm policy  add-cluster-role-to-user cluster-admin admin
oc login -u admin -p admin

echo "==============================="
echo "Enable OAB, Service catalog"
echo "==============================="
oc cluster add service-catalog
oc cluster add automation-service-broker