# Instructions to install OpenShift using a cluster ansible role

- Prerequisite:
  - Linux VM (CentOS7, ...) that you can ssh and where your public key has been imported
  - Ansible [2.4](http://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

- To create an all in one cluster using oc cluster command, then it is required to have a CentOS vm that you can access using ssh

  First you need to generate the inventory file. If the the IP address of the VM is `192.168.99.50`, then the command to be executed 
  
  ```bash
  cd ansible/
  ansible-playbook playbook/generate_inventory.yml -e ip_address=192.168.99.50 -e type=simple
  ```

- Next you can execute one of the role available to `up`, `down` or `clean` the cluster created

  ```bash
  ansible-playbook -i inventory/simple_host playbook/cluster.yml --tags "up" 
  ```

- To override the default parameters of the `oc cluster up` command, then pass extra vars within the command 

  ```bash
  ansible-playbook -i inventory/simple_host playbook/cluster.yml \
    -e openshift_release_tag_name=v3.9.0 \
    -e "@extra_vars.yml" \
    --tags "up" 
  ```

- To stop the cluster, then run this command

  ```bash
  ansible-playbook -i inventory/simple_host playbook/cluster.yml --tags "down" 
  ```
  
- To clean up the environment* before to re-install the OpenShift cluster, use the `clean` parameter

  ```bash
  ansible-playbook -i inventory/simple_host playbook/cluster.yml --tags "clean" 
  ```

**NOTE**: The clean up role will stop the docker daemon, remove folders containing config persisted and finally remove the tmpfs partitions