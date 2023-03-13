#!/bin/sh

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

log_message() {
    if [ "${LOGGING_VERBOSITY}" -ge "$1" ]; then
        echo "$2"
    fi
}

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
  log_message "1" " Kind installation script"
  log_message "1" ""
  log_message "1" "- Deploying a local secured (using htpasswd) docker registry"
  log_message "1" "- Generating a selfsigned certificate (using openssl) to expose the registry as a HTTP/HTTPS endpoint"
  log_message "1" "- Setting a docker network between the containers: kind and registry and alias \"registry.local\""
  log_message "1" "- Allowing to access the repository using as address \"registry.local:${REGISTRY_PORT}\" within a pod, from laptop or when a pod is created"
  log_message "1" "- Exposing 2 additional NodePort: 30000 and 31000"
  log_message "1" "- Deploying an ingress controller"
  log_message "1" "- Copying the generated certificate here: $HOME/local-registry.crt"
  log_message "1" ""
  log_message "1" ""
  log_message "5" "Variables used:"
  log_message "5" ""
  log_message "5" "CLUSTER_NAME: ${CLUSTER_NAME}"
  log_message "5" "DELETE_KIND_CLUSTER: ${DELETE_KIND_CLUSTER}"
  log_message "5" "INGRESS: ${INGRESS}"
  log_message "5" "KNATIVE_VERSION: ${KNATIVE_VERSION}"
  log_message "5" "KUBERNETES_VERSION: ${KUBERNETES_VERSION}"
  log_message "5" "LOGGING_VERBOSITY: ${LOGGING_VERBOSITY}"
  log_message "5" "REGISTRY_IMAGE_VERSION: ${REGISTRY_IMAGE_VERSION}"
  log_message "5" "REGISTRY_PASSWORD: ${REGISTRY_PASSWORD}"
  log_message "5" "REGISTRY_PORT: ${REGISTRY_PORT}"
  log_message "5" "REGISTRY_USER: ${REGISTRY_USER}"
  log_message "5" "SECURE_REGISTRY: ${SECURE_REGISTRY}"
  log_message "5" "SERVER_IP: ${SERVER_IP}"
  log_message "5" "SHOW_HELP: ${SHOW_HELP}"
  log_message "5" "USE_EXISTING_CLUSTER: ${USE_EXISTING_CLUSTER}"
}

show_usage() {
    log_message "0" ""
    log_message "0" "Usage: "
    log_message "0" "  ./deploy-kind.sh [parameters,...]"
    log_message "0" ""
    log_message "0" "Required parameters: "
    log_message "0" "  --ingress [nginx,kourier]           Ingress to be deployed. One of nginx,kourier."
    log_message "0" ""
    log_message "0" "Optional parameters: "
    log_message "0" "  -h, --help:                         This help message"
    log_message "0" ""
    log_message "0" "  --cluster-name <name>               Name of the cluster. Default: kind"
    log_message "0" "  --delete-kind-cluster               Deletes the Kind cluster prior to creating a new one. Default: No"
    log_message "0" "  --knative-version <version>         KNative version to be used. Default: 1.9.0"
    log_message "0" "  --kubernetes-version <version>      Kubernetes version to be install"
    log_message "0" "                                      Default: latest"
    log_message "0" "  --registry-image-version <version>  Version of the registry container to be used. Default: 2.6.2"
    log_message "0" "  --registry-password <password>      Registry user password. Default: snowdrop"
    log_message "0" "  --registry-port <port>              Port to publish the registry. Default: 5000"
    log_message "0" "  --registry-user <user>              Registry user. Default: admin"
    log_message "0" "  --secure-registry                   Secure the docker registry. Default: No"
    log_message "0" "  --server-ip <ip-address>            IP address to be used. Default: 127.0.0.1"
    log_message "0" "  --use-existing-cluster              Uses existing kind cluster if it already exists. Default: No"
    log_message "0" "  -v, --verbosity <value>             Logging verbosity (0..9). Default: 1"
    log_message "0" "                                      A verbosity setting of 0 logs only critical events."
    log_message "0" "                                      Default: 0"
}

