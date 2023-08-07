#!/usr/bin/env bash

set -e
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

check_os_distro() {
  PLATFORM='unknown'
  unamestr=$(uname | tr '[:upper:]' '[:lower:]')
  if [[ "$unamestr" == 'linux' ]]; then
     PLATFORM='linux'
     DISTRO=$(cat /etc/*-release | tr [:upper:] [:lower:] | grep -Poi '(debian|ubuntu|red hat|centos|fedora)' | uniq )
  elif [[ "$unamestr" == 'darwin' ]]; then
     PLATFORM='linux'
     DISTRO='darwin'
  fi
  log "CYAN" "OS type: $PLATFORM"

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

init() {
  # Check OS TYPE and/or linux distro
  check_os_distro
  check_arch

  # Define the destination directory according to distro and arch
  if [ "$DISTRO" = "darwin" ] && [ "$ARCH" = "arm64" ]; then
    DEST_DIR="/opt/bin"
    log_msg "BLUE" $(printf "Destination dir: %s" $DEST_DIR)
  else
    DEST_DIR="/usr/local/bin"
    log_msg "BLUE" $(printf "Destination dir: %s" $DEST_DIR)
  fi

  # Install pre-req tools
  log "CYAN" "Installing useful tools: k9s, unzip, wget, jq,..."
  if [[ $DISTRO == 'fedora' ]]; then
    sudo yum install git wget unzip bash-completion openssl jq -y
  elif [[ $DISTRO == 'centos' ]]; then
    sudo yum install git wget unzip epel-release bash-completion jq -y
  elif [[ $DISTRO == 'darwin' ]]; then
    if ! command -v brew &> /dev/null; then
      log_msg "YELLOW" $(printf "Brew is not installed ! %s" https://brew.sh/)
    else
      brew install jq wget
    fi
  fi
}

docker() {
    if [ "$DISTRO" -eq "darwin" ]; then
        echo "Darwin installation is not supported."
    else
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/${DISTRO}/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo groupadd docker
        sudo usermod -aG docker $USER
        sudo chown $USER /var/run/docker.sock
        sudo systemctl restart docker
    fi
}

others() {
   if ! command -v pv &> /dev/null; then
     log "CYAN" "Installing Pipe viewer"
     sudo yum install -y pv
   fi
}

kubeTools() {
  K9S_VERSION=$(wget -qO- https://api.github.com/repos/derailed/k9s/releases/latest | jq -r '.tag_name')
  KIND_VERSION=$(wget -qO- https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | jq -r '.tag_name')

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
    wget -q https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${ARCH}.tar.gz && tar -vxf k9s_Linux_${ARCH}.tar.gz
    sudo cp k9s ${DEST_DIR}
  fi

  log "CYAN" "Checking if kubectl krew exists..."
  if ! command -v ${KREW_ROOT:-$HOME/.krew}/bin/kubectl-krew &> /dev/null; then
    log "CYAN" "Install kubectl krew tool - https://krew.sigs.k8s.io/docs/user-guide/setup/install/"
    (
      set -x; cd "$(mktemp -d)" &&
      KREW="krew-${DISTRO}_${ARCH}" &&
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

    log "CYAN" "Install kubectl-oidc-login - https://github.com/int128/kubelogin"
    ${KREW_ROOT:-$HOME/.krew}/bin/kubectl-krew install oidc-login

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
  check)
      check_os_distro
      check_arch
      exit;;
  docker)
      init
      docker
      exit;;
  others)
      init
      others
      exit;;
  *)
      init
      kubeTools
      exit;;
esac
