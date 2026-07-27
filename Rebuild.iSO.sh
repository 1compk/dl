#!/bin/bash
set -e

# Get inputs from user
ls -1
read -p "Enter source directory (default: Current Location): " SourceDiR
SourceDiR="${SourceDiR:-.}"

read -p "Enter output ISO directory (default: Parent of SourceDir): " iSODiR

# Validate and resolve source directory
if [[ ! -d "$SourceDiR" ]]; then
    echo "Error: Source directory '$SourceDiR' not found"
    exit 1
fi
SourceDiR="$(cd "$SourceDiR" && pwd)"

# Set ISO path with default to parent directory
LIVEKITNAME="minios"
PERCHIMG="resizeme.img"
iSODiR="${iSODiR:-$(dirname "$SourceDiR")}"

# Validate and resolve ISO directory
if [[ ! -d "$iSODiR" ]]; then
    echo "Error: ISO directory '$iSODiR' not found"
    exit 1
fi
iSODiR="$(cd "$iSODiR" && pwd)"

ISO="${iSODiR}/MiniOS-Build-$(date +%H%M.%d%m%Y).iso"

trap "rm -f '$PERCHIMG'" EXIT

echo "Building ISO from: $SourceDiR"
echo "Output file: $ISO"

# Create persistence image
dd if=/dev/zero of="$PERCHIMG" bs=1 count=0 seek=128k
sudo mkfs.ext2 -b 1024 -L resizeme "$PERCHIMG"

# Create ISO
xorriso --as mkisofs \
  -iso-level 3 -volid "MiniOS" -A "MiniOS" \
  -joliet -joliet-long -rational-rock \
  -eltorito-boot "${LIVEKITNAME}/boot/grub/i386-pc/eltorito.img" \
  -eltorito-catalog "${LIVEKITNAME}/boot/grub/boot.cat" \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e "${LIVEKITNAME}/boot/grub/efi64.img" -no-emul-boot \
  -eltorito-alt-boot -e "${LIVEKITNAME}/boot/grub/efi32.img" -no-emul-boot \
  --isohybrid-mbr "${LIVEKITNAME}/boot/grub/i386-pc/boot_hybrid.img" \
  -isohybrid-gpt-basdat -append_partition 2 0x83 "$PERCHIMG" \
  -partition_cyl_align on -partition_offset 16 -part_like_isohybrid \
  -output "$ISO" "$SourceDiR"

echo "ISO created: $ISO"
