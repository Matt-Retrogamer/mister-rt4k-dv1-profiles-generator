#!/usr/bin/env bash

# Exit on error and unset variables
set -eu

# Script Name: generate_rt4k_mister_dv1_profiles.sh
# Description: Replicate profiles to MiSTer profiles/DV1/ on RetroTINK 4K
# Usage: ./generate_rt4k_mister_dv1_profiles.sh [options]
# Options:
#   -h, --help              Show help message and exit
#   -v, --verbose           Enable verbose output
#   -f, --force             Force overwrite of existing profiles
#   -r, --rt4k PATH         Set RT4K SD Card root path
#   -m, --mister PATH       Set MiSTer root path (local path or SSH URL)
#   -i, --set-hdmi-input    Enable HDMI input override in profiles

# Default paths (can be overridden by command-line arguments or environment variables)
RT4K="${RT4K:-data/rt4k/}"
MISTER="${MISTER:-data/mister/}"
VERBOSE=0
FORCE=0
SET_HDMI_INPUT=0  # New variable to control HDMI input override

# Function to show help message
show_help() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -h, --help              Show help message and exit"
  echo "  -v, --verbose           Enable verbose output"
  echo "  -f, --force             Force overwrite of existing profiles"
  echo "  -r, --rt4k PATH         Set RT4K SD Card root path"
  echo "  -m, --mister PATH       Set MiSTer root path (local path or SSH URL)"
  echo "  -i, --set-hdmi-input    Enable HDMI input override in profiles"
  echo "Examples:"
  echo "  $0 --rt4k /media/rt4k/ --mister /media/fat/ --verbose --set-hdmi-input"
  echo "  $0 --rt4k /media/rt4k/ --mister ssh://192.168.1.100 --verbose --set-hdmi-input"
  echo "  $0 --rt4k /media/rt4k/ --mister ssh://user@hostname --force --verbose --set-hdmi-input"
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
    -i|--set-hdmi-input)
      SET_HDMI_INPUT=1
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

# Ensure RT4K path ends with a slash
[[ "${RT4K}" != */ ]] && RT4K="${RT4K}/"

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

# Ensure MISTER_PATH ends with a slash
[[ "${MISTER_PATH}" != */ ]] && MISTER_PATH="${MISTER_PATH}/"

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

# Arrays to track profile names for detailed summary
created_profile_names=()
overwritten_profile_names=()
skipped_profile_names=()

# Renaming rules (original_name target_name)
declare -a renaming_rules=(
  "TurboGrafx16.rt4 TGFX16.rt4"
  "GameboyColor.rt4 GBC.rt4"
  "PocketChallengeV2.rt4 PocketChalleng.rt4"
  "WonderSwanColor.rt4 WonderSwanColo.rt4"
)

# Replace associative array with two regular arrays
renaming_map_keys=()
renaming_map_values=()

for rule in "${renaming_rules[@]}"; do
  original_name="${rule%% *}"
  target_name="${rule#* }"
  renaming_map_keys+=("$original_name")
  renaming_map_values+=("$target_name")
done

# Function to get target name from original name
get_target_name() {
  local original_name="$1"
  local i
  for i in "${!renaming_map_keys[@]}"; do
    if [[ "${renaming_map_keys[$i]}" == "$original_name" ]]; then
      echo "${renaming_map_values[$i]}"
      return
    fi
  done
  echo ""
}

# Function to get file list (handles local and remote paths)
get_file_list() {
  local path="$1"
  local ext="$2"
  if [ "$REMOTE_MISTER" -eq 1 ]; then
    ssh "${SSH_USER}@${SSH_HOST}" "find \"$path\" -maxdepth 1 -type f -name '*.$ext' -exec basename \"{}\" \;" 2>/dev/null || true
  else
    find "$path" -maxdepth 1 -type f -name "*.$ext" -exec basename "{}" \; 2>/dev/null || true
  fi
}

