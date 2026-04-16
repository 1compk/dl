echo "Start from Home"
cd /home

echo "Plz provide your User"
read -p "For Extract Setting Files : " inputuser

echo "Your User is : "$USER" "

echo "Extracting Setting Files..."
sudo 7z x -y Noble.Settings.7z -o/home/"$USER"
sudo 7z x -y Noble.FF.Settings.7z -o/home/"$USER"
sudo 7z x -y Trixie.Settings.7z -o/home/"$USER"
sudo 7z x -y Trixie.FF.Settings.7z -o/home/"$USER"
sudo 7z x -y User.Settings.7z -o/home/"$USER"
sudo 7z x -y Firefox.Settings.7z -o/home/"$USER"

echo "Changing Owner of Setting Files..."
sudo chown -R "$USER":user /home/"$USER"/
sudo chown -R "$USER":user /home/"$USER"/.config
sudo chown -R "$USER":user /home/"$USER"/.local
sudo chown -R "$USER":user /home/"$USER"/.mozilla

echo "Updating and Upgrading System..."
sudo apt update && sudo apt upgrade -y
sudo mandb -c

echo "Cleaning..."
sudo nala clean

echo "Updating and Upgrading System..."
sudo apt modernize-sources -y
sudo apt update && sudo apt upgrade -y

echo "Installing Lastest FDM and Neofetch..."
sudo apt install apparmor apparmor-profiles engrampa ffmpeg mate-polkit sddm-theme-maui systemd-timesyncd

echo "Cleaning..."
sudo nala clean

sudo mv /etc/apt/sources.list.d/freedownloadmanager.list /etc/apt/sources.list.d/freedownloadmanager.bak

echo "Setting Desktop Manager..."
sudo dpkg-reconfigure sddm
sudo mousepad /etc/sddm.conf

echo "Setting Timezone..."
sudo dpkg-reconfigure tzdata

echo "Setting Completed..."
echo "Now Plz Reboot by : sudo reboot"
