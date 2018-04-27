# Post Installation

>> FROM OC DOC

# Post installation

The post_installation playbook performs various tasks, like enabling the cluster admin user, installing Istio etc.
Make sure that the `openshift_admin_pwd` is specified when invoking the command. 

```bash
ansible-playbook -i inventory/simple_host playbook/post_installation.yml -e openshift_admin_pwd=admin
```

>> FROM CLOUD DOC PAGE

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

For the first machine the following will create an admin user (who is granted cluster-admin priviledges) and an extra 5 users (user1 - user5)

```bash
ansible-playbook -i inventory/cloud_host playbook/post_installation.yml -e openshift_node=masters --tags identity_provider,enable_cluster_admin,add_extra_users -e number_of_extra_users=5 -e first_extra_user_offset=1 -e openshift_admin_pwd=admin
```

This step will create 5 users with credentials like `user1/pwd1` while also creating a project for like `user1` for each user

By default these users will have admin roles (although not cluster-admin) and will each have a project that corresponds to the user name.
These defaults can be changed using the `make_users_admin` and `create_user_project` flags. See [here](playbook/roles/add_extra_users/defaults/main.yml) 

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
