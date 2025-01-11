CC = riscv64-unknown-elf-gcc
AS = riscv64-unknown-elf-as
LD = riscv64-unknown-elf-ld
PY = python

CCFLAGS = -fno-pic -march=rv32i -mabi=ilp32 -fno-stack-protector -w -Wl,--no-relax
ASFLAGS = -march=rv32i -mabi=ilp32 -mno-relax
LDFLAGS = -melf32lriscv -nostdlib

SOURCES = main.c start.s
OBJECTS = start.o main.o
LDSCRIPT = link.ld
ELF = firmware.elf
HEX = firmware.hex

all: $(HEX)

%.o: %.c
	$(CC) $(CCFLAGS) $< -o $@

%.o: %.s
	$(AS) $(ASFLAGS) $< -o $@

$(ELF): $(OBJECTS)
	$(LD) $(CCFLAGS) -o $@ -T $(LDSCRIPT) $(OBJECTS) $(LDFLAGS)

$(HEX): $(ELF)
	$(PY) utils.py --format_elf $(ELF)

clean:
	rm -f $(OBJECTS) $(ELF) $(HEX)

simulate: $(HEX)
	sh simulate.sh

.PHONY: all clean simulate
