# RISC-V 5-Stage Pipeline Simulator
The project models instruction execution cycle-by-cycle and demonstrates:

* Data hazards
* Forwarding
* Load-use stall
* Register writeback
* Memory operations

---

## Features

✔ 5 Pipeline Stages

* IF  – Instruction Fetch
* ID  – Instruction Decode
* EX  – Execute (ALU + Forwarding)
* MEM – Memory Access
* WB  – Write Back

✔ Hazard Handling

* Forwarding from EX/MEM & MEM/WB
* Load-use stall detection

✔ Instruction Support

* Arithmetic: `add sub addi and or xor`
* Memory: `lw sw`
* Control: `halt`
* Automatic `NOP` insertion

✔ Cycle-by-cycle output

* Shows pipeline contents every cycle
* Shows register values after each cycle
* Final register dump

---

## 🧱 Project Structure

```
.
├── pipeline.c        # Main simulator source code
├── inst.txt         # Input instruction file
└── README.md
```

---

## ⚙️ How It Works

The simulator mimics real hardware pipeline behavior.

Each clock cycle:

1. WB stage writes result to register file
2. MEM accesses data memory
3. EX performs ALU + forwarding
4. ID decodes and checks hazards
5. IF fetches next instruction

Then pipeline registers are updated simultaneously (rising clock edge).

---

## ▶️ How To Compile & Run

### Linux / Mac

```bash
gcc pipeline.c -o pipeline
./pipeline
```

### Windows (MinGW)

```bash
gcc pipeline.c -o pipeline.exe
pipeline.exe
```


