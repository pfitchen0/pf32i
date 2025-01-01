import binascii
import subprocess
from elftools.elf.elffile import ELFFile

HEX_FILE = "firmware.hex"


def format_elf(elf_file: str) -> None:
    with open(elf_file, "rb") as e:
        elf = ELFFile(e)
        memory = b"\x00" * 0x4000
        for segment in elf.iter_segments():
            if segment.header.p_paddr < 0x80000000:  # this segment is a header.
                continue
            addr = segment.header.p_paddr - 0x80000000
            data = segment.data()
            memory = memory[:addr] + data + memory[addr + len(data) :]
            with open(HEX_FILE, "wb") as h:
                h.write(
                    b"\n".join(
                        [
                            binascii.hexlify(memory[i : i + 4][::-1])
                            for i in range(0, len(memory), 4)
                        ]
                    )
                )


def simulate(elf_file: str) -> str:
    format_elf(elf_file=elf_file)
    stdout = subprocess.run(
        ["sh", "iverilog.sh", HEX_FILE], capture_output=True
    ).stdout.decode()
    # _ = subprocess.run(["rm", HEX_FILE], capture_output=True)
    return stdout