check_pre_requisites() {
  log_message "1" "Checking pre requisites..."

  log_message "1" "Checking if kind exists..."
  if ! command -v kind &> /dev/null; then
    log_message "0" "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    log_message "0" "kind is not installed"
    log_message "0" "Use a package manager (i.e 'brew install kind') or visit the official site https://kind.sigs.k8s.io"
    exit 1
  fi
  log_message "1" "...passed!"

  log_message "1" "Checking if kubectl exists..."
  if ! command -v kubectl &> /dev/null; then
    log_message "0" "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    log_message "0" "Please install kubectl 1.15 or higher"
    exit 1
  fi
  log_message "1" "...passed!"

  log_message "1" "Checking if helm exists..."
  if ! command -v helm &> /dev/null; then
    log_message "0" "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    log_message "0" "Helm could not be found. To get helm: https://helm.sh/docs/intro/install/"
    log_message "0" "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
  fi
  log_message "1" "...passed!"

  log_message "1" "Checking helm version..."
  log_message "5" "helm version"
  HELM_VERSION=$(helm version 2>&1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+') || true
  if [[ ${HELM_VERSION} < "v3.0.0" ]]; then
    log_message "0" "Please upgrade helm to v3.0.0 or higher"
    exit 1
  fi
  log_message "1" "...passed!"

  log_message "1" "Checking kubectl version..."
  log_message "5" "kubectl version -o json 2> /dev/null | jq -r '.clientVersion.gitVersion' | cut -d. -f2"
  KUBE_CLIENT_VERSION=$(kubectl version -o json 2> /dev/null | jq -r '.clientVersion.gitVersion' | cut -d. -f2) || true
  if [[ ${KUBE_CLIENT_VERSION} -lt 14 ]]; then
    log_message "0" "Please update kubectl to 1.15 or higher"
    exit 1
  fi
  log_message "1" "...passed."
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
  log_message "5" "kindCfg: Deleting kind cluster ${CLUSTER_NAME}..."
  kind delete cluster -n ${CLUSTER_NAME}
  docker container rm kind-registry -f
}

deploy_ingress_kourier() {
  log_message "1" "Deploying KNative Ingress"
  echo "Install the required custom resources of knative"
  kubectl apply -f https://github.com/knative/serving/releases/download/knative-v${KNATIVE_VERSION}/serving-crds.yaml

  log_message "1" "Install the core components of Knative Serving"
  kubectl apply -f https://github.com/knative/serving/releases/download/knative-v${KNATIVE_VERSION}/serving-core.yaml
  kubectl -n knative-serving rollout status deployment activator
  kubectl -n knative-serving rollout status deployment autoscaler
  kubectl -n knative-serving rollout status deployment controller
  kubectl -n knative-serving rollout status deployment domain-mapping
  kubectl -n knative-serving rollout status deployment domainmapping-webhook
  kubectl -n knative-serving rollout status deployment webhook

  log_message "1" "Install the Knative Kourier controller"
  kubectl apply -f https://github.com/knative/net-kourier/releases/download/knative-v${KNATIVE_VERSION}/kourier.yaml
  kubectl -n knative-serving rollout status deployment net-kourier-controller
  kubectl -n kourier-system rollout status deployment 3scale-kourier-gateway

  log_message "1" "Configure Knative Serving to use Kourier by default"
  kubectl patch configmap/config-network \
    -n knative-serving \
    --type merge \
    -p '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'

  log_message "1" "Configure the Knative domain to: $SERVER_IP.nip.io"
  KNATIVE_DOMAIN="${SERVER_IP}.nip.io"
  kubectl patch configmap/config-domain \
    -n knative-serving \
    -p "{\"data\": {\"$KNATIVE_DOMAIN\": \"\"}}"

  log_message "1" "Patching the kourier service to use the nodePort 31080 and type nodePort"
  kubectl patch -n kourier-system svc kourier --type='json' -p='[{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 31080}]'
  kubectl patch -n kourier-system svc kourier --type='json' -p='[{"op": "replace", "path": "/spec/ports/1/nodePort", "value": 31443}]'
  kubectl patch -n kourier-system svc kourier --type='json' -p='[{"op": "replace", "path": "/spec/type", "value": "NodePort"}]'

  log_message "0" "####### TO TEST ########"
  log_message "0" "Execute the following commands: "
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

  log_message "0" "$knCmd"
  log_message "0" "Then wait till the pods are created before to curl it: http://hello.default.${SERVER_IP}.nip.io"
  log_message "0" "Sometimes the revision hangs as deployment has been modified, then do"
  log_message "0" "kubectl scale --replicas=0 deployment/hello-00001-deployment"
  log_message "0" "kubectl scale --replicas=1 deployment/hello-00001-deployment"
}

deploy_ingress_nginx() {
  log_message "1" "Deploying nginx Ingress"
  #
  # Install the ingress nginx controller using helm
  # Set the Service type as: NodePort (needed for kind)
  #
  log_message "1" "Installing the ingress controller using Helm within the namespace: ingress"
  helm upgrade --install ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --namespace ingress --create-namespace \
    --set controller.service.type=NodePort \
    --set controller.hostPort.enabled=true \
    --set controller.watchIngressWithoutClass=true
}

##### /Functions

###### Command Line Parser
UNMANAGED_PARAMS=""
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

while [ $# -gt 0 ]; do
  log_message "0" "$1"
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}";
    case $1 in
      --help) SHOW_HELP="y"; break 2 ;;
      --cluster-name) CLUSTER_NAME="$2"; shift ;;
      --delete-kind-cluster) DELETE_KIND_CLUSTER="y" ;;
      --ingress) INGRESS="$2"; shift ;;
      --knative-version) KNATIVE_VERSION="$2"; shift ;;
      --kubernetes-version) KUBERNETES_VERSION="$2"; shift ;;
      --registry-image-version) REGISTRY_IMAGE_VERSION="$2"; shift ;;
      --registry-password) REGISTRY_PASSWORD="$2"; shift ;;
      --registry-port) REGISTRY_PORT="$2"; shift ;;
      --registry-user) REGISTRY_USER="$2"; shift ;;
      --secure-registry) SECURE_REGISTRY="y" ;;
      --server-ip) SERVER_IP="$2"; shift ;;
      --use-existing-cluster) USE_EXISTING_CLUSTER="y"; ;;
      --verbosity) LOGGING_VERBOSITY="$2"; shift ;;
      *) INVALID_SWITCH="$1" ; break 2 ;;
    esac;
    shift
  elif [[ $1 == *"-"* ]]; then
    case $1 in
      -h) SHOW_HELP="y"; break 2 ;;
      -v) LOGGING_VERBOSITY="$2"; shift ;;
      *) INVALID_SWITCH="$1" ; break 2 ;;
    esac;
    shift
  fi
