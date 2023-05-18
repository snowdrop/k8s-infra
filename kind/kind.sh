#!/usr/bin/env bash

#
# Script creating a Kubernetes cluster using kind tool
# deploying a (private) docker registry
# ingress contoller (nginx, kourier)
#
# Creation: April - 2023
#
# Add hereafter changes done post creation date as backlog
#
# MMM dd YYYY:
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

log_message_nonl() {
    VERBOSITY_LEVEL=$1
    MESSAGE="${@:2}"
    if [ "${LOGGING_VERBOSITY}" -ge "${VERBOSITY_LEVEL}" ]; then
        echo -ne "${MESSAGE}\033[0K\r"
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
    # log_message ${VERBOSITY_LEVEL} "${GREEN}\xE2\x9C\x85${NC} ${MSG}"
    log_message ${VERBOSITY_LEVEL} "${GREEN}\xE2\x9C\x94${NC} ${MSG}"
}

note() {
    VERBOSITY_LEVEL=$1
    MSG="${@:2}"
#   echo -e "${BLUE}NOTE:${NC} $1"
    log_message ${VERBOSITY_LEVEL} "${BLUE}!${NC} ${MSG}"
}

note_start_task() {
    VERBOSITY_LEVEL=$1
    MSG="${@:2}"
#   echo -e "${BLUE}NOTE:${NC} $1"
    log_message_nonl ${VERBOSITY_LEVEL} "${BLUE}!${NC} ${MSG}"
}

warn() {
#   echo -e "${YELLOW}WARN:${NC} $1"
    log_message 1 "${YELLOW}\xE2\x9A\xA0${NC} $1"
}

error() {
#   echo -e "${RED}ERROR:${NC} $1"
    log_message 0 "${RED}\xE2\x9D\x8C${NC} $1"
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
    log_message "1" "Script to create/delete a Kubernetes cluster using kind like a : "
    log_message "1" "- ingress controller (nginx, kourier)"
    log_message "1" ""
    note "5" "Variables used:"
    note "5" ""
    note "5" "CLUSTER_NAME: ${CLUSTER_NAME}"
    note "5" "DELETE_KIND_CLUSTER: ${DELETE_KIND_CLUSTER}"
    note "5" "INGRESS: ${INGRESS}"
    note "5" "KNATIVE_VERSION: ${KNATIVE_VERSION}"
    note "5" "KUBERNETES_VERSION: ${KUBERNETES_VERSION}"
    note "5" "LOGGING_VERBOSITY: ${LOGGING_VERBOSITY}"
    note "5" "REGISTRY_PORT: ${REGISTRY_PORT}"
    note "5" "SECURE_REGISTRY: ${SECURE_REGISTRY}"
    note "5" "SERVER_IP: ${SERVER_IP}"
    note "5" "SHOW_HELP: ${SHOW_HELP}"
    note "5" "USE_EXISTING_CLUSTER: ${USE_EXISTING_CLUSTER}"
}

