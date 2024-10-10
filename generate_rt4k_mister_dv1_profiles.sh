#!/bin/bash

# Exit on error and unset variables
set -eu

# Script Name: generate_rt4k_mister_dv1_profiles.sh
# Description: Replicate profiles to MiSTer profiles/DV1/ on RetroTINK 4K
# Usage: ./generate_rt4k_mister_dv1_profiles.sh [options]
# Options:
#   -h, --help          Show help message and exit
#   -v, --verbose       Enable verbose output
#   -f, --force         Force overwrite of existing profiles
#   -r, --rt4k PATH     Set RT4K SD Card root path
#   -m, --mister PATH   Set MiSTer root path (local path or SSH URL)

# Default paths (can be overridden by command-line arguments or environment variables)
RT4K="${RT4K:-data/rt4k/}"
MISTER="${MISTER:-data/mister/}"
VERBOSE=0
FORCE=0

# Function to show help message
show_help() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -h, --help          Show help message and exit"
  echo "  -v, --verbose       Enable verbose output"
  echo "  -f, --force         Force overwrite of existing profiles"
  echo "  -r, --rt4k PATH     Set RT4K SD Card root path"
  echo "  -m, --mister PATH   Set MiSTer root path (local path or SSH URL)"
  echo "Examples:"
  echo "  $0 --rt4k /media/rt4k/ --mister /media/fat/ --verbose"
  echo "  $0 --rt4k /media/rt4k/ --mister ssh://192.168.1.100 --verbose"
  echo "  $0 --rt4k /media/rt4k/ --mister ssh://user@hostname --force --verbose"
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
    -f|--force)
      FORCE=1
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

