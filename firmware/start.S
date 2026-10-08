/* ============================================================================
 * start.S — Bare-Metal Startup Code for Western Digital VeeR EL2 (RV32IMC)
 * Project: CARDIOEDGE SoC
 * 
 * Target: RV32IMC
 * Memory Map:
 *   IMEM: 0x00000000 - 0x0000FFFF (64 KB)
 *   DMEM: 0x00010000 - 0x0001FFFF (64 KB)
 * ============================================================================ */

    .section .text.init, "ax"
    .global _start
    .type _start, @function

_start:
    /* ------------------------------------------------------------------------
     * 1. Disable Machine-Mode Interrupts
     * ------------------------------------------------------------------------ */
    csrw mstatus, zero
    csrw mie, zero

    /* ------------------------------------------------------------------------
     * 2. Initialize Global Pointer (GP) for Relaxed Addressing
     * ------------------------------------------------------------------------ */
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop

    /* ------------------------------------------------------------------------
     * 3. Initialize Stack Pointer (SP) in Data SRAM (DMEM)
     * ------------------------------------------------------------------------ */
    la sp, _stack_top

    /* ------------------------------------------------------------------------
     * 4. Copy Initialized Data Section from Flash/IMEM (LMA) to DMEM (VMA)
     * ------------------------------------------------------------------------ */
    la t0, _sdata       /* Destination start in DMEM */
    la t1, _edata       /* Destination end in DMEM */
    la t2, _sidata      /* Source start in IMEM (LMA) */

    beq t0, t2, copy_data_done  /* Skip if LMA == VMA */
copy_data_loop:
    bge t0, t1, copy_data_done
    lw  t3, 0(t2)
    sw  t3, 0(t0)
    addi t0, t0, 4
    addi t2, t2, 4
    j copy_data_loop
copy_data_done:

    /* ------------------------------------------------------------------------
     * 5. Zero-Fill Uninitialized Data Section (.bss) in DMEM
     * ------------------------------------------------------------------------ */
    la t0, _sbss
    la t1, _ebss
zero_bss_loop:
    bge t0, t1, zero_bss_done
    sw  zero, 0(t0)
    addi t0, t0, 4
    j zero_bss_loop
zero_bss_done:

    /* ------------------------------------------------------------------------
     * 6. Call Application Main
     * ------------------------------------------------------------------------ */
    call main

    /* ------------------------------------------------------------------------
     * 7. Infinite Halt Trap Loop if main() ever returns
     * ------------------------------------------------------------------------ */
halt_loop:
    wfi
    j halt_loop

    .size _start, . - _start