done

if [[ "$SHOW_HELP" == "y" ]]; then
  show_usage
  exit 0
elif [[ -v INVALID_SWITCH ]]; then
  log_message "0" "ERROR: Invalid switch ${INVALID_SWITCH}"
  show_usage
  exit 1
elif [ ! -v INGRESS ]; then
    log_message "0" "ERROR: Ingress is not defined."
  show_usage
  exit 1
fi

###### /Command Line Parser

###### Execution

print_logo

check_pre_requisites

kindCfgExtraMounts=""
registry_name="${CLUSTER_NAME}-registry"
registry_server='localhost'
temp_cert_dir="_tmp"

if [ "${INGRESS}" == 'kourier' ]; then
  CONTAINER_80_PORT=31080
  CONTAINER_443_PORT=31443
elif [ "${INGRESS}" == 'nginx' ]; then
  CONTAINER_80_PORT=80
  CONTAINER_443_PORT=443
else
    log_message "0" "ERROR: Invalid ingress ${INGRESS}."
    show_usage
    exit 1  
fi

if [ "${SECURE_REGISTRY}" == 'y' ]; then
  if [ ! -d ${temp_cert_dir} ];then
    mkdir -p _tmp
  fi
  # Generate the Self signed certificate using openssl
  pushd $temp_cert_dir
  mkdir -p certs/${registry_server}

  log_message "1" "==== Generate the openssl config"
  create_openssl_cfg > req.cnf

  log_message "1" "==== Create the self signed certificate certificate and client key files"
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
  - containerPort: ${CONTAINER_80_PORT}
    hostPort: 80
    protocol: TCP
    listenAddress: "0.0.0.0"
  - containerPort: ${CONTAINER_443_PORT}
    hostPort: 443
    protocol: TCP
    listenAddress: "0.0.0.0"
  - containerPort: 30000
    hostPort: 30000
    protocol: tcp
  - containerPort: 31000
    hostPort: 31000
    protocol: tcp
