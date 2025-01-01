#!/bin/bash

hex_file="firmware.hex"

if [[ ! -f "$hex_file" ]]; then
    echo "Error: File '$hex_file' does not exist."
    exit 1
fi

iverilog testbench.v pf32i.v
vvp a.out
rm -f a.out