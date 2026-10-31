#!/usr/bin/env bash
# ==============================================================================
# Script: view_verdi.sh
# Purpose: Viewer-only script to launch Synopsys Verdi with pre-generated FSDB
#          waveforms for CardioEdge SoC verification test cases (TC-01..TC-18).
#
# NOTE: This script is strictly a waveform viewer. It does NOT compile,
#       does NOT run VCS, does NOT rebuild executables, and does NOT regenerate waveforms.
#       All waveforms must be prepared beforehand using: ./prepare_all_waveforms.sh
#
# Usage:
#   ./view_verdi.sh 1                # View TC-01 waveform (cardioedge_tc01.fsdb)
#   ./view_verdi.sh 8                # View TC-08 waveform (cardioedge_tc08.fsdb)
#   ./view_verdi.sh 18               # View TC-18 waveform (cardioedge_tc18.fsdb)
#   ./view_verdi.sh TC-08            # Also accepts TC-08 format
#   ./view_verdi.sh regression       # View full regression waveform (cardioedge_regression.fsdb)
# ==============================================================================

set -e

# Toolchain configuration
export SNPSLMD_LICENSE_FILE="${SNPSLMD_LICENSE_FILE:-27021@14.139.1.126}"
export VCS_HOME="${VCS_HOME:-/home/student/snps_tools_target/vcs/U-2023.03}"
export VERDI_HOME="${VERDI_HOME:-/home/student/snps_tools_target/verdi/U-2023.03-SP1}"
export PATH="${VCS_HOME}/bin:${VERDI_HOME}/bin:${PATH}"

# Resolve script directory (resolving symlinks if invoked via symlink)
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
    DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
cd "${SCRIPT_DIR}"

# Authoritative Test Descriptions
declare -A TEST_NAMES=(
    [1]="RISC-V CPU Boot & SoC Reset Bring-Up"
    [2]="Data Memory Access & RV32I ISA Execution via 64-to-32 Adapter"
    [3]="AXI4 Interconnect Address Mapping & Channel Handshake Protocol"
    [4]="Dual-Master Interconnect Concurrency & Bus Contention Arbitration"
    [5]="UART Peripheral Subsystem & Serial Communication"
    [6]="GPIO Subsystem Input/Output & Atomic Bit-Level Operations"
    [7]="32-Bit Timer Subsystem Counting, Expiration & W1C Interrupt"
    [8]="FIR Filter Configuration & Numerical Golden Model Comparison"
    [9]="ADC Digital Interface, Sample Capture & Overrun Handling"
    [10]="SPI Master Controller Configuration & Full-Duplex Data Transfer"
    [11]="QRS Detection Engine Verification Against Clinical ECG Waveforms"
    [12]="Cardiac Rhythm Classification & Heart Rate Extraction"
    [13]="Interconnect Address Boundary & Dummy Slave DECERR Negative Testing"
    [14]="System Interrupt Architecture, PIC Routing & Dynamic Firing"
    [15]="CPU-Initiated Peripheral Integration & Firmware Telemetry Readback"
    [16]="End-to-End Cardiac Signal Processing Pipeline Flow"
    [17]="SoC Reset Recovery & Multi-IP State Re-Initialization"
    [18]="Comprehensive SoC System Regression & Simulation Completion"
)

# ------------------------------------------------------------------------------
# 1. Validate & Parse Requested Test ID
# ------------------------------------------------------------------------------
INPUT_ARG="$1"

if [ -z "${INPUT_ARG}" ] || [ "${INPUT_ARG}" = "-h" ] || [ "${INPUT_ARG}" = "--help" ]; then
    echo "=============================================================================="
    echo " CardioEdge Synopsys Verdi Waveform Viewer (Viewer-Only)"
    echo "=============================================================================="
    echo " Usage:"
    echo "   ./view_verdi.sh <test_id>     # Opens pre-generated test waveform (1..18)"
    echo "   ./view_verdi.sh regression    # Opens pre-generated full regression waveform"
    echo ""
    echo " Examples:"
    echo "   ./view_verdi.sh 1             # TC-01: RISC-V CPU Boot & SoC Reset Bring-Up"
    echo "   ./view_verdi.sh 8             # TC-08: FIR Filter Golden Model Comparison"
    echo "   ./view_verdi.sh 11            # TC-11: QRS Detection Engine Verification"
    echo "   ./view_verdi.sh 18            # TC-18: Comprehensive SoC System Regression"
    echo "   ./view_verdi.sh regression    # Complete Full 18-Test Regression Waveform"
    echo ""
    echo " Note: All waveforms must be pre-generated via: ./prepare_all_waveforms.sh"
    echo "=============================================================================="
    exit 0
