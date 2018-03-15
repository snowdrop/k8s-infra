# Action
install
cdrom

# Run the Setup Agent on first boot
firstboot --enable

# Accept Eula
eula --agreed

# Keyboard layouts
keyboard --xlayouts='us'

# System language
lang en_US.UTF-8

# Root pwd
sshpw --username=root --plaintext centos
rootpw --plaintext centos
auth --useshadow --passalgo=sha512

# System timezone
timezone Europe/Brussels --isUtc --ntpservers=0.centos.pool.ntp.org,1.centos.pool.ntp.org,2.centos.pool.ntp.org,3.centos.pool.ntp.org

# System services
services --enabled=NetworkManager,sshd

# Shutdown after installing
shutdown

# Firewall configuration
firewall --disabled
selinux --enforcing

# Network information
network --bootproto=dhcp --device=eth0 --activate --onboot=on
network --bootproto=dhcp --device=eth1 --activate --onboot=on

# System bootloader configuration
bootloader --timeout=1 --location=mbr --boot-drive=sda --append="no_timer_check console=ttyS0 console=tty0 net.ifnames=0 biosdevname=0"
autopart --type=lvm
zerombr

# Partition clearing information
clearpart --all --drives=sda
ignoredisk --only-use=sda

#Repos
repo --name=base --baseurl=http://mirror.centos.org/centos/7/os/x86_64/
repo --name=updates --baseurl=http://mirror.centos.org/centos/7/updates/x86_64/
repo --name=extras --baseurl=http://mirror.centos.org/centos/7/extras/x86_64/
repo --name=atomic --baseurl=http://mirror.centos.org/centos/7/atomic/x86_64/adb/

%packages  --excludedocs --instLangs=en --ignoremissing
@core
openssl
bash
docker # TODO Check why this package is not there during installation
dracut
e4fsprogs
efibootmgr
grub2
grub2-efi
kernel
net-tools
parted
shadow-utils
shim
python-setuptools

#Packages to be removed
-aic94xx-firmware
-alsa-firmware
-iprutils
-ivtv-firmware
-iwl100-firmware
-iwl1000-firmware
-iwl105-firmware
-iwl135-firmware
-iwl2000-firmware
-iwl2030-firmware
-iwl3160-firmware
-iwl3945-firmware
-iwl4965-firmware
-iwl5000-firmware
-iwl5150-firmware
-iwl6000-firmware
-iwl6000g2a-firmware
-iwl6000g2b-firmware
-iwl6050-firmware
-iwl7260-firmware
-iwl7265-firmware
-postfix
-rsyslog
%end