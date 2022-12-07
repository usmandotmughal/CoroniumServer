#!/bin/bash

#Coronium GS Installer for Ubuntu 14

function e {
	echo " "
	echo "-----------------------------------------------------------------"
	echo $1
	echo "-----------------------------------------------------------------"
	echo " "	
}

clear

e "Installing Luvit..."

cd /usr/local/src
git clone https://github.com/luvit/luvit.git

cd luvit

make
make install

cd ..

rm -rf luvit

clear

e "Installing redis luvit"

cd /usr/local/lib/luvit

git clone https://github.com/tadeuszwojcik/luvit-redis.git redis

cd redis

make

clear

e "Installing Coronium GS library"

cd /home/ubuntu

mv ./coronium-gs/gs.monit /etc/monit/monitrc.d/gs.monit

mv ./coronium-gs/Server/* .

#updater
mv ./coronium-gs/update-gs.sh .
chmod +x update-gs.sh

e "Installing service..."

mv gs.conf /etc/init/gs.conf

chown -R ubuntu:ubuntu *

rm -rf coronium-gs

#remove all installers
rm install*

e "Linking log file..."

ln -s /var/log/upstart/gs.log

clear

e "Finishing up..."

#clean up
passwd -l root

#keys
#shred -u /etc/ssh/*_key /etc/ssh/*_key.pub

#history
shred -u ~/.*history

updatedb

e "All Done! Rebooting..."

reboot

exit 0
