FROM dtzar/helm-kubectl

ARG KIND_VERSION
ARG KUBECTX_VERSION

RUN apk add --no-cache docker
RUN wget -q https://github.com/kubernetes-sigs/kind/releases/download/v${KIND_VERSION}/kind-linux-amd64 -O /usr/local/bin/kind && chmod +x /usr/local/bin/kind \
    && wget -q https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_VERSION}/kubectx_v${KUBECTX_VERSION}_linux_x86_64.tar.gz -O - | tar -xzO kubectx > /usr/local/bin/kubectx \
    && chmod +x /usr/local/bin/kubectx \
    && wget -q https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_VERSION}/kubens_v${KUBECTX_VERSION}_linux_x86_64.tar.gz -O - | tar -xzO kubens > /usr/local/bin/kubens \
    && chmod +x /usr/local/bin/kubens