show_usage() {
    log_message "0" ""
    log_message "0" "Usage: "
    log_message "0" "\t./kind.sh command [parameters,...]"
    log_message "0" ""
    log_message "0" "Available commands: "
    log_message "0" "\tinstall-cluster\t\t\t\t\tInstall the kind cluster"
    log_message "0" "\tremove-cluster\t\t\t\t\tRemove the kind cluster"
    log_message "0" "\tinstall-registry\t\t\t\tInstall the container registry"
    log_message "0" "\tremove-registry\t\t\t\t\tRemove the container registry"
    log_message "0" ""
    log_message "0" "Parameters: "
    log_message "0" "\t-h, --help\t\t\t\tThis help message"
    log_message "0" ""
    log_message "0" "\t--cluster-name <name>\t\t\tName of the cluster. Default: kind"
    log_message "0" "\t--delete-kind-cluster\t\t\tDeletes the Kind cluster prior to creating a new one. Default: No"
    log_message "0" "\t--ingress [nginx,kourier]\t\tIngress to be deployed. One of nginx,kourier. Default: nginx"
    log_message "0" "\t--ingress-ports httpPort:httpsPort\tIngress ports to be mapped.  e.g. 'HttpPort:HttpsPort '"
    log_message "0" "\t\t\t\t\t\tngninx default: 80:443."
    log_message "0" "\t\t\t\t\t\tkourier default: 31080:31443."
    log_message "0" "\t--knative-version <version>\t\tKNative version to be used. Default: 1.9.0"
    log_message "0" "\t--kubernetes-version <version>\t\tKubernetes version to be install. Default: latest"
    log_message "0" "\t--provider <provider>\t\t\tContainer Runtime [docker,podman]. Default: docker"
    log_message "0" "\t--port-map <port map list>\t\tList of ports to map on kind config. e.g. 'ContainerPort1:HostPort1,ContainerPort2:HostPort2,...'"
    log_message "0" "\t--registry-image-version <version>\tVersion of the registry container to be used. Default: 2.6.2"
    log_message "0" "\t--registry-name <name>\t\t\tName of the registry. Default: <cluster_name>-registry"
    log_message "0" "\t--registry-password <password>\t\tRegistry user password. Default: snowdrop"
    log_message "0" "\t--registry-port <port>\t\t\tPort of the registry. Default: 5000"
    log_message "0" "\t--registry-user <user>\t\t\tRegistry user. Default: admin"
    log_message "0" "\t--secure-registry\t\t\tSecure the docker registry. Default: No"
    log_message "0" "\t--server-ip <ip-address>\t\tIP address to be used. Default: 127.0.0.1"
    log_message "0" "\t--skip-ingress-installation \t\tSkip the installation of an ingress. Default: No"
    log_message "0" "\t--use-existing-cluster\t\t\tUses existing kind cluster if it already exists. Default: No"
    log_message "0" "\t-v, --verbosity <value>\t\t\tLogging verbosity (0..9). Default: 1"
    log_message "0" "\t\t\t\t\t\tA verbosity setting of 0 logs only critical events."
}

check_pre_requisites() {
    note_start_task "1" "Checking pre requisites..."

    note_start_task "2" "Checking if jq exists..."
    if ! command -v jq &> /dev/null; then
        error "Checking if jq exists... jq is not installed !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        error "Use a package manager to install"
        exit 1
    fi
    succeeded "2" "Checking if jq exists..."

    note_start_task "2" "Checking if kind exists..."
    if ! command -v kind &> /dev/null; then
        error "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        error "kind is not installed"
        error "Use a package manager (i.e 'brew install kind') or visit the official site https://kind.sigs.k8s.io"
        exit 1
    fi
    succeeded "2" "Checking if kind exists..."

    note "2" "CRI Provider: ${CRI_PROVIDER}"
    if [ "${CRI_PROVIDER}" == 'docker' ]; then
        note_start_task "2" "Checking if docker exists..."
        if ! command -v docker &> /dev/null; then
            error "docker is not installed"
            error "Use a package manager (i.e. 'brew install docker') or visit the official site https://docs.docker.com/engine/install/"
            exit 1
        fi

        case "$OSTYPE" in
            "linux-gnu"*) 
                note_start_task "2" "Checking if docker exists..."
                set +e
                systemctl is-active --quiet service docker
                case "$?" in
                    0) succeeded "2" "Checking if docker service is started..." ;;
                    *) 
                        error "docker service is not started"
                        error "Start the service with 'sudo systemctl start docker'"
                        exit 1
                    ;;
                esac
                set -e
            ;;
        esac;
    elif [ "${CRI_PROVIDER}" == 'podman' ]; then
        note_start_task "2" "Checking if podman exists..."
        if ! command -v podman &> /dev/null; then
            error "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            error "podman is not installed"
            error "Use a package manager (i.e. 'brew install podman') or visit the official site either https://podman.io/ or https://podman-desktop.io/"
            exit 1
        fi
        succeeded "2" "Checking if docker exists..."
    fi

    if [ ${COMMAND} == "install" ]; then
        note_start_task "2" "Checking if kubectl exists... "
        if ! command -v kubectl &> /dev/null; then
            error "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            error "Please install kubectl 1.15 or higher"
            exit 1
        fi
        succeeded "2" ""

        note_start_task "2" "Checking if helm exists... "
        if ! command -v helm &> /dev/null; then
            error "Checking if helm exists..."
            error "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            error "Helm could not be found. To get helm: https://helm.sh/docs/intro/install/"
            error "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            exit 1
        fi
        succeeded "2" "Checking if helm exists... "

        note_start_task "2" "Checking helm version... "
        log_message "5" "helm version"
        HELM_VERSION=$(helm version 2>&1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+') || true
        if [[ ${HELM_VERSION} < "v3.0.0" ]]; then
            error "Checking helm version... Please upgrade helm to v3.0.0 or higher"
            exit 1
        fi
        succeeded "2" "Checking helm version..."

        note_start_task "2" "Checking kubectl version... "
        log_message "5" "kubectl version -o json 2> /dev/null | jq -r '.clientVersion.gitVersion' | cut -d. -f2"
        KUBE_CLIENT_VERSION=$(kubectl version -o json 2> /dev/null | jq -r '.clientVersion.gitVersion' | cut -d. -f2) || true
        if [[ ${KUBE_CLIENT_VERSION} -lt 14 ]]; then
            error "Checking kubectl version... Please update kubectl to 1.15 or higher"
            exit 1
        fi
        succeeded "2" "Checking kubectl version..."
    fi
    succeeded "1" "Pre requisites check passed!"
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
DNS.3 = ${REGISTRY_NAME}
EOF
)
echo "$CFG"
}

