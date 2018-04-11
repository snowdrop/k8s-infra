# Instructions to install OpenShift using oc cluster command

- To create an all in one cluster using oc cluster command, then it is required to have a CentOS vm that you can access using ssh

First you need to generate the inventory file. If the the IP address of the VM is `192.168.99.50`, then the command is 

```bash
~/MyProjects/cloud-native/infra/ansible
ansible-playbook playbook/generate_inventory.yml -e ip_address=192.168.99.50 -e type=simple
```

- Next you can execute one of the role created to `up`, `down` or `clean` the cluster created

```bash
ansible-playbook -i inventory/simple_host playbook/cluster.yml --tags "up" 
```

- To override the default parameters of the `oc cluster up` command, then pass extra vars within the command 
```bash
ansible-playbook -i inventory/simple_host playbook/cluster.yml -e openshift_release_tag_name=v3.9.0 --tags "up" 
-e "@extra_vars.yml"
```

- To stop the cluster, then run this command
```bash
ansible-playbook -i inventory/simple_host playbook/cluster.yml --tags "down" 
```
- To clean up the environment* before to re-install the OpenShift cluster, use the `clean` parameter
```bash
ansible-playbook -i inventory/simple_host playbook/cluster.yml --tags "clean" 
```

* : stop docker daemon, remove tmpfs partitions

# Post installation

The post_installation playbook performs various tasks, like enabling the cluster admin user, installing Istio etc.
Make sure that the `openshift_admin_pwd` is specified when invoking the command. 

```bash
ansible-playbook -i inventory/simple_host playbook/post_installation.yml -e openshift_admin_pwd=admin
```
