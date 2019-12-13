# Play with our list of Developer's features

## Roles - Features

The table hereafter summarizes the roles available that you can call using the `post_installation` playbook.

| Role Name | Cluster | Description  |
| --------- | ------- | ------------ | 
| [add_extra_users](#command-add_extra_users) | okd | Create list of users/passwords and their corresponding project |
| [delete_extra_users](#command-delete_extra_users) | | okd | Delete extra users created using `add_extra_users` |
| [enable_cluster_role](#command-enable_cluster_role) | okd | Grant a cluster role to an OpenShift user |
| [identity_provider](#command-identity_provider) | okd | Set the Master-configuration of OpenShift to use `htpasswd` as its identity provider |
| [persistence](#command-persistence) | okd | Enable Persistence using `hotPath` as `persistenceVolume` |
| [docker](#extra-docker-config) | okd |  Enable extra docker config to access it using port 2376 |
| [component_crd_operator](#component-crd-operator)| okd | Install the Component CRD and Operator processing them | 
| [snowdrop_site](#command-install-snowdrop-site) | k8s,okd | Install Snowdrop web site |
| [halkyon_site](#command-install-halkyon-site) | k8s,okd | Install Halkyon Nginx web site |
| [install_nexus](#command-install_nexus) | okd | Install Nexus Repository Server |
| [install_jenkins](#command-install_jenkins) | okd | Install Jenkins and configure it to handle `s2i` builds started within an OpenShift project |
| [install_jaeger](#command-install_jaeger) | okd | Install Distributed Tracing - Jaeger |
| [install_istio](#command-install_istio) | okd | Install ServiceMesh - Istio |
| [service_catalog](#command-service-catalog) | okd | Deploy the [Ansible Service Broker](http://automationbroker.io/) |
| [install_efk](#command-logging-efk) | okd | Install EFK on the cluster |
| [tekton_pipelines](#command-tekton-pipelines) | k8s,okd |  Install Tekton Pipelines |
| [install_launcher](#command-install_launcher) | okd | Install and enable the Fabric8 [Launcher](http://fabric8-launcher) |
| [install_oc](#command-install_oc) | okd | Install oc client within the vm

## Prerequisite

  - Linux VM (CentOS7, ...) running, that you can ssh on port 22 and where your public key has been imported
  - Ansible [>=2.7](http://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
  - Cluster installed

## General command

The post_installation playbook, that yu can execute as presented hereafter performs various tasks.
When you will run it, make sure that the `openshift_admin_pwd` is specified when invoking the command as it contains the 'openshift' admin user
to be used to executed `oc` commands on the cluster.

```bash
ansible-playbook -i inventory/simple_host playbook/post_installation.yml -e openshift_admin_pwd=admin
```

To install one of the roles, you will specify it using the `--tags` parameter as showed hereafter.

```bash
ansible-playbook -i inventory/cloud_host playbook/post_installation.yml -e openshift_admin_pwd=admin --tags "enable_cluster_role"
```

**Remarks** : 

- Refer to the `ROLE/defaults/main.yml` to learn what are the parameters and their default value
- To only install specific roles, you will pass a comma separated values list using the `--tags install_nexus,install_jaeger` parameter
- If you would like to execute all roles except some, you can use Ansible's `--skip-tags` in the same fashion. 

## Role's command

### Command identity_provider

  ```bash
  ansible-playbook -i inventory/cloud_host playbook/post_installation.yml -e openshift_admin_pwd=admin --tags "identity_provider"
  ```
  
### Command add_extra_users

  **WARNING**: Role `identity_provider` must be executed before !
  
  For the first machine the following will create an admin user (who is granted cluster-admin priviledges) and an extra 5 users (user1 - user5)

  ```bash
  ansible-playbook -i inventory/cloud_host playbook/post_installation.yml --tags add_extra_users \
     -e number_of_extra_users=5 \
     -e first_extra_user_offset=1
  ```
  
  This step will create 5 users with credentials like `user1/pwd1` while also creating a project for like `user1` for each user
  
  By default these users will have admin roles (although not cluster-admin) and will each have a project that corresponds to the user name.
  These defaults can be changed using the `make_users_admin` and `create_user_project` flags. See [here](playbook/roles/add_extra_users/defaults/main.yml)
  
### Command delete_extra_users

  **WARNING**: Role `identity_provider` must be executed before !

  ```bash
  ansible-playbook -i inventory/cloud_host playbook/post_installation.yml --tags delete_extra_users \
     -e number_of_extra_users=5 \
     -e first_extra_user_offset=1
  ```
  
  This step will delete 5 users whose user names are like  `user1` while also deleting the projects like `user1` that were associated to those users
    

### Command enable_cluster_role

  ```bash
  ansible-playbook -i inventory/cloud_host playbook/post_installation.yml \
     -e openshift_admin_pwd=admin \
     --tags "enable_cluster_role"
  ```
  
  The `enable_cluster_role` role also accepts the following parameters that can be added using Ansible's `extra-vars` [syntax](http://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#passing-variables-on-the-command-line):
  
  
| Name | Description  | Default
| --------- | ------------ | ------------ |
| cluster_role_name | The name of the cluster role to grant to the admin user | cluster-admin  
| user | The user to which to grant the cluster role | admin  
| openshift_admin_pwd | The password of the admin user |   
  
### Command halkyon

  ```bash
  ansible-playbook -i inventory/hetzner_host playbook/post_installation.yml \
    --tags halkyon \
    -e ACTION=create
  ``` 

  To remove halkyon, pass as parameter `-e ACTION=remove` 
  You can also disable to patch the `master-config.yaml` file of the kube-api server with `MutatingAdmissionWebhook` and `ValidatingAdmissionWebhook` using 
  `-e patch=false`. By default, it is patched. 
  
### Command Persistence

  ```bash
  ansible-playbook -i inventory/cloud_host playbook/post_installation.yml \
    --tags persistence \
    -e openshift_admin_pwd=admin
  ```
  
  The number of PVs to be created can be controlled by the `number_of_volumes` variable. See [here](playbook/roles/persistence/defaults/main.yml).
  By default, 10 volumes of 5Gb each will be created.

### Extra docker config

  ```bash
  ansible-playbook -i inventory/cloud_host playbook/post_installation.yml --tags docker
  ```
  
  Configure docker daemon to accept traffic on port 2376. Client can then access it using `export DOCKER_HOST=tcp://IP_ADDRESS:2376`   
  
### Component crd operator  

  ```bash
  ansible-playbook -i inventory/cloud_host playbook/post_installation.yml \
    --tags component_crd_operator
  ```
  
  To remove the Component CRD and its operator, pass then the following variable `-e remove=true`
  
  To use a different version of the image, then use `-e component_operator_docker_image_version=master`

### Command Tekton Pipelines

  ```bash
  ansible-playbook -i inventory/cloud_host playbook/post_installation.yml \
    --tags tekton_pipelines
  ```
  
  To uninstall the `tekton pipelines`, execute this command where you pass the parameter `-e remove=true`
  
  You can specify the version to be installed. If not defined, the latest release will be installed using the parameter `-e tekton_release_version=v0.3.1`

### Command Install Snowdrop Site

  The Snowdrop web site can be installed using the following role and command
  
  ```bash
  ansible-playbook -i inventory/cloud_host playbook/post_installation.yml \
    --tags snowdrop-site \
    -e github_secret=secret101
  ```
  
  To remove the kubernetes resources of the Snowdrop web site, pass then the following variable `-e remove=true`

### Command Install Halkyon Site

  The Halkyon web site can be installed using the following role and command
  
  ```bash
  ansible-playbook -i inventory/cloud_host playbook/post_installation.yml \
    --tags halkyon-site
  ```
  
  To remove the kubernetes resources of the Snowdrop web site, pass then the following variable `-e remove=true`

### Command install_nexus

  The nexus server will be installed under the project `infra` and will contain the Red Hat proxy servers
  
  ```bash
  ansible-playbook -i inventory/cloud_host playbook/post_installation.yml \
     --tags nexus
  ```
  
  The `nexus` role also accepts the following parameters that can be added using Ansible's `extra-vars` [syntax](http://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#passing-variables-on-the-command-line):
  
  
| Name | Description  | Default
| --------- | ------------ | ------------ |
| persistence | Whether or not the Nexus instance uses persistent storage | true

### Command install_jenkins

  The Jenkins server will be installed under the project `infra` 
  
  ```bash
  ansible-playbook -i inventory/cloud_host playbook/post_installation.yml \
     --tags jenkins
  ```
  
  **WARNING**: In case you would be interested to re-install jenkins, then the namespace `infra` must be deleted and recreated manually !

### Command install_jaeger

  ```bash
  ansible-playbook -i inventory/cloud_host playbook/post_installation.yml \
     --tags jaeger \
     -e infra_project=infra
  ```
  **WARNING**: the `infra_project` parameter is mandatory

### Command install_istio

  ```bash
  ansible-playbook -i inventory/cloud_host playbook/post_installation.yml \
     --tags istio
  ```
 
    
  The `istio` role also accepts the following parameters that can be added using Ansible's `extra-vars` [syntax](http://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#passing-variables-on-the-command-line):
  
  
| Name | Description  | Default
| --------- | ------------ | ------------ |
| istio_authentication | Whether or not the Istio installation will have auth enabled | false

### Command install_launcher

  ```bash
  ansible-playbook -i inventory/cloud_host playbook/post_installation.yml \
     --tags {install-launcher|uninstall-launcher}
  ```
  
    
  The `launcher` role also accepts the following parameters that can be added using Ansible's `extra-vars` [syntax](http://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html#passing-variables-on-the-command-line):
  
  
| Name | Description  | Default
| --------- | ------------ | ------------ |
| launcher_project_name | The project where the launcher will be installed | devex |
| launcher_github_username | The github username to use |  |
| launcher_github_token | The github token to use |  |
| launcher_keycloak_url | The keycloak URL to use |  |
| launcher_keycloak_realm | The keycloak realm to use | |
| launcher_openshift_user | The launcher openshift user | admin |
| launcher_openshift_pwd | The launcher openshift user | admin |
| launcher_template_version | The launcher template version | master |
| launcher_template_name | The launcher template name | fabric8-launcher |  
| launcher_template_url | The launcher template URL | https://raw.githubusercontent.com/fabric8-launcher/launcher-openshift-templates/master/openshift/launcher-template.yaml |  
| launcher_catalog_git_repo | Git Repo where the catalog is defined | https://github.com/fabric8-launcher/launcher-booster-catalog.git |  
| launcher_catalog_git_branch | Git branch where the catalog is defined | master |  
| launcher_catalog_filter | The filter used to limit which catalog entries will appear |  |  
| launcher_openshift_console_url | The URL where the Openshift console is accessible | Looked up automatically using `oc` |  
| launcher_openshift_api_url | The URL of the Openshift API | https://openshift.default.svc.cluster.local |  
| launcher_keycloak_template_name | The project where the launcher will be installed | devex |  

### Command install_oc

  ```bash
  ansible-playbook -i inventory/cloud_host playbook/post_installation.yml \
     --tags install_oc
  ```

### Command Service catalog

  To install the service catalog, execute this command
  ```bash
  ansible-playbook -i inventory/cloud_host openshift-ansible/playbooks/openshift-service-catalog/config.yml -e ansible_service_broker_install=true
  ```

### Command Logging EFK

  To install the infrastructure collecting the pod's logs using ElasticSearch Fluendtd & Kibana dashboard, execute this command
  ```bash
  ansible-playbook -i inventory/cloud_host openshift-ansible/playbooks/openshift-logging/config.yml -e openshift_logging_install_logging=true
  ```

### KubeDB Operator

  **Prerequisite**: Helm must be installed. Run the playbook command where you pass to `playbook/post_installation.yml`, the tag `--tags helm`

  ```bash
  ansible-playbook -i inventory/simple_host playbook/post_installation.yml --tags kubedb
  ```    
  
  To uninstall the `KubeDB operator and catalog of the availbale databases`, execute this command where you pass the parameter `remove=true`
  ```bash
  ansible-playbook -i inventory/simple_host playbook/post_installation.yml --tags kubedb -e remove=true
  ```  
  
  You can, during the installation of the kubedb operator, install and enable their mutating and validating webhooks using this parameter `-e kubedb_enablewebhook=true`. By default, webhooks are not enabled.
  The namespace where kudedb should be installed can be specified using `-e kubedb_namespace=my-kudeb`. By default, it is `kubedb`
  
### K8s Service Catalog and OABroker

  ```bash
  ansible-playbook -i inventory/simple_host playbook/post_installation.yml --tags k8s_service_broker
  ```    
  
  To uninstall the `Service Catalog and OABroker`, execute this command where you pass the parameter `remove=true`
  ```bash
  ansible-playbook -i inventory/simple_host playbook/post_installation.yml --tags k8s_service_broker -e remove=true
  ```

### Tekton Pipelines

  ```bash
  ansible-playbook -i inventory/simple_host playbook/post_installation.yml --tags tekton_pipelines -e isOpenshift=false
  ```
  
  To uninstall the `tekton pipelines`, execute this command where you pass the parameter `remove=true`
  ```bash
  ansible-playbook -i inventory/simple_host playbook/post_installation.yml --tags tekton_pipelines -e remove=true  -e isOpenshift=false
  ```
  
  You can specify the version to be installed. If not defined, the latest release will be installed
  ```bash
  ansible-playbook -i inventory/simple_host playbook/post_installation.yml --tags tekton_pipelines -e tekton_release_version=v0.3.1 -e isOpenshift=false
  ```
  
  To install it using the oc client installed within the VM, then execute this command
  ```bash
  ansible-playbook -i inventory/simple_host playbook/post_installation.yml --tags tekton_pipelines -e isOpenshift=true -e client_tool=oc
  ```
  
### Component Operator

  ```bash
  ansible-playbook -i inventory/simple_host playbook/post_installation.yml --tags component_crd_operator -e isOpenshift=false
  ```  
  
  To remove the Component CRD and its operator, pass then the following variable `-e remove=true`
  
  To use a different version of the image, then use `-e component_operator_docker_image_version=master`

