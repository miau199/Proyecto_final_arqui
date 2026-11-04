`timescale 1ns / 1ps

module dmem #(
    parameter int MEM_DEPTH = 64
)(
    input  logic        clk_i,
    input  logic        we_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] wdata_i,
    output logic [31:0] rdata_o
);

  logic [31:0] mem [0:MEM_DEPTH-1];

  integer i;
  initial begin
    for (i = 0; i < MEM_DEPTH; i = i + 1) begin
      mem[i] = 32'b0;
    end
  end

  // Escritura síncrona
  always_ff @(posedge clk_i) begin
    if (we_i) begin
      mem[addr_i[31:2]] <= wdata_i;
      $display("[DMEM WRITE] Addr: 0x%08h (Word: %0d) <= Data: 0x%08h (%0d)", 
               addr_i, addr_i[31:2], wdata_i, $signed(wdata_i));
    end
  end

  // Lectura combinacional
  assign rdata_o = mem[addr_i[31:2]];

endmodule