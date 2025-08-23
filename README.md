Armbian AMD64 Downloads : https://dl.armbian.com/uefi-x86/

Mirror : https://mirror.twds.com.tw/armbian-dl/uefi-x86/archive/?C=S&O=D

Free Download Manager : https://debrepo.freedownloadmanager.org/pool/main/f/freedownloadmanager/

==================================================================

Flash img :

    Find Target Drive : lsblk
    Use DD Command for X = target drive :

sudo xzcat file.img.xz | sudo dd of=/dev/sdX status=progress bs=3M conv=fsync

sudo dd if=xxx.img of=/dev/sdX status=progress bs=3M conv=fsync

Decompress XZ : xz -dk xxx.img.xz

Decompress 7Zip : 7z x xxx.img.xz

==================================================================

Fast User Settings : sh /usersetup.sh

==================================================================

Install Grub bootloader :
lsblk = /dev/sdX > mount = /mnt/sdX

#Grub-Install gonna Create "/efi/grub" Files > /efi/grub/grub.cfg :

sudo grub-install --target=i386-pc /dev/sdX --boot-directory=/mnt/sdX2/efi --removable

#Grub-Install gonna Create "/efi/boot/bootx64.efi" File > /efi/boot/grub.cfg :

sudo grub-install --target=x86_64-efi --efi-directory=/mnt/sdX2 --boot-directory=/mnt/sdX2/efi --removable

==================================================================

#Slax64 Setting :

passwd guest

usermod -l user guest

usermod -d /home/user -m user

apt update && apt install sudo nala -y

usermod -aG sudo user

for amd gpu : firmware-amd-graphics mesa-vulkan-drivers 

==================================================================

#Gnome-Disks Mount Options :

defaults,x-gvfs-show,noauto

user,users,noatime,nodiratime,suid,dev,exec,async,comment=x-gvfs-show,x-gvfs-show,x-udisks-auth

==================================================================

#Ubuntu remove :

grub-customizer

libfontembed1

libpulsedsp

==================================================================

menuentry "Usb - SSTR Grub4Dos Boot Menu" {
    echo Searching... /SSTR/grldr
search --file --no-floppy --set=root /SSTR/grldr

    echo Loading... kernel
ntldr (${root})/SSTR/grldr

    echo Booting... /SSTR/grldr
boot
}

menuentry "Wimboot" {
    linux16 /wimboot/wimboot gui pause
    initrd16 newc:bcd:(loop)/boot/bcd \
           newc:boot.sdi:(loop)/boot/boot.sdi \
           newc:boot.wim:(loop)/sources/boot.wim
}
