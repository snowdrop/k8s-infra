#!/usr/bin/env bash

IP_ADDRESS=${1:-192.168.99.50}

vboxmanage hostonlyif ipconfig vboxnet0 --ip 192.168.99.1 --netmask 255.255.255.0
vboxmanage dhcpserver remove --ifname vboxnet0
vboxmanage dhcpserver add --ifname vboxnet0 --ip 192.168.99.20 --netmask 255.255.255.0 --lowerip ${IP_ADDRESS} --upperip ${IP_ADDRESS}
vboxmanage dhcpserver modify --ifname vboxnet0 --enable
