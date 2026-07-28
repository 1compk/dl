#!/bin/bash
set -e

# Configuration
SourceDiR="${SourceDiR:-.}"
LIVEKITNAME="minios"
ISO="../MiniOS-Rebuild-$(date +%H%M%S.%d%m%Y).iso"
PERCHIMG="resizeme.img"

trap "rm -f '$PERCHIMG'" EXIT

# Create persistence image
dd if=/dev/zero of="$PERCHIMG" bs=1k count=128
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
  -append_partition 2 0x83 "$PERCHIMG" \
  -appended_part_as_gpt \
  -iso_mbr_part_type 0xee \
  -partition_cyl_align off -partition_offset 16 \
  -output "$ISO" "$SourceDiR"

echo "ISO created: $ISO"
