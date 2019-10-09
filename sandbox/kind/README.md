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

- Create the Kind cluster
```bash
kind delete cluster --name halkyon
kind create cluster --name halkyon --config kind-config.yml
export KUBECONFIG="$(kind get kubeconfig-path --name="halkyon")"
kubectl cluster-info
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

secretname=$(kubectl get serviceaccount default --namespace=kube-system -o jsonpath='{.secrets[0].name}')
kubectl get secret "$secretname" --namespace=kube-system -o template --template='{{.data.token}}' | base64 --decode
```  
- Open your browser at this address `http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login`, copy/paste the token
  and enjoy your K8s experience

## Issue

- x509 certificate unauthorized: https://github.com/kubernetes-sigs/kind/issues/110#issuecomment-517433525
