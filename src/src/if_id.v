`include "consts.vh"

module if_id
    (
        input wire clk, rst, rdy,

        input wire [`InstAddrBus] if_pc,
        input wire [`InstBus] if_inst,

        input wire ex_is_branch,
        input wire [`InstAddrBus] ex_branch_pc,

        input wire [`StallBus] stall_stat,

        output reg [`InstAddrBus] id_pc,
        output reg [`InstBus] id_inst
    );

    always @(posedge clk) begin
        if (rst || ex_is_branch && ex_branch_pc != id_pc) begin
            id_pc <= `ZERO_WORD;
            id_inst <= `ZERO_WORD;
        end else if (rdy && !stall_stat[2]) begin
            if (!stall_stat[1]) begin
                id_pc <= if_pc;
                id_inst <= if_inst;
            end else begin
                id_pc <= `ZERO_WORD;
                id_inst <= `ZERO_WORD;
            end
        end
    end

endmodule: if_id