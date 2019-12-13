## Instructions

To let the `Ansible tool` to access the VM running locally or remotely, it is needed to have an [`inventory`](https://docs.ansible.com/ansible/2.3/intro_inventory.html) file.
Some of the bash scripts part of this project will generate it by default but if this is not the case, you can create 
it using the following role where you can specify :

- Template type to be used: 
  - [simple](../ansible/playbook/roles/generate_inventory/templates/simple.inventory.j2), 
  - [hetzner](../ansible/playbook/roles/generate_inventory/templates/hetzner.inventory.j2),
  - [okd-cloud](../ansible/playbook/roles/generate_inventory/templates/cloud.inventory.j2),
- The `IP` address of the VM to ssh

The command to be executed is :
  
  ```bash
  cd ansible/
  ansible-playbook playbook/generate_inventory.yml -e ip_address=192.168.99.50 -e type=simple
  ```
