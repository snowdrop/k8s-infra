# Prerequisites

You need to have both the `decorator` and `openstacksdk` pip packages installed.
Depending on the existing state of your machine, you might need to do:

```bash
[sudo] pip install [--upgrade] decorator
[sudo] pip install [--upgrade] openstacksdk
```

Install openstack.cloud Ansible collection.

```bash
$ ansible-galaxy collection install openstack.cloud
```

# Provision a VM on OpenStack

The first thing that needs to be done is to provision a fairly large CentOS virtual machine top of the Cloud operating system OpenStack.
This can of course be done via the OpenStack UI or can be automated using our Ansible openstack playbook like so:

```
ansible-playbook playbook/openstack.yml -e type=cloude -e '{"state": "present", "hostname": "somehostname", "openstack": {"os_username": "username", "os_password": "password", "os_domain": "domain", "os_auth_url": "https://somehost:13000/v3", "os_project_id": "someprojectid", "os_network": "network", "os_security_group": "security_group"}}'`
```

The playbook also uses the variables defined in `roles/openstack/defaults/main.yml`. Those variables can also be overridden using the syntax above.
For example to override the VM flavor, network and security group, one would execute the following command:

```
ansible-playbook playbook/openstack.yml \
   -e type=cloude \
   -e '{"state": "present", "hostname": "somehostname", "openstack": {"timeout": "600","os_username": "username", "os_password": "password", "os_domain": "domain", "os_auth_url": "https://somehost:13000/v3", "os_project_id": "someprojectid", "vm": {"network": "some_network", "security_group": "some_security_group", "flavor": "m1.medium"}}}'`
```

To delete a VM, simply replace `"state": "present"` with `"state": "absent"`

When using `"state": "present"`, the playbook will also generate an Openshift 3.11 inventory file in `inventory/cloud_host` 
as well as the private key of the new VM as `inventory/id_openstack.rsa` 

**IMPORTANT** : The Ansible commands should be executed within the ansible folder !

```
ansible-playbook playbook/openstack.yml -e type=cloude -e '{"state": "present", "hostname": "n311-prod", "openstack": {"timeout": "300", "os_username": "psi-spring-boot-jenkins", "os_password": "xxxxxxxx", "os_domain":  "redhat.com", "os_auth_url": "https://rhos-d.infra.prod.upshift.rdu2.redhat.com:13000/v3/", "vm": {"network": "provider_net_shared", "security_group": "spring-boot",  "flavor": "ci.m5.large", "volumes" : ["ceph-volume"]}}}'
```

```
ansible-playbook playbook/openstack.yml -e k8s_type=masters -e k8s_version=121 -e '{"openstack": {"vm": {"network": "provider_net_shared"}}}' -e vm_name=vm20210217-t01 --tags create
```
