### How to setup a kubernetes cluster on Centos7

Useful links

- https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#master-isolation
- https://powerodit.ch/2017/10/29/all-in-one-kubernetes-cluster-with-kubeadm/
- https://kubernetes.io/docs/setup/independent/install-kubeadm/
- https://kubernetes.io/docs/concepts/cluster-administration/addons/
- https://ichbinblau.github.io/2017/09/20/Setup-Kubernetes-Cluster-on-Centos-7-3-with-Kubeadm/

## OpenStack

- Create a VM using ansible playbook
```bash
git clone https://github.com/snowdrop/openshift-infra.git && cd openshift-infra/ansible
ansible-playbook playbook/openstack.yml -e '{"state": "present", "hostname": "n114-test", "openstack": {"os_username": "spring-boot-jenkins", "os_password": "Y4zh73d9", "os_auth_url": "https://ci-rhos.centralci.eng.rdu2.redhat.com:13000/v2.0/", "vm": {"flavor": "m5.large"}}}'
```
- Install Docker using the bash script
```bash
ssh -o StrictHostKeyChecking=no -i inventory/id_openstack.rsa -t centos@10.8.250.104 sudo 'bash -s' -- < ../kubernetes/install-docker-systemd.sh
```   

- Create K8s cluster using the eth0 ip address of the VM. This is not the external IP address !!
```bash
ip=$(ssh -o StrictHostKeyChecking=no -i inventory/id_openstack.rsa centos@10.8.250.104 sudo ip -o -4  address show  | awk ' NR==2 { gsub(/\/.*/, "", $4); print $4 } ')
external_ip=10.8.250.104
ssh -o StrictHostKeyChecking=no -i inventory/id_openstack.rsa -t centos@10.8.250.104 sudo 'bash -s' -- < ../kubernetes/create-k8s-cluster.sh 1.14.1 ${ip} n114-test true ${external_ip}
...
kubeadm join 172.16.195.15:6443 --token m3imk1.syzt7dj2s3wrpwpr \
    --discovery-token-ca-cert-hash sha256:ecedb846b8d263fdfbb6ab6591e41896c08e4f3ce04f522e649b42ba7763c22b 
```
- To test if the Component Operator is working with the `OABroker, ServiceCatalog`, install it with an example of `Component CR` and check the pods created
```bash
ssh -o StrictHostKeyChecking=no -i inventory/id_openstack.rsa -t centos@10.8.250.104 sudo 'bash -s' -- < ../kubernetes/test-component-operator.sh
ssh -o StrictHostKeyChecking=no -i inventory/id_openstack.rsa -t centos@10.8.250.104 sudo kubectl get all,serviceinstance,servicebinding,secrets -n demo
```

