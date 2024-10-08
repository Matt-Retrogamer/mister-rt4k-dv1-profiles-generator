#!/bin/bash

# Usage: ./update_kurohouou_profiles.sh /path/to/SD_Card /path/to/update.zip

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 /path/to/SD_Card /path/to/update.zip"
    exit 1
fi

SD_CARD_PATH="$1"
ZIP_FILE="$2"

# Step 3.1: Delete banners in the image folder
echo "Deleting banners in the 'image' folder..."
find "$SD_CARD_PATH/image" -type f -iname '*Kuro Houou*.bmp' -exec rm -f {} +

# Step 3.2: Delete the listed profile folders
echo "Deleting specified profile folders..."
find "$SD_CARD_PATH/profile/_CRT Emulation" -type d -iname '*Kuro Houou*' -exec rm -rf {} +

# Step 3.3: Copy 'image' folder from the zip file to the SD card root
echo "Copying 'image' folder from the zip file to the SD card root..."
unzip -o "$ZIP_FILE" "image/*" -d "$SD_CARD_PATH"

# Step 3.3: Copy 'profile' folder contents to the target directory
echo "Copying 'profile' folder contents from the zip file to '$SD_CARD_PATH/profile/_CRT Emulation'..."
TEMP_DIR=$(mktemp -d)
unzip -o "$ZIP_FILE" "profile/*" -d "$TEMP_DIR"
mkdir -p "$SD_CARD_PATH/profile/_CRT Emulation"
mv "$TEMP_DIR/profile/"* "$SD_CARD_PATH/profile/_CRT Emulation/"
rm -rf "$TEMP_DIR"

echo "Update completed successfully."