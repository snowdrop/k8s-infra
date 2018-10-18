# Provision a VM on OpenStack

The first thing that needs to be done is to provision a fairly large CentOS virtual machine top of the Cloud operating system OpenStack.
This can of course be done via the OpenStack UI or can be automated using our Ansible openstack playbook like so:

```
ansible-playbook playbook/openstack.yml -e '{"state": "present", "hostname": "somehostname", "openstack": {"os_username": "username", "os_password": "password", "os_auth_url": "https://somehost:13000/v3", "os_project_id": "someprojectid"}}'`
```

The playbook also uses the variables defined in `roles/openstack/defaults/main.yml`. Those variables can also be overridden using the syntax above.
For example to override the VM flavor, one would execute the following command:

```
ansible-playbook playbook/openstack.yml -e '{"state": "present", "hostname": "somehostname", "openstack": {"os_username": "username", "os_password": "password", "os_auth_url": "https://somehost:13000/v3", "os_project_id": "someprojectid", "vm": {"flavor": "m1.medium"}}}'`
```

To delete a VM, simply replace `"state": "present"` with `"state": "absent"`

When using `"state": "present"`, the playbook will also generate an Openshift 3.10 inventory file in `inventory/cloud_host` 
as well as the private key of the new VM as `inventory/id_openstack.rsa` 

**IMPORTANT** : The Ansible commands should be executed within the ansible folder !
