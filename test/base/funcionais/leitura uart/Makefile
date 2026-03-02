
TOOLCHAIN = riscv64-unknown-elf
CC  = $(TOOLCHAIN)-gcc
OBJCOPY = $(TOOLCHAIN)-objcopy
COMMON_DIR = ../../../../common

CFLAGS = -march=rv32i -mabi=ilp32 -O2 -g \
         -ffreestanding -nostdlib -nostartfiles \
         -Wall

LDFLAGS = -Wl,-T,$(COMMON_DIR)/linker.ld -Wl,--gc-sections

all: firmware.hex

firmware.elf: $(COMMON_DIR)/crt0.S main.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(COMMON_DIR)/crt0.S main.c

firmware.bin: firmware.elf
	$(OBJCOPY) -O binary $< $@

firmware.hex: firmware.bin
	python3 $(COMMON_DIR)/bin2memh_word32.py firmware.bin firmware.hex
	rm -f firmware.elf firmware.bin

clean:
	rm -f firmware.elf firmware.bin firmware.hex

