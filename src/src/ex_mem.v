`include "consts.vh"

module ex_mem
    (
        input wire clk, rst, rdy,

        input wire [`RegAddrBus] ex_reg_write_dest,
        input wire ex_reg_write_en,
        input wire [`RegBus] ex_reg_write_data,

        input wire [1:0] ex_mem_op,
        input wire [1:0] ex_mem_length,
        input wire [`MemAddrBus] ex_mem_addr,

        input wire [`StallBus] stall_stat,

        output reg [`RegAddrBus] mem_reg_write_dest,
        output reg mem_reg_write_en,
        output reg [`RegBus] mem_reg_write_data,

        output reg [1:0] mem_mem_op,
        output reg [1:0] mem_mem_length,
        output reg [`MemAddrBus] mem_mem_addr
    );

    always @(posedge clk) begin
        if (rst) begin
            mem_reg_write_dest <= `RegAddrNOP;
            mem_reg_write_en <= 1'b0;
            mem_reg_write_data <= `ZERO_WORD;
            mem_mem_op <= `MEM_OP_NONE;
            mem_mem_length <= 2'b0;
            mem_mem_addr <= `ZERO_WORD;
        end else if (rdy && !stall_stat[4]) begin
            if (!stall_stat[3]) begin
                mem_reg_write_dest <= ex_reg_write_dest;
                mem_reg_write_en <= ex_reg_write_en;
                mem_reg_write_data <= ex_reg_write_data;
                mem_mem_op <= ex_mem_op;
                mem_mem_length <= ex_mem_length;
                mem_mem_addr <= ex_mem_addr;
            end else begin
                mem_reg_write_dest <= `RegAddrNOP;
                mem_reg_write_en <= 1'b0;
                mem_reg_write_data <= `ZERO_WORD;
                mem_mem_op <= `MEM_OP_NONE;
                mem_mem_length <= 2'b0;
                mem_mem_addr <= `ZERO_WORD;
            end
        end
    end

endmodule: ex_mem