#!/bin/bash

# Exit on error and unset variables
set -eu

# Script Name: generate_rt4k_mister_dv1_profiles.sh
# Description: Replicate profiles to MiSTer profiles/DV1/ on Retrotink 4K
# Usage: ./generate_rt4k_mister_dv1_profiles.sh [options]
# Options:
#   -h, --help          Show help message and exit
#   -v, --verbose       Enable verbose output
#   -r, --rt4k PATH     Set RT4K SD Card root path
#   -m, --mister PATH   Set MiSTer root path

# Default paths (can be overridden by command-line arguments or environment variables)
RT4K="${RT4K:-/media/rt4k/}"
MISTER="${MISTER:-/media/mister/}"
VERBOSE=0

# Function to show help message
show_help() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -h, --help          Show help message and exit"
  echo "  -v, --verbose       Enable verbose output"
  echo "  -r, --rt4k PATH     Set RT4K SD Card root path"
  echo "  -m, --mister PATH   Set MiSTer root path"
  echo "Example:"
  echo "  $0 --rt4k /media/rt4k/ --mister /media/mister/ --verbose"
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -r|--rt4k)
      RT4K="$2"
      shift 2
      ;;
    -m|--mister)
      MISTER="$2"
      shift 2
      ;;
    -v|--verbose)
      VERBOSE=1
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Function to log messages
log() {
  if [ "$VERBOSE" -eq 1 ]; then
    echo "$1"
  fi
}

# Check if RT4K path is set and exists
if [ -z "$RT4K" ] || [ ! -d "$RT4K" ]; then
  echo "Error: RT4K SD Card root path not set or does not exist."
  echo "Please set it using the --rt4k option or RT4K environment variable."
  exit 1
fi

# Check if MiSTer path is set and exists
if [ -z "$MISTER" ] || [ ! -d "$MISTER" ]; then
  echo "Error: MiSTer root path not set or does not exist."
  echo "Please set it using the --mister option or MISTER environment variable."
  exit 1
fi

# Set Base Profiles (Console, Arcade, Portables)
PRF_CONSOLE="${RT4K}profile/_CRT Emulation/Kuro Houou - CRT Model Emulation/JVC D-Series-D200 - 4K HDR.rt4"
PRF_GBA="${RT4K}profile/Nintendo Switch/Billgonzo's GBC-GBA Profiles/Switch_GBA_13x.rt4"
PRF_GBC="${RT4K}profile/Nintendo Switch/Billgonzo's GBC-GBA Profiles/Switch_GBC_15x.rt4"
PRF_ARCADE="${RT4K}profile/_CRT Emulation/Kuro Houou - CRT Model Emulation/JVC D-Series-D200 - 4K HDR.rt4"

# Check if base profile files exist
for profile in "$PRF_CONSOLE" "$PRF_GBA" "$PRF_GBC" "$PRF_ARCADE"; do
  if [ ! -f "$profile" ]; then
    echo "Error: Base profile file not found: $profile"
    exit 1
  fi
done

# Counters for summary
created_profiles=0
skipped_profiles=0
errors=0

# Function to process cores
process_cores() {
  local core_type="$1"
  local source_dir="$2"
  local base_profile="$3"
  local file_ext="$4"
  local delimiter="$5"

  local source_path="${MISTER}${source_dir}"
  if [ ! -d "$source_path" ]; then
    log "Warning: Source directory not found: $source_path"
    return
  fi

  for f in "$source_path"*."$file_ext"; do
    # Skip if no files found
    [ -e "$f" ] || continue
    # Get the filename without extension
    filename=$(basename "$f" ".$file_ext")
    # Extract the core name before the first delimiter
    core_name=${filename%%"$delimiter"*}
    # Destination profile path
    dest_profile="${RT4K}profile/DV1/${core_name}.rt4"
    # Check if the profile already exists
    if [ ! -f "$dest_profile" ]; then
      log "Creating profile for ${core_name}"
      if cp "$base_profile" "$dest_profile"; then
        ((created_profiles++))
      else
        echo "Error: Failed to copy profile for ${core_name}"
        ((errors++))
      fi
    else
      log "${core_name}.rt4 already exists. Skipping."
      ((skipped_profiles++))
    fi
  done
}

