#include <stdio.h>
#include <string.h>
#include <stdarg.h>

#define REG_COUNT 32
#define MEM_SIZE 1024
#define MAX_INST 50

/* ================= OPCODES ================= */
typedef enum
{
    ADD,SUB,ADDI,AND,OR,XOR,LW,SW,BEQ,HALT,NOP} opcode_t;

typedef struct
{    opcode_t op;
    int rd, rs1, rs2, imm;
    char text[40];
} instruction_t;

/* ================= PIPELINE REGISTERS ================= */
typedef struct
{
    instruction_t instr;
    int pc;
} IF_ID;

typedef struct
{
    instruction_t instr;
    int pc;
    int RD1, RD2, RegWrite, MemRead, MemWrite;
} ID_EX;

typedef struct
{
    instruction_t instr;
    int ALUOut, WriteData, RegWrite, MemRead, MemWrite;
} EX_MEM;

typedef struct
{
    instruction_t instr;
    int Result, RegWrite;
} MEM_WB;

/* ================= GLOBALS ================= */
int REG[REG_COUNT], DATA_MEM[MEM_SIZE];
int PC = 0, inst_count = 0, halted = 0, cycle = 1, stall = 0;

int branch_taken = 0;
int branch_target = 0;

instruction_t INST_MEM[MAX_INST];
IF_ID if_id, if_id_o;
ID_EX id_ex, id_ex_o;
EX_MEM ex_mem, ex_mem_o;
MEM_WB mem_wb, mem_wb_o;

FILE *out_file;
/* ================= PRINT ================= */
void print_log(const char *format, ...) {
    va_list args;
    
    // Print to Console
    va_start(args, format);
    vprintf(format, args);
    va_end(args);

    // Print to File
    va_start(args, format);
    vfprintf(out_file, format, args);
    va_end(args);
}

void print_registers()
{
    print_log("Registers: ");
    for (int i = 0; i < 8; i++)
        print_log("x%d=%d ", i, REG[i]);
    print_log("\n");
}

void final_register_dump()
{
    print_log("\n===== FINAL REGISTER STATE =====\n");
    for (int i = 0; i < REG_COUNT; i++)
    {
        print_log("x%-2d = %-5d", i, REG[i]);
        if ((i + 1) % 8 == 0)
            print_log("\n");
    }
}

/* ================= FETCH ================= */
void fetch()
{
    if (halted)
        return;

    if (branch_taken)
    {
        PC = branch_target;
        branch_taken = 0;

        if_id_o.instr.op = NOP;
        strcpy(if_id_o.instr.text, "FLUSH");
        print_log("IF  : FLUSH (BRANCH)\n");
        return;
    }
    if (stall)
    {
        print_log("IF  : STALL\n");
        return;
    }
    int index = PC / 4;
    if (index >= inst_count)
    {
        if_id_o.instr.op = NOP;
        strcpy(if_id_o.instr.text, "NOP");
    }
    else
    {
        if_id_o.instr = INST_MEM[index];
        if_id_o.pc = PC;
        PC += 4;
    }
    print_log("IF  : %s\n", if_id_o.instr.text);
}

/* ================= DECODE ================= */
void decode()
{
    if (branch_taken)
    {
        id_ex_o.instr.op = NOP;
        strcpy(id_ex_o.instr.text, "FLUSH");
        id_ex_o.RegWrite = id_ex_o.MemRead = id_ex_o.MemWrite = 0;
        print_log("ID  : FLUSH\n");
        return;
    }
    if (id_ex.MemRead &&
        (id_ex.instr.rd == if_id.instr.rs1 ||
         id_ex.instr.rd == if_id.instr.rs2))
    {
        stall = 1;
        id_ex_o.instr.op = NOP;
        strcpy(id_ex_o.instr.text, "STALL");
        id_ex_o.RegWrite = id_ex_o.MemRead = id_ex_o.MemWrite = 0;
        print_log("ID  : STALL\n");
        return;
    }
    stall = 0;
    id_ex_o.instr = if_id.instr;
     id_ex_o.pc = if_id.pc;
    id_ex_o.RD1 = REG[if_id.instr.rs1];
    id_ex_o.RD2 = REG[if_id.instr.rs2];

    id_ex_o.RegWrite =
        (if_id.instr.op != SW &&
         if_id.instr.op != HALT &&
         if_id.instr.op != NOP &&
         if_id.instr.op != BEQ);

    id_ex_o.MemRead = (if_id.instr.op == LW);
    id_ex_o.MemWrite = (if_id.instr.op == SW);

    print_log("ID  : %s\n", id_ex_o.instr.text);
}