# REMOVE

delete_kind_cluster() {
    note_start_task "1" "Removing kind cluster (${CLUSTER_NAME})..."
    set +e
    ${KIND_COMMAND} delete cluster -n ${CLUSTER_NAME} -q
    case "$?" in
        0) succeeded "1" "Removing kind cluster (${CLUSTER_NAME})..." ;;
        130) warn "Removing kind cluster (${CLUSTER_NAME})... no cluster to be removed" ;;
        *) 
            error "Removing kind cluster (${CLUSTER_NAME})... unsuccessful, try removing the cluster manually executing '${KIND_COMMAND} delete cluster -n ${CLUSTER_NAME}'" 
            exit 1
        ;;
    esac
    set -e
    SCRIPT_RESULT_MESSAGE+="\n"
    SCRIPT_RESULT_MESSAGE+="  * Kind cluster has been deleted \n"

    if [ "${CRI_COMMAND}" == 'podman' ]; then
        note_start_task "1" "Delete Podman Control Plane container..."
        podman_cp_container_name="${CLUSTER_NAME}-control-plane"
        podman_cp_container_id=$(${CRI_COMMAND} container ls --filter name=^${podman_cp_container_name}$ --all --quiet)
        if [ ! ${podman_cp_container_id} == "" ]; then
            ${CRI_COMMAND} container stop ${CLUSTER_NAME}-control-plane
            ${CRI_COMMAND} container rm ${CLUSTER_NAME}-control-plane
            succeeded "1" "Delete Podman Control Plane container..."
        else
            warn "Delete Podman Control Plane container... nothing to be done."
        fi
        SCRIPT_RESULT_MESSAGE+="\n"
        SCRIPT_RESULT_MESSAGE+="  * Podman Control Plane container has been deleted \n"
    fi
}

function delete_cri_resources(){
    note_start_task "1" "Removing ${CRI_COMMAND} network..."
    docker_network_id=$(${CRI_COMMAND} network ls --filter name=^kind$ --quiet)
    if [ ! ${docker_network_id} == "" ]; then
        NETWORK_RM_RES=eval ${NETWORK_RM_CMD} 1> /dev/null
        succeeded "1" "Removing ${CRI_COMMAND} network..."
    else 
        warn "Removing ${CRI_COMMAND} network... nothing to be done!"
    fi
}

# /REMOVE

