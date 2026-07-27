#!/bin/bash

CurrentTime=$(date +"%H%M.%d%m%Y")
DefaultName="MiniOS.Rebuild.${CurrentTime}.iso"

# Get output filename from user
#read -p "Enter ISO output filename: " iSOName

# Set default name if input is empty
if [ -z "$iSOName" ]; then
    iSOName="$DefaultName"
fi

# Append .iso extension if missing
if [[ ! "$iSOName" =~ \.iso$ ]]; then
    iSOName="${iSOName}.iso"
fi

echo "Building $iSOName..."

# Run xorriso
xorriso \
    --as mkisofs \
    -iso-level 3 \
    -volid "MiniOS" \
    -A "MiniOS" \
    -joliet -joliet-long -rational-rock \
    -eltorito-boot "minios/boot/grub/i386-pc/eltorito.img" \
    -eltorito-catalog "minios/boot/grub/boot.cat" \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-alt-boot \
    -e "minios/boot/grub/efi64.img" \
    -no-emul-boot \
    -eltorito-alt-boot \
    -e "minios/boot/grub/efi32.img" \
    -no-emul-boot \
    --isohybrid-mbr "minios/boot/grub/i386-pc/boot_hybrid.img" \
    -append_partition 2 0x83 "resizeme.img" \
    -partition_cyl_align on \
    -partition_offset 16 \
    -part_like_isohybrid \
    -graft-points /=. \
    -output "$iSOName"

echo "Done!"
