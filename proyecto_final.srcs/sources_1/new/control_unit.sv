`timescale 1ns / 1ps
//==============================================================
// control_unit.sv - Main Decoder + ALU Decoder
//==============================================================
module control_unit
  import riscv_pkg::*;
(
    input  logic [6:0] opcode_i,
    input  logic [2:0] funct3_i,
    input  logic       funct7b5_i,   // bit 30 de la instruccion (add/sub, srl/sra)

    // Senales hacia el Datapath
    output logic       reg_write_o,  // habilita escritura en el banco de registros
    output logic [2:0] imm_src_o,    // formato de inmediato (IMM_I/S/B/J/U)
    output logic       alu_src_o,    // 0: rs2, 1: inmediato extendido
    output logic       mem_write_o,  // habilita escritura en memoria de datos
    output logic [1:0] result_src_o, // RES_ALU / RES_MEM / RES_PC4 / RES_IMM
    output logic       branch_o,     // instruccion de salto condicional
    output logic       jump_o,       // salto incondicional (jal / jalr)
    output logic       jalr_o,       // destino = (rs1 + imm) & ~1
    output logic [3:0] alu_ctrl_o    // operacion de la ALU
);

  logic [1:0] alu_op_mode; // 00: suma, 01: resta, 10: segun funct3/funct7

  //---------------------------------------------------------
  // 1. Decodificador principal (Main Decoder)
  //---------------------------------------------------------
  always_comb begin
    // Valores por defecto (evitan latches; opcode desconocido = NOP)
    reg_write_o  = 1'b0;
    imm_src_o    = IMM_I;
    alu_src_o    = 1'b0;
    mem_write_o  = 1'b0;
    result_src_o = RES_ALU;
    branch_o     = 1'b0;
    jump_o       = 1'b0;
    jalr_o       = 1'b0;
    alu_op_mode  = 2'b00;

    case (opcode_i)
      OPCODE_LOAD: begin            // lw rd, imm(rs1)
        reg_write_o  = 1'b1;
        imm_src_o    = IMM_I;
        alu_src_o    = 1'b1;
        result_src_o = RES_MEM;
        alu_op_mode  = 2'b00;
      end

      OPCODE_STORE: begin           // sw rs2, imm(rs1)
        imm_src_o    = IMM_S;
        alu_src_o    = 1'b1;
        mem_write_o  = 1'b1;
        alu_op_mode  = 2'b00;
      end

      OPCODE_R_TYPE: begin
        reg_write_o  = 1'b1;
        alu_src_o    = 1'b0;
        result_src_o = RES_ALU;
        alu_op_mode  = 2'b10;
      end

      OPCODE_I_TYPE: begin
        reg_write_o  = 1'b1;
        imm_src_o    = IMM_I;
        alu_src_o    = 1'b1;
        result_src_o = RES_ALU;
        alu_op_mode  = 2'b10;
      end

      OPCODE_BRANCH: begin          // beq / bne (rs1 - rs2 -> zero)
        imm_src_o    = IMM_B;
        alu_src_o    = 1'b0;
        branch_o     = 1'b1;
        alu_op_mode  = 2'b01;
      end

      OPCODE_JAL: begin             // rd = PC+4 ; PC = PC + immJ
        reg_write_o  = 1'b1;
        imm_src_o    = IMM_J;
        result_src_o = RES_PC4;
        jump_o       = 1'b1;
      end

      OPCODE_JALR: begin            // rd = PC+4 ; PC = (rs1 + immI) & ~1
        reg_write_o  = 1'b1;
        imm_src_o    = IMM_I;
        alu_src_o    = 1'b1;
        result_src_o = RES_PC4;
        jump_o       = 1'b1;
        jalr_o       = 1'b1;
        alu_op_mode  = 2'b00;
      end

      OPCODE_LUI: begin             // rd = imm << 12
        reg_write_o  = 1'b1;
        imm_src_o    = IMM_U;
        result_src_o = RES_IMM;
      end

      default: ;
    endcase
  end

  //---------------------------------------------------------
  // 2. Decodificador de la ALU (ALU Decoder)
  //---------------------------------------------------------
  always_comb begin
    case (alu_op_mode)
      2'b00: alu_ctrl_o = ALU_ADD;  // lw / sw / jalr: calculo de direccion
      2'b01: alu_ctrl_o = ALU_SUB;  // beq / bne: comparacion
      2'b10: begin
        case (funct3_i)
          // En R-type, funct7[5] distingue sub de add. En I-type (addi) siempre suma.
          3'b000: alu_ctrl_o = (funct7b5_i && (opcode_i == OPCODE_R_TYPE)) ? ALU_SUB : ALU_ADD;
          3'b001: alu_ctrl_o = ALU_SLL;   // sll / slli
          3'b010: alu_ctrl_o = ALU_SLT;   // slt / slti
          3'b011: alu_ctrl_o = ALU_SLTU;  // sltu / sltiu
          3'b100: alu_ctrl_o = ALU_XOR;   // xor / xori
          // En R-type y en srai el bit 30 distingue sra de srl
          3'b101: alu_ctrl_o = funct7b5_i ? ALU_SRA : ALU_SRL;
          3'b110: alu_ctrl_o = ALU_OR;    // or / ori
          3'b111: alu_ctrl_o = ALU_AND;   // and / andi
          default: alu_ctrl_o = ALU_ADD;
        endcase
      end
      default: alu_ctrl_o = ALU_ADD;
    endcase
  end

endmodule
