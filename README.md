# pf32i: RISC-V RV32I Processor

## Overview

`pf32i.v` is a super simple, low performance - but hopefully easy to understand - RISC-V RV32I multi-cycle processor implementation. It is inspired by other RV32I implementations such as the [FemtoRV32I](https://github.com/BrunoLevy/learn-fpga/blob/master/FemtoRV/TUTORIALS/FROM_BLINKER_TO_RISCV/README.md), [twitchcore](https://github.com/geohot/twitchcore/blob/master/README.md), and [picorv32](https://github.com/YosysHQ/picorv32).

## Prerequisites

Install iverilog/icarus-verilog for simulation:

```
brew install icarus-verilog
```

Install riscv-tools for building RISC-V binaries:

```
brew install riscv-tools
```

Install python dependencies to convert binaries into a hex array that we can load into our verilog memory module with `$readmemh()`:

```
pip install -r requirements.txt
```

## Simulation

Run the `simulate.sh` script to use icarus-verilog to simulate the design.

## Testing

Clone and build the official [`riscv-tests`](https://github.com/riscv-software-src/riscv-tests.git).

```
git clone https://github.com/riscv-software-src/riscv-tests.git
cd riscv-tests
git submodule update --init --recursive
autoconf
./configure
make
make install
cd ..
```