# ============================================================
# CARDIOEDGE GPIO - STANDALONE AXI4-LITE VERIFICATION
#
# Run from:
#   /home/student/Documents/HONOURS_CBP_CARDIOEDGE/run
# ============================================================

# GPIO simulation-only pull-up/pull-down model
+define+SIMULATION

# GPIO RTL
../rtl/gpio/gpio_bit.sv
../rtl/gpio/gpio_wrapper.sv
../rtl/gpio/gpio_regs.sv
../rtl/gpio/gpio_axi.sv

# Common AXI4-Lite register-bus adapter (used internally by gpio_axi)
../rtl/common/axi4lite_slave_adapter.sv

# GPIO AXI standalone testbench
../tb/tb_gpio_axi.sv
