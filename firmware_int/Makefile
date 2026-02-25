
TOOLCHAIN = riscv64-unknown-elf
CC  = $(TOOLCHAIN)-gcc
OBJCOPY = $(TOOLCHAIN)-objcopy
COMMON_DIR = ../common

CFLAGS = -march=rv32i -mabi=ilp32 -O2 -g \
         -ffreestanding -nostdlib -nostartfiles \
         -Wall

LDFLAGS = -Wl,-T,$(COMMON_DIR)/linker.ld -Wl,--gc-sections

all: firmware.hex

firmware.elf: $(COMMON_DIR)/start.S main.c irq.c
	$(CC) $(CFLAGS) $(LDFLAGS) -I $(COMMON_DIR) -o $@ $(COMMON_DIR)/start.S main.c irq.c

firmware.bin: firmware.elf
	$(OBJCOPY) -O binary $< $@

firmware.hex: firmware.bin
	python3 $(COMMON_DIR)/bin2memh_word32.py firmware.bin firmware.hex
	rm -f firmware.elf firmware.bin
	
clean:
	rm -f firmware.elf firmware.bin firmware.hex

