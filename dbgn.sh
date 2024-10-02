apt update -y && apt install nala -y && nala fetch

nala update && nala upgrade -y

nala install 7zip exfatprogs ntfs-3g libqt5widgets5 lz4 mtools mmv zstd cmst fonts-liberation fonts-nanum fonts-sawarabi-gothic fonts-tlwg-waree pcmanfm ghex galculator gparted gnome-packagekit gnome-packagekit-common gnome-package-updater mousepad nemo nemo-data nemo-fileroller nemo-font-manager viewnior grub-customizer sddm gnome-tweaks -y

nala install anacron apt-xapian-index at-spi2-core colord cups dbus-x11 dmz-cursor-theme dconf-cli eject foomatic-db-compressed-ppds gdebi gnome-calculator gnome-control-center gnome-disk-utility gnome-desktop3-data gnome-menus gnome-screenshot gnome-system-monitor gnome-terminal gnome-session gnome-shell inputattach libnotify-bin libpulsedsp lm-sensors pavucontrol profile-sync-daemon pulseaudio pulseaudio-module-bluetooth software-properties-gtk system-config-printer tracker tracker-extract tracker-miner-fs upower x11-apps x11-session-utils x11-utils x11-xserver-utils xarchiver xdg-user-dirs xdg-user-dirs-gtk xfonts-base xserver-xorg xwayland zenity -y

nala clean
