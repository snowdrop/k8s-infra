default: docker_build

DOCKER_IMAGE ?= snowdrop/kubetools
DOCKER_TAG ?= latest

KIND_VERSION=0.10.0
KUBECTX_VERSION=0.9.3

docker_build:
	@docker build \
      --build-arg KIND_VERSION=$(KIND_VERSION)  \
      --build-arg KUBECTX_VERSION=$(KUBECTX_VERSION) \
	  -t $(DOCKER_IMAGE):$(DOCKER_TAG) .
	@docker tag $(DOCKER_IMAGE):$(DOCKER_TAG) quay.io/$(DOCKER_IMAGE):$(DOCKER_TAG)

docker_push:
	# Push to quay.io
	@docker push quay.io/$(DOCKER_IMAGE):$(DOCKER_TAG)
