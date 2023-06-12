echo "Kubernetes version : ${K8S_VERSION}"
echo "IP address exposing K8S API : ${IP_ADDRESS}"
echo "VM_USER : ${VM_USER}"

systemctl stop firewalld

sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum update -y && yum install -y containerd.io-1.2.13 docker-ce-19.03.8 docker-ce-cli-19.03.8

# Create required directories
sudo mkdir /etc/docker
sudo mkdir -p /etc/systemd/system/docker.service.d

# Create daemon json config file
sudo tee /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

# Start and enable Services
sudo groupadd docker
sudo usermod -aG docker ${VM_USER}
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker

sudo swapoff -a

sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum install -y kubelet-${K8S_VERSION} kubeadm-${K8S_VERSION} kubectl-${K8S_VERSION} --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

sudo kubeadm config images pull --kubernetes-version ${K8S_VERSION}
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=${IP_ADDRESS} --kubernetes-version ${K8S_VERSION}

mkdir -p /home/${VM_USER}/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/${VM_USER}/.kube/config
sudo chown 1000:1000 /home/${VM_USER}/.kube/config

export KUBECONFIG=/home/${VM_USER}/.kube/config

cat << EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: system:kube-system:default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: default
    namespace: kube-system
EOF

kubectl -n kube-system get deployment coredns -o yaml | sed 's/allowPrivilegeEscalation: false/allowPrivilegeEscalation: true/g' | kubectl apply -f -
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/579be3e869570b9c8cb0a452ce9e60699bac8062/Documentation/kube-flannel.yml
kubectl taint nodes --all node-role.kubernetes.io/master-

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended.yaml

kubectl delete service/kubernetes-dashboard -n kubernetes-dashboard
cat <<EOF | kubectl apply -f -
kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kube-system
spec:
  type: NodePort
  ports:
    - port: 443
      targetPort: 8443
      nodePort: 32641
  selector:
    k8s-app: kubernetes-dashboard
EOF
