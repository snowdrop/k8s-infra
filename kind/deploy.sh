#!/usr/bin/env bash

#
# Script creating a Kubernetes cluster using kind tool
# deploying a private docker registry and kourier to route the traffic
#
# Creation: March 8 Feb - 2023
#
# Add hereafter changes done post creation date as backlog
#
# Feb 8th 2023:
#
# -
#

set -o errexit

######################
# Logging and Output #
######################

# Defining some colors for output
NC='\033[0m' # No Color
COLOR_RESET="\033[0m" # Reset color
BLACK="\033[0;30m"
BLUE='\033[0;34m'
BROWN="\033[0;33m"
GREEN='\033[0;32m'
GREY="\033[0;90m"
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
RED='\033[0;31m'
PURPLE="\033[0;35m"
WHITE='\033[0;37m'
YELLOW='\033[0;33m'

log_message() {
    VERBOSITY_LEVEL=$1
    MESSAGE="${@:2}"
    if [ "${LOGGING_VERBOSITY}" -ge "${VERBOSITY_LEVEL}" ]; then
        echo -e "${MESSAGE}"
    fi
}

repeat_char(){
    COLOR=${1}
	for i in {1..70}; do echo -ne "${!COLOR}$2${NC}"; done
}

msg() {
    VERBOSITY_LEVEL=${1}
    COLOR=${2}
    MSG="${@:3}"
    # echo -e "\n${!COLOR}## ${MSG}${NC}"
    log_message ${VERBOSITY_LEVEL} "\n${!COLOR}## ${MSG}${NC}"
}

succeeded() {
    VERBOSITY_LEVEL=$1
    MSG="${@:2}"
#   echo -e "${GREEN}NOTE:${NC} $1"
    log_message ${VERBOSITY_LEVEL} "${GREEN}SUCCESS:${NC} ${MSG}"
}

note() {
    VERBOSITY_LEVEL=$1
    MSG="${@:2}"
#   echo -e "${BLUE}NOTE:${NC} $1"
    log_message ${VERBOSITY_LEVEL} "${BLUE}NOTE:${NC} ${MSG}"
}

warn() {
#   echo -e "${YELLOW}WARN:${NC} $1"
    log_message 1 "${YELLOW}WARN:${NC} $1"
}

error() {
#   echo -e "${RED}ERROR:${NC} $1"
    log_message 0 "${RED}ERROR:${NC} $1"
}

log() {
    VERBOSITY_LEVEL=${1}
    COLOR=${2}
    MSG="${@:3}"
    echo; repeat_char ${COLOR} '#'; msg ${1} ${MSG}; repeat_char ${COLOR} '#'; echo
}

#######################
# /Logging and Output #
#######################


print_logo() {
    log_message "1" ""
    log_message "1" "Welcome to our"
    log_message "1" "                                                                   "
    log_message "1" "   _____                                  _                        "
    log_message "1" "  / ____|                                | |                       "
    log_message "1" " | (___    _ __     ___   __      __   __| |  _ __    ___    _ __  "
    log_message "1" "  \___ \  | '_ \   / _ \  \ \ /\ / /  / _  | |  __|  / _ \  | \ _ \ "
    log_message "1" "  ____) | | | | | | (_) |  \ V  V /  | (_| | | |    | (_) | | |_) |"
    log_message "1" " |_____/  |_| |_|  \___/    \_/\_/    \__,_| |_|     \___/  |  __/ "
    log_message "1" "                                                            | |    "
    log_message "1" "                                                            |_|    "
    log_message "1" "Managing a kubernetes cluster using kind"
    log_message "1" ""
    note "5" "Variables used:"
    note "5" ""
    note "5" "CLUSTER_NAME: ${CLUSTER_NAME}"
    note "5" "DELETE_KIND_CLUSTER: ${DELETE_KIND_CLUSTER}"
    note "5" "INGRESS: ${INGRESS}"
    note "5" "KNATIVE_VERSION: ${KNATIVE_VERSION}"
    note "5" "KUBERNETES_VERSION: ${KUBERNETES_VERSION}"
    note "5" "LOGGING_VERBOSITY: ${LOGGING_VERBOSITY}"
    note "5" "REGISTRY_IMAGE_VERSION: ${REGISTRY_IMAGE_VERSION}"
    note "5" "REGISTRY_PASSWORD: ${REGISTRY_PASSWORD}"
    note "5" "REGISTRY_PORT: ${REGISTRY_PORT}"
    note "5" "REGISTRY_USER: ${REGISTRY_USER}"
    note "5" "SECURE_REGISTRY: ${SECURE_REGISTRY}"
    note "5" "SERVER_IP: ${SERVER_IP}"
    note "5" "SHOW_HELP: ${SHOW_HELP}"
    note "5" "USE_EXISTING_CLUSTER: ${USE_EXISTING_CLUSTER}"
}

