`include "consts.vh"

module id_ex
    (
        input wire clk, rst, rdy,

        input wire [`OpBus] id_op,
        input wire [`SelBus] id_sel,
        input wire [`RegBus] id_reg1, id_reg2,
        input wire id_reg_write_en,
        input wire [`RegAddrBus] id_reg_write_dest,
        input wire [`InstAddrBus] id_pc, id_offset,

        input wire [`StallBus] stall_stat,

        input wire ex_is_branch,
        input wire [`InstAddrBus] ex_branch_pc,

        output reg [`OpBus] ex_op,
        output reg [`SelBus] ex_sel,
        output reg [`RegBus] ex_reg1, ex_reg2,
        output reg ex_reg_write_en,
        output reg [`RegAddrBus] ex_reg_write_dest,
        output reg [`InstAddrBus] ex_pc, ex_offset
    );

    always @(posedge clk) begin
        if (rst || ex_is_branch && ex_branch_pc != id_pc) begin
            ex_op <= `EX_NOP;
            ex_sel <= `EX_RES_NOP;
            ex_reg1 <= `ZERO_WORD;
            ex_reg2 <= `ZERO_WORD;
            ex_reg_write_en <= `FALSE;
            ex_reg_write_dest <= `RegAddrNOP;
            ex_pc <= `ZERO_WORD;
            ex_offset <= `ZERO_WORD;
        end else if (rdy && !stall_stat[3]) begin
            if (!stall_stat[2]) begin
                ex_op <= id_op;
                ex_sel <= id_sel;
                ex_reg1 <= id_reg1;
                ex_reg2 <= id_reg2;
                ex_reg_write_dest <= id_reg_write_dest;
                ex_reg_write_en <= id_reg_write_en;
                ex_pc <= id_pc;
                ex_offset <= id_offset;
            end else begin
                ex_op <= `EX_NOP;
                ex_sel <= `EX_RES_NOP;
                ex_reg1 <= `ZERO_WORD;
                ex_reg2 <= `ZERO_WORD;
                ex_reg_write_en <= `FALSE;
                ex_reg_write_dest <= `RegAddrNOP;
                ex_pc <= `ZERO_WORD;
                ex_offset <= `ZERO_WORD;
            end
        end
    end

endmodule: id_ex