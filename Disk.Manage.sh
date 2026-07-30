#!/usr/bin/env bash
set -euo pipefail

echo "==== Image Flashing & Disk Setup Utility ===="

die() { echo "ERROR: $*" >&2; exit 1; }

# List disks (full path)
list_disks() {
  echo
  echo "Available block devices:"
  lsblk -a -p -o NAME,TYPE,TRAN,SIZE,MODEL | grep -Ev "ram" || true
  echo
}

# Normalize device: accept /dev/sdx or sdx or sdxY
normalize_device() {
  local raw=$1
  local dev
  if [[ "$raw" == /dev/* ]]; then
    dev="$raw"
  else
    dev="/dev/$raw"
  fi
  if [[ ! -b "$dev" ]]; then
    die "Block device '$dev' not found."
  fi
  echo "$dev"
}

# Returns partition device name for a disk + partition number, handling nvme and mmcblk
get_part_name() {
  local disk="$1"
  local num="$2"
  if [[ "$disk" =~ (nvme|mmcblk) ]]; then
    printf "%sp%s" "$disk" "$num"
  else
    printf "%s%s" "$disk" "$num"
  fi
}

# Return separator for default mountpoint ("" or "p")
get_part_sep() {
  local disk="$1"
  if [[ "$disk" =~ (nvme|mmcblk) ]]; then
    printf "p"
  else
    printf ""
  fi
}

# Wait for a block device node to appear, up to timeout seconds (default 10s)
wait_for_part() {
  local part="$1"
  local timeout="${2:-10}"
  local waited=0
  while [[ ! -b "$part" && $waited -lt $timeout ]]; do
    sleep 0.5
    waited=$((waited + 1))
  done
  if [[ ! -b "$part" ]]; then
    echo "Warning: partition device $part did not appear after ${timeout}s"
    return 1
  fi
  return 0
}

# Confirm destructive action
confirm_action() {
  local target=$1
  echo
  echo "Selected: $target"
  echo "Confirm your target . Type y to proceed:"
  read -rn1 -p "> " c; echo
  [[ "$c" =~ ^[Yy]$ ]] || { echo "Aborted by user. Returning..."; main; }
}

# GUI partitioner runner
run_partitioner() {
  local cmd="$*"
  echo "Launching: $cmd"
  sudo --preserve-env=DISPLAY,XAUTHORITY sh -c "$cmd &"
  read -rp "Press ENTER when finished with the partitioner..."
}

# Ensure kernel sees partition changes and udev settled
rescan_and_settle() {
  local disk="$1"
  sudo sync || true
  sudo partprobe "$disk" || true
  sudo udevadm settle || true
  sudo systemctl daemon-reload || true
  sleep 1
}

# Flashing helper
flash_image() {
  local image=$1
  local target=$2
  if [[ ! -f "$image" || ! -r "$image" ]]; then die "Image '$image' not found/readable."; fi
  if [[ ! -b "$target" ]]; then die "Target '$target' is not a block device/partition."; fi
  if mount | grep -q "^$target"; then die "Target $target appears mounted. Unmount and retry."; fi

  if [[ "$image" == *.xz ]]; then
    if command -v xzcat >/dev/null 2>&1; then
      sudo xzcat "$image" | sudo dd of="$target" bs=4K status=progress conv=fdatasync
    elif command -v 7z >/dev/null 2>&1; then
      sudo 7z x -so "$image" | sudo dd of="$target" bs=4K status=progress conv=fdatasync
    else
      die "No xzcat or 7z available."
    fi
  elif [[ "$image" == *.img || "$image" == *.iso || "$image" == *.raw ]]; then
    sudo dd if="$image" of="$target" bs=4K status=progress conv=fdatasync
  else
    die "Unsupported image type."
  fi

  # Ensure writes flushed
  sudo sync
  sudo systemctl daemon-reload || true
  echo "Flashing complete."
}

# Wipe disk using wipefs or blkdiscard based on storage type
wipe_disk_completely() {
  list_disks
  read -rp "Enter target disk to WIPE completely (e.g., sdb or /dev/sdb): " disk_in
  local disk=$(normalize_device "$disk_in")
  
  echo "WARNING: This will completely wipe all partition tables!"
  confirm_action "$disk" || return

  echo "Unmounting partitions on $disk..."
  sudo sync
  sudo umount "${disk}"* 2>/dev/null || true

  # Detect device type and wipe accordingly
  if [[ "$disk" =~ (nvme|mmcblk) ]] || [[ $(cat "/sys/block/${disk##*/}/queue/rotational" 2>/dev/null) -eq 0 ]]; then
    echo "SSD detected. Using blkdiscard..."
    sudo blkdiscard -f "$disk" || echo "Warning: blkdiscard not supported."
  else
    echo "HDD detected. Using wipefs..."
    sudo wipefs -a "$disk"
  fi

  echo "Success: Disk $disk has been completely wiped."

  # Optional secondary wipe with dd command
  read -rn1 -p "Wipe again with DD command for extra security? (y/n): " use_dd; echo
  if [[ "$use_dd" =~ ^[Yy]$ ]]; then
    echo "Wiping $disk with DD command (this may take a while)..."
    sudo dd if=/dev/zero of="$disk" bs=4K conv=fdatasync status=progress
    echo "Success: Disk $disk has been completely wiped."
  fi
}

# Partitioning, formatting, grub functions

create_gpt_partitions() {
  local disk=$1

  echo "Unmounting any active partitions on $disk..."
  sudo sync
  sudo umount "${disk}"* 2>/dev/null || true

  echo "Creating GPT label on $disk"
  sudo wipefs -a "$disk"
  sudo parted -s "$disk" mklabel gpt

  echo "Creating BIOS partition (4MiB-8MiB) for bios_grub"
  sudo parted -s "$disk" mkpart bios 4MiB 8MiB
  sudo parted -s "$disk" set 1 bios_grub on

  echo "Creating EFI partition (8MiB-1008MiB) FAT32"
  sudo parted -s "$disk" mkpart efi fat32 8MiB 1008MiB

  echo "Creating Linux partition (1008MiB to 103459MiB) f2fs"
  sudo parted -s "$disk" mkpart f2fs f2fs 1008MiB 103459MiB

  echo "Creating Linux partition (103459MiB to 100%) ext4"
  sudo parted -s "$disk" mkpart ext4 ext4 103459MiB 100%

  echo "Refreshing partition table state..."
  rescan_and_settle "$disk"

  local p1 p2 p3 p4
  p1=$(get_part_name "$disk" 1)
  p2=$(get_part_name "$disk" 2)
  p3=$(get_part_name "$disk" 3)
  p4=$(get_part_name "$disk" 4)

  # Wait for partition nodes
  wait_for_part "$p1" 10 || true
  wait_for_part "$p2" 10 || true
  wait_for_part "$p3" 10 || true
  wait_for_part "$p4" 10 || true

  echo "Formatting partitions: $p2, $p3, $p4"
  sudo umount "$p2" 2>/dev/null || true
  sudo mkfs.vfat -F 32 -a -I "$p2"
  sudo sync
  sudo partprobe "$disk" || true
  sudo udevadm settle || true

  sudo umount "$p3" 2>/dev/null || true
  sudo umount "$p4" 2>/dev/null || true
  #sudo mkfs.btrfs -fv -s 4K -n 32K -O no-holes "$p3" || die "mkfs.btrfs failed on $p3"
  #sudo mkfs.xfs -f -s size=4096 -b size=4096 -n size=64k -l size=64m,lazy-count=1 "$p3" || die "mkfs.xfs failed on $p3"
  sudo mkfs.f2fs -f -a 1 -o 1 -O extra_attr,flexible_inline_xattr,inode_checksum,sb_checksum "$p3" || die "mkfs.f2fs failed on $p3"
  sudo mkfs.ext4 -F -b 4096 -m 0 -O "has_journal,sparse_super,dir_index" "$p4" || die "mkfs.ext4 failed on $p4"

  echo "Refreshing partition table state..."
  rescan_and_settle "$disk"

  echo "Partitions created and formatted."
  echo "Partitions on $disk:"
  sudo parted -s "$disk" print
}

create_mbr_partitions() {
  local disk=$1

  echo "Unmounting any active partitions on $disk..."
  sudo sync
  sudo umount "${disk}"* 2>/dev/null || true

  echo "Creating MBR (msdos) label on $disk"
  sudo wipefs -a "$disk"
  sudo parted -s "$disk" mklabel msdos

  echo "Creating Boot partition (8MiB-1008MiB) FAT32"
  sudo parted -s "$disk" mkpart primary fat32 8MiB 1008MiB
  
  echo "Setting boot flag on partition 1"
  sudo parted -s "$disk" set 1 boot on

  echo "Creating Linux partition (1008MiB to 100%) ext4"
  sudo parted -s "$disk" mkpart primary ext4 1008MiB 100%

  echo "Refreshing partition table state..."
  rescan_and_settle "$disk"

  local p1 p2
  p1=$(get_part_name "$disk" 1)
  p2=$(get_part_name "$disk" 2)

  wait_for_part "$p1" 10 || true
  wait_for_part "$p2" 10 || true

  echo "Formatting $p1 as FAT32"
  sudo umount "$p1" 2>/dev/null || true
  sudo mkfs.vfat -F 32 -a -s 8 -I "$p1"
  
  echo "Formatting $p2"
  sudo umount "$p2" 2>/dev/null || true
  #sudo mkfs.btrfs -fv -s 4K -n 16K -O no-holes "$p2" || die "mkfs.btrfs failed on $p2"
  #sudo mkfs.f2fs -f -a 1 -o 10 -O extra_attr,flexible_inline_xattr,inode_checksum,sb_checksum "$p2" || die "mkfs.f2fs failed on $p2"
  sudo mkfs.ext4 -F -b 4096 -m 0 -E stride=2,stripe-width=2 -O "^has_journal,sparse_super,dir_index" "$p2" || die "mkfs.ext4 failed on $p2"
  #sudo mkfs.xfs -f -s size=4096 -b size=4096 -d agcount=2 -m reflink=0 -n size=64k -l size=64m,lazy-count=1 "$p2" || die "mkfs.xfs failed on $p2"

  echo "Refreshing partition table state..."
  rescan_and_settle "$disk"

  echo "Partitions created and formatted successfully."
  echo "Final Partition Layout on $disk:"
  sudo parted -s "$disk" print
}

mount_efi() {
  local part=$(get_part_name "$1" "$2")

  [[ -b "$part" ]] || die "EFI partition $part does not exist."

  sudo mkdir -p "$3"
  sudo umount "$part" 2>/dev/null || true
  sudo mount "$part" "$3" && echo "Mounted $part -> $3"
}

install_grub() {
  local disk=$1
  local efi_mount=$2

  rescan_and_settle "$disk"

  if [[ ! -d "$efi_mount" ]]; then die "EFI mountpoint $efi_mount not found"; fi

  echo "Installing GRUB (UEFI x86_64) to $efi_mount"
  sudo grub-install --target=x86_64-efi --efi-directory="$efi_mount" --boot-directory="$efi_mount/efi" --removable || echo "UEFI grub-install returned non-zero"

  echo "Installing GRUB (BIOS i386-pc) to $disk"
  sudo grub-install --target=i386-pc "$disk" --boot-directory="$efi_mount/efi" --removable --recheck --force || echo "BIOS grub-install returned non-zero"

  echo "Unmounting any active partitions on $disk..."
  sudo sync
  sudo umount "${disk}"* 2>/dev/null || true
  echo "GRUB installation attempted. Verify success messages above."
}

create_gpt_disk() {
  list_disks
  read -rp "Enter target disk (e.g., sdb or /dev/sdb): " disk_in
  disk=$(normalize_device "$disk_in")
  confirm_action "$disk" || return
  create_gpt_partitions "$disk"

  local efnum=2
  sep=$(get_part_sep "$disk")
  read -rp "Enter mount point for EFI (default /mnt/${disk##*/}${sep}${efnum}): " mountp
  if [[ -z "$mountp" ]]; then
    mountp="/mnt/${disk##*/}${sep}${efnum}"
    echo "Using default: $mountp"
  fi

  part=$(get_part_name "$disk" "$efnum")
  wait_for_part "$part" 15 || echo "Proceeding even though $part may not exist yet"

  mount_efi "$disk" "$efnum" "$mountp"
  install_grub "$disk" "$mountp"
  echo "Done creating GPT disk and installing GRUB."
}

create_mbr_disk() {
  list_disks
  read -rp "Enter target disk (e.g., sdb or /dev/sdb): " disk_in
  disk=$(normalize_device "$disk_in")
  confirm_action "$disk" || return
  
  create_mbr_partitions "$disk"

  local efnum=1
  sep=$(get_part_sep "$disk")
  read -rp "Enter mount point for Boot/EFI (default /mnt/${disk##*/}${sep}${efnum}): " mountp
  if [[ -z "$mountp" ]]; then
    mountp="/mnt/${disk##*/}${sep}${efnum}"
    echo "Using default: $mountp"
  fi

  part=$(get_part_name "$disk" "$efnum")
  wait_for_part "$part" 15 || echo "Proceeding even though $part may not exist yet"

  sudo mkdir -p "$mountp"
  sudo mount "$part" "$mountp" || die "Failed to mount $part to $mountp"

  install_grub "$disk" "$mountp"

  echo "Done creating MBR disk and installing Hybrid GRUB (BIOS + UEFI)."
}

install_grub_only() {
  list_disks
  read -rp "Enter disk (e.g., sdb or /dev/sdb) where EFI partition resides: " disk_in
  disk=$(normalize_device "$disk_in")

  echo "Current partitions on $disk:"
  sudo parted -s "$disk" print

  read -rp "Enter EFI partition number to mount (e.g., 2): " efnum

  sep=$(get_part_sep "$disk")
  mountp="/mnt/${disk##*/}${sep}${efnum}"

  part=$(get_part_name "$disk" "$efnum")
  wait_for_part "$part" 15 || echo "Proceeding even though $part may not exist yet"

  mount_efi "$disk" "$efnum" "$mountp"
  install_grub "$disk" "$mountp"

  echo "GRUB-only installation attempted."
}

show_disk_details() {
  list_disks
  read -rp "Enter disk to inspect (e.g., sdb or /dev/sdb) or ENTER to skip: " disk_in || true
  if [[ -n "${disk_in:-}" ]]; then
    disk=$(normalize_device "$disk_in")
    echo
    echo "parted print for $disk:"
    sudo parted -s "$disk" print

    echo
    echo "blkid output:"
    sudo blkid "${disk}"* || true

    echo
    echo "Detailed lsblk:"
    lsblk -a -p -o NAME,TYPE,FSTYPE,SIZE,MOUNTPOINT,LABEL,UUID "$disk" || true
  fi
}

main() {
  while true; do
    echo
    echo "App Need: grub-pc grub-efi-amd64-bin parted"
    echo "Main Menu:"
    echo "1) Flash Linux image (to entire device)"
    echo "2) Flash Windows image (to partition)"
    echo "3) Create GPT disk (partitions, format, install GRUB)"
    echo "4) Create MBR disk (partitions, format, install GRUB)"
    echo "5) Wipe disk completely (wipefs + dd zero-fill)"
    echo "6) Show disk details"
    echo "7) Install GRUB only to existing EFI partition"
    echo "q) Quit"
    read -rp "Choose an option: " choice

    case "$choice" in
      1)
        list_disks
        read -rp "Enter target device (e.g., sdb or /dev/sdb): " t
        target=$(normalize_device "$t")
        confirm_action "$target" || return
        run_partitioner "gparted $target"
        ls
        read -rp "Enter Linux image path (.img or .xz): " img
        flash_image "$img" "$target"
        rescan_and_settle "$target"
        run_partitioner "gparted $target"
        ;;
      2)
        list_disks
        read -rp "Enter target device for partitioning (e.g., sdb or /dev/sdb): " t
        target=$(normalize_device "$t")
        confirm_action "$target" || return
        run_partitioner "gparted $target"
        list_disks
        read -rp "Enter partition to flash (e.g., sdb1 or /dev/sdb1): " p
        part=$(normalize_device "$p")
        confirm_action "$part" || return
        ls
        read -rp "Enter Windows image path (.img or .xz): " img
        flash_image "$img" "$part"
        rescan_and_settle "${part%[0-9]*}" || true
        run_partitioner "gparted $target"
        run_partitioner "gnome-disks"
        run_partitioner "gparted $target"
        sudo sync
        ;;
      3)
        create_gpt_disk
        ;;
      4)
        create_mbr_disk
        ;;
      5)
        wipe_disk_completely
        ;;
      6)
        show_disk_details
        ;;
      7)
        install_grub_only
        ;;
      q|Q)
        echo "Exiting."
        exit 0
        ;;
      *)
        echo "Invalid choice."
        ;;
    esac
  done
}

main
