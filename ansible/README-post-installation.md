# Post Installation

FROM OC DOC

# Post installation

The post_installation playbook performs various tasks, like enabling the cluster admin user, installing Istio etc.
Make sure that the `openshift_admin_pwd` is specified when invoking the command. 

```bash
ansible-playbook -i inventory/simple_host playbook/post_installation.yml -e openshift_admin_pwd=admin
```
