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

# Source per-core profiles and base profiles from config file if it exists
PROFILES_CONFIG_FILE="profiles_config.sh"
if [ -f "$PROFILES_CONFIG_FILE" ]; then
  log "Sourcing profiles from $PROFILES_CONFIG_FILE"
  source "$PROFILES_CONFIG_FILE"
else
  log "Config file $PROFILES_CONFIG_FILE not found. Using default profiles."
fi

# Set Base Profiles (Console, Arcade) - Fallback to defaults if not set in override
PRF_CONSOLE="${PRF_CONSOLE:-${RT4K}profile/_CRT Emulation/Kuro Houou - CRT Model Emulation/JVC D-Series-D200 - 4K HDR.rt4}"
PRF_ARCADE="${PRF_ARCADE:-${RT4K}profile/_CRT Emulation/Kuro Houou - CRT Model Emulation/JVC D-Series-D200 - 4K HDR.rt4}"

# Check if base profile files exist
for profile in "$PRF_CONSOLE" "$PRF_ARCADE"; do
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

# Function to sanitize core_name to a valid variable name
sanitize_var_name() {
  local input="$1"
  # Convert to uppercase, replace spaces with underscores, remove invalid characters
  local sanitized=$(echo "$input" | tr '[:lower:]' '[:upper:]' | tr ' ' '_' | tr -cd '[:alnum:]_')
  echo "$sanitized"
}

# Placeholder function to set HDMI input in the profile
set_hdmi_input() {
  local profile_path="$1"
  # Placeholder for future implementation
  # log "Setting HDMI input for profile: $profile_path (placeholder)"
}

# Function to process cores
process_cores() {
  local core_type="$1"
  local source_dir="$2"
  local default_base_profile="$3"
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

    # Sanitize core_name
    sanitized_core_name=$(sanitize_var_name "$core_name")
    # Construct variable name
    var_name="PRF_${sanitized_core_name}"

    # Determine the base profile to use
    if [ -n "${!var_name:-}" ]; then
      base_profile_to_use="${!var_name}"
    else
      base_profile_to_use="$default_base_profile"
    fi

    # Check if the base profile file exists
    if [ ! -f "$base_profile_to_use" ]; then
      echo "Error: Base profile file not found: $base_profile_to_use for core $core_name"
      errors=$((errors + 1))
      continue
    fi

    # Destination profile path
    dest_profile="${RT4K}profile/DV1/${core_name}.rt4"

    # Check if the profile exists
    if [ -f "$dest_profile" ]; then
      if [ "$FORCE" -eq 1 ]; then
        log "Overwriting existing profile for ${core_name}"
        if cp "$base_profile_to_use" "$dest_profile"; then
          set_hdmi_input "$dest_profile"
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
      if cp "$base_profile_to_use" "$dest_profile"; then
        set_hdmi_input "$dest_profile"
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

    # Sanitize core_name
    sanitized_core_name=$(sanitize_var_name "$filename")
    # Construct variable name
    var_name="PRF_${sanitized_core_name}"

    # Determine the base profile to use
    if [ -n "${!var_name:-}" ]; then
      base_profile_to_use="${!var_name}"
    else
      base_profile_to_use="$PRF_ARCADE"
    fi

    # Check if the base profile file exists
    if [ ! -f "$base_profile_to_use" ]; then
      echo "Error: Base profile file not found: $base_profile_to_use for core $filename"
      errors=$((errors + 1))
      continue
    fi

    dest_profile="${RT4K}profile/DV1/${filename}.rt4"
    # Check if the profile exists
    if [ -f "$dest_profile" ]; then
      if [ "$FORCE" -eq 1 ]; then
        log "Overwriting existing profile for ${filename}"
        if cp "$base_profile_to_use" "$dest_profile"; then
          set_hdmi_input "$dest_profile"
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
      if cp "$base_profile_to_use" "$dest_profile"; then
        set_hdmi_input "$dest_profile"
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
        set_hdmi_input "$dest_profile"
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
      set_hdmi_input "$dest_profile"
      created_profiles=$((created_profiles + 1))
    else
      echo "Error: Failed to create Menu.rt4 profile"
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
