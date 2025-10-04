echo "Start from Home"
cd /home

echo "Plz provide your User"
read -p "For Extract Setting Files : " inputuser

echo "Your User is : $inputuser "

echo "Extracting Setting Files..."
sudo 7z x -y User.Settings.7z -o/home/"$inputuser"
sudo 7z x -y Firefox.Settings.7z -o/home/"$inputuser"

echo "Changing Owner of Setting Files..."
sudo chown -R "$inputuser":"$inputuser" /home/"$inputuser"

echo "Updating and Upgrading System..."
sudo nala update && sudo apt upgrade -y

echo "Cleaning..."
sudo nala clean

echo "Installing Lastest FDM and Neofetch..."
sudo nala install apparmor apparmor-profiles engrampa neofetch

echo "Cleaning..."
sudo nala clean

echo "Setting Desktop Manager..."
#sudo dpkg-reconfigure sddm

echo "Setting Timezone..."
sudo dpkg-reconfigure tzdata

echo "Setting Completed..."
echo "Now Plz Reboot by : sudo reboot"