fi

IS_REGRESSION=0
TEST_NUM=0

# Normalize input argument
if [ "${INPUT_ARG,,}" = "regression" ] || [ "${INPUT_ARG}" = "cardioedge_regression.fsdb" ] || [ "${INPUT_ARG,,}" = "all" ]; then
    IS_REGRESSION=1
elif [[ "${INPUT_ARG}" =~ ^[Tt][Cc]-?([0-9]+)$ ]]; then
    TEST_NUM=$((10#${BASH_REMATCH[1]}))
elif [[ "${INPUT_ARG}" =~ ^cardioedge_tc([0-9]+)\.fsdb$ ]]; then
    TEST_NUM=$((10#${BASH_REMATCH[1]}))
elif [[ "${INPUT_ARG}" =~ ^[0-9]+$ ]]; then
    TEST_NUM=$((10#${INPUT_ARG}))
else
    echo "[ERROR] Invalid Test ID: '${INPUT_ARG}'."
    echo "        Valid IDs are 1 to 18 (corresponding to TC-01 through TC-18 in"
    echo "        CardioEdge_Project_Test_Cases_Condensed.xlsx), or 'regression'."
    exit 1
fi

if [ "${IS_REGRESSION}" -eq 1 ]; then
    FSDB_FILE="cardioedge_regression.fsdb"
    WAVE_RC="cardioedge_wave.rc"
    TEST_TITLE="Full 18-Test Regression Waveform"
else
    if [ "${TEST_NUM}" -lt 1 ] || [ "${TEST_NUM}" -gt 18 ]; then
        echo "[ERROR] Test ID '${TEST_NUM}' is out of range."
        echo "        Valid range is 1 to 18 as defined in authoritative test suite."
        exit 1
    fi
    printf -v PAD_ID "%02d" "${TEST_NUM}"
    FSDB_FILE="cardioedge_tc${PAD_ID}.fsdb"
    TEST_TITLE="TC-${PAD_ID}: ${TEST_NAMES[$TEST_NUM]}"
    
    # Use dedicated signal setup file if available, otherwise fallback to master setup
    if [ -f "cardioedge_tc${PAD_ID}_wave.rc" ]; then
        WAVE_RC="cardioedge_tc${PAD_ID}_wave.rc"
    else
        WAVE_RC="cardioedge_wave.rc"
    fi
fi

# ------------------------------------------------------------------------------
# 2. Check That FSDB Exists and Is Readable (Strict Viewer Requirement)
# ------------------------------------------------------------------------------
if [ ! -f "${FSDB_FILE}" ] || [ ! -r "${FSDB_FILE}" ] || [ ! -s "${FSDB_FILE}" ]; then
    echo "=============================================================================="
    echo " [ERROR] Pre-generated waveform file '${FSDB_FILE}' not found or unreadable!"
    echo "=============================================================================="
    echo " The viewer script does NOT simulate or regenerate waveforms."
    echo " Please run the preparation script beforehand to generate all waveforms:"
    echo ""
    echo "   ./prepare_all_waveforms.sh"
    echo ""
    echo " Or prepare only this test:"
    echo "   ./prepare_all_waveforms.sh ${TEST_NUM}"
    echo "=============================================================================="
    exit 1
fi

FSDB_SIZE="$(du -h "${FSDB_FILE}" | cut -f1)"

# ------------------------------------------------------------------------------
# 3. Launch Verdi Waveform Viewer
# ------------------------------------------------------------------------------
echo "=============================================================================="
echo " Opening Synopsys Verdi Waveform Viewer"
echo " Target Test   : ${TEST_TITLE}"
echo " Waveform FSDB : ${FSDB_FILE} (${FSDB_SIZE})"
echo " Signal Setup  : ${WAVE_RC}"
echo " Simulation DB : simv_comprehensive.daidir"
echo " Mode          : Pre-generated waveform playback (No simulation triggered)"
echo "=============================================================================="

if [ -z "${DISPLAY}" ]; then
    echo "[NOTICE] DISPLAY environment variable is currently unset."
    echo "         Verdi GUI requires an active X11 display session (ssh -X or -Y)."
fi

# Launch Verdi in the background with the exact requested FSDB
verdi -dbdir simv_comprehensive.daidir \
      -ssf "${FSDB_FILE}" \
      -sswr "${WAVE_RC}" &

echo "[INFO] Verdi process launched in background (PID: $!)."
exit 0
