#!/bin/bash

show_help() {
  echo "This script loads a hex array into the pf32i.v memory module, then simulates running the program with iverilog."
  echo "Usage:"
  echo "  sh iverilog.sh firmware.hex"
  echo "Options:"
  echo "  -h, --help  Display this help message"
}

if [[ $# -eq 0 ]] || [[ $# -gt 1 ]]; then
  show_help
  exit 1
fi

case "$1" in
  -h|--help)
    show_help
    exit 0
    ;;
  *)
    hex_file="$1"

    if [[ ! -f "$hex_file" ]]; then
      echo "Error: File '$hex_file' does not exist."
      exit 1
    fi

    iverilog testbench.v pf32i.v
    vvp a.out
    rm -f a.out
    ;;
esac
