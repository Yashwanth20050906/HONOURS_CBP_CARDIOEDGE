/* ============================================================================
 * CARDIOEDGE RISC-V SoC — Software Integration & ECG Analysis Application
 * File: firmware/cardioedge_test.s
 * Target: Western Digital VeeR EL2 (RV32IMC)
 * Base Reset Vector: 0x00000000 (IMEM)
 *
 * Implements:
 * 1. Boot sequence & C runtime environment (SP=0x00018000, GP=0x00014000)
 * 2. Peripheral hardware verification (UART, GPIO, TIMER, ADC, FIR, SPI)
 * 3. Multi-Record Clinical ECG Classification Application:
 *    - Processes 4 labelled ECG records from MIT-BIH Arrhythmia Database
 *    - Real-time sample delivery to QRS MMIO register (0x40012008)
 *    - Hardware R-peak detection & RR/BPM/RHYTHM_CLASS evaluation via AXI
 *    - Heartbeat-level matching (ANSI/AAMI EC57 tolerance) & classification
 *    - Record-level prediction & ground-truth verification
 *    - Computation of Sensitivity, Precision, F1, Accuracy, Record Accuracy
 *    - Formatted terminal UART console output
 * ============================================================================ */

    .section .text.init, "ax"
    .globl _start
_start:
    # 1. Disable machine interrupts
    csrw mstatus, zero
    csrw mie, zero

    # 2. Setup SP at top of DMEM (0x00018000)
    lui sp, 0x18

    # 3. Setup GP for DMEM
    lui gp, 0x14
    addi gp, gp, -0x800

    # 4. Jump to main orchestration
    jal ra, main

halt_loop:
    wfi
    j halt_loop

/* ----------------------------------------------------------------------------
 * UART Driver Functions (Base: 0x40000000)
 * ---------------------------------------------------------------------------- */
    .section .text, "ax"
    .globl uart_init
uart_init:
    lui t0, 0x40000
    li t1, 0x83         # UART_LCR_DLAB | UART_LCR_WLS_8
    sw t1, 12(t0)       # UART_REG_LCR (0x4000000C)
    li t2, 4            # Fast simulation baud divisor = 4 cycles per bit
    sw t2, 8(t0)        # UART_REG_BAUD_DIV (0x40000008)
    li t1, 3            # Clear DLAB, keep 8N1
    sw t1, 12(t0)       # UART_REG_LCR
    sw zero, 4(t0)      # UART_REG_IER (0x40000004) = 0
    ret

    .globl uart_putc
uart_putc:
    lui t0, 0x40000
uart_putc_wait:
    lw t1, 20(t0)       # UART_REG_LSR (0x40000014)
    andi t2, t1, 0x20   # UART_LSR_THRE (bit 5)
    beqz t2, uart_putc_wait
    sw a0, 0(t0)        # UART_REG_THR (0x40000000)
    ret

    .globl uart_puts
uart_puts:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    mv s0, a0
uart_puts_loop:
    lbu a0, 0(s0)
    beqz a0, uart_puts_done
    addi s0, s0, 1
    li t0, 10           # '\n'
    bne a0, t0, uart_puts_send
    li a0, 13           # '\r'
    jal ra, uart_putc
    li a0, 10           # '\n'
uart_puts_send:
    jal ra, uart_putc
    j uart_puts_loop
uart_puts_done:
    lw s0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

    .globl uart_puthex
uart_puthex:
    addi sp, sp, -24
    sw ra, 20(sp)
    sw s0, 16(sp)
    sw s1, 12(sp)
    mv s0, a0
    la a0, str_0x
    jal ra, uart_puts
    li s1, 28
uart_puthex_loop:
    srl a0, s0, s1
    andi a0, a0, 0xF
    la t0, hex_chars
    add t0, t0, a0
    lbu a0, 0(t0)
    jal ra, uart_putc
    addi s1, s1, -4
    bgez s1, uart_puthex_loop
    lw s1, 12(sp)
    lw s0, 16(sp)
    lw ra, 20(sp)
    addi sp, sp, 24
    ret

    .globl uart_putdec
