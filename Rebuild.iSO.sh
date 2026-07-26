#!/bin/bash

clear
echo "=================================================="
echo "    ISO Boot Repair Tool using xorriso"
echo "=================================================="
echo ""

# 1. List available .iso files in the current directory
echo "[+] Available ISO files in this directory:"
echo "--------------------------------------------------"
ls -1 *.iso 2>/dev/null || echo "(No .iso files found in this directory. You can type full path manually.)"
echo "--------------------------------------------------"
echo ""

# 2. Get Source ISO (Original Bootable ISO)
while true; do
    read -p " Enter Source ISO path (Original Bootable): " SourceISO
    if [ -f "$SourceISO" ]; then
        break
    else
        echo "[-] Error: File '$SourceISO' not found. Please try again."
    fi
done

# 3. Get Edited ISO (Modified via ISO Master)
while true; do
    read -p " Enter Edited ISO path (Modified Content): " EditISO
    if [ -f "$EditISO" ]; then
        # Check if Edited ISO is the same as Source ISO
        if [ "$SourceISO" == "$EditISO" ]; then
            echo "[!] Warning: Edited ISO should not be the same as Source ISO."
            continue
        fi
        break
    else
        echo "[-] Error: File '$EditISO' not found. Please try again."
    fi
done

# --- [ บรรทัดที่แก้ไขใหม่เพื่อดึงวันที่ปัจจุบัน ] ---
CURRENT_DATE=$(date +"%d.%m.%Y")
DIR_PATH=$(dirname "$EditISO")
FILE_NAME=$(basename "$EditISO" .iso)

# ผลลัพธ์จะได้ชื่อไฟล์เป็น: ชื่อไฟล์เดิม-26.07.2026.iso
FinalISO="${DIR_PATH}/${FILE_NAME}-${CURRENT_DATE}.iso"
# --------------------------------------------------

# 4. Process Confirmation Summary
clear
echo "=================================================="
echo "          PROCESS CONFIRMATION SUMMARY"
echo "=================================================="
echo "Source ISO (Extracting Boot Sector):"
echo "   -> $SourceISO"
echo ""
echo "Edited ISO (Using Modded Content):"
echo "   -> $EditISO"
echo ""
echo "Final Output ISO (Bootable Result):"
echo "   -> $FinalISO"
echo "=================================================="
echo ""

# Ask for confirmation before execution
read -p "[?] Do you want to start the repair process? (y/n): " confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo ""
    echo "[*] Injecting bootloader and compiling new ISO via xorriso..."
    
    # Execute xorriso command
    xorriso -indev "$SourceISO" \
            -dev "$EditISO" \
            -outdev "$FinalISO" \
            -boot_image any keep
            
    if [ $? -eq 0 ]; then
        echo ""
        echo "--------------------------------------------------"
        echo "[+] ISO Boot Repair Successful!"
        echo "[+] Fixed ISO saved at: $FinalISO"
        echo "--------------------------------------------------"
    else
        echo ""
        echo "[-] Error: Something went wrong during xorriso execution."
    fi
else
    echo ""
    echo "[-] Process cancelled by user."
fi