# INSTALL
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
    kubectl patch -n kourier-system svc kourier --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/ports/0/nodePort\", \"value\": ${INGRESS_80_CONTAINER_PORT}}]"
    kubectl patch -n kourier-system svc kourier --type='json' -p="[{\"op\": \"replace\", \"path\": \"/spec/ports/1/nodePort\", \"value\": ${INGRESS_443_CONTAINER_PORT}}]"
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
    SCRIPT_RESULT_MESSAGE+="\n"
    SCRIPT_RESULT_MESSAGE+="  * Kourier Ingress has been deployed \n"
}

deploy_ingress_nginx() {
    note "1" "Deploying nginx Ingress..."
    #
    # Install the ingress nginx controller using helm
    # Set the Service type as: NodePort (needed for kind)
    #
    helm upgrade --install ingress-nginx ingress-nginx \
        --repo https://kubernetes.github.io/ingress-nginx \
        --namespace ingress --create-namespace \
        --set controller.service.type=NodePort \
        --set controller.hostPort.enabled=true \
        --set controller.watchIngressWithoutClass=true
    succeeded "1" "Deploying nginx Ingress..."
    note "2" "Ingress controller installed within the namespace: ingress"
    SCRIPT_RESULT_MESSAGE+="\n"
    SCRIPT_RESULT_MESSAGE+="  * nginx Ingress has been deployed \n"
}

function configure_registry_on_kind() {
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


}

get_kind_cluster() {
    eval "$1=$(${KIND_COMMAND} get clusters | { grep "${CLUSTER_NAME}" || test $? = 1; })"
}

deploy_kind_cluster() {

    if [ "${SECURE_REGISTRY}" == 'y' ]; then
        if [ ! -d ${temp_cert_dir} ];then
            mkdir -p _tmp
        fi
        # Generate the Self signed certificate using openssl
        pushd $temp_cert_dir
        mkdir -p $HOME/.registry/certs/${REGISTRY_NAME}

        note "1" "==== Generate the openssl config"
        create_openssl_cfg > req.cnf

        note "1" "==== Create the self signed certificate certificate and client key files"
        openssl req -x509 \
            -nodes \
            -days 365 \
            -newkey rsa:4096 \
            -keyout $HOME/.registry/certs/${REGISTRY_NAME}/client.key \
            -out $HOME/.registry/certs/${REGISTRY_NAME}/client.crt \
            -config req.cnf \
            -sha256
        kindCfgContainerdConfigPatches=$(cat <<EOF
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."${REGISTRY_NAME}:${REGISTRY_PORT}"]
    endpoint = ["https://${REGISTRY_NAME}:${REGISTRY_PORT}"]
  [plugins."io.containerd.grpc.v1.cri".registry.configs."${REGISTRY_NAME}:${REGISTRY_PORT}".tls]
    cert_file = "/etc/docker/certs.d/${REGISTRY_NAME}/client.crt"
    key_file  = "/etc/docker/certs.d/${REGISTRY_NAME}/client.key"
EOF
)

        kindCfgExtraMounts=$(cat <<EOF
extraMounts:
  - containerPath: /etc/docker/certs.d/${REGISTRY_NAME}
    hostPath: $HOME/.registry/certs/${REGISTRY_NAME}
EOF
)
    else
        kindCfgContainerdConfigPatches=$(cat <<EOF
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."${REGISTRY_NAME}:${REGISTRY_PORT}"]
    endpoint = ["http://${REGISTRY_NAME}:${REGISTRY_PORT}"]
