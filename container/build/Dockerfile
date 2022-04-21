FROM centos:8

ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN cd /etc/yum.repos.d/
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

RUN dnf check-update ; \
    dnf install -y gcc libffi-devel python3 epel-release ; \
    dnf install -y python3-pip ; \
    dnf install -y jq wget openvpn git pass pinentry-curses ; \
    dnf clean all

RUN pip3 install --upgrade pip; \
    pip3 install --upgrade virtualenv; \
    python3 -m pip install ansible decorator openstacksdk wheel

RUN ansible-galaxy collection install openstack.cloud ibm.cloudcollection community.general

ENV PASSWORD_STORE_DIR=/opt/volumes/pass
ENV GNUPGHOME=/opt/volumes/gnupg

WORKDIR /opt

COPY --chmod=755 entrypoint.sh /opt/

ENTRYPOINT ["/opt/entrypoint.sh"]
