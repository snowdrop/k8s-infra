# Instructions to install OpenShift using a cluster ansible role

## Prerequisite

  - Linux VM (CentOS7, ...) running, that you can ssh on port 22 and where your public key has been imported
  - Ansible [2.4](http://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

## Instructions

- To create an all in one cluster using the oc cluster role, then it is required to first generate an inventory file.
  If the the IP address of the VM is `192.168.99.50`, then the command to be executed is
  
  ```bash
  cd ansible/
  ansible-playbook playbook/generate_inventory.yml -e ip_address=192.168.99.50 -e type=simple
  ```
  
**NOTE**: This step is not needed if the target VM was created using the [create-vm.sh](../virtualbox/create-vm.sh) script
since the script automatically invokes said command once the VM has been created  

- Next you can execute one of these tags to `up`, `down` or `clean` the cluster created

  ```bash
  ansible-playbook -i inventory/simple_host playbook/cluster.yml --tags "up" 
  ```

- To override the default parameters of the `oc cluster up` command, then pass extra vars within the command 

  ```bash
  ansible-playbook -i inventory/simple_host playbook/cluster.yml \
    -e openshift_release_tag_name=v3.10.0 \
    -e "@extra_vars.yml" \
    --tags "up" 
  ```

- To add enable the Ansible Service Broker, set `enable_asb` to `true` like so

  ```bash
  ansible-playbook -i inventory/simple_host playbook/cluster.yml --tags "up" -e enable="service-catalog,automation-service-broker" 
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
