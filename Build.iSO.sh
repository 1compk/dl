#!/bin/bash
set -e

# Configuration
LIVEKITNAME="minios"
PERCHIMG="resizeme.img"
SourceDiR="${SourceDiR:-.}"
ISO="../Rebuild-$(basename "$PWD").iso"

# Create persistence image
sudo dd if=/dev/zero of="$PERCHIMG" bs=1k count=0 seek=128
sudo mkfs.ext2 -F -b 1024 -L resizeme "$PERCHIMG"

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
sync