show_usage() {
    log_message "0" ""
    log_message "0" "Usage: "
    log_message "0" "\t./deploy.sh command [parameters,...]"
    log_message "0" ""
    log_message "0" "Available commands: "
    log_message "0" "\tinstall:\t\t\t\tInstall the kind cluster"
    log_message "0" "\tremove:\t\t\t\t\tRemove the kind cluster"
    log_message "0" ""
    log_message "0" "Required parameters: "
    log_message "0" "\t--ingress [nginx,kourier]:\t\tIngress to be deployed. One of nginx,kourier."
    log_message "0" ""
    log_message "0" "Optional parameters: "
    log_message "0" "\t-h, --help:\t\t\t\tThis help message"
    log_message "0" ""
    log_message "0" "\t--cluster-name <name>\t\t\tName of the cluster. Default: kind"
    log_message "0" "\t--delete-kind-cluster\t\t\tDeletes the Kind cluster prior to creating a new one. Default: No"
    log_message "0" "\t--knative-version <version>\t\tKNative version to be used. Default: 1.9.0"
    log_message "0" "\t--kubernetes-version <version>\t\tKubernetes version to be install. Default: latest"
    log_message "0" "\t--provider <provider>\t\t\tContainer Runtime [docker,podman]. Default: docker"
    log_message "0" "\t--port-map <port map list>\t\tList of ports to map on kind config. e.g. 'ContainerPort1:HostPort1,ContainerPort2:HostPort2,...'"
    log_message "0" "\t--registry-image-version <version>\tVersion of the registry container to be used. Default: 2.6.2"
    log_message "0" "\t--registry-password <password>\t\tRegistry user password. Default: snowdrop"
    log_message "0" "\t--registry-port <port>\t\t\tPort to publish the registry. Default: 5000"
    log_message "0" "\t--registry-user <user>\t\t\tRegistry user. Default: admin"
    log_message "0" "\t--secure-registry\t\t\tSecure the docker registry. Default: No"
    log_message "0" "\t--server-ip <ip-address>\t\tIP address to be used. Default: 127.0.0.1"
    log_message "0" "\t--use-existing-cluster\t\t\tUses existing kind cluster if it already exists. Default: No"
    log_message "0" "\t-v, --verbosity <value>\t\t\tLogging verbosity (0..9). Default: 1"
    log_message "0" "\t\t\t\t\t\tA verbosity setting of 0 logs only critical events."
}

