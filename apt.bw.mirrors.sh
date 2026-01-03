echo "Add Updating and Upgrading System Mirrors..."

# Use tee to write to the file with sudo privileges
echo "deb https://mirror.sg.gs/debian/ bookworm main" | sudo tee /etc/apt/sources.list.d/nala-bookworm.list > /dev/null

# Use tee -a (append) to add the second mirror
echo "deb https://mirror.twds.com.tw/debian/ bookworm main" | sudo tee -a /etc/apt/sources.list.d/nala-bookworm.list > /dev/null

#cp -u nala-bookworm.list /etc/apt/sources.list.d/

echo "Updating and Upgrading System..."
# Debian 13 (bookworm) officially supports modernizing to the deb822 (.sources) format
sudo apt modernize-sources -y
sudo apt update && sudo apt upgrade -y