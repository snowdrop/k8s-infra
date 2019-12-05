#cloud-config
chpasswd:
  list: |
    root:USER_PASSWORD_HASHED
  expire: False

disable_root: false

package_upgrade: false

packages:
  - ansible

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

