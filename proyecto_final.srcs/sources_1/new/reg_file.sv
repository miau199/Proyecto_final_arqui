`timescale 1ns / 1ps
//==============================================================
// reg_file.sv - Banco de 32 registros x 32 bits
//   2 puertos de lectura asincrona + 1 puerto de escritura sincrona
//   + 1 puerto de lectura de depuracion (para LEDs en FPGA)
//==============================================================
module reg_file (
    input  logic        clk_i,
    input  logic        rst_ni,      // reset asincrono, activo en bajo
    input  logic        we_i,        // write enable (reg_write)
    input  logic [4:0]  raddr1_i,    // rs1 = instr[19:15]
    input  logic [4:0]  raddr2_i,    // rs2 = instr[24:20]
    input  logic [4:0]  waddr_i,     // rd  = instr[11:7]
    input  logic [31:0] wdata_i,
    output logic [31:0] rdata1_o,
    output logic [31:0] rdata2_o,
    // Puerto de depuracion (solo lectura)
    input  logic [4:0]  dbg_raddr_i,
    output logic [31:0] dbg_rdata_o
);

  logic [31:0] rf [0:31];

  // Escritura sincrona; x0 nunca se modifica
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int i = 0; i < 32; i++) rf[i] <= 32'b0;
    end else if (we_i && (waddr_i != 5'd0)) begin
      rf[waddr_i] <= wdata_i;
    end
  end

  // Lectura combinacional (x0 siempre devuelve 0)
  assign rdata1_o    = (raddr1_i    == 5'd0) ? 32'b0 : rf[raddr1_i];
  assign rdata2_o    = (raddr2_i    == 5'd0) ? 32'b0 : rf[raddr2_i];
  assign dbg_rdata_o = (dbg_raddr_i == 5'd0) ? 32'b0 : rf[dbg_raddr_i];

endmodule
