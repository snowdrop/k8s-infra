## Additional infos

### Authentication managed by Ingress

- Ingress config: https://kubernetes.github.io/ingress-nginx/examples/auth/basic/
- Dashboard parameters : https://github.com/kubernetes/dashboard/blob/master/docs/common/dashboard-arguments.md

## Create a bootstrap token and make it part of the cluster-admin role

References:
- https://kubernetes.io/docs/reference/access-authn-authz/authentication/
- https://medium.com/@toddrosner/kubernetes-tls-bootstrapping-cf203776abc7

- Assign the `system:bootstrappers group` to the `cluster-admin` role
```bash
cat <<EOF | sudo kubectl apply -f -
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cluster-admin-for-bootstrappers
subjects:
- kind: Group
  name: system:bootstrappers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF
```

- Create the token and assign it to the group `system:bootstrappers:worker` as it will be next used to define the RBAC
```bash
kubeadm token create --print-join-command \
        --ttl=0 \
        --groups=system:bootstrappers:worker \
        --description=admin-user
kubeadm join 159.69.209.188:6443 --token osmwlc.0mqd865t3tzdfjyv --discovery-token-ca-cert-hash sha256:002ee331c1775d01304157ca459fd5488ef8bf4081c68dabdfabd8525660d7cc 
```

- Or create manually the Token
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  # Name MUST be of form "bootstrap-token-<token id>"
  name: bootstrap-token-06001c
  namespace: kube-system

# Type MUST be 'bootstrap.kubernetes.io/token'
type: bootstrap.kubernetes.io/token
stringData:
  # Human readable description. Optional.
  description: "ch006m"

  # Token ID and secret. Required.
  token-id: 06001c
  token-secret: f395accd246ae52d

  # Expiration. Optional.
  expiration: 2020-03-01T03:22:11Z

  # Allowed usages.
  usage-bootstrap-authentication: "true"
  usage-bootstrap-signing: "true"
  auth-extra-groups: system:bootstrappers:worker
EOF
```

- List the token created
```bash
kubeadm token list
TOKEN                     TTL         EXPIRES               USAGES                   DESCRIPTION   EXTRA GROUPS
06001c.f395accd246ae52d   88d         2020-03-01T03:22:11Z  authentication,signing   ch006m        system:bootstrappers:worker
osmwlc.0mqd865t3tzdfjyv   <forever>   <never>               authentication,signing   admin-user    system:bootstrappers:worker
```

## Other references

- https://stackoverflow.com/questions/43072514/kubernetes-how-to-enable-api-server-bearer-token-auth
- https://stackoverflow.com/questions/35942193/kubernetes-simple-authentication
- https://stackoverflow.com/questions/58276969/k8s-convert-kubeadm-init-command-line-arguments-to-config-yaml
- https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/control-plane-flags/

