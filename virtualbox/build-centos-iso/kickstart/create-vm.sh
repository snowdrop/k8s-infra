#!/usr/bin/env bash

LOCAL_HOST="/Users/dabou/images"
ISO_NAME="centos7.iso"
ISO="$LOCAL_HOST/$CENTOS_ISO"
virtualbox_vm_name="CentOS-7.1" # VM Name
OSTYPE="Linux_64";
DISKSIZE=20480; #in MB
RAM=4096; #in MB
CPU=2;
CPUCAP=100;
PAE="on";
VRAM=8;
USB="off";

echo "######### Poweroff machine if it runs"
vboxmanage controlvm $virtualbox_vm_name poweroff
echo "######### .............. Done"

echo "######### unregister vm "$virtualbox_vm_name" and delete it"
vboxmanage unregistervm $virtualbox_vm_name --delete || echo "No VM by name ${virtualbox_vm_name}"

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
vboxmanage createvm --name ${virtualbox_vm_name} --ostype "$OSTYPE" --register --basefolder=$HOME/VirtualBox\ VMs

# VirtualBox Network
echo "######### Define NIC adapters; NAT and vboxnet0"
vboxmanage modifyvm ${virtualbox_vm_name} \
        --nic1 hostonly --hostonlyadapter1 vboxnet0 \
        --nic2 nat

# VM Config
echo "######### Customize vm; ram, cpu, ...."
vboxmanage modifyvm ${virtualbox_vm_name} --memory "$RAM";
vboxmanage modifyvm ${virtualbox_vm_name} --boot1 dvd --boot2 disk --boot3 none --boot4 none;
vboxmanage modifyvm ${virtualbox_vm_name} --chipset piix3;
vboxmanage modifyvm ${virtualbox_vm_name} --ioapic on;
vboxmanage modifyvm ${virtualbox_vm_name} --mouse ps2;
vboxmanage modifyvm ${virtualbox_vm_name} --cpus "$CPU" --cpuexecutioncap "$CPUCAP" --pae "$PAE";
vboxmanage modifyvm ${virtualbox_vm_name} --hwvirtex off --nestedpaging off;

vboxmanage modifyvm ${virtualbox_vm_name} --vram "$VRAM";
vboxmanage modifyvm ${virtualbox_vm_name} --monitorcount 1;
vboxmanage modifyvm ${virtualbox_vm_name} --accelerate2dvideo off --accelerate3d off;
vboxmanage modifyvm ${virtualbox_vm_name} --audio none;
vboxmanage modifyvm ${virtualbox_vm_name} --hpet on;
vboxmanage modifyvm ${virtualbox_vm_name} --x2apic off;
vboxmanage modifyvm ${virtualbox_vm_name} --rtcuseutc on;
vboxmanage modifyvm ${virtualbox_vm_name} --nestedpaging on;
vboxmanage modifyvm ${virtualbox_vm_name} --hwvirtex on;

vboxmanage modifyvm ${virtualbox_vm_name} --clipboard bidirectional;
vboxmanage modifyvm ${virtualbox_vm_name} --usb "$USB";
vboxmanage modifyvm ${virtualbox_vm_name} --vrde on;

# VirtualBox HDD
echo "######### Create SATA storage"
vboxmanage storagectl ${virtualbox_vm_name} --name "SATA" --add sata --controller IntelAhci --bootable on --hostiocache on

echo "######### Create vmdk HD"
vboxmanage createhd --filename $HOME/VirtualBox\ VMs/${virtualbox_vm_name}/disk.vmdk --size 29296 --format VMDK

echo "######### Attach vmdk to SATA Controller as port 1"
vboxmanage storageattach ${virtualbox_vm_name} --storagectl "SATA" --type hdd --port 0 --device 0 --medium $HOME/VirtualBox\ VMs/${virtualbox_vm_name}/disk.vmdk


echo "######### Create IDE storage"
vboxmanage storagectl ${virtualbox_vm_name} --name "IDE Controller" --add ide
vboxmanage storageattach ${virtualbox_vm_name} --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium $LOCAL_HOST/$ISO_NAME
vboxmanage storageattach ${virtualbox_vm_name} --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium emptydrive
vboxmanage storageattach ${virtualbox_vm_name} --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium additions
vboxmanage modifyvm ${virtualbox_vm_name} --boot1 dvd --boot2 disk --boot3 none --boot4 none

vboxmanage startvm ${virtualbox_vm_name} --type headless
until $(vboxmanage showvminfo --machinereadable CentOS-7.1 | grep -q ^VMState=.poweroff.); do
    sleep 10
done

echo "######### Remove IDE DVD"
vboxmanage storagectl ${virtualbox_vm_name} --name "IDE Controller" --remove
vboxmanage storagectl ${virtualbox_vm_name} --name "IDE Controller" --add ide
vboxmanage storageattach ${virtualbox_vm_name} --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium emptydrive

vboxmanage startvm ${virtualbox_vm_name} --type headless
vboxmanage controlvm ${virtualbox_vm_name} natpf2 ssh,tcp,127.0.0.1,5222,,22

