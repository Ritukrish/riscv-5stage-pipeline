#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define REG_COUNT 32
#define MAX_INST  50

/* ================= REGISTER FILE ================= */
int REG[REG_COUNT];

/* ================= GLOBAL FLAGS ================= */
int exception = 0;
int halted = 0;

/* ================= OPCODES ================= */
typedef enum {
    ADD, SUB, ADDI, AND, OR, XOR, HALT, NOP, ILLEGAL
} opcode_t;

/* ================= INSTRUCTION ================= */
typedef struct {
    opcode_t op;
    int rd, rs1, rs2, imm;
    char text[64];
} instruction_t;

/* ================= PIPELINE REGISTERS ================= */

/* IF/ID */
typedef struct {
    int pc;
    instruction_t instr;
} IF_ID;

/* ID/EX */
typedef struct {
    instruction_t instr;
    int RD1, RD2;
    int RegWrite;
} ID_EX;

/* EX/MEM */
typedef struct {
    instruction_t instr;
    int ALUOut;
    int RegWrite;
} EX_MEM;

/* MEM/WB */
typedef struct {
    instruction_t instr;
    int Result;
    int RegWrite;
} MEM_WB;

/* ================= GLOBALS ================= */
instruction_t INST_MEM[MAX_INST];
int PC = 0, inst_count = 0, cycle = 1;

/* Pipeline registers */
IF_ID  if_id, if_id_next;
ID_EX  id_ex, id_ex_next;
EX_MEM ex_mem, ex_mem_next;
MEM_WB mem_wb, mem_wb_next;

/* ================= FETCH ================= */
void fetch() {
    if (halted || exception) return;

    if_id_next.pc = PC;
    if_id_next.instr = INST_MEM[PC];
    printf("IF  : %s\n", if_id_next.instr.text);
    PC++;
}

/* ================= DECODE ================= */
void decode() {
    id_ex_next.instr = if_id.instr;

    /* Illegal instruction detection */
    if (if_id.instr.op == ILLEGAL) {
        printf("EXCEPTION: Illegal instruction -> %s", if_id.instr.text);
        exception = 1;

        id_ex_next.instr.op = NOP;   
        id_ex_next.RegWrite = 0;
        return;
    }

    id_ex_next.RD1 = REG[if_id.instr.rs1];
    id_ex_next.RD2 = REG[if_id.instr.rs2];

    id_ex_next.RegWrite =
        (if_id.instr.op != HALT && if_id.instr.op != NOP);

    printf("ID  : %s\n", id_ex_next.instr.text);
}

/* ================= EXECUTE ================= */
void execute() {
    if (exception) {
        ex_mem_next.instr.op = NOP;
        ex_mem_next.RegWrite = 0;
        return;
    }

    ex_mem_next.instr = id_ex.instr;
    ex_mem_next.RegWrite = id_ex.RegWrite;

    int A = id_ex.RD1;
    int B = id_ex.RD2;

    /* -------- EX/MEM forwarding -------- */
    if (ex_mem.RegWrite && ex_mem.instr.rd != 0) {
        if (ex_mem.instr.rd == id_ex.instr.rs1)
            A = ex_mem.ALUOut;
        if (ex_mem.instr.rd == id_ex.instr.rs2)
            B = ex_mem.ALUOut;
    }

    /* -------- MEM/WB forwarding -------- */
    if (mem_wb.RegWrite && mem_wb.instr.rd != 0) {
        if (mem_wb.instr.rd == id_ex.instr.rs1 &&
            ex_mem.instr.rd != id_ex.instr.rs1)
            A = mem_wb.Result;

        if (mem_wb.instr.rd == id_ex.instr.rs2 &&
            ex_mem.instr.rd != id_ex.instr.rs2)
            B = mem_wb.Result;
    }

    switch (id_ex.instr.op) {
        case ADD:  ex_mem_next.ALUOut = A + B; break;
        case SUB:  ex_mem_next.ALUOut = A - B; break;
        case ADDI: ex_mem_next.ALUOut = A + id_ex.instr.imm; break;
        case AND:  ex_mem_next.ALUOut = A & B; break;
        case OR:   ex_mem_next.ALUOut = A | B; break;
        case XOR:  ex_mem_next.ALUOut = A ^ B; break;
        default:   ex_mem_next.ALUOut = 0;
    }

    printf("EX  : %s\n", ex_mem_next.instr.text);
}

/* ================= MEMORY ================= */
void memory() {
    mem_wb_next.instr = ex_mem.instr;
    mem_wb_next.Result = ex_mem.ALUOut;
    mem_wb_next.RegWrite = ex_mem.RegWrite;

    printf("MEM : %s\n", mem_wb_next.instr.text);
}

/* ================= WRITE BACK ================= */
void writeback() {
    if (mem_wb.RegWrite && mem_wb.instr.rd != 0)
        REG[mem_wb.instr.rd] = mem_wb.Result;

    if (mem_wb.instr.op == HALT)
        halted = 1;

    REG[0] = 0; 

    printf("WB  : %s\n", mem_wb.instr.text);
}

/* ================= CLOCK EDGE ================= */
void clock_edge() {
    mem_wb = mem_wb_next;
    ex_mem = ex_mem_next;
    id_ex  = id_ex_next;
    if_id  = if_id_next;
}

/* ================= LOAD INSTRUCTIONS ================= */
void load_instructions() {
    FILE *f = fopen("inst.txt", "r");
    char line[100];

    while (fgets(line, sizeof(line), f)) {
        instruction_t inst;
        inst.op = ILLEGAL;
        inst.rd = inst.rs1 = inst.rs2 = inst.imm = 0;
        strcpy(inst.text, line);

        if      (sscanf(line,"addi x%d,x%d,%d",&inst.rd,&inst.rs1,&inst.imm)==3) inst.op=ADDI;
        else if (sscanf(line,"add x%d,x%d,x%d",&inst.rd,&inst.rs1,&inst.rs2)==3) inst.op=ADD;
        else if (sscanf(line,"sub x%d,x%d,x%d",&inst.rd,&inst.rs1,&inst.rs2)==3) inst.op=SUB;
        else if (sscanf(line,"and x%d,x%d,x%d",&inst.rd,&inst.rs1,&inst.rs2)==3) inst.op=AND;
        else if (sscanf(line,"or x%d,x%d,x%d",&inst.rd,&inst.rs1,&inst.rs2)==3)  inst.op=OR;
        else if (sscanf(line,"xor x%d,x%d,x%d",&inst.rd,&inst.rs1,&inst.rs2)==3) inst.op=XOR;
        else if (strstr(line,"halt")) inst.op=HALT;
        else if (strcmp(line,"\n")==0) inst.op=NOP;

        INST_MEM[inst_count++] = inst;
    }
    fclose(f);
}

/* ================= PRINT REGISTERS ================= */
void print_registers(int cycle) {
    printf("\nRegisters after cycle %d:\n", cycle);
    for (int i = 0; i < 8; i++)
        printf("x%d=%d  ", i, REG[i]);
    printf("\n");
}

/* ================= MAIN ================= */
int main() {
    for (int i = 0; i < REG_COUNT; i++)
        REG[i] = 0;

    load_instructions();

    while (!halted) {
        printf("\n--- CYCLE %d ---\n", cycle);

        writeback();
        memory();
        execute();
        decode();
        fetch();

        clock_edge();
        print_registers(cycle);
        cycle++;

        if (exception) {
            printf("\nPipeline flushed due to exception. Processor halted.\n");
            break;
        }
    }

    printf("\n====== FINAL REGISTER STATE ======\n");
    print_registers(cycle - 1);
    return 0;
}
