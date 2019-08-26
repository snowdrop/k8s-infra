# Using oc cluster up
hcloud server delete dabou1
hcloud server create --name dabou1 --type cx41 --image centos-7 --ssh-key snowdrop  --user-data-from-file ../virtualbox/build-centos-iso/user-data
IP_HETZNER=$(hcloud server describe dabou1 -o json | jq -r .public_net.ipv4.ip)
ssh-keygen -R $IP_HETZNER
sleep 20s
ssh root@$IP_HETZNER

cat /var/log/cloud-init.log | more
 

PUBLIC_IP=$(ifconfig eth0 | sed -En 's/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
version=3.11
mkdir -p /var/lib/origin/openshift.local.clusterup
echo -e '{ \n   "insecure-registries" : [ "172.30.0.0/16" ],\n   "hosts" : [ "unix://", "tcp://0.0.0.0:2376" ]\n}' > /etc/docker/daemon.json
systemctl restart docker

wget https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
tar -vxf openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
sudo cp openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit/oc /usr/local/bin

# oc cluster up --tag=v${version} \
#   --base-dir="/var/lib/origin/openshift.local.clusterup" \
#   --public-hostname=${PUBLIC_IP} \
#   --skip-registry-check=true \
#   --enable=[-sample-templates]
# oc cluster down
  
hcloud server create-image --description "oc client" --type snapshot dabou1 
Image 7050052 created from server 3162121

ID_IMAGE=$(hcloud image list | grep "oc client" | cut -d" " -f 1)
hcloud server delete dabou1
hcloud server create --name dabou1 --type cx41 --image $ID_IMAGE --ssh-key snowdrop

IP_HETZNER=$(hcloud server describe dabou1 -o json | jq -r .public_net.ipv4.ip)
ssh root@$IP_HETZNER

PUBLIC_IP=$(ifconfig eth0 | sed -En 's/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
version=3.11
mkdir -p /var/lib/origin/openshift.local.clusterup
echo -e '{ \n   "insecure-registries" : [ "172.30.0.0/16" ],\n   "hosts" : [ "unix://", "tcp://0.0.0.0:2376" ]\n}' > /etc/docker/daemon.json
systemctl restart docker

wget https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
tar -vxf openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
sudo cp openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit/oc /usr/local/bin

STARTTIME=$(date +%s)
oc cluster up \
  --tag=v${version} \
  --base-dir="/var/lib/origin/openshift.local.clusterup" \
  --public-hostname=${PUBLIC_IP} \
  --skip-registry-check=true \
  --enable=[-sample-templates]
ENDTIME=$(date +%s)
echo "It took $(($ENDTIME - $STARTTIME)) seconds to complete this task..."

#ansible-playbook playbook/generate_inventory.yml -e ip_address=$IPCloud -e type=simple
#ansible-playbook -i inventory/simple_host playbook/cluster.yml --tags "up" -e ansible_os_family=RedHat -e openshift_release_tag_name=v3.11.0
#ansible-playbook -i inventory/simple_host playbook/post_installation.yml -e openshift_admin_pwd=admin --tags "enable_cluster_role"
  
DON'T WORK
https://docs.okd.io/latest/getting_started/administrators.html#running-in-a-docker-container  


# Using openshift ansible playbook

hcloud floating-ip create --type ipv4 --server dabou1
Floating IP 91243 created

hcloud server delete dabou1
hcloud server create --name dabou1 --type cx31 --image centos-7 --ssh-key snowdrop --user-data-from-file ../virtualbox/build-centos-iso/user-data
IP_HETZNER=$(hcloud server describe dabou1 -o json | jq -r .public_net.ipv4.ip)


ansible-playbook playbook/generate_inventory.yml -e ip_address=$IP_HETZNER
ansible-playbook -i inventory/cloud_host openshift-ansible/playbooks/prerequisites.yml
ansible-playbook -i inventory/cloud_host openshift-ansible/playbooks/deploy_cluster.yml -e openshift_install_examples=false
ansible-playbook -i inventory/cloud_host playbook/post_installation.yml -e openshift_admin_pwd=admin --tags "enable_cluster_role" 
hcloud server create-image --description "ocp3 created with openshift-ansible" --type snapshot dabou1 
ID_IMAGE=$(hcloud image list | grep "ocp3 cluster" | cut -d" " -f 1)
hcloud server create --name dabou1 --type cx31 --image $ID_IMAGE --ssh-key snowdrop

IP_HETZNER=$(hcloud server describe dabou1 -o json | jq -r .public_net.ipv4.ip)
open https://$IP_HETZNER:8443/console

ssh centos@$IP_HETZNER
