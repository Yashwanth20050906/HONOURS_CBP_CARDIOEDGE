#!/usr/bin/env bash
# ==============================================================================
# generate_hex.sh — Automated Firmware Compilation & Hex Generation Script
# Project: CARDIOEDGE SoC
# Target: Western Digital VeeR EL2 (RV32IMC)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

echo "=================================================================="
echo "    CARDIOEDGE Firmware Compilation & Hex Generation Utility"
echo "=================================================================="

# Detect available RISC-V cross-compilers
TOOLCHAIN_PREFIX=""
for prefix in "riscv64-unknown-elf-" "riscv32-unknown-elf-" "riscv-none-elf-" "riscv64-elf-" "riscv32-elf-"; do
    if command -v "${prefix}gcc" &> /dev/null; then
        TOOLCHAIN_PREFIX="${prefix}"
        break
    fi
done

if [ -z "${TOOLCHAIN_PREFIX}" ]; then
    echo "[-] ERROR: RISC-V cross compiler not found in current PATH."
    echo ""
    echo "Available search candidates checked:"
    echo "  - riscv64-unknown-elf-gcc"
    echo "  - riscv32-unknown-elf-gcc"
    echo "  - riscv-none-elf-gcc"
    echo ""
    echo "Expected Lab Procedure Tomorrow:"
    echo "  1. Source the lab module/environment (e.g., module load riscv-toolchain)"
    echo "  2. Ensure '${CROSS_COMPILE:-riscv64-unknown-elf-}gcc' is in PATH"
    echo "  3. Re-run this script: ./generate_hex.sh"
    echo "=================================================================="
    exit 1
fi

CC="${TOOLCHAIN_PREFIX}gcc"
OBJCOPY="${TOOLCHAIN_PREFIX}objcopy"
OBJDUMP="${TOOLCHAIN_PREFIX}objdump"
SIZE="${TOOLCHAIN_PREFIX}size"

echo "[+] Using cross-compiler: ${CC}"
${CC} --version | head -n 1

# Configuration parameters
ARCH="-march=rv32imc -mabi=ilp32"
CFLAGS="${ARCH} -O0 -g -ffreestanding -nostdlib -Wall -Wextra"
LDFLAGS="-T cardioedge.ld -nostdlib -Wl,--gc-sections"

TARGET="cardioedge_test"
ELF="${TARGET}.elf"
BIN="${TARGET}.bin"
HEX="${TARGET}.hex"
VHX="${TARGET}.vhx"
DUMP="${TARGET}.dump"

echo ""
echo "[1/5] Compiling and linking: start.S + cardioedge_test.c -> ${ELF}..."
${CC} ${CFLAGS} ${LDFLAGS} -o "${ELF}" start.S cardioedge_test.c

echo "[2/5] Generating raw binary: ${BIN}..."
${OBJCOPY} -O binary "${ELF}" "${BIN}"

echo "[3/5] Generating Intel HEX: ${HEX}..."
${OBJCOPY} -O ihex "${ELF}" "${HEX}"

echo "[4/5] Generating Verilog HEX (for simulation \$readmemh): ${VHX}..."
${OBJCOPY} -O verilog "${ELF}" "${VHX}"

echo "[5/5] Generating disassembly dump: ${DUMP}..."
${OBJDUMP} -d -S "${ELF}" > "${DUMP}"

echo ""
echo "=== Memory Utilization Report ==="
${SIZE} "${ELF}"

echo ""
echo "=================================================================="
echo "    FIRMWARE BUILD COMPLETE"
echo "  Artifacts generated:"
echo "    - ${ELF}  (Executable and Linkable Format)"
echo "    - ${BIN}  (Flat Binary)"
echo "    - ${HEX}  (Intel HEX format)"
echo "    - ${VHX}  (Verilog HEX format for simulation \$readmemh)"
echo "    - ${DUMP} (Complete RV32IMC Disassembly)"
echo "=================================================================="
