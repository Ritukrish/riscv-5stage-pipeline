# Linear Search using Custom RISC-V Pipeline Simulator

## 📌 Project Description

This project implements **Linear Search** using a custom 5-stage pipelined processor simulator written in C.

The simulator supports the following instruction set:

```
ADD, SUB, ADDI, AND, OR, XOR, LW, SW, BEQ, HALT, NOP
```

The linear search algorithm is written in assembly using only the supported instructions.

---

# 📂 Memory Layout

The array is stored in `DATA_MEM` starting at address **100**.

Example data:

| Address | Value |
| ------- | ----- |
| 100     | 1     |
| 104     | 2     |
| 108     | 3     |
| 112     | 4     |
| 116     | 5     |

Array size: `5`

---

# 🔎 Linear Search – Element Found Case

Searching for value **4**.

### Assembly Code

```assembly
addi x1,x0,100
addi x2,x0,5
addi x3,x0,0
addi x6,x0,4
addi x7,x0,-1
beq x3,x2,7
lw x4,0(x1)
beq x4,x6,4
addi x1,x1,4
addi x3,x3,1
beq x0,x0,-5
add x7,x3,x0
halt
```

---

## 🧠 Register Usage

| Register | Purpose                        |
| -------- | ------------------------------ |
| x1       | Array base pointer             |
| x2       | Array size (n)                 |
| x3       | Index (i)                      |
| x4       | Loaded array value             |
| x6       | Search key                     |
| x7       | Result index (-1 if not found) |

---

## ✅ Output (Element Found)

```
===== FINAL REGISTER STATE =====
x0  = 0    x1  = 112  x2  = 5    x3  = 3    x4  = 4    x5  = 0    x6  = 4    x7  = 3
x8  = 0    x9  = 0    x10 = 0    x11 = 0    x12 = 0    x13 = 0    x14 = 0    x15 = 0
x16 = 0    x17 = 0    x18 = 0    x19 = 0    x20 = 0    x21 = 0    x22 = 0    x23 = 0
x24 = 0    x25 = 0    x26 = 0    x27 = 0    x28 = 0    x29 = 0    x30 = 0    x31 = 0
```

### ✔ Explanation

The value **4** is located at index **3** in the array:

```
[1, 2, 3, 4, 5]
 0  1  2  3  4
```

So:

```
x7 = 3
```

---

# ❌ Linear Search – Element NOT Found Case

Searching for value **10**.

### Assembly Code

```assembly
addi x1,x0,100
addi x2,x0,5
addi x3,x0,0
addi x6,x0,10
addi x7,x0,-1
beq x3,x2,7
lw x4,0(x1)
beq x4,x6,4
addi x1,x1,4
addi x3,x3,1
beq x0,x0,-5
add x7,x3,x0
halt
```

---

## ✅ Output (Element Not Found)

```
===== FINAL REGISTER STATE =====
x0  = 0    x1  = 120  x2  = 5    x3  = 5    x4  = 5    x5  = 0    x6  = 10   x7  = -1
x8  = 0    x9  = 0    x10 = 0    x11 = 0    x12 = 0    x13 = 0    x14 = 0    x15 = 0
x16 = 0    x17 = 0    x18 = 0    x19 = 0    x20 = 0    x21 = 0    x22 = 0    x23 = 0
x24 = 0    x25 = 0    x26 = 0    x27 = 0    x28 = 0    x29 = 0    x30 = 0    x31 = 0
```

### ✔ Explanation

The value **10** does not exist in the array.

The loop runs until:

```
i == n  → 5
```

So:

```
x7 = -1
```

which represents **NOT FOUND**.

---

# ⚙️ How the Algorithm Works

Pseudo-code:

```
result = -1
for i from 0 to n-1:
    if arr[i] == key:
        result = i
        break
```