check_pre_requisites() {
    note "1" "Checking pre requisites..."

    note "1" "Checking if kind exists..."
    if ! command -v kind &> /dev/null; then
        error "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        error "kind is not installed"
        error "Use a package manager (i.e 'brew install kind') or visit the official site https://kind.sigs.k8s.io"
        exit 1
    fi
    succeeded "1" "...passed!"

    if [ ${COMMAND} == "install" ]; then
        note "1" "Checking if kubectl exists..."
        if ! command -v kubectl &> /dev/null; then
            error "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            error "Please install kubectl 1.15 or higher"
            exit 1
        fi
        succeeded "1" "...passed!"

        note "1" "Checking if helm exists..."
        if ! command -v helm &> /dev/null; then
            error "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            error "Helm could not be found. To get helm: https://helm.sh/docs/intro/install/"
            error "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            exit 1
        fi
        succeeded "1" "...passed!"

        note "1" "Checking helm version..."
        log_message "5" "helm version"
        HELM_VERSION=$(helm version 2>&1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+') || true
        if [[ ${HELM_VERSION} < "v3.0.0" ]]; then
            error "Please upgrade helm to v3.0.0 or higher"
            exit 1
        fi
        succeeded "1" "...passed!"

        note "1" "Checking kubectl version..."
        log_message "5" "kubectl version -o json 2> /dev/null | jq -r '.clientVersion.gitVersion' | cut -d. -f2"
        KUBE_CLIENT_VERSION=$(kubectl version -o json 2> /dev/null | jq -r '.clientVersion.gitVersion' | cut -d. -f2) || true
        if [[ ${KUBE_CLIENT_VERSION} -lt 14 ]]; then
            error "Please update kubectl to 1.15 or higher"
            exit 1
        fi
        succeeded "1" "...passed."
    fi
    succeeded "1" "...pre requisites check passed!"
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
CN = localhost

[x509_ext]
basicConstraints        = critical, CA:TRUE
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always, issuer:always
keyUsage                = critical, cRLSign, digitalSignature, keyCertSign
nsComment               = "OpenSSL Generated Certificate"
subjectAltName          = @alt_names

[alt_names]
DNS.1 = kind-registry
DNS.2 = localhost
DNS.3 = registry.local
DNS.4 = ${SERVER_IP}.sslip.io
EOF
)
echo "$CFG"
}

delete_kind_cluster() {
    note "1" "Checking if cluster exists..."
    existing_kind_cluster=''
    get_kind_cluster existing_kind_cluster
    note "5" "${existing_kind_cluster}"
    if [ ! "${existing_kind_cluster}" == "" ]; then
        warn "Deleting kind cluster ${CLUSTER_NAME}..."
        note "5" "kind delete cluster -n ${CLUSTER_NAME}"
        kind delete cluster -n ${CLUSTER_NAME}
        succeeded "1" "...kind cluster deleted!"
    else
        warn "...no kind cluster found!"
    fi
    note "1" "Checking if kind registry container exists..."
    #docker_container_id=$(docker container ls --filter name=^kind-registry$ --all --quiet)
    docker_container_id=$(${CRI_PROVIDER} container ls --filter name=^${CLUSTER_NAME}-registry$ --all --quiet)
    if [ ! ${docker_container_id} == "" ]; then
        note "1" "...yes, removing docker kind registry container..."
        ${CRI_PROVIDER} container rm ${CLUSTER_NAME}-registry -f
        succeeded "1" "Docker kind registry container removed."
    else 
        note "1" "...no, that was easy!"
    fi

    if [ "${CRI_PROVIDER}" == 'podman' ]; then
        note "1" "Check if podman Control Plane container exists..."
        podman_cp_container_name="${CLUSTER_NAME}-control-plane"
        podman_cp_container_id=$(${CRI_PROVIDER} container ls --filter name=^${podman_cp_container_name}$ --all --quiet)
        if [ ! ${podman_cp_container_id} == "" ]; then
            note "1" "Delete control Plane container..."
            ${CRI_PROVIDER} container stop ${CLUSTER_NAME}-control-plane
            ${CRI_PROVIDER} container rm ${CLUSTER_NAME}-control-plane
            succeeded "...done"
        else
            note "1" "...no, so nothing to be done!"
        fi
    fi


}

