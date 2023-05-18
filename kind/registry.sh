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
    log_message "1" "Script to create/delete a container registry (secure or insecure)  "
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
    log_message "0" "\t./registry.sh command [parameters,...]"
    log_message "0" ""
    log_message "0" "Available commands: "
    log_message "0" "\tinstall\t\t\t\t\tInstall the kind cluster"
    log_message "0" "\tremove\t\t\t\t\tRemove the kind cluster"
    log_message "0" ""
    log_message "0" "Parameters: "
    log_message "0" "\t-h, --help\t\t\t\tThis help message"
    log_message "0" ""
#    log_message "0" "\t--cluster-name <name>\t\t\tName of the cluster. Default: kind"
#    log_message "0" "\t--delete-kind-cluster\t\t\tDeletes the Kind cluster prior to creating a new one. Default: No"
#    log_message "0" "\t--ingress [nginx,kourier]\t\tIngress to be deployed. One of nginx,kourier. Default: nginx"
#    log_message "0" "\t--ingress-ports httpPort:httpsPort\tIngress ports to be mapped.  e.g. 'HttpPort:HttpsPort '"
#    log_message "0" "\t\t\t\t\t\tngninx default: 80:443."
#    log_message "0" "\t\t\t\t\t\tkourier default: 31080:31443."
#    log_message "0" "\t--knative-version <version>\t\tKNative version to be used. Default: 1.9.0"
#    log_message "0" "\t--kubernetes-version <version>\t\tKubernetes version to be install. Default: latest"
    log_message "0" "\t--provider <provider>\t\t\tContainer Runtime [docker,podman]. Default: docker"
#    log_message "0" "\t--port-map <port map list>\t\tList of ports to map on kind config. e.g. 'ContainerPort1:HostPort1,ContainerPort2:HostPort2,...'"
    log_message "0" "\t--registry-image-version <version>\tVersion of the registry container to be used. Default: 2.6.2"
    log_message "0" "\t--registry-name <name>\t\t\tName of the registry. Default: <cluster_name>-registry"
    log_message "0" "\t--registry-password <password>\t\tRegistry user password. Default: snowdrop"
    log_message "0" "\t--registry-port <port>\t\t\tPort of the registry. Default: 5000"
    log_message "0" "\t--registry-user <user>\t\t\tRegistry user. Default: admin"
    log_message "0" "\t--secure-registry\t\t\tSecure the docker registry. Default: No"
#    log_message "0" "\t--server-ip <ip-address>\t\tIP address to be used. Default: 127.0.0.1"
#    log_message "0" "\t--skip-ingress-installation \t\tSkip the installation of an ingress. Default: No"
#    log_message "0" "\t--use-existing-cluster\t\t\tUses existing kind cluster if it already exists. Default: No"
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
        note_start_task "2" "Checking if ${REGISTRY_PORT} is available... "
        set +e
        nc -z localhost ${REGISTRY_PORT}
        case "$?" in
            0) 
                error "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                error "Container registry port ${REGISTRY_PORT} is in use"
                exit 1
            ;;
            *) 
                succeeded "2" "Checking if ${REGISTRY_PORT} is available... "
            ;;
        esac
        set -e
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
function remove_container_registry() {
    note_start_task "1" "Removing kind registry container..."
    docker_container_id=$(${CRI_COMMAND} container ls --filter name=^${REGISTRY_NAME}$ --all --quiet)
    if [ ! ${docker_container_id} == "" ]; then
        ${CRI_COMMAND} container rm ${REGISTRY_NAME} -f 1> /dev/null
        succeeded "1" "Removing kind registry container..."
    else 
        warn "Removing kind registry container... no container to be removed."
    fi
    SCRIPT_RESULT_MESSAGE+="\n"
    SCRIPT_RESULT_MESSAGE+="  * kind registry container has been deleted \n"
}
# /REMOVE

# INSTALL

