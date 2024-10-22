#!/usr/bin/env python3

import sys
import os
import struct

def main():
    if len(sys.argv) != 2:
        print("Usage: set_hdmi_input.py <profile_file>")
        sys.exit(1)
    profile_file = sys.argv[1]

    # Constants based on your Bash script
    header_size = 128                # Header size in bytes
    input_source_offset = 22505      # Offset in data section (excluding header)
    total_input_offset = header_size + input_source_offset

    input_source_hdmi_value = 0      # Value representing HDMI input

    try:
        with open(profile_file, 'r+b') as f:
            # Set the HDMI input value at the specified offset
            f.seek(total_input_offset)
            f.write(bytes([input_source_hdmi_value]))

            # Read the data starting from offset 128 to the end of the file
            f.seek(header_size)
            data = f.read()

            # Calculate the CRC16 using the provided algorithm
            crc = calculate_crc16(data)

            # Prepare the CRC bytes in little-endian order
            crc_low = crc & 0xFF
            crc_high = (crc >> 8) & 0xFF

            # Write the CRC back into the header at offset 32
            f.seek(32)
            f.write(bytes([crc_low, crc_high, 0x00, 0x00]))  # Append two zero bytes

    except Exception as e:
        print(f"Error processing file {profile_file}: {e}")
        sys.exit(1)

def calculate_crc16(data):
    crc = 0

    # CRC table as per the provided C code
    crc_table = [
        0x0000, 0x1021, 0x2042, 0x3063,
        0x4084, 0x50A5, 0x60C6, 0x70E7,
        0x8108, 0x9129, 0xA14A, 0xB16B,
        0xC18C, 0xD1AD, 0xE1CE, 0xF1EF,
    ]

    for byte in data:
        t_dat = byte

        # First iteration
        crc_index = ((crc >> 12) ^ (t_dat >> 4)) & 0x0F
        crc = crc_table[crc_index] ^ ((crc << 4) & 0xFFFF)

        # Second iteration
        crc_index = ((crc >> 12) ^ (t_dat & 0x0F)) & 0x0F
        crc = crc_table[crc_index] ^ ((crc << 4) & 0xFFFF)

    return crc & 0xFFFF

if __name__ == "__main__":
    main()