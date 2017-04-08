MEMORY
{
    ROM (rx) : ORIGIN = 0x00000000, LENGTH = 16K
    RAM (xrw) : ORIGIN = 0x00020000, LENGTH = 64K
}

SECTIONS { 
  .vectors 0x00 : { *(.vectors) } > ROM
  .text 0x200 : { *(.text) } > ROM
  .data : { *(.data) } > RAM AT>ROM
  .bss :  { *(.bss)  *(COMMON) } > RAM
}

OUTPUT_ARCH(m68k:68000)
