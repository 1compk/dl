#!/bin/bash
#echo "deb http://debian-archive.trafficmanager.net/debian/ bookworm main" > /etc/apt/sources.list.d/nala-bookworm.list
#echo "deb https://mirror.sg.gs/debian/ bookworm main" >> /etc/apt/sources.list.d/nala-bookworm.list
#echo "deb https://mirror.twds.com.tw/debian/ bookworm main" >> /etc/apt/sources.list.d/nala-bookworm.list
cp -u nala-bookworm.list /etc/apt/sources.list.d/

#passwd guest
#usermod -l user guest
#usermod -d /home/user -m user

# Unblock wifi
rfkill unblock all
rfkill unblock wifi

#Scan for wifi :
nmcli d wifi list

# Prompt for New User and Password
read -p "Enter SSID : " nmssid
read -p "Enter Password : " wifipass
nmcli d wifi connect "$nmssid" password "$wifipass"

ping -c 2 1.1.1.1

apt update -y && apt install nala perl sudo -y

nala --install-completion bash

nala clean

#deluser --remove-home guest
#ls /home

# Prompt for New User and Password
#read -p "Enter New User : " inputuser
#adduser "$inputuser"
#usermod -aG sudo,audio,video,dip,netdev,plugdev "$inputuser"
#id -Gn "$inputuser"
#echo

nala update && apt upgrade -y

nala clean

nala install bash-completion elpa-bash-completion gcc network-manager systemd-timesyncd -y

nala clean

ping -c 2 1.1.1.1
