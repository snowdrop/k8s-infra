# Hetzner Cloud

The following guide details how to provision a Hetzner VM using the [Hetzner Cloud APi](https://docs.hetzner.cloud/#overview) or the  [Hetzner Cloud client](https://github.com/hetznercloud/cli) that you can install using the 
following brew command `brew install hcloud`
To getting started, you must get a Token for your API as described [here](https://docs.hetzner.cloud/#overview-getting-started).

In order to create a vm and next access it, you must first import your ssh public key using this command
```bash
hcloud ssh-key create --name USER_KEY_NAME --public-key-from-file ~/.ssh/id_rsa.pub
```

## Using oc cluster up

In order to configure and install different software and to deploy openshift using `oc cluster up`,
you must execute locally the bash script `./scripts/create-user-data.sh` responsible to populate the `user-data` file
that cloud-init will use on the remote vm during the creation of the vm.

```bash
./scripts/create-user-data.sh
```

Next create a Hetzner cloud vm using as parameters the `user-data` file created previously and your public key imported

```bash
hcloud server delete dabou1
hcloud server create --name dabou1 --type cx41 --image centos-7 --ssh-key USER_KEY_NAME  --user-data-from-file ./scripts/user-data
```

You can ssh to the newly created vm using the following command
```bash
IP_HETZNER=$(hcloud server describe dabou1 -o json | jq -r .public_net.ipv4.ip)
ssh-keygen -R $IP_HETZNER
sleep 20s
ssh root@$IP_HETZNER
```

## Using openshift ansible playbook

```bash
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
```
