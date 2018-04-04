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

# Post installation

```bash
ansible-playbook -i inventory/simple_host playbook/post_installation.yml -e "@extra_vars.yml"
```
