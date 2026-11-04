`timescale 1ns / 1ps

module datapath (
    input  logic        clk_i,
    input  logic        rst_ni,
    
    // Control proveniente de la Control Unit
    input  logic        reg_write_i,
    input  logic [2:0]  imm_src_i,
    input  logic        alu_src_i,
    input  logic [1:0]  result_src_i,
    input  logic        branch_i,
    input  logic        jump_i,
    input  logic [3:0]  alu_ctrl_i,

    // Interfaz con Memoria de Instrucciones
    output logic [31:0] pc_o,
    input  logic [31:0] instr_i,

    // Interfaz con Memoria de Datos[cite: 17]
    output logic [31:0] alu_result_o,
    output logic [31:0] write_data_o,
    input  logic [31:0] read_data_i
);

  // Señales internas del Datapath[cite: 17]
  logic [31:0] pc_next;
  logic [31:0] pc_target;
  logic [31:0] pc_plus4;
  logic [31:0] imm_ext;
  logic [31:0] src_a;
  logic [31:0] src_b;
  logic [31:0] result;
  logic        zero;
  logic        pc_src;

  // 1. Lógica del Program Counter (PC)[cite: 17]
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      pc_o <= 32'b0;
    end else begin
      pc_o <= pc_next;
    end
  end

  assign pc_plus4  = pc_o + 32'd4;
  assign pc_target = pc_o + imm_ext; // Dirección de salto (branch o jal)[cite: 17]

  // Condición de salto: Jump incondicional (JAL) o Branch tomado (BEQ con Zero activo)[cite: 17]
  assign pc_src = jump_i | (branch_i & zero);
  assign pc_next = pc_src ? pc_target : pc_plus4;

  // 2. Banco de Registros[cite: 17]
  reg_file u_reg_file (
      .clk_i    (clk_i),
      .rst_ni   (rst_ni),
      .we_i     (reg_write_i),
      .raddr1_i (instr_i[19:15]),
      .raddr2_i (instr_i[24:20]),
      .waddr_i  (instr_i[11:7]),
      .wdata_i  (result),
      .rdata1_o (src_a),
      .rdata2_o (write_data_o) // Salida para sw hacia memoria de datos[cite: 17]
  );

  // 3. Extensor de Inmediatos[cite: 17]
  imm_extend u_imm_extend (
      .instr_i   (instr_i[31:7]),
      .imm_src_i (imm_src_i),
      .imm_ext_o (imm_ext)
  );

  // 4. Mux de Entrada B de la ALU (Registro vs Inmediato)[cite: 17]
  assign src_b = alu_src_i ? imm_ext : write_data_o;

  // 5. ALU[cite: 17]
  alu u_alu (
      .a_i        (src_a),
      .b_i        (src_b),
      .alu_ctrl_i (alu_ctrl_i),
      .result_o   (alu_result_o),
      .zero_o     (zero)
  );

  // 6. Mux para Selección del Resultado (Writeback al Banco de Registros)[cite: 17]
  always_comb begin
    case (result_src_i)
      2'b00:   result = alu_result_o; // Operaciones R-type / I-type[cite: 17]
      2'b01:   result = read_data_i;  // lw[cite: 17]
      2'b10:   result = pc_plus4;     // jal (retorno link)[cite: 17]
      default: result = alu_result_o;
    endcase
  end

endmodule