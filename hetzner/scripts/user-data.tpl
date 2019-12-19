#cloud-config
chpasswd:
  list: |
    root:USER_PASSWORD_HASHED
  expire: False

disable_root: false

package_upgrade: false

yum_repos:
  - epel:
      baseurl: http://download.fedoraproject.org/pub/epel/7/$basearch
      enabled: true
      gpgcheck: false
      name: Extra Packages for Centos 7 - $basearch

packages:
  - ansible
  - git

users:
  - name: centos
    gecos: Centos User
    passwd: USER_PASSWORD_HASHED
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
  - timedatectl set-timezone TIMEZONE

