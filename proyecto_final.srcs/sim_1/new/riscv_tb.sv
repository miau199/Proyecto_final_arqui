`timescale 1ns / 1ps
//==============================================================
// riscv_tb.sv - Testbench autoverificable del RV32I single-cycle
//   - Ejecuta program.mem hasta que el PC se estabiliza (jal x0, 0)
//   - Compara x1..x31 y la memoria de datos contra valores esperados
//   - Imprime PASS / FAIL
//   Compatible con Vivado xsim y Synopsys VCS (+define+FSDB para Verdi)
//==============================================================
module riscv_tb;

  logic        clk;
  logic        rst_n;
  logic [31:0] imem_addr, instr;
  logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;
  logic        dmem_we;
  logic [31:0] dbg_rdata;

  localparam logic [31:0] PC_FINAL   = 32'h0000_0094; // direccion de "jal x0, 0"
  localparam int          MAX_CYCLES = 200;

  // DUT
  riscv_single_cycle dut (
      .clk_i        (clk),
      .rst_ni       (rst_n),
      .imem_addr_o  (imem_addr),
      .instr_i      (instr),
      .dmem_addr_o  (dmem_addr),
      .dmem_wdata_o (dmem_wdata),
      .dmem_we_o    (dmem_we),
      .dmem_rdata_i (dmem_rdata),
      .dbg_raddr_i  (5'd0),
      .dbg_rdata_o  (dbg_rdata)
  );

  imem u_imem (.addr_i(imem_addr), .instr_o(instr));

  dmem u_dmem (
      .clk_i   (clk),
      .we_i    (dmem_we),
      .addr_i  (dmem_addr),
      .wdata_i (dmem_wdata),
      .rdata_o (dmem_rdata)
  );

  // Reloj de 100 MHz (periodo 10 ns)
  initial clk = 1'b0;
  always #5 clk = ~clk;

  // Volcado de ondas para Verdi (vcs ... +define+FSDB)
`ifdef FSDB
  initial begin
    $fsdbDumpfile("riscv_tb.fsdb");
    $fsdbDumpvars(0, riscv_tb);
  end
`endif

  int errors = 0;
  int checks = 0;

  task automatic check_reg(input int r, input logic [31:0] exp);
    logic [31:0] got;
    got = dut.u_datapath.u_reg_file.rf[r];
    checks++;
    if (got !== exp) begin
      errors++;
      $display("  [FAIL] x%0d = 0x%08h  (esperado 0x%08h)", r, got, exp);
    end else
      $display("  [ OK ] x%0d = 0x%08h", r, got);
  endtask

  task automatic check_mem(input int word, input logic [31:0] exp);
    logic [31:0] got;
    got = u_dmem.mem[word];
    checks++;
    if (got !== exp) begin
      errors++;
      $display("  [FAIL] mem[%0d] = 0x%08h  (esperado 0x%08h)", word, got, exp);
    end else
      $display("  [ OK ] mem[%0d] = 0x%08h", word, got);
  endtask

  int cycles = 0;

  initial begin
    $timeformat(-9, 0, " ns", 8);
    rst_n = 1'b0;
    repeat (2) @(negedge clk);   // reset durante 2 ciclos
    rst_n = 1'b1;

    // Traza ciclo a ciclo: instruccion que se ejecuta en cada flanco
    while ((cycles < MAX_CYCLES) && (imem_addr !== PC_FINAL)) begin
      $display("[%t] PC = 0x%08h | Instr = 0x%08h", $time, imem_addr, instr);
      @(posedge clk); #1;
      cycles++;
    end
    repeat (3) @(posedge clk);  // confirmar que el bucle final retiene el PC
    #1;

    $display("\n===== Verificacion de resultados (%0d ciclos) =====", cycles);
    if (imem_addr !== PC_FINAL) begin
      errors++;
      $display("  [FAIL] PC final = 0x%08h (esperado 0x%08h)", imem_addr, PC_FINAL);
    end

    check_reg( 1, 32'h0000_0005);  // addi
    check_reg( 2, 32'h0000_000a);  // addi
    check_reg( 3, 32'h0000_000f);  // add
    check_reg( 4, 32'h0000_000a);  // sub
    check_reg( 5, 32'h0000_000a);  // lw (lee lo que guardo sw)
    check_reg( 6, 32'h0000_000a);  // and
    check_reg( 7, 32'h0000_000f);  // or
    check_reg( 8, 32'h0000_000a);  // xor
    check_reg( 9, 32'h0000_0001);  // slt
    check_reg(10, 32'h0000_000a);  // sll
    check_reg(11, 32'h0000_0005);  // srl
    check_reg(12, 32'hffff_fff8);  // addi negativo
    check_reg(13, 32'hffff_fffc);  // sra
    check_reg(14, 32'h0000_0001);  // sltu
    check_reg(15, 32'h0000_0000);  // slt con negativo
    check_reg(16, 32'h0000_0006);  // andi
    check_reg(17, 32'h0000_0015);  // ori
    check_reg(18, 32'h0000_0001);  // slti
    check_reg(19, 32'h1234_5000);  // lui
    check_reg(20, 32'h0000_0008);  // base de memoria
    check_reg(21, 32'h0000_0000);  // beq tomado -> instruccion saltada
    check_reg(22, 32'h0000_0001);  // bne no tomado -> se ejecuta
    check_reg(23, 32'h0000_0000);  // bne tomado -> instruccion saltada
    check_reg(24, 32'h0000_0002);  // beq no tomado -> se ejecuta
    check_reg(25, 32'h0000_007c);  // jal: direccion de retorno
    check_reg(26, 32'h0000_0000);  // jal -> instruccion saltada
    check_reg(27, 32'h0000_0084);  // jalr: direccion de retorno
    check_reg(28, 32'h0000_0000);  // jalr -> instruccion saltada
    check_reg(29, 32'h0000_0007);  // destino de jalr
    check_reg(30, 32'h0000_0002);  // xori
    check_reg(31, 32'hffff_fffe);  // srai
    check_mem(2, 32'h0000_000a);   // sw x4, 0(x20)
    check_mem(3, 32'h1234_5000);   // sw x19, 4(x20)

    $display("==================================================");
    if (errors == 0)
      $display("  RESULTADO: PASS  (%0d/%0d verificaciones correctas)", checks, checks);
    else
      $display("  RESULTADO: FAIL  (%0d errores)", errors);
    $display("==================================================\n");
    $finish;
  end

endmodule
