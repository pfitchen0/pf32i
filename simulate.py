"""Simulate running an ELF file on pf32i.v."""

import argparse

import utils


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        "Simulate running an ELF file on pf32i.v."
    )
    parser.add_argument(
        "--elf", required=True, type=str, help="Path to the ELF file to format."
    )
    args = parser.parse_args()

    stdout = utils.simulate(args.elf)
    print(stdout)
