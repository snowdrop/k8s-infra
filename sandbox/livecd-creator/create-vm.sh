#!/usr/bin/env bash

LOCAL_HOST="/Users/dabou/images"
ISO_NAME="centos7.iso"
ISO="$LOCAL_HOST/$ISO_NAME"
VIRTUAL_BOX_NAME="CentOS-7.1" # VM Name
OSTYPE="Linux_64";
DISKSIZE=20480; #in MB
RAM=5120; #in MB
CPU=4;
CPUCAP=100;
PAE="on";
VRAM=8;
USB="off";

echo "######### Poweroff machine if it runs"
vboxmanage controlvm $VIRTUAL_BOX_NAME poweroff
echo "######### .............. Done"

echo "######### unregister vm "$VIRTUAL_BOX_NAME" and delete it"
vboxmanage unregistervm $VIRTUAL_BOX_NAME --delete || echo "No VM by name ${VIRTUAL_BOX_NAME}"

####################################################################
echo "######### Create vboxnet0 network and set dhcp server : 192.168.99.0/24"
vboxmanage hostonlyif remove vboxnet0
vboxmanage hostonlyif create
vboxmanage hostonlyif ipconfig vboxnet0 --ip 192.168.99.1 --netmask 255.255.255.0
vboxmanage dhcpserver remove --ifname vboxnet0
vboxmanage dhcpserver add --ifname vboxnet0 --ip 192.168.99.20 --netmask 255.255.255.0 --lowerip 192.168.99.50 --upperip 192.168.99.50
vboxmanage dhcpserver modify --ifname vboxnet0 --enable

##########################################
echo "######### Create VM"
vboxmanage createvm --name ${VIRTUAL_BOX_NAME} --ostype "$OSTYPE" --register --basefolder=$HOME/VirtualBox\ VMs

# VirtualBox Network
echo "######### Define NIC adapters; NAT and vboxnet0"
vboxmanage modifyvm ${VIRTUAL_BOX_NAME} \
        --nic1 hostonly --hostonlyadapter1 vboxnet0 \
        --nic2 nat

# VM Config
echo "######### Customize vm; ram, cpu, ...."
vboxmanage modifyvm ${VIRTUAL_BOX_NAME} --memory "$RAM";
vboxmanage modifyvm ${VIRTUAL_BOX_NAME} --boot1 dvd --boot2 dvd --boot3 disk --boot4 none;
vboxmanage modifyvm ${VIRTUAL_BOX_NAME} --chipset piix3;
vboxmanage modifyvm ${VIRTUAL_BOX_NAME} --ioapic on;
vboxmanage modifyvm ${VIRTUAL_BOX_NAME} --mouse ps2;
vboxmanage modifyvm ${VIRTUAL_BOX_NAME} --cpus "$CPU" --cpuexecutioncap "$CPUCAP" --pae "$PAE";
vboxmanage modifyvm ${VIRTUAL_BOX_NAME} --hwvirtex off --nestedpaging off;

vboxmanage modifyvm ${VIRTUAL_BOX_NAME} --vram "$VRAM";
vboxmanage modifyvm ${VIRTUAL_BOX_NAME} --monitorcount 1;
vboxmanage modifyvm ${VIRTUAL_BOX_NAME} --accelerate2dvideo off --accelerate3d off;
vboxmanage modifyvm ${VIRTUAL_BOX_NAME} --audio none;
vboxmanage modifyvm ${VIRTUAL_BOX_NAME} --hpet on;
vboxmanage modifyvm ${VIRTUAL_BOX_NAME} --x2apic off;
vboxmanage modifyvm ${VIRTUAL_BOX_NAME} --rtcuseutc on;
vboxmanage modifyvm ${VIRTUAL_BOX_NAME} --nestedpaging on;
vboxmanage modifyvm ${VIRTUAL_BOX_NAME} --hwvirtex on;

vboxmanage modifyvm ${VIRTUAL_BOX_NAME} --clipboard bidirectional;
vboxmanage modifyvm ${VIRTUAL_BOX_NAME} --usb "$USB";
vboxmanage modifyvm ${VIRTUAL_BOX_NAME} --vrde on;

# VirtualBox HDD
echo "######### Create SATA storage"
vboxmanage storagectl ${VIRTUAL_BOX_NAME} --name "SATA" --add sata --controller IntelAhci --bootable on --hostiocache on

echo "######### Create vmdk HD"
vboxmanage createhd --filename $HOME/VirtualBox\ VMs/${VIRTUAL_BOX_NAME}/disk.vmdk --size 29296 --format VMDK

echo "######### Attach vmdk and ISO to SATA Controller"
vboxmanage storageattach ${VIRTUAL_BOX_NAME} --storagectl "SATA" --type dvddrive --port 0 --medium $ISO
vboxmanage storageattach ${VIRTUAL_BOX_NAME} --storagectl "SATA" --type hdd --port 1 --medium $HOME/VirtualBox\ VMs/${VIRTUAL_BOX_NAME}/disk.vmdk

vboxmanage startvm ${VIRTUAL_BOX_NAME} --type headless
vboxmanage controlvm ${VIRTUAL_BOX_NAME} natpf2 ssh,tcp,127.0.0.1,5222,,22

