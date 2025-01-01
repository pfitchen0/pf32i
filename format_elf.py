"""Formats an ELF file into a hex array for $readmemh() in Verilog."""

import argparse
import binascii
from elftools.elf.elffile import ELFFile
import os

TMP_FOLDER = "tmp"


def format_elf(elf_file: str, hex_file) -> None:
    with open(elf_file, "rb") as e:
        elf = ELFFile(e)
        memory = b"\x00" * 0x4000
        for segment in elf.iter_segments():
            print(segment.header)
            if segment.header.p_paddr < 0x80000000:  # this segment is a header.
                continue
            addr = segment.header.p_paddr - 0x80000000
            data = segment.data()
            memory = memory[:addr] + data + memory[addr + len(data) :]
            with open(hex_file, "wb") as h:
                h.write(
                    b"\n".join(
                        [
                            binascii.hexlify(memory[i : i + 4][::-1])
                            for i in range(0, len(memory), 4)
                        ]
                    )
                )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        "Format ELF file as a hex array for $readmemh() in Verilog."
    )
    parser.add_argument(
        "--elf", required=True, type=str, help="Path to the ELF file to format."
    )
    parser.add_argument(
        "--hex", default="firmware.hex", type=str, help="Output file for the hex array."
    )
    args = parser.parse_args()

    format_elf(args.elf, args.hex)