EOF
)
    fi

    kindCmd="${KIND_COMMAND} -v ${LOGGING_VERBOSITY} create cluster  -n ${CLUSTER_NAME}"
    kindExtraPortMappings=$(cat <<EOF
  - containerPort: ${INGRESS_80_CONTAINER_PORT}
    hostPort: ${INGRESS_80_CONTAINER_PORT}
    protocol: TCP
    listenAddress: "0.0.0.0"
  - containerPort: ${INGRESS_443_CONTAINER_PORT}
    hostPort: ${INGRESS_443_CONTAINER_PORT}
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
    kind_get_clusters=$(${KIND_COMMAND} get clusters | { grep "${CLUSTER_NAME}" || test $? = 1; }) 
    if [ ! "${kind_get_clusters}" == "" ]; then
        note "1" "Cluster already exists..."
        if [ "$USE_EXISTING_CLUSTER" == "y" ]; then
            note "1" "...using existing cluster. Exporting cluster kubeconfig..."
            note "5" "CMD: kind export kubeconfig -n ${CLUSTER_NAME}"
            ${KIND_COMMAND} export kubeconfig -n ${CLUSTER_NAME}
            succeeded "1" "...done!"
        else
            error "Cluster already exists. Either use the existing cluster (--use-existing-cluster) or delete the cluster (--delete-kind-cluster)."
            exit 1
        fi
    else 
        note "5" "=== Get the tag version of the image to be installed for the kubernetes version: ${KUBERNETES_VERSION} ..."
        if [ ${KUBERNETES_VERSION} == "latest" ]; then
            kindCmd+=""
        else
            kind_image_sha=$(wget -q https://raw.githubusercontent.com/snowdrop/k8s-infra/main/kind/images.json -O - | \
            jq -r --arg VERSION "$KUBERNETES_VERSION" '.[] | select(.k8s == $VERSION).sha')
            kindCmd+=" --image ${kind_image_sha}"
        fi
        note "5" "Creating a Kind cluster using kindest/node: ${KUBERNETES_VERSION} and logging verbosity: ${LOGGING_VERBOSITY}"
        echo "${kindCfg}" | ${kindCmd} --config=-

        if [ "${CRI_PROVIDER}" == 'podman' ]; then
            sudo -E kind get kubeconfig > ${HOME}/.kube/config
        fi
        
    fi
    SCRIPT_RESULT_MESSAGE+="\n"
    SCRIPT_RESULT_MESSAGE+="  * ${CLUSTER_NAME} kind cluster has been deployed\n"
    SCRIPT_RESULT_MESSAGE+="\n"
    SCRIPT_RESULT_MESSAGE+="  * Cluster configuration has been copied to ${HOME}/.kube/config\n"
    SCRIPT_RESULT_MESSAGE+="\n"
    SCRIPT_RESULT_MESSAGE+="  * Execute 'kind get kubeconfig --name ${CLUSTER_NAME}' to obtain the cluster configuration\n"
}

function install() {
    deploy_kind_cluster

    configure_registry_on_kind
    
    if [ "${SKIP_INGRESS_INSTALLATION}" == 'n' ]; then
        if [ "${INGRESS}" == 'kourier' ]; then
            deploy_ingress_kourier
        elif [ "${INGRESS}" == 'nginx' ]; then
            deploy_ingress_nginx
        fi
    fi
}


function remove() {
    delete_kind_cluster
    delete_cri_resources
}

function validate_ingress() {
    if [ "${INGRESS}" == 'kourier' ]; then
        INGRESS_80_CONTAINER_PORT=31080
        INGRESS_443_CONTAINER_PORT=31443
    elif [ "${INGRESS}" == 'nginx' ]; then
        INGRESS_80_CONTAINER_PORT=80
        INGRESS_443_CONTAINER_PORT=443
    else
        error "Invalid ingress ${INGRESS}, choose one of nginx or kourier."
        show_usage
        exit 1  
    fi

    note "5" "Ingress ports: ${INGRESS_PORTS}"
    if [ -v INGRESS_PORTS ]; then
        IFS=':' read -ra PORT_MAP <<< "${INGRESS_PORTS}"
        INGRESS_80_CONTAINER_PORT=${PORT_MAP[0]}
        INGRESS_443_CONTAINER_PORT=${PORT_MAP[1]}
    else 
        if [ "${INGRESS}" == 'kourier' ]; then
            INGRESS_80_CONTAINER_PORT=31080
            INGRESS_443_CONTAINER_PORT=31443
        elif [ "${INGRESS}" == 'nginx' ]; then
            INGRESS_80_CONTAINER_PORT=80
            INGRESS_443_CONTAINER_PORT=443
        fi
    fi
    note "5" "Ingress ports: ${INGRESS_80_CONTAINER_PORT}:${INGRESS_443_CONTAINER_PORT}"
}