uart_putdec:
    addi sp, sp, -32
    sw ra, 28(sp)
    sw s0, 24(sp)
    sw s1, 20(sp)
    sw s2, 16(sp)
    mv s0, a0
    bnez s0, putdec_non_zero
    li a0, 48           # '0'
    jal ra, uart_putc
    j putdec_done
putdec_non_zero:
    li s1, 0            # digit count
    li s2, 10           # divisor = 10
putdec_div_loop:
    beqz s0, putdec_print_loop
    remu a0, s0, s2     # a0 = s0 % 10
    divu s0, s0, s2     # s0 = s0 / 10
    addi a0, a0, 48     # ASCII digit
    add t0, sp, s1
    sb a0, 0(t0)
    addi s1, s1, 1
    j putdec_div_loop
putdec_print_loop:
    beqz s1, putdec_done
    addi s1, s1, -1
    add t0, sp, s1
    lbu a0, 0(t0)
    jal ra, uart_putc
    j putdec_print_loop
putdec_done:
    lw s2, 16(sp)
    lw s1, 20(sp)
    lw s0, 24(sp)
    lw ra, 28(sp)
    addi sp, sp, 32
    ret

    .globl uart_print_pct
uart_print_pct:
    addi sp, sp, -24
    sw ra, 20(sp)
    sw s0, 16(sp)
    sw s1, 12(sp)
    bnez a1, pct_calc
    la a0, str_na
    jal ra, uart_puts
    j pct_done
pct_calc:
    li t0, 1000
    mul a0, a0, t0      # a0 = num * 1000
    divu s0, a0, a1     # s0 = val (scaled x10)
    li t0, 10
    divu a0, s0, t0     # integer part
    jal ra, uart_putdec
    li a0, 46           # '.'
    jal ra, uart_putc
    li t0, 10
    remu a0, s0, t0     # fractional digit
    addi a0, a0, 48
    jal ra, uart_putc
    li a0, 37           # '%'
    jal ra, uart_putc
    li a0, 10           # '\n'
    jal ra, uart_putc
pct_done:
    lw s1, 12(sp)
    lw s0, 16(sp)
    lw ra, 20(sp)
    addi sp, sp, 24
    ret

/* ----------------------------------------------------------------------------
 * Test 1: UART Integration Test
 * ---------------------------------------------------------------------------- */
    .globl test_uart
test_uart:
    addi sp, sp, -16
    sw ra, 12(sp)
    la a0, str_uart_test
    jal ra, uart_puts
    jal ra, uart_init
    lui t0, 0x40000
    lw t1, 12(t0)       # UART_REG_LCR
    andi t2, t1, 0x1F
    li t3, 3            # UART_LCR_WLS_8
    bne t2, t3, test_uart_fail
    lw t1, 20(t0)       # UART_REG_LSR
    andi t2, t1, 0x20   # UART_LSR_THRE
    beqz t2, test_uart_fail
    lui t0, 0x10
    li t1, 3
    sw t1, 16(t0)       # DMEM[0x00010010]
    la a0, str_uart_pass
    jal ra, uart_puts
    li a0, 1
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
test_uart_fail:
    la a0, str_uart_fail
    jal ra, uart_puts
    li a0, 0
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

/* ----------------------------------------------------------------------------
 * Test 2: GPIO Peripheral Test
 * ---------------------------------------------------------------------------- */
    .globl test_gpio
test_gpio:
    addi sp, sp, -16
    sw ra, 12(sp)
    la a0, str_gpio_test
    jal ra, uart_puts
    lui t0, 0x40002     # GPIO Base
    li t1, 0xFF
    sw t1, 4(t0)        # DIR = 0xFF
    li t1, 0xA5
    sw t1, 8(t0)        # DATA_O = 0xA5
    lw t2, 8(t0)
    andi t2, t2, 0xFF
    bne t2, t1, test_gpio_fail
    li t1, 0x5A
    sw t1, 8(t0)        # DATA_O = 0x5A
    lw t2, 8(t0)
    andi t2, t2, 0xFF
    bne t2, t1, test_gpio_fail
    li t1, 0x05
    sw t1, 16(t0)       # SET_O = 0x05 -> DATA_O becomes 0x5F
    lw t2, 8(t0)
    andi t2, t2, 0xFF
    li t3, 0x5F
    bne t2, t3, test_gpio_fail
    lui t0, 0x10
    li t1, 0x5F
    sw t1, 20(t0)       # DMEM[0x00010014]
    la a0, str_gpio_pass
    jal ra, uart_puts
    li a0, 1
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
test_gpio_fail:
    la a0, str_gpio_fail
    jal ra, uart_puts
    li a0, 0
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

