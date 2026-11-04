`timescale 1ns / 1ps

module riscv_tb;

  logic        clk;
  logic        rst_n;
  logic [31:0] imem_addr;
  logic [31:0] instr;
  logic [31:0] dmem_addr;
  logic [31:0] dmem_wdata;
  logic        dmem_we;
  logic [31:0] dmem_rdata;

  // Instancia del Top del Procesador
  riscv_single_cycle dut (
      .clk_i        (clk),
      .rst_ni       (rst_n),
      .imem_addr_o  (imem_addr),
      .instr_i      (instr),
      .dmem_addr_o  (dmem_addr),
      .dmem_wdata_o (dmem_wdata),
      .dmem_we_o    (dmem_we),
      .dmem_rdata_i (dmem_rdata)
  );

  // Instancia de Memorias
  imem u_imem (
      .addr_i  (imem_addr),
      .instr_o (instr)
  );

  dmem u_dmem (
      .clk_i   (clk),
      .we_i    (dmem_we),
      .addr_i  (dmem_addr),
      .wdata_i (dmem_wdata),
      .rdata_o (dmem_rdata)
  );

  // Generación de Reloj (100 MHz -> periodo 10 ns)
  always #5 clk = ~clk;

  initial begin
    clk   = 0;
    rst_n = 0;

    // Pulso de Reset
    #20;
    @(negedge clk);
    rst_n = 1;

    // Monitoreo de ejecución
    repeat (25) begin
      @(posedge clk);
      #1;
      $display("[T=%0t ns] PC = 0x%08h | Instr = 0x%08h", $time, imem_addr, instr);
    end

    $display("--- Simulacion completada ---");
    $finish;
  end

endmodule