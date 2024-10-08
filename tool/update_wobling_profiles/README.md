
# Update Wobbling Pixels Profiles Script

This script automates the process of updating and replacing all the Retrotink 4K profiles created by **Wobbling Pixels** on your Retrotink 4K SD card.

## Usage

```bash
./update_wobbling_profiles.sh /path/to/SD_Card /path/to/Wobbling_Pixels_Update.zip
```

- Replace `/path/to/SD_Card` with the path to your Retrotink 4K SD card’s root directory.
- Replace `/path/to/Wobbling_Pixels_Update.zip` with the path to the Wobbling Pixels update zip file.

## Instructions

1. **Download the script** and place it on your computer.
2. **Make the script executable**:
   ```bash
   chmod +x update_wobbling_profiles.sh
   ```
3. **Insert your Retrotink 4K SD card** into your computer and note its mount point.
4. **Run the script**:
   ```bash
   ./update_wobbling_profiles.sh /path/to/SD_Card /path/to/Wobbling_Pixels_Update.zip
   ```
5. Wait for the script to complete, then **safely eject your SD card**.

## What the Script Does

- Deletes old Wobbling Pixels banner files in the image folder.
- Removes outdated Wobbling Pixels profile folders in the profile directory.
- Copies new image, mask, and profile folders from the update zip file to the root of your SD card.

## Notes

- **Backup your SD card** before running the script.
- Ensure you have the necessary permissions to read and write to the SD card and the update zip file.
- The script requires **bash**, **find**, and **unzip** to be installed on your system.

## Example

If your SD card is mounted at `/media/user/RETROTINK` and your update zip file is located at `/home/user/Downloads/Wobbling_Pixels_Update.zip`, run:

```bash
./update_wobbling_profiles.sh /media/user/RETROTINK /home/user/Downloads/Wobbling_Pixels_Update.zip
```