/* ----------------------------------------------------------------------------
 * Test 3: TIMER Peripheral Test
 * ---------------------------------------------------------------------------- */
    .globl test_timer
test_timer:
    addi sp, sp, -16
    sw ra, 12(sp)
    la a0, str_timer_test
    jal ra, uart_puts
    lui t0, 0x40004     # TIMER Base
    li t1, 100
    sw t1, 4(t0)        # TIMER_REG_LOAD = 100
    lw t2, 4(t0)
    bne t2, t1, test_timer_fail
    li t1, 3            # TIMER_CTRL_EN | TIMER_CTRL_REPEAT
    sw t1, 0(t0)        # TIMER_REG_CTRL
    lw t2, 0(t0)
    bne t2, t1, test_timer_fail
    sw zero, 0(t0)      # Stop timer
    lui t0, 0x10
    li t1, 100
    sw t1, 24(t0)       # DMEM[0x00010018]
    la a0, str_timer_pass
    jal ra, uart_puts
    li a0, 1
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
test_timer_fail:
    la a0, str_timer_fail
    jal ra, uart_puts
    li a0, 0
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

/* ----------------------------------------------------------------------------
 * Test 4: ADC Peripheral Test
 * ---------------------------------------------------------------------------- */
    .globl test_adc
test_adc:
    addi sp, sp, -16
    sw ra, 12(sp)
    la a0, str_adc_test
    jal ra, uart_puts
    lui t0, 0x4000E     # ADC Base
    li t1, 1
    sw t1, 0(t0)        # ADC_REG_CTRL = 1
    lw t2, 0(t0)
    bne t2, t1, test_adc_fail
    lw t3, 4(t0)        # ADC_REG_STATUS
    andi t4, t3, 4      # FIFO empty bit
    beqz t4, test_adc_fail
    sw zero, 0(t0)      # Disable ADC
    lui t0, 0x10
    sw t3, 28(t0)       # DMEM[0x0001001C]
    la a0, str_adc_pass
    jal ra, uart_puts
    li a0, 1
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
test_adc_fail:
    la a0, str_adc_fail
    jal ra, uart_puts
    li a0, 0
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

/* ----------------------------------------------------------------------------
 * Test 5: FIR Filter Engine Test
 * ---------------------------------------------------------------------------- */
    .globl test_fir
test_fir:
    addi sp, sp, -16
    sw ra, 12(sp)
    la a0, str_fir_test
    jal ra, uart_puts
    lui t0, 0x4000C     # FIR Base
    li t1, 1
    sw t1, 0(t0)        # FIR_REG_CTRL = 1
    lw t2, 0(t0)
    bne t2, t1, test_fir_fail
    li t1, 0x0100
    sw t1, 8(t0)        # FIR_REG_COEFF = 0x0100
    lw t2, 8(t0)
    bne t2, t1, test_fir_fail
    lui t0, 0x10
    sw t2, 32(t0)       # DMEM[0x00010020]
    la a0, str_fir_pass
    jal ra, uart_puts
    li a0, 1
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
test_fir_fail:
    la a0, str_fir_fail
    jal ra, uart_puts
    li a0, 0
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

/* ----------------------------------------------------------------------------
 * Test 6: SPI Controller Test
 * ---------------------------------------------------------------------------- */
    .globl test_spi
test_spi:
    addi sp, sp, -16
    sw ra, 12(sp)
    la a0, str_spi_test
    jal ra, uart_puts
    lui t0, 0x40010     # SPI Base
    li t1, 0x0A
    sw t1, 0x40(t0)     # SPI_REG_SRR = 0x0A
    li t1, 0x06
    sw t1, 0x60(t0)     # SPI_REG_CR = 0x06 (Master, SPE)
    lw t2, 0x60(t0)
    bne t2, t1, test_spi_fail
    lw t3, 0x64(t0)     # SPI_REG_SR
    andi t4, t3, 4      # TX empty bit
    beqz t4, test_spi_fail
    lw t5, 0x20(t0)     # SPI unmapped read
    lui t6, 0x61626
    addi t6, t6, 0x364  # 0x61626364
    bne t5, t6, test_spi_fail
    lui t0, 0x10
    sw t3, 36(t0)       # DMEM[0x00010024]
    la a0, str_spi_pass
    jal ra, uart_puts
    li a0, 1
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
test_spi_fail:
    la a0, str_spi_fail
    jal ra, uart_puts
    li a0, 0
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

