# Instructions to install a Kubernetes Cluster using Ansible playbooks 

## Prerequisite

- Linux VM (CentOS7, ...) running, that you can ssh on port 22 and where your public key has been imported
- Ansible [>=2.8](http://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

## Instructions

This cluster that the following playbook will setup will be created using `Kubeadmin` and will be provisioned with

- Kubernetes Dashboard
- Helm Tiller
- Kubernetes ServiceCatalog and OpenShift Ansible Broker

```bash
cd ansible
ansible-playbook -i inventory/simple_host playbook/k8s.yml 
```

## Post installations steps

If you want to configure your cluster with additional features, then you can install them using the following
roles

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
  ansible-playbook -i inventory/simple_host playbook/k8s.yml --tags tekton_pipelines -e tekton_release_version=v0.3.1  -e isOpenshift=false
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

- To use the new OpenShift console, install nodejs, go, yarn, jq tools
```bash
ssh -o StrictHostKeyChecking=no -i inventory/id_openstack.rsa -t centos@10.8.250.104 sudo 'bash -s' -- < ../kubernetes/install-tools-openshift-console.sh
```
- And next launch it
```bash
ssh -o StrictHostKeyChecking=no -i inventory/id_openstack.rsa -t centos@10.8.250.104 sudo 'bash -s' -- < ../kubernetes/launch-console.sh
```

- Configure the  Docker registry

Create first the `Kube Docker registry` service to get the `ClusterIP` address needed to create the selfsigned certificate

```bash
kubectl apply -f ../kubernetes/docker-registry/service.yml
kubectl get service/kube-registry
NAME            TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
kube-registry   ClusterIP   10.101.25.6   <none>        5000/TCP   25s
```

**Remark**: The External IP address to be passed as parameter too is the Eth0 IP address of the machine

First, use the following bash script responsible to create a private key, CSR and next call the K8s API in order to sign the certificate and next approve it
```bash
ssh -o StrictHostKeyChecking=no -i ../../ansible/inventory/id_openstack.rsa -t centos@10.8.250.104 sudo 'bash -s' -- < ../kubernetes/gen-self-signed-cert.sh 10.101.25.6 10.8.250.104
```

The files generated will become available under the folder `/root/docker-certs` and will been used to configure the docker registry.

Install the docker registry
```bash
kubectl apply -f ../kubernetes/docker-registry/registry-pvc.yml
```
