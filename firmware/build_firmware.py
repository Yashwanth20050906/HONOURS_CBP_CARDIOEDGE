#!/usr/bin/env python3
"""
==============================================================================
build_firmware.py — CARDIOEDGE Bare-Metal RV32IMC Firmware Assembler & Builder
Target: Western Digital VeeR EL2 (RV32IMC)
Generates:
  1. cardioedge_test.elf (Authentic 32-bit RISC-V ELF executable)
  2. cardioedge_test.hex (Intel HEX format with IMEM base 0x00000000)
  3. cardioedge_test.vhx (Verilog HEX format with 32-bit words for $readmemh)
  4. cardioedge_test.dump (Full disassembly report)
==============================================================================
"""

import os
import sys
import struct
import re

REGISTERS = {
    "zero": 0, "ra": 1, "sp": 2, "gp": 3, "tp": 4,
    "t0": 5, "t1": 6, "t2": 7,
    "s0": 8, "fp": 8, "s1": 9,
    "a0": 10, "a1": 11, "a2": 12, "a3": 13, "a4": 14, "a5": 15, "a6": 16, "a7": 17,
    "s2": 18, "s3": 19, "s4": 20, "s5": 21, "s6": 22, "s7": 23, "s8": 24, "s9": 25, "s10": 26, "s11": 27,
    "t3": 28, "t4": 29, "t5": 30, "t6": 31
}
for i in range(32):
    REGISTERS[f"x{i}"] = i

CSRS = {
    "mstatus": 0x300,
    "misa": 0x301,
    "mie": 0x304,
    "mtvec": 0x305,
    "mscratch": 0x340,
    "mepc": 0x341,
    "mcause": 0x342,
    "mtval": 0x343,
    "mip": 0x344
}

def parse_reg(s):
    s = s.strip().lower()
    if s in REGISTERS:
        return REGISTERS[s]
    raise ValueError(f"Unknown register: {s}")

def parse_imm(s, labels=None, pc=0):
    s = s.strip()
    if labels and s in labels:
        return labels[s]
    return int(s, 0)

def parse_mem_operand(s):
    # Matches offset(reg) e.g. 12(t0) or 0(s1) or -4(sp)
    m = re.match(r"^([+-]?(?:0x[0-9a-fA-F]+|\d+))\s*\(\s*([a-zA-Z0-9]+)\s*\)$", s.strip())
    if m:
        offset_val = int(m.group(1), 0)
        reg_val = parse_reg(m.group(2))
        return offset_val, reg_val
    # also handle (reg)
    m2 = re.match(r"^\(\s*([a-zA-Z0-9]+)\s*\)$", s.strip())
    if m2:
        return 0, parse_reg(m2.group(1))
    raise ValueError(f"Invalid memory operand: {s}")

def encode_r(funct7, rs2, rs1, funct3, rd, opcode=0x33):
    return ((funct7 & 0x7F) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 0x7) << 12) | ((rd & 0x1F) << 7) | (opcode & 0x7F)

def encode_i(imm, rs1, funct3, rd, opcode=0x13):
    return ((imm & 0xFFF) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 0x7) << 12) | ((rd & 0x1F) << 7) | (opcode & 0x7F)

def encode_s(imm, rs2, rs1, funct3, opcode=0x23):
    return (((imm >> 5) & 0x7F) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 0x7) << 12) | ((imm & 0x1F) << 7) | (opcode & 0x7F)

def encode_b(imm, rs2, rs1, funct3, opcode=0x63):
    b_imm = (((imm >> 12) & 1) << 31) | (((imm >> 5) & 0x3F) << 25) | (((imm >> 1) & 0xF) << 8) | (((imm >> 11) & 1) << 7)
    return b_imm | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((funct3 & 0x7) << 12) | (opcode & 0x7F)

def encode_u(imm, rd, opcode=0x37):
    return (imm & 0xFFFFF000) | ((rd & 0x1F) << 7) | (opcode & 0x7F)

def encode_j(imm, rd, opcode=0x6F):
    j_imm = (((imm >> 20) & 1) << 31) | (((imm >> 1) & 0x3FF) << 21) | (((imm >> 11) & 1) << 20) | (((imm >> 12) & 0xFF) << 12)
    return j_imm | ((rd & 0x1F) << 7) | (opcode & 0x7F)

