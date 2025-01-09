AS = riscv64-unknown-elf-as
LD = riscv64-unknown-elf-ld
PY = python

ASFLAGS = -march=rv32i -mabi=ilp32 -mno-relax
LDFLAGS = -melf32lriscv -nostdlib

SOURCES = firmware.s
OBJECTS = $(SOURCES:.s=.o)  # replace .s with .o
LDSCRIPT = link.ld
ELF = firmware.elf
HEX = firmware.hex

all: $(HEX)

%.o: %.asm
	$(AS) $(ASFLAGS) $< -o $@

$(ELF): $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) -o $@ -T $(LDSCRIPT)

$(HEX): $(ELF)
	$(PY) utils.py --format_elf $(ELF)

clean:
	rm -f $(OBJECTS) $(ELF) $(HEX)

.PHONY: all clean