echo "Add Updating and Upgrading System Mirrors..."
echo "deb https://mirror.sg.gs/debian/ bookworm main" >> /etc/apt/sources.list.d/nala-bookworm.list
echo "deb https://mirror.twds.com.tw/debian/ bookworm main" >> /etc/apt/sources.list.d/nala-bookworm.list
#cp -u nala-bookworm.list /etc/apt/sources.list.d/

echo "Updating and Upgrading System..."
sudo apt modernize-sources -y
sudo apt update && sudo apt upgrade -y
