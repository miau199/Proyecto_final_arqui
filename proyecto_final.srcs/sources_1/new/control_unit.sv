`timescale 1ns / 1ps
import riscv_pkg::*;

module control_unit (
    input  logic [6:0] opcode_i,
    input  logic [2:0] funct3_i,
    input  logic       funct7b5_i, // bit 5 de funct7 (diferencia ADD/SUB y SRL/SRA)[cite: 17]
    
    // Señales hacia el Datapath[cite: 17]
    output logic       reg_write_o,
    output logic [2:0] imm_src_o,    // Selección de tipo inmediato (I, S, B, J, U)[cite: 17]
    output logic       alu_src_o,    // 0: Registro rd2, 1: ExtImm[cite: 17]
    output logic       mem_write_o,  // Habilita escritura en RAM de datos[cite: 17]
    output logic [1:0] result_src_o, // 00: ALU, 01: MemData, 10: PC+4[cite: 17]
    output logic       branch_o,     // Activo en instrucciones de salto condicional[cite: 17]
    output logic       jump_o,       // Activo en JAL / JALR[cite: 17]
    output logic [3:0] alu_ctrl_o    // Señal directa a la ALU[cite: 17]
);

  logic [1:0] alu_op_mode; //[cite: 17]

  //---------------------------------------------------------
  // 1. Decodificador Principal (Main Decoder)[cite: 17]
  //---------------------------------------------------------
  always_comb begin
    // Valores por defecto seguros para evitar inferencia de latches[cite: 4, 17]
    reg_write_o  = 1'b0;
    imm_src_o    = 3'b000;
    alu_src_o    = 1'b0;
    mem_write_o  = 1'b0;
    result_src_o = 2'b00;
    branch_o     = 1'b0;
    jump_o       = 1'b0;
    alu_op_mode  = 2'b00;

    case (opcode_i)
      OPCODE_LOAD: begin
        reg_write_o  = 1'b1;
        imm_src_o    = 3'b000; // I-type[cite: 17]
        alu_src_o    = 1'b1;   // Base + Offset[cite: 17]
        mem_write_o  = 1'b0;
        result_src_o = 2'b01;   // Carga dato desde memoria[cite: 17]
        alu_op_mode  = 2'b00;   // Suma para calcular dirección[cite: 17]
      end

      OPCODE_STORE: begin
        reg_write_o  = 1'b0;
        imm_src_o    = 3'b001; // S-type[cite: 17]
        alu_src_o    = 1'b1;   // Base + Offset[cite: 17]
        mem_write_o  = 1'b1;   // Escribe en memoria[cite: 17]
        alu_op_mode  = 2'b00;   // Suma para calcular dirección[cite: 17]
      end

      OPCODE_R_TYPE: begin
        reg_write_o  = 1'b1;
        alu_src_o    = 1'b0;   // Operando B viene de Registro[cite: 17]
        result_src_o = 2'b00;   // Viene de ALU[cite: 17]
        alu_op_mode  = 2'b10;   // Decodificar según funct3 y funct7[cite: 17]
      end

      OPCODE_I_TYPE: begin
        reg_write_o  = 1'b1;
        imm_src_o    = 3'b000; // I-type[cite: 17]
        alu_src_o    = 1'b1;   // Inmediato extendido[cite: 17]
        result_src_o = 2'b00;   // Viene de ALU[cite: 17]
        alu_op_mode  = 2'b10;   // Decodificar según funct3[cite: 17]
      end

      OPCODE_BRANCH: begin
        imm_src_o    = 3'b010; // B-type[cite: 17]
        alu_src_o    = 1'b0;   // Compara dos registros[cite: 17]
        branch_o     = 1'b1;
        alu_op_mode  = 2'b01;   // Resta para comparar igualdad/magnitud[cite: 17]
      end

      OPCODE_JAL: begin
        reg_write_o  = 1'b1;   // Guarda dirección de retorno (PC+4)[cite: 17]
        imm_src_o    = 3'b011; // J-type[cite: 17]
        result_src_o = 2'b10;   // Escribe PC+4 en rd[cite: 17]
        jump_o       = 1'b1;
      end

      default: ;
    endcase
  end

  //---------------------------------------------------------
  // 2. Decodificador de la ALU (ALU Decoder)[cite: 17]
  //---------------------------------------------------------
  always_comb begin
    case (alu_op_mode)
      2'b00: alu_ctrl_o = ALU_ADD; // Para Loads y Stores (cálculo de offset)[cite: 17]
      2'b01: alu_ctrl_o = ALU_SUB; // Para Branches (comparación)[cite: 17]
      2'b10: begin                 // Operaciones R-Type / I-Type según funct3[cite: 17]
        case (funct3_i)
          3'b000: begin
            // En R-type, el bit 5 de funct7 distingue SUB de ADD. En I-type siempre es ADD[cite: 17].
            if (funct7b5_i && (opcode_i == OPCODE_R_TYPE))
              alu_ctrl_o = ALU_SUB;
            else
              alu_ctrl_o = ALU_ADD;
          end
          3'b010: alu_ctrl_o = ALU_SLT;  // slt / slti[cite: 17]
          3'b110: alu_ctrl_o = ALU_OR;   // or / ori[cite: 17]
          3'b111: alu_ctrl_o = ALU_AND;  // and / andi[cite: 17]
          3'b100: alu_ctrl_o = ALU_XOR;  // xor / xori[cite: 17]
          3'b001: alu_ctrl_o = ALU_SLL;  // sll / slli[cite: 17]
          3'b101: alu_ctrl_o = ALU_SRL;  // srl / srli[cite: 17]
          default: alu_ctrl_o = ALU_ADD;
        endcase
      end
      default: alu_ctrl_o = ALU_ADD;
    endcase
  end

endmodule
