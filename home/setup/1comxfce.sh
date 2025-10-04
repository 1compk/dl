#sudo dpkg --add-architecture i386
#!/bin/bash

echo "Updating..."
sudo apt update -y

echo "Installing Nala..."
sudo apt install nala -y

echo "Installing Nala Completion Bash..."
sudo nala --install-completion bash

echo "Updating..."
sudo apt update -y && sudo apt upgrade -y

echo "Cleaning..."
sudo nala clean

echo "Installing 1ComXFce..."
xargs -a 1comxfce sudo apt install

echo "Updating..."
sudo apt update -y

echo "Cleaning..."
sudo nala clean

echo "Setting Desktop Manager..."
sudo dpkg-reconfigure sddm

echo "Setting Timezone..."
sudo dpkg-reconfigure tzdata

echo "Setting Completed..."
echo "Now Plz Reboot by : sudo reboot"