deploy_ingress_kourier() {
  note "1" "Deploying KNative Ingress"
  echo "Install the required custom resources of knative"
  kubectl apply -f https://github.com/knative/serving/releases/download/knative-v${KNATIVE_VERSION}/serving-crds.yaml

  note "1" "Install the core components of Knative Serving"
  kubectl apply -f https://github.com/knative/serving/releases/download/knative-v${KNATIVE_VERSION}/serving-core.yaml
  kubectl -n knative-serving rollout status deployment activator
  kubectl -n knative-serving rollout status deployment autoscaler
  kubectl -n knative-serving rollout status deployment controller
  kubectl -n knative-serving rollout status deployment domain-mapping
  kubectl -n knative-serving rollout status deployment domainmapping-webhook
  kubectl -n knative-serving rollout status deployment webhook

  note "1" "Install the Knative Kourier controller"
  kubectl apply -f https://github.com/knative/net-kourier/releases/download/knative-v${KNATIVE_VERSION}/kourier.yaml
  kubectl -n knative-serving rollout status deployment net-kourier-controller
  kubectl -n kourier-system rollout status deployment 3scale-kourier-gateway

  note "1" "Configure Knative Serving to use Kourier by default"
  kubectl patch configmap/config-network \
    -n knative-serving \
    --type merge \
    -p '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'

  note "1" "Configure the Knative domain to: $SERVER_IP.nip.io"
  KNATIVE_DOMAIN="${SERVER_IP}.nip.io"
  kubectl patch configmap/config-domain \
    -n knative-serving \
    -p "{\"data\": {\"$KNATIVE_DOMAIN\": \"\"}}"

  note "1" "Patching the kourier service to use the nodePort 31080 and type nodePort"
  kubectl patch -n kourier-system svc kourier --type='json' -p='[{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 31080}]'
  kubectl patch -n kourier-system svc kourier --type='json' -p='[{"op": "replace", "path": "/spec/ports/1/nodePort", "value": 31443}]'
  kubectl patch -n kourier-system svc kourier --type='json' -p='[{"op": "replace", "path": "/spec/type", "value": "NodePort"}]'

  note "0" "####### TO TEST ########"
  note "0" "Execute the following commands: "
  knCmd="cat <<-EOF | kubectl apply -f -
  apiVersion: serving.knative.dev/v1
  kind: Service
  metadata:
    name: hello
  spec:
    template:
      spec:
        containers:
        - image: gcr.io/knative-samples/helloworld-go
          env:
          - name: TARGET
            value: Go Hello example
EOF"

  note "0" "$knCmd"
  note "0" "Then wait till the pods are created before to curl it: http://hello.default.${SERVER_IP}.nip.io"
  note "0" "Sometimes the revision hangs as deployment has been modified, then do"
  note "0" "kubectl scale --replicas=0 deployment/hello-00001-deployment"
  note "0" "kubectl scale --replicas=1 deployment/hello-00001-deployment"
}

deploy_ingress_nginx() {
  note "1" "Deploying nginx Ingress"
  #
  # Install the ingress nginx controller using helm
  # Set the Service type as: NodePort (needed for kind)
  #
  note "1" "Installing the ingress controller using Helm within the namespace: ingress"
  helm upgrade --install ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --namespace ingress --create-namespace \
    --set controller.service.type=NodePort \
    --set controller.hostPort.enabled=true \
    --set controller.watchIngressWithoutClass=true
}

deploy_docker_registry() {
    # Document the local registry
    # https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${REGISTRY_PORT}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

    if [ "${SECURE_REGISTRY}" == 'y' ]; then
        note "1" "Securing registry..."
        note "1" "==== Create the htpasswd file where user: ${REGISTRY_USER} and password: ${REGISTRY_PASSWORD}"
        mkdir -p auth
        ${CRI_PROVIDER} run --entrypoint htpasswd registry:2.7.0 -Bbn ${REGISTRY_USER} ${REGISTRY_PASSWORD} > auth/htpasswd

        note "1" "==== Creating a docker registry"
        ${CRI_PROVIDER} run -d \
            -p 5000:5000 \
            --restart=always \
            --name ${registry_name} \
            -v $(pwd)/auth:/auth \
            -v $(pwd)/certs/${registry_server}:/certs \
            -e REGISTRY_AUTH=htpasswd \
            -e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" \
            -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
            -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/client.crt \
            -e REGISTRY_HTTP_TLS_KEY=/certs/client.key \
            registry:${REGISTRY_IMAGE_VERSION}

        # connect the container registry to the cluster network
        # (the network may already be connected)
        ${CRI_PROVIDER} network connect kind "${registry_name}" --alias registry.local || true

        # Upload the self-signed certificate to the kind container
        name="${name:-"kind"}"
        containers="$(kind get nodes --name="$name" 2>/dev/null)"
        if [[ "$containers" == "" ]]; then
            log_message "1" "No kind nodes found for cluster \"$name\"" >&2
            exit 1
        fi

        CERT_DIR=/usr/local/share/ca-certificates
        certfile="certs/${registry_server}/client.crt"

        while IFS= read -r container; do
            log_message "1" "==== Copying ${certfile} to ${container}:${CERT_DIR}"
            docker cp "$certfile" "${container}:${CERT_DIR}"

            log_message "1" "==== Updating CA certificates in ${container}..."
            docker exec "$container" update-ca-certificates

            log_message "1" "==== Restarting containerd"
            docker exec "$container" systemctl restart containerd
        done <<< "$containers"

        log_message "1" "Copy the client.crt to the docker cert.d folder"
        sudo mkdir -p /etc/docker/certs.d/${SERVER_IP}.sslip.io:5000
        sudo cp $certfile /etc/docker/certs.d/${SERVER_IP}.sslip.io:5000/ca.crt
        sudo service docker restart

        log_message "1" "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        log_message "1" "Log on to the docker registry using the address and user/password"
        log_message "1" "docker login ${SERVER_IP}.sslip.io:5000 -u ${REGISTRY_USER} -p ${REGISTRY_PASSWORD}"
        log_message "1" "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"

        popd
    else
        note "1" "Start a local Docker registry (unless it is already started)"
        # Start a local Docker registry (unless it already exists)
        running="$(${CRI_PROVIDER} inspect -f '{{.State.Running}}' "${registry_name}" 2>/dev/null || true)"
        if [ "${running}" != 'true' ]; then
            ${CRI_PROVIDER} run \
            -d --restart=always -p "${REGISTRY_PORT}:5000" --name "${registry_name}" \
            registry:2
        fi

        # Connect the local Docker registry with the kind network
        ${CRI_PROVIDER} network connect "kind" "${registry_name}" > /dev/null 2>&1 &
        if [ "${CRI_PROVIDER}" == 'podman' ]; then
            warn "Set the kind registry as an insecure registry by adding the following configuration to the /etc/containers/registries.conf.d/kind-registry.conf file"
            log_message "0" '[[registry]]'
            log_message "0" 'location = "localhost:5000"'
            log_message "0" 'insecure = true'
        fi
    fi

}

