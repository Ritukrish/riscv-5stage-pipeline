# RISC-V 5-Stage Pipeline Simulator

## Factorial Program Execution (Using Loop-Based Multiplication)

This project extends the pipelined processor simulator to execute an assembly program that computes the **factorial of a number (N!)**.

The processor is a simplified RISC-V-like architecture implemented in C that models real CPU pipeline behavior including hazards and forwarding.

---

## Objective

Implement and execute a factorial program in assembly on a **5-stage pipelined processor** and observe:

* Data hazards
* Control hazards
* Pipeline stalls
* Branch flushing
* Forwarding

---

## What the Program Computes

We compute:

```
N = 5
Factorial = 5! = 120
```

The factorial is computed using repeated multiplication:

```
fact = fact × i
```

Since our ISA does not include a `mul` instruction, multiplication is implemented using **repeated addition (nested loop)**.

---

## Assembly Program

```
addi x1,x0,5        # N = 5
addi x2,x0,1        # i = 1
addi x3,x0,1        # fact = 1

beq x2,x1,11        # if i==N goto end

addi x2,x2,1        # i++

addi x6,x3,0        # temp = fact
addi x5,x0,0        # result = 0
addi x4,x0,0        # counter = 0

add x5,x5,x6        # result += temp
addi x4,x4,1        # counter++

beq x4,x2,2         # if counter==i exit multiply
beq x0,x0,-3        # loop multiply

addi x3,x5,0        # fact = result
beq x0,x0,-10       # repeat outer loop

halt
```

---

## Register Usage

| Register | Purpose                     |
| -------- | --------------------------- |
| x1       | N (input number)            |
| x2       | Loop variable i             |
| x3       | factorial result            |
| x4       | inner loop counter          |
| x5       | multiplication result       |
| x6       | temporary copy of factorial |

Final expected value:

```
x3 = 120
```

---

## Pipeline Architecture

The processor implements a classic 5-stage pipeline:

| Stage | Function               |
| ----- | ---------------------- |
| IF    | Instruction Fetch      |
| ID    | Decode + Register Read |
| EX    | ALU Execution          |
| MEM   | Memory Access          |
| WB    | Write Back             |

---

## Hazard Handling Implemented

### 1. Data Hazard — Forwarding

Example:

```
add x5,x5,x6
addi x4,x4,1
beq x4,x2,2
```

The branch depends on the updated value of `x4`.

Forwarding allows the correct value to reach EX stage without waiting.

---

### 2. Load-Use Hazard — Stall

The simulator detects when a register is used immediately after load and inserts:

```
ID : STALL
IF : STALL
```

(Though factorial program mainly shows arithmetic hazards)

---

### 3. Control Hazard — Branch Flush

Branches are resolved in EX stage:

```
beq x4,x2,2
beq x0,x0,-3
beq x0,x0,-10
```

When branch is taken:

```
IF : FLUSH (BRANCH)
ID : FLUSH
```

Pipeline clears incorrect instructions.

---

## Program Behavior

The program contains **nested loops**:

* Outer loop → iterate from 1 to N
* Inner loop → multiply using repeated addition

This creates heavy control hazards — ideal for observing pipeline behavior.

---

## Expected Output

Final register state:

```
x3 = 120
```

The simulator also generates:

```
Cycle by cycle pipeline trace
Console output
output.txt log file
```

---

## Observations

| Feature        | Observed               |
| -------------- | ---------------------- |
| Forwarding     | Frequent               |
| Branch Hazard  | Very frequent (loops)  |
| Pipeline Flush | Many times             |
| Stalls         | Occasional             |
| CPI            | Higher due to branches |

The factorial program shows significantly worse performance than array sum due to nested loops causing branch penalties.

---

## How to Run

Compile:

```
gcc pipeline.c -o sim
```

Run:

```
./sim
```

Output will be printed to:

```
Console
output.txt
```

Factorial is a perfect example of **branch-heavy workload** in pipeline architecture.

---

## Final Result

```
Input : 5
Output: 120
Register x3 = 120
```


If you want, I can also calculate the **approximate CPI of this factorial program** — that’s a very common viva question.
