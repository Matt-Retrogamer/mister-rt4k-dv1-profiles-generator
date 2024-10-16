#!/usr/bin/env bash

# Usage: ./update_wobling_profiles.sh /path/to/SD_Card /path/to/update.zip

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 /path/to/SD_Card /path/to/update.zip"
    exit 1
fi

SD_CARD_PATH="$1"
ZIP_FILE="$2"

# Step 3.1: Delete banners in the image folder
echo "Deleting banners in the 'image' folder..."
find "$SD_CARD_PATH/image" -type f -iname '*Wobbling Pixels*.bmp' -exec rm -f {} +

# Step 3.2: Delete the listed profile folders
echo "Deleting specified profile folders..."
find "$SD_CARD_PATH/profile" -type d -iname '*Wobbling Pixels*' -exec rm -rf {} +

# Step 3.3: Copy 'image', 'mask', and 'profile' folders from the zip file to the SD card root
echo "Copying 'image', 'mask', and 'profile' folders from the zip file to the SD card root..."
unzip -o "$ZIP_FILE" "image/*" "mask/*" "profile/*" -d "$SD_CARD_PATH"

echo "Update completed successfully."