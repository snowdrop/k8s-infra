Table of Contents
=================

* [Harbor](#harbor)
    * [Prerequisites](#prerequisites)
    * [Instructions](#instructions)
    * [Issue](#issue)
    * [Remove Harbor](#remove-harbor)
    * [Optional](#optional)

# Harbor

Instructions to deploy Harbor on a k8s cluster using the Helm chart

## Prerequisites

- k8s cluster >= 1.20
- Ingress nginx controller installed
- Persistent Volumes: 3x 1Gi, 2x5Gi, 2x50Gi or use a dynamic `local-path-provisioner` such [as](https://github.com/rancher/local-path-provisioner/) 
- Ingress-nginx

## Ingress

To install on the k8s cluster an ingress controller exposing the services under the ports `http 32080`, `https: 32443` execute this command
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
TEMP_DIR=_temp/ingress-nginx
mkdir -p $TEMP_DIR

cat <<EOF > $TEMP_DIR/values.yml
controller:
  service:
    type: NodePort
    nodePorts:
      http: 32080
      https: 32443
EOF
helm install ingress \
    -f $TEMP_DIR/values.yml \
    -n ingress-nginx \
    --create-namespace \
    ingress-nginx/ingress-nginx
```
To remove it
```bash
helm uninstall ingress -n ingress-nginx
```

## Instructions

```bash
helm repo add harbor https://helm.goharbor.io

VM_IP=192.168.1.90
PORT=32443
TEMP_DIR=_temp/harbor
mkdir -p $TEMP_DIR
cat <<EOF > $TEMP_DIR/values.yml
expose:
  type: ingress
  tls:
    enabled: true
  ingress:
    className: "nginx"
    hosts:
      core: "registry.harbor.$VM_IP.nip.io"
      notary: "notary.harbor.$VM_IP.nip.io"
externalURL: "https://registry.harbor.$VM_IP.nip.io:$PORT"
persistence:
  enabled: true
  resourcePolicy: "keep"
  persistentVolumeClaim:
    registry:
      storageClass: local-path
      size: 50Gi
    chartmuseum:
      storageClass: local-path
    jobservice:
      storageClass: local-path  
    database:
      storageClass: local-path  
    redis:
      storageClass: local-path
    trivy:
      storageClass: local-path  
EOF

helm install harbor \
  -f $TEMP_DIR/values.yml \
  -n harbor \
  --create-namespace \
  harbor/harbor
```
Login in to the UI at the address `https://registry.harbor.$VM_IP.nip.io:$PORT` using as user `admin` and password `Harbor12345`

Next, get the certificate and trust it. Restart the docker daemon
```bash
curl -k https://registry.harbor.$VM_IP.nip.io:$PORT/api/v2.0/systeminfo/getcert > $TEMP_DIR/ca.crt
# Mac OS
mkdir -p ~/.docker/certs.d/registry.harbor.$VM_IP.nip.io:$PORT/
cp $TEMP_DIR/ca.crt ~/.docker/certs.d/registry.harbor.$VM_IP.nip.io:$PORT/
osascript -e 'quit app "Docker"'; open -a Docker
# Linux
sudo mkdir -p /etc/docker/certs.d/registry.harbor.$VM_IP.nip.io:$PORT/
sudo cp $TEMP_DIR/ca.crt /etc/docker/certs.d/registry.harbor.$VM_IP.nip.io:$PORT/
sudo systemctl restart docker

sudo cp $TEMP_DIR/ca.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
```
Tag, push an image and launch a Kubernetes's pod to test the image from harbor registry
```bash
docker login registry.harbor.$VM_IP.nip.io:$PORT -u admin -p Harbor12345
docker pull gcr.io/google-samples/hello-app:1.0
docker tag gcr.io/google-samples/hello-app:1.0 registry.harbor.$VM_IP.nip.io:$PORT/library/hello-app:1.0
docker push registry.harbor.$VM_IP.nip.io:$PORT/library/hello-app:1.0
kubectl create deployment hello --image=registry.harbor.$VM_IP.nip.io:$PORT/library/hello-app:1.0
```
**Note**: If the cluster has been created using [kind](https://kind.sigs.k8s.io/docs/user/private-registries/), then it is also needed to upload the certificate as described here otherwise you will get a `x509: certificate signed by unknown authority`

To pull/push images within the cluster, secret must be created and patched to the serviceaccount used
```bash
kubectl -n default create secret docker-registry harbor-creds \
    --docker-server=registry.harbor.$VM_IP.nip.io:$PORT \
    --docker-username=admin \
    --docker-password=Harbor12345
kubectl patch serviceaccount default -n default -p '{"imagePullSecrets": [{"name": "harbor-creds"}]}'
```

## Issue

The only limitation that we have using harbor deployed on a k8s cluster is is when you restart the cluster or VM as the harbor pod could not be ready when the kpack controller reconcilles the clusterstack CRDs. 

The workaround is to restart the kpack controller
```
kubectl rollout restart deployment/kpack-controller -n kpack
```

## Remove Harbor

```bash
helm uninstall harbor -n harbor
kubectl delete pvc/harbor-chartmuseum -n harbor
kubectl delete pvc/harbor-jobservice -n harbor
kubectl delete pvc/harbor-registry -n harbor
kubectl delete pvc/data-harbor-redis-0 -n harbor
kubectl delete pvc/data-harbor-trivy-0 -n harbor
kubectl delete pvc/database-data-harbor-database-0 -n harbor
```

## Optional

To get the chart files locally
`helm pull --untar harbor/harbor`

Generate a selfsigned certificate
```bash
VM_IP=192.168.1.90 REMOTE_HOME_DIR=$(pwd) ../scripts/tools/gen-selfsigned-cert.sh
```
To logon using a robot token - see: https://veducate.co.uk/authenticate-docker-harbor-robot/
```bash
username=$(cat robot_toto.json | jq -r .name)
password=$(cat robot_toto.json | jq -r .token)
echo "$password" | docker login https://registry.harbor.192.168.1.90.nip.io --username "$username" --password-stdin
```
