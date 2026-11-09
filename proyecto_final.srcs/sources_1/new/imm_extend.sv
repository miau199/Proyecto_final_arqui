`timescale 1ns / 1ps
//==============================================================
// imm_extend.sv - Extensor de inmediatos (I, S, B, J, U)
//==============================================================
module imm_extend
  import riscv_pkg::*;
(
    input  logic [31:7] instr_i,   // bits [31:7] de la instruccion
    input  logic [2:0]  imm_src_i, // formato de inmediato
    output logic [31:0] imm_ext_o
);

  always_comb begin
    case (imm_src_i)
      // Tipo I (addi, lw, jalr...)
      IMM_I: imm_ext_o = {{20{instr_i[31]}}, instr_i[31:20]};
      // Tipo S (sw)
      IMM_S: imm_ext_o = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
      // Tipo B (beq, bne) - bit 0 implicito en 0
      IMM_B: imm_ext_o = {{20{instr_i[31]}}, instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};
      // Tipo J (jal) - bit 0 implicito en 0
      IMM_J: imm_ext_o = {{12{instr_i[31]}}, instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};
      // Tipo U (lui)
      IMM_U: imm_ext_o = {instr_i[31:12], 12'b0};
      default: imm_ext_o = 32'b0;
    endcase
  end

endmodule
