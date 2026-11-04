`timescale 1ns / 1ps

module riscv_single_cycle (
    input  logic        clk_i,
    input  logic        rst_ni,

    // Interfaz con Memoria de Instrucciones (ROM/IMEM)[cite: 17]
    output logic [31:0] imem_addr_o,
    input  logic [31:0] instr_i,

    // Interfaz con Memoria de Datos (RAM/DMEM)[cite: 17]
    output logic [31:0] dmem_addr_o,
    output logic [31:0] dmem_wdata_o,
    output logic        dmem_we_o,
    input  logic [31:0] dmem_rdata_i
);

  // Cables de interconexión Control <-> Datapath[cite: 17]
  logic       reg_write;
  logic [2:0] imm_src;
  logic       alu_src;
  logic [1:0] result_src;
  logic       branch;
  logic       jump;
  logic [3:0] alu_ctrl;

  // Instanciación de la Unidad de Control[cite: 17]
  control_unit u_control_unit (
      .opcode_i     (instr_i[6:0]),
      .funct3_i     (instr_i[14:12]),
      .funct7b5_i   (instr_i[30]),
      .reg_write_o  (reg_write),
      .imm_src_o    (imm_src),
      .alu_src_o    (alu_src),
      .mem_write_o  (dmem_we_o),
      .result_src_o (result_src),
      .branch_o     (branch),
      .jump_o       (jump),
      .alu_ctrl_o   (alu_ctrl)
  );

  // Instanciación del Datapath[cite: 17]
  datapath u_datapath (
      .clk_i        (clk_i),
      .rst_ni       (rst_ni),
      .reg_write_i  (reg_write),
      .imm_src_i    (imm_src),
      .alu_src_i    (alu_src),
      .result_src_i (result_src),
      .branch_i     (branch),
      .jump_i       (jump),
      .alu_ctrl_i   (alu_ctrl),
      .pc_o         (imem_addr_o),
      .instr_i      (instr_i),
      .alu_result_o (dmem_addr_o),
      .write_data_o (dmem_wdata_o),
      .read_data_i  (dmem_rdata_i)
  );

endmodule