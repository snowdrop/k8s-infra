#!/usr/bin/env bash

#
# doc links
# https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/
# https://blog.cloudflare.com/introducing-cfssl/
#

SERVICE_NAME=kube-registry
NAMESPACE=kube-system
CLUSTER_IP=${1:-172.168.0.24}
EXTERNAL_IP=${2:-195.201.87.126}
KUBECONFIG=/root/.kube/config

echo "Download and install tools"
sudo wget https://pkg.cfssl.org/R1.2/cfssl_linux-386
sudo chmod +x cfssl_linux-386
mv cfssl_linux-386 cfssl

sudo wget https://pkg.cfssl.org/R1.2/cfssljson_linux-386
sudo chmod +x cfssljson_linux-386
mv cfssljson_linux-386 cfssljson

# Common Name: 172.30.4.187 (= ClusterIP address)
# Subject Alternative Names: docker-registry-default.195.201.87.126.nip.io, docker-registry.default.svc, docker-registry.default.svc.cluster.local, 172.30.4.187, IP Address:172.30.4.187

echo "Delete any previous CSR send to k8s"
sudo kubectl --kubeconfig=${KUBECONFIG} delete csr ${SERVICE_NAME}.${NAMESPACE}

echo "Generate the pem and csr files"

cat <<EOF | ./cfssl genkey - | ./cfssljson -bare server
{
  "hosts": [
    "${SERVICE_NAME}.${NAMESPACE}.svc",
    "${SERVICE_NAME}.${NAMESPACE}.svc.cluster.local",
    "${CLUSTER_IP}",
    "IP Address: ${CLUSTER_IP}"
  ],
  "CN": "${CLUSTER_IP}",
  "key": {
    "algo": "ecdsa",
    "size": 256
  }
}
EOF

#echo "Mover them under certs folder"
#mv server.csr certs
#mv server-key.pem certs

echo "Generate a CSR yaml blob and send it to the apiserver by running the following command:"
cat <<EOF | sudo kubectl --kubeconfig=${KUBECONFIG} apply -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: ${SERVICE_NAME}.${NAMESPACE}
spec:
  groups:
  - system:authenticated
  request: $(cat server.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

sudo kubectl --kubeconfig=${KUBECONFIG} certificate approve  ${SERVICE_NAME}.${NAMESPACE}
sudo kubectl --kubeconfig=${KUBECONFIG} get csr ${SERVICE_NAME}.${NAMESPACE} -o jsonpath='{.status.certificate}' | base64 --decode > server.crt

echo "Append the CA Certificate to the generated"
sudo cat /etc/kubernetes/pki/ca.crt >> server.crt

echo "Add the ${CLUSTER_IP} certificate to the certificates supported by the docker daemon"
sudo mkdir -p /etc/docker/certs.d/${CLUSTER_IP}:5000/
sudo cp server.crt /etc/docker/certs.d/${CLUSTER_IP}:5000/

echo "Copy the self signed Certificate and Private keys under the folder that we will mount within the docker registry"
sudo mkdir -p /root/docker-certs
sudo cp server.crt /root/docker-certs
sudo cp server-key.pem /root/docker-certs

