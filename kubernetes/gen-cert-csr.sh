#!/bin/bash

# Input source - https://kubernetes.github.io/ingress-nginx/deploy/validating-webhook/
SERVICE_NAME=kubedb-api
NAMESPACE=kubedb

TEMP_DIRECTORY=$(mktemp -d)
echo "creating certs in directory ${TEMP_DIRECTORY}"

cat <<EOF >> ${TEMP_DIRECTORY}/csr.conf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${SERVICE_NAME}
DNS.2 = ${SERVICE_NAME}.${NAMESPACE}
DNS.3 = ${SERVICE_NAME}.${NAMESPACE}.svc
EOF

openssl genrsa -out ${TEMP_DIRECTORY}/server-key.pem 2048
openssl req -new -key ${TEMP_DIRECTORY}/server-key.pem \
    -subj "/CN=${SERVICE_NAME}.${NAMESPACE}.svc" \
    -out ${TEMP_DIRECTORY}/server.csr \
    -config ${TEMP_DIRECTORY}/csr.conf

cat <<EOF | kubectl create -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: ${SERVICE_NAME}.${NAMESPACE}.svc
spec:
  request: $(cat ${TEMP_DIRECTORY}/server.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

kubectl certificate approve ${SERVICE_NAME}.${NAMESPACE}.svc

for x in $(seq 10); do
    SERVER_CERT=$(kubectl get csr ${SERVICE_NAME}.${NAMESPACE}.svc -o jsonpath='{.status.certificate}')
    if [[ ${SERVER_CERT} != '' ]]; then
        break
    fi
    sleep 1
done
if [[ ${SERVER_CERT} == '' ]]; then
    echo "ERROR: After approving csr ${SERVICE_NAME}.${NAMESPACE}.svc, the signed certificate did not appear on the resource. Giving up after 10 attempts." >&2
    exit 1
fi
echo ${SERVER_CERT} | openssl base64 -d -A -out ${TEMP_DIRECTORY}/server-cert.pem

kubectl create secret generic kube-api.svc \
    --from-file=key.pem=${TEMP_DIRECTORY}/server-key.pem \
    --from-file=cert.pem=${TEMP_DIRECTORY}/server-cert.pem \
    -n ${NAMESPACE}