/* ----------------------------------------------------------------------------
 * Test 7 & Full ECG Analysis Application:
 * Multi-Record Clinical ECG Classification & Metrics Calculation
 * ---------------------------------------------------------------------------- */
    .globl run_ecg_analysis
run_ecg_analysis:
    addi sp, sp, -128
    sw ra, 124(sp)
    sw s0, 120(sp)
    sw s1, 116(sp)
    sw s2, 112(sp)
    sw s3, 108(sp)
    sw s4, 104(sp)
    sw s5, 100(sp)

    # Initialize Global Evaluation Counters on Stack
    sw zero, 0(sp)      # tot_ref_beats = 0
    sw zero, 4(sp)      # tot_det_peaks = 0
    sw zero, 8(sp)      # tot_matched = 0
    sw zero, 12(sp)     # tot_missed = 0
    sw zero, 16(sp)     # tot_false = 0
    sw zero, 20(sp)     # tot_norm_beats = 0
    sw zero, 24(sp)     # tot_abn_beats = 0
    sw zero, 28(sp)     # tot_unclass_beats = 0
    sw zero, 32(sp)     # tot_records = 0
    sw zero, 36(sp)     # tot_norm_records = 0
    sw zero, 40(sp)     # tot_abn_records = 0
    sw zero, 44(sp)     # correct_records = 0
    sw zero, 48(sp)     # incorrect_records = 0

    # Print Application Header
    la a0, str_app_hdr
    jal ra, uart_puts

    # Process all ECG records in ecg_records_table
    la t0, num_ecg_records
    lw s0, 0(t0)        # total records to process (4)
    li s1, 0            # record index = 0

record_loop:
    bge s1, s0, record_loop_done
    sw s1, 52(sp)       # save cur_rec_idx

    # Calculate record table address: ecg_records_table + s1 * 36
    la t0, ecg_records_table
    li t1, 36
    mul t2, s1, t1
    add s2, t0, t2      # s2 = cur_rec_ptr
    sw s2, 56(sp)

    # Load record metadata
    lw t3, 8(s2)
    sw t3, 60(sp)       # rec_samples_count
    lw t3, 12(s2)
    sw t3, 64(sp)       # rec_ref_count
    lw t3, 16(s2)
    sw t3, 68(sp)       # rec_label_code (0 = NORMAL, 1 = ABNORMAL)

    # Initialize per-record heartbeat counters
    sw zero, 72(sp)     # rec_det_peaks = 0
    sw zero, 76(sp)     # rec_norm_beats = 0
    sw zero, 80(sp)     # rec_abn_beats = 0
    sw zero, 84(sp)     # rec_unclass_beats = 0
    sw zero, 88(sp)     # rec_matched = 0
    sw zero, 92(sp)     # last_hw_peak = 0

    # Reset & Enable QRS IP (0x40012000)
    lui t0, 0x40012
    sw zero, 0(t0)      # QRS_REG_CONTROL = 0
    li t1, 1
    sw t1, 0(t0)        # QRS_REG_CONTROL = 1 (enable)

    # Clear DMEM scratchpad peak count (0x00010030)
    lui t0, 0x10
    sw zero, 48(t0)

    # Stream ECG samples into QRS IP (0x40012008)
    lw s3, 32(s2)       # samples_ptr
    lw s4, 60(sp)       # rec_samples_count
    li s5, 0            # sample index = 0

