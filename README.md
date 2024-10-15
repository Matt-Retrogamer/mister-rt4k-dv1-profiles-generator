# MiSTer RT4K DV1 Profiles Generator

## Description

The **MiSTer RT4K DV1 Profiles Generator** is a Bash script designed to automate the replication of profile files (`.rt4`) for the RetroTINK 4K device, specifically for use with the MiSTer FPGA system. This script simplifies the process of generating profiles for various MiSTer cores, ensuring that your RetroTINK 4K is correctly configured to display them.

By scanning your MiSTer directories—either locally or remotely via SSH—for console, arcade, computer, and utility cores, the script creates corresponding profile files in the `profiles/DV1/` directory on your RetroTINK 4K SD card. It handles special cases, allows for additional custom profiles, and includes options for customization and verbose output.

## Features

- **Automated Profile Generation**: Scans MiSTer core directories and creates corresponding `.rt4` profiles.
- **Supports Multiple Core Types**: Handles console, arcade, computer, and utility cores.
- **SSH Remote Retrieval**: Optionally retrieves core names from a remote MiSTer device via SSH, eliminating the need to remove the SD card.
- **Default MiSTer Path and SSH User**: Assumes default MiSTer path `/media/fat/` and SSH user `root` if not specified.
- **Customizable Base Profiles**: Allows you to specify base profiles for different core types.
- **Per-Core Profile Overrides**: Supports custom per-core profiles through an override script (`profiles_config.sh`).
- **Additional Arcade Profiles**: Processes additional arcade profiles listed in a text file.
- **Force Overwrite**: Option to forcefully recreate and overwrite existing profiles with the `--force` flag.
- **Special Case Handling**: Includes specific handling for certain cores like GBA, GBC, and menu cores.
- **User-Friendly Options**: Command-line arguments and environment variables for easy customization.
- **Verbose Output**: Optional verbose mode for detailed logging.
- **Error Handling**: Checks for missing files and directories, providing meaningful error messages.

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Backup](#backup)
- [Usage](#usage)
  - [Syntax](#syntax)
  - [Options](#options)
  - [Examples](#examples)
- [Configuration](#configuration)
  - [Environment Variables](#environment-variables)
  - [Base Profiles](#base-profiles)
  - [Per-Core Profile Overrides](#per-core-profile-overrides)
- [Additional Arcade Profiles](#additional-arcade-profiles)
- [Output](#output)
- [Logging and Verbose Mode](#logging-and-verbose-mode)
- [SSH Key-Based Authentication Setup on MiSTer](#ssh-key-based-authentication-setup-on-mister)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
  - [Steps to Contribute](#steps-to-contribute)
- [Todo](#todo)
- [License](#license)
- [Acknowledgements](#acknowledgements)
- [Contact](#contact)

## Requirements

- **Operating System**: Linux or any Unix-like system with Bash.
- **Bash Version**: Bash 3.0 or higher.
- **Dependencies**: None (uses standard Unix utilities like `cp`, `mv`, etc.).
- **SSH Access** (optional): For remote retrieval of core names, SSH access to the MiSTer device is required.
  - **SSH Keys**: Recommended for password-less authentication.
- **RetroTINK 4K**: Up-to-date SD card with the latest profiles installed:
  - **Kuro Houou Profiles**: [Google Drive Link](https://drive.google.com/drive/folders/1zxQqn36P6QPx3mu83SuNplTbbwID1YA2)
  - **Wobbling Pixels Profiles**: [Google Drive Link](https://drive.google.com/drive/folders/1vMn27wOXiCCT9tSqCKr89IhdP3nXP-V5)
- **MiSTer FPGA**: Up-to-date SD card with the latest core updates.

## Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Matt-Retrogamer/mister-rt4k-dv1-profiles-generator.git
   ```
2. **Navigate to the Directory**:
   ```bash
   cd mister-rt4k-dv1-profiles-generator
   ```
3. **Make the Script Executable**:
   ```bash
   chmod +x generate_rt4k_mister_dv1_profiles.sh
   ```

## Backup

- **Backup your SD cards** before running the script(s).

## Usage

### Syntax

   ```bash
   ./generate_rt4k_mister_dv1_profiles.sh [options]
   ```

### Options

- `-h`, `--help` : Show help message and exit.
- `-v`, `--verbose` : Enable verbose output.
- `-r`, `--rt4k PATH` : Set RetroTINK 4K SD card root path.
- `-m`, `--mister PATH` : Set MiSTer root path (local path or SSH URL).
- `-f`, `--force` : Force overwrite of existing profiles.

## Examples

1. **Basic Usage with Default Paths**:
   ```bash
   ./generate_rt4k_mister_dv1_profiles.sh
   ```

2. **Specify Paths via Command-Line Arguments**:
   ```bash
   ./generate_rt4k_mister_dv1_profiles.sh --rt4k /path/to/rt4k/ --mister /path/to/mister/
   ```

3. **Enable Verbose Output**:
   ```bash
   ./generate_rt4k_mister_dv1_profiles.sh --verbose
   ```

4. **Specify Remote MiSTer via SSH (using defaults)**:
   ```bash
   ./generate_rt4k_mister_dv1_profiles.sh --rt4k /media/rt4k/ --mister ssh://192.168.1.100
   ```
   - SSH user defaults to root.
   - MiSTer path defaults to /media/fat/.

5. **Specify SSH User and Host**:
   ```bash
   ./generate_rt4k_mister_dv1_profiles.sh --rt4k /media/rt4k/ --mister ssh://user@hostname
   ```

6. **Specify SSH User, Host, and Custom MiSTer Path**:
   ```bash
   ./generate_rt4k_mister_dv1_profiles.sh --rt4k /media/rt4k/ --mister ssh://user@hostname:/custom/path --verbose
   ```

7. **Force Overwrite of Existing Profiles**:
   ```bash
   ./generate_rt4k_mister_dv1_profiles.sh --force
   ```

8. **Display Help Message**:
   ```bash
   ./generate_rt4k_mister_dv1_profiles.sh --help
   ```

## Configuration

### Environment Variables

Alternatively, you can set the following environment variables to specify paths:
   ```bash
   export RT4K=/media/rt4k/
   export MISTER=/media/mister/
   ./generate_rt4k_mister_dv1_profiles.sh
   ```

### Base Profiles

Ensure that the base profile files exist at the specified locations on your RetroTINK 4K SD card:

- **Console Base Profile**:
   ```bash
   ${RT4K}profile/_CRT Emulation/Kuro Houou - CRT Model Emulation/JVC D-Series-D200 - 4K HDR.rt4
   ```
- **Arcade Base Profile**:
   ```bash
   ${RT4K}profile/_CRT Emulation/Kuro Houou - CRT Model Emulation/JVC D-Series-D200 - 4K HDR.rt4
   ```
- **GBA Base Profile**:
   ```bash
   ${RT4K}profile/Nintendo Switch/Billgonzo's GBC-GBA Profiles/Switch_GBA_13x.rt4
   ```
- **GBC Base Profile**:
   ```bash
   ${RT4K}profile/Nintendo Switch/Billgonzo's GBC-GBA Profiles/Switch_GBC_15x.rt4
   ```

### Per-Core Profile Overrides

The script allows you to define custom profiles for specific MiSTer cores by using the `profiles_config.sh` file. This file should be in the same directory as the main script and contains variable definitions for core-specific profiles.

To create per-core profile overrides, simply edit `profiles_config.sh` and add entries like the examples below:

```bash
# profiles_config.sh

# Define per-core profiles override
PRF_NES="${RT4K}profile/Consoles/NES_Specific_Profile.rt4"
PRF_SNES="${RT4K}profile/Consoles/SNES_Specific_Profile.rt4"
PRF_GENESIS="${RT4K}profile/Consoles/Genesis_Specific_Profile.rt4"
# Add more per-core profiles as needed
```

These definitions allow the script to use custom profiles for specific cores instead of the default base profile.

## Additional Arcade Profiles

If you have additional arcade profiles to generate, create a text file named `DV1_ARCADE.txt` in the same directory as the script. List the names of the arcade ROMs (without paths) you wish to generate profiles for, one per line.

Example `DV1_ARCADE.txt`:
   ```bash
   sfa2.zip
   msh.zip
   ssf2t.zip
   ```

## Output

The script will generate `.rt4` profile files in the following directory:
   ```bash
   ${RT4K}profile/DV1/
   ```

## Logging and Verbose Mode

- **Verbose Mode**: Use the `--verbose` or `-v` option to enable detailed output of the script’s actions.
- **Error Messages**: Any errors encountered will be displayed in the console, regardless of the verbosity setting.

## SSH Key-Based Authentication Setup on MiSTer

Below is a step-by-step guide on setting up SSH key-based authentication between your local machine and your MiSTer device.
This will allow you to SSH into your MiSTer without typing a password each time.

### Setting Up SSH Key-Based Authentication on MiSTer
For better security, it’s recommended to generate the SSH key pair on your local machine and copy the public key to the MiSTer device.
If you are familiar with ssh, please also define a pathphrase to be more secure.

#### Prerequisites

- **MiSTer IP Address**: For this example, we’ll use `192.168.0.119`.
- **Root Access**: You have root access to the MiSTer device.
- **Local Machine**: The computer from which you will SSH into the MiSTer.

#### Steps:

1. **Generate SSH Key Pair on Local Machine**
   ```bash
   ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
   ```

2. **When prompted, write it to a specific path and let the pathphrase empty**
   ```bash
   ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
   Generating public/private rsa key pair.
   Enter file in which to save the key (~/.ssh/id_rsa): ~/.ssh/id_rsa_mister
   Enter passphrase (empty for no passphrase):
   Enter same passphrase again:
   Your identification has been saved in ~/.ssh/id_rsa_mister
   Your public key has been saved in ~/.ssh/id_rsa_mister
   ```

3. **Copy the Public Key to MiSTer (default root password is '1')**
   ```bash
   ssh-copy-id -i ~/.ssh/id_rsa_mister.pub root@192.168.0.119
   ```

4. **Configure SSH to Use the Private Key (If Not Using Default Key)**
   ```bash
   nano ~/.ssh/config
   ```

   ```bash
   Host mister
      HostName 192.168.0.119
      User root
      IdentityFile ~/.ssh/id_rsa_mister
   ```

5. **Test the SSH Connection**
   ```bash
   ssh mister
   ```

5. **Now you can run the tool simply like this (assuming the IP of your mister does not change ;)**
   ```bash
   ./generate_rt4k_mister_dv1_profiles.sh --verbose -m ssh://mister
   ```

Note: This method is secure because the private key remains on your local machine and is never exposed or transferred.

## Troubleshooting

- **SSH Connectivity Issues**:
  - Ensure you can SSH into your MiSTer device without password prompts.
  - Set up SSH keys for password-less authentication.

- **Base Profile Not Found**:
  - Verify that the path to the base profile is correct and that the file exists.

- **Permission Denied**:
  - Ensure that you have the necessary permissions to read from the source directories and write to the destination directory.

- **No Profiles Generated**:
  - Check that the source directories contain the expected `.rbf` or `.zip` files.

- **Script Exits Immediately**:
  - Ensure you are using Bash 3.0 or higher.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request if you have suggestions for improvements or find a bug.

### Steps to Contribute

1. **Fork the Repository**
2. **Create a Feature Branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Commit Your Changes**:
   ```bash
   git commit -am 'Add new feature'
   ```
4. **Push to the Branch**:
   ```bash
   git push origin feature/your-feature-name
   ```
5. **Open a Pull Request**

## TODO

- [x] Fix script execution on Linux Bash
- [x] Feature: add SSH remote retrieval of the core names on the MiSTer (allows execution without removing the SD card from the MiSTer)
- [x] Feature: Add DV1 Arcade profiles management. Read MiSTer MRA file and create DV1 Arcade list based on `<setname>` (e.g., `sfa2.zip` > `sfa2.rt4`)
- [x] Feature: Add override profiles option

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Acknowledgements

- **MiSTer FPGA Community**: For their work on open-source FPGA implementations.
- **RetroTINK 4K Team**: For providing a versatile upscaler.
- **Contributors**: Thanks to everyone who has contributed to this project.

## Contact

For questions, suggestions, or support, please open an issue on the GitHub repository.