get_kind_cluster() {
    eval "$1=$(kind get clusters | { grep "${CLUSTER_NAME}" || test $? = 1; })"
}

deploy_kind_cluster() {

    if [ "${SECURE_REGISTRY}" == 'y' ]; then
        if [ ! -d ${temp_cert_dir} ];then
            mkdir -p _tmp
        fi
        # Generate the Self signed certificate using openssl
        pushd $temp_cert_dir
        mkdir -p certs/${registry_server}

        note "1" "==== Generate the openssl config"
        create_openssl_cfg > req.cnf

        note "1" "==== Create the self signed certificate certificate and client key files"
        openssl req -x509 \
            -nodes \
            -days 365 \
            -newkey rsa:4096 \
            -keyout certs/${registry_server}/client.key \
            -out certs/${registry_server}/client.crt \
            -config req.cnf \
            -sha256
        kindCfgContainerdConfigPatches=$(cat <<EOF
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.local:${REGISTRY_PORT}"]
    endpoint = ["https://registry.local:${REGISTRY_PORT}"]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."${SERVER_IP}.sslip.io:${REGISTRY_PORT}"]
    endpoint = ["https://${SERVER_IP}.sslip.io:${REGISTRY_PORT}"]
  [plugins."io.containerd.grpc.v1.cri".registry.configs."registry.local:${REGISTRY_PORT}".tls]
    cert_file = "/etc/docker/certs.d/${registry_server}/client.crt"
    key_file  = "/etc/docker/certs.d/${registry_server}/client.key"
EOF
)

        kindCfgExtraMounts=$(cat <<EOF
extraMounts:
  - containerPath: /etc/docker/certs.d/${registry_server}
    hostPath: $(pwd)/certs/${registry_server}
EOF
)
    else
        kindCfgContainerdConfigPatches=$(cat <<EOF
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${REGISTRY_PORT}"]
    endpoint = ["http://${registry_name}:${REGISTRY_PORT}"]
EOF
)
    fi

    kindCmd="kind -v ${LOGGING_VERBOSITY} create cluster  -n ${CLUSTER_NAME}"
    kindExtraPortMappings=$(cat <<EOF
  - containerPort: ${CONTAINER_80_PORT}
    hostPort: ${HOST_80_PORT}
    protocol: TCP
    listenAddress: "0.0.0.0"
  - containerPort: ${CONTAINER_443_PORT}
    hostPort: ${HOST_443_PORT}
    protocol: TCP
    listenAddress: "0.0.0.0"
EOF
)
    IFS=',' read -ra ADDR <<< "${PORT_MAP}"
    for i in "${ADDR[@]}"; do
        IFS=':' read -ra PORTS <<< "${i}"
        kindExtraPortMappings+=$(cat <<EOF

  - containerPort: ${PORTS[0]}
    hostPort: ${PORTS[1]}
    protocol: TCP
    listenAddress: "0.0.0.0"
EOF
)
    done

