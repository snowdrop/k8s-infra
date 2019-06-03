# Instructions to install a Kubernetes Cluster using Ansible playbooks 

## Prerequisite

- Linux VM (CentOS7, ...) running, that you can ssh on port 22 and where your public key has been imported
- Ansible [>=2.7](http://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

## Instructions

This cluster that the following playbook will setup will be created using `Kubeadmin` and will be provisioned with

- Kubernetes Dashboard
- Helm Tiller

```bash
cd ansible
ansible-playbook -i inventory/simple_host playbook/k8s.yml --tags k8s_cluster
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
  
  
### K8s Service Catalog and OABroker

  ```bash
  ansible-playbook -i inventory/simple_host playbook/k8s.yml --tags k8s_service_broker
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
  
### Component Operator

  ```bash
  ansible-playbook -i inventory/simple_host playbook/k8s.yml --tags component_crd_operator -e isOpenshift=false
  ```  
  
  To remove the Component CRD and its operator, pass then the following variable `-e remove=true`
  
  To use a different version of the image, then use `-e component_operator_docker_image_version=master`

## TODO

- To test if the Component Operator is working with the `OABroker, ServiceCatalog`, install it with an example of `Component CR` and check the pods created
```bash
ssh -o StrictHostKeyChecking=no -i inventory/id_openstack.rsa -t centos@10.8.250.104 sudo 'bash -s' -- < ../kubernetes/test-component-operator.sh
ssh -o StrictHostKeyChecking=no -i inventory/id_openstack.rsa -t centos@10.8.250.104 sudo kubectl get all,serviceinstance,servicebinding,secrets -n demo
```