function install_container_registry() {
    if [ "${SECURE_REGISTRY}" == 'y' ]; then
        note "1" "Securing registry..."
        note "2" "==== Create the htpasswd file where user: ${REGISTRY_USER} and password: ${REGISTRY_PASSWORD}"
        mkdir -p $HOME/.registry/auth
        ${CRI_COMMAND} run --entrypoint htpasswd registry:2.7.0 -Bbn ${REGISTRY_USER} ${REGISTRY_PASSWORD} > $HOME/.registry/auth/htpasswd

        SCRIPT_RESULT_MESSAGE+="\n"
        SCRIPT_RESULT_MESSAGE+="  * The htpasswd file is located at $HOME/.registry/auth/htpasswd\n"

        note_start_task "2" "Creating a docker registry..."
        ${CRI_COMMAND} run -d \
            -p ${REGISTRY_PORT}:5000 \
            --restart=always \
            --name ${REGISTRY_NAME} \
            -v $HOME/.registry/auth:/auth \
            -v $HOME/.registry/certs/${REGISTRY_NAME}:/certs \
            -e REGISTRY_AUTH=htpasswd \
            -e REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm" \
            -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
            -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/client.crt \
            -e REGISTRY_HTTP_TLS_KEY=/certs/client.key \
            registry:${REGISTRY_IMAGE_VERSION}
        succeeded "2" "Creating a docker registry.  "

        # connect the container registry to the cluster network
        # (the network may already be connected)
        note_start_task "2" "Connect the container registry to the cluster network..."
        ${CRI_COMMAND} network connect kind "${REGISTRY_NAME}" || true
        succeeded "2" "Connect the container registry to the cluster network.  "

        # Upload the self-signed certificate to the kind container
        name="${name:-"kind"}"
        containers="$(${KIND_COMMAND} get nodes --name="$name" 2>/dev/null)"
        if [[ "$containers" == "" ]]; then
            log_message "1" "No kind nodes found for cluster \"$name\"" >&2
            exit 1
        fi

        CERT_DIR=/usr/local/share/ca-certificates
        certfile="$HOME/.registry/certs/${REGISTRY_NAME}/client.crt"

        while IFS= read -r container; do
            note_start_task "1" "Copying ${certfile} to ${container}:${CERT_DIR}"
            ${CRI_COMMAND} cp "$certfile" "${container}:${CERT_DIR}"
            succeeded "1" "Copying ${certfile} to ${container}:${CERT_DIR}"

            note_start_task "1" "Updating CA certificates in ${container}..."
            ${CRI_COMMAND} exec "$container" update-ca-certificates
            succeeded "1" "Updating CA certificates in ${container}..."

            note_start_task "1" "Restarting containerd..."
            ${CRI_COMMAND} exec "$container" systemctl restart containerd
            succeeded "1" "Restarting containerd..."
        done <<< "$containers"

        log_message "1" "Copy the client.crt to the docker cert.d folder"
        mkdir -p $HOME/.docker/certs.d/${REGISTRY_NAME}:${REGISTRY_PORT}
        cp $certfile $HOME/.docker/certs.d/${REGISTRY_NAME}:${REGISTRY_PORT}/client.crt
        cp $HOME/.registry/certs/${REGISTRY_NAME}/client.key $HOME/.docker/certs.d/${REGISTRY_NAME}:${REGISTRY_PORT}/client.key
        eval ${DOCKER_RESTART_COMMAND}

        SCRIPT_RESULT_MESSAGE+="\n"
        SCRIPT_RESULT_MESSAGE+="  * Secured container registry has been deployed \n"
        SCRIPT_RESULT_MESSAGE+="\n"
        SCRIPT_RESULT_MESSAGE+="    * Log on to the container registry using the address and user/password\n"
        SCRIPT_RESULT_MESSAGE+="      ${CRI_COMMAND} login ${REGISTRY_NAME}:${REGISTRY_PORT} -u ${REGISTRY_USER} -p ${REGISTRY_PASSWORD}\n"

        popd
    else
        note "5" "1-------------> ${REGISTRY_NAME}"
        note_start_task "1" "Starting local Container registry ${REGISTRY_NAME}..."
        running="$(${CRI_COMMAND} inspect -f '{{.State.Running}}' "${REGISTRY_NAME}" 2>/dev/null || true)"
        if [ "${running}" != 'true' ]; then
            ${CRI_COMMAND} run -d --restart=always -p "${REGISTRY_PORT}:5000" \
              --name "${REGISTRY_NAME}" registry:2
            succeeded "1" "Starting a local Container registry ${REGISTRY_NAME}..."
        else   
            warn "Starting a local Container registry ${REGISTRY_NAME}... already running."
        fi

        # Connect the local Container registry with the kind network
        note_start_task "1" "Connecting the local Container registry with the kind network ${REGISTRY_NAME}..."
        if [ "$(${CRI_COMMAND} inspect -f='{{json .NetworkSettings.Networks.kind}}' ${REGISTRY_NAME})" = 'null' ]; then
            ${CRI_COMMAND} network connect "kind" "${REGISTRY_NAME}" > /dev/null 2>&1 &
            succeeded "1" "Connecting the local Container registry with the kind network ${REGISTRY_NAME}..."
        else   
            warn "Connecting the local Container registry with the kind network ${REGISTRY_NAME}... already connected."
        fi

        SCRIPT_RESULT_MESSAGE+="\n"
        SCRIPT_RESULT_MESSAGE+="  * Insecure container registry has been deployed \n"
        case "$CRI_PROVIDER" in
            "docker") 
                case "$OSTYPE" in
                    "linux-gnu"*) 
                        SCRIPT_REQUIRED_STEPS+="\n"
                        SCRIPT_REQUIRED_STEPS+="    * Edit the daemon.json file, whose default location might be one of ~/.docker/config.json or /etc/docker/daemon.json on Linux, and restart the docker service  \n"
                    ;;
                    "darwin"*) 
                        SCRIPT_REQUIRED_STEPS+="\n"
                        SCRIPT_REQUIRED_STEPS+="    * Edit the daemon.json file. If you use Docker Desktop for Mac or Docker Desktop for Windows, click the Docker icon, choose Settings and then choose Docker Engine.\n"
                    ;;
                esac
                SCRIPT_REQUIRED_STEPS+="      {\"insecure-registries\" : [\"${REGISTRY_NAME}:${REGISTRY_PORT}\"]}\n"
            ;;
            "podman") 
                SCRIPT_REQUIRED_STEPS+="    * Set the kind registry as an insecure registry by adding the following configuration to the /etc/containers/registries.conf.d/kind-registry.conf file\n"
                SCRIPT_REQUIRED_STEPS+='[[registry]]\n'
                SCRIPT_REQUIRED_STEPS+='location = "localhost:${REGISTRY_PORT}"\n'
                SCRIPT_REQUIRED_STEPS+='insecure = true\n'
            ;;
        esac
        SCRIPT_RESULT_MESSAGE+="\n"
        SCRIPT_RESULT_MESSAGE+="    * Log on to the container registry using the address\n"
        SCRIPT_RESULT_MESSAGE+="      ${CRI_COMMAND} login ${REGISTRY_NAME}:${REGISTRY_PORT}\n"
    fi
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
REGISTRY_IMAGE_VERSION="2.6.2"
REGISTRY_PASSWORD="snowdrop"
REGISTRY_PORT="5000"
REGISTRY_USER="admin"
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
        #--cluster-name) CLUSTER_NAME="$2"; shift ;;
        #--delete-kind-cluster) DELETE_KIND_CLUSTER="y" ;;
        #--ingress) INGRESS="$2"; shift ;;
        #--ingress-ports) INGRESS_PORTS="$2"; shift ;;
        #--knative-version) KNATIVE_VERSION="$2"; shift ;;
        #--kubernetes-version) KUBERNETES_VERSION="$2"; shift ;;
        --provider) CRI_PROVIDER="$2"; shift ;;
        #--port-map) PORT_MAP="$2"; shift ;;
        --registry-name) REGISTRY_NAME="$2"; shift ;;
        --registry-image-version) REGISTRY_IMAGE_VERSION="$2"; shift ;;
        --registry-password) REGISTRY_PASSWORD="$2"; shift ;;
        --registry-port) REGISTRY_PORT="$2"; shift ;;
        --registry-user) REGISTRY_USER="$2"; shift ;;
        --secure-registry) SECURE_REGISTRY="y" ;;
        #--skip-ingress-installation) SKIP_INGRESS_INSTALLATION="y" ;;
        #--server-ip) SERVER_IP="$2"; shift ;;
        #--use-existing-cluster) USE_EXISTING_CLUSTER="y"; ;;
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
fi

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
        install_container_registry
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
        remove_container_registry
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