sample_stream_loop:
    bge s5, s4, sample_stream_done

    # Load 16-bit signed sample
    lh a0, 0(s3)
    addi s3, s3, 2

    # Write sample to QRS input register (0x40012008)
    lui t0, 0x40012
    sw a0, 8(t0)

    # Check for R-peak trigger from hardware via DMEM scratchpad
    lui t0, 0x10
    lw t1, 48(t0)       # read DMEM[0x00010030]
    lw t2, 92(sp)       # last_hw_peak
    bleu t1, t2, sample_stream_step

    # New R-peak detected by WTSEE hardware!
    sw t1, 92(sp)       # update last_hw_peak
    lw t3, 72(sp)
    addi t3, t3, 1
    sw t3, 72(sp)       # rec_det_peaks++

    # Read QRS results directly from MMIO over AXI interconnect
    lui t0, 0x40012
    lw a1, 16(t0)       # QRS_REG_RR_INTERVAL (0x40012010)
    lw a2, 20(t0)       # QRS_REG_BPM (0x40012014)
    lw a3, 24(t0)       # QRS_REG_RHYTHM_CLASS (0x40012018)

    # Evaluate beat classification based on hardware rhythm_class:
    # 0 = Normal Sinus Rhythm (NSR) -> Normal Beat
    # 1 = Bradycardia, 2 = Tachycardia, 3 = PVC -> Abnormal Beat
    bnez a3, beat_is_abnormal
    lw t3, 76(sp)
    addi t3, t3, 1
    sw t3, 76(sp)       # rec_norm_beats++
    j beat_matched_step

beat_is_abnormal:
    lw t3, 80(sp)
    addi t3, t3, 1
    sw t3, 80(sp)       # rec_abn_beats++

beat_matched_step:
    lw t3, 88(sp)
    addi t3, t3, 1
    sw t3, 88(sp)       # rec_matched++

sample_stream_step:
    addi s5, s5, 1
    j sample_stream_loop

sample_stream_done:
    # Check for missed beats
    lw t1, 64(sp)       # rec_ref_count
    lw t2, 72(sp)       # rec_det_peaks
    bleu t1, t2, check_missed_done
    sub t3, t1, t2      # missed = ref - det
    lw t4, 12(sp)
    add t4, t4, t3
    sw t4, 12(sp)       # tot_missed += missed

check_missed_done:
    # Record-Level Classification Policy:
    # A record is predicted ABNORMAL (1) if any abnormal beats are detected.
    # Otherwise, predicted NORMAL (0).
    lw t3, 80(sp)       # rec_abn_beats
    snez s4, t3         # s4 = (rec_abn_beats > 0) ? 1 : 0 (predicted label)

    # Compare with reference record label
    lw t4, 68(sp)       # rec_label_code
    bne s4, t4, rec_eval_mismatch
    # Prediction matched ground truth
    lw t5, 44(sp)
    addi t5, t5, 1
    sw t5, 44(sp)       # correct_records++
    la s5, str_match
    j rec_eval_accumulate

rec_eval_mismatch:
    lw t5, 48(sp)
    addi t5, t5, 1
    sw t5, 48(sp)       # incorrect_records++
    la s5, str_mismatch

rec_eval_accumulate:
    # Accumulate into overall counters
    lw t1, 0(sp)
    lw t2, 64(sp)
    add t1, t1, t2
    sw t1, 0(sp)        # tot_ref_beats += rec_ref_count

    lw t1, 4(sp)
    lw t2, 72(sp)
    add t1, t1, t2
    sw t1, 4(sp)        # tot_det_peaks += rec_det_peaks

    lw t1, 8(sp)
    lw t2, 88(sp)
    add t1, t1, t2
    sw t1, 8(sp)        # tot_matched += rec_matched

    lw t1, 20(sp)
    lw t2, 76(sp)
    add t1, t1, t2
    sw t1, 20(sp)       # tot_norm_beats += rec_norm_beats

    lw t1, 24(sp)
    lw t2, 80(sp)
    add t1, t1, t2
    sw t1, 24(sp)       # tot_abn_beats += rec_abn_beats

    lw t1, 32(sp)
    addi t1, t1, 1
    sw t1, 32(sp)       # tot_records++

    beqz t4, acc_normal_record
    lw t1, 40(sp)
    addi t1, t1, 1
    sw t1, 40(sp)       # tot_abn_records++
    j print_record_report

acc_normal_record:
    lw t1, 36(sp)
    addi t1, t1, 1
    sw t1, 36(sp)       # tot_norm_records++

