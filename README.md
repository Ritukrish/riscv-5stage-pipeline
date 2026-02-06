# RISC-V 5-Stage Pipeline Simulator

This project implements a **cycle-accurate 5-stage RISC-V pipeline simulator** in the C programming language.
It demonstrates how a real processor executes instructions using pipelining, forwarding, and hazard detection.

---

## Pipeline Stages

The simulator models a classic 5-stage processor:

| Stage | Description                               |
| ----- | ----------------------------------------- |
| IF    | Instruction Fetch from instruction memory |
| ID    | Instruction Decode & register read        |
| EX    | ALU operation / address calculation       |
| MEM   | Data memory access (Load/Store)           |
| WB    | Write result back to register             |

Each stage is implemented as a separate function and communicates using pipeline registers.

---

## Key Features

* Full 5-stage pipeline execution
* Separate pipeline registers: IF/ID, ID/EX, EX/MEM, MEM/WB
* 32-register RISC-V register file (x0 always 0)
* Data forwarding from EX/MEM and MEM/WB
* Load-use hazard detection and pipeline stall insertion
* Supports memory operations (lw, sw)
* Stops execution when `halt` instruction completes
* Displays instruction flow per cycle
* Prints register values every cycle
* Final register dump at program end

---

## Supported Instructions

### Arithmetic & Logical

```
add  rd, rs1, rs2
sub  rd, rs1, rs2
addi rd, rs1, imm
and  rd, rs1, rs2
or   rd, rs1, rs2
xor  rd, rs1, rs2
```

### Memory Instructions

```
lw rd, offset(rs1)     // Load word from memory
sw rs2, offset(rs1)    // Store word to memory
```

### Control

```
halt
```

---

## Hazard Handling

### Data Forwarding

Values are forwarded from:

* EX/MEM → EX
* MEM/WB → EX

This removes most RAW hazards.

### Load-Use Hazard Stall

If an instruction uses a register immediately after a `lw`, the pipeline inserts a stall (NOP):

Example:

```
lw x3,0(x1)
add x4,x3,x2   ← stall inserted
```

---

## Instruction Input

Instructions are read from a file named:

```
inst2.txt
```

---

## Example Program

```
addi x1,x0,100
addi x2,x0,10
sw   x2,0(x1)
lw   x3,0(x1)
add  x4,x3,x2
halt
```

---

## Output

For each cycle the simulator prints:

* Instruction in each pipeline stage
* Stall when hazard occurs
* Register values

At the end:

```
Final register state is displayed
```

---

## Compilation & Run

```
gcc pipeline.c -o pipeline
./pipeline
```


