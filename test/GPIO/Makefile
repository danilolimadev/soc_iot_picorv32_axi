
TOOLCHAIN = riscv64-unknown-elf
CC  = $(TOOLCHAIN)-gcc
OBJCOPY = $(TOOLCHAIN)-objcopy

CFLAGS = -march=rv32i -mabi=ilp32 -O2 -g \
         -ffreestanding -nostdlib -nostartfiles \
         -Wall

LDFLAGS = -Wl,-T,../common/linker.ld -Wl,--gc-sections

all: firmware.hex

firmware.elf: ../common/crt0.S main.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ ../common/crt0.S main.c

firmware.bin: firmware.elf
	$(OBJCOPY) -O binary $< $@

firmware.hex: firmware.bin
	python3 ../common/bin2memh_word32.py firmware.bin firmware.hex

clean:
	rm -f firmware.elf firmware.bin firmware.hex