- To use the k8s cluster from your local machine, execute this script and save the result locally
```bash
ssh -o StrictHostKeyChecking=no -i inventory/id_openstack.rsa -t centos@10.8.250.104 sudo 'bash -s' -- < ../kubernetes/get-k8s-config.sh > remote-k8s.cfg
export KUBECONFIG=remote-k8s.cfg 
kubectl get all -A
kubectl get pods -A
NAMESPACE               NAME                                                  READY   STATUS      RESTARTS   AGE
automation-broker-apb   automation-broker-apb                                 0/1     Completed   0          6m33s
automation-broker       automation-broker-f64d55f77-qftt7                     2/2     Running     0          6m
catalog                 catalog-catalog-apiserver-68b964b5cc-ghjx7            2/2     Running     0          7m20s
catalog                 catalog-catalog-controller-manager-6b6cfc4899-p46hv   1/1     Running     0          7m20s
kube-system             coredns-6765558d84-vkz2s                              1/1     Running     0          7m48s
kube-system             coredns-6765558d84-vvb6g                              1/1     Running     0          7m48s
kube-system             default-http-backend-6864bbb7db-vjvcw                 1/1     Running     0          7m22s
kube-system             etcd-n114-test.localdomain                            1/1     Running     0          6m43s
kube-system             kube-apiserver-n114-test.localdomain                  1/1     Running     0          6m54s
kube-system             kube-controller-manager-n114-test.localdomain         1/1     Running     0          7m2s
kube-system             kube-flannel-ds-amd64-b69s2                           1/1     Running     0          7m47s
kube-system             kube-proxy-92qwn                                      1/1     Running     0          7m47s
kube-system             kube-scheduler-n114-test.localdomain                  1/1     Running     0          6m50s
kube-system             kubernetes-dashboard-5b4b76869b-htnl8                 1/1     Running     0          7m48s
kube-system             nginx-ingress-controller-586cdc477c-rs2gb             1/1     Running     0          7m22s
kube-system             tiller-deploy-8458f6c667-thn6l                        1/1     Running     0          7m48s
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

## Manual instructions

The following section details the instructions tested before the creation of the scripts.

### Add yum repo & install kubelet, kubeadm and kubectl
```
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

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
```

### Disable SELINUX

```
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
```

### Pass bridged IPv4 traffic to iptables

Set `/proc/sys/net/bridge/bridge-nf-call-iptables` to `1` by running `sysctl net.bridge.bridge-nf-call-iptables=1` to pass bridged IPv4 traffic to iptables’ chains. This is a requirement for some CNI plugins to work, for more information please see here.

```
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
or
sysctl net.bridge.bridge-nf-call-iptables=1
```

TODO: TO BE CHECKED
```
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl -p
```

[see](https://github.com/kubernetes/kubeadm/issues/312#issuecomment-429828991)


### Start kubelet
```
systemctl start kubelet
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.99.50
```

Output
```
[root@cloud ~]# kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.99.50
[init] Using Kubernetes version: v1.14.1
[preflight] Running pre-flight checks
  [WARNING Service-Kubelet]: kubelet service is not enabled, please run 'systemctl enable kubelet.service'
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Activating the kubelet service
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [cloud localhost] and IPs [192.168.99.50 127.0.0.1 ::1]
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [cloud localhost] and IPs [192.168.99.50 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [cloud kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 192.168.99.50]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[apiclient] All control plane components are healthy after 17.003335 seconds
[upload-config] storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.14" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Skipping phase. Please see --experimental-upload-certs
[mark-control-plane] Marking the node cloud as control-plane by adding the label "node-role.kubernetes.io/master=''"
[mark-control-plane] Marking the node cloud as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[bootstrap-token] Using token: om9c9r.3pid52k7xqyymqd4
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] creating the "cluster-info" ConfigMap in the "kube-public" namespace
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.99.50:6443 --token om9c9r.3pid52k7xqyymqd4 \
    --discovery-token-ca-cert-hash sha256:14779e32e999d46c4034a86751841e9b67211d90f3f254f6b22127d303e7e037
```

# Create kube config file
```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config  
```

# Check if the pods are running
```
kubectl get pods -A
NAMESPACE     NAME                            READY   STATUS    RESTARTS   AGE
kube-system   coredns-fb8b8dccf-4p6m7         0/1     Pending   0          22m
kube-system   coredns-fb8b8dccf-dl8kt         0/1     Pending   0          22m
...
```

The coreDNS are pending has the pod was not tainted, [See](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#control-plane-node-isolation)

```
kubectl describe pods/coredns-fb8b8dccf-4p6m7 -n kube-system
Name:               coredns-fb8b8dccf-4p6m7
Namespace:          kube-system
Priority:           2000000000
PriorityClassName:  system-cluster-critical
Node:               <none>
Labels:             k8s-app=kube-dns
                    pod-template-hash=fb8b8dccf
Events:
  Type     Reason            Age                 From               Message
  ----     ------            ----                ----               -------
  Warning  FailedScheduling  26s (x18 over 24m)  default-scheduler  0/1 nodes are available: 1 node(s) had taints that the pod didn't tolerate.
```

To resolve it, execute this command

```
kubectl taint nodes --all node-role.kubernetes.io/master-
```


# Install Flannel as pod's virtual network

Setup an isolated virtual network where our pods and nodes can communicate with each other. We will be using flannel deployed as a pod inside Kubernetes as it is the most common virtual network setup used.

```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/a70459be0084506e4ec919aa1c114638878db11b/Documentation/kube-flannel.yml
kubectl get pods,ds -n kube-system
```

### Install the dashboard

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended/kubernetes-dashboard.yaml
```

### How to log to dashboard without a password

