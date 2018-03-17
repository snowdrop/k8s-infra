## OS Installation on Hetzner Cloud Machine

You first need to login to Hetzner robot
at https://robot.your-server.de/server

### Install CentOS 7.4 Minimal

* Select CentOS 7.4 in Linux tab and accept initiate installation. Take care to note the root password supplied.
* Initiate a reset from the Reset tab.
* Wait a few minutes for the installation to complete

### Copy ssh key to machine

You need to perform ssh-copy-id root@ipaddress in order to later perform password-less login
The root password is supplied via email when the Hetzner machine is initially created

### Install NetworkManager

```bash
yum install -y NetworkManager
systemctl enable NetworkManager
systemct start NetworkManager
```

## Install Openshift

Follow the instructions in `../ansible/README-cloud.md`