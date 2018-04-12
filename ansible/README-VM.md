# Installation of OpenShift Cluster using Ansible Playbooks

## Prerequisites

You need to create a VM with the process described in `virtualbox/README`

The instructions in that section result in the creation of VM running CentOS 7.
The IP address of the machine is pinned to `192.168.99.50` and the machine is accessible via ssh using `root/centos` credentials


To install Openshift on the VM, follow one of the following methods

## Ansible executed within the target vm

- Follow these instructions when the vm is ready

```bash
echo "## Add yum repo needed to download rpms"
ssh root@192.168.99.50 "mkdir -p /root/install"

echo "#### Clone project"
ssh root@192.168.99.50 "git clone https://github.com/snowdrop/cloud-native-infra.git install"

ssh root@192.168.99.50 "cd install/ansible && git clone -b release-3.7 https://github.com/openshift/openshift-ansible.git"
ssh root@192.168.99.50 "cd install/ansible && ansible-playbook playbook/generate_inventory.yml -e ip_address=192.168.99.50 -e use_local=true"
ssh root@192.168.99.50 "cd install/ansible && ansible-playbook -i inventory/cloud_host openshift-ansible/playbooks/byo/config.yml"
```

## Ansible started locally

- Git clone `openshihift-ansible` project locally using version `3.7`
```bash
git clone -b release-3.7 https://github.com/openshift/openshift-ansible.git
```

- Generate inventory host file containing the definition about the OpenShift instance to be provisioned from a j2 template

```bash
ansible-playbook playbook/generate_inventory.yml -e ip_address=192.168.99.50
```

- Install the OpenShift All in One Cluster

```bash
ansible-playbook -i inventory/cloud_host openshift-ansible/playbooks/byo/config.yml -e openshift_node=masters
```

Customization of the installation is possible by changing the variables found in `inventory/cloud_host` from the command line using Ansible's `-e` syntax.
For example in order to enable installation of the service broker the following command could be executed

`ansible-playbook -i inventory/cloud_host openshift-ansible/playbooks/byo/config.yml -e openshift_enable_service_catalog=true`

## Common tasks

- Create OpenShift cluster
```bash
ansible-playbook -i inventory openshift-ansible/playbooks/byo/config.yml
```

** NOTES **

- If during the execution of the byo playbook, the service-catalog role reports this error, then relaunch the following playbook
```bash
TASK [ansible_service_broker : Create the Broker resource in the catalog] **************************************************************************************************************************************************************************
fatal: [192.168.99.50]: FAILED! => {"changed": false, "failed": true, "msg": {"cmd": "/usr/bin/oc create -f /tmp/brokerout-dJmL1S -n default", "results": {}, "returncode": 1, "stderr": "error: unable to recognize \"/tmp/brokerout-dJmL1S\": no matches for servicecatalog.k8s.io/, Kind=ClusterServiceBroker\n", "stdout": ""}}

ansible-playbook -i inventory openshift-ansible/playbooks/byo/openshift-cluster/service-catalog.yml
```
- As the `APB` pods could not be deployed correctly, then relaunch the `APB` and `APB etcd` deployments from the console or terminal

- Post installation steps

  - Enable cluster admin role for `admin` user
  - Setup persistence using `HostPath` mounted volumes `/tmp/pv001 ...`,
  - Create `infra` project
  - Install Nexus, Jenkins  

```bash
ansible-playbook -i inventory playbook/post_installation.yml -e openshift_node=masters -e openshift_admin_pwd=admin
```

## Old content not used

- Secure copy your public key to the vm
```bash
ssh-keygen -R "[127.0.0.1]:5222"
sshpass -f pwd.txt ssh -o StrictHostKeyChecking=no root@127.0.0.1 -p 5222 "mkdir ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
sshpass -f pwd.txt ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub root@127.0.0.1 -p 5222
```