/* ================= EXECUTE ================= */
void execute()
{
    ex_mem_o.instr = id_ex.instr;
    ex_mem_o.RegWrite = id_ex.RegWrite;
    ex_mem_o.MemRead = id_ex.MemRead;
    ex_mem_o.MemWrite = id_ex.MemWrite;

    int A = id_ex.RD1, B = id_ex.RD2;

    /* Forwarding */
    if (ex_mem.RegWrite && ex_mem.instr.rd != 0)
    {
        if (ex_mem.instr.rd == id_ex.instr.rs1)
            A = ex_mem.ALUOut;
        if (ex_mem.instr.rd == id_ex.instr.rs2)
            B = ex_mem.ALUOut;
    }
    if (mem_wb.RegWrite && mem_wb.instr.rd != 0)
    {
        if (mem_wb.instr.rd == id_ex.instr.rs1)
            A = mem_wb.Result;
        if (mem_wb.instr.rd == id_ex.instr.rs2)
            B = mem_wb.Result;
    }

    switch (id_ex.instr.op)
    {
    case ADD:ex_mem_o.ALUOut = A + B;
        break;
    case SUB:  ex_mem_o.ALUOut = A - B;
        break;
    case ADDI: ex_mem_o.ALUOut = A + id_ex.instr.imm;
        break;
    case LW:
    case SW:  ex_mem_o.ALUOut = A + id_ex.instr.imm;
        break;
    case AND: ex_mem_o.ALUOut = A & B;
        break;
    case OR:  ex_mem_o.ALUOut = A | B;
        break;
    case XOR: ex_mem_o.ALUOut = A ^ B;
        break;
    case BEQ:
        if (A - B == 0)
        {
            branch_taken = 1;
            branch_target = id_ex.pc + (id_ex.instr.imm * 4);
        }
        break;

    default:
        ex_mem_o.ALUOut = 0;
    }
    ex_mem_o.WriteData = B;
    print_log("EX  : %s\n", ex_mem_o.instr.text);
}

/* ================= MEMORY ================= */
void memory()
{
    mem_wb_o.instr = ex_mem.instr;
    mem_wb_o.RegWrite = ex_mem.RegWrite;

    if (ex_mem.MemRead)
        mem_wb_o.Result = DATA_MEM[ex_mem.ALUOut];
    else if (ex_mem.MemWrite)
        DATA_MEM[ex_mem.ALUOut] = ex_mem.WriteData;
    else
        mem_wb_o.Result = ex_mem.ALUOut;

    print_log("MEM : %s\n", mem_wb_o.instr.text);
}

/* ================= WRITEBACK ================= */
void writeback()
{
    if (mem_wb.RegWrite && mem_wb.instr.rd != 0)
        REG[mem_wb.instr.rd] = mem_wb.Result;

    if (mem_wb.instr.op == HALT)
        halted = 1;

    REG[0] = 0;
    print_log("WB  : %s\n", mem_wb.instr.text);
}

/* ================= CLOCK ================= */
void update_regs()
{
    if (!stall)
        if_id = if_id_o;
    id_ex = id_ex_o;
    ex_mem = ex_mem_o;
    mem_wb = mem_wb_o;
}

/* ================= LOAD PROGRAM ================= */
void load_instructions()
{
    FILE *f = fopen("inst.txt", "r");
    if (!f)
        return;

    char line[100];

    while (fgets(line, 100, f) && inst_count < MAX_INST)
    {
        instruction_t i = {NOP, 0, 0, 0, 0, ""};
        strcpy(i.text, line);

        if (sscanf(line, "addi x%d,x%d,%d", &i.rd, &i.rs1, &i.imm) == 3)
            i.op = ADDI;
        else if (sscanf(line, "add x%d,x%d,x%d", &i.rd, &i.rs1, &i.rs2) == 3)
            i.op = ADD;
        else if (sscanf(line, "sub x%d,x%d,x%d", &i.rd, &i.rs1, &i.rs2) == 3)
            i.op = SUB;
        else if (sscanf(line, "and x%d,x%d,x%d", &i.rd, &i.rs1, &i.rs2) == 3)
            i.op = AND;
        else if (sscanf(line, "or x%d,x%d,x%d", &i.rd, &i.rs1, &i.rs2) == 3)
            i.op = OR;
        else if (sscanf(line, "xor x%d,x%d,x%d", &i.rd, &i.rs1, &i.rs2) == 3)
            i.op = XOR;
        else if (sscanf(line, "lw x%d,%d(x%d)", &i.rd, &i.imm, &i.rs1) == 3)
            i.op = LW;
        else if (sscanf(line, "sw x%d,%d(x%d)", &i.rs2, &i.imm, &i.rs1) == 3)
            i.op = SW;
        else if (sscanf(line, "beq x%d,x%d,%d", &i.rs1, &i.rs2, &i.imm) == 3)
            i.op = BEQ;
        else if (strstr(line, "halt"))
            i.op = HALT;

        INST_MEM[inst_count++] = i;
    }
    fclose(f);
}

/* ================= MAIN ================= */
int main()
{
    memset(REG, 0, sizeof(REG));
    memset(DATA_MEM, 0, sizeof(DATA_MEM));

    /* ================= DATA INITIALIZATION ================= */
    int n = 5;
    DATA_MEM[96] = n;       
    DATA_MEM[100] = 1;     
    DATA_MEM[104] = 2;    
    DATA_MEM[108] = 3;    
    DATA_MEM[112] = 4;     
    DATA_MEM[116] = 5;   
    /* ======================================================= */

    load_instructions();

    out_file = fopen("output.txt", "w");
    if (out_file == NULL) {
        printf("Error opening output.txt!\n");
        return 1;
    }

    while (!halted && cycle < 200)
    {
        print_log("\n--- CYCLE %d ---\n", cycle++);
        writeback();
        memory();
        execute();
        decode();
        fetch();
        update_regs();
        print_registers();
    }

    final_register_dump();
    fclose(out_file);
    return 0;
}
