#!/bin/bash

set -e

# Function to list disks and partitions using parted print
list_disks() {
  lsblk -a -p -o NAME,SIZE,MODEL,TRAN | grep -v "loop"
  # Show available disks and partitions 
  # Store the list of disks for validation later
  disks=()
  while read -r disk; do
    disks+=("/dev/$disk")  # Store full device paths
  done < <(lsblk -no -a -o NAME | grep -v loop) # Exclude loop devices

  echo "Available disks (sda, sdb, etc.):"
  for i in "${!disks[@]}"; do
    echo "$((i + 1)). ${disks[i]#/dev/}" # Show options without /dev/
  done
  read -p "Enter the number corresponding to the disk: " disk_num
  if [[ ! "$disk_num" =~ ^[0-9]+$ ]] || (( disk_num < 1 )) || (( disk_num > ${#disks[@]} )); then
      echo "Invalid disk number."
      return 1
  fi
  disk="${disks[$((disk_num - 1))]}" # Get the full path
  echo "You selected: ${disk##*/}"

  echo "Partitions on $disk:"
  sudo parted -s "$disk" print
  return 0 # Indicate success
}

# Function to create partitions (common logic)
create_partitions() {
  local disk=$1

  echo "==== Clear Drive or Unmount Partitons First ===="
  sudo gparted "$disk"

  # Create a new GPT partition table
  sudo parted -s "$disk" mklabel gpt

  # Create the BIOS partition (4 MB) for bios_grub
  sudo parted -s "$disk" mkpart bios 2MiB 5MiB
  sudo parted -s "$disk" set 1 bios_grub on

  # Create the EFI partition (800 MB) in FAT32
  sudo parted -s "$disk" mkpart efi fat32 5MiB 45MiB
  sudo parted -s "$disk" set 2 boot on
  sudo parted -s "$disk" set 2 esp on

  # Create the EXT4 partition (using remaining space for Linux)
  sudo parted -s "$disk" mkpart ext4 ext4 45MiB 50%

  # Format the partitions
  echo "Formatting partitions..."
  sudo mkfs.vfat -F32 "${disk}2"
  sudo mkfs.ext4 "${disk}3"

  echo "Partitions created and formatted."
}

mount_efi() {
  local disk=$1
  local efinput=$2
  local custom_mount=$3

  efinput="/dev/${disk##*/}$efinput"
  if [ ! -e "$efinput" ]; then
    echo "Error: Partition $efinput does not exist."
    return 1
  fi

  sudo mkdir -p "$custom_mount"
  echo "Mounting $efinput to $custom_mount"
  sudo mount "$efinput" "$custom_mount"

  echo "EFI partition mounted."
  return 0
}

install_grub() {
  local disk=$1
  local custom_mount=$2

  echo "Installing GRUB for BIOS (i386-pc)..."
  sudo grub-install --target=i386-pc "$disk" --boot-directory="$custom_mount/efi" --removable

  echo "Installing GRUB for UEFI (x86_64-efi)..."
  sudo grub-install --target=x86_64-efi --efi-directory="$custom_mount" --boot-directory="$custom_mount/efi" --removable

  echo "GRUB installation completed."
}

create_new_disk() {
  local efinput
  local custom_mount

  if ! list_disks; then return 1; fi

  create_partitions "$disk"  # Use the 'disk' from list_disks

  echo "Partitions on $disk (after creation):"
  sudo parted -s "$disk" print

  read -p "Enter the partition number for the EFI partition (see parted print output, e.g., 2): " efinput

  read -p "Enter the desired mount point for EFI partition (e.g., /mnt/sdb2): " custom_mount
  if [ -z "$custom_mount" ]; then
    custom_mount="/mnt/${disk##*/}${efinput}"  # Default: /mnt/sdb2 (e.g.)
    echo "Using default mount point: $custom_mount"
  fi

  if ! mount_efi "$disk" "$efinput" "$custom_mount"; then
      return 1
  fi
  
  install_grub "$disk" "$custom_mount"

  return 0
}

install_grub_only() {
  local efinput
  local custom_mount

  if ! list_disks; then return 1; fi

  echo "Partitions on $disk:"
  sudo parted -s "$disk" print

  read -p "Enter the partition number for the EFI partition (see parted print output, e.g., 2): " efinput
  sudo parted -s "$disk" set "${efinput##*/}" boot on
  sudo parted -s "$disk" set "${efinput##*/}" esp on

  read -p "Enter the desired mount point for EFI partition (e.g., /mnt/sdb2): " custom_mount
  if [ -z "$custom_mount" ]; then
    custom_mount="/mnt/${disk##*/}${efinput}"  # Default: /mnt/sdb2 (e.g.)
    echo "Using default mount point: $custom_mount"
  fi

  if ! mount_efi "$disk" "$efinput" "$custom_mount"; then
      return 1
  fi

  install_grub "$disk" "$custom_mount"

  return 0
}

show_disk_details() {
  if ! list_disks; then return 1; fi
  return 0
}

while true; do
  echo "App Need: grub-pc grub-efi-amd64-bin parted"
  echo "Choose an option:"
  echo "1. Create a new disk (Partition and Install GRUB)"
  echo "2. Install GRUB only (on an existing disk)"
  echo "3. Show disk details"
  echo "4. Exit"
  read -p "Enter your choice (1, 2, 3, or 4): " choice

  case $choice in
    1) if ! create_new_disk; then echo "Operation failed."; fi ;;
    2) if ! install_grub_only; then echo "Operation failed."; fi ;;
    3) if ! show_disk_details; then echo "Operation failed."; fi ;;
    4) echo "Exiting..." ; exit 0 ;;
    *) echo "Invalid choice. Please enter 1, 2, 3, or 4." ;;
  esac
done
