#!/usr/bin/env bash

VM_IP=${VM_IP:=127.0.0.1}
REMOTE_HOME_DIR=${REMOTE_HOME_DIR:-$HOME}
TMP_DIR=$REMOTE_HOME_DIR/tmp
VM_IP_AND_DOMAIN_NAME="$VM_IP.nip.io"

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
CN = "harbor.$VM_IP_AND_DOMAIN_NAME"
[x509_ext]
basicConstraints        = critical, CA:TRUE
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always, issuer:always
keyUsage                = critical, cRLSign, digitalSignature, keyCertSign
nsComment               = "OpenSSL Generated Certificate"
subjectAltName          = @alt_names
[alt_names]
DNS.1 = "harbor.$VM_IP_AND_DOMAIN_NAME"
DNS.2 = "notary.$VM_IP_AND_DOMAIN_NAME"
EOF
)
echo "$CFG"
}

log_line "RED" "Generate first the selfsigned certificate using the bash gen-selfsigned-cert.sh file !!!"

log_line "CYAN" "Add TCE repository containing the Harbor package"
tanzu package repository add tce-repo --url projects.registry.vmware.com/tce/main:v0.12.0 -n tce-repository --create-namespace

PKG_FQNAME="harbor.community.tanzu.vmware.com"
PKG_VERSION="2.4.2"
PKG_NAME="harbor"

cat <<EOF > $TMP_DIR/values-harbor.yml
namespace: harbor
hostname: harbor.$VM_IP.nip.io
port:
  https: 443
logLevel: info
enableContourHttpProxy: true
tlsCertificateSecretName: harbor-tls
EOF

log_line "CYAN" "Populate the password and append additional secret keys to the values file"
imgpkg pull -b projects.registry.vmware.com/tce/harbor -o $TMP_DIR/harbor
$TMP_DIR/harbor/config/scripts/generate-passwords.sh >> $TMP_DIR/values-harbor.yml
head -n -1 $TMP_DIR/values-harbor.yml > $TMP_DIR/new-values-harbor.yml; mv $TMP_DIR/new-values-harbor.yml $TMP_DIR/values-harbor.yml

log_line "CYAN" "Create the harbor-tls kubernetes secret containing the crt and key files"
kubectl create ns harbor
kubectl create -n harbor secret generic harbor-tls \
  --type=kubernetes.io/tls \
  --from-file=$TMP_DIR/certs/harbor.$VM_IP.nip.io/tls.crt \
  --from-file=$TMP_DIR/certs/harbor.$VM_IP.nip.io/tls.key

tanzu package install $PKG_NAME -p $PKG_FQNAME -v $PKG_VERSION -n tce-repository -f $TMP_DIR/values-$PKG_NAME.yml

HARBOR_PWD_STR=$(cat $TMP_DIR/values-$PKG_NAME.yml | grep harborAdminPassword)
IFS=': ' && read -a strarr <<< $HARBOR_PWD_STR
HARBOR_PWD=${strarr[1]}

log_line "YELLOW" ""
log_line "YELLOW" "Harbor URL: https://harbor.$VM_IP.nip.io and admin password: $HARBOR_PWD"
log_line "YELLOW" ""
log_line "YELLOW" "To allow locally to pull/push an image to the private registry, then copy the tls.crt file to the docker certificates folder: /etc/docker/certs.d/harbor.$VM_IP.nip.io/"
log_line "YELLOW" "sudo cp $TMP_DIR/certs/harbor.$VM_IP.nip.io/tls.crt /etc/docker/certs.d/harbor.$VM_IP.nip.io/"
log_line "YELLOW" ""
log_line "YELLOW" "Log on: docker login harbor.$VM_IP.nip.io -u admin -p $HARBOR_PWD"
log_line "YELLOW" "Tag and push an image:"
log_line "YELLOW" "docker pull gcr.io/google-samples/hello-app:1.0"
log_line "YELLOW" "docker tag gcr.io/google-samples/hello-app:1.0 harbor.$VM_IP.nip.io/library/hello-app:1.0"
log_line "YELLOW" "docker push harbor.$VM_IP.nip.io/library/hello-app:1.0"
log_line "YELLOW" ""
log_line "YELLOW" "Create a kubernetes pod to verify if the cluster can pull the image: "
log_line "YELLOW" "kubectl create deployment hello --image=harbor.$VM_IP.nip.io/library/hello-app:1.0"
log_line "YELLOW" "kubectl rollout status deployment/hello"
log_line "YELLOW" "deployment "hello" successfully rolled out"
log_line "YELLOW" ""
log_line "YELLOW" "To push/pull images from the Harbor registry using a pod, create a secret and configure the imagePullSecrets of the service account"
log_line "YELLOW" "kubectl -n <NAMESPACE> create secret docker-registry harbor-creds \""
log_line "YELLOW" "    --docker-server=harbor.$VM_IP.nip.io \""
log_line "YELLOW" "    --docker-username=admin \""
log_line "YELLOW" "    --docker-password=$HARBOR_PWD"
log_line "YELLOW" "kubectl patch serviceaccount <ACCOUNT_NAME> -n <NAMESPACE> -p '{"imagePullSecrets": [{"name": "harbor-creds"}]}'"