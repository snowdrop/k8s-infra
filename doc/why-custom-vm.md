When it is needed to customize the `Linux VM` locally, you cannot rely on the VM installed with mini(kube/shift) or docker destop tools as they dont offer the possibility 
to install additional packages, to customize easily the firewall, host adapters, ...

This is also specifically true when you will install the cluster using `ansible-playbook` as the deployment tool.
The `Ansible playooks` requires some `prerequisites` in addition to having a
primary ethernet adapter, the one to be used by the OpenShift Master API (which is the Kubernetes controller, ....).

For such an environment, it makes sense to customize a Linux ISO image and to perform post-installation tasks to make it ready for your needs.