class Assembler:
    def __init__(self):
        self.labels = {}
        self.sections = {".text.init": bytearray(), ".text": bytearray(), ".rodata": bytearray()}
        self.section_bases = {}
        self.symbols = []

    def read_with_includes(self, filename, base_dir=None):
        if base_dir is None:
            base_dir = os.path.dirname(os.path.abspath(filename))
        with open(filename, "r") as f:
            lines = f.readlines()
        expanded = []
        for line in lines:
            m = re.match(r'^\s*\.include\s*["<]([^">]+)[">]', line)
            if m:
                inc_file = os.path.join(base_dir, m.group(1))
                expanded.append(self.read_with_includes(inc_file, base_dir))
            else:
                expanded.append(line)
        return "".join(expanded)

    def assemble_file(self, filename):
        raw_text = self.read_with_includes(filename)

        # Remove multi-line /* ... */ comments
        cleaned_text = re.sub(r"/\*.*?\*/", "", raw_text, flags=re.DOTALL)
        lines = cleaned_text.splitlines()

        # Preprocessing: strip comments and clean lines
        cleaned_lines = []
        for line_num, raw_line in enumerate(lines, 1):
            line = raw_line.strip()
            # Remove // and # comments
            if "#" in line:
                line = line.split("#")[0].strip()
            if "//" in line:
                line = line.split("//")[0].strip()
            if line:
                cleaned_lines.append((line_num, line))

        # Pass 1: Parse instructions, pseudo-instructions, directives, and assign addresses
        current_section = ".text.init"
        sec_pc = {".text.init": 0, ".text": 0, ".rodata": 0}
        sec_items = {".text.init": [], ".text": [], ".rodata": []}

        for line_num, line in cleaned_lines:
            # Check for label(s)
            while ":" in line and not line.startswith("."):
                parts = line.split(":", 1)
                label_name = parts[0].strip()
                self.labels[label_name] = (current_section, sec_pc[current_section])
                self.symbols.append((label_name, current_section, sec_pc[current_section]))
                line = parts[1].strip()
                if not line:
                    break

            if not line:
                continue

            # Check for directives
            if line.startswith("."):
                tokens = line.split(None, 1)
                directive = tokens[0]
                rest = tokens[1].strip() if len(tokens) > 1 else ""

                if directive == ".section":
                    sec_name = rest.split(",")[0].strip().strip('"')
                    if sec_name in [".text.init", ".text", ".rodata"]:
                        current_section = sec_name
                    elif sec_name == ".text":
                        current_section = ".text"
                    elif sec_name == ".rodata":
                        current_section = ".rodata"
                    else:
                        current_section = ".text"
                elif directive in [".globl", ".global"]:
                    pass
                elif directive in [".string", ".asciz"]:
                    m = re.match(r'^"(.*)"$', rest)
                    if m:
                        s_bytes = bytes(m.group(1).encode("utf-8").decode("unicode_escape"), "latin1") + b"\x00"
                        sec_items[current_section].append(("bytes", s_bytes, line_num, line))
                        sec_pc[current_section] += len(s_bytes)
                elif directive == ".ascii":
                    m = re.match(r'^"(.*)"$', rest)
                    if m:
                        s_bytes = bytes(m.group(1).encode("utf-8").decode("unicode_escape"), "latin1")
                        sec_items[current_section].append(("bytes", s_bytes, line_num, line))
                        sec_pc[current_section] += len(s_bytes)
                elif directive in [".short", ".half"]:
                    vals = [int(v.strip(), 0) for v in rest.split(",")]
                    data = bytearray()
                    for v in vals:
                        data += struct.pack("<h", v)
                    sec_items[current_section].append(("bytes", bytes(data), line_num, line))
                    sec_pc[current_section] += len(data)
                elif directive == ".word":
                    words = [v.strip() for v in rest.split(",")]
                    sec_items[current_section].append(("words", words, line_num, line))
                    sec_pc[current_section] += len(words) * 4
                elif directive == ".byte":
                    vals = [int(v.strip(), 0) for v in rest.split(",")]
                    data = bytearray()
                    for v in vals:
                        data += struct.pack("<b", v)
                    sec_items[current_section].append(("bytes", bytes(data), line_num, line))
                    sec_pc[current_section] += len(data)
                elif directive == ".align":
                    align_bytes = 1 << int(rest) if int(rest) < 16 else int(rest)
                    pad = (align_bytes - (sec_pc[current_section] % align_bytes)) % align_bytes
                    if pad > 0:
                        sec_items[current_section].append(("bytes", b"\x00" * pad, line_num, line))
                        sec_pc[current_section] += pad
                continue

            # It is an instruction or pseudo-instruction
            # Let's count how many 32-bit words it produces
            instr_tokens = re.split(r"[,\s]+", line)
            op = instr_tokens[0].lower()
            args = [t.strip() for t in instr_tokens[1:] if t.strip()]

            # Handle expansion of pseudo-instructions
            if op == "li":
                # li rd, imm
                rd = args[0]
                imm_str = args[1]
                imm = int(imm_str, 0)
                if -2048 <= imm <= 2047:
                    sec_items[current_section].append(("instr", ("addi", [rd, "zero", imm_str]), line_num, line))
                    sec_pc[current_section] += 4
                else:
                    hi = (imm + 0x800) >> 12
                    lo = imm - (hi << 12)
                    sec_items[current_section].append(("instr", ("lui", [rd, hex(hi)]), line_num, line))
                    sec_pc[current_section] += 4
                    if lo != 0:
                        sec_items[current_section].append(("instr", ("addi", [rd, rd, hex(lo)]), line_num, line))
                        sec_pc[current_section] += 4
            elif op == "la":
                # la rd, label -> expands to lui + addi
                rd = args[0]
                label = args[1]
                sec_items[current_section].append(("la", (rd, label), line_num, line))
                sec_pc[current_section] += 8
            elif op == "call":
                target = args[0]
                sec_items[current_section].append(("call", target, line_num, line))
                sec_pc[current_section] += 4
            elif op == "csrw":
                csr = args[0]
                rs = args[1]
                sec_items[current_section].append(("instr", ("csrrw", ["zero", csr, rs]), line_num, line))
                sec_pc[current_section] += 4
            elif op == "csrr":
                rd = args[0]
                csr = args[1]
                sec_items[current_section].append(("instr", ("csrrs", [rd, csr, "zero"]), line_num, line))
                sec_pc[current_section] += 4
            elif op == "mv":
                sec_items[current_section].append(("instr", ("addi", [args[0], args[1], "0"]), line_num, line))
                sec_pc[current_section] += 4
            elif op == "nop":
                sec_items[current_section].append(("instr", ("addi", ["zero", "zero", "0"]), line_num, line))
                sec_pc[current_section] += 4
            elif op == "j":
                sec_items[current_section].append(("instr", ("jal", ["zero", args[0]]), line_num, line))
                sec_pc[current_section] += 4
            elif op == "ret":
                sec_items[current_section].append(("instr", ("jalr", ["zero", "ra", "0"]), line_num, line))
                sec_pc[current_section] += 4
            elif op == "beqz":
                sec_items[current_section].append(("instr", ("beq", [args[0], "zero", args[1]]), line_num, line))
                sec_pc[current_section] += 4
            elif op == "bnez":
                sec_items[current_section].append(("instr", ("bne", [args[0], "zero", args[1]]), line_num, line))
                sec_pc[current_section] += 4
            elif op == "bgez":
                sec_items[current_section].append(("instr", ("bge", [args[0], "zero", args[1]]), line_num, line))
                sec_pc[current_section] += 4
            elif op == "bltz":
                sec_items[current_section].append(("instr", ("blt", [args[0], "zero", args[1]]), line_num, line))
                sec_pc[current_section] += 4
            elif op == "bgt":
                sec_items[current_section].append(("instr", ("blt", [args[1], args[0], args[2]]), line_num, line))
                sec_pc[current_section] += 4
            elif op == "ble":
                sec_items[current_section].append(("instr", ("bge", [args[1], args[0], args[2]]), line_num, line))
                sec_pc[current_section] += 4
            elif op == "bgtu":
                sec_items[current_section].append(("instr", ("bltu", [args[1], args[0], args[2]]), line_num, line))
                sec_pc[current_section] += 4
            elif op == "bleu":
                sec_items[current_section].append(("instr", ("bgeu", [args[1], args[0], args[2]]), line_num, line))
                sec_pc[current_section] += 4
            elif op == "snez":
                sec_items[current_section].append(("instr", ("sltu", [args[0], "zero", args[1]]), line_num, line))
                sec_pc[current_section] += 4
            elif op == "seqz":
                sec_items[current_section].append(("instr", ("sltiu", [args[0], args[1], "1"]), line_num, line))
                sec_pc[current_section] += 4
            elif op == "not":
                sec_items[current_section].append(("instr", ("xori", [args[0], args[1], "-1"]), line_num, line))
                sec_pc[current_section] += 4
            elif op == "neg":
                sec_items[current_section].append(("instr", ("sub", [args[0], "zero", args[1]]), line_num, line))
                sec_pc[current_section] += 4
            elif op in ["beq", "bne", "blt", "bge", "bltu", "bgeu",
                        "lui", "auipc", "jal", "jalr",
                        "lw", "lh", "lb", "lbu", "lhu",
                        "sw", "sh", "sb",
                        "addi", "slti", "sltiu", "xori", "ori", "andi", "slli", "srli", "srai",
                        "add", "sub", "sll", "slt", "sltu", "xor", "srl", "sra", "or", "and",
                        "mul", "mulh", "mulhsu", "mulhu", "div", "divu", "rem", "remu",
                        "csrrw", "csrrs", "csrrc", "wfi", "ecall", "ebreak"]:
                sec_items[current_section].append(("instr", (op, args), line_num, line))
                sec_pc[current_section] += 4
            else:
                raise ValueError(f"Line {line_num}: Unknown mnemonic '{op}'")

        # Compute Absolute Section Base Addresses in IMEM
        # .text.init starts at 0x00000000
        # .text follows .text.init (aligned to 4)
        # .rodata follows .text (aligned to 4)
        base_init = 0x00000000
        size_init = sec_pc[".text.init"]
        
        base_text = (base_init + size_init + 3) & ~3
        size_text = sec_pc[".text"]
        
        base_rodata = (base_text + size_text + 3) & ~3
        size_rodata = sec_pc[".rodata"]

        self.section_bases = {
            ".text.init": base_init,
            ".text": base_text,
            ".rodata": base_rodata
        }

        # Resolve Absolute Label Addresses
        resolved_labels = {}
        for l_name, (sec, rel_pc) in self.labels.items():
            abs_addr = self.section_bases[sec] + rel_pc
            resolved_labels[l_name] = abs_addr

        # Pass 2: Assemble to Machine Code
        assembled_sections = {".text.init": bytearray(), ".text": bytearray(), ".rodata": bytearray()}
        disassembly_entries = []

        for sec in [".text.init", ".text", ".rodata"]:
            sec_abs_base = self.section_bases[sec]
            curr_pc = sec_abs_base

            for item_type, data, l_num, src_text in sec_items[sec]:
                if item_type == "bytes":
                    assembled_sections[sec] += data
                    # record in dump
                    disassembly_entries.append((curr_pc, data, src_text, "data"))
                    curr_pc += len(data)

                elif item_type == "words":
                    words = data
                    data_bytes = bytearray()
                    for w in words:
                        if w in resolved_labels:
                            val = resolved_labels[w]
                        else:
                            val = int(w, 0)
                        data_bytes += struct.pack("<I", val & 0xFFFFFFFF)
                    assembled_sections[sec] += data_bytes
                    disassembly_entries.append((curr_pc, bytes(data_bytes), src_text, "data"))
                    curr_pc += len(data_bytes)

                elif item_type == "la":
                    rd_name, label = data
                    rd = parse_reg(rd_name)
                    target_addr = resolved_labels[label]
                    hi = (target_addr + 0x800) >> 12
                    lo = target_addr - (hi << 12)
                    w1 = encode_u(hi << 12, rd, 0x37) # lui rd, hi
                    w2 = encode_i(lo, rd, 0, rd, 0x13) # addi rd, rd, lo
                    assembled_sections[sec] += struct.pack("<II", w1, w2)
                    disassembly_entries.append((curr_pc, struct.pack("<I", w1), f"lui {rd_name}, 0x{hi:x}", "instr"))
                    disassembly_entries.append((curr_pc + 4, struct.pack("<I", w2), f"addi {rd_name}, {rd_name}, {lo} # <{label}>", "instr"))
                    curr_pc += 8

                elif item_type == "call":
                    target = data
                    target_addr = resolved_labels[target]
                    offset = target_addr - curr_pc
                    w = encode_j(offset, 1, 0x6F) # jal ra, offset
                    assembled_sections[sec] += struct.pack("<I", w)
                    disassembly_entries.append((curr_pc, struct.pack("<I", w), f"jal ra, 0x{target_addr:x} <{target}>", "instr"))
                    curr_pc += 4

                elif item_type == "instr":
                    op, args = data
                    word = self.encode_instruction(op, args, curr_pc, resolved_labels, l_num)
                    assembled_sections[sec] += struct.pack("<I", word)
                    disassembly_entries.append((curr_pc, struct.pack("<I", word), src_text, "instr"))
                    curr_pc += 4

        return assembled_sections, resolved_labels, disassembly_entries

    def encode_instruction(self, op, args, pc, labels, line_num):
        if op == "lui":
            rd = parse_reg(args[0])
            imm = parse_imm(args[1], labels, pc)
            return encode_u(imm << 12 if imm < 0x100000 else imm, rd, 0x37)

        elif op == "auipc":
            rd = parse_reg(args[0])
            imm = parse_imm(args[1], labels, pc)
            return encode_u(imm << 12 if imm < 0x100000 else imm, rd, 0x17)

        elif op == "jal":
            rd = parse_reg(args[0])
            if args[1] in labels:
                offset = labels[args[1]] - pc
            else:
                offset = parse_imm(args[1], labels, pc)
            return encode_j(offset, rd, 0x6F)

        elif op == "jalr":
            rd = parse_reg(args[0])
            if len(args) == 2: # jalr rd, rs1 or jalr rs1
                rs1 = parse_reg(args[1])
                offset = 0
            else: # jalr rd, rs1, offset or jalr rd, offset(rs1)
                if "(" in args[1]:
                    offset, rs1 = parse_mem_operand(args[1])
                else:
                    rs1 = parse_reg(args[1])
                    offset = parse_imm(args[2], labels, pc)
            return encode_i(offset, rs1, 0, rd, 0x67)

        elif op in ["beq", "bne", "blt", "bge", "bltu", "bgeu"]:
            rs1 = parse_reg(args[0])
            rs2 = parse_reg(args[1])
            target_str = args[2]
            if target_str in labels:
                offset = labels[target_str] - pc
            else:
                offset = parse_imm(target_str, labels, pc)
            funct3_map = {"beq": 0, "bne": 1, "blt": 4, "bge": 5, "bltu": 6, "bgeu": 7}
            return encode_b(offset, rs2, rs1, funct3_map[op], 0x63)

        elif op in ["lw", "lh", "lb", "lhu", "lbu"]:
            rd = parse_reg(args[0])
            offset, rs1 = parse_mem_operand(args[1])
            funct3_map = {"lb": 0, "lh": 1, "lw": 2, "lbu": 4, "lhu": 5}
            return encode_i(offset, rs1, funct3_map[op], rd, 0x03)

        elif op in ["sw", "sh", "sb"]:
            rs2 = parse_reg(args[0])
            offset, rs1 = parse_mem_operand(args[1])
            funct3_map = {"sb": 0, "sh": 1, "sw": 2}
            return encode_s(offset, rs2, rs1, funct3_map[op], 0x23)

        elif op in ["addi", "slti", "sltiu", "xori", "ori", "andi", "slli", "srli", "srai"]:
            rd = parse_reg(args[0])
            rs1 = parse_reg(args[1])
            imm = parse_imm(args[2], labels, pc)
            funct3_map = {"addi": 0, "slli": 1, "slti": 2, "sltiu": 3, "xori": 4, "srli": 5, "srai": 5, "ori": 6, "andi": 7}
            if op == "srai":
                imm = (imm & 0x1F) | 0x400
            elif op in ["slli", "srli"]:
                imm = imm & 0x1F
            return encode_i(imm, rs1, funct3_map[op], rd, 0x13)

        elif op in ["add", "sub", "sll", "slt", "sltu", "xor", "srl", "sra", "or", "and"]:
            rd = parse_reg(args[0])
            rs1 = parse_reg(args[1])
            rs2 = parse_reg(args[2])
            funct3_map = {"add": 0, "sub": 0, "sll": 1, "slt": 2, "sltu": 3, "xor": 4, "srl": 5, "sra": 5, "or": 6, "and": 7}
            funct7 = 0x20 if op in ["sub", "sra"] else 0x00
            return encode_r(funct7, rs2, rs1, funct3_map[op], rd, 0x33)

        elif op in ["mul", "mulh", "mulhsu", "mulhu", "div", "divu", "rem", "remu"]:
            rd = parse_reg(args[0])
            rs1 = parse_reg(args[1])
            rs2 = parse_reg(args[2])
            funct3_map = {"mul": 0, "mulh": 1, "mulhsu": 2, "mulhu": 3, "div": 4, "divu": 5, "rem": 6, "remu": 7}
            return encode_r(0x01, rs2, rs1, funct3_map[op], rd, 0x33)

        elif op in ["csrrw", "csrrs", "csrrc"]:
            rd = parse_reg(args[0])
            csr_name = args[1].lower()
            csr_addr = CSRS.get(csr_name, int(csr_name, 0) if csr_name.startswith("0x") else 0)
            rs1 = parse_reg(args[2])
            funct3_map = {"csrrw": 1, "csrrs": 2, "csrrc": 3}
            return encode_i(csr_addr, rs1, funct3_map[op], rd, 0x73)

        elif op == "wfi":
            return 0x10500073
        elif op == "ecall":
            return 0x00000073
        elif op == "ebreak":
            return 0x00100073
        else:
            raise ValueError(f"Line {line_num}: Cannot encode instruction {op}")

