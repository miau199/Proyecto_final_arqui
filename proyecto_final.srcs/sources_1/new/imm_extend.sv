`timescale 1ns / 1ps

module imm_extend (
    input  logic [31:7] instr_i,   // Bits [31:7] de la instrucción
    input  logic [2:0]  imm_src_i, // Control de formato de inmediato
    output logic [31:0] imm_ext_o
);

  always_comb begin
    case (imm_src_i)
      // Tipo I (Loads, Aritmética inmediata)
      3'b000: imm_ext_o = {{20{instr_i[31]}}, instr_i[31:20]};

      // Tipo S (Stores: sw)
      3'b001: imm_ext_o = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};

      // Tipo B (Branches: beq, bne)
      3'b010: imm_ext_o = {{20{instr_i[31]}}, instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};

      // Tipo J (Jumps: jal)
      3'b011: imm_ext_o = {{12{instr_i[31]}}, instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};

      // Tipo U (Upper Immediate: lui)
      3'b100: imm_ext_o = {instr_i[31:12], 12'b0};

      default: imm_ext_o = 32'b0;
    endcase
  end

endmodule