function validate_cri() {
    note "2" "CRI Provider: ${CRI_PROVIDER}"
    if [ "${CRI_PROVIDER}" == 'docker' ]; then
        CRI_COMMAND="docker"
        KIND_COMMAND=kind
        unset KIND_EXPERIMENTAL_PROVIDER
        HOST_80_PORT=80
        HOST_443_PORT=443
    elif [ "${CRI_PROVIDER}" == 'podman' ]; then
        CRI_COMMAND="sudo podman"
        # WARN: NO SUPPORT FOR ROOTLESS PODMAN CONTAINERS YET
        KIND_COMMAND="sudo --preserve-env kind"
        export KIND_EXPERIMENTAL_PROVIDER=podman
        HOST_80_PORT=30080
        HOST_443_PORT=30443
    else
        error "Invalid CRI provider ${CRI_PROVIDER}."
        show_usage
        exit 1  
    fi
}

function check_os() {
    case "$OSTYPE" in
        "linux-gnu"*) 
            DOCKER_RESTART_COMMAND="sudo systemctl restart docker" 
            NETWORK_RM_CMD="${CRI_COMMAND} network rm -f kind"
        ;;
        "darwin"*) 
            # DOCKER_RESTART_COMMAND='echo -e "${YELLOW}\xE2\x9A\xA0 : Script paused to Restart the Docker service manually. ${NC}" ; read -n1 -s -r -p $"Press any key to continue..." key' 
            DOCKER_RESTART_COMMAND='echo ""' 
            NETWORK_RM_CMD="${CRI_COMMAND} network rm kind"
        ;;
        *) error "Unknown OS"; exit 1 ;;
    esac;
    note "5" "${DOCKER_RESTART_COMMAND}"
    # if [ "$OSTYPE" == "linux-gnu"* ]; then
    #     # DOCKER_RESTART_COMMAND="sudo systemctl restart docker"
    #     DOCKER_RESTART_COMMAND="read -n1 -s -r -p $'${YELLOW}\xE2\x9A\xA0: script paused to Restart the Docker service manually, press any key to continue...!${NC}' key"
    # elif [ "$OSTYPE" == "darwin"* ]; then
    #     # Mac OSX
    #     DOCKER_RESTART_COMMAND="read -n1 -s -r -p $'${YELLOW}\xE2\x9A\xA0: script paused to Restart the Docker service manually, press any key to continue...!${NC}' key"
    # # elif [ "$OSTYPE" == "cygwin" ]; then
    # #         # POSIX compatibility layer and Linux environment emulation for Windows
    # # elif [ "$OSTYPE" == "msys" ]; then
    # #         # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
    # # elif [ "$OSTYPE" == "win32" ]; then
    # #         # I'm not sure this can happen.
    # elif [ "$OSTYPE" == "freebsd"* ]; then
    #         # ...
    # else
    #         # Unknown.
    # fi
}
##### /Functions

###### Command Line Parser
CLUSTER_NAME="kind"
CRI_PROVIDER=docker
CRI_COMMAND=docker
DELETE_KIND_CLUSTER="n"
INGRESS="nginx"
KIND_COMMAND=kind
KNATIVE_VERSION="1.9.0"
KUBERNETES_VERSION="latest"
LOGGING_VERBOSITY="1"
REGISTRY_PORT="5000"
SCRIPT_RESULT_MESSAGE=""
SCRIPT_REQUIRED_STEPS=""
SKIP_INGRESS_INSTALLATION="n"
SECURE_REGISTRY="n"
SERVER_IP="127.0.0.1"
SHOW_HELP="n"
USE_EXISTING_CLUSTER="n"
PORT_MAP=""

