# RISC-V 5-Stage Pipeline Simulator

## Sum of N Numbers using Assembly

This project implements a **5-stage pipelined processor simulator** in C and executes a RISC-V-like assembly program to compute the **sum of an array of N numbers stored in memory**.

The simulator models real processor behavior including:

* Instruction Fetch
* Decode
* Execute
* Memory Access
* Write Back
* Data Forwarding
* Load-Use Stall
* Branch Hazard + Pipeline Flush

---

## Problem Statement

An array is stored in memory such that:

| Memory Location | Meaning                   |
| --------------- | ------------------------- |
| 96              | Size of array (N)         |
| 100             | Starting address of array |
| Next addresses  | Array elements            |

The goal is to:

> Write an assembly program to compute the sum of all array elements
> Then execute it in a pipelined processor and observe behavior

---

## Memory Initialization

Inside the simulator:

```c
int n = 5;
DATA_MEM[96] = n;

DATA_MEM[100] = 1;
DATA_MEM[104] = 2;
DATA_MEM[108] = 3;
DATA_MEM[112] = 4;
DATA_MEM[116] = 5;
```

Expected result:

```
SUM = 1 + 2 + 3 + 4 + 5 = 15
```

Final answer stored in register:

```
x4 = 15
```

---

## Assembly Program

```
addi x1,x0,5        # N = 5
addi x2,x0,100      # base address
addi x3,x0,0        # i = 0
addi x4,x0,0        # sum = 0

beq x3,x1,6         # if i==N exit

lw x5,0(x2)         # load array[i]
add x4,x4,x5        # sum += arr[i]

addi x2,x2,4        # next element
addi x3,x3,1        # i++

beq x0,x0,-5        # loop back
halt
```

---

## Pipeline Architecture

5-stage pipeline implemented:

| Stage | Description             |
| ----- | ----------------------- |
| IF    | Fetch instruction       |
| ID    | Decode + Read registers |
| EX    | ALU operations          |
| MEM   | Memory access           |
| WB    | Write back result       |

---

## Implemented Hazards

### 1. Data Hazard (Forwarding)

Forwarding from EX/MEM and MEM/WB:

```
add x4,x4,x5
addi x3,x3,1
```

Without forwarding → wrong sum
With forwarding → correct execution

---

### 2. Load-Use Hazard (STALL)

```
lw x5,0(x2)
add x4,x4,x5
```

The value from memory is not ready immediately → pipeline stall inserted.

Output example:

```
ID : STALL
IF : STALL
```

---

### 3. Control Hazard (Branch Flush)

```
beq x3,x1,6
beq x0,x0,-5
```

When branch is taken:

```
IF : FLUSH (BRANCH)
ID : FLUSH
```

Pipeline clears wrong instructions.

---

## Pipeline Behavior Observations

| Hazard     | Occurs | Action            |
| ---------- | ------ | ----------------- |
| RAW        | Yes    | Forwarding        |
| Load-Use   | Yes    | 1 cycle stall     |
| Branch     | Yes    | Flush             |
| Structural | No     | Separate memories |

---

## How to Run

### Compile

```bash
gcc pipeline.c -o sim
```

### Run

```bash
./sim
```

### Output

Console + `output.txt`:

```
--- CYCLE 1 ---
IF  : addi x1,x0,5
ID  : ...
EX  : ...
MEM : ...
WB  : ...
```

Final registers:

```
x4 = 15
```