EOF
)

log_message "5" "kindCfg: ${kindCfg}"

if [ "$DELETE_KIND_CLUSTER" == "y" ]; then
  log_message "0" "Deleting Kind cluster..."
  delete_kind_cluster
fi

log_message "1" "Checking if kind cluster already exists..."
kind_get_clusters=$(kind get clusters | grep "${CLUSTER_NAME}")

if [ $? -eq 0 ]; then
  log_message "1" "Cluster already exists..."
  if [ "$USE_EXISTING_CLUSTER" == "y" ]; then
    log_message "1" "...using existing cluster..."
    log_message "1" "Exporting cluster kubeconfig..."
    log_message "5" "CMD: kind export kubeconfig -n ${CLUSTER_NAME}"
    kind export kubeconfig -n ${CLUSTER_NAME}
    log_message "1" "...done!"
  else
    log_message "0" "...ERROR: cluster exists and not using current cluster!"
    exit 1
  fi
else 
  log_message "1" "=== Get the tag version of the image to be installed for the kubernetes version: ${KUBERNETES_VERSION} ..."
  if [ ${KUBERNETES_VERSION} == "latest" ]; then
    kindCmd+=""
  else
    kind_image_sha=$(wget -q https://raw.githubusercontent.com/snowdrop/k8s-infra/main/kind/images.json -O - | \
    jq -r --arg VERSION "$KUBERNETES_VERSION" '.[] | select(.k8s == $VERSION).sha')
    kindCmd+=" --image ${kind_image_sha}"
  fi

  log_message "1" "Creating a Kind cluster using kindest/node: ${KUBERNETES_VERSION} and logging verbosity: ${LOGGING_VERBOSITY}"
  echo "${kindCfg}" | ${kindCmd} --config=-
fi

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
  log_message "1" "==== Create the htpasswd file where user: ${REGISTRY_USER} and password: ${REGISTRY_PASSWORD}"
  mkdir -p auth
  docker run --entrypoint htpasswd registry:2.7.0 -Bbn ${REGISTRY_USER} ${REGISTRY_PASSWORD} > auth/htpasswd

  log_message "1" "==== Creating a docker registry"
  docker run -d \
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
  docker network connect kind "${registry_name}" --alias registry.local || true

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
  # Start a local Docker registry (unless it already exists)
  running="$(docker inspect -f '{{.State.Running}}' "${registry_name}" 2>/dev/null || true)"
  if [ "${running}" != 'true' ]; then
    docker run \
      -d --restart=always -p "${REGISTRY_PORT}:5000" --name "${registry_name}" \
      registry:2
  fi

  # Connect the local Docker registry with the kind network
  docker network connect "kind" "${registry_name}" > /dev/null 2>&1 &
fi

log_message "1" "INGRESS: ${INGRESS}"
if [ "${INGRESS}" == 'kourier' ]; then
  deploy_ingress_kourier
elif [ "${INGRESS}" == 'nginx' ]; then
  deploy_ingress_nginx
fi
