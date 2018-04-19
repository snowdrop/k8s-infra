# Install all in one Openshift Origin 3.9 on an Openstack machine

## Provision Machine from Openstack

The first thing that needs to be done is to provision a fairly large CentOS machine from Openstack.
This can of course be done via the UI or can be automated using the ansible openstack playbook like so:

`ansible-playbook playbook/openstack.yml -e '{"state": "present", "hostname": "somehostname", "openstack": {"os_username": "username", "os_password": "password", "os_auth_url": "https://somehost:13000/v2.0/"}}'`

The playbook also uses the variables defined in `roles/openstack/defaults/main.yml`. Those variables can also be overriden using the syntax above.
For example to override the VM flavor, one would execute the following command:

`ansible-playbook playbook/openstack.yml -e '{"state": "present", "hostname": "somehostname", "openstack": {"flavor": "m1.medium"", "os_username": "username", "os_password": "password", "os_auth_url": "https://somehost:13000/v2.0/"}}'`

To delete a VM, simply replace `"state": "present"` with `"state": "absent"`

## Update the created VM so Openshift can be installed on it

After ssh-ing into the machine the following changes need to be made:

* Disable selinux
  
  selinux can be disabled by setting `SELINUX=disabled` in `/etc/selinux/config`
  
* Install network manager

  `sudo yum install -y NetworkManager`
  
* Restart VM
  
  This can easily be done by the Openstack UI using `Soft Reboot Instance`
  
## Execute openshift-ansible playbooks

Assuming floating IP = `10.8.250.104` and private IP = `172.16.195.12` an inventory file named `inventory/openstack_host` needs to be created like so:

```plain
[OSEv3:children]
masters
nodes
etcd

[OSEv3:vars]
ansible_user=centos

public_ip_address=10.8.250.104
host_key_checking=false

containerized=true
openshift_enable_excluders=false
openshift_release=v3.9

openshift_deployment_type=origin

openshift_hostname=n002
openshift_master_cluster_public_hostname=10.8.250.104
openshift_master_default_subdomain=10.8.250.104.nip.io
openshift_master_unsupported_embedded_etcd=true

# To avoid message
# - Available disk space in "/var" (9.5 GB) is below minimum recommended (40.0 GB)
# - Docker storage drivers 'overlay' and 'overlay2' are only supported with 'xfs' as the backing storage, but this host's storage is type 'extfs'
# - Available memory (2.0 GiB) is too far below recommended value (16.0 GiB)
# - Docker version is higher than expected
openshift_disable_check = docker_storage,memory_availability,disk_availability,docker_image_availability,package_version

# we need to increase the pods per core because we might temporarily have multiple build pods running at the same time
openshift_node_kubelet_args={'pods-per-core': ['20']}

# ASB Service Catalog
openshift_enable_service_catalog=false
ansible_service_broker_registry_whitelist=[".*-apb$"]

# Python Interpreter
ansible_python_interpreter=/usr/bin/python

# Enable htpasswd auth
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/master/htpasswd'}]
# htpasswd -nb admin admin
openshift_master_htpasswd_users={'admin': '$apr1$DloeoaY3$nqbN9fQBkyXgbj58buqEM.'}



# host group for masters
[masters]
10.8.250.104 openshift_public_hostname=10.8.250.104 openshift_hostname=172.16.195.12

[etcd]
10.8.250.104

# host group for worker nodes, we list master node here so that
# openshift-sdn gets installed. We mark the master node as not
# schedulable.
[nodes]
10.8.250.104 openshift_node_labels="{'region':'infra','zone':'default', 'node-role.kubernetes.io/compute': 'true'}" openshift_public_hostname=10.8.250.104 openshift_hostname=172.16.195.12
```

The openshift-ansible playbooks can now be launched like so:


```bash
ansible-playbook -i inventory/cloud_host_n002 openshift-ansible/playbooks/prerequisites.yml --become
ansible-playbook -i inventory/cloud_host_n002 openshift-ansible/playbooks/deploy-playbook.yml --become
```  

