/* ============================================================================
 * cardioedge.ld — Authoritative Linker Script for CARDIOEDGE RISC-V SoC
 * Target: Western Digital VeeR EL2 (RV32IMC)
 * 
 * Memory Layout:
 *   IMEM (Instruction SRAM): Base 0x00000000, Size 64 KB (0x00000000 - 0x0000FFFF)
 *   DMEM (Data SRAM)       : Base 0x00010000, Size 64 KB (0x00010000 - 0x0001FFFF)
 * 
 * Stack Top: 0x00018000 (32 KB allocated for BSS/Data, 32 KB for Stack/Scratchpad)
 * ============================================================================ */

OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
    IMEM (rx)  : ORIGIN = 0x00000000, LENGTH = 64K
    DMEM (rwx) : ORIGIN = 0x00010000, LENGTH = 64K
}

SECTIONS
{
    /* ------------------------------------------------------------------------
     * Code and Read-Only Data in IMEM
     * ------------------------------------------------------------------------ */
    .text : {
        . = ALIGN(4);
        KEEP(*(.text.init))          /* Startup code placed at reset vector 0x0 */
        *(.text .text.*)             /* Application code */
        *(.rodata .rodata.*)         /* Constants, strings */
        *(.srodata .srodata.*)
        . = ALIGN(4);
        _etext = .;
    } > IMEM

    /* ------------------------------------------------------------------------
     * Initialized Data (VMA in DMEM, LMA in IMEM)
     * ------------------------------------------------------------------------ */
    .data : {
        . = ALIGN(4);
        _sdata = .;
        __global_pointer$ = . + 0x800; /* Relaxed addressing pointer */
        *(.data .data.*)
        *(.sdata .sdata.*)
        . = ALIGN(4);
        _edata = .;
    } > DMEM AT > IMEM
    
    _sidata = LOADADDR(.data);

    /* ------------------------------------------------------------------------
     * Uninitialized Data (Zero-filled by startup code)
     * ------------------------------------------------------------------------ */
    .bss (NOLOAD) : {
        . = ALIGN(4);
        _sbss = .;
        *(.sbss .sbss.*)
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
    } > DMEM

    /* ------------------------------------------------------------------------
     * Stack Allocation in Upper DMEM
     * ------------------------------------------------------------------------ */
    .stack (NOLOAD) : {
        . = ALIGN(16);
        _stack_bottom = .;
        . = ORIGIN(DMEM) + 0x8000;   /* Allocate up to 0x00018000 */
        _stack_top = .;
    } > DMEM

    _end = .;

    /* Discard C++ exception handling frames */
    /DISCARD/ : {
        *(.eh_frame)
        *(.comment)
    }
}
