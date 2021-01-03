`ifndef __CONST_RISCV
`define __CONST_RISCV

`define ZERO_WORD 32'h00000000
`define TRUE 1'b1
`define FALSE 1'b0

`define InstLen 32
`define InstBus 31:0
`define InstAddrLen 32
`define InstAddrBus 31:0

`define RegAddrLen 5
`define RegAddrBus 4:0
`define RegAddrNOP 5'b0
`define RegNum 32
`define RegLen 32
`define RegBus 31:0

`define ICacheIndexLen 256
`define ICacheIndexBus 0:255
`define ICacheIndexBits 9:2
`define ICacheTagBus 8:0
`define ICacheTagBits 17:10

`define PredIndexLen 256
`define PredIndexBus 0:255
`define PredIndexBits 9:2
`define PredTagBus 7:0
`define PredTagBits 17:10

//OP
`define OP_IMM 7'b0010011
`define OP_LUI 7'b0110111
`define OP_AUIPC 7'b0010111
`define OP_OP 7'b0110011
`define OP_JAL 7'b1101111
`define OP_JALR 7'b1100111
`define OP_BRANCH 7'b1100011
`define OP_LOAD 7'b0000011
`define OP_STORE 7'b0100011

//FUNCT3
`define F3_BEQ 3'b000
`define F3_BNE 3'b001
`define F3_BLT 3'b100
`define F3_BGE 3'b101
`define F3_BLTU 3'b110
`define F3_BGEU 3'b111

`define F3_LB 3'b000
`define F3_LH 3'b001
`define F3_LW 3'b010
`define F3_LBU 3'b100
`define F3_LHU 3'b101

`define F3_SB 3'b000
`define F3_SH 3'b001
`define F3_SW 3'b010

`define F3_ADD 3'b000
`define F3_SUB 3'b000
`define F3_SLL 3'b001
`define F3_SLT 3'b010
`define F3_SLTU 3'b011
`define F3_XOR 3'b100
`define F3_SRL 3'b101
`define F3_SRA 3'b101
`define F3_OR 3'b110
`define F3_AND 3'b111

`define F3_ADDI 3'b000
`define F3_SLLI 3'b001
`define F3_SLTI 3'b010
`define F3_SLTIU 3'b011
`define F3_XORI 3'b100
`define F3_SRLI 3'b101
`define F3_ORI 3'b110
`define F3_ANDI 3'b111

//FUNCT7
`define F7_SLLI 7'b0000000
`define F7_SRLI 7'b0000000
`define F7_SRAI 7'b0100000
`define F7_ADD 7'b0000000
`define F7_SUB 7'b0100000
`define F7_SLL 7'b0000000
`define F7_SLT 7'b0000000
`define F7_SLTU 7'b0000000
`define F7_XOR 7'b0000000
`define F7_SRL 7'b0000000
`define F7_SRA 7'b0100000
`define F7_OR 7'b0000000
`define F7_AND 7'b0000000

//EX_OP
`define OpBus 4:0

`define EX_NOP 5'h0
`define EX_ADD 5'h1
`define EX_SUB 5'h2
`define EX_SLT 5'h3
`define EX_SLTU 5'h4
`define EX_XOR 5'h5
`define EX_OR 5'h6
`define EX_AND 5'h7
`define EX_SLL 5'h8
`define EX_SRL 5'h9
`define EX_SRA 5'ha
`define EX_AUIPC 5'hb

`define EX_JAL 5'hc
`define EX_JALR 5'hd
`define EX_BEQ 5'he
`define EX_BNE 5'hf
`define EX_BLT 5'h10
`define EX_BGE 5'h11
`define EX_BLTU 5'h12
`define EX_BGEU 5'h13

`define EX_LB 5'h14
`define EX_LH 5'h15
`define EX_LW 5'h16
`define EX_LBU 5'h17
`define EX_LHU 5'h18

`define EX_SB 5'h19
`define EX_SH 5'h1a
`define EX_SW 5'h1b

//EX_SEL
`define SelBus 2:0

`define EX_RES_NOP 3'b000
`define EX_RES_LOGIC 3'b001
`define EX_RES_SHIFT 3'b010
`define EX_RES_ARITH 3'b011
`define EX_RES_JAL 3'b100
`define EX_RES_MEM 3'b101

`define MemAddrBus 31:0
`define MemBus 7:0

`define MEM_OP_NONE 2'b00
`define MEM_OP_READ 2'b01
`define MEM_OP_READU 2'b10
`define MEM_OP_WRITE 2'b11

`define MEM_STAT_READ 1'b0
`define MEM_STAT_WRITE 1'b1
`define MEM_STAT_RAM 1'b0
`define MEM_STAT_INST 1'b1

`define StallBus 5:0
`define NO_STALL 6'b000000
`define IF_STALL 6'b000011
`define ID_STALL 6'b000111
`define MEM_STALL 6'b011111
`define ALL_STALL 6'b111111

`endif