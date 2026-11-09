`timescale 1ns / 1ps
//==============================================================
// dmem.sv - Memoria de datos (escritura sincrona, lectura combinacional)
//   Sintetizable en Vivado (RAM distribuida).
//==============================================================
module dmem #(
    parameter int MEM_DEPTH = 64
)(
    input  logic        clk_i,
    input  logic        we_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] wdata_i,
    output logic [31:0] rdata_o
);

  localparam int AW = $clog2(MEM_DEPTH);

  logic [31:0] mem [0:MEM_DEPTH-1];

  initial begin
    for (int i = 0; i < MEM_DEPTH; i++) mem[i] = 32'b0;
  end

  always_ff @(posedge clk_i) begin
    if (we_i) begin
      mem[addr_i[AW+1:2]] <= wdata_i;
      // synthesis translate_off
      $display("[DMEM WRITE] t=%0t  Addr: 0x%08h (Word: %0d) <= Data: 0x%08h (%0d)",
               $time, addr_i, addr_i[AW+1:2], wdata_i, $signed(wdata_i));
      // synthesis translate_on
    end
  end

  assign rdata_o = mem[addr_i[AW+1:2]];

endmodule
