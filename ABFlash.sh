#!/bin/bash

set -e

echo "==== Flash Image Using DD Script ===="

# Function to list available devices
list_devices() {
    echo ""
    echo "Available target devices:"
    lsblk -a -p -o NAME,TRAN,SIZE,MODEL | grep -v "loop"
}

# Function to confirm action
confirm_action() {
    local target=$1
    echo "You selected: $target."
    echo "Are you sure you want to write to this device?"
    read -rp "THIS WILL ERASE ALL DATA! (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        echo "Aborted."
        exit 1
    fi
}

# Function to check if image file exists
check_image_exists() {
    local image=$1
    if [[ ! -f "$image" ]]; then
        echo "Error: File '$image' does not exist."
        exit 1
    fi
}

# Flash image function
flash_image() {
    local image=$1
    local target=$2
    if [[ "$image" == *.xz ]]; then
        echo "Flashing compressed image using xzcat..."
        sudo xzcat "$image" | sudo dd of="$target" bs=4M status=progress conv=fsync
    elif [[ "$image" == *.img ]]; then
        echo "Flashing raw image using dd..."
        sudo dd if="$image" of="$target" bs=4M status=progress conv=fsync
    else
        echo "Unsupported file type. Please provide a .img or .xz file."
        exit 1
    fi
}

# Main function
main() {
    list_devices

    # Prompt user for target device
    read -rp "Enter the device path to flash to (e.g., sdb, sdc or sdX): " target
    confirm_action "/dev/$target"

    # Setup partition
    echo "==== Clear Drive or Unmount Partitions First ===="
    sudo gparted "/dev/$target"

    # Ask user for the image file
    read -rp "Enter the image file name to flash (.img or .xz): " image
    check_image_exists "$image"

    flash_image "$image" "/dev/$target"
    sudo sync
    echo "Flashing completed!"

    # Wait before continuing
    read -p "Press Enter to Continue or Press Ctrl + C to Exit... : " wait
    clear

    list_devices

    # Prompt user for target device
    read -rp "Enter the device path to flash to (e.g., sdb, sdc or sdX): " target
    confirm_action "/dev/$target"

    # Setup partition
    echo "==== Clear Drive or Unmount Partitions First ===="
    echo "==== If Using Windows Image Must Creat FAT32 Partition ===="
    sudo gparted "/dev/$target"

    list_devices

    # Ask user for the second target device (partition)
    read -rp "Enter the partition to flash to (e.g., sdb3, sdc4 or sdXX): " part2flash
    confirm_action "/dev/$part2flash"

    # Flash the second partition
    read -rp "Enter the image file name to flash (.img or .xz): " image
    check_image_exists "$image"

    flash_image "$image" "/dev/$part2flash"
    sudo sync
    echo "Flashing completed!"

    # Resize and check Windows partition
    echo "Resize and Checking Windows Partition : $part2flash"
    sudo ntfsresize -i -f -v /dev/"$part2flash"

    # Repair and Check Windows partition
    echo "Checking Windows Partition : $part2flash"
    sudo gnome-disks

    # Force resize (without action) and update partition label
    sudo ntfsresize --force --force --no-action /dev/"$part2flash"
    sudo ntfsresize --force --force /dev/"$part2flash"
    sudo ntfslabel --new-half-serial /dev/"$part2flash"
    sudo sync

    # Final checks
    echo "Checking Windows Partition : $part2flash"
    sudo ntfsresize -i -f -v /dev/"$part2flash"
    sudo ntfsresize --force --force --no-action /dev/"$part2flash"
    sudo ntfsresize --force --force /dev/"$part2flash"
    sudo sync

    echo "Done... Please re-check the partition and mount if necessary."
}

# Run the script with retries in case of error
retry_count=0
while true; do
    main
    if [ $? -eq 0 ]; then
        break
    else
        ((retry_count++))
        if [ "$retry_count" -ge 2 ]; then
            echo "Script failed after 2 attempts."
            exit 1
        fi
        echo "Error encountered, retrying ($retry_count/2)..."
        sleep 3
    fi
done
