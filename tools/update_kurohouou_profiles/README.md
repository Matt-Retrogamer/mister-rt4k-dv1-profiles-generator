
# Update Kuro Houou Profiles Script

This script automates the process of updating and replacing all the Retrotink 4K profiles created by **Kuro Houou** on your Retrotink 4K SD card.

The latest Kuro Houou profiles can be found here: https://drive.google.com/drive/folders/1zxQqn36P6QPx3mu83SuNplTbbwID1YA2

## Usage

```bash
./update_kurohouou_profiles.sh /path/to/SD_Card /path/to/Kuro_Houou_Update.zip
```

- Replace `/path/to/SD_Card` with the path to your Retrotink 4K SD card’s root directory.
- Replace `/path/to/Kuro_Houou_Update.zip` with the path to the Kuro Houou update zip file.

## Instructions

1. **Download the script** and place it on your computer.
2. **Make the script executable**:
   ```bash
   chmod +x update_kurohouou_profiles.sh
   ```
3. **Insert your Retrotink 4K SD card** into your computer and note its mount point.
4. **Run the script**:
   ```bash
   ./update_kurohouou_profiles.sh /path/to/SD_Card /path/to/Kuro_Houou_Update.zip
   ```
5. Wait for the script to complete, then **safely eject your SD card**.

## What the Script Does

- Deletes old Kuro Houou banner files in the image folder.
- Removes outdated Kuro Houou profile folders in the profile directory.
- Copies new image, mask, and profile folders from the update zip file to the root of your SD card.

## Notes

- **Backup your SD card** before running the script.
- Ensure you have the necessary permissions to read and write to the SD card and the update zip file.
- The script requires **bash**, **find**, and **unzip** to be installed on your system.

## Example

If your SD card is mounted at `/media/user/RETROTINK` and your update zip file is located at `/home/user/Downloads/Kuro_Houou_Update.zip`, run:

```bash
./update_kurohouou_profiles.sh /media/user/RETROTINK /home/user/Downloads/Kuro_Houou_Update.zip
```