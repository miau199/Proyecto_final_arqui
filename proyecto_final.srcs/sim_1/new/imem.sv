`timescale 1ns / 1ps

module imem #(
    parameter int MEM_DEPTH = 64
)(
    input  logic [31:0] addr_i,
    output logic [31:0] instr_o
);

  logic [31:0] mem [0:MEM_DEPTH-1];

  initial begin
    // Carga el código de máquina generado
    $readmemh("program.mem", mem);
  end

  // Indexado por palabra (word-aligned)
  assign instr_o = mem[addr_i[31:2]];

endmodule