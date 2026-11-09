`timescale 1ns / 1ps
//==============================================================
// riscv_pkg.sv - Constantes globales del nucleo RV32I single-cycle
//==============================================================
package riscv_pkg;

  // Opcodes base RV32I soportados
  typedef enum logic [6:0] {
    OPCODE_R_TYPE = 7'b0110011, // add, sub, and, or, xor, slt, sltu, sll, srl, sra
    OPCODE_I_TYPE = 7'b0010011, // addi, andi, ori, xori, slti, sltiu, slli, srli, srai
    OPCODE_LOAD   = 7'b0000011, // lw
    OPCODE_STORE  = 7'b0100011, // sw
    OPCODE_BRANCH = 7'b1100011, // beq, bne
    OPCODE_JAL    = 7'b1101111, // jal
    OPCODE_JALR   = 7'b1100111, // jalr
    OPCODE_LUI    = 7'b0110111  // lui
  } opcode_e;

  // Codigos internos de operacion de la ALU
  typedef enum logic [3:0] {
    ALU_ADD  = 4'b0000,
    ALU_SUB  = 4'b0001,
    ALU_AND  = 4'b0010,
    ALU_OR   = 4'b0011,
    ALU_XOR  = 4'b0100,
    ALU_SLT  = 4'b0101, // Set Less Than (con signo)
    ALU_SLTU = 4'b0110, // Set Less Than (sin signo)
    ALU_SLL  = 4'b0111, // Shift Left Logical
    ALU_SRL  = 4'b1000, // Shift Right Logical
    ALU_SRA  = 4'b1001  // Shift Right Arithmetic
  } alu_op_e;

  // Seleccion de formato de inmediato (imm_src)
  localparam logic [2:0] IMM_I = 3'b000;
  localparam logic [2:0] IMM_S = 3'b001;
  localparam logic [2:0] IMM_B = 3'b010;
  localparam logic [2:0] IMM_J = 3'b011;
  localparam logic [2:0] IMM_U = 3'b100;

  // Seleccion del dato de write-back (result_src)
  localparam logic [1:0] RES_ALU = 2'b00; // resultado de la ALU
  localparam logic [1:0] RES_MEM = 2'b01; // dato leido de memoria (lw)
  localparam logic [1:0] RES_PC4 = 2'b10; // PC + 4 (jal / jalr)
  localparam logic [1:0] RES_IMM = 2'b11; // inmediato extendido (lui)

endpackage
