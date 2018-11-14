#cloud-config
chpasswd:
  list: |
    root:centos
  expire: False

disable_root: false

package_upgrade: false

packages:
  - docker
  - git
  - wget
  - ansible
  - net-tools
  - NetworkManager
  - python-rhsm-certificates
  - atomic

users:
  - name: centos
    gecos: Centos User
    # Password is - passw0rd
    passwd: $6$altGzO36s.9bPVLU$F/X/IGg5Sdsmc1RgN78O7gV5kvbKX3OPPVvs/qobJpRM4CMQMxjf0JoiMRS1j4V//fkg1QT/6w5gd4KecVtod.
    lock-passwd: false
    chpasswd: { expire: False }
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_pwauth: True
    ssh_authorized_keys:
      - SSH_PUBLIC_KEY

  - name: root
    ssh_authorized_keys:
      - SSH_PUBLIC_KEY

runcmd:
  - yum install -y NetworkManager
  - rm -rf /etc/docker/certs.d/registry.access.redhat.com
  - systemctl enable docker
  - systemctl restart docker
  - systemctl start NetworkManager
  - systemctl enable NetworkManager
  - timedatectl set-timezone TIMEZONE
  - echo "192.168.99.50 $HOSTNAME" >> /etc/hosts
