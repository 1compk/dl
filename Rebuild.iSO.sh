#!/bin/bash
# MiniOS ISO Smart Updater (Simple)

set -e

# Check dependencies
if ! command -v xorriso &> /dev/null; then
    echo "Error: xorriso not found. Install libisoburn."
    exit 1
fi

ls -1 *iso
# Get inputs
read -p "Source ISO path: " SOURCE_ISO
[ -f "$SOURCE_ISO" ] || { echo "Error: File not found"; exit 1; }

ls -1
read -p "Update directory path: " UPDATE_DIR
[ -d "$UPDATE_DIR" ] || { echo "Error: Directory not found"; exit 1; }

read -p "File to delete (optional, press Enter to skip): " FILE_TO_DELETE

ls -1 *.iso
CURRENT_DATE=$(date +"%H%M.%d.%m.%Y")
read -p "Output ISO path (default: MiniOS-Patched-${CURRENT_DATE}.iso): " OUTPUT_ISO
OUTPUT_ISO="${OUTPUT_ISO:-MiniOS-Patched-${CURRENT_DATE}.iso}"

# Confirmation
echo ""
echo "Source ISO: $SOURCE_ISO"
echo "Update Dir: $UPDATE_DIR"
[ -n "$FILE_TO_DELETE" ] && echo "Delete: $FILE_TO_DELETE"
echo "Output ISO: $OUTPUT_ISO"
echo ""

read -p "Proceed? (y/n): " confirm
[ "$confirm" = "y" ] || [ "$confirm" = "Y" ] || { echo "Cancelled."; exit 0; }

# Build xorriso command
CMD="xorriso -indev '$SOURCE_ISO'"

if [ -n "$FILE_TO_DELETE" ]; then
    CMD="$CMD -rm '$FILE_TO_DELETE' --"
fi

CMD="$CMD -boot_image any keep -boot_image any partition_offset=16 -outdev '$OUTPUT_ISO' -overwrite on -update_r '$UPDATE_DIR' / -commit"

# Execute
echo ""
echo "Processing ISO..."
eval "$CMD"

if [ -f "$OUTPUT_ISO" ] && [ -s "$OUTPUT_ISO" ]; then
    echo "Success! ISO created: $OUTPUT_ISO"
    ls -lh "$OUTPUT_ISO"
else
    echo "Error: Failed to create ISO"
    exit 1
fi
