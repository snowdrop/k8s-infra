# Install all in one Openshift Origin 3.9 on machine

## Prerequisites

You need to have installed CentOS 7.4 on a machine provisioned on the cloud of your choice.
Furthermore you need to be able to perform password-less login to the machine using the root user.

## Installation steps

- Git clone OpenShift Ansible

First git clone the OpenShift Ansible project locally using the branch corresponding to the version of ocp yu want to install

```bash
echo "#### Git clone openshift ansible"
if [ ! -d "openshift-ansible" ]; then
  git clone -b release-3.9 https://github.com/openshift/openshift-ansible.git
fi
```

- Generate inventory host file containing the definition about the OpenShift instance to be provisioned from a j2 template
Take care to supply the correct IP address in the corresponding argument

```bash
ansible-playbook playbook/generate_inventory.yml -e ip_address=192.168.99.50 -e openshift_origin_version=3.9
```

The inventory is later user by the [official](https://github.com/openshift/openshift-ansible) Openshift Ansible installation playbook to customize the setup
If you would like to customize some of the options, then first change the template file at `roles/generate_inventory/templates/cloud.inventory.j2`
before running the `playbook/generate_inventory.yml` role

Furthermore, the above command will generate an inventory file that will use `root` as `ansible_user`.
If another user other than `root` is to be used for accessing the machine over ssh, you can pass the `username` variable like so:

```bash
ansible-playbook playbook/generate_inventory.yml -e ip_address=192.168.99.50 -e openshift_origin_version=3.9 -e username=centos
```

- Install OpenShift

```bash
ansible-playbook -i inventory/cloud_host openshift-ansible/playbooks/prerequisites.yml
ansible-playbook -i inventory/cloud_host openshift-ansible/playbooks/deploy_cluster.yml
```

If the `ansible_user` that is has been set in the inventory is not `root`, then the `--become` flag needs to be added to both
of the above commands 

REMARK : Customization of the installation (inventory file generated) is possible by changing the variables found in `inventory/cloud_host` from the command line using Ansible's `-e` syntax.

- Execute post installation steps such as : 
  - Enable cluster admin role for `admin` user
  - Setup persistence using `HostPath` mounted volumes `/tmp/pv001 ...`,
  - Create `infra` project
  - Install Nexus, Jenkins 
 

```bash
ansible-playbook -i inventory/cloud_host playbook/post_installation.yml -e openshift_admin_pwd=admin --tags "enable_cluster_admin,persistence"
```

Remark : You can also select to only install specific parts by using Ansible's `tags` support like so: `--tags install_nexus,install_jaeger`
If you would like to execute all roles except some, you can use Ansible's `--skip-tags` in the same fashion. 
The tags can be found in ` playbook/post_installation.yml`

Remark on persistence: The number of PVs to be created can be controlled by the `number_of_volumes` variable. See [here](playbook/roles/persistence/defaults/main.yml)

- Install the service catalog
```bash
ansible-playbook -i inventory/cloud_host openshift-ansible/playbooks/openshift-service-catalog/config.yml
```

- Create users and projects

For the first machine the following will create the first 5 users

```bash
ansible-playbook -i inventory/cloud_host playbook/post_installation.yml -e openshift_node=masters --tags identity_provider -e number_of_extra_users=5 -e first_extra_user_offset=1 -e openshift_admin_pwd=admin
```

This step will create 5 users with credentials like `user1/pwd1` while also creating a project for like `user1` for each user 

## Soft clean up of an existing machine

If all you care to do is reset openshift back to zero then stop the API, Controllers, and etcd. Then follow these instructions

```bash
- Stop services, clean docker images

docker system prune -a -f

systemctl stop etcd.service
systemctl stop origin-master-api.service
systemctl stop origin-master-controllers.service
systemctl stop origin-node.service

- Remove /var/lib/etcd/member directory,

sudo rm -rf /var/lib/etcd/member

- Start etcd, start the api, start the controllers.

systemctl restart etcd.service
systemctl restart origin-master-api.service
systemctl restart origin-master-controllers.service
...
systemctl restart origin-node.service

- You'll now have a completely clean cluster, which means no registry and router but you can re-add those with

oc login -u system:admin
oc adm registry
oc adm policy add-scc-to-user hostnetwork -z router
oc adm router
oc adm policy add-cluster-role-to-user cluster-admin admin

- Add imagestreams, templates

mkdir -p /home/tmp && cd /home/tmp
git clone https://github.com/openshift/openshift-ansible.git
cd openshift-ansible/roles/openshift_examples/files/examples/latest/
for f in image-streams/image-streams-centos7.json; do cat $f | oc create -n openshift -f -; done
for f in db-templates/*.json; do cat $f | oc create -n openshift -f -; done
for f in quickstart-templates/*.json; do cat $f | oc create -n openshift -f -; done
```

Then we can continue the normal installation to have jenkins, nexus, jaeger

```bash
ansible-playbook -i inventory/cloud_host playbook/setup_ocp.yml -e openshift_node=masters --skip-tags "config_dns,install_jenkins" -e persistence=false
ansible-playbook -i inventory/cloud_host playbook/install_jenkins_for-hetzner.yml -e openshift_node=masters
ansible-playbook -i inventory/cloud_host playbook/install_jaeger.yml -e openshift_node=masters
ansible-playbook -i inventory/cloud_host playbook/add_users.yml -e openshift_node=masters -e number_of_users=20 -e first_user_offset=31
or
ansible-playbook -i inventory/cloud_host playbook/add_users.yml -e openshift_node=masters -e number_of_users=30 -e first_user_offset=1
ansible-playbook -i inventory/cloud_host ../ocp-create/openshift-ansible/playbooks/byo/openshift-cluster/service-catalog.yml
```