See: https://stackoverflow.com/questions/46664104/how-to-sign-in-kubernetes-dashboard, https://docs.giantswarm.io/guides/install-kubernetes-dashboard/

Create a `ClusterRoleBinding` to grant the Dashboard `serviceaccount` the role `cluster-admin`

```bash
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
```
AND disable the authentication by adding the parameter `- --enable-skip-login` to the dashboard kubernetes deployment yaml resource within the container args section
```bash
kubectl edit deployment/kubernetes-dashboard --namespace=kube-system
...
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      k8s-app: kubernetes-dashboard
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        k8s-app: kubernetes-dashboard
    spec:
      containers:
      - args:
        - --auto-generate-certificates
        - --enable-skip-login
        image: k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.1
```

### Start the proxy to access the dashboard remotely
```bash
kubectl proxy --address=192.168.99.50 --accept-hosts '.*'
```

### Setup ingress using helm

Download helm

```bash
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh
Downloading https://kubernetes-helm.storage.googleapis.com/helm-v2.13.1-linux-amd64.tar.gz
Preparing to install helm and tiller into /usr/local/bin
helm installed into /usr/local/bin/helm
tiller installed into /usr/local/bin/tiller
Run 'helm init' to configure helm.
```

Initialize helm client and Tiller server
```bash
helm init --service-account tiller
Creating /root/.helm
Creating /root/.helm/repository
Creating /root/.helm/repository/cache
Creating /root/.helm/repository/local
Creating /root/.helm/plugins
Creating /root/.helm/starters
Creating /root/.helm/cache/archive
Creating /root/.helm/repository/repositories.yaml
Adding stable repo with URL: https://kubernetes-charts.storage.googleapis.com
Adding local repo with URL: http://127.0.0.1:8879/charts
$HELM_HOME has been configured at /root/.helm.

Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.

Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
To prevent this, run `helm init` with the --tiller-tls-verify flag.
For more information on securing your installation see: https://docs.helm.sh/using_helm/#securing-your-helm-installation
Happy Helming!
```

Configure and install ingress

[See](https://kubernetes.github.io/ingress-nginx/deploy/)

Create first a `ClusterRoleBinding` for the `Tiller` serviceaccount

```bash
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
```

Install ingress using the minikube addons ingress resources (as helm chart do not work)
```bash
kubectl create -f https://raw.githubusercontent.com/snowdrop/openshift-infra/master/kubernetes/ingress/ingress-configmap.yaml
kubectl create -f https://raw.githubusercontent.com/snowdrop/openshift-infra/master/kubernetes/ingress/ingress-rbac.yaml
kubectl create -f https://raw.githubusercontent.com/snowdrop/openshift-infra/master/kubernetes/ingress/ingress-svc.yaml
kubectl create -f https://raw.githubusercontent.com/snowdrop/openshift-infra/master/kubernetes/ingress/ingress-dp.yaml
```

Check if the pod is running correctly
```bash
ubectl logs pod/nginx-ingress-controller-586cdc477c-vv7m5 -n kube-system
-------------------------------------------------------------------------------
NGINX Ingress controller
  Release:    0.23.0
  Build:      git-be1329b22
  Repository: https://github.com/kubernetes/ingress-nginx
-------------------------------------------------------------------------------
W0416 15:16:32.487382       6 flags.go:213] SSL certificate chain completion is disabled (--enable-ssl-chain-completion=false)
nginx version: nginx/1.15.9
W0416 15:16:32.494176       6 client_config.go:549] Neither --kubeconfig nor --master was specified.  Using the inClusterConfig.  This might not work.
I0416 15:16:32.495832       6 main.go:200] Creating API client for https://10.96.0.1:443
I0416 15:16:32.505274       6 main.go:244] Running in Kubernetes cluster version v1.14 (v1.14.1) - git (clean) commit b7394102d6ef778017f2ca4046abbaa23b88c290 - platform linux/amd64
I0416 15:16:32.507276       6 main.go:102] Validated kube-system/default-http-backend as the default backend.
I0416 15:16:32.999477       6 nginx.go:261] Starting NGINX Ingress controller
I0416 15:16:33.012601       6 event.go:221] Event(v1.ObjectReference{Kind:"ConfigMap", Namespace:"kube-system", Name:"nginx-load-balancer-conf", UID:"c60d2ddf-6057-11e9-935a-080027a95fa5", APIVersion:"v1", ResourceVersion:"45758", FieldPath:""}): type: 'Normal' reason: 'CREATE' ConfigMap kube-system/nginx-load-balancer-conf
I0416 15:16:33.012898       6 event.go:221] Event(v1.ObjectReference{Kind:"ConfigMap", Namespace:"kube-system", Name:"tcp-services", UID:"c60de178-6057-11e9-935a-080027a95fa5", APIVersion:"v1", ResourceVersion:"45759", FieldPath:""}): type: 'Normal' reason: 'CREATE' ConfigMap kube-system/tcp-services
I0416 15:16:33.015383       6 event.go:221] Event(v1.ObjectReference{Kind:"ConfigMap", Namespace:"kube-system", Name:"udp-services", UID:"c60ee9b6-6057-11e9-935a-080027a95fa5", APIVersion:"v1", ResourceVersion:"45760", FieldPath:""}): type: 'Normal' reason: 'CREATE' ConfigMap kube-system/udp-services
I0416 15:16:34.103349       6 event.go:221] Event(v1.ObjectReference{Kind:"Ingress", Namespace:"demo", Name:"fruit-client-sb", UID:"32c70e71-603f-11e9-bb5b-080027a95fa5", APIVersion:"extensions/v1beta1", ResourceVersion:"31128", FieldPath:""}): type: 'Normal' reason: 'CREATE' Ingress demo/fruit-client-sb
I0416 15:16:34.200848       6 nginx.go:282] Starting NGINX process
I0416 15:16:34.201242       6 leaderelection.go:205] attempting to acquire leader lease  kube-system/ingress-controller-leader-nginx...
W0416 15:16:34.206185       6 controller.go:371] Service "kube-system/default-http-backend" does not have any active Endpoint
I0416 15:16:34.206456       6 controller.go:172] Configuration changes detected, backend reload required.
I0416 15:16:34.221100       6 leaderelection.go:214] successfully acquired lease kube-system/ingress-controller-leader-nginx
I0416 15:16:34.221215       6 status.go:148] new leader elected: nginx-ingress-controller-586cdc477c-vv7m5
I0416 15:16:34.231576       6 status.go:388] updating Ingress demo/fruit-client-sb status from [{ }] to [{192.168.99.50 }]
I0416 15:16:34.239931       6 event.go:221] Event(v1.ObjectReference{Kind:"Ingress", Namespace:"demo", Name:"fruit-client-sb", UID:"32c70e71-603f-11e9-bb5b-080027a95fa5", APIVersion:"extensions/v1beta1", ResourceVersion:"47354", FieldPath:""}): type: 'Normal' reason: 'UPDATE' Ingress demo/fruit-client-sb
I0416 15:16:34.320183       6 controller.go:190] Backend successfully reloaded.
```


### Enable persistent volume

```bash
cat <<EOF | kubectl create -f - 
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv001
spec:
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 3Gi
  hostPath:
    path: /tmp/pv001
    type: ""
  persistentVolumeReclaimPolicy: Recycle
EOF

cat <<EOF | kubectl create -f - 
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv002
spec:
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 3Gi
  hostPath:
    path: /tmp/pv001
    type: ""
  persistentVolumeReclaimPolicy: Recycle
EOF

cat <<EOF | kubectl create -f - 
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv003
spec:
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 3Gi
  hostPath:
    path: /tmp/pv001
    type: ""
  persistentVolumeReclaimPolicy: Recycle
EOF

```

## Install ServiceBroker and OAB

Get and install helm chart of the k8s service-catalog
```bash
helm repo add svc-cat https://svc-catalog-charts.storage.googleapis.com
helm install svc-cat/catalog --name catalog --namespace catalog
```

Install OAB

```bash
kubectl apply -f https://raw.githubusercontent.com/cmoulliard/cloud-native/master/oab/install.yml
```

**REMARK** : OAB can also be configured to contain the Helm's charts imported from `https://kubernetes-charts.storage.googleapis.com`. Then, install it using this command
`kubectl apply -f https://raw.githubusercontent.com/cmoulliard/cloud-native/master/oab/install-helm.yml`

# Install The Component Operator

```bash
kubectl config use-context component-operator
export operator_project=$GOPATH/src/github.com/snowdrop/component-operator

kubectl create -f $operator_project/deploy/sa.yaml
kubectl create -f $operator_project/deploy/cluster-rbac.yaml
kubectl create -f $operator_project/deploy/crd.yaml
kubectl create -f $operator_project/deploy/operator.yaml
```

### Tear down

```
kubectl drain cloud --delete-local-data --force --ignore-daemonsets
kubectl delete node cloud
```
Then, on the node being removed, reset all kubeadm installed state:
```
kubeadm reset
```

Finally, delete the `kube config file`
```bash
rm -rf $HOME/.kube/config
```

### Install golang on Centos7

```bash
rpm --import https://mirror.go-repo.io/centos/RPM-GPG-KEY-GO-REPO
curl -s https://mirror.go-repo.io/centos/go-repo.repo | tee /etc/yum.repos.d/go-repo.repo
yum install golang

mkdir -p ~/go/{bin,pkg,src}
echo 'export GOPATH="$HOME/go"' >> ~/.bashrc
echo 'export PATH="$PATH:${GOPATH//://bin:}/bin"' >> ~/.bashrc
source ~/.bashrc
```

### Install Nodejs, yarn, jq

On CentOS, Fedora and RHEL, you can install Yarn via a RPM package repository.
```bash
curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
```
If you do not already have Node.js installed, you should also configure the NodeSource repository:

```bash
curl --silent --location https://rpm.nodesource.com/setup_8.x | sudo bash -
```

Then you can simply:
```bash
sudo yum install yarn
```

To install jq on centos
```bash
wget -O jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod +x ./jq
mv jq /usr/bin
```

### To use OpenShift console

Prerequisites: Nodejs, yarn, jq and go are installed

```bash
go get github.com/openshift/console && cd $GOPATH/src/github.com/openshift/console
./build.sh 

export KUBECONFIG=$HOME/.kube/config
source ./contrib/environment.sh
./bin/bridge
```

### Install the Component Operator

```bash
go get github.com/snowdrop/component-operator
export operator_project=$GOPATH/src/github.com/snowdrop/component-operator

kubectl create ns operators
kubectl create -f $operator_project/deploy/sa.yaml -n operators
kubectl create -f $operator_project/deploy/cluster-rbac.yaml -n operators
kubectl create -f $operator_project/deploy/crds/crd.yaml -n operators
kubectl create -f $operator_project/deploy/operator.yaml -n operators
```

### Test component operator

Prerequisite: Install JDK, Apache Maven and Httpie tool

```bash
wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo
yum install apache-maven
yum install httpie
```

Clone the `component-operator-demo` project and build it

```bash
git clone https://github.com/snowdrop/component-operator-demo.git && cd component-operator-demo
mvn package
```

Install for each service its Component, link, service
```bash
kubectl apply -f fruit-client-sb/target/classes/META-INF/ap4k/component.yml -n demo
kubectl apply -f fruit-backend-sb/target/classes/META-INF/ap4k/component.yml -n demo
```

### Play with the component

```bash
# Access shell of the backend pod to display the env vars
./scripts/k8s_cmd.sh fruit-backend-sb env | grep DB

./scripts/k8s_push_start.sh fruit-backend sb demo
./scripts/k8s_push_start.sh fruit-client sb demo

# look if the app jar has been upload
./scripts/k8s_cmd.sh fruit-backend-sb 'ls /deployments'

# Check the logs
./scripts/k8s_logs.sh fruit-backend-sb demo
./scripts/k8s_logs.sh fruit-client-sb demo

# Call the Rest endpoints (client or fruits)
curl --resolve fruit-client-sb:8080:192.168.99.50 -k http://fruit-client-sb:8080/api/client 
curl --resolve fruit-backend-sb:80:192.168.99.50 -k http://fruit-backend-sb/api/fruits
```

Patch the `Component` CR to switch from `innerloop` to `outerloop`
```bash
kubectl patch cp fruit-backend-sb -p '{"spec":{"deploymentMode":"outerloop"}}' --type=merge
```