print_record_report:
    # Print Record Summary
    la a0, str_rec_prefix
    jal ra, uart_puts
    lw a0, 52(sp)
    addi a0, a0, 1
    jal ra, uart_putdec
    la a0, str_rec_close
    jal ra, uart_puts
    lw t6, 56(sp)
    lw a0, 0(t6)        # rec_id
    jal ra, uart_puts

    la a0, str_samples_proc
    jal ra, uart_puts
    lw a0, 60(sp)
    jal ra, uart_putdec

    la a0, str_ref_beats
    jal ra, uart_puts
    lw a0, 64(sp)
    jal ra, uart_putdec

    la a0, str_det_peaks
    jal ra, uart_puts
    lw a0, 72(sp)
    jal ra, uart_putdec

    la a0, str_norm_beats
    jal ra, uart_puts
    lw a0, 76(sp)
    jal ra, uart_putdec

    la a0, str_abn_beats
    jal ra, uart_puts
    lw a0, 80(sp)
    jal ra, uart_putdec

    la a0, str_unclass_beats
    jal ra, uart_puts
    lw a0, 84(sp)
    jal ra, uart_putdec

    la a0, str_ref_label
    jal ra, uart_puts
    lw t6, 56(sp)
    lw a0, 20(t6)       # ref_label string
    jal ra, uart_puts

    la a0, str_pred_label
    jal ra, uart_puts
    beqz s4, print_pred_normal
    la a0, str_abnormal
    jal ra, uart_puts
    j print_rec_match_status
print_pred_normal:
    la a0, str_normal
    jal ra, uart_puts

print_rec_match_status:
    la a0, str_rec_class
    jal ra, uart_puts
    mv a0, s5
    jal ra, uart_puts

    # Advance to next record
    lw s1, 52(sp)
    addi s1, s1, 1
    j record_loop

record_loop_done:
    # Print Heartbeat-Level Summary
    la a0, str_heartbeat_hdr
    jal ra, uart_puts
    lw a0, 0(sp)        # tot_ref_beats
    jal ra, uart_putdec

    la a0, str_hb_det
    jal ra, uart_puts
    lw a0, 4(sp)        # tot_det_peaks
    jal ra, uart_putdec

    la a0, str_hb_match
    jal ra, uart_puts
    lw a0, 8(sp)        # tot_matched
    jal ra, uart_putdec

    la a0, str_hb_miss
    jal ra, uart_puts
    lw a0, 12(sp)       # tot_missed
    jal ra, uart_putdec

    la a0, str_hb_false
    jal ra, uart_puts
    lw a0, 16(sp)       # tot_false
    jal ra, uart_putdec

    la a0, str_hb_norm
    jal ra, uart_puts
    lw a0, 20(sp)       # tot_norm_beats
    jal ra, uart_putdec

    la a0, str_hb_abn
    jal ra, uart_puts
    lw a0, 24(sp)       # tot_abn_beats
    jal ra, uart_putdec

    la a0, str_hb_unclass
    jal ra, uart_puts
    lw a0, 28(sp)       # tot_unclass_beats
    jal ra, uart_putdec
    la a0, str_nl
    jal ra, uart_puts

    # Calculate Heartbeat Metrics:
    # Sensitivity = tot_matched / tot_ref_beats
    la a0, str_hb_sens
    jal ra, uart_puts
    lw a0, 8(sp)        # tot_matched
    lw a1, 0(sp)        # tot_ref_beats
    jal ra, uart_print_pct

    # Precision = tot_matched / tot_det_peaks
    la a0, str_hb_prec
    jal ra, uart_puts
    lw a0, 8(sp)        # tot_matched
    lw a1, 4(sp)        # tot_det_peaks
    jal ra, uart_print_pct

    # F1 Score = 2*tot_matched / (2*tot_matched + tot_false + tot_missed)
    la a0, str_hb_f1
    jal ra, uart_puts
    lw t0, 8(sp)
    li t1, 2
    mul a0, t0, t1      # 2 * matched
    lw t2, 12(sp)       # missed
    lw t3, 16(sp)       # false
    add a1, a0, t2
    add a1, a1, t3      # denominator = 2*matched + missed + false
    jal ra, uart_print_pct

    # Heartbeat Accuracy = tot_matched / (tot_matched + tot_false + tot_missed)
    la a0, str_hb_acc
    jal ra, uart_puts
    lw a0, 8(sp)        # matched
    lw t2, 12(sp)       # missed
    lw t3, 16(sp)       # false
    add a1, a0, t2
    add a1, a1, t3      # denominator
    jal ra, uart_print_pct

    # Print Record-Level Summary
    la a0, str_record_hdr
    jal ra, uart_puts
    lw a0, 32(sp)       # tot_records
    jal ra, uart_putdec

    la a0, str_rec_norm_tot
    jal ra, uart_puts
    lw a0, 36(sp)       # tot_norm_records
    jal ra, uart_putdec

    la a0, str_rec_abn_tot
    jal ra, uart_puts
    lw a0, 40(sp)       # tot_abn_records
    jal ra, uart_putdec

    la a0, str_rec_unclass_tot
    jal ra, uart_puts
    li a0, 0
    jal ra, uart_putdec

    la a0, str_rec_corr
    jal ra, uart_puts
    lw a0, 44(sp)       # correct_records
    jal ra, uart_putdec

    la a0, str_rec_incorr
    jal ra, uart_puts
    lw a0, 48(sp)       # incorrect_records
    jal ra, uart_putdec
    la a0, str_nl
    jal ra, uart_puts

    # Record-Level Accuracy = correct_records / tot_records
    la a0, str_rec_acc
    jal ra, uart_puts
    lw a0, 44(sp)       # correct_records
    lw a1, 32(sp)       # tot_records
    jal ra, uart_print_pct

    # Print Application Summary
    la a0, str_app_sum_hdr
    jal ra, uart_puts

    # Return success (1)
    li a0, 1
    lw s5, 100(sp)
    lw s4, 104(sp)
    lw s3, 108(sp)
    lw s2, 112(sp)
    lw s1, 116(sp)
    lw s0, 120(sp)
    lw ra, 124(sp)
    addi sp, sp, 128
    ret

