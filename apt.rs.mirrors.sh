echo "Add Updating and Upgrading System Mirrors..."
echo "deb https://mirror.twds.com.tw/ubuntu/ resolute main restricted universe multiverse" >> /etc/apt/sources.list.d/nala-resolute.list
echo "deb https://repo.huaweicloud.com/ubuntu/ resolute main restricted universe multiverse" >> /etc/apt/sources.list.d/nala-resolute.list
#cp -u nala-resolute.list /etc/apt/sources.list.d/

echo "Updating and Upgrading System..."
sudo apt modernize-sources -y
sudo apt update && sudo apt upgrade -y