# Function to process additional Arcade profiles from a text file
process_additional_arcade_profiles() {
  local txt_file="DV1_ARCADE.txt"
  # Check if the file exists
  if [ ! -f "$txt_file" ]; then
    log "Additional arcade profiles file ($txt_file) not found."
    return
  fi
  while IFS= read -r line; do
    # Trim whitespace
    line=$(echo "$line" | xargs)
    # Skip empty lines or comments
    [[ -z "$line" || "$line" == \#* ]] && continue
    filename=$(basename "$line" .zip)
    dest_profile="${RT4K}profile/DV1/${filename}.rt4"
    # Check if the profile already exists
    if [ ! -f "$dest_profile" ]; then
      log "Creating additional arcade profile for ${filename}"
      if cp "$PRF_ARCADE" "$dest_profile"; then
        ((created_profiles++))
      else
        echo "Error: Failed to copy profile for ${filename}"
        ((errors++))
      fi
    else
      log "${filename}.rt4 already exists. Skipping."
      ((skipped_profiles++))
    fi
  done < "$txt_file"
}

# Function for additional handling and specific profiles
additional_handling() {
  # Rename TurboGrafx16.rt4 to TGFX16.rt4 if TGFX16.rt4 does not exist
  if [ ! -f "${RT4K}profile/DV1/TGFX16.rt4" ]; then
    if [ -f "${RT4K}profile/DV1/TurboGrafx16.rt4" ]; then
      log "Renaming TurboGrafx16.rt4 to TGFX16.rt4"
      if mv "${RT4K}profile/DV1/TurboGrafx16.rt4" "${RT4K}profile/DV1/TGFX16.rt4"; then
        ((created_profiles++))
      else
        echo "Error: Failed to rename TurboGrafx16.rt4 to TGFX16.rt4"
        ((errors++))
      fi
    fi
  else
    log "TGFX16.rt4 already exists. Skipping rename."
    ((skipped_profiles++))
  fi

  # Menu Core
  if [ ! -f "${RT4K}profile/DV1/Menu.rt4" ]; then
    log "Creating Menu.rt4 profile"
    if cp "$PRF_ARCADE" "${RT4K}profile/DV1/Menu.rt4"; then
      ((created_profiles++))
    else
      echo "Error: Failed to create Menu.rt4 profile"
      ((errors++))
    fi
  else
    log "Menu.rt4 already exists. Skipping."
    ((skipped_profiles++))
  fi

  # Portables/Specific profiles
  declare -A portables=(
    ["GBA"]="$PRF_GBA"
    ["GBC"]="$PRF_GBC"
  )

  for portable in "${!portables[@]}"; do
    dest_profile="${RT4K}profile/DV1/${portable}.rt4"
    if [ ! -f "$dest_profile" ]; then
      log "Creating ${portable}.rt4 profile"
      if cp "${portables[$portable]}" "$dest_profile"; then
        ((created_profiles++))
      else
        echo "Error: Failed to create ${portable}.rt4 profile"
        ((errors++))
      fi
    else
      log "${portable}.rt4 already exists. Skipping."
      ((skipped_profiles++))
    fi
  done
}

# Main script execution
main() {
  # Ensure destination directory exists
  mkdir -p "${RT4K}profile/DV1/"

  # Process cores and profiles
  process_cores "Console" "_Console/" "$PRF_CONSOLE" "rbf" "_"
  process_cores "Arcade" "games/mame/" "$PRF_ARCADE" "zip" ""
  process_cores "Computer" "_Computer/" "$PRF_CONSOLE" "rbf" "_"
  process_cores "Utility" "_Utility/" "$PRF_CONSOLE" "rbf" "_"
  process_additional_arcade_profiles
  additional_handling

  # Summary
  echo "Profile replication completed."
  echo "Profiles created: $created_profiles"
  echo "Profiles skipped: $skipped_profiles"
  if [ "$errors" -gt 0 ]; then
    echo "Errors encountered: $errors"
  fi
}

# Execute main function
main