###############################################################################
# Retrieves .mra filenames and their <setname> in a single pass
###############################################################################
get_mra_setnames() {
  local path="$1"
  if [ "$REMOTE_MISTER" -eq 1 ]; then
    ssh "${SSH_USER}@${SSH_HOST}" bash -s <<EOF || true
      find "$path" -maxdepth 1 -type f -name '*.mra' -print0 |
      while IFS= read -r -d '' file; do
        setname=\$(sed -n -E 's/.*<setname>([^<]+)<\\/setname>.*/\\1/p' "\$file")
        echo "\$(basename "\$file")"\$'\t'"\$setname"
      done
EOF
  else
    find "$path" -maxdepth 1 -type f -name '*.mra' -print0 |
    while IFS= read -r -d '' file; do
      local setname
      setname=$(sed -n -E 's/.*<setname>([^<]+)<\/setname>.*/\1/p' "$file")
      echo "$(basename "$file")"$'\t'"$setname"
    done
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

# Function to set HDMI input in the profile and recalculate CRC
set_hdmi_input() {
  local profile_path="$1"

  # Check if Python 3 and the Python script are available
  if command -v python3 >/dev/null 2>&1 && [ -f "tools/set_hdmi_input_python/set_hdmi_input.py" ]; then
    # Call the Python script
    log "Setting input to HDMI for profile: $profile_path (python3 implementation - Fast)"
    python3 tools/set_hdmi_input_python/set_hdmi_input.py "$profile_path"
  else
    log "Setting input to HDMI for profile: $profile_path (Bash implementation - Slow)"

    # Offsets and values based on the RT4K profile structure
    local header_size=128                # Header size in bytes
    local input_source_offset=22505      # Offset in data section (excluding header)
    local total_input_offset=$((header_size + input_source_offset))  # Total offset in file

    local input_source_hdmi_value=0      # Value representing HDMI input (from definitions)

    # Write the HDMI input value at the specified offset
    printf "%02x" "$input_source_hdmi_value" | xxd -r -p | dd of="$profile_path" bs=1 seek="$total_input_offset" count=1 conv=notrunc status=none

    # Read the data starting from offset 128 to the end of the file
    local crc_data_hex
    crc_data_hex=$(dd if="$profile_path" bs=1 skip=128 status=none | xxd -p -c 256 | tr -d '\n')

    # Calculate the CRC16 using the provided algorithm
    local crc
    crc=$(crc16 "$crc_data_hex")

    # Prepare the CRC bytes in little-endian order
    local crc_low
    local crc_high
    crc_low=$(printf "%02x" $((crc & 0xFF)))
    crc_high=$(printf "%02x" $(((crc >> 8) & 0xFF)))

    # Combine CRC bytes and two zero bytes
    printf "%s%s0000" "$crc_low" "$crc_high" | xxd -r -p | dd of="$profile_path" bs=1 seek=32 count=4 conv=notrunc status=none
  fi
}

# CRC16 calculation function in Bash (as per provided C code)
crc16() {
  local data_hex="$1"
  local crc=0
  local data_len=${#data_hex}
  local index t_dat crc_index

  # CRC table as per the provided C code
  local crc_table=(
    0x0000 0x1021 0x2042 0x3063
    0x4084 0x50a5 0x60c6 0x70e7
    0x8108 0x9129 0xa14a 0xb16b
    0xc18c 0xd1ad 0xe1ce 0xf1ef
  )

  # Process each byte (represented as two hex characters)
  for (( index=0; index<data_len; index+=2 )); do
    # Get the current byte value
    t_dat=$(( 0x${data_hex:$index:2} ))

    # First iteration
    crc_index=$(( (crc >> 12) ^ (t_dat >> 4) ))
    crc=$(( ${crc_table[crc_index & 0x0F]} ^ ( (crc << 4) & 0xFFFF ) ))

    # Second iteration
    crc_index=$(( (crc >> 12) ^ (t_dat & 0x0F) ))
    crc=$(( ${crc_table[crc_index & 0x0F]} ^ ( (crc << 4) & 0xFFFF ) ))
  done

  # Return the lower 16 bits of crc
  echo $(( crc & 0xFFFF ))
}

# Function to process cores (generic for console/computer/utility)
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
      core_name=$(echo "$core_name" | tr -d ' ')
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
    profile_name="${core_name}.rt4"

    # Check if the profile is scheduled for renaming
    target_name="$(get_target_name "$profile_name")"
    if [[ -n "$target_name" ]]; then
      dest_profile_target="${RT4K}profile/DV1/${target_name}"
      if [ -f "$dest_profile_target" ] && [ "$FORCE" -eq 0 ]; then
        log "Profile ${target_name} already exists. Skipping creation of ${profile_name}."
        skipped_profiles=$((skipped_profiles + 1))
        continue
      fi
    fi

    dest_profile="${RT4K}profile/DV1/${profile_name}"

    # Check if the profile exists
    if [ -f "$dest_profile" ]; then
      if [ "$FORCE" -eq 1 ]; then
        log "Overwriting existing profile for ${core_name}"
        if cp "$base_profile_to_use" "$dest_profile"; then
          if [ "$SET_HDMI_INPUT" -eq 1 ]; then
            set_hdmi_input "$dest_profile"
          fi
          overwritten_profiles=$((overwritten_profiles + 1))
          overwritten_profile_names+=("${profile_name}")
        else
          echo "Error: Failed to overwrite profile for ${core_name}"
          errors=$((errors + 1))
        fi
      else
        log "${core_name}.rt4 already exists. Skipping."
        skipped_profiles=$((skipped_profiles + 1))
        skipped_profile_names+=("${profile_name}")
      fi
    else
      log "Creating profile for ${core_name}"
      if cp "$base_profile_to_use" "$dest_profile"; then
        if [ "$SET_HDMI_INPUT" -eq 1 ]; then
          set_hdmi_input "$dest_profile"
        fi
        created_profiles=$((created_profiles + 1))
        created_profile_names+=("${profile_name}")
      else
        echo "Error: Failed to create profile for ${core_name}"
        errors=$((errors + 1))
      fi
    fi
  done < <(get_file_list "$source_path" "$file_ext")
}

# Process Arcade cores using the <setname> from each .mra file
process_arcade_cores() {
  local source_dir="_Arcade/"
  local default_base_profile="$PRF_ARCADE"
  local source_path="${MISTER_PATH}${source_dir}"

  if ! directory_exists "$source_path"; then
    log "Warning: Source directory not found: $source_path"
    return
  fi

  while IFS=$'\t' read -r mra_file setname; do
    [[ -z "$mra_file" ]] && continue

    if [[ -z "$setname" ]]; then
      log "Warning: No setname found in MRA file: $mra_file. Skipping."
      continue
    fi

    local full_path="${source_path}${mra_file}"
    # Sanitize setname
    local sanitized_core_name=$(sanitize_var_name "$setname")
    local var_name="PRF_${sanitized_core_name}"

    # Determine the base profile to use
    local base_profile_to_use
    if [ -n "${!var_name:-}" ]; then
      base_profile_to_use="${!var_name}"
    else
      base_profile_to_use="$default_base_profile"
    fi

    # Check if the base profile file exists
    if [ ! -f "$base_profile_to_use" ]; then
      echo "Error: Base profile file not found: $base_profile_to_use for core $setname"
      errors=$((errors + 1))
      continue
    fi

    local profile_name="${setname}.rt4"

    # Check if the profile is scheduled for renaming
    local target_name
    target_name="$(get_target_name "$profile_name")"
    if [[ -n "$target_name" ]]; then
      local dest_profile_target="${RT4K}profile/DV1/${target_name}"
      if [ -f "$dest_profile_target" ] && [ "$FORCE" -eq 0 ]; then
        log "Profile ${target_name} already exists. Skipping creation of ${profile_name}."
        skipped_profiles=$((skipped_profiles + 1))
        skipped_profile_names+=("${target_name}")
        continue
      fi
    fi

    local dest_profile="${RT4K}profile/DV1/${profile_name}"

    # Check if the profile exists
    if [ -f "$dest_profile" ]; then
      if [ "$FORCE" -eq 1 ]; then
        log "Overwriting existing profile for ${setname}"
        if cp "$base_profile_to_use" "$dest_profile"; then
          if [ "$SET_HDMI_INPUT" -eq 1 ]; then
            set_hdmi_input "$dest_profile"
          fi
          overwritten_profiles=$((overwritten_profiles + 1))
          overwritten_profile_names+=("${profile_name}")
        else
          echo "Error: Failed to overwrite profile for ${setname}"
          errors=$((errors + 1))
        fi
      else
        log "${setname}.rt4 already exists. Skipping."
        skipped_profiles=$((skipped_profiles + 1))
        skipped_profile_names+=("${profile_name}")
      fi
    else
      log "Creating profile for ${setname}"
      if cp "$base_profile_to_use" "$dest_profile"; then
        if [ "$SET_HDMI_INPUT" -eq 1 ]; then
          set_hdmi_input "$dest_profile"
        fi
        created_profiles=$((created_profiles + 1))
        created_profile_names+=("${profile_name}")
      else
        echo "Error: Failed to create profile for ${setname}"
        errors=$((errors + 1))
      fi
    fi
  done < <(get_mra_setnames "$source_path")
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

    dest_profile="${RT4K}profile/DV1/${filename}.rt4"
    # Check if the profile exists
    if [ -f "$dest_profile" ]; then
      if [ "$FORCE" -eq 1 ]; then
        log "Overwriting existing profile for ${filename}"
        if cp "$base_profile_to_use" "$dest_profile"; then
          if [ "$SET_HDMI_INPUT" -eq 1 ]; then
            set_hdmi_input "$dest_profile"
          fi
          overwritten_profiles=$((overwritten_profiles + 1))
          overwritten_profile_names+=("${filename}.rt4")
        else
          echo "Error: Failed to overwrite profile for ${filename}"
          errors=$((errors + 1))
        fi
      else
        log "${filename}.rt4 already exists. Skipping."
        skipped_profiles=$((skipped_profiles + 1))
        skipped_profile_names+=("${filename}.rt4")
      fi
    else
      log "Creating additional arcade profile for ${filename}"
      if cp "$base_profile_to_use" "$dest_profile"; then
        if [ "$SET_HDMI_INPUT" -eq 1 ]; then
          set_hdmi_input "$dest_profile"
        fi
        created_profiles=$((created_profiles + 1))
        created_profile_names+=("${filename}.rt4")
      else
        echo "Error: Failed to create profile for ${filename}"
        errors=$((errors + 1))
      fi
    fi
  done < "$txt_file"
}

# Function for additional handling and specific profiles
additional_handling() {
  # Loop over the renaming rules
  for rule in "${renaming_rules[@]}"; do
    # Split rule into original_name and target_name
    original_name="${rule%% *}"
    target_name="${rule#* }"

    # Source and destination profile paths
    src_file="${RT4K}profile/DV1/${original_name}"
    dest_file="${RT4K}profile/DV1/${target_name}"

    # Check if the source file exists
    if [ -f "$src_file" ]; then
      # Check if the destination profile exists
      if [ "$FORCE" -eq 1 ] || [ ! -f "$dest_file" ]; then
        log "Renaming ${original_name} to ${target_name}"
        if mv -f "$src_file" "$dest_file"; then
          if [ "$FORCE" -eq 1 ]; then
            overwritten_profiles=$((overwritten_profiles + 1))
            overwritten_profile_names+=("${target_name}")
          else
            created_profiles=$((created_profiles + 1))
            created_profile_names+=("${target_name}")
          fi
        else
          echo "Error: Failed to rename ${original_name} to ${target_name}"
          errors=$((errors + 1))
        fi
      else
        log "${target_name} already exists. Skipping rename."
        skipped_profiles=$((skipped_profiles + 1))
        skipped_profile_names+=("${target_name}")
      fi
    else
      log "Source file ${original_name} not found. Skipping rename."
      # No need to increment skipped_profiles here since it wasn't generated in this run
    fi
  done

  # Menu Core
  dest_profile="${RT4K}profile/DV1/Menu.rt4"
  if [ -f "$dest_profile" ]; then
    if [ "$FORCE" -eq 1 ]; then
      log "Overwriting Menu.rt4 profile"
      if cp "$PRF_ARCADE" "$dest_profile"; then
        if [ "$SET_HDMI_INPUT" -eq 1 ]; then
          set_hdmi_input "$dest_profile"
        fi
        overwritten_profiles=$((overwritten_profiles + 1))
        overwritten_profile_names+=("Menu.rt4")
      else
        echo "Error: Failed to overwrite Menu.rt4 profile"
        errors=$((errors + 1))
      fi
    else
      log "Menu.rt4 already exists. Skipping."
      skipped_profiles=$((skipped_profiles + 1))
      skipped_profile_names+=("Menu.rt4")
    fi
  else
    log "Creating Menu.rt4 profile"
    if cp "$PRF_ARCADE" "$dest_profile"; then
      if [ "$SET_HDMI_INPUT" -eq 1 ]; then
        set_hdmi_input "$dest_profile"
      fi
      created_profiles=$((created_profiles + 1))
      created_profile_names+=("Menu.rt4")
    else
      echo "Error: Failed to create Menu.rt4 profile"
      errors=$((errors + 1))
    fi
  fi
}

# Function to display detailed profile summary
show_profile_summary() {
  local max_display=20
  local list_type="$1"
  local count="$2"
  local array_name="$3"
  
  if [ "$count" -gt 0 ]; then
    echo
    # Create a temporary array name to work with
    local temp_array_ref="${array_name}[@]"
    local profiles=("${!temp_array_ref}")
    
    if [ "$count" -le "$max_display" ]; then
      echo "Profiles ${list_type}:"
      printf '  - %s\n' "${profiles[@]}"
    else
      echo "Profiles ${list_type} (showing first ${max_display} of ${count}):"
      printf '  - %s\n' "${profiles[@]:0:$max_display}"
      echo "  ... and $((count - max_display)) more"
    fi
  fi
}

# Main script execution
main() {
  # Ensure destination directory exists
  mkdir -p "${RT4K}profile/DV1/"

  # Process cores and profiles
  process_cores "Console" "_Console/" "$PRF_CONSOLE" "rbf" "_"
  process_cores "Console" "_Console/" "$PRF_CONSOLE" "mgl" ""
  
  # Arcade: creates profiles based on the setname field of each mra file in _Arcade/
  process_arcade_cores
  
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

  # Show detailed profile lists
  show_profile_summary "created" "$created_profiles" created_profile_names
  show_profile_summary "overwritten" "$overwritten_profiles" overwritten_profile_names
  show_profile_summary "skipped" "$skipped_profiles" skipped_profile_names
}

# Execute main function
main
