#!/usr/bin/env bash

###################
# Global parameters
###################
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

newline=$'\n'

###############
## Functions ##
###############
fmt() {
  COLOR="WHITE"
  MSG="${@:1}"
  echo -e "${!COLOR} ${MSG}${NC}"
}

generate_eyecatcher(){
  COLOR=${1}
	for i in {1..50}; do echo -ne "${!COLOR}$2${NC}"; done
}

log_msg() {
  COLOR=${1}
  MSG="${@:2}"
  echo -e "\n${!COLOR}## ${MSG}${NC}"
}

log_line() {
  COLOR=${1}
  MSG="${@:2}"
  echo -e "${!COLOR}## ${MSG}${NC}"
}

log() {
  MSG="${@:2}"
  echo; generate_eyecatcher ${1} '#'; log_msg ${1} ${MSG}; generate_eyecatcher ${1} '#'; echo
}

check_os() {
  PLATFORM='unknown'
  unamestr=$(uname)
  if [[ "$unamestr" == 'Linux' ]]; then
     PLATFORM='linux'
  elif [[ "$unamestr" == 'Darwin' ]]; then
     PLATFORM='darwin'
  fi
  log "CYAN" "OS type: $PLATFORM"
}

check_distro() {
  DISTRO=$( cat /etc/*-release | tr [:upper:] [:lower:] | grep -Poi '(debian|ubuntu|red hat|centos|fedora)' | uniq )
  if [ -z $DISTRO ]; then
      DISTRO='unknown'
  fi
  log "CYAN" "Detected Linux distribution: $DISTRO"
}

check_arch() {
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"
  if [ -z $ARCH ]; then
        ARCH='unknown'
    fi
    log "CYAN" "Detected Arch: $ARCH"
}

docker() {
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/${DISTRO}/docker-ce.repo
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    #sudo yum install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo groupadd docker
    sudo usermod -aG docker $USER
    echo "Please reboot the VM !!"
}

others() {
   if ! command -v pv &> /dev/null; then
     log "CYAN" "Installing Pipe viewer"
     yum install pv
   fi
}

kubeTools() {
  K9S_VERSION=$(curl -s "https://api.github.com/repos/derailed/k9s/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
  KIND_VERSION=$(curl -s "https://api.github.com/repos/kubernetes-sigs/kind/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')

  REMOTE_HOME_DIR=${REMOTE_HOME_DIR:-$HOME}
  DEST_DIR="/usr/local/bin"

  # Check OS TYPE and/or linux distro
  check_os
  check_distro
  check_arch

  log "CYAN" "Install useful tools: k9s, unzip, wget, jq,..."
  if [[ $DISTRO == 'fedora' ]]; then
    sudo yum install git wget unzip bash-completion openssl -y
  else
    sudo yum install git wget unzip epel-release bash-completion -y
  fi

  if ! command -v helm &> /dev/null; then
    log "CYAN" "Installing Helm"
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
  fi

  log "CYAN" "Checking if kubectl is installed..."
  if ! command -v kubectl &> /dev/null; then
     set -x
     curl -sLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/${PLATFORM}/${ARCH}/kubectl"
     chmod +x ./kubectl; sudo mv ./kubectl ${DEST_DIR}/kubectl
     set +x
  fi

  log "CYAN" "Checking if kind exists..."
  if ! command -v kind &> /dev/null; then
     set -x
     curl -sLo ./kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-${PLATFORM}-${ARCH}
     chmod +x ./kind; sudo mv ./kind ${DEST_DIR}/kind
     set +x
  fi

  log "CYAN" "Checking if k9s exists..."
  if ! command -v k9s &> /dev/null; then
    sudo yum install jq -y
    wget -q https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${ARCH}.tar.gz && tar -vxf k9s_Linux_${ARCH}.tar.gz
    sudo cp k9s ${DEST_DIR}
  fi

  log "CYAN" "Checking if kubectl krew exists..."
  if ! command -v ${KREW_ROOT:-$HOME/.krew}/bin/kubectl-krew &> /dev/null; then
    log "CYAN" "Install kubectl krew tool - https://krew.sigs.k8s.io/docs/user-guide/setup/install/"
    (
      set -x; cd "$(mktemp -d)" &&
      OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
      ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
      KREW="krew-${OS}_${ARCH}" &&
      curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
      tar zxvf "${KREW}.tar.gz" &&
      ./"${KREW}" install krew
    )

    log "CYAN" "Install kubectl-tree - https://github.com/ahmetb/kubectl-tree"
    ${KREW_ROOT:-$HOME/.krew}/bin/kubectl-krew install tree

    log "CYAN" "Install kubectl-ctx, kubectl-ns - https://github.com/ahmetb/kubectx"
    ${KREW_ROOT:-$HOME/.krew}/bin/kubectl-krew install ctx
    ${KREW_ROOT:-$HOME/.krew}/bin/kubectl-krew install ns

    log "CYAN" "Install kubectl-konfig - https://github.com/corneliusweig/konfig"
    ${KREW_ROOT:-$HOME/.krew}/bin/kubectl-krew install konfig

    BASHRC_D_DIR="$HOME/.bashrc.d"
    if [ ! -d ${BASHRC_D_DIR} ]; then
        mkdir -p ${BASHRC_D_DIR}
    fi

    log "CYAN" "Export krew PATH to ${BASHRC_D_DIR}/krew.path"
    echo "PATH=\"${KREW_ROOT:-$HOME/.krew}/bin:$PATH\"" > ${BASHRC_D_DIR}/krew.path

    log "CYAN" "Create kubectl & plugins aliases to ${BASHRC_D_DIR}/aliases"
    cat <<EOF > ${BASHRC_D_DIR}/aliases
# kubectl shortcut -> kc
alias kc='kubectl'
# kubectl shortcut -> k
alias k='kubectl'

# kubectl krew
alias krew='kubectl krew'

# kubectl tree
alias ktree='kubectl tree'

# kubectl ns
alias kns='kubectl ns'

# kubectl ctx
alias kctx='kubectl ctx'

# kubectl konfig
alias konfig='kubectl konfig'
EOF

  log "CYAN" "$(cat ${BASHRC_D_DIR}/aliases)"
  log "WARN" "Source now the .bashrc file: \". $HOME/.bashrc\" in your terminal"

  fi
}

case $1 in
    docker)     docker; exit;;
    others)     others; exit;;
    *)          exit;;
esac

kubeTools
