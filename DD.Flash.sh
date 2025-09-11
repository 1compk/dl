#!/bin/bash

set -e

echo "==== Image Flashing Utility ===="

# Displays available block devices
list_devices() {
    echo "Listing available devices..."
    echo ""
    echo "Available target devices:"
    lsblk -a -p -o NAME,TRAN,SIZE,MODEL | grep -v "loop"
    echo ""
}

# Confirms critical actions with the user
confirm_action() {
    local target_path=$1
    echo "You've selected: $target_path."
    echo "Are you absolutely sure you want to proceed?"
    read -rp "THIS WILL ERASE ALL DATA ON THE TARGET! (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        echo "Action aborted by user."
        echo "Aborted."
        exit 1
    fi
}

# Checks if the provided image file exists
check_image_exists() {
    local image=$1
    if [[ ! -f "$image" ]]; then
        echo "Error: Image file '$image' not found."
        echo "Error: File '$image' does not exist. Please check the path and filename."
        exit 1
    fi
}

# Validates the user's device/partition input
validate_device_input() {
    local input=$1
    #if [[ ! "$input" =~ ^sd[a-z]+([0-9]+)?$ ]]; then
        #echo "Invalid device/partition input: $input"
        #echo "Error: Invalid device or partition format. Please enter 'sdb', 'sdb4', etc."
        #exit 1
    #fi
    # Ensure the full path is used internally
    echo "/dev/$input"
}

# Performs the image flashing operation
flash_image() {
    local image=$1
    local target_device=$2
    echo "Starting image flash: '$image' to '$target_device'"

    if [[ "$image" == *.xz ]]; then
        #echo "Flashing compressed image using xzcat..."
        #sudo xzcat "$image" | sudo dd of="$target_device" bs=3M status=progress conv=fsync 2>&1
        echo "Flashing compressed image using 7zip..."
        sudo 7z x -so "$image" | sudo dd of="$target_device" bs=3M status=progress conv=fsync 2>&1
    elif [[ "$image" == *.img ]]; then
        echo "Flashing raw image using dd..."
        sudo dd if="$image" of="$target_device" bs=3M status=progress conv=fsync 2>&1
    else
        echo "Unsupported image file type: $image"
        echo "Error: Unsupported file type. Please provide a .img or .xz file."
        exit 1
    fi
    sudo sync
    echo "Image flashing completed successfully."
    echo "Flashing completed!"
}

# --- Main Script Logic ---

main() {
    list_devices

    echo "Please choose an action:"
    echo "1. Flash Linux Image (to entire device)"
    echo "2. Flash Windows Image (to a partition)"
    read -rp "Enter your choice (1 or 2): " choice

    local target_input=""
    local target_path=""
    local image_file=""

    case "$choice" in
        1) # Flash Linux Image
            read -rp "Enter the target device (e.g., sdb, sdc): " target_input
            target_path=$(validate_device_input "$target_input")
            confirm_action "$target_path"

            echo "Launching GParted for device setup: $target_path"
            echo "==== Please use GParted to clear the drive and Unmount necessary partitions. ===="
            echo "Once done, close GParted to continue."
            sudo gparted "$target_path"
            echo "GParted session for device setup completed."

            read -rp "Enter the Linux image file name (.img or .xz): " image_file
            check_image_exists "$image_file"

            flash_image "$image_file" "$target_path"
            echo "Linux image flashing process finished."
            echo "Linux image flashing completed!"

            echo "Launching GParted for device setup: $target_path"
            echo "==== Please use GParted to check the drive and Unmount necessary partitions. ===="
            echo "Once done, close GParted to continue."
            sudo gparted "$target_path"
            echo "GParted session for device setup completed."
            ;;

        2) # Flash Windows Image
            read -rp "Enter the target device (e.g., sdb, sdc) for GParted: " target_input
            target_path=$(validate_device_input "$target_input")
            confirm_action "$target_path"

            echo "Launching GParted for Windows partition setup: $target_path"
            echo "==== Important: Use GParted to create a FAT32 partition for Windows. ===="
            echo "Once done, close GParted to continue."
            sudo gparted "$target_path"
            echo "GParted session for Windows partition setup completed."

            list_devices # List devices again to show new partitions

            read -rp "Enter the specific partition to flash the Windows image to (e.g., sdb1, sdc4): " part_input
            local part_path=$(validate_device_input "$part_input")
            confirm_action "$part_path"

            read -rp "Enter the Windows image file name (.img or .xz): " image_file
            check_image_exists "$image_file"

            flash_image "$image_file" "$part_path"
            
            echo "Launching Gnome Disks for Windows partition repair: $part_path"
            echo "==== Please use Gnome Disks to repair the Windows partition ($part_path). ===="
            echo "After repairing, you can close Gnome Disks to continue with resizing and UUID changes."
            sudo gnome-disks
            echo "Gnome Disks session completed."

            echo "Resizing and updating Windows partition: $part_path"
            echo "Resizing and checking Windows Partition: $part_path"
            # Attempt to unmount the partition if it's mounted
            if mount | grep -q "$part_path"; then
                echo "Attempting to unmount $part_path before resize."
                sudo umount "$part_path" || echo "Warning: Could not unmount $part_path. Proceeding anyway, but issues might occur."
            fi

            # Check and then resize
            echo "Running ntfsresize checks and resize on $part_path"
            sudo ntfsresize -i -f -v "$part_path" 2>&1
            sudo ntfsresize --force --force "$part_path" 2>&1
            sudo ntfslabel --new-half-serial "$part_path" 2>&1
            sudo sync
            echo "Windows partition resize and UUID update completed."

            echo "Windows image flashing and post-processing completed!"
            ;;

        *)
            echo "Invalid choice: $choice"
            echo "Invalid choice. Please enter 1 or 2."
            exit 1
            ;;
    esac

    echo "Script execution completed successfully."
    echo "Done! Please re-check the partition and mount if necessary."
}

# Run the main function. No automatic retries, as user interaction is high.
main
