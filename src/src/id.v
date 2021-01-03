`include "consts.vh"

module id
    (
        input wire rst, rdy,
        input wire [`InstAddrBus] pc_i,
        input wire [`InstBus] inst_i,

        input wire [1:0] ex_mem_op,
        input wire ex_reg_write_en_i, mem_reg_write_en_i,
        input wire [`RegAddrBus] ex_reg_write_dest_i, mem_reg_write_dest_i,
        input wire [`RegBus] ex_reg_write_data_i, mem_reg_write_data_i,

        output reg reg1_read_en_o, reg2_read_en_o,
        output reg [`RegAddrBus] reg1_addr_o, reg2_addr_o,
        input wire [`RegBus] reg1_data_i, reg2_data_i,

        output reg [`OpBus] op_o,
        output reg [`SelBus] sel_o,
        output reg [`RegBus] reg1_o, reg2_o,
        output reg [`InstAddrBus] pc_o, offset_o,

        output reg reg_write_en_o,
        output reg [`RegAddrBus] reg_write_dest_o,

        output wire id_stall
    );

    wire [6:0] opcode = inst_i[6:0];
    wire [2:0] funct3 = inst_i[14:12];
    wire [6:0] funct7 = inst_i[31:25];

    wire [4:0] rd = inst_i[11:7];
    wire [4:0] rs1 = inst_i[19:15];
    wire [4:0] rs2 = inst_i[24:20];

    wire [11:0] immI = inst_i[31:20];
    wire [11:0] immS = {inst_i[31:25], inst_i[11:7]};
    wire [11:0] immB = {inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8]};
    wire [19:0] immU = inst_i[31:12];
    wire [19:0] immJ = {inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21]};

    reg [31:0] imm;

    wire ex_ld_en = (ex_mem_op == `MEM_OP_READ || ex_mem_op == `MEM_OP_READU);

    reg reg1_stall, reg2_stall;

    assign id_stall = reg1_stall | reg2_stall;

    always @(*) begin
        if (rst || !rdy) begin
            reg_write_dest_o = `RegAddrNOP;
            reg1_read_en_o = `FALSE;
            reg2_read_en_o = `FALSE;
            reg1_addr_o = `RegAddrNOP;
            reg2_addr_o = `RegAddrNOP;
            reg_write_en_o = `FALSE;
            op_o = `EX_NOP;
            sel_o = `EX_RES_NOP;
            imm = `ZERO_WORD;
        end else begin
            reg_write_dest_o = rd;
            case (opcode)
                `OP_IMM : begin
                    reg1_read_en_o = `TRUE;
                    reg2_read_en_o = `FALSE;
                    reg1_addr_o = rs1;
                    reg2_addr_o = `RegAddrNOP;
                    reg_write_en_o = `TRUE;

                    case (funct3)
                        `F3_ADDI: begin
                            op_o = `EX_ADD;
                            sel_o = `EX_RES_ARITH;
                            imm = {{20{immI[11]}}, immI[11:0]};
                        end
                        `F3_SLLI: begin
                            op_o = `EX_SLL;
                            sel_o = `EX_RES_SHIFT;
                            imm = {27'h0, rs2[4:0]};
                        end
                        `F3_SLTI: begin
                            op_o = `EX_SLT;
                            sel_o = `EX_RES_ARITH;
                            imm = {{20{immI[11]}}, immI[11:0]};
                        end
                        `F3_SLTIU: begin
                            op_o = `EX_SLTU;
                            sel_o = `EX_RES_ARITH;
                            imm = {{20{immI[11]}}, immI[11:0]};
                        end
                        `F3_XORI: begin
                            op_o = `EX_XOR;
                            sel_o = `EX_RES_LOGIC;
                            imm = {{20{immI[11]}}, immI[11:0]};
                        end
                        `F3_SRLI: begin
                            case (funct7)
                                `F7_SRLI : begin
                                    op_o = `EX_SRL;
                                    sel_o = `EX_RES_SHIFT;
                                    imm = {27'h0, rs2[4:0]};
                                end
                                `F7_SRAI: begin
                                    op_o = `EX_SRA;
                                    sel_o = `EX_RES_SHIFT;
                                    imm = {27'h0, rs2[4:0]};
                                end
                                default: begin
                                    op_o = `EX_NOP;
                                    sel_o = `EX_RES_NOP;
                                    imm = `ZERO_WORD;
                                end
                            endcase
                        end
                        `F3_ORI: begin
                            op_o = `EX_OR;
                            sel_o = `EX_RES_LOGIC;
                            imm = {{20{immI[11]}}, immI[11:0]};
                        end
                        `F3_ANDI: begin
                            op_o = `EX_AND;
                            sel_o = `EX_RES_LOGIC;
                            imm = {{20{immI[11]}}, immI[11:0]};
                        end
                        default: begin
                            op_o = `EX_NOP;
                            sel_o = `EX_RES_NOP;
                            imm = `ZERO_WORD;
                        end
                    endcase
                end
                `OP_LUI: begin
                    reg1_read_en_o = `FALSE;
                    reg2_read_en_o = `FALSE;
                    reg1_addr_o = `RegAddrNOP;
                    reg2_addr_o = `RegAddrNOP;
                    reg_write_en_o = `TRUE;
                    op_o = `EX_OR;
                    sel_o = `EX_RES_LOGIC;
                    imm = {immU[19:0], 12'h0};
                end
                `OP_AUIPC: begin
                    reg1_read_en_o = `FALSE;
                    reg2_read_en_o = `FALSE;
                    reg1_addr_o = `RegAddrNOP;
                    reg2_addr_o = `RegAddrNOP;
                    reg_write_en_o = `TRUE;
                    op_o = `EX_AUIPC;
                    sel_o = `EX_RES_ARITH;
                    imm = {immU[19:0], 12'h0};
                end
                `OP_OP: begin
                    reg1_read_en_o = `TRUE;
                    reg2_read_en_o = `TRUE;
                    reg1_addr_o = rs1;
                    reg2_addr_o = rs2;
                    reg_write_en_o = `TRUE;
                    imm = `ZERO_WORD;
                    
                    case (funct3)
                        `F3_ADD: begin
                            case (funct7)
                                `F7_ADD: begin
                                    op_o = `EX_ADD;
                                    sel_o = `EX_RES_ARITH;
                                end
                                `F7_SUB: begin
                                    op_o = `EX_SUB;
                                    sel_o = `EX_RES_ARITH;
                                end
                                default: begin
                                    op_o = `EX_NOP;
                                    sel_o = `EX_RES_NOP;                                    
                                end
                            endcase
                        end
                        `F3_SLL: begin
                            op_o = `EX_SLL;
                            sel_o = `EX_RES_SHIFT;
                        end
                        `F3_SLT: begin
                            op_o = `EX_SLT;
                            sel_o = `EX_RES_ARITH;
                        end
                        `F3_SLTU: begin
                            op_o = `EX_SLTU;
                            sel_o = `EX_RES_ARITH;
                        end
                        `F3_XOR: begin
                            op_o = `EX_XOR;
                            sel_o = `EX_RES_LOGIC;
                        end
                        `F3_SRL: begin
                            case (funct7)
                                `F7_SRL: begin
                                    op_o = `EX_SRL;
                                    sel_o = `EX_RES_SHIFT;
                                end
                                `F7_SRA: begin
                                    op_o = `EX_SRA;
                                    sel_o = `EX_RES_SHIFT;
                                end
                                default: begin
                                    op_o = `EX_NOP;
                                    sel_o = `EX_RES_NOP;                                    
                                end
                            endcase
                        end
                        `F3_OR: begin
                            op_o = `EX_OR;
                            sel_o = `EX_RES_LOGIC;
                        end
                        `F3_AND: begin
                            op_o = `EX_AND;
                            sel_o = `EX_RES_LOGIC;
                        end
                        default: begin
                            op_o = `EX_NOP;
                            sel_o = `EX_RES_NOP;
                        end
                    endcase
                end
                `OP_JAL: begin
                    reg1_read_en_o = `FALSE;
                    reg2_read_en_o = `FALSE;
                    reg1_addr_o = `RegAddrNOP;
                    reg2_addr_o = `RegAddrNOP;
                    reg_write_en_o = `TRUE;
                    op_o = `EX_JAL;
                    sel_o = `EX_RES_JAL;
                    imm = {{11{immJ[19]}}, immJ[19:0], 1'h0};
                end
                `OP_JALR: begin
                    reg1_read_en_o = `TRUE;
                    reg2_read_en_o = `FALSE;
                    reg1_addr_o = rs1;
                    reg2_addr_o = `RegAddrNOP;
                    reg_write_en_o = `TRUE;
                    op_o = `EX_JALR;
                    sel_o = `EX_RES_JAL;
                    imm = {{20{immI[11]}}, immI[11:0]};
                end
                `OP_BRANCH: begin
                    reg1_read_en_o = `TRUE;
                    reg2_read_en_o = `TRUE;
                    reg1_addr_o = rs1;
                    reg2_addr_o = rs2;
                    reg_write_en_o = `FALSE;
                    sel_o = `EX_RES_NOP;
                    imm = {{19{immB[11]}}, immB[11:0], 1'B0};

                    case (funct3)
                        `F3_BEQ: begin
                            op_o = `EX_BEQ;
                        end
                        `F3_BNE: begin
                            op_o = `EX_BNE;
                        end
                        `F3_BLT: begin
                            op_o = `EX_BLT;
                        end
                        `F3_BGE: begin
                            op_o = `EX_BGE;
                        end
                        `F3_BLTU: begin
                            op_o = `EX_BLTU;
                        end
                        `F3_BGEU: begin
                            op_o = `EX_BGEU;
                        end
                        default: begin
                            op_o = `EX_NOP;
                        end
                    endcase
                end
                `OP_LOAD: begin
                    reg1_read_en_o = `TRUE;
                    reg2_read_en_o = `FALSE;
                    reg1_addr_o = rs1;
                    reg2_addr_o = `RegAddrNOP;
                    reg_write_en_o = `TRUE;
                    imm = {{20{immI[11]}}, immI[11:0]};

                    case (funct3)
                        `F3_LB: begin
                            op_o = `EX_LB;
                            sel_o = `EX_RES_MEM;
                        end
                        `F3_LH: begin
                            op_o = `EX_LH;
                            sel_o = `EX_RES_MEM;
                        end
                        `F3_LW: begin
                            op_o = `EX_LW;
                            sel_o = `EX_RES_MEM;
                        end
                        `F3_LBU: begin
                            op_o = `EX_LBU;
                            sel_o = `EX_RES_MEM;
                        end
                        `F3_LHU: begin
                            op_o = `EX_LHU;
                            sel_o = `EX_RES_MEM;
                        end
                        default: begin
                            op_o = `EX_NOP;
                            sel_o = `EX_RES_NOP;
                        end
                    endcase
                end
                `OP_STORE: begin
                    reg1_read_en_o = `TRUE;
                    reg2_read_en_o = `TRUE;
                    reg1_addr_o = rs1;
                    reg2_addr_o = rs2;
                    reg_write_en_o = `FALSE;
                    imm = {{20{immS[11]}}, immS[11:0]};

                    case (funct3)
                        `F3_SB: begin
                            op_o = `EX_SB;
                            sel_o = `EX_RES_MEM;
                        end
                        `F3_SH: begin
                            op_o = `EX_SH;
                            sel_o = `EX_RES_MEM;
                        end
                        `F3_SW: begin
                            op_o = `EX_SW;
                            sel_o = `EX_RES_MEM;
                        end
                        default: begin
                            op_o = `EX_NOP;
                            sel_o = `EX_RES_NOP;
                        end
                    endcase
                end
                default: begin
                    reg1_read_en_o = `FALSE;
                    reg2_read_en_o = `FALSE;
                    reg1_addr_o = `RegAddrNOP;
                    reg2_addr_o = `RegAddrNOP;
                    reg_write_en_o = `FALSE;
                    op_o = `EX_NOP;
                    sel_o = `EX_RES_NOP;
                    imm = `ZERO_WORD;
                end
            endcase
        end
    end

    always @(*) begin
        if (rst || !rdy) begin
            reg1_o = `ZERO_WORD;
            reg1_stall = `FALSE;
        end else if (reg1_read_en_o) begin
            if (reg1_addr_o == `RegAddrNOP) begin
                reg1_o = `ZERO_WORD;
                reg1_stall = `FALSE;
            end else if (ex_ld_en && ex_reg_write_dest_i == reg1_addr_o) begin
                reg1_o = `ZERO_WORD;
                reg1_stall = `TRUE;
            end else if (ex_reg_write_en_i && ex_reg_write_dest_i == reg1_addr_o) begin
                reg1_o = ex_reg_write_data_i;
                reg1_stall = `FALSE;
            end else if (mem_reg_write_en_i && mem_reg_write_dest_i == reg1_addr_o) begin
                reg1_o = mem_reg_write_data_i;
                reg1_stall = `FALSE;
            end else begin
                reg1_o = reg1_data_i;
                reg1_stall = `FALSE;
            end
        end else begin
            reg1_o = imm;
            reg1_stall = `FALSE;
        end
    end

    always @(*) begin
        if (rst || !rdy) begin
            reg2_o = `ZERO_WORD;
            reg2_stall = `FALSE;
        end else if (reg2_read_en_o) begin
            if (reg2_addr_o == `RegAddrNOP) begin
                reg2_o = `ZERO_WORD;
                reg2_stall = `FALSE;
            end else if (ex_ld_en && ex_reg_write_dest_i == reg2_addr_o) begin
                reg2_o = `ZERO_WORD;
                reg2_stall = `TRUE;
            end else if (ex_reg_write_en_i && ex_reg_write_dest_i == reg2_addr_o) begin
                reg2_o = ex_reg_write_data_i;
                reg2_stall = `FALSE;
            end else if (mem_reg_write_en_i && mem_reg_write_dest_i == reg2_addr_o) begin
                reg2_o = mem_reg_write_data_i;
                reg2_stall = `FALSE;
            end else begin
                reg2_o = reg2_data_i;
                reg2_stall = `FALSE;
            end
        end else begin
            reg2_o = imm;
            reg2_stall = `FALSE;
        end
    end

    always @(*) begin
        if (rst || !rdy) begin
            pc_o = `ZERO_WORD;
            offset_o = `ZERO_WORD;
        end else begin
            pc_o = pc_i;
            offset_o = imm;
        end
    end

endmodule: id