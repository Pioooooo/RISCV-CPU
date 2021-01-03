`include "consts.vh"

module reg_file
    (
        input wire clk, rst, rdy,

        input wire w_en,
        input wire [`RegAddrLen-1:0] w_addr,
        input wire [`RegLen-1:0] w_data,

        input wire r1_en, r2_en,
        input wire [`RegAddrLen-1:0] r1_addr, r2_addr,
        output reg [`RegLen-1:0] r1_data, r2_data
    );

    reg [`RegLen-1:0] regs[0:`RegNum-1];
    integer i;
    
    always @(posedge clk) begin
        if(rst) begin
            for (i = 0; i < `RegNum; i = i + 1) begin
                regs[i] <= `ZERO_WORD;
            end
        end else if (rdy && w_en && w_addr != `RegAddrNOP) begin
            regs[w_addr] <= w_data;
        end
    end

    always @(*)begin
        if (rst || !rdy || r1_addr == `RegAddrNOP) begin
            r1_data = `ZERO_WORD;
        end else if (w_en && w_addr == r1_addr) begin
            r1_data = w_data;
        end else begin
            r1_data = regs[r1_addr];
        end
    end
    always @(*)begin
        if (rst || !rdy || r2_addr == `RegAddrNOP) begin
            r2_data = `ZERO_WORD;
        end else if (w_en && w_addr == r2_addr) begin
            r2_data = w_data;
        end else begin
            r2_data = regs[r2_addr];
        end
    end

endmodule: reg_file