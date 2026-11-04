`timescale 1ns / 1ps

module reg_file (
    input  logic        clk_i,
    input  logic        rst_ni,      // Reset activo en bajo
    input  logic        we_i,        // Write Enable (reg_write de control)[cite: 17]
    input  logic [4:0]  raddr1_i,    // rs1 (bits [19:15])[cite: 17]
    input  logic [4:0]  raddr2_i,    // rs2 (bits [24:20])[cite: 17]
    input  logic [4:0]  waddr_i,     // rd  (bits [11:7])[cite: 17]
    input  logic [31:0] wdata_i,     // Dato a escribir[cite: 17]
    output logic [31:0] rdata1_o,    // Dato leído 1[cite: 17]
    output logic [31:0] rdata2_o     // Dato leído 2[cite: 17]
);

  logic [31:0] rf [0:31];
  integer i;

  // Escritura síncrona[cite: 17]
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (i = 0; i < 32; i = i + 1) begin
        rf[i] <= 32'b0;
      end
    end else if (we_i && (waddr_i != 5'd0)) begin
      rf[waddr_i] <= wdata_i; // x0 nunca se modifica[cite: 17]
    end
  end

  // Lectura combinacional (x0 siempre devuelve 0)[cite: 17]
  assign rdata1_o = (raddr1_i == 5'd0) ? 32'b0 : rf[raddr1_i];
  assign rdata2_o = (raddr2_i == 5'd0) ? 32'b0 : rf[raddr2_i];

endmodule