# Kind cluster config template
    kindCfg=$(cat <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  apiServerAddress: "${SERVER_IP}"
containerdConfigPatches:
${kindCfgContainerdConfigPatches}
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
        authorization-mode: "AlwaysAllow"
  ${kindCfgExtraMounts}
  extraPortMappings:
${kindExtraPortMappings}
EOF
)
    note "5" "kindCfg: ${kindCfg}"

    if [ "$DELETE_KIND_CLUSTER" == "y" ]; then
        note "0" "Deleting Kind cluster..."
        delete_kind_cluster
        succeeded "1" "...done!"
    fi

    note "1" "Checking if kind cluster exists..."
    kind_get_clusters=$(kind get clusters | { grep "${CLUSTER_NAME}" || test $? = 1; }) 
    if [ ! "${kind_get_clusters}" == "" ]; then
        note "1" "Cluster already exists..."
        if [ "$USE_EXISTING_CLUSTER" == "y" ]; then
            note "1" "...using existing cluster. Exporting cluster kubeconfig..."
            note "5" "CMD: kind export kubeconfig -n ${CLUSTER_NAME}"
            kind export kubeconfig -n ${CLUSTER_NAME}
            succeeded "1" "...done!"
        else
            error "Cluster already exists. Either use the existing cluster (--use-existing-cluster) or delete the cluster (--delete-kind-cluster)."
            exit 1
        fi
    else 
        note "1" "=== Get the tag version of the image to be installed for the kubernetes version: ${KUBERNETES_VERSION} ..."
        if [ ${KUBERNETES_VERSION} == "latest" ]; then
            kindCmd+=""
        else
            kind_image_sha=$(wget -q https://raw.githubusercontent.com/snowdrop/k8s-infra/main/kind/images.json -O - | \
            jq -r --arg VERSION "$KUBERNETES_VERSION" '.[] | select(.k8s == $VERSION).sha')
            kindCmd+=" --image ${kind_image_sha}"
        fi
        note "1" "Creating a Kind cluster using kindest/node: ${KUBERNETES_VERSION} and logging verbosity: ${LOGGING_VERBOSITY}"
        echo "${kindCfg}" | ${kindCmd} --config=-
    fi
}

function install() {
    deploy_kind_cluster

    deploy_docker_registry

    note "1" "INGRESS: ${INGRESS}"
    if [ "${INGRESS}" == 'kourier' ]; then
        deploy_ingress_kourier
    elif [ "${INGRESS}" == 'nginx' ]; then
        deploy_ingress_nginx
    fi
}

function remove() {
    delete_kind_cluster
    note "1" "Removing ${CRI_PROVIDER} network..."
    note "1" "Checking if ${CRI_PROVIDER} network exists..."
    docker_network_id=$(${CRI_PROVIDER} network ls --filter name=^kind$ --quiet)
    if [ ! ${docker_network_id} == "" ]; then
        note "1" "...yes, removing ${CRI_PROVIDER} network..."
        ${CRI_PROVIDER} network rm kind
        succeeded "1" "${CRI_PROVIDER} network removed."
    else 
        note "1" "...no, nothing to be done then."
    fi
}

function validate_ingress() {
    if [ "${INGRESS}" == 'kourier' ]; then
        CONTAINER_80_PORT=31080
        CONTAINER_443_PORT=31443
    elif [ "${INGRESS}" == 'nginx' ]; then
        CONTAINER_80_PORT=80
        CONTAINER_443_PORT=443
    else
        error "Invalid ingress ${INGRESS}."
        show_usage
        exit 1  
    fi
}

