# Install OS instead of upgrade
cdrom
install

# Accept Eula
eula --agreed

# Keyboard layouts
keyboard 'us'

# Disable firstboot
firstboot --disable

# System language
lang en_US.UTF-8

# Root pwd
sshpw --username=root --plaintext centos
rootpw --plaintext centos
auth --useshadow --passalgo=sha512

# Skip media disk check
skipx

# System timezone
timezone Europe/Brussels --isUtc --ntpservers=0.centos.pool.ntp.org,1.centos.pool.ntp.org,2.centos.pool.ntp.org,3.centos.pool.ntp.org

# System services
services --enabled=NetworkManager,sshd

# Shutdown after installing
shutdown

# Firewall configuration
firewall --disabled

# Selinux
selinux --disabled

# Network information
network --bootproto=dhcp --device=eth0 --activate --onboot=on
network --bootproto=dhcp --device=eth1 --activate --onboot=on

# System bootloader configuration
bootloader --timeout=1 --location=mbr --append="no_timer_check console=ttyS0 console=tty0 net.ifnames=0 biosdevname=0"

# Clear the Master Boot Record
zerombr

# Partition clearing information
autopart --type=lvm
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
docker
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
syslinux
python-setuptools
yum

# The point of a live image is to install
anaconda
isomd5sum

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

%post

cat > /etc/rc.d/init.d/centos-live << EOF
#!/bin/bash
#
# live: Init script for live image
#
# chkconfig: 345 00 99
# description: Init script for live image.

. /etc/init.d/functions

# add centos user with no passwd
useradd -c "Jerry" centos
echo 'password' | passwd --stdin centos

# Stopgap fix for RH #217966; should be fixed in HAL instead
touch /media/.hal-mtab
EOF

chmod 755 /etc/rc.d/init.d/centos-live
/sbin/restorecon /etc/rc.d/init.d/centos-live
/sbin/chkconfig --add centos-live

echo "Welcome to my world" > /etc/motd
%end