# Determine if MISTER path is remote
if [[ "$MISTER" == ssh://* ]]; then
  REMOTE_MISTER=1
  MISTER_SSH_URL="${MISTER#ssh://}"
  # Default values
  SSH_USER="root"
  MISTER_PATH="/media/fat/"
  
  # Extract SSH_USER and MISTER_SSH_REST
  if [[ "$MISTER_SSH_URL" == *@* ]]; then
    SSH_USER="${MISTER_SSH_URL%%@*}"
    MISTER_SSH_REST="${MISTER_SSH_URL#*@}"
  else
    MISTER_SSH_REST="$MISTER_SSH_URL"
  fi
  
  # Extract SSH_HOST and MISTER_PATH
  if [[ "$MISTER_SSH_REST" == *:* ]]; then
    SSH_HOST="${MISTER_SSH_REST%%:*}"
    MISTER_PATH_TMP="${MISTER_SSH_REST#*:}"
    if [ -n "$MISTER_PATH_TMP" ]; then
      MISTER_PATH="$MISTER_PATH_TMP"
    fi
  else
    SSH_HOST="$MISTER_SSH_REST"
  fi
else
  REMOTE_MISTER=0
  MISTER_PATH="$MISTER"
fi

# Debug output
log "MiSTer Path: $MISTER_PATH"
if [ "$REMOTE_MISTER" -eq 1 ]; then
  log "Remote MiSTer detected."
  log "SSH User: $SSH_USER"
  log "SSH Host: $SSH_HOST"
fi

# Check if MiSTer path is set and exists
if [ -z "$MISTER_PATH" ]; then
  echo "Error: MiSTer root path not set."
  echo "Please set it using the --mister option or MISTER environment variable."
  exit 1
fi

if [ "$REMOTE_MISTER" -eq 1 ]; then
  # Check if remote directory exists
  if ! ssh "${SSH_USER}@${SSH_HOST}" "[ -d \"$MISTER_PATH\" ]"; then
    echo "Error: MiSTer root path does not exist on remote host."
    exit 1
  fi
else
  if [ ! -d "$MISTER_PATH" ]; then
    echo "Error: MiSTer root path does not exist."
    exit 1
  fi
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
overwritten_profiles=0
skipped_profiles=0
errors=0

# Function to get file list (handles local and remote paths)
get_file_list() {
  local path="$1"
  local ext="$2"
  if [ "$REMOTE_MISTER" -eq 1 ]; then
    ssh "${SSH_USER}@${SSH_HOST}" "find \"$path\" -maxdepth 1 -type f -name '*.$ext' -exec basename {} \;" 2>/dev/null || true
  else
    find "$path" -maxdepth 1 -type f -name "*.$ext" -exec basename {} \; 2>/dev/null || true
  fi
}

# Function to check if directory exists (handles local and remote paths)
directory_exists() {
  local path="$1"
  if [ "$REMOTE_MISTER" -eq 1 ]; then
    ssh "${SSH_USER}@${SSH_HOST}" "[ -d \"$path\" ]"
  else
    [ -d "$path" ]
  fi
}

# Function to process cores
process_cores() {
  local core_type="$1"
  local source_dir="$2"
  local base_profile="$3"
  local file_ext="$4"
  local delimiter="$5"

  local source_path="${MISTER_PATH}${source_dir}"
  if ! directory_exists "$source_path"; then
    log "Warning: Source directory not found: $source_path"
    return
  fi

  while IFS= read -r filename; do
    # Skip if no files found
    [[ -z "$filename" ]] && continue

    # Extract the core name before the first delimiter
    if [ -n "$delimiter" ]; then
      core_name=${filename%%"$delimiter"*}
    else
      core_name=${filename%.*}  # Remove file extension
    fi

    # Skip if core_name is empty
    if [[ -z "$core_name" ]]; then
      log "Warning: core_name is empty for filename: $filename"
      continue
    fi

    # Destination profile path
    dest_profile="${RT4K}profile/DV1/${core_name}.rt4"

    # Check if the profile exists
    if [ -f "$dest_profile" ]; then
      if [ "$FORCE" -eq 1 ]; then
        log "Overwriting existing profile for ${core_name}"
        if cp "$base_profile" "$dest_profile"; then
          overwritten_profiles=$((overwritten_profiles + 1))
        else
          echo "Error: Failed to overwrite profile for ${core_name}"
          errors=$((errors + 1))
        fi
      else
        log "${core_name}.rt4 already exists. Skipping."
        skipped_profiles=$((skipped_profiles + 1))
      fi
    else
      log "Creating profile for ${core_name}"
      if cp "$base_profile" "$dest_profile"; then
        created_profiles=$((created_profiles + 1))
      else
        echo "Error: Failed to create profile for ${core_name}"
        errors=$((errors + 1))
      fi
    fi
  done < <(get_file_list "$source_path" "$file_ext")
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
    # Check if the profile exists
    if [ -f "$dest_profile" ]; then
      if [ "$FORCE" -eq 1 ]; then
        log "Overwriting existing profile for ${filename}"
        if cp "$PRF_ARCADE" "$dest_profile"; then
          overwritten_profiles=$((overwritten_profiles + 1))
        else
          echo "Error: Failed to overwrite profile for ${filename}"
          errors=$((errors + 1))
        fi
      else
        log "${filename}.rt4 already exists. Skipping."
        skipped_profiles=$((skipped_profiles + 1))
      fi
    else
      log "Creating additional arcade profile for ${filename}"
      if cp "$PRF_ARCADE" "$dest_profile"; then
        created_profiles=$((created_profiles + 1))
      else
        echo "Error: Failed to create profile for ${filename}"
        errors=$((errors + 1))
      fi
    fi
  done < "$txt_file"
}

# Function for additional handling and specific profiles
additional_handling() {
  # Rename TurboGrafx16.rt4 to TGFX16.rt4 if TGFX16.rt4 does not exist or FORCE is set
  if [ "$FORCE" -eq 1 ] || [ ! -f "${RT4K}profile/DV1/TGFX16.rt4" ]; then
    if [ -f "${RT4K}profile/DV1/TurboGrafx16.rt4" ]; then
      log "Renaming TurboGrafx16.rt4 to TGFX16.rt4"
      if mv -f "${RT4K}profile/DV1/TurboGrafx16.rt4" "${RT4K}profile/DV1/TGFX16.rt4"; then
        if [ "$FORCE" -eq 1 ]; then
          overwritten_profiles=$((overwritten_profiles + 1))
        else
          created_profiles=$((created_profiles + 1))
        fi
      else
        echo "Error: Failed to rename TurboGrafx16.rt4 to TGFX16.rt4"
        errors=$((errors + 1))
      fi
    fi
  else
    log "TGFX16.rt4 already exists. Skipping rename."
    skipped_profiles=$((skipped_profiles + 1))
  fi

  # Menu Core
  dest_profile="${RT4K}profile/DV1/Menu.rt4"
  if [ -f "$dest_profile" ]; then
    if [ "$FORCE" -eq 1 ]; then
      log "Overwriting Menu.rt4 profile"
      if cp "$PRF_ARCADE" "$dest_profile"; then
        overwritten_profiles=$((overwritten_profiles + 1))
      else
        echo "Error: Failed to overwrite Menu.rt4 profile"
        errors=$((errors + 1))
      fi
    else
      log "Menu.rt4 already exists. Skipping."
      skipped_profiles=$((skipped_profiles + 1))
    fi
  else
    log "Creating Menu.rt4 profile"
    if cp "$PRF_ARCADE" "$dest_profile"; then
      created_profiles=$((created_profiles + 1))
    else
      echo "Error: Failed to create Menu.rt4 profile"
      errors=$((errors + 1))
    fi
  fi

  # Portables/Specific profiles

  # Handle GBA
  dest_profile="${RT4K}profile/DV1/GBA.rt4"
  if [ -f "$dest_profile" ]; then
    if [ "$FORCE" -eq 1 ]; then
      log "Overwriting GBA.rt4 profile"
      if cp "$PRF_GBA" "$dest_profile"; then
        overwritten_profiles=$((overwritten_profiles + 1))
      else
        echo "Error: Failed to overwrite GBA.rt4 profile"
        errors=$((errors + 1))
      fi
    else
      log "GBA.rt4 already exists. Skipping."
      skipped_profiles=$((skipped_profiles + 1))
    fi
  else
    log "Creating GBA.rt4 profile"
    if cp "$PRF_GBA" "$dest_profile"; then
      created_profiles=$((created_profiles + 1))
    else
      echo "Error: Failed to create GBA.rt4 profile"
      errors=$((errors + 1))
    fi
  fi

  # Handle GBC
  dest_profile="${RT4K}profile/DV1/GBC.rt4"
  if [ -f "$dest_profile" ]; then
    if [ "$FORCE" -eq 1 ]; then
      log "Overwriting GBC.rt4 profile"
      if cp "$PRF_GBC" "$dest_profile"; then
        overwritten_profiles=$((overwritten_profiles + 1))
      else
        echo "Error: Failed to overwrite GBC.rt4 profile"
        errors=$((errors + 1))
      fi
    else
      log "GBC.rt4 already exists. Skipping."
      skipped_profiles=$((skipped_profiles + 1))
    fi
  else
    log "Creating GBC.rt4 profile"
    if cp "$PRF_GBC" "$dest_profile"; then
      created_profiles=$((created_profiles + 1))
    else
      echo "Error: Failed to create GBC.rt4 profile"
      errors=$((errors + 1))
    fi
  fi
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
  echo "Profiles overwritten: $overwritten_profiles"
  echo "Profiles skipped: $skipped_profiles"
  if [ "$errors" -gt 0 ]; then
    echo "Errors encountered: $errors"
  fi
}

# Execute main function
main