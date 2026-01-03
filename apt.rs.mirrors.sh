echo "Add Updating and Upgrading System Mirrors..."

# Use tee to write to the file with sudo privileges
echo "deb https://mirror.twds.com.tw/ubuntu/ resolute main restricted universe multiverse" | sudo tee /etc/apt/sources.list.d/nala-resolute.list > /dev/null

# Use tee -a (append) to add the second mirror
echo "deb https://repo.huaweicloud.com/ubuntu/ resolute main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list.d/nala-resolute.list > /dev/null

#cp -u nala-resolute.list /etc/apt/sources.list.d/

echo "Updating and Upgrading System..."
# Debian 13 (trixie) officially supports modernizing to the deb822 (.sources) format
sudo apt modernize-sources -y
sudo apt update && sudo apt upgrade -y
