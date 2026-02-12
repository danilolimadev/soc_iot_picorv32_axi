
TOOLCHAIN = riscv64-unknown-elf
CC  = $(TOOLCHAIN)-gcc
OBJCOPY = $(TOOLCHAIN)-objcopy
COMMON_DIR = ../../common

CFLAGS = -march=rv32i -mabi=ilp32 -O2 -g \
         -ffreestanding -nostdlib -nostartfiles \
         -Wall

LDFLAGS = -Wl,-T,./linker.ld -Wl,--gc-sections

all: firmware.hex

firmware.elf: startup.c tb_cpu_int.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ startup.c tb_cpu_int.c

firmware.bin: firmware.elf
	$(OBJCOPY) -O binary $< $@

firmware.hex: firmware.bin
	python3 $(COMMON_DIR)/bin2memh_word32.py firmware.bin firmware.hex

clean:
	rm -f firmware.elf firmware.bin firmware.hex

