default: docker_build

DOCKER_IMAGE ?= snowdrop/kubetools
DOCKER_TAG ?= latest

# Note: Latest version of kind may be found at:
# https://github.com/kubernetes-sigs/kind/releases
KIND_VERSION=0.10.0

# Note: Latest version of kubectx, kubens may be found at:
# https://github.com/ahmetb/kubectx/releases
KUBECTX_VERSION=0.9.3

# Latest version of docker can be found
# https://download.docker.com/linux/static/stable/x86_64/
DOCKER_VERSION=19.03.14

docker_build:
	docker build \
      --build-arg KIND_VERSION=$(KIND_VERSION)  \
      --build-arg KUBECTX_VERSION=$(KUBECTX_VERSION) \
      --build-arg DOCKER_VERSION=${DOCKER_VERSION} \
	  -t $(DOCKER_IMAGE):$(DOCKER_TAG) .
	docker tag $(DOCKER_IMAGE):$(DOCKER_TAG) quay.io/$(DOCKER_IMAGE):$(DOCKER_TAG)

docker_push:
	# Push to quay.io
	docker push quay.io/$(DOCKER_IMAGE):$(DOCKER_TAG)
