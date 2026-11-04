package riscv_pkg;

  // Opcodes base RV32I
  typedef enum logic [6:0] {
    OPCODE_R_TYPE = 7'b0110011, // add, sub, and, or, slt, xor, sll, srl
    OPCODE_I_TYPE = 7'b0010011, // addi, andi, ori, slti, etc.
    OPCODE_LOAD   = 7'b0000011, // lw, lb, lh
    OPCODE_STORE  = 7'b0100011, // sw, sb, sh
    OPCODE_BRANCH = 7'b1100011, // beq, bne, blt, bge
    OPCODE_JAL    = 7'b1101111, // jal[cite: 17]
    OPCODE_JALR   = 7'b1100111, // jalr[cite: 17]
    OPCODE_LUI    = 7'b0110111  // lui[cite: 17]
  } opcode_e;

  // Códigos de operación interna para la ALU[cite: 17]
  typedef enum logic [3:0] {
    ALU_ADD  = 4'b0000,
    ALU_SUB  = 4'b0001,
    ALU_AND  = 4'b0010,
    ALU_OR   = 4'b0011,
    ALU_XOR  = 4'b0100,
    ALU_SLT  = 4'b0101, // Set Less Than (Signed)[cite: 17]
    ALU_SLTU = 4'b0110, // Set Less Than (Unsigned)[cite: 17]
    ALU_SLL  = 4'b0111, // Shift Left Logical[cite: 17]
    ALU_SRL  = 4'b1000  // Shift Right Logical[cite: 17]
  } alu_op_e;

endpackage