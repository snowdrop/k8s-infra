# Instructions to install a Kubernetes Cluster using Ansible playbooks 

## Prerequisite

- Linux VM (CentOS7, ...) running, that you can ssh on port 22 and where your public key has been imported
- Ansible [>=2.7](http://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

## Instructions

This cluster that the following playbook will setup will be created using `Kubelet` and `Kubeadmin`

```bash
cd ansible
ansible-playbook -i inventory/simple_host playbook/k8s.yml \
   --tags k8s_cluster
```

You can specify the version of kubernetes to be installed using this parameter `-e k8s_version=1.14.1`. If you need to use the sudo root user on the target vm, then pass the parameter `--become`

## Post installations steps

If you want to configure your cluster with additional features, then you can install them using the following
roles

### Create K8s Config Yml

  ```bash
  ansible-playbook -i inventory/simple_host playbook/k8s.yml --tags k8s_config
  ```
  
  This role will generate the file `remote-k8s-config.yml` within the inventory folder. You can then use it if you export the `KUBECONFIG` env var
  
  e.g. export KUBECONFIG=inventory/remote-k8s-config.yml
  
  If you need to use the sudo root user on the target vm, then pass the parameter `--become`
  
  To export the configuration using a different file name within the inventory folder, pass the parameter `-e k8s_config_filename`
  ```bash
  ansible-playbook -i inventory/simple_host playbook/k8s.yml --tags k8s_config -e k8s_config_filename=node_k8s_config.yml
  ```  

### Install Ingress Router

  ```bash
  ansible-playbook -i inventory/simple_host playbook/k8s.yml --tags ingress
  ```  

### Install Helm

  ```bash
  ansible-playbook -i inventory/simple_host playbook/k8s.yml --tags helm
  ``` 
  
### Install K8s Dashboard

  ```bash
  ansible-playbook -i inventory/simple_host playbook/k8s.yml --tags k8s_dashboard
  ```   
  
  To uninstall the dashboard, execute this command where you pass the parameter `-e remove=true` 

### Docker Registry

  ```bash
  ansible-playbook -i inventory/simple_host playbook/k8s.yml --tags docker_registry
  ```  
  
### New ocp4 console

  To install the new ocp4 console on the port `0.0.0.0:9000`, then execute the following command
  
  ```bash
  ansible-playbook -i inventory/simple_host playbook/k8s.yml --tags ocp4_console
  ```    
  
  You can next access it at the address `http://ocp4-console.external_ip_address.nip.io`.
  The External IP address exposing the console can be changed using the following parameter `-e external_ip_address=192.168.99.50`
  
  To uninstall the `ocp4 console`, execute this command where you pass the parameter `-e remove=true`

### KubeDB Operator

  **Prerequisite**: Helm must be installed. Run the playbook command where you pass to `playbook/k8s.yml`, the tag `--tags helm`

  ```bash
  ansible-playbook -i inventory/simple_host playbook/k8s.yml --tags kubedb
  ```    
  
  To uninstall the `KubeDB operator and catalog of the availbale databases`, execute this command where you pass the parameter `remove=true`
  ```bash
  ansible-playbook -i inventory/simple_host playbook/k8s.yml --tags kubedb -e remove=true
  ```  
  
  You can, during the installation of the kubedb operator, install and enable their mutating and validating webhooks using this parameter `-e kubedb_enablewebhook=true`. By default, webhooks are not enabled.
  The namespace where kudedb should be installed can be specified using `-e kubedb_namespace=my-kudeb`. By default, it is `kubedb`
  
### K8s Service Catalog and OABroker

  ```bash
  ansible-playbook -i inventory/simple_host playbook/k8s.yml --tags k8s_service_broker
  ```    
  
  To uninstall the `Service Catalog and OABroker`, execute this command where you pass the parameter `remove=true`
  ```bash
  ansible-playbook -i inventory/simple_host playbook/k8s.yml --tags k8s_service_broker -e remove=true
  ```

### Tekton Pipelines

  ```bash
  ansible-playbook -i inventory/simple_host playbook/k8s.yml --tags tekton_pipelines -e isOpenshift=false
  ```
  
  To uninstall the `tekton pipelines`, execute this command where you pass the parameter `remove=true`
  ```bash
  ansible-playbook -i inventory/simple_host playbook/k8s.yml --tags tekton_pipelines -e remove=true  -e isOpenshift=false
  ```
  
  You can specify the version to be installed. If not defined, the latest release will be installed
  ```bash
  ansible-playbook -i inventory/simple_host playbook/k8s.yml --tags tekton_pipelines -e tekton_release_version=v0.3.1 -e isOpenshift=false
  ```
  
  To install it using the oc client installed within the VM, then execute this command
  ```bash
  ansible-playbook -i inventory/simple_host playbook/k8s.yml --tags tekton_pipelines -e isOpenshift=true -e client_tool=oc
  ```
  
### Component Operator

  ```bash
  ansible-playbook -i inventory/simple_host playbook/k8s.yml --tags component_crd_operator -e isOpenshift=false
  ```  
  
  To remove the Component CRD and its operator, pass then the following variable `-e remove=true`
  
  To use a different version of the image, then use `-e component_operator_docker_image_version=master`
