#!/usr/bin/env bash

IMAGE_DIR=$1
VIRTUAL_BOX_NAME="CentOS-7" # VM Name
OSTYPE="Linux_64";
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

echo "######### Copy disk.vdi created"
cp ${IMAGE_DIR}/centos7.vdi ${IMAGE_DIR}/disk.vdi

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

echo "######### Resize VDI disk to 15GB"
vboxmanage modifyhd ${IMAGE_DIR}/disk.vdi --resize 20000

echo "######### Create IDE Controller, attach vdi disk and iso dvd"
vboxmanage storagectl ${VIRTUAL_BOX_NAME} --name "IDE Controller" --add ide --hostiocache on
vboxmanage storageattach ${VIRTUAL_BOX_NAME} --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium ${IMAGE_DIR}/vbox-config.iso
vboxmanage storageattach ${VIRTUAL_BOX_NAME} --storagectl "IDE Controller" --port 1 --device 0 --type hdd --medium ${IMAGE_DIR}/disk.vdi

echo "######### start vm and configure SSH Port forward"
vboxmanage startvm ${VIRTUAL_BOX_NAME} --type headless
vboxmanage controlvm ${VIRTUAL_BOX_NAME} natpf2 ssh,tcp,127.0.0.1,5222,,22

