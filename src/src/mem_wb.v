`include "consts.vh"

module mem_wb
    (
        input clk, rst, rdy,

        input wire mem_reg_write_en,
        input wire [`RegAddrBus ] mem_reg_write_dest,
        input wire [`RegBus] mem_reg_write_data,

        output reg wb_reg_write_en,
        output reg [`RegAddrBus] wb_reg_write_dest,
        output reg [`RegBus] wb_reg_write_data,

        input wire [`StallBus] stall_stat
    );

    always @(posedge clk) begin
        if (rst) begin
            wb_reg_write_en <= `FALSE;
            wb_reg_write_dest <= `RegAddrNOP ;
            wb_reg_write_data <= `ZERO_WORD;
        end else if (rdy && !stall_stat[5]) begin
            wb_reg_write_en <= mem_reg_write_en;
            wb_reg_write_dest <= mem_reg_write_dest;
            wb_reg_write_data <= mem_reg_write_data;
        end
    end

endmodule: mem_wb