#!/usr/bin/env bash

# https://medium.com/geekculture/deploying-docker-registry-on-kubernetes-3319622b8f32

VM_IP=${VM_IP:=127.0.0.1}
REMOTE_HOME_DIR=${REMOTE_HOME_DIR:-$HOME}
TMP_DIR=$REMOTE_HOME_DIR/tmp
IP_AND_DOMAIN_NAME="$VM_IP.nip.io"

DIR=`dirname $0` # to get the location where the script is located

# Defining some colors for output
RED='\033[0;31m'
NC='\033[0m' # No Color
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

repeat_char(){
  COLOR=${1}
	for i in {1..50}; do echo -ne "${!COLOR}$2${NC}"; done
}

log_line() {
    COLOR=${1}
    MSG="${@:2}"
    echo -e "${!COLOR}## ${MSG}${NC}"
}

log_msg() {
    COLOR=${1}
    MSG="${@:2}"
    echo -e "\n${!COLOR}## ${MSG}${NC}"
}

log() {
  MSG="${@:2}"
  echo; repeat_char ${1} '#'; log_msg ${1} ${MSG}; repeat_char ${1} '#'; echo
}

repeat(){
	local start=1
	local end=${1:-80}
	local str="${2:-=}"
	local range=$(seq $start $end)
	for i in $range ; do echo -n "${str}"; done
}

create_openssl_cfg() {
CFG=$(cat <<EOF
[req]
distinguished_name = subject
x509_extensions    = x509_ext
prompt             = no
[subject]
C  = BE
ST = Namur
L  = Florennes
O  = Red Hat
OU = Snowdrop
CN = "$IP_AND_DOMAIN_NAME"
[x509_ext]
basicConstraints        = critical, CA:TRUE
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always, issuer:always
keyUsage                = critical, cRLSign, digitalSignature, keyCertSign
nsComment               = "OpenSSL Generated Certificate"
subjectAltName          = @alt_names
[alt_names]
DNS.1 = "registry.$IP_AND_DOMAIN_NAME"
EOF
)
echo "$CFG"
}

log "CYAN" "Populate a self signed certificate ..."
mkdir -p $TMP_DIR/certs/registry.$IP_AND_DOMAIN_NAME

log "CYAN" "Generate the openssl stuff"
create_openssl_cfg > $TMP_DIR/certs/req.cnf

log "CYAN" "Create the self signed certificate certificate and client key files"
openssl req -x509 \
  -nodes \
  -days 365 \
  -newkey rsa:4096 \
  -keyout $TMP_DIR/certs/registry.${IP_AND_DOMAIN_NAME}/tls.key \
  -out $TMP_DIR/certs/registry.${IP_AND_DOMAIN_NAME}/tls.crt \
  -config $TMP_DIR/certs/req.cnf \
  -sha256

#log_line "CYAN" "Copy the tls.crt under /usr/local/share/ca-certificates/$VM_IP.nip.io.crt and update the the ca-certificates"
log_line "CYAN" "Copy the tls.crt to /etc/pki/ca-trust/source/anchors/ and trust the certificate"
sudo cp $TMP_DIR/certs/registry.${IP_AND_DOMAIN_NAME}/tls.crt /etc/pki/ca-trust/source/anchors/registry.${IP_AND_DOMAIN_NAME}.crt
sudo update-ca-trust

log_line "CYAN" "Copy the tls.crt to /etc/docker/certs.d/registry.${IP_AND_DOMAIN_NAME} and restart docker daemon"
sudo mkdir -p /etc/docker/certs.d/registry.${IP_AND_DOMAIN_NAME}
sudo cp $TMP_DIR/certs/registry.${IP_AND_DOMAIN_NAME}/tls.crt /etc/docker/certs.d/registry.${IP_AND_DOMAIN_NAME}/ca.crt
#sudo systemctl restart docker

log_line "CYAN" "Store the certificate and private as kubernetes secret"
export KUBECONFIG=/home/centos/.kube/config
kubectl create ns images-registry
kubectl create secret tls registry-cert \
    --cert=$TMP_DIR/certs/registry.${IP_AND_DOMAIN_NAME}/tls.crt \
    --key=$TMP_DIR/certs/registry.${IP_AND_DOMAIN_NAME}/tls.key \
    -n images-registry

log_line "CYAN" "Deploy the docker registry"
cat <<EOF | kubectl apply -f -
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: registry-data-pvc
  namespace: images-registry
spec:
  storageClassName: standard
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    run: registry
  name: registry
  namespace: images-registry
spec:
  replicas: 1
  selector:
    matchLabels:
      run: registry
  template:
    metadata:
      labels:
        run: registry
    spec:
      containers:
      - name: registry
        image: registry:2
        ports:
        - containerPort: 5000
        env:
        - name: REGISTRY_HTTP_TLS_CERTIFICATE
          value: "/certs/tls.crt"
        - name: REGISTRY_HTTP_TLS_KEY
          value: "/certs/tls.key"
        volumeMounts:
        - name: registry-certs
          mountPath: "/certs"
          readOnly: true
        - name: registry-data
          mountPath: /var/lib/registry
          subPath: registry
      volumes:
      - name: registry-certs
        secret:
          secretName: registry-cert
      - name: registry-data
        persistentVolumeClaim:
          claimName: registry-data-pvc
---
apiVersion: v1
kind: Service
metadata:
  annotations:
    projectcontour.io/upstream-protocol.tls: "443"
  name: registry
  namespace: images-registry
spec:
spec:
  selector:
    run: registry
  ports:
    - name: registry-tcp
      protocol: TCP
      port: 5000
      targetPort: 5000
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: registry
  namespace: images-registry
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: HTTPS                                                                                                                      │
    projectcontour.io/ingress.class: contour                                                                                                                                 │
    service.alpha.kubernetes.io/app-protocols: '{"https":"HTTPS"}'
spec:
  ingressClassName: contour
  rules:
  - host: registry.$IP_AND_DOMAIN_NAME
    http:
      paths:
      - backend:
          service:
            name: registry
            port:
              number: 5000
        path: /
        pathType: ImplementationSpecific
  tls:
  - hosts:
    - registry.$IP_AND_DOMAIN_NAME
    secretName: registry-cert
EOF

# Test it
sleep 5
curl -v https://registry.$IP_AND_DOMAIN_NAME/v2/_catalog
