# Instructions to install OpenShift using the Ansible OpenShift playbook 

## Prerequisite

  - Linux VM (CentOS7, ...) running, that you can ssh on port 22 and where your public key has been imported
  - Ansible [2.4](http://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

## Instructions

- First git clone the `OpenShift Ansible` project locally using the branch corresponding to the version of ocp you want to install

  ```bash
  echo "#### Git clone openshift ansible"
  if [ ! -d "openshift-ansible" ]; then
    git clone -b release-3.9 https://github.com/openshift/openshift-ansible.git
  fi
  ```

- Generate the inventory host file containing the parameters used by the `openshift` like the IP address of the VM to ssh.

  ```bash
  ansible-playbook playbook/generate_inventory.yml -e ip_address=192.168.99.50
  ```
  
  **WARNING**: Take care to supply the correct IP address in the corresponding argument !
  
  The inventory is later user by the [official](https://github.com/openshift/openshift-ansible) Openshift Ansible installation playbook to customize the setup
  If you would like to change some of the options, then first modify the template file located here - `roles/generate_inventory/templates/cloud.inventory.j2`
  before running the `playbook/generate_inventory.yml` role
  
  Furthermore, the above command will generate an inventory file that will use `root` as `ansible_user`.
  If another user other than `root` is to be used for accessing the machine over ssh, you can pass the `username` variable like so:
  
  ```bash
  ansible-playbook playbook/generate_inventory.yml -e ip_address=192.168.99.50 -e username=centos
  ```

- Install OpenShift

  Execute the following Ansible commands to first check if the VM where OpenShift must be installed conforms to the prerequisites and next download the docker images, create the etc service, ...
  
  ```bash
  ansible-playbook -i inventory/cloud_host openshift-ansible/playbooks/prerequisites.yml
  ansible-playbook -i inventory/cloud_host openshift-ansible/playbooks/deploy_cluster.yml
  ```
  
  If the `ansible_user` that is has been set in the inventory is not `root`, then the `--become` flag needs to be added to both
  of the above commands 
  
  **REMARK** : Customization of the installation (inventory file generated) is possible by changing the variables found in `inventory/cloud_host` from the command line using Ansible's `-e` syntax.