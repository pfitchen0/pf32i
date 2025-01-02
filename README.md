# pf32i: RISC-V RV32I Processor

## Overview

`pf32i.v` is a super simple, low performance - but hopefully easy to understand - RISC-V RV32I multi-cycle processor implementation. It is *heavily* inspired by other RV32I implementations such as the [FemtoRV32I](https://github.com/BrunoLevy/learn-fpga/blob/master/FemtoRV/TUTORIALS/FROM_BLINKER_TO_RISCV/README.md), [twitchcore](https://github.com/geohot/twitchcore/blob/master/README.md), and [picorv32](https://github.com/YosysHQ/picorv32). I highly recommend checking out each of these, particularly the [FemtoRV32I](https://github.com/BrunoLevy/learn-fpga/blob/master/FemtoRV/TUTORIALS/FROM_BLINKER_TO_RISCV/README.md) tutorial.

## Prerequisites

Clone this repository:

```
git clone https://github.com/pfitchen0/pf32i.git
cd pf32i
```

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

## Testing

Clone and build the official [`riscv-tests`](https://github.com/riscv-software-src/riscv-tests.git).

```
git clone https://github.com/riscv-software-src/riscv-tests.git
cd riscv-tests
git submodule update --init --recursive
autoconf
./configure
make
cd ..
```

The above commands will clone and build all of the RISC-V tests. For this RV32I processor, we only care about the `riscv-tests/isa/rv32ui-p*` tests. You should now see a list of compiled ELF files (first 4 bytes of each file are the ASCII characters for *EFL) and corresponding dissassembled `.dump` files for each unit test under `riscv-tests/isa/riscv-tests/isa/rv32ui-p*`:

```
ls -l riscv-tests/isa/rv32ui-p*
```

Take a look at one of the `.dump` files, `riscv-tests/isa/rv32ui-p-add.dump` for example. There are `<pass>` and `<fail>` sections, which clearly show the pass/fail critieria:

```
8000066c <fail>:
8000066c:	0ff0000f          	fence
80000670:	00018063          	beqz	gp,80000670 <fail+0x4>
80000674:	00119193          	sll	gp,gp,0x1
80000678:	0011e193          	or	gp,gp,1
8000067c:	05d00893          	li	a7,93
80000680:	00018513          	mv	a0,gp
80000684:	00000073          	ecall

80000688 <pass>:
80000688:	0ff0000f          	fence
8000068c:	00100193          	li	gp,1
80000690:	05d00893          	li	a7,93
80000694:	00000513          	li	a0,0
80000698:	00000073          	ecall
```

If the processor hits an ECALL instruction and register `a7` contains 93, this signals that the test has completed. If register `gp` is 1 and `a0` is 0, then the test passed! If not, then we can see which test failed from the `gp` register. Take a look at test #38 in `riscv-tests/isa/rv32ui-p-add.dump`:

```
80000650 <test_38>:
80000650:	02600193          	li	gp,38
80000654:	01000093          	li	ra,16
80000658:	01e00113          	li	sp,30
8000065c:	00208033          	add	zero,ra,sp
80000660:	00000393          	li	t2,0
80000664:	00701463          	bne	zero,t2,8000066c <fail>
80000668:	02301063          	bne	zero,gp,80000688 <pass>
```

The first thing this test does - or any test for that matter - is load the test number into the `gp` register. In the `<fail>` routine, `gp` gets shifted left with a 1 pushed into the lower bit. We can recover the failed test number by shifting `gp` right one bit.

`pf32i.v` checks for test completion in the EXECUTE stage, and prints out the test status:

```
// Exit state is ECALL with code 93 in a7
if (ecall && (/*a7*/regs[17] == 93)) begin
    // Pass
    if ((/*gp*/regs[3] == 1) && (/*a0*/regs[10] == 0)) begin
        $display("pc = 0x%04x", pc);
        $display("PASS");
    // Fail
    end else begin
        $display("test %0d failed", /*gp*/regs[3] >> 1);
        $display("pc = 0x%04x", pc);
        $display("FAIL");
    end
    $finish();
end
```

But how do we actually run these tests? Run the `test_pf32i.py`. `test_pf32i.py` formats each pre-compiled test into a hex array that can be loaded into the verilog memory module with `$readmemh()`. The `pf32i.v` implementation then checks for test completion in the EXECUTE stage and reports PASS/FAIL.

You can use the `test_pf32i.py` script to run all test cases at once.\*

\* *The `riscv-tests/isa/rv32ui-p-ma_data` test is skipped as it covers unaligned (or mis-aligned) loads and stores that cross word boundaries. `pf32i` doesn't support this (yet), but per the RISC-V specifications, mis-aligned loads/stores are optional. We can specify that mis-aligned memory access across word boundaries is not supported to the compiler with the [`-mstrict-align`](https://gcc.gnu.org/onlinedocs/gcc/RISC-V-Options.html) flag.*

## Simulation

Run the `simulate.py` python script to convert your elf to a hex array for `$readmemh` and then use icarus-verilog to simulate the design.