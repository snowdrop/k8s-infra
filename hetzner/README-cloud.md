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
hcloud server delete VM_NAME
hcloud server create --name VM_NAME --type cx41 --image centos-7 --ssh-key USER_KEY_NAME  --user-data-from-file ./scripts/user-data
```

You can ssh to the newly created vm using the following command
```bash
IP_HETZNER=$(hcloud server describe VM_NAME -o json | jq -r .public_net.ipv4.ip)
ssh-keygen -R $IP_HETZNER
sleep 20s
ssh root@$IP_HETZNER
```

## Using openshift ansible playbook

### Remote

We can provision the VM using ansible playbook by importing this project within the VM and next by executing this playbook as defined
within the bash script

```bash
ansible-playbook -i ./inventory/hetzner_vm playbook/cluster.yml \
    -e openshift_release_tag_name=v3.11.0 \
    -e public_ip_address="${hostIP}" \
    --tags "up" \
    2>&1
```

The scenario to create a VM and next to ssh the bash ansible script is the following: 

```bash
./scripts/create-user-data.sh
hcloud server create --name VM_NAME --type cx41 --image centos-7 --ssh-key USER_KEY_NAME --user-data-from-file ./scripts/user-data
IP_HETZNER=$(hcloud server describe VM_NAME -o json | jq -r .public_net.ipv4.ip)
sleep 90s
ssh-keygen -R $IP_HETZNER
while ! nc -z $IP_HETZNER 22; do echo "Wait till we can ssh..."; sleep 10; done
ssh -o StrictHostKeyChecking=no root@$IP_HETZNER 'while kill -0 $(cat /run/yum.pid) 2> /dev/null; do echo "Wait till yum process is released"; sleep 10; done;'
ssh -o StrictHostKeyChecking=no root@$IP_HETZNER 'bash -s' < ./scripts/post-installation.sh
ssh -o StrictHostKeyChecking=no root@$IP_HETZNER << EOF
hostIP=$(hostname -I | awk '{print $1}')
cd /tmp/infra/ansible
ansible-playbook -i ./inventory/hetzner_vm playbook/cluster.yml \
    -e openshift_release_tag_name="v${version}.0" \
    -e public_ip_address="${hostIP}" \
    --tags "up" \
    2>&1

echo "Enable cluster-admin role for admin user"
ansible-playbook -i ./inventory/hetzner_vm playbook/post_installation.yml \
     -e openshift_admin_pwd=admin \
     --tags "enable_cluster_role"

exit 0
EOF
```

### Locally

You can also if you prefer execute from this project the Ansible playbook. The commands to be executed are described here after

- Create a Hetzner cloud vm and wait till we can ssh
```bash
cd hetzner
./scripts/create-user-data.sh
hcloud server create \
  --name VM_NAME \
  --type cx41 \
  --image centos-7 \
  --ssh-key USER_KEY_NAME \
  --user-data-from-file ./scripts/user-data
IP_HETZNER=$(hcloud server describe VM_NAME -o json | jq -r .public_net.ipv4.ip)
ssh-keygen -R $IP_HETZNER
while ! nc -z $IP_HETZNER 22; do echo "Wait till we can ssh..."; sleep 10; done
```
- Execute the post installation script to install docker loike git, wget
```bash
ssh -o StrictHostKeyChecking=no root@$IP_HETZNER 'bash -s' < ./scripts/post-installation.sh
```

- Move to the ansible directory, generate the inventory file and run the playbook able to perform a `oc cluster up`
```bash
cd ../ansible
ansible-playbook playbook/generate_inventory.yml \
  -e ip_address=$IP_HETZNER \
  -e type=hetzner
ansible-playbook -i inventory/hetzner_host playbook/cluster.yml \
   -e public_ip_address=$(hcloud server describe VM_NAME -o json | jq -r .public_net.ipv4.ip) \
   -e ansible_os_family="RedHat" \
   --tags "up"
```