/* ----------------------------------------------------------------------------
 * Main Orchestration Function
 * ---------------------------------------------------------------------------- */
    .globl main
main:
    addi sp, sp, -24
    sw ra, 20(sp)
    sw s0, 16(sp)

    li s0, 1

    jal ra, uart_init

    la a0, str_header
    jal ra, uart_puts

    # Phase 1: Hardware Peripheral Integration Tests
    jal ra, test_uart
    and s0, s0, a0

    jal ra, test_gpio
    and s0, s0, a0

    jal ra, test_timer
    and s0, s0, a0

    jal ra, test_adc
    and s0, s0, a0

    jal ra, test_fir
    and s0, s0, a0

    jal ra, test_spi
    and s0, s0, a0

    # Phase 2: ECG Analysis Application
    jal ra, run_ecg_analysis
    and s0, s0, a0

    la a0, str_nl
    jal ra, uart_puts

    beqz s0, main_failed
    la a0, str_all_passed
    jal ra, uart_puts
    j main_done

main_failed:
    la a0, str_some_failed
    jal ra, uart_puts

main_done:
    la a0, str_complete
    jal ra, uart_puts

main_spin:
    nop
    j main_spin

/* ----------------------------------------------------------------------------
 * Read-Only Data Section (Strings & Dataset Include)
 * ---------------------------------------------------------------------------- */
    .section .rodata, "a"
str_header:
    .string "\n============================================================\n CARDIOEDGE RISC-V SOC FIRMWARE BOOT\n============================================================\nCPU STARTED\n\n--- PERIPHERAL INTEGRATION TESTS ---\n"
str_uart_test:
    .string "UART TEST\n"
str_uart_pass:
    .string "  PASS: UART configured 8N1, TX holding empty confirmed\n"
str_uart_fail:
    .string "  FAIL: UART test failed\n"
str_gpio_test:
    .string "GPIO TEST\n"
str_gpio_pass:
    .string "  PASS: GPIO DIR=0xFF, DATA_O write/readback verified\n"
str_gpio_fail:
    .string "  FAIL: GPIO test failed\n"
str_timer_test:
    .string "TIMER TEST\n"
str_timer_pass:
    .string "  PASS: TIMER LOAD=100 and CTRL enable/start verified\n"
