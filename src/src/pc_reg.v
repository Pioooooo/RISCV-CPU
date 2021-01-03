`include "consts.vh"

module pc_reg
    (
        input wire clk, rst, rdy,

        output reg [`InstAddrBus] pc,

        input wire [`InstAddrBus] next_pc,

        input wire [`StallBus] stall_stat,

        input wire ex_is_branch,
        input wire [`InstAddrBus] ex_branch_pc, id_pc
    );

    always @(posedge clk) begin
        if (rst) begin
            pc <= `ZERO_WORD;
        end else if (rdy) begin
            if (ex_is_branch && ex_branch_pc != id_pc) begin
                pc <= ex_branch_pc;
            end else if (!stall_stat[0]) begin
                pc <= next_pc;
            end
        end
    end

endmodule: pc_reg
