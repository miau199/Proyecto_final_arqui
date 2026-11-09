`timescale 1ns / 1ps
//==============================================================
// imem.sv - Memoria de instrucciones (ROM, lectura combinacional)
//   Se carga con program.mem. Sintetizable en Vivado (LUT-ROM).
//==============================================================
module imem #(
    parameter int MEM_DEPTH = 64
)(
    input  logic [31:0] addr_i,
    output logic [31:0] instr_o
);

  logic [31:0] mem [0:MEM_DEPTH-1];

  initial begin
    // Posiciones no usadas = NOP (addi x0, x0, 0)
    for (int i = 0; i < MEM_DEPTH; i++) mem[i] = 32'h0000_0013;
    $readmemh("program.mem", mem);
  end

  // Indexado por palabra: se descartan los 2 bits menos significativos
  assign instr_o = mem[addr_i[$clog2(MEM_DEPTH)+1:2]];

endmodule
