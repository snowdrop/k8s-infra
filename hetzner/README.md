## OS Installation on Hetzner Cloud Machine

You first need to login to Hetzner robot
at https://robot.your-server.de/server

### Install Fedora on Machine

* Initiate VNC connection from VNC tab
    - Select Fedora OS
    - Note the address and password on the console
* Reset machine
* Login to machine via a VNC client using the address and password for one of the previous steps
* In order to install the Fedora, space need to be reclaimed on Disk(s)
    - The only way I got this to work, was to delete the largest the partition on disk(s), while leaving the other ones intact
* Select Fedora Cloud in Software

### Copy ssh key to machine

You need to perform ssh-copy-id root@ipaddress in order to later perform password-less login
The root password is supplied via email when the Hetzner machine is initially created

## Install Openshift

Follow the instructions in `../ansible/README.md`