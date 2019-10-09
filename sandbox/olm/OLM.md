# To install the Operator Lifecycle Manager
```bash
./scripts/install-olm.sh 0.12.0

or

kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.12.0/crds.yaml
kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/0.12.0/olm.yaml
```

- To check if the catalog has been well deployed and contains operators
```bash
kc get CatalogSource/operatorhubio-catalog -n olm
kc get packagemanifests/halkyon -n olm
```

# To install an operator using CLI

## To be executed with a user having cluster-admin role

- Create a new project
```bash
oc new-project user1
```
- Create the `RoleBinding` for the user `user1` and by example the role `view`. This role allows
  to view the content of its project.
```bash
oc policy add-role-to-user view user1

or 

echo '
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: view
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: user1
' | kc apply -f - -n user1
```

- Next create a role that we will use to delegate more rights to the developer
```bash
echo '
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: dev:user-full-access
rules:
- apiGroups: ["", "extensions", "apps", "halkyon.io", "tekton.dev", "kubedb.com", "operators.coreos.com", "rbac.authorization.k8s.io"]
  resources: ["*"]
  verbs: ["*"]
' | kc apply -f - -n user1
```
- The `ClusterRole` allows users to lookup the necessary resources across namespaces, and to create CRDs anywhere in the cluster (which is required by the installation of the operator, in certain cases).
```bash
echo '
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: dev:user-node-readonly-access
rules:
- apiGroups: ["", "apps", "extensions"]
  resources: ["*"]
  verbs: ["get", "watch", "list"]
- apiGroups: ["apiextensions.k8s.io"]
  resources: ["customresourcedefinitions"]
  verbs: ["*"]
- apiGroups: ["rbac.authorization.k8s.io"]
  resources: ["rolebindings"]
  verbs: ["get", "watch", "list"] 
' | kc apply -f - 
```
- Next assign both Roles to the user `user1` to give they full access to their namespace
  and readonly for the other namespaces
```bash
echo '
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev:user-full-access
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: dev:user-full-access
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: user1
' | kubectl apply -f - -n user1

and 

echo '
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dev:user-node-readonly-access
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: dev:user-node-readonly-access
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: user1
' | kubectl apply -f -
```
## To be executed with a basic user - user1

- Log on as `user1`
```bash
oc login -u user1 -p user1
```
- Create an `operatorGroup` for the user 'user1'
```bash
echo '
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: user1
spec:
  targetNamespaces:
  - user1
' | kc apply -f - -n user1
```
- And finally, create a subscription using a basic user `user1`
```bash
echo '
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: halkyon
spec:
  channel: alpha
  installPlanApproval: Automatic
  name: halkyon
  source: operatorhubio-catalog
  sourceNamespace: olm
  startingCSV: halkyon.v0.1.3
' | kc apply -f - -n user1
```
