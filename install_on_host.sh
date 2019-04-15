#!/bin/sh 
echo "Script Begin"

# check our script has been started with root auth
if [ "$(id -u)" != "0" ]; then
	echo "${RED}${BOLD}This script must be run with root privileges. Please run again as either root or using sudo.${NONE}"
	tput sgr0
	exit 1
fi

# install required packages
sudo apt-get update && sudo apt-get install sysstat lzop liblzo2-dev liblzo2-2 mtx mt-st sg3-utils zlib1g-dev git lsscsi build-essential gawk alien fakeroot linux-headers-$(uname -r) -y

# create user, group and folders 
sudo groupadd -r vtl
sudo useradd -r -c "Virtual Tape Library" -d /opt/mhvtl -g vtl vtl -s /bin/bash
sudo mkdir -p /opt/mhvtl
sudo mkdir -p /etc/mhvtl
sudo chown -Rf vtl:vtl /opt/mhvtl
sudo chown -Rf vtl:vtl /etc/mhvtl

make distclean
cd kernel/ 
make && sudo make install
cd .. 
make && sudo make install

# fix some errors 
sudo mkdir /etc/tgt
sudo ln -s /usr/lib64/libvtlscsi.so /usr/lib/
sudo /etc/init.d/mhvtl start

sleep 3
echo "Show your tape libraries now!"
lsscsi 

