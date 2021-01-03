`include "consts.vh"

module IF
    (
        input wire clk, rst, rdy,

        input wire [`InstAddrBus] pc_i,

        output reg mem_en_o,
        output reg [`InstAddrBus] mem_addr_o,
        input wire mem_rdy_i,
        input wire [`InstBus] inst_i,

        output reg [`InstAddrBus] pc_o,
        output reg [`InstBus] inst_o,

        output reg if_stall
    );

    reg [`ICacheTagBus] tag[`ICacheIndexBus];
    reg [`InstBus] inst[`ICacheIndexBus];

    wire hit = tag[pc_i[`ICacheIndexBits]] == {1'b1, pc_i[`ICacheTagBits]};
    wire [`InstBus] cache_inst = inst[pc_i[`ICacheIndexBits]];

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < `ICacheIndexLen; i = i + 1) begin
                tag[i] <= 0;
            end
        end else if (rdy) begin
            if (mem_rdy_i) begin
                tag[pc_i[`ICacheIndexBits]] <= {1'b1, pc_i[`ICacheTagBits]};
                inst[pc_i[`ICacheIndexBits]] <= inst_i;
            end
        end
    end

    always @(*) begin
        if (rst || !rdy) begin
            mem_en_o = `FALSE;
            mem_addr_o = `ZERO_WORD;
            pc_o = `ZERO_WORD;
            inst_o = `ZERO_WORD;
            if_stall = `FALSE;
        end else if (hit) begin
            mem_en_o = `FALSE;
            mem_addr_o = `ZERO_WORD;
            pc_o = pc_i;
            inst_o = cache_inst;
            if_stall = `FALSE;
        end else if (mem_rdy_i) begin
            mem_en_o = `FALSE;
            mem_addr_o = pc_i + 4;
            pc_o = pc_i;
            inst_o = inst_i;
            if_stall = `FALSE;
        end else begin
            mem_en_o = `TRUE;
            mem_addr_o = pc_i;
            pc_o = pc_i;
            inst_o = inst_i;
            if_stall = `TRUE;
        end
    end

endmodule: IF
