`include "consts.vh"

module mem
    (
        input wire rst, rdy,

        input wire [`RegAddrBus] reg_write_dest_i,
        input wire reg_write_en_i,
        input wire [`RegBus] reg_write_data_i,

        input wire [1:0] mem_op_i,
        input wire [1:0] mem_length_i,
        input wire [`MemAddrBus] mem_addr_i,

        output reg [`RegAddrBus] reg_write_dest_o,
        output reg reg_write_en_o,
        output reg [`RegBus] reg_write_data_o,

        output reg ram_r_en_o, ram_w_en_o,
        output reg [1:0] ram_length_o,
        output reg [`MemAddrBus] ram_addr_o,
        output reg [`RegBus] ram_data_o,

        input wire [`RegBus] ram_data_i,
        input wire ram_rdy_i,

        output reg mem_stall
    );

    always @(*) begin
        if (rst || !rdy) begin
            reg_write_dest_o = `RegAddrNOP;
            reg_write_en_o = `FALSE;
            reg_write_data_o = `ZERO_WORD;
            mem_stall = `FALSE;
            ram_r_en_o = `FALSE;
            ram_w_en_o = `FALSE;
            ram_length_o = 2'b0;
            ram_addr_o = `ZERO_WORD;
            ram_data_o = `ZERO_WORD;
        end else if (ram_rdy_i) begin
            case (mem_op_i)
                `MEM_OP_READ:begin
                    case (mem_length_i)
                        2'b00: reg_write_data_o = {{24{ram_data_i[7]}}, ram_data_i[7:0]};
                        2'b01: reg_write_data_o = {{16{ram_data_i[15]}}, ram_data_i[15:0]};
                        2'b10: reg_write_data_o = {{8{ram_data_i[23]}}, ram_data_i[23:0]};
                        2'b11: reg_write_data_o = ram_data_i;
                    endcase
                end
                `MEM_OP_READU: begin
                    case (mem_length_i)
                        2'b00: reg_write_data_o = {24'b0, ram_data_i[7:0]};
                        2'b01: reg_write_data_o = {16'b0, ram_data_i[15:0]};
                        2'b10: reg_write_data_o = {8'b0, ram_data_i[23:0]};
                        2'b11: reg_write_data_o = ram_data_i;
                    endcase
                end
                default: begin
                    reg_write_data_o = reg_write_data_i;
                end
            endcase
            reg_write_dest_o = reg_write_dest_i;
            reg_write_en_o = reg_write_en_i;
            ram_r_en_o = `FALSE;
            ram_w_en_o = `FALSE;
            ram_length_o = 2'b0;
            ram_addr_o = `ZERO_WORD;
            ram_data_o = `ZERO_WORD;
            mem_stall = `FALSE;
        end else begin
            case (mem_op_i)
                `MEM_OP_READ:begin
                    reg_write_dest_o = `RegAddrNOP;
                    reg_write_en_o = `FALSE;
                    reg_write_data_o = `ZERO_WORD;
                    ram_length_o = mem_length_i;
                    ram_r_en_o = `TRUE;
                    ram_w_en_o = `FALSE;
                    ram_addr_o = mem_addr_i;
                    ram_data_o = `ZERO_WORD;
                    mem_stall = `TRUE;
                end
                `MEM_OP_READU: begin
                    reg_write_dest_o = `RegAddrNOP;
                    reg_write_en_o = `FALSE;
                    reg_write_data_o = `ZERO_WORD;
                    ram_length_o = mem_length_i;
                    ram_r_en_o = `TRUE;
                    ram_w_en_o = `FALSE;
                    ram_addr_o = mem_addr_i;
                    ram_data_o = `ZERO_WORD;
                    mem_stall = `TRUE;
                end
                `MEM_OP_WRITE: begin
                    reg_write_dest_o = `RegAddrNOP;
                    reg_write_en_o = `FALSE;
                    reg_write_data_o = `ZERO_WORD;
                    ram_length_o = mem_length_i;
                    ram_r_en_o = `FALSE;
                    ram_w_en_o = `TRUE;
                    ram_addr_o = mem_addr_i;
                    mem_stall = `TRUE;
                    case (mem_length_i)
                        2'b00:ram_data_o = {24'b0, reg_write_data_i[7:0]};
                        2'b01:ram_data_o = {16'b0, reg_write_data_i[15:0]};
                        2'b10:ram_data_o = {8'b0, reg_write_data_i[23:0]};
                        2'b11:ram_data_o = reg_write_data_i;
                    endcase
                end
                default: begin
                    reg_write_dest_o = reg_write_dest_i;
                    reg_write_en_o = reg_write_en_i;
                    reg_write_data_o = reg_write_data_i;
                    ram_length_o = 2'h0;
                    ram_r_en_o = `FALSE;
                    ram_w_en_o = `FALSE;
                    ram_addr_o = `ZERO_WORD;
                    ram_data_o = `ZERO_WORD;
                    mem_stall = `FALSE;
                end
            endcase
        end
    end

endmodule: mem