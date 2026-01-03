echo "Add Updating and Upgrading System Mirrors..."
echo "deb https://mirror.twds.com.tw/ubuntu/ noble main restricted universe multiverse" >> /etc/apt/sources.list.d/nala-noble.list
echo "deb https://repo.huaweicloud.com/ubuntu/ noble main restricted universe multiverse" >> /etc/apt/sources.list.d/nala-noble.list
#cp -u nala-noble.list /etc/apt/sources.list.d/

echo "Updating and Upgrading System..."
sudo apt modernize-sources -y
sudo apt update && sudo apt upgrade -y
