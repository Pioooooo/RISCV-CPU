`include "consts.vh"

module ex
    #(
        parameter DBG = 0
    )
    (
        input wire rst, rdy,

        input wire [`OpBus] op_i,
        input wire [`SelBus] sel_i,
        input wire [`RegBus] reg1_i, reg2_i,
        input wire reg_write_en_i,
        input wire [`RegAddrBus] reg_write_dest_i,
        input wire [`InstAddrBus] pc_i, offset_i,

        output reg [`RegAddrBus] reg_write_dest_o,
        output reg reg_write_en_o,
        output reg [`RegBus] reg_write_data_o,

        output reg is_branch_o, branch_en_o, is_jalr_o,
        output reg [`InstAddrBus] branch_pc_o,

        output reg [1:0] mem_op_o,
        output reg [1:0] mem_length_o,
        output reg [`MemAddrBus] mem_addr_o
    );

    reg [`RegBus] logic_o;
    reg [`RegBus] shift_o;
    reg [`RegBus] arith_o;

    always @(*) begin
        if (rst || !rdy) begin
            is_branch_o = `FALSE;
            branch_en_o = `FALSE;
            is_jalr_o = `FALSE;
            branch_pc_o = `ZERO_WORD;
        end else begin
            case (op_i)
                `EX_JAL: begin
                    is_branch_o = `TRUE;
                    is_jalr_o = `FALSE;
                    branch_en_o = `TRUE;
                    branch_pc_o = pc_i + offset_i;
                end
                `EX_JALR: begin
                    is_branch_o = `TRUE;
                    is_jalr_o = `TRUE;
                    branch_en_o = `TRUE;
                    branch_pc_o = (reg1_i + reg2_i) & ~32'h1;
                end
                `EX_BEQ: begin
                    is_branch_o = `TRUE;
                    is_jalr_o = `FALSE;
                    branch_en_o = (reg1_i == reg2_i);
                    branch_pc_o = branch_en_o ? pc_i + offset_i : pc_i + 4;
                end
                `EX_BNE: begin
                    is_branch_o = `TRUE;
                    is_jalr_o = `FALSE;
                    branch_en_o = (reg1_i != reg2_i);
                    branch_pc_o = branch_en_o ? pc_i + offset_i : pc_i + 4;
                end
                `EX_BLT: begin
                    is_branch_o = `TRUE;
                    is_jalr_o = `FALSE;
                    branch_en_o = ($signed(reg1_i) < $signed(reg2_i));
                    branch_pc_o = branch_en_o ? pc_i + offset_i : pc_i + 4;
                end
                `EX_BGE: begin
                    is_branch_o = `TRUE;
                    is_jalr_o = `FALSE;
                    branch_en_o = ($signed(reg1_i) >= $signed(reg2_i));
                    branch_pc_o = branch_en_o ? pc_i + offset_i : pc_i + 4;
                end
                `EX_BLTU: begin
                    is_branch_o = `TRUE;
                    is_jalr_o = `FALSE;
                    branch_en_o = (reg1_i < reg2_i);
                    branch_pc_o = branch_en_o ? pc_i + offset_i : pc_i + 4;
                end
                `EX_BGEU: begin
                    is_branch_o = `TRUE;
                    is_jalr_o = `FALSE;
                    branch_en_o = (reg1_i >= reg2_i);
                    branch_pc_o = branch_en_o ? pc_i + offset_i : pc_i + 4;
                end
                default: begin
                    is_branch_o = `FALSE;
                    is_jalr_o = `FALSE;
                    branch_en_o = `FALSE;
                    branch_pc_o = `ZERO_WORD;
                end
            endcase
        end
    end

    always @(*) begin
        if (rst || !rdy) begin
            logic_o = `ZERO_WORD;
        end else begin
            case (op_i)
                `EX_OR: begin
                    logic_o = reg1_i | reg2_i;
                end
                `EX_XOR: begin
                    logic_o = reg1_i ^ reg2_i;
                end
                `EX_AND: begin
                    logic_o = reg1_i & reg2_i;
                end
                default: begin
                    logic_o = `ZERO_WORD;
                end
            endcase
        end
    end

    always @(*) begin
        if (rst || !rdy) begin
            shift_o = `ZERO_WORD;
        end else begin
            case (op_i)
                `EX_SLL: begin
                    shift_o = reg1_i << reg2_i[4:0];
                end
                `EX_SRL: begin
                    shift_o = reg1_i >> reg2_i[4:0];
                end
                `EX_SRA: begin
                    shift_o = $signed(reg1_i) >>> reg2_i[4:0];
                end
                default: begin
                    shift_o = `ZERO_WORD;
                end
            endcase
        end
    end

    always @(*) begin
        if (rst || !rdy) begin
            arith_o = `ZERO_WORD;
        end else begin
            case (op_i)
                `EX_ADD: begin
                    arith_o = reg1_i+reg2_i;
                end
                `EX_SUB: begin
                    arith_o = reg1_i-reg2_i;
                end
                `EX_SLT: begin
                    arith_o = $signed(reg1_i) < $signed(reg2_i);
                end
                `EX_SLTU: begin
                    arith_o = reg1_i < reg2_i;
                end
                `EX_AUIPC: begin
                    arith_o = pc_i + offset_i;
                end
                default: begin
                    arith_o = `ZERO_WORD;
                end
            endcase
        end
    end

    always @(*) begin
        if (rst || !rdy) begin
            mem_length_o = 2'b0;
            mem_addr_o = `ZERO_WORD;
            mem_op_o = `MEM_OP_NONE;
        end else begin
            case (op_i)
                `EX_SB: begin
                    mem_length_o = 0;
                    mem_addr_o = reg1_i + offset_i;
                    mem_op_o = `MEM_OP_WRITE;
                end
                `EX_SH: begin
                    mem_length_o = 1;
                    mem_addr_o = reg1_i + offset_i;
                    mem_op_o = `MEM_OP_WRITE;
                end
                `EX_SW: begin
                    mem_length_o = 3;
                    mem_addr_o = reg1_i + offset_i;
                    mem_op_o = `MEM_OP_WRITE;
                end
                `EX_LB: begin
                    mem_length_o = 0;
                    mem_addr_o = reg1_i + offset_i;
                    mem_op_o = `MEM_OP_READ;
                end
                `EX_LH: begin
                    mem_length_o = 1;
                    mem_addr_o = reg1_i + offset_i;
                    mem_op_o = `MEM_OP_READ;
                end
                `EX_LW: begin
                    mem_length_o = 3;
                    mem_addr_o = reg1_i + offset_i;
                    mem_op_o = `MEM_OP_READ;
                end
                `EX_LBU: begin
                    mem_length_o = 0;
                    mem_addr_o = reg1_i + offset_i;
                    mem_op_o = `MEM_OP_READU;
                end
                `EX_LHU: begin
                    mem_length_o = 1;
                    mem_addr_o = reg1_i + offset_i;
                    mem_op_o = `MEM_OP_READU;
                end
                default: begin
                    mem_length_o = 2'b0;
                    mem_addr_o = `ZERO_WORD;
                    mem_op_o = `MEM_OP_NONE;
                end
            endcase
        end
    end

    always @(*) begin
        if (rst || !rdy) begin
            reg_write_en_o = `FALSE;
            reg_write_dest_o = `ZERO_WORD;
            reg_write_data_o = `ZERO_WORD;
        end else begin
            if (DBG && pc_i != `ZERO_WORD) $write("%X\t%X\t%X\n", pc_i, reg1_i, reg2_i);
            case (sel_i)
                `EX_RES_JAL : begin
                    reg_write_en_o = reg_write_en_i;
                    reg_write_dest_o = reg_write_dest_i;
                    reg_write_data_o = pc_i + 4;
                end
                `EX_RES_LOGIC: begin
                    reg_write_en_o = reg_write_en_i;
                    reg_write_dest_o = reg_write_dest_i;
                    reg_write_data_o = logic_o;
                end
                `EX_RES_SHIFT: begin
                    reg_write_en_o = reg_write_en_i;
                    reg_write_dest_o = reg_write_dest_i;
                    reg_write_data_o = shift_o;
                end
                `EX_RES_ARITH: begin
                    reg_write_en_o = reg_write_en_i;
                    reg_write_dest_o = reg_write_dest_i;
                    reg_write_data_o = arith_o;
                end
                `EX_RES_MEM: begin
                    reg_write_en_o = reg_write_en_i;
                    reg_write_dest_o = reg_write_dest_i;
                    reg_write_data_o = reg2_i;
                end
                default: begin
                    reg_write_en_o = `FALSE;
                    reg_write_dest_o = `ZERO_WORD;
                    reg_write_data_o = `ZERO_WORD;
                end
            endcase
        end
    end

endmodule: ex