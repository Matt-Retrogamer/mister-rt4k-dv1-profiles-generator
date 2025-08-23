#!/usr/bin/env bash

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

# Step 3.2: Delete the listed profile folders (both old and new locations)
echo "Deleting specified profile folders..."
find "$SD_CARD_PATH/profile/_CRT Emulation" -type d -iname '*Kuro Houou*' -exec rm -rf {} + 2>/dev/null || true
find "$SD_CARD_PATH/profile" -type d -iname '*CRT TV and PVM Emulation by Kuro Houou*' -exec rm -rf {} + 2>/dev/null || true

# Step 3.3: Copy 'image' folder from the zip file to the SD card root
echo "Copying 'image' folder from the zip file to the SD card root..."
unzip -o "$ZIP_FILE" "image/*" -d "$SD_CARD_PATH"

# Step 3.3: Copy 'profile' folder contents to the target directory
echo "Copying 'profile' folder contents from the zip file to '$SD_CARD_PATH/profile/'..."
TEMP_DIR=$(mktemp -d)
unzip -o "$ZIP_FILE" "profile/*" -d "$TEMP_DIR"
find "$TEMP_DIR" -exec chmod u+w "{}" \;
mkdir -p "$SD_CARD_PATH/profile"
mv "$TEMP_DIR/profile/"* "$SD_CARD_PATH/profile/"
rm -rf "$TEMP_DIR"

echo "Update completed successfully."