`timescale 1ns / 1ps
//==============================================================
// datapath.sv - Ruta de datos del RV32I single-cycle
//==============================================================
module datapath
  import riscv_pkg::*;
(
    input  logic        clk_i,
    input  logic        rst_ni,

    // Control proveniente de la Control Unit
    input  logic        reg_write_i,
    input  logic [2:0]  imm_src_i,
    input  logic        alu_src_i,
    input  logic [1:0]  result_src_i,
    input  logic        branch_i,
    input  logic        jump_i,
    input  logic        jalr_i,
    input  logic [3:0]  alu_ctrl_i,

    // Interfaz con memoria de instrucciones
    output logic [31:0] pc_o,
    input  logic [31:0] instr_i,

    // Interfaz con memoria de datos
    output logic [31:0] alu_result_o,
    output logic [31:0] write_data_o,
    input  logic [31:0] read_data_i,

    // Depuracion
    input  logic [4:0]  dbg_raddr_i,
    output logic [31:0] dbg_rdata_o
);

  logic [31:0] pc_next, pc_target, pc_plus4;
  logic [31:0] imm_ext, src_a, src_b, result;
  logic        zero, branch_taken, pc_src;

  //------------------------------------------------------------
  // 1. Program Counter
  //------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) pc_o <= 32'b0;
    else         pc_o <= pc_next;
  end

  assign pc_plus4  = pc_o + 32'd4;
  assign pc_target = pc_o + imm_ext;   // destino de branch / jal

  // beq (funct3 = 000) salta si zero = 1 ; bne (funct3 = 001) salta si zero = 0.
  // funct3[0] = instr[12] invierte la condicion.
  assign branch_taken = branch_i & (zero ^ instr_i[12]);
  assign pc_src       = jump_i | branch_taken;

  always_comb begin
    if (jalr_i)       pc_next = {alu_result_o[31:1], 1'b0}; // (rs1 + imm) & ~1
    else if (pc_src)  pc_next = pc_target;
    else              pc_next = pc_plus4;
  end

  //------------------------------------------------------------
  // 2. Banco de registros
  //------------------------------------------------------------
  reg_file u_reg_file (
      .clk_i       (clk_i),
      .rst_ni      (rst_ni),
      .we_i        (reg_write_i),
      .raddr1_i    (instr_i[19:15]),
      .raddr2_i    (instr_i[24:20]),
      .waddr_i     (instr_i[11:7]),
      .wdata_i     (result),
      .rdata1_o    (src_a),
      .rdata2_o    (write_data_o),   // tambien es el dato para sw
      .dbg_raddr_i (dbg_raddr_i),
      .dbg_rdata_o (dbg_rdata_o)
  );

  //------------------------------------------------------------
  // 3. Extensor de inmediatos
  //------------------------------------------------------------
  imm_extend u_imm_extend (
      .instr_i   (instr_i[31:7]),
      .imm_src_i (imm_src_i),
      .imm_ext_o (imm_ext)
  );

  //------------------------------------------------------------
  // 4. Mux operando B + ALU
  //------------------------------------------------------------
  assign src_b = alu_src_i ? imm_ext : write_data_o;

  alu u_alu (
      .a_i        (src_a),
      .b_i        (src_b),
      .alu_ctrl_i (alu_ctrl_i),
      .result_o   (alu_result_o),
      .zero_o     (zero)
  );

  //------------------------------------------------------------
  // 5. Mux de write-back
  //------------------------------------------------------------
  always_comb begin
    case (result_src_i)
      RES_ALU: result = alu_result_o;
      RES_MEM: result = read_data_i;
      RES_PC4: result = pc_plus4;
      RES_IMM: result = imm_ext;
      default: result = alu_result_o;
    endcase
  end

endmodule