set +e
while [ $# -gt 0 ]; do
    note "9" "$1"
    if [[ $1 == "--"* ]]; then
        param="${1/--/}";
        case $1 in
        --help) SHOW_HELP="y"; break 2 ;;
        --cluster-name) CLUSTER_NAME="$2"; shift ;;
        --delete-kind-cluster) DELETE_KIND_CLUSTER="y" ;;
        --ingress) INGRESS="$2"; shift ;;
        --ingress-ports) INGRESS_PORTS="$2"; shift ;;
        --knative-version) KNATIVE_VERSION="$2"; shift ;;
        --kubernetes-version) KUBERNETES_VERSION="$2"; shift ;;
        --provider) CRI_PROVIDER="$2"; shift ;;
        --port-map) PORT_MAP="$2"; shift ;;
        --registry-name) REGISTRY_NAME="$2"; shift ;;
        --registry-port) REGISTRY_PORT="$2"; shift ;;
        --secure-registry) SECURE_REGISTRY="y" ;;
        --skip-ingress-installation) SKIP_INGRESS_INSTALLATION="y" ;;
        --server-ip) SERVER_IP="$2"; shift ;;
        --use-existing-cluster) USE_EXISTING_CLUSTER="y"; ;;
        --verbosity) LOGGING_VERBOSITY="$2"; shift ;;
        *) INVALID_SWITCH="${INVALID_SWITCH} $1" ; break 2 ;;
        esac;
    shift
    elif [[ $1 == "-"* ]]; then
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
            *) INVALID_COMMAND="${INVALID_COMMAND} $1" ; break 2 ;;
        esac;
        shift
  fi
done
set -e

if [ "$SHOW_HELP" == "y" ]; then
    show_usage
    exit 0
elif ! [ -z ${INVALID_COMMAND+x} ]; then
    error "Invalid command ${INVALID_COMMAND}"
    show_usage
    exit 1
elif ! [ -z ${INVALID_SWITCH+x} ]; then
    error "Invalid switch(es) ${INVALID_SWITCH}"
    show_usage
    exit 1
elif [ -z ${COMMAND+x} ]; then
    error "A command must be provided!!!"
    show_usage
    exit 1
elif [ ${COMMAND} == 'install' ] && [ -z ${INGRESS+x} ]; then
    error "The Ingress controller to be installed is not defined (nginx, kourier)."
    show_usage  
    exit 1
fi

case ${COMMAND} in
    install) validate_ingress ;;
esac;


if [ "$REGISTRY_NAME" == "" ]; then
    REGISTRY_NAME="${CLUSTER_NAME}-registry"
fi

note "5" "REGISTRY_NAME: ${REGISTRY_NAME}"

###### /Command Line Parser

###### Execution

check_os

print_logo

check_pre_requisites

validate_cri

kindCfgExtraMounts=""
temp_cert_dir="_tmp"

case ${COMMAND} in
    install) 
        validate_ingress
        note "5" "PORT_MAP: ${PORT_MAP}"
        install
        log_message "0" ""
        log_message "0" ""
        succeeded "0" " ################### Installation completed! ###################"
        SCRIPT_REQUIRED_STEPS+="\n"
        SCRIPT_REQUIRED_STEPS+="  * Add to your /etc/hosts file: 127.0.0.1 localhost ${REGISTRY_NAME}\n"
        SCRIPT_REQUIRED_STEPS+="\n"
        SCRIPT_REQUIRED_STEPS+="  * To avoid to get a permission denied on the mounted volume /certs, disable SELINUX=disabled within the file /etc/selinux/config and reboot !\n"
        SCRIPT_RESULT_MESSAGE+="\n"
        SCRIPT_RESULT_MESSAGE+="  * You can test the container registry using the instructions from: https://github.com/snowdrop/k8s-infra/blob/main/kind/README.adoc#container-registry\n"
        log_message "0" " ### Installation resume: "
        log_message "0" "${SCRIPT_RESULT_MESSAGE}"
        log_message "0" " ### Required steps: "
        log_message "0" "${SCRIPT_REQUIRED_STEPS}"
    ;;
    remove) 
        remove 
        SCRIPT_REQUIRED_STEPS+="\n"
        SCRIPT_REQUIRED_STEPS+="  * Check your /etc/hosts file and remove references to the ${REGISTRY_NAME} container registry container.\n"
        log_message "0" ""
        log_message "0" ""
        succeeded "0" " ################### Removal completed! ###################"
        log_message "0" " ### Removal resume: "
        log_message "0" "${SCRIPT_RESULT_MESSAGE}"
        log_message "0" "  ### Required steps: "
        log_message "0" "${SCRIPT_REQUIRED_STEPS}"
    ;;
    
esac;
