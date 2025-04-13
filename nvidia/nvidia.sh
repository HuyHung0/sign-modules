#!/bin/bash

# Directory where the DER file is located
DER_DIR="/usr/share/nvidia"
# Pattern for the file; adjust if needed
PATTERN="nvidia-modsign-crt-*.der"

# Find the DER file(s) that match the pattern
files=("$DER_DIR"/$PATTERN)

# Check if no file is found
if [ ${#files[@]} -eq 0 ]; then
    echo "No matching DER file found in $DER_DIR."
    exit 1
fi

# Check if multiple files are found
if [ ${#files[@]} -gt 1 ]; then
    echo "Multiple DER files found in $DER_DIR. Please ensure only one is present."
    echo "Files found:"
    for file in "${files[@]}"; do
        echo " - $file"
    done
    exit 1
fi

# Only one file was found. Use it.
key_file=${files[0]}
echo "DER file found: $key_file"

# Prompt user for confirmation
read -p "Do you want to import this key? (y/n): " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    sudo mokutil --import "$key_file"
    echo "Key import initiated. Now reboot your system."
else
    echo "Operation cancelled."
fi