function validate_cri() {
    note "1" "CRI Provider: ${CRI_PROVIDER}"
    if [ "${CRI_PROVIDER}" == 'docker' ]; then
        unset KIND_EXPERIMENTAL_PROVIDER
        HOST_80_PORT=80
        HOST_443_PORT=443
    elif [ "${CRI_PROVIDER}" == 'podman' ]; then
        export KIND_EXPERIMENTAL_PROVIDER=podman
        HOST_80_PORT=30080
        HOST_443_PORT=30443
    else
        error "Invalid CRI provider ${CRI_PROVIDER}."
        show_usage
        exit 1  
    fi
}
##### /Functions

###### Command Line Parser
CLUSTER_NAME="kind"
DELETE_KIND_CLUSTER="n"
KNATIVE_VERSION="1.9.0"
KUBERNETES_VERSION="latest"
LOGGING_VERBOSITY="1"
REGISTRY_IMAGE_VERSION="2.6.2"
REGISTRY_PASSWORD="snowdrop"
REGISTRY_PORT="5000"
REGISTRY_USER="admin"
SECURE_REGISTRY="n"
SERVER_IP="127.0.0.1"
SHOW_HELP="n"
USE_EXISTING_CLUSTER="n"
CRI_PROVIDER=docker
PORT_MAP=""

while [ $# -gt 0 ]; do
    note "9" "$1"
    if [[ $1 == *"--"* ]]; then
        param="${1/--/}";
        case $1 in
        --help) SHOW_HELP="y"; break 2 ;;
        --cluster-name) CLUSTER_NAME="$2"; shift ;;
        --delete-kind-cluster) DELETE_KIND_CLUSTER="y" ;;
        --ingress) INGRESS="$2"; shift ;;
        --knative-version) KNATIVE_VERSION="$2"; shift ;;
        --kubernetes-version) KUBERNETES_VERSION="$2"; shift ;;
        --provider) CRI_PROVIDER="$2"; shift ;;
        --port-map) PORT_MAP="$2"; shift ;;
        --registry-image-version) REGISTRY_IMAGE_VERSION="$2"; shift ;;
        --registry-password) REGISTRY_PASSWORD="$2"; shift ;;
        --registry-port) REGISTRY_PORT="$2"; shift ;;
        --registry-user) REGISTRY_USER="$2"; shift ;;
        --secure-registry) SECURE_REGISTRY="y" ;;
        --server-ip) SERVER_IP="$2"; shift ;;
        --use-existing-cluster) USE_EXISTING_CLUSTER="y"; ;;
        --verbosity) LOGGING_VERBOSITY="$2"; shift ;;
        *) INVALID_SWITCH="${INVALID_SWITCH} $1" ; break 2 ;;
        esac;
    shift
    elif [[ $1 == *"-"* ]]; then
        case $1 in
            -h) SHOW_HELP="y"; break 2 ;;
            -v) LOGGING_VERBOSITY="$2"; shift ;;
            *) INVALID_SWITCH="${INVALID_SWITCH} $1" ; break 2 ;;
        esac;
        shift
    else
        case $1 in
            install) COMMAND="install" ;;
            remove) COMMAND="remove" ;;
            *) INVALID_SWITCH="${INVALID_COMMAND} $1" ; break 2 ;;
        esac;
        shift
  fi
done

if [ "$SHOW_HELP" == "y" ]; then
    show_usage
    exit 0
elif [ -v INVALID_COMMAND ]; then
    error "Invalid command ${INVALID_COMMAND}"
    show_usage
    exit 1
elif [ -v INVALID_SWITCH ]; then
    error "Invalid switch(es) ${INVALID_SWITCH}"
    show_usage
    exit 1
elif [ ! -v COMMAND ]; then
    error "A command must be provided!!!"
    show_usage
    exit 1
elif [ ${COMMAND} == 'install' ] && [ ! -v INGRESS ]; then
    error "Ingress is not defined."
    show_usage
    exit 1
fi

###### /Command Line Parser

###### Execution

print_logo

check_pre_requisites

validate_cri

kindCfgExtraMounts=""
registry_name="${CLUSTER_NAME}-registry"
registry_server='localhost'
temp_cert_dir="_tmp"

case ${COMMAND} in
    install) validate_ingress ; install ;;
    remove) remove ;;
esac;
