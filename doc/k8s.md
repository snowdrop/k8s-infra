# Instructions to install Kubernetes

Table of Contents
=================

  * [Prerequisite](#prerequisite)
  * [Instructions](#instructions)
  * [Post installations steps](#post-installations-steps)
     * [Create K8s Config Yml](#create-k8s-config-yml)
     * [Install Ingress Router](#install-ingress-router)
     * [Install Helm](#install-helm)
     * [Install K8s Dashboard](#install-k8s-dashboard)
     * [Docker Registry](#docker-registry)
     * [New ocp4 console](#new-ocp4-console)

## Prerequisite

- Linux VM (CentOS 7, ...) running, that you can ssh on port 22 and where your public key has been imported
- Ansible [>=2.7](http://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- Ansible inventory - see [doc](inventory.md) ! 

## Instructions

This cluster that the following playbook will setup will be created using `Kubelet` and `Kubeadmin`

```bash
cd ansible
ansible-playbook -i inventory/simple_host playbook/post_installation.yml \
   --tags k8s_cluster
```

You can specify the version of `kubernetes` to be installed using this parameter `-e k8s_version=1.14.1`.

If you need to use the sudo root user on the target vm, then pass the parameter `--become`.

## Post installations steps

If you want to configure your cluster with additional features, then you can install them using the following
roles :

### Create K8s Config Yml

  ```bash
  ansible-playbook -i inventory/simple_host playbook/post_installation.yml --tags k8s_config
  ```
  
  This role will generate the file `remote-k8s-config.yml` within the inventory folder and will contain 
  the `Kind: Config` yaml resource which specify the definition of the `clusters`, `contexts`, `tokens` and `certificates`.
  
  You can then use it if you export the `KUBECONFIG` env var
  
  `e.g. export KUBECONFIG=inventory/remote-k8s-config.yml`
  
  If you need to use the sudo root user on the target vm, then pass the parameter `--become`
  
  To export the configuration using a different file name within the inventory folder, pass the parameter `-e k8s_config_filename`
  ```bash
  ansible-playbook -i inventory/simple_host playbook/post_installation.yml --tags k8s_config -e k8s_config_filename=node_k8s_config.yml
  ```  

### Install Ingress Router
  
  By default, a kubernetes cluster don't install a proxy able communicate with the [services deployed](https://kubernetes.io/docs/concepts/services-networking/ingress/) on the cluster. To have 
  access to such information, then it is needed to install an [Ingress controller](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/).
  
  ```bash
  ansible-playbook -i inventory/simple_host playbook/post_installation.yml --tags ingress
  ```  

### Install K8s Dashboard

By default, the kubernetes cluster don't install [Web UI - Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/) to manage, access the Kubernetes resources.

  ```bash
  ansible-playbook -i inventory/simple_host playbook/post_installation.yml --tags k8s_dashboard
  ```   
  
  To uninstall the dashboard, execute this command where you pass the parameter `-e remove=true` 
  
  Next, grab the token of the admin-user secret in order to access the dashboard
  ```bash
  kubectl -n kubernetes-dashboard get secret/admin-user -o jsonpath='{.data.token}' | base64 -d
  ```

### Install Helm (optional)

  ```bash
  ansible-playbook -i inventory/simple_host playbook/post_installation.yml --tags helm
  ``` 

### Docker Registry (optional)

  ```bash
  ansible-playbook -i inventory/simple_host playbook/post_installation.yml --tags docker_registry
  ```  
  
### New ocp4 console  (optional)

  To install the new ocp4 console on the port `0.0.0.0:9000`, then execute the following command
  
  ```bash
  ansible-playbook -i inventory/simple_host playbook/post_installation.yml --tags ocp4_console
  ```    
  
  You can next access it at the address `http://ocp4-console.external_ip_address.nip.io`.
  The External IP address exposing the console can be changed using the following parameter `-e external_ip_address=192.168.99.50`
  
  To uninstall the `ocp4 console`, execute this command where you pass the parameter `-e remove=true`