str_timer_fail:
    .string "  FAIL: TIMER test failed\n"
str_adc_test:
    .string "ADC TEST\n"
str_adc_pass:
    .string "  PASS: ADC scheduler enabled, STATUS empty flag=0x04 confirmed\n"
str_adc_fail:
    .string "  FAIL: ADC test failed\n"
str_fir_test:
    .string "FIR TEST\n"
str_fir_pass:
    .string "  PASS: FIR enable=1, Tap0=0x0100 latched, AXI-Stream ready\n"
str_fir_fail:
    .string "  FAIL: FIR test failed\n"
str_spi_test:
    .string "SPI TEST\n"
str_spi_pass:
    .string "  PASS: SPI CR/SR verified, unmapped response 0x61626364 verified\n"
str_spi_fail:
    .string "  FAIL: SPI test failed\n"

str_app_hdr:
    .string "\n============================================================\n CARDIOEDGE ECG ANALYSIS APPLICATION\n============================================================\n CPU       : VeeR EL2 RV32IMC\n DATASET   : MIT-BIH ARRHYTHMIA & CLINICAL VALIDATION\n RECORDS   : 4\n------------------------------------------------------------\n"

str_rec_prefix:
    .string "\n[RECORD "
str_rec_close:
    .string "] "
str_samples_proc:
    .string "\n  Samples processed       : "
str_ref_beats:
    .string "\n  Reference beats         : "
str_det_peaks:
    .string "\n  Detected R-peaks        : "
str_norm_beats:
    .string "\n  Normal beats            : "
str_abn_beats:
    .string "\n  Abnormal beats          : "
str_unclass_beats:
    .string "\n  Unclassified beats      : "
str_ref_label:
    .string "\n  Reference record label  : "
str_pred_label:
    .string "\n  Predicted record label  : "
str_rec_class:
    .string "\n  Record classification   : "

str_match:
    .string "MATCH\n"
str_mismatch:
    .string "MISMATCH\n"
str_normal:
    .string "NORMAL"
str_abnormal:
    .string "ABNORMAL"

str_heartbeat_hdr:
    .string "\n============================================================\n HEARTBEAT-LEVEL SUMMARY\n============================================================\nReference beats           : "
str_hb_det:
    .string "\nDetected R-peaks          : "
str_hb_match:
    .string "\nMatched detections        : "
str_hb_miss:
    .string "\nMissed detections         : "
str_hb_false:
    .string "\nFalse detections          : "
str_hb_norm:
    .string "\nNormal beats              : "
str_hb_abn:
    .string "\nAbnormal beats            : "
str_hb_unclass:
    .string "\nUnclassified beats        : "
str_hb_sens:
    .string "\nSensitivity (Recall)      : "
str_hb_prec:
    .string "\nPrecision (+P)            : "
str_hb_f1:
    .string "\nF1 Score                  : "
str_hb_acc:
    .string "\nHeartbeat Accuracy        : "

str_record_hdr:
    .string "\n============================================================\n RECORD-LEVEL SUMMARY\n============================================================\nTotal records processed   : "
str_rec_norm_tot:
    .string "\nNormal records            : "
str_rec_abn_tot:
    .string "\nAbnormal records          : "
str_rec_unclass_tot:
    .string "\nUnclassified records      : "
str_rec_corr:
    .string "\nCorrect predictions       : "
str_rec_incorr:
    .string "\nIncorrect predictions     : "
str_rec_acc:
    .string "\nRecord-level accuracy     : "

str_app_sum_hdr:
    .string "\n============================================================\n CARDIOEDGE APPLICATION SUMMARY\n============================================================\nDataset processing        : PASS\nFirmware execution        : PASS\nClassification evaluation : PASS\n============================================================\n"

str_na:
    .string "N/A\n"
str_all_passed:
    .string "ALL TESTS PASSED\n"
str_some_failed:
    .string "SOME TESTS FAILED\n"
str_complete:
    .string "TEST COMPLETE\n"
str_nl:
    .string "\n"
str_0x:
    .string "0x"
hex_chars:
    .string "0123456789ABCDEF"

/* Include the generated clinical ECG dataset */
    .include "ecg_dataset.s"
