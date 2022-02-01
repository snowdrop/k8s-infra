## Tips 

This document contains the commands to be used to:
- Clean the password store from VM's keys created previously
- Update the inventory used by ansible to access the VM or the k8s cluster 
- Create/delete a VM on hetzner,
- Install/remove a K8s cluster on the VM
- Remote SSH or access using yourkubectl client the cluster

**WARNING**: Be sure that you are using the proper password store within your terminal before to execute the commands hereafter

```
VM_NAME=h01-121
ansible-playbook hetzner/ansible/hetzner-delete-server.yml -e vm_name=${VM_NAME} -e hetzner_context_name=snowdrop
ansible-playbook ansible/playbook/passstore_controller_inventory_remove.yml -e vm_name=${VM_NAME} -e pass_provider=hetzner
ansible-playbook ansible/playbook/passstore_controller_inventory.yml -e vm_name=${VM_NAME} -e pass_provider=hetzner -e k8s_type=masters -e k8s_version=121 -e operation=create
ansible-playbook hetzner/ansible/hetzner-create-ssh-key.yml -e vm_name=${VM_NAME}
ansible-playbook hetzner/ansible/hetzner-create-server.yml -e vm_name=${VM_NAME} -e salt_text=$(gpg --gen-random --armor 1 20) -e hetzner_context_name=snowdrop -e server_type=cpx41
ansible-playbook ansible/playbook/sec_host.yml -e vm_name=${VM_NAME} -e provider=hetzner

ansible-playbook kubernetes/ansible/k8s-misc.yml --limit ${VM_NAME} -e k8s_version=1.21.4 -e registry_nodePort=32500 -e remove=false --tags "k8s_cluster,k8s_config,docker_registry"
```

## Delete k8s cluster
```
VM_NAME=h01-121
ansible-playbook kubernetes/ansible/k8s.yml --limit ${VM_NAME} -e k8s_version=1.21.4 -e remove=false 
ansible-playbook hetzner/ansible/hetzner-delete-server.yml -e vm_name=${VM_NAME} -e hetzner_context_name=snowdrop
ansible-playbook hetzner/ansible/hetzner-delete-ssh-key.yml -e vm_name=${VM_NAME}
```

## Get Kubernetes config (post VM and cluster created)
```
VM_NAME=h01-121
ssh-hetznerc ${VM_NAME} cat /etc/kubernetes/admin.conf > ~/.kube/h01-121
export KUBECONFIG=~/.kube/h01-121
```

## Copy your user's public key to the VM
```
IP=$(PASSWORD_STORE_DIR=~/.password-store-snowdrop pass show hetzner/${VM_NAME}/ansible_ssh_host | awk 'NR==1{print $1}')
PORT=$(PASSWORD_STORE_DIR=~/.password-store-snowdrop pass show hetzner/${VM_NAME}/ansible_ssh_port | awk 'NR==1{print $1}')
USER=$(PASSWORD_STORE_DIR=~/.password-store-snowdrop pass show hetzner/${VM_NAME}/os_user | awk 'NR==1{print $1}')
ssh-copy-id -p ${PORT} -i ~/.ssh/id_rsa.pub ${USER}@${IP}
```

## Remote SSH
```
SSH_KEY=~/.ssh/id_rsa_snowdrop_hetzner_${VM_NAME}
echo "$(PASSWORD_STORE_DIR=~/.password-store-snowdrop pass show hetzner/${VM_NAME}/id_rsa)" > ~/.ssh/id_rsa_snowdrop_hetzner_${VM_NAME}
chmod 600 ~/.ssh/id_rsa_snowdrop_hetzner_${VM_NAME}
IP=$(PASSWORD_STORE_DIR=~/.password-store-snowdrop pass show hetzner/${VM_NAME}/ansible_ssh_host | awk 'NR==1{print $1}')
PORT=$(PASSWORD_STORE_DIR=~/.password-store-snowdrop pass show hetzner/${VM_NAME}/ansible_ssh_port | awk 'NR==1{print $1}')
USER=$(PASSWORD_STORE_DIR=~/.password-store-snowdrop pass show hetzner/${VM_NAME}/os_user | awk 'NR==1{print $1}')
ssh -i ${SSH_KEY} ${USER}@${IP} -p ${PORT} "<COMMAND>"
ssh -i ${SSH_KEY} ${USER}@${IP} -p ${PORT} "bash -s" -- < ./bash_script.sh
```
