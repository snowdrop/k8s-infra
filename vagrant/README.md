# Vagrant project

The goal of this project is to help you to launch locally using vagrant a Centos VM and next to create a kubernetes cluster 
using `kubeadml` and `kubelet` tools

## Prerequisite

- Ansible 2.9
- `passwordstore` role. As the `k8s_dashboard` role depends on the `passwordstore` role which is available on galaxy repository, execute the following command to install it
```bash
ansible-galaxy collection install community.general
```

## Ansible instructions

- To launch a Centos7 VM, configure an IP fix address `192.168.99.50` accessible from your laptop, execute this command:
```bash
vagrant destroy -f && vagrant up && ssh-keygen -R '[127.0.0.1]:2222'
```
- To create the `k8s cluster` and deploy additional features such as: ingress and the dashboard, execute the following command: 
  **Remark**: If you use a different `password store`, then pass as parameter the location of your local `PASSWORD_STORE_DIR`
```bash
export PASSWORD_STORE_DIR=~/.password-store-work
export ANSIBLE_ROLES_PATH="../ansible/roles"
ansible-playbook -i ansible/local ../kubernetes/ansible/k8s.yml -e pass_provider=vagrant
```
- Patch the Ingress controller service to add an `externalIP` as no external Loadbalancer has been deployed. Without such an IP address, then the status of the service will stay equal to `pending`
```bash
kubectl --kubeconfig=./remote-k8s-config.yml patch svc/ingress-nginx-controller -n ingress-nginx -p '{"spec": {"type": "LoadBalancer", "externalIPs":["<IP_ADDRESS>>"]}}'

Example
kubectl --kubeconfig=./remote-k8s-config.yml patch svc/ingress-nginx-controller -n ingress-nginx -p '{"spec": {"type": "LoadBalancer", "externalIPs":["192.168.99.50"]}}'
```
- To install separately some features, use these ansible commands
```bash
ansible-playbook -i ansible/local ../kubernetes/ansible/k8s-misc.yml -e pass_provider=vagrant --tags k8s_dashboard
ansible-playbook -i ansible/local ../kubernetes/ansible/k8s-misc.yml --tags cert_manager
```

## To clean up

- To clean the vm and token created for the dashboard
```bash
vagrant destroy -f 
pass rm -r vagrant/centos7 -f
```
