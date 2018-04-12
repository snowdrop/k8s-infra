## OS Installation on Hetzner Cloud Machine

You first need to login to Hetzner robot
at https://robot.your-server.de/server

### Install CentOS 7.4 Minimal

* Select CentOS 7.4 in Linux tab and accept initiate installation. Take care to note the root password supplied.
![Linux installation](linux-installation.png)

* Initiate a reset from the Reset tab.
![Hardware reset](hardware-reset.png)

* Wait a few minutes for the installation to complete

### Copy ssh key to machine

You need to perform `ssh-copy-id root@ipaddress` in order to later perform password-less login
The root password is supplied via email when the Hetzner machine is initially created

E.g

```bash
sshpass -f pwd.txt ssh -o StrictHostKeyChecking=no root@195.201.87.126 "mkdir ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
sshpass -f pwd.txt ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub root@195.201.87.126
```

### PRe-req : Install NetworkManager

```bash
yum install -y NetworkManager
systemctl enable NetworkManager
systemctl start NetworkManager
```

## Install OpenShift

Follow the instructions in `../ansible/README-cloud.md`
