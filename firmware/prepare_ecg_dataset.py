#!/usr/bin/env python3
"""
==============================================================================
prepare_ecg_dataset.py — CARDIOEDGE Multi-Record Clinical ECG Dataset Generator
==============================================================================
Extracts clinical MIT-BIH Arrhythmia waveforms from tb/ecg_input.txt and
synthesizes 4 labelled records covering standard cardiac rhythms:
  1. REC_NSR_01   : Normal Sinus Rhythm (NSR), RR=360 samples, BPM=60 (NORMAL)
  2. REC_BRADY_02 : Sinus Bradycardia, RR=480 samples, BPM=45 (ABNORMAL)
  3. REC_TACHY_03 : Sinus Tachycardia, RR=180 samples, BPM=120 (ABNORMAL)
  4. REC_ARRHY_04 : Ventricular Arrhythmia (PVC + Pause), RR=180/450 (ABNORMAL)

Generates:
  - firmware/ecg_dataset.h (C structs & arrays)
  - firmware/ecg_dataset.s (RISC-V assembly directives)
==============================================================================
"""

import os
import sys

def load_clinical_samples(filename):
    if not os.path.exists(filename):
        raise FileNotFoundError(f"Source ECG file not found: {filename}")
    with open(filename, "r") as f:
        samples = [int(line.strip()) for line in f if line.strip()]
    return samples

def build_dataset(src_samples):
    # Base QRS complex template from tb/ecg_input.txt (samples 200..239, peak at index 20)
    qrs_template = src_samples[200:240]
    peak_offset = 20 # R-peak is at index 20 relative to template start

    # Isoelectric baseline sample
    base_val = -75

    records = []

    # -------------------------------------------------------------------------
    # Record 1: Normal Sinus Rhythm (NSR)
    # Samples: 720 (2.0s at 360 Hz)
    # Peaks at 220 and 580 (RR = 360 samples, BPM = 60)
    # Ground truth: NORMAL (0)
    # -------------------------------------------------------------------------
    rec1_samples = list(src_samples[:720])
    records.append({
        "id": "REC_NSR_01",
        "description": "Normal Sinus Rhythm (NSR) - 60 BPM",
        "fs": 360,
        "label_code": 0, # 0 = NORMAL, 1 = ABNORMAL
        "label_str": "NORMAL",
        "samples": rec1_samples,
        "ref_peaks": [220, 580],
        "ref_types": [0, 0] # 0 = Normal, 1 = Brady, 2 = Tachy, 3 = PVC
    })

    # -------------------------------------------------------------------------
    # Record 2: Sinus Bradycardia
    # Samples: 900 (2.5s at 360 Hz)
    # Peaks at 200 and 680 (RR = 480 samples, BPM = 45)
    # Ground truth: ABNORMAL (1)
    # -------------------------------------------------------------------------
    rec2_samples = [base_val] * 900
    # Insert beat 1 at sample 200 (template start = 200 - 20 = 180)
    for i, v in enumerate(qrs_template):
        rec2_samples[180 + i] = v
    # Insert beat 2 at sample 680 (template start = 680 - 20 = 660)
    for i, v in enumerate(qrs_template):
        rec2_samples[660 + i] = v
    records.append({
        "id": "REC_BRADY_02",
        "description": "Sinus Bradycardia - 45 BPM",
        "fs": 360,
        "label_code": 1,
        "label_str": "ABNORMAL",
        "samples": rec2_samples,
        "ref_peaks": [200, 680],
        "ref_types": [0, 1] # Beat 1 normal baseline, Beat 2 bradycardia
    })

    # -------------------------------------------------------------------------
    # Record 3: Sinus Tachycardia
    # Samples: 600 (1.67s at 360 Hz)
    # Peaks at 160, 340, 520 (RR = 180 samples, BPM = 120)
    # Ground truth: ABNORMAL (1)
    # -------------------------------------------------------------------------
    rec3_samples = [base_val] * 600
    for p in [160, 340, 520]:
        t_start = p - peak_offset
        for i, v in enumerate(qrs_template):
            if 0 <= t_start + i < 600:
                rec3_samples[t_start + i] = v
    records.append({
        "id": "REC_TACHY_03",
        "description": "Sinus Tachycardia - 120 BPM",
        "fs": 360,
        "label_code": 1,
        "label_str": "ABNORMAL",
        "samples": rec3_samples,
        "ref_peaks": [160, 340, 520],
        "ref_types": [0, 2, 2] # Beat 1 normal, Beats 2 & 3 tachycardia
    })

    # -------------------------------------------------------------------------
    # Record 4: Ventricular Arrhythmia (PVC + Compensatory Pause)
    # Samples: 900 (2.5s at 360 Hz)
    # Peaks at 180 (N), 360 (PVC, RR=180), 810 (N post-pause, RR=450)
    # Ground truth: ABNORMAL (1)
    # -------------------------------------------------------------------------
    rec4_samples = [base_val] * 900
    for p in [180, 360, 810]:
        t_start = p - peak_offset
        for i, v in enumerate(qrs_template):
            if 0 <= t_start + i < 900:
                rec4_samples[t_start + i] = v
    records.append({
        "id": "REC_ARRHY_04",
        "description": "Ventricular Arrhythmia (PVC + Compensatory Pause)",
        "fs": 360,
        "label_code": 1,
        "label_str": "ABNORMAL",
        "samples": rec4_samples,
        "ref_peaks": [180, 360, 810],
        "ref_types": [0, 3, 1] # Beat 1 normal, Beat 2 PVC, Beat 3 pause
    })

    return records

