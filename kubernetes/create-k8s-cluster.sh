#!/usr/bin/env bash

# To install k8s within the centos machine, execute this remote shell command
# ssh -o StrictHostKeyChecking=no root@192.168.99.50 'bash -s' -- < ./kubernetes/create-k8s-cluster.sh 1.14.1
#
# Script tested with component-operator + OAB successfully using k8s 1.13.5, 1.14.1
#
# ssh -o StrictHostKeyChecking=no root@192.168.99.50 'bash -s' -- < ./kubernetes/test-component-operator.sh
# ssh -o StrictHostKeyChecking=no root@192.168.99.50 'kubectl get all,serviceinstance,servicebinding,secrets -n demo'

version=${1:-1.14.1}
ip=${2:-192.168.99.50}
host=${3:-cloud}

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF

yum install kubeadm-${version} kubectl-${version} kubelet-${version} --disableexcludes=kubernetes -y 

systemctl enable kubelet.service
systemctl start kubelet

# Setting SELinux in permissive mode by running setenforce 0 and sed ... effectively disables it.
# This is required to allow containers to access the host filesystem, which is needed by pod networks for example.
# You have to do this until SELinux support is improved in the kubelet.
sudo setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
getenforce

# Some users on RHEL/CentOS 7 have reported issues with traffic being routed incorrectly due to iptables being bypassed.
# You should ensure net.bridge.bridge-nf-call-iptables is set to 1 in your sysctl config, e.g.
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

echo "##########################################"
echo "Pulling k8s linux images for version ${version}"
echo "##########################################"
kubeadm config images pull

echo "####################################"
echo "Initialising k8s cluster"
echo "####################################"
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=${ip}

echo "####################################"
echo "Create kube config file"
echo "####################################"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "#####################################################"
echo "Install Flannel Virtual Network for pod communication"
echo "#####################################################"
kubectl -n kube-system get deployment coredns -o yaml |   sed 's/allowPrivilegeEscalation: false/allowPrivilegeEscalation: true/g' |   kubectl apply -f -
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/a70459be0084506e4ec919aa1c114638878db11b/Documentation/kube-flannel.yml

echo "####################################"
echo "Taint the Cloud node"
echo "####################################"
kubectl taint nodes --all node-role.kubernetes.io/master-

echo "#####################################################"
echo "Install K8 dashboard where the dashboard service account has the cluster role"
echo "#####################################################"
cat <<EOF | kubectl create -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: kubernetes-dashboard
  labels:
    k8s-app: kubernetes-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard
  namespace: kube-system
EOF
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended/kubernetes-dashboard.yaml

echo "####################################"
echo "Disable login"
echo "####################################"
kubectl -n kube-system patch deploy kubernetes-dashboard --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--enable-skip-login"}]'

echo "####################################"
echo "Start the proxy exposing the route to access remotely the Dashboard"
echo "####################################"
kubectl proxy --address=${ip} --accept-hosts '.*' &

echo "####################################"
echo "Install Helm and initialize Tiller on k8s as cluster admin role"
echo "####################################"
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh

cat <<EOF | kubectl create -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: tiller-clusterrolebinding
subjects:
- kind: ServiceAccount
  name: tiller
  namespace: kube-system
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: ""
EOF
helm init --wait --service-account tiller

echo "####################################"
echo "Install Ingress using resources as defined by the minikube addon"
echo "####################################"
kubectl create -f https://raw.githubusercontent.com/snowdrop/openshift-infra/master/kubernetes/ingress/ingress-configmap.yaml
kubectl create -f https://raw.githubusercontent.com/snowdrop/openshift-infra/master/kubernetes/ingress/ingress-rbac.yaml
kubectl create -f https://raw.githubusercontent.com/snowdrop/openshift-infra/master/kubernetes/ingress/ingress-svc.yaml
kubectl create -f https://raw.githubusercontent.com/snowdrop/openshift-infra/master/kubernetes/ingress/ingress-dp.yaml

echo "####################################"
echo "Create PVs"
echo "####################################"
for i in {1..5}
do
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv00$i
spec:
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 3Gi
  hostPath:
    path: /tmp/pv00$i
    type: ""
  persistentVolumeReclaimPolicy: Recycle
EOF
done

echo "####################################"
echo "Install ServiceBroker"
echo "####################################"
helm repo add svc-cat https://svc-catalog-charts.storage.googleapis.com
helm install svc-cat/catalog --name catalog --namespace catalog

echo "####################################"
echo " Wait until the catalog is ready before moving on"
echo "####################################"
until kubectl get pods -n catalog -l app=catalog-catalog-apiserver | grep 2/2; do sleep 1; done
until kubectl get pods -n catalog -l app=catalog-catalog-controller-manager | grep 1/1; do sleep 1; done

echo "####################################"
echo "Install OAB"
echo "####################################"
# Create resources hereafter as they are not available anymore from master branch (see old file : https://github.com/openshift/ansible-service-broker/blob/ansible-service-broker-1.3.18-1/apb/install.yaml
# We will create a POD and not a job now !!
# apiVersion: batch/v1
# kind: Job
# metadata:
#   name: automation-broker-apb
#   namespace: automation-broker-apb
# spec:
#   backoffLimit: 5
#   activeDeadlineSeconds: 300
#   template:
#     spec:
#       restartPolicy: OnFailure
#       serviceAccount: automation-broker-apb
#       containers:
#       - name: apb
#         image: docker.io/automationbroker/automation-broker-apb:latest
#         args:
#         - "provision"
#         - "-e create_broker_namespace=true"
#         - "-e broker_auto_escalate=true"
#         - "-e wait_for_broker=true"
#         imagePullPolicy: IfNotPresent

cat <<EOF | kubectl create -f -
---
apiVersion: v1
kind: Namespace
metadata:
  name: automation-broker-apb
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: automation-broker-apb
  namespace: automation-broker-apb
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: automation-broker-apb
roleRef:
  name: cluster-admin
  kind: ClusterRole
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: automation-broker-apb
  namespace: automation-broker-apb
---
apiVersion: v1
kind: Pod
metadata:
  name: automation-broker-apb
  namespace: automation-broker-apb
spec:
  serviceAccount: automation-broker-apb
  containers:
    - name: apb
      image: docker.io/automationbroker/automation-broker-apb:latest
      args:
      - "provision"
      - "-e create_broker_namespace=true"
      - "-e broker_auto_escalate=true"
      - "-e wait_for_broker=true"
      imagePullPolicy: IfNotPresent
  restartPolicy: Never
EOF

echo "K8s cluster is running. You can now play with it "
