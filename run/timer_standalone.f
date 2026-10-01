# ============================================================
# CARDIOEDGE TIMER - STANDALONE AXI4-LITE VERIFICATION
#
# Run from:
#   /home/student/Documents/HONOURS_CBP_CARDIOEDGE/run
# ============================================================

# Timer RTL
../rtl/timer/timer_core.sv
../rtl/timer/timer_regs.sv
../rtl/timer/timer_axi.sv

# Common AXI4-Lite register-bus adapter (used internally by timer_axi)
../rtl/common/axi4lite_slave_adapter.sv

# Timer AXI standalone testbench
../tb/tb_timer_axi.sv
