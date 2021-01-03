`include "consts.vh"

module predictor
    (
        input wire clk, rst, rdy,

        input wire [`InstAddrBus] pc,

        output reg [`InstAddrBus] next_pc,

		input wire ex_is_branch, ex_branch_en, ex_is_jalr,
		input wire [`InstAddrBus] ex_pc, ex_branch_pc
    );

	reg [`PredTagBus] tag[`PredIndexBus];
	reg [`InstAddrBus] dest[`PredIndexBus];
	reg [1:0] bht[`PredIndexBus];

	wire hit = tag[pc[`PredIndexBits]] == pc[`PredTagBits];
	wire [`InstAddrBus] pred_pc = dest[pc[`PredIndexBits]];

	integer i;

    always @(posedge clk) begin
        if (rst) begin
			for (i = 0; i < `PredIndexLen; i = i + 1) begin
				bht[i] <= 2'b0;
			end
        end else if (rdy && ex_is_branch && ! ex_is_jalr) begin
			tag[pc[`PredIndexBits]] <= ex_pc[`PredTagBits];
			dest[pc[`PredIndexBits]] <= ex_branch_pc;
			if (ex_branch_en) begin
				case (bht[pc[`PredIndexBits]])
					2'b00: bht[pc[`PredIndexBits]] <= 2'b01;
					2'b01: bht[pc[`PredIndexBits]] <= 2'b10;
					2'b10: bht[pc[`PredIndexBits]] <= 2'b11;
					2'b11: bht[pc[`PredIndexBits]] <= 2'b11;
				endcase
			end else begin
				case (bht[pc[`PredIndexBits]])
					2'b00: bht[pc[`PredIndexBits]] <= 2'b00;
					2'b01: bht[pc[`PredIndexBits]] <= 2'b00;
					2'b10: bht[pc[`PredIndexBits]] <= 2'b01;
					2'b11: bht[pc[`PredIndexBits]] <= 2'b10;
				endcase
			end
		end
    end

	always @(*) begin
		if (rst || !rdy) begin
            next_pc = `ZERO_WORD;
		end else if (hit && bht[1]) begin
			next_pc = pred_pc;
		end else begin
            next_pc = pc + 4;
		end
	end

endmodule: predictor
