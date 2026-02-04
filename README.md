# RISC-V 5-Stage Pipeline Simulator

This project implements a **5-stage RISC-V pipeline simulator** in **C language**.

## Key Features
 
* 5 pipeline stages: **IF, ID, EX, MEM, WB**
* Separate function for each stage and each pipeline register
* 32-register RISC-V register file (`x0` always 0)
* **Data forwarding** from EX/MEM and MEM/WB stages
* Supports instructions:
  `add`, `sub`, `addi`, `and`, `or`, `xor`, `halt`
* Detects **illegal instructions**, flushes pipeline, and stops execution
* Prints instruction flow and first **8 register values per cycle**
* Displays final register values

## Instruction Input

Instructions are read from `inst.txt` in RISC-V format.

## Example Program

```
addi x1,x0,10
addi x2,x0,3
add  x3,x1,x2
sub  x4,x3,x2
and  x3,x4,x1
halt
```

## Compile & Run

```bash
gcc pipeline.c -o pipeline
./pipeline
```
