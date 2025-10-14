echo "Updating and Upgrading System..."
sudo apt update -y && sudo apt upgrade -y

echo "Cleaning..."
sudo nala clean

sudo apt install git -y

git clone https://github.com/1compk/minios-skyline.git

sync

cd minios-skyline

sudo chmod +x tx.xfce.build.sh

ls
