#!/usr/bin/env bash
# ==============================================================================
# Script: prepare_all_waveforms.sh
# Purpose: Pre-generate all individual CardioEdge SoC test waveforms (TC-01..TC-18)
#          and the full regression waveform in advance for Synopsys Verdi.
# Usage:
#   ./prepare_all_waveforms.sh            # Run all 18 test cases + regression
#   ./prepare_all_waveforms.sh <test_id>  # Run only a specific test ID (e.g. 8)
#   ./prepare_all_waveforms.sh -recompile # Force recompile before generation
# ==============================================================================

set -o pipefail

# ------------------------------------------------------------------------------
# 1. Environment & Toolchain Setup
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# 2. Authoritative Test Case Definitions (from Condensed XLSX / Testbench)
# ------------------------------------------------------------------------------
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

# Parse command line arguments
FORCE_RECOMPILE=0
SINGLE_TEST=""

for arg in "$@"; do
    case "${arg}" in
        -recompile|-c|--recompile)
            FORCE_RECOMPILE=1
            ;;
        *)
            if [[ "${arg}" =~ ^[Tt][Cc]-?([0-9]+)$ ]]; then
                SINGLE_TEST="${BASH_REMATCH[1]}"
            elif [[ "${arg}" =~ ^[0-9]+$ ]]; then
                SINGLE_TEST="${arg}"
            fi
            ;;
    esac
done

echo "=============================================================================="
echo " CARDIOEDGE SoC — Automated Test Waveform Pre-Generation"
echo " Synopsys VCS & Verdi Environment"
echo "=============================================================================="
echo " Project Directory : ${SCRIPT_DIR}"
echo " VCS Home          : ${VCS_HOME}"
echo " Verdi Home        : ${VERDI_HOME}"
echo " License Server    : ${SNPSLMD_LICENSE_FILE}"

# ------------------------------------------------------------------------------
# 3. Validate Dependencies & Project Configuration
# ------------------------------------------------------------------------------
echo ""
echo "[1/4] Validating Project Dependencies..."

FILELIST="filelist_cardioedge_comprehensive_soc.f"
TB_TOP="../tb/tb_cardioedge_comprehensive_soc.sv"
WAVE_RC_MASTER="cardioedge_wave.rc"

if [ ! -f "${FILELIST}" ]; then
    echo "[ERROR] Filelist '${FILELIST}' not found in ${SCRIPT_DIR}."
    exit 1
fi

if [ ! -f "${TB_TOP}" ]; then
    echo "[ERROR] Testbench '${TB_TOP}' not found."
    exit 1
fi

if [ ! -f "${WAVE_RC_MASTER}" ]; then
    echo "[ERROR] Waveform configuration master '${WAVE_RC_MASTER}' not found."
    exit 1
fi

if [ ! -f "cardioedge_test.hex" ] && [ ! -f "../firmware/cardioedge_test.hex" ]; then
    echo "[ERROR] Firmware memory image 'cardioedge_test.hex' not found."
    exit 1
fi

echo "  ✓ VCS Filelist               : ${FILELIST}"
echo "  ✓ Testbench Top              : ${TB_TOP}"
echo "  ✓ Waveform Master Config     : ${WAVE_RC_MASTER}"
echo "  ✓ Memory Initialization      : Confirmed"

# ------------------------------------------------------------------------------
# 4. Compile Simulation Executable If Needed
# ------------------------------------------------------------------------------
echo ""
echo "[2/4] Checking Simulation Executable..."

NEED_COMPILE=0
if [ ! -f "simv_comprehensive" ]; then
    NEED_COMPILE=1
    echo "  -> 'simv_comprehensive' executable not found. Compilation required."
elif [ "${FORCE_RECOMPILE}" -eq 1 ]; then
    NEED_COMPILE=1
    echo "  -> Force recompile requested."
elif [ "${TB_TOP}" -nt "simv_comprehensive" ] || [ "${FILELIST}" -nt "simv_comprehensive" ]; then
    NEED_COMPILE=1
    echo "  -> Source or filelist newer than executable. Compilation required."
