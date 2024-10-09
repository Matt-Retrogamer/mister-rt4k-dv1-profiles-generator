
# MiSTer RT4K DV1 Profiles Generator

## Description

The **MiSTer RT4K DV1 Profiles Generator** is a Bash script designed to automate the replication of profile files (.rt4) for the RetroTINK 4K device, specifically for use with the MiSTer FPGA system. This script simplifies the process of generating profiles for various MiSTer cores, ensuring that your RetroTINK 4K is correctly configured to display them.

By scanning your MiSTer directories for console, arcade, computer, and utility cores, the script creates corresponding profile files in the `profiles/DV1/` directory on your RetroTINK 4K SD card. It handles special cases, allows for additional custom profiles, and includes options for customization and verbose output.

## Features

- **Automated Profile Generation**: Scans MiSTer core directories and creates corresponding .rt4 profiles.
- **Supports Multiple Core Types**: Handles console, arcade, computer, and utility cores.
- **Customizable Base Profiles**: Allows you to specify base profiles for different core types.
- **Additional Arcade Profiles**: Processes additional arcade profiles listed in a text file.
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
- [Base Profiles](#base-profiles)
- [Additional Arcade Profiles](#additional-arcade-profiles)
- [Output](#output)
- [Logging and Verbose Mode](#logging-and-verbose-mode)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [Todo](#todo)
- [License](#license)
- [Acknowledgements](#acknowledgements)
- [Contact](#contact)

## Requirements

- **Operating System**: Linux or any Unix-like system with Bash.
- **Bash Version**: Bash 3.0 or higher.
- **Dependencies**: None (uses standard Unix utilities like `cp`, `mv`, etc.).
- **RetroTink 4K**: Up to date SDCard with the latest profiles installed:
  * The latest Kuro Houou profiles can be found here: https://drive.google.com/drive/folders/1zxQqn36P6QPx3mu83SuNplTbbwID1YA2
  * The latest Wobbling Pixels profiles can be found here: https://drive.google.com/drive/folders/1vMn27wOXiCCT9tSqCKr89IhdP3nXP-V5
  * You can use the tools avalaible in this project to inject them into your RT4K SDCard
- **MiSTer FPGA**: Up to date SDCard with the latest core updates.

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
- `-m`, `--mister PATH` : Set MiSTer root path.

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
4. **Display Help Message**:
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

## Troubleshooting

- **Base Profile Not Found**: Verify that the path to the base profile is correct and that the file exists.
- **Permission Denied**: Ensure that you have the necessary permissions to read from the source directories and write to the destination directory.
- **No Profiles Generated**: Check that the source directories contain the expected `.rbf` or `.zip` files.
- **Script Exits Immediately**: Ensure you are using Bash 3.0 or higher.

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

- [ ] Fix script execution on Linux bash (works only on mac bash currently)
- [ ] Feature: add SSH remote retrieval of the core names on the MiSTer (allows execution without removing the SD card from the MiSTer)
- [ ] Feature: Add DV1 Arcade profiles management. Read MiSTer MRA file and create DV1 Arcade list based on `<setname>` (e.g., `sfa2.zip` > `sfa2.rt4`)

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Acknowledgements

- **MiSTer FPGA Community**: For their work on open-source FPGA implementations.
- **RetroTINK 4K Team**: For providing a versatile upscaler.
- **Contributors**: Thanks to everyone who has contributed to this project.

## Contact

For questions, suggestions, or support, please open an issue on the GitHub repository.