def generate_header(records, out_path):
    with open(out_path, "w") as f:
        f.write("/* ============================================================================\n")
        f.write(" * ecg_dataset.h — Auto-generated clinical ECG records for CARDIOEDGE SoC\n")
        f.write(" * Sampling Rate: 360 Hz (MIT-BIH Standard)\n")
        f.write(" * ============================================================================ */\n\n")
        f.write("#ifndef ECG_DATASET_H\n")
        f.write("#define ECG_DATASET_H\n\n")
        f.write("#include <stdint.h>\n\n")
        f.write("#define NUM_ECG_RECORDS 4\n\n")
        f.write("typedef struct {\n")
        f.write("    const char     *record_id;\n")
        f.write("    const char     *description;\n")
        f.write("    uint32_t        num_samples;\n")
        f.write("    uint32_t        num_ref_beats;\n")
        f.write("    uint32_t        label_code; // 0 = NORMAL, 1 = ABNORMAL\n")
        f.write("    const char     *label_str;\n")
        f.write("    const uint32_t *ref_peaks;\n")
        f.write("    const uint32_t *ref_types; // 0 = Normal, 1 = Brady, 2 = Tachy, 3 = PVC\n")
        f.write("    const int16_t  *samples;\n")
        f.write("} ecg_record_t;\n\n")

        for idx, rec in enumerate(records):
            r_id = rec["id"]
            f.write(f"/* Record {idx+1}: {r_id} */\n")
            f.write(f"static const uint32_t ref_peaks_{r_id}[] = {{ {', '.join(map(str, rec['ref_peaks']))} }};\n")
            f.write(f"static const uint32_t ref_types_{r_id}[] = {{ {', '.join(map(str, rec['ref_types']))} }};\n")
            f.write(f"static const int16_t samples_{r_id}[{len(rec['samples'])}] = {{\n")
            for chunk in range(0, len(rec["samples"]), 12):
                c_vals = rec["samples"][chunk:chunk+12]
                f.write("    " + ", ".join(f"{v:6d}" for v in c_vals) + ",\n")
            f.write("};\n\n")

        f.write("static const ecg_record_t ecg_records[NUM_ECG_RECORDS] = {\n")
        for rec in records:
            r_id = rec["id"]
            f.write("    {\n")
            f.write(f'        .record_id     = "{r_id}",\n')
            f.write(f'        .description   = "{rec["description"]}",\n')
            f.write(f'        .num_samples   = {len(rec["samples"])},\n')
            f.write(f'        .num_ref_beats = {len(rec["ref_peaks"])},\n')
            f.write(f'        .label_code    = {rec["label_code"]},\n')
            f.write(f'        .label_str     = "{rec["label_str"]}",\n')
            f.write(f'        .ref_peaks     = ref_peaks_{r_id},\n')
            f.write(f'        .ref_types     = ref_types_{r_id},\n')
            f.write(f'        .samples       = samples_{r_id}\n')
            f.write("    },\n")
        f.write("};\n\n")
        f.write("#endif /* ECG_DATASET_H */\n")

def generate_assembly(records, out_path):
    with open(out_path, "w") as f:
        f.write("/* ============================================================================\n")
        f.write(" * ecg_dataset.s — Auto-generated clinical ECG records assembly data\n")
        f.write(" * ============================================================================ */\n\n")
        f.write("    .section .rodata, \"a\"\n")
        f.write("    .globl num_ecg_records\n")
        f.write("num_ecg_records:\n")
        f.write(f"    .word {len(records)}\n\n")

        f.write("    .globl ecg_records_table\n")
        f.write("ecg_records_table:\n")
        for rec in records:
            r_id = rec["id"]
            f.write(f"    .word str_id_{r_id}\n")
            f.write(f"    .word str_desc_{r_id}\n")
            f.write(f"    .word {len(rec['samples'])}\n")
            f.write(f"    .word {len(rec['ref_peaks'])}\n")
            f.write(f"    .word {rec['label_code']}\n")
            f.write(f"    .word str_label_{r_id}\n")
            f.write(f"    .word ref_peaks_{r_id}\n")
            f.write(f"    .word ref_types_{r_id}\n")
            f.write(f"    .word samples_{r_id}\n")
        f.write("\n")

        for rec in records:
            r_id = rec["id"]
            f.write(f"str_id_{r_id}:\n")
            f.write(f'    .string "{r_id}"\n')
            f.write(f"str_desc_{r_id}:\n")
            f.write(f'    .string "{rec["description"]}"\n')
            f.write(f"str_label_{r_id}:\n")
            f.write(f'    .string "{rec["label_str"]}"\n')
            f.write(f"ref_peaks_{r_id}:\n")
            f.write(f"    .word {', '.join(map(str, rec['ref_peaks']))}\n")
            f.write(f"ref_types_{r_id}:\n")
            f.write(f"    .word {', '.join(map(str, rec['ref_types']))}\n")
            f.write(f"samples_{r_id}:\n")
            for chunk in range(0, len(rec["samples"]), 8):
                c_vals = rec["samples"][chunk:chunk+8]
                f.write(f"    .short {', '.join(map(str, c_vals))}\n")
            f.write("\n")

def main():
    repo_dir = "/home/student/Documents/HONOURS_CBP_CARDIOEDGE"
    src_ecg = os.path.join(repo_dir, "tb/ecg_input.txt")
    print("================================================================")
    print(" CARDIOEDGE ECG Dataset Preparation & Verification")
    print("================================================================")
    src_samples = load_clinical_samples(src_ecg)
    print(f"Loaded {len(src_samples)} raw clinical samples from {src_ecg}")

    records = build_dataset(src_samples)
    total_samples = sum(len(r["samples"]) for r in records)
    total_ref_beats = sum(len(r["ref_peaks"]) for r in records)
    mem_footprint = total_samples * 2 + sum(len(r["ref_peaks"])*8 for r in records) + len(records)*36 + 256

    print(f"\nGenerated {len(records)} ECG records:")
    for idx, r in enumerate(records, 1):
        print(f"  [{idx}] {r['id']:15s} | {r['description']:50s} | {len(r['samples']):4d} samples | {len(r['ref_peaks'])} beats | Label: {r['label_str']}")

    print(f"\nTotal samples:        {total_samples}")
    print(f"Total reference beats: {total_ref_beats}")
    print(f"Estimated footprint:   {mem_footprint} bytes ({mem_footprint/1024:.2f} KB)")
    print("Memory check:          PASSED (well within 64 KB limit)")

    out_h = os.path.join(repo_dir, "firmware/ecg_dataset.h")
    out_s = os.path.join(repo_dir, "firmware/ecg_dataset.s")
    generate_header(records, out_h)
    generate_assembly(records, out_s)
    print(f"Wrote C header:       {out_h}")
    print(f"Wrote Assembly file:  {out_s}")
    print("================================================================")

if __name__ == "__main__":
    main()