fi

if [ "${NEED_COMPILE}" -eq 1 ]; then
    echo "=============================================================================="
    echo " [VCS COMPILE] Compiling CardioEdge Comprehensive Testbench..."
    echo "=============================================================================="
    vcs -full64 -sverilog -ntb_opts uvm -timescale=1ns/1ps -debug_access+all \
        -kdb -f "${FILELIST}" -o simv_comprehensive \
        -l compile_comprehensive.log

    if [ ! -f "simv_comprehensive" ]; then
        echo "[ERROR] VCS compilation failed. Inspect compile_comprehensive.log."
        exit 1
    fi
    echo " [VCS COMPILE] Compilation succeeded."
else
    echo "  ✓ Simulation executable 'simv_comprehensive' is up to date."
fi

# ------------------------------------------------------------------------------
# 5. Pre-Run Test Cases & Generate Waveforms
# ------------------------------------------------------------------------------
echo ""
echo "[3/4] Executing Simulations and Generating Waveforms..."

declare -a TARGET_TESTS
if [ -n "${SINGLE_TEST}" ]; then
    ID_NUM=$((10#${SINGLE_TEST}))
    if [ "${ID_NUM}" -lt 1 ] || [ "${ID_NUM}" -gt 18 ]; then
        echo "[ERROR] Invalid single test ID: ${SINGLE_TEST}. Valid range is 1..18."
        exit 1
    fi
    TARGET_TESTS=("${ID_NUM}")
    echo "  Target: Single test TC-$(printf '%02d' "${ID_NUM}")"
else
    for i in {1..18}; do
        TARGET_TESTS+=("${i}")
    done
    echo "  Target: All 18 Authoritative Test Cases (TC-01 through TC-18)"
fi

declare -A TEST_OUTCOME
declare -A TEST_EXIT
declare -A FSDB_SIZE
declare -A LOG_NAMES
TOTAL_FAILURES=0

for id in "${TARGET_TESTS[@]}"; do
    printf -v PAD_ID "%02d" "${id}"
    TEST_DESC="${TEST_NAMES[$id]}"
    LOG_FILE="sim_tc${PAD_ID}.log"
    FSDB_FILE="cardioedge_tc${PAD_ID}.fsdb"
    RC_FILE="cardioedge_tc${PAD_ID}_wave.rc"

    LOG_NAMES[$id]="${LOG_FILE}"

    echo "------------------------------------------------------------------------------"
    echo " Running TC-${PAD_ID}: ${TEST_DESC}"
    echo " Command: ./simv_comprehensive -no_save +TEST_ID=${id} -l ${LOG_FILE}"

    SIM_STATUS=0
    ./simv_comprehensive -no_save +TEST_ID="${id}" -l "${LOG_FILE}" || SIM_STATUS=$?
    TEST_EXIT[$id]="${SIM_STATUS}"

    # Verify simulation exit and PASS marker in log
    PASS_COUNT=$(grep -c "\[PASS\] TC-${PAD_ID}:" "${LOG_FILE}" || true)
    FAIL_COUNT=$(grep -c "\[FAIL\] TC-${PAD_ID}:" "${LOG_FILE}" || true)

    if [ "${SIM_STATUS}" -eq 0 ] && [ "${PASS_COUNT}" -ge 1 ] && [ "${FAIL_COUNT}" -eq 0 ]; then
        TEST_OUTCOME[$id]="PASS"
    else
        TEST_OUTCOME[$id]="FAIL"
        TOTAL_FAILURES=$((TOTAL_FAILURES + 1))
    fi

    # Verify FSDB file exists and is non-empty
    if [ -f "${FSDB_FILE}" ] && [ -s "${FSDB_FILE}" ]; then
        FSDB_SIZE[$id]="$(du -h "${FSDB_FILE}" | cut -f1)"
        
        # Check completeness with fsdbsanitycheck if available
        if command -v fsdbsanitycheck >/dev/null 2>&1; then
            SANITY_OUT=$(fsdbsanitycheck "${FSDB_FILE}" 2>&1 || true)
            if echo "${SANITY_OUT}" | grep -q "finished"; then
                SANITY_STATUS="Complete"
            else
                SANITY_STATUS="Incomplete"
                TEST_OUTCOME[$id]="CORRUPT_FSDB"
                TOTAL_FAILURES=$((TOTAL_FAILURES + 1))
            fi
        else
            SANITY_STATUS="Verified Size"
        fi
    else
        FSDB_SIZE[$id]="MISSING"
        TEST_OUTCOME[$id]="MISSING_FSDB"
        TOTAL_FAILURES=$((TOTAL_FAILURES + 1))
        SANITY_STATUS="Missing"
    fi

    # Pre-generate dedicated Verdi signal setup file for this test
    sed "s/cardioedge_regression\.fsdb/${FSDB_FILE}/g" "${WAVE_RC_MASTER}" > "${RC_FILE}"

    echo "   Outcome  : ${TEST_OUTCOME[$id]} (Exit Code: ${SIM_STATUS})"
    echo "   Waveform : ${FSDB_FILE} (${FSDB_SIZE[$id]}, ${SANITY_STATUS})"
    echo "   Setup RC : ${RC_FILE}"
done

# Ensure full regression FSDB is also preserved / available
if [ -z "${SINGLE_TEST}" ]; then
    if [ ! -f "cardioedge_regression.fsdb" ] || [ ! -s "cardioedge_regression.fsdb" ]; then
        echo "------------------------------------------------------------------------------"
        echo " Generating Full-Regression FSDB (Method A: cardioedge_regression.fsdb)..."
        ./simv_comprehensive -no_save -l sim_comprehensive.log
    fi
fi

# ------------------------------------------------------------------------------
# 6. Verification Summary & Scorecard
# ------------------------------------------------------------------------------
REPORT_FILE="waveform_preparation_report.txt"

{
    echo "================================================================================================================"
    echo "                    CARDIOEDGE SoC TEST WAVEFORM PRE-GENERATION REPORT"
    echo "================================================================================================================"
    printf " %-7s | %-8s | %-9s | %-12s | %-24s | %s\n" "Test ID" "Outcome" "Exit Code" "FSDB Size" "FSDB Waveform File" "Test Description"
    echo "---------+----------+-----------+--------------+--------------------------+-------------------------------------"
    for id in "${TARGET_TESTS[@]}"; do
        printf -v PAD_ID "%02d" "${id}"
        printf " TC-%-4s | %-8s | %-9s | %-12s | %-24s | %s\n" \
            "${PAD_ID}" \
            "${TEST_OUTCOME[$id]}" \
            "${TEST_EXIT[$id]}" \
            "${FSDB_SIZE[$id]}" \
            "cardioedge_tc${PAD_ID}.fsdb" \
            "${TEST_NAMES[$id]}"
    done
    echo "================================================================================================================"
    echo " Total Tests Attempted : ${#TARGET_TESTS[@]}"
    echo " Total Failures        : ${TOTAL_FAILURES}"
    echo " Full Regression FSDB  : cardioedge_regression.fsdb ($(du -h cardioedge_regression.fsdb 2>/dev/null | cut -f1 || echo 'N/A'))"
    echo "================================================================================================================"
} | tee "${REPORT_FILE}"

if [ "${TOTAL_FAILURES}" -gt 0 ]; then
    echo ""
    echo "[ERROR] Waveform pre-generation encountered ${TOTAL_FAILURES} failure(s)."
    exit 1
fi

echo ""
echo "=============================================================================="
echo " [SUCCESS] All requested test waveforms are pre-generated and verified!"
echo " Ready for viewer-only workflow:"
echo "   ./view_verdi.sh 1"
echo "   ./view_verdi.sh 8"
echo "   ./view_verdi.sh 11"
echo "   ... up to ./view_verdi.sh 18"
echo "=============================================================================="
exit 0
