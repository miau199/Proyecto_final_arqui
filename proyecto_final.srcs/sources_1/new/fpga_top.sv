`timescale 1ns / 1ps
//==============================================================
// fpga_top.sv - Top para la tarjeta Basys 3 (xc7a35tcpg236-1)
//
//   clk  (W5)   : reloj de 100 MHz de la tarjeta
//   btnC (U18)  : reset (mantener presionado = reset)
//   sw[4:0]     : numero de registro a mostrar (x0..x31)
//   sw[15]      : 0 = mostrar bits [15:0], 1 = mostrar bits [31:16]
//   sw[14]      : 1 = mostrar el PC[15:0] en lugar del registro
//   led[15:0]   : valor mostrado
//
//   Ejemplo: sw = 00101 (x5) -> led = 0x000A (lw cargo el 10 que guardo sw)
//
//   El nucleo corre a 25 MHz (MMCM 100 MHz -> 25 MHz) para dar margen
//   de timing a la ruta critica de ciclo unico.
//==============================================================
module fpga_top (
    input  logic        clk,
    input  logic        btnC,
    input  logic [15:0] sw,
    output logic [15:0] led
);

  //------------------------------------------------------------
  // Generacion de reloj: 100 MHz -> VCO 1000 MHz -> 25 MHz
  //------------------------------------------------------------
  logic clk_fb, clk_core_unbuf, clk_core, locked;

  MMCME2_BASE #(
      .CLKIN1_PERIOD    (10.0),
      .DIVCLK_DIVIDE    (1),
      .CLKFBOUT_MULT_F  (10.0),
      .CLKOUT0_DIVIDE_F (40.0)
  ) u_mmcm (
      .CLKIN1   (clk),
      .CLKFBIN  (clk_fb),
      .CLKFBOUT (clk_fb),
      .CLKOUT0  (clk_core_unbuf),
      .LOCKED   (locked),
      .PWRDWN   (1'b0),
      .RST      (1'b0)
  );

  BUFG u_bufg (.I(clk_core_unbuf), .O(clk_core));

  //------------------------------------------------------------
  // Reset: asincrono al activar, sincronizado al liberar
  //------------------------------------------------------------
  logic       rst_async;
  logic [1:0] rst_sync;
  logic       rst_n;

  assign rst_async = btnC | ~locked;

  always_ff @(posedge clk_core or posedge rst_async) begin
    if (rst_async) rst_sync <= 2'b00;
    else           rst_sync <= {rst_sync[0], 1'b1};
  end
  assign rst_n = rst_sync[1];

  //------------------------------------------------------------
  // Nucleo + memorias
  //------------------------------------------------------------
  logic [31:0] imem_addr, instr;
  logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;
  logic        dmem_we;
  logic [31:0] dbg_rdata;

  riscv_single_cycle u_core (
      .clk_i        (clk_core),
      .rst_ni       (rst_n),
      .imem_addr_o  (imem_addr),
      .instr_i      (instr),
      .dmem_addr_o  (dmem_addr),
      .dmem_wdata_o (dmem_wdata),
      .dmem_we_o    (dmem_we),
      .dmem_rdata_i (dmem_rdata),
      .dbg_raddr_i  (sw[4:0]),
      .dbg_rdata_o  (dbg_rdata)
  );

  imem u_imem (.addr_i(imem_addr), .instr_o(instr));

  dmem u_dmem (
      .clk_i   (clk_core),
      .we_i    (dmem_we),
      .addr_i  (dmem_addr),
      .wdata_i (dmem_wdata),
      .rdata_o (dmem_rdata)
  );

  //------------------------------------------------------------
  // Visualizacion en LEDs
  //------------------------------------------------------------
  always_comb begin
    if (sw[14])      led = imem_addr[15:0];
    else if (sw[15]) led = dbg_rdata[31:16];
    else             led = dbg_rdata[15:0];
  end

endmodule
