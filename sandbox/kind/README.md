# How to create a kind cluster

- Create a Centos7 VM where a docker daemon is running
- Install kind tool
```bash
curl -Lo ./kind https://github.com/kubernetes-sigs/kind/releases/download/v0.5.1/kind-$(uname)-amd64
chmod +x ./kind
mv ./kind /usr/loca/bin/kind
```

- Add the IP Address of your VM running docker as it will be used to register the K8s Api server. If you don't specify it, then
  Kind will use as ApiServer - `0.0.0.0`
```bash
echo '
kind: Cluster
apiVersion: kind.sigs.k8s.io/v1alpha3
networking:
  apiServerAddress: 192.168.99.50
' > kind-config.yml
```  

**Remark**: More info about the config is available here : https://github.com/kubernetes-sigs/kind/blob/master/pkg/apis/config/v1alpha3/types.go

**Warning**: If you can access the Virtualbox VM, check if the `vboxnet0` network is still working and if it fails, reset it using the script `/virtualbox/reset-vboxnet0.sh`
- Create the Kind cluster
```bash
kind delete cluster --name halkyon
kind create cluster --name halkyon \
  --config kind-config.yml \
  --image kindest/node:v1.14.6@sha256:464a43f5cf6ad442f100b0ca881a3acae37af069d5f96849c1d06ced2870888d
export KUBECONFIG="$(kind get kubeconfig-path --name="halkyon")"
kubectl cluster-info
```

The k8s version available can be found here: https://hub.docker.com/r/kindest/node/tags
```bash
examples of images
  --image kindest/node:v1.13.10@sha256:2f5f882a6d0527a2284d29042f3a6a07402e1699d792d0d5a9b9a48ef155fa2a
  --image kindest/node:v1.15.3@sha256:27e388752544890482a86b90d8ac50fcfa63a2e8656a96ec5337b902ec8e5157
```
- Next, install the console
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta4/aio/deploy/recommended.yaml
kubectl proxy
Starting to serve on 127.0.0.1:8001
```


- To use a token to access the console, follow these instructions: https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md
  and create a ServiceAccount and ClusterRoleBinding.
```bash
echo '
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
' | kc apply -f - -n kubernetes-dashboard

echo '
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
' | kc apply -f - -n kubernetes-dashboard
```

- Now we need to find token we can use to log in. Execute following command:
```bash
kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')

OR

secretname=$(kubectl get serviceaccount admin-user --namespace=kubernetes-dashboard -o jsonpath='{.secrets[0].name}')
kubectl get secret "$secretname" --namespace=kubernetes-dashboard -o template --template='{{.data.token}}' | base64 --decode
```  
- Open your browser at this address `http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login`, copy/paste the token
  and enjoy your K8s experience

## Issue

- x509 certificate unauthorized: https://github.com/kubernetes-sigs/kind/issues/110#issuecomment-517433525

## TODO

Update docker ansible playbook to be able to install more recent version as docker 1.13 dont work with k8s 1.13 image
```bash
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
curl -SsL https://get.docker.com | bash
sudo usermod -aG docker centos

sed -i 's/dockerd\ \-H\ fd\:\/\//dockerd/g' /lib/systemd/system/docker.service
cat /usr/lib/systemd/system/docker.service
systemctl daemon-reload
systemctl restart docker
systemctl status docker.service
```
