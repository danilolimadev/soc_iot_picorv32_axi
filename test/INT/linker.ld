ENTRY(start_func)

MEMORY
{
  RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 64K
}

SECTIONS
{

  . = ORIGIN(RAM);

  .init :
  {
    KEEP(*(.init))
    KEEP(*(.init.*))
  } > RAM

  .text : {
    *(.text*)
    *(.rodata*)
  } > RAM

  .data : { *(.data*) } > RAM
  .bss  : { *(.bss*) *(COMMON) } > RAM

  . = ALIGN(16);
  _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
