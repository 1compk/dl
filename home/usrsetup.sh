echo "Start from Home"
cd /home

echo "Plz provide your User"
read -p "For Extract Setting Files : " inputuser

echo "Your User is : "$USER" "

echo "Extracting Setting Files..."
sudo 7z x -y User.Settings.7z -o/home/"$USER"
sudo 7z x -y Firefox.Settings.7z -o/home/"$USER"

echo "Changing Owner of Setting Files..."
sudo chown -R "$USER":user /home/"$USER"

echo "Updating and Upgrading System..."
sudo apt update && sudo apt upgrade -y

echo "Cleaning..."
sudo nala clean

echo "Installing Lastest FDM and Neofetch..."
sudo apt install apparmor apparmor-profiles engrampa fastfetch mate-polkit sddm-theme-maui

echo "Cleaning..."
sudo nala clean

echo "Setting Desktop Manager..."
#sudo dpkg-reconfigure sddm

echo "Setting Timezone..."
sudo dpkg-reconfigure tzdata

echo "Setting Completed..."
echo "Now Plz Reboot by : sudo reboot"
