#!/bin/bash

HEX_FILE="firmware.hex"

if [[ ! -f "$HEX_FILE" ]]; then
    echo "Error: File '$HEX_FILE' does not exist."
    exit 1
fi

iverilog testbench.v pf32i.v
vvp a.out
rm -f a.out