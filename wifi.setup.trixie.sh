#!/bin/bash
#echo "deb http://debian-archive.trafficmanager.net/debian/ trixie main" > /etc/apt/sources.list.d/nala-trixie.list
#echo "deb https://mirror.sg.gs/debian/ trixie main" >> /etc/apt/sources.list.d/nala-trixie.list
#echo "deb https://mirror.twds.com.tw/debian/ trixie main" >> /etc/apt/sources.list.d/nala-trixie.list
rsync -avP nala-trixie.list /etc/apt/sources.list.d/

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

apt update -y && apt install nala systemd-timesyncd perl sudo -y

nala --install-completion bash

nala clean

deluser --remove-home guest
ls /home

apt update -y && apt upgrade -y

nala clean

apt install bash-completion elpa-bash-completion network-manager -y

nala clean