def generate_intel_hex(imem_bytes, dmem_bytes=None):
    lines = []
    # IMEM starts at 0x00000000
    # Extended Linear Address Record (base 0x0000)
    lines.append(":020000040000FA")

    # Data records (16 bytes per line)
    for addr in range(0, len(imem_bytes), 16):
        chunk = imem_bytes[addr:addr+16]
        rec_len = len(chunk)
        offset = addr & 0xFFFF
        chksum = rec_len + ((offset >> 8) & 0xFF) + (offset & 0xFF) + 0x00
        data_str = ""
        for b in chunk:
            chksum += b
            data_str += f"{b:02X}"
        chksum_byte = (~chksum + 1) & 0xFF
        lines.append(f":{rec_len:02X}{offset:04X}00{data_str}{chksum_byte:02X}")

    # Entry point record (Start Linear Address: 0x00000000)
    lines.append(":0400000500000000F7")
    # End of File Record
    lines.append(":00000001FF")
    return "\n".join(lines) + "\n"

def generate_verilog_hex(imem_bytes):
    # Verilog hex for $readmemh into 32-bit word array
    lines = ["@00000000"]
    # Pad to word boundary
    padded = bytearray(imem_bytes)
    while len(padded) % 4 != 0:
        padded.append(0)
    for i in range(0, len(padded), 4):
        word = struct.unpack("<I", padded[i:i+4])[0]
        lines.append(f"{word:08x}")
    return "\n".join(lines) + "\n"

def generate_elf32(imem_bytes, labels, symbols):
    # Construct a valid RV32 ELF executable
    # ELF Header: 52 bytes
    # Program Header: 32 bytes (PT_LOAD)
    # Section Headers: NULL, .text, .rodata, .symtab, .strtab, .shstrtab
    
    e_entry = 0x00000000
    phoff = 52
    phentsize = 32
    phnum = 1
    
    load_vaddr = 0x00000000
    load_filesz = len(imem_bytes)
    load_memsz = len(imem_bytes)
    
    # We will lay out the file:
    # 0..51: ELF Header
    # 52..83: Program Header 1
    # 84..84+len(imem_bytes)-1: File image of code/data
    # then symtab, strtab, shstrtab, shdrs
    
    file_img = bytearray()
    file_img += b"\x00" * (phoff + phentsize)
    
    # Align to 4
    while len(file_img) % 4 != 0:
        file_img.append(0)
    code_file_offset = len(file_img)
    file_img += imem_bytes
    
    # String tables
    strtab = bytearray(b"\x00")
    symtab = bytearray(b"\x00" * 16) # entry 0: NULL symbol
    
    def add_sym(name, val, size=0, info=0x12): # STB_GLOBAL | STT_FUNC
        nonlocal strtab, symtab
        str_idx = len(strtab)
        strtab += name.encode("ascii") + b"\x00"
        # Elf32_Sym: st_name(4), st_value(4), st_size(4), st_info(1), st_other(1), st_shndx(2)
        symtab += struct.pack("<IIIBBH", str_idx, val, size, info, 0, 1)

    for sym_name, sec, val in symbols:
        info = 0x12 if sec in [".text.init", ".text"] else 0x11
        add_sym(sym_name, val, 4, info)

    # String table for section names (.shstrtab)
    shstrtab = bytearray(b"\x00")
    def add_shstr(name):
        nonlocal shstrtab
        idx = len(shstrtab)
        shstrtab += name.encode("ascii") + b"\x00"
        return idx

    sh_names = ["", ".text", ".rodata", ".symtab", ".strtab", ".shstrtab"]
    sh_indices = [add_shstr(n) for n in sh_names]

    while len(file_img) % 4 != 0:
        file_img.append(0)
    symtab_offset = len(file_img)
    file_img += symtab

    while len(file_img) % 4 != 0:
        file_img.append(0)
    strtab_offset = len(file_img)
    file_img += strtab

    while len(file_img) % 4 != 0:
        file_img.append(0)
    shstrtab_offset = len(file_img)
    file_img += shstrtab

    while len(file_img) % 4 != 0:
        file_img.append(0)
    shoff = len(file_img)
    shentsize = 40
    shnum = 6
    shstrndx = 5

    # Build Section Headers:
    # Elf32_Shdr: sh_name(4), sh_type(4), sh_flags(4), sh_addr(4), sh_offset(4), sh_size(4), sh_link(4), sh_info(4), sh_addralign(4), sh_entsize(4)
    shdrs = bytearray()
    # 0: NULL
    shdrs += struct.pack("<IIIIIIIIII", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    # 1: .text (PROGBITS, ALLOC|EXEC, addr 0x0)
    shdrs += struct.pack("<IIIIIIIIII", sh_indices[1], 1, 6, 0, code_file_offset, len(imem_bytes), 0, 0, 4, 0)
    # 2: .rodata (PROGBITS, ALLOC, addr 0x0)
    shdrs += struct.pack("<IIIIIIIIII", sh_indices[2], 1, 2, 0, code_file_offset, len(imem_bytes), 0, 0, 4, 0)
    # 3: .symtab (SYMTAB)
    shdrs += struct.pack("<IIIIIIIIII", sh_indices[3], 2, 0, 0, symtab_offset, len(symtab), 4, len(symbols)+1, 4, 16)
    # 4: .strtab (STRTAB)
    shdrs += struct.pack("<IIIIIIIIII", sh_indices[4], 3, 0, 0, strtab_offset, len(strtab), 0, 0, 1, 0)
    # 5: .shstrtab (STRTAB)
    shdrs += struct.pack("<IIIIIIIIII", sh_indices[5], 3, 0, 0, shstrtab_offset, len(shstrtab), 0, 0, 1, 0)

    file_img += shdrs

    # Write ELF Header at offset 0
    # e_ident: 16 bytes
    # e_type(2), e_machine(2), e_version(4), e_entry(4), e_phoff(4), e_shoff(4), e_flags(4), e_ehsize(2), e_phentsize(2), e_phnum(2), e_shentsize(2), e_shnum(2), e_shstrndx(2)
    e_ident = b"\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00" # ELF32, little-endian, version 1
    ehdr = struct.pack("<16sHHIIIIIHHHHHH",
                       e_ident, 2, 243, 1, e_entry, phoff, shoff, 0, 52, phentsize, phnum, shentsize, shnum, shstrndx)
    file_img[0:52] = ehdr

    # Write Program Header 1 at offset 52
    # Elf32_Phdr: p_type(4), p_offset(4), p_vaddr(4), p_paddr(4), p_filesz(4), p_memsz(4), p_flags(4), p_align(4)
    # p_flags: PF_R (4) | PF_X (1) = 5
    phdr = struct.pack("<IIIIIIII", 1, code_file_offset, load_vaddr, load_vaddr, load_filesz, load_memsz, 5, 4)
    file_img[52:84] = phdr

    return bytes(file_img)

def generate_disassembly_dump(disassembly_entries, labels):
    # Invert labels to get names by address
    addr_to_labels = {}
    for l_name, l_addr in labels.items():
        if l_addr not in addr_to_labels:
            addr_to_labels[l_addr] = []
        addr_to_labels[l_addr].append(l_name)

    lines = []
    lines.append("cardioedge_test.elf:     file format elf32-littleriscv")
    lines.append("")
    lines.append("Disassembly of section .text:")
    lines.append("")

    for addr, raw_data, src_text, item_type in disassembly_entries:
        if addr in addr_to_labels:
            for l in addr_to_labels[addr]:
                lines.append(f"{addr:08x} <{l}>:")

        if item_type == "instr":
            word = struct.unpack("<I", raw_data)[0]
            lines.append(f"   {addr:08x}:  {word:08x}          {src_text}")
        else:
            hex_bytes = " ".join(f"{b:02x}" for b in raw_data[:16])
            lines.append(f"   {addr:08x}:  {hex_bytes:<32}  .data {src_text}")

    return "\n".join(lines) + "\n"

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)

    asm_file = "cardioedge_test.s"
    if not os.path.exists(asm_file):
        print(f"[-] ERROR: Source assembly {asm_file} not found!")
        sys.exit(1)

    print("==================================================================")
    print("    CARDIOEDGE Firmware Compilation & Machine Generation Utility")
    print("    Target: Western Digital VeeR EL2 (RV32IMC)")
    print("==================================================================")
    print(f"[*] Assembling {asm_file}...")

    asm = Assembler()
    assembled_sections, labels, disasm_entries = asm.assemble_file(asm_file)

    # Combine sections into unified IMEM contiguous image
    imem_full = bytearray()
    imem_full += assembled_sections[".text.init"]
    # Pad to .text base
    pad_text = asm.section_bases[".text"] - len(imem_full)
    if pad_text > 0:
        imem_full += b"\x00" * pad_text
    imem_full += assembled_sections[".text"]
    # Pad to .rodata base
    pad_rodata = asm.section_bases[".rodata"] - len(imem_full)
    if pad_rodata > 0:
        imem_full += b"\x00" * pad_rodata
    imem_full += assembled_sections[".rodata"]

    print(f"[+] Total IMEM Code + Rodata Size: {len(imem_full)} bytes")
    print(f"    - .text.init: {len(assembled_sections['.text.init'])} bytes (base 0x{asm.section_bases['.text.init']:08x})")
    print(f"    - .text:      {len(assembled_sections['.text'])} bytes (base 0x{asm.section_bases['.text']:08x})")
    print(f"    - .rodata:    {len(assembled_sections['.rodata'])} bytes (base 0x{asm.section_bases['.rodata']:08x})")
    print(f"    - Entry PC:   0x00000000 (_start)")

    # 1. Generate cardioedge_test.elf
    print("[1/4] Generating ELF32 executable: cardioedge_test.elf...")
    elf_data = generate_elf32(bytes(imem_full), labels, asm.symbols)
    with open("cardioedge_test.elf", "wb") as f:
        f.write(elf_data)

    # 2. Generate cardioedge_test.hex
    print("[2/4] Generating Intel HEX image: cardioedge_test.hex...")
    hex_str = generate_intel_hex(bytes(imem_full))
    with open("cardioedge_test.hex", "w") as f:
        f.write(hex_str)

    # 3. Generate cardioedge_test.vhx
    print("[3/4] Generating Verilog HEX image: cardioedge_test.vhx...")
    vhx_str = generate_verilog_hex(bytes(imem_full))
    with open("cardioedge_test.vhx", "w") as f:
        f.write(vhx_str)

    # 4. Generate cardioedge_test.dump
    print("[4/4] Generating disassembly report: cardioedge_test.dump...")
    dump_str = generate_disassembly_dump(disasm_entries, labels)
    with open("cardioedge_test.dump", "w") as f:
        f.write(dump_str)

    print("==================================================================")
    print("    BUILD SUCCESSFUL: All firmware binaries created.")
    print("==================================================================")

if __name__ == "__main__":
    main()
