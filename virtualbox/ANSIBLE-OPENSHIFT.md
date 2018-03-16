# Installation of OpenShift Cluster using Ansible Playbooks

## Ansible executed within the target vm

- Follow these instructions when the vm is ready

```bash
echo "## Add yum repo needed to download rpms"
ssh root@root@192.168.99.50 "yum-config-manager --enable rhel-7-server-ose-3.7-rpms"
ssh root@root@192.168.99.50 "yum-config-manager --enable rhel-7-server-rh-common-rpms"

echo "#### Copy project -> TODO : Should be converted into a git clone command"
scp -r /Users/dabou/Code/rhoar/cloud-native/infra/virtualbox/playbook root@192.168.99.50:/root/install
scp /Users/dabou/Code/rhoar/cloud-native/infra/virtualbox/inventory-local root@192.168.99.50:/root/install/inventory

ssh root@192.168.99.50 "cd install && git clone -b release-3.7 https://github.com/openshift/openshift-ansible.git"
ssh root@192.168.99.50 "ANSIBLE_LOG_PATH=/var/log/ansible.log ansible-playbook -i inventory openshift-ansible/playbooks/byo/config.yml"
ssh root@192.168.99.50 "tail -f /var/log/ansible.log"
```

## Ansible started locally

- Git clone `openshihift-ansible` project locally using version `3.7`
```bash
git clone -b release-3.7 https://github.com/openshift/openshift-ansible.git
```

- Import RPMs of OpenShift 3.7 as they can't be downloaded by Ansible playbook
```bash
ansible-playbook -i inventory playbook/install-package.yaml -e openshift_node=masters
```

Remark : As some rpms packages could not be uploaded correctly during the first execution of the playbook, then re-execute the command !

## Common tasks

- Create OpenShift cluster
```bash
ANSIBLE_LOG_PATH=/var/log/ansible.log ansible-playbook -i inventory openshift-ansible/playbooks/byo/config.yml
```

** NOTES **

- If during the execution of the byo playbook, the service-catloag role reports this error, then relaunch the following playbook
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
ansible-playbook -i inventory playbook/post_installation.yml -e openshift_node=masters
```

## Old content not used

- Secure copy your public key to the vm
```bash
ssh-keygen -R "[127.0.0.1]:5222"
sshpass -f pwd.txt ssh -o StrictHostKeyChecking=no root@127.0.0.1 -p 5222 "mkdir ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
sshpass -f pwd.txt ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub root@127.0.0.1 -p 5222
```
