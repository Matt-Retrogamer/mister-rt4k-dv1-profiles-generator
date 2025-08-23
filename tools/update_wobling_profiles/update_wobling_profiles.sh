#!/usr/bin/env bash

# Usage: ./update_wobling_profiles.sh /path/to/SD_Card /path/to/update.zip [PRO|CE] [NTSC|PAL|BOTH]
# Examples:
#   ./update_wobling_profiles.sh /media/rt4k/ wobbling_profiles.zip
#   ./update_wobling_profiles.sh /media/rt4k/ wobbling_profiles.zip PRO NTSC
#   ./update_wobling_profiles.sh /media/rt4k/ wobbling_profiles.zip CE BOTH

if [ "$#" -lt 2 ] || [ "$#" -gt 4 ]; then
    echo "Usage: $0 /path/to/SD_Card /path/to/update.zip [PRO|CE] [NTSC|PAL|BOTH]"
    echo "Examples:"
    echo "  $0 /media/rt4k/ wobbling_profiles.zip"
    echo "  $0 /media/rt4k/ wobbling_profiles.zip PRO NTSC"
    echo "  $0 /media/rt4k/ wobbling_profiles.zip CE BOTH"
    echo ""
    echo "Default: PRO BOTH"
    exit 1
fi

SD_CARD_PATH="$1"
ZIP_FILE="$2"
RT4K_TYPE="${3:-PRO}"  # Default to PRO
REGION="${4:-BOTH}"    # Default to BOTH

# Validate parameters
if [[ "$RT4K_TYPE" != "PRO" && "$RT4K_TYPE" != "CE" ]]; then
    echo "Error: RT4K type must be PRO or CE"
    exit 1
fi

if [[ "$REGION" != "NTSC" && "$REGION" != "PAL" && "$REGION" != "BOTH" ]]; then
    echo "Error: Region must be NTSC, PAL, or BOTH"
    exit 1
fi

echo "Installing Wobbling Pixels profiles for RT4K $RT4K_TYPE, region: $REGION"

# Step 3.1: Delete banners in the image folder
echo "Deleting banners in the 'image' folder..."
find "$SD_CARD_PATH/image" -type f -iname '*Wobbling Pixels*.bmp' -exec rm -f {} +

# Step 3.2: Delete the listed profile folders
echo "Deleting specified profile folders..."
find "$SD_CARD_PATH/profile" -type d -iname '*Wobbling Pixels*' -exec rm -rf {} +

# Step 3.3: Extract and install profiles based on selection
TEMP_DIR=$(mktemp -d)
echo "Extracting archive to temporary directory..."
unzip -q "$ZIP_FILE" -d "$TEMP_DIR"

# Function to copy profiles from a specific folder
copy_profiles() {
    local source_folder="$1"
    local folder_name="$2"
    
    if [ -d "$source_folder" ]; then
        echo "Installing $folder_name profiles..."
        
        # Copy image files if they exist
        if [ -d "$source_folder/image" ]; then
            cp -r "$source_folder/image/"* "$SD_CARD_PATH/image/" 2>/dev/null || true
        fi
        
        # Copy mask files if they exist
        if [ -d "$source_folder/mask" ]; then
            mkdir -p "$SD_CARD_PATH/mask"
            cp -r "$source_folder/mask/"* "$SD_CARD_PATH/mask/" 2>/dev/null || true
        fi
        
        # Copy profile files if they exist
        if [ -d "$source_folder/profile" ]; then
            mkdir -p "$SD_CARD_PATH/profile"
            cp -r "$source_folder/profile/"* "$SD_CARD_PATH/profile/" 2>/dev/null || true
        fi
    else
        echo "Warning: $folder_name folder not found in archive"
    fi
}

# Install based on selection
if [ "$REGION" = "NTSC" ] || [ "$REGION" = "BOTH" ]; then
    copy_profiles "$TEMP_DIR/Retrotink 4K $RT4K_TYPE NTSC Profiles" "RT4K $RT4K_TYPE NTSC"
fi

if [ "$REGION" = "PAL" ] || [ "$REGION" = "BOTH" ]; then
    copy_profiles "$TEMP_DIR/Retrotink 4K $RT4K_TYPE PAL Profiles" "RT4K $RT4K_TYPE PAL"
fi

# Clean up
rm -rf "$TEMP_DIR"

echo "Update completed successfully."