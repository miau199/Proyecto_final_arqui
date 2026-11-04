`timescale 1ns / 1ps
import riscv_pkg::*;

module alu (
    input  logic [31:0]   a_i,
    input  logic [31:0]   b_i,
    input  logic [3:0]    alu_ctrl_i, // alu_op_e[cite: 17]
    output logic [31:0]   result_o,
    output logic          zero_o
);

  always_comb begin
    case (alu_ctrl_i)
      ALU_ADD:  result_o = a_i + b_i;
      ALU_SUB:  result_o = a_i - b_i;
      ALU_AND:  result_o = a_i & b_i;
      ALU_OR:   result_o = a_i | b_i;
      ALU_XOR:  result_o = a_i ^ b_i;
      ALU_SLT:  result_o = ($signed(a_i) < $signed(b_i)) ? 32'd1 : 32'd0;
      ALU_SLTU: result_o = (a_i < b_i) ? 32'd1 : 32'd0;
      ALU_SLL:  result_o = a_i << b_i[4:0];
      ALU_SRL:  result_o = a_i >> b_i[4:0];
      default:  result_o = 32'b0;
    endcase
  end

  // Bandera Zero: activa cuando el resultado es 0 (usada para BEQ / BNE)[cite: 17]
  assign zero_o = (result_o == 32'b0);

endmodule