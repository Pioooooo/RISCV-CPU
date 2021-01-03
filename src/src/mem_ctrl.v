`include "consts.vh"

module mem_ctrl
    (
        input wire clk, rst, rdy, uart_full,

        input wire r_en_i, w_en_i,
        input wire [1:0] ram_length_i,
        input wire [`MemAddrBus] ram_addr_i,
        input wire [`RegBus] ram_data_i,

        output reg [`RegBus] ram_data_o,
        output reg ram_rdy_o,

        input wire inst_en_i,
        input wire [`InstAddrBus] pc_i,
        output reg [`InstBus] inst_o,
        output reg inst_rdy_o,

        input wire [`MemBus] mem_din_i,
        output reg [`MemBus] mem_dout_o,
        output reg [`MemAddrBus] mem_addr_o,
        output reg mem_w_en_o
    );

    reg rw_stat, data_type, busy, uart;
    reg [2:0] stage;
    reg [`MemAddrBus] ram_addr;
    reg [23:0] ram_data;

    always @(posedge clk) begin
        if (rst) begin
            stage <= 3'b0;
            ram_addr <= `ZERO_WORD;
            ram_data <= 24'b0;
            busy <= `FALSE;
            uart <= `FALSE;
            rw_stat <= 1'b0;
            data_type <= 1'b0;
            ram_rdy_o <= `FALSE;
            inst_rdy_o <= `FALSE;
            ram_data_o <= `ZERO_WORD;
            inst_o <= `ZERO_WORD;
            mem_w_en_o <= `FALSE;
            mem_addr_o <= `ZERO_WORD;
            mem_dout_o <= 8'b0;
        end else if(rdy) begin
            if (busy) begin
                if (rw_stat == `MEM_STAT_READ) begin // reading
                    if (data_type == `MEM_STAT_INST && ram_addr != pc_i) begin
                        if (inst_en_i) begin
                            inst_rdy_o <= `FALSE;
                            inst_o <= `ZERO_WORD;
                            ram_addr <= pc_i;
                            stage <= 3'h4;
                            mem_w_en_o <= `FALSE;
                            mem_addr_o <= pc_i + 3;
                        end else begin
                            stage <= 3'b0;
                            ram_addr <= `ZERO_WORD;
                            ram_data <= 24'b0;
                            busy <= `FALSE;
                            uart <= `FALSE;
                            rw_stat <= 1'b0;
                            data_type <= 1'b0;
                            ram_rdy_o <= `FALSE;
                            inst_rdy_o <= `FALSE;
                            ram_data_o <= `ZERO_WORD;
                            inst_o <= `ZERO_WORD;
                            mem_w_en_o <= `FALSE;
                            mem_addr_o <= `ZERO_WORD;
                            mem_dout_o <= 8'b0;
                        end
                    end else begin
                        case (stage)
                            3'h4: begin
                                mem_addr_o <= ram_addr + 2;
                                mem_w_en_o <= `FALSE;
                                stage <= 3'h3;
                                ram_rdy_o <= `FALSE;
                                inst_rdy_o <= `FALSE;
                            end
                            3'h3: begin
                                ram_data[23:16] <= mem_din_i;
                                mem_addr_o <= ram_addr + 1;
                                mem_w_en_o <= `FALSE;
                                stage <= 3'h2;
                                ram_rdy_o <= `FALSE;
                                inst_rdy_o <= `FALSE;
                            end
                            3'h2: begin
                                ram_data[15:8] <= mem_din_i;
                                mem_addr_o <= ram_addr;
                                mem_w_en_o <= `FALSE;
                                stage <= 3'h1;
                                ram_rdy_o <= `FALSE;
                                inst_rdy_o <= `FALSE;
                            end
                            3'h1: begin
                                ram_data[7:0] <= mem_din_i;
                                mem_addr_o <= `ZERO_WORD;
                                mem_w_en_o <= `FALSE;
                                stage <= 3'h0;
                                ram_rdy_o <= `FALSE;
                                inst_rdy_o <= `FALSE;
                            end
                            3'h0: begin
                                busy <= `FALSE;
                                if (data_type == `MEM_STAT_RAM) begin
                                    ram_data_o <= {ram_data, mem_din_i};
                                    ram_rdy_o <= `TRUE;
                                    inst_rdy_o <= `FALSE;
                                end else begin
                                    inst_o <= {ram_data, mem_din_i};
                                    ram_rdy_o <= `FALSE;
                                    inst_rdy_o <= `TRUE;
                                end
                                ram_data <= 24'b0;
                            end
                        endcase
                    end
                end else begin // writing
                    if (uart) begin
                        if (stage != 0) begin
                            mem_addr_o <= `ZERO_WORD;
                            mem_dout_o <= 8'b0;
                            mem_w_en_o <= `FALSE;
                            stage <= stage - 1;
                            ram_rdy_o <= `FALSE;
                            inst_rdy_o <= `FALSE;
                        end else begin
                            if (uart_full) begin
                                mem_addr_o <= `ZERO_WORD;
                                mem_dout_o <= 8'b0;
                                mem_w_en_o <= `FALSE;
                                stage <= 3'h0;
                                ram_rdy_o <= `FALSE;
                                inst_rdy_o <= `FALSE;
                            end else begin
                                mem_addr_o <= ram_addr;
                                mem_dout_o <= ram_data[7:0];
                                mem_w_en_o <= `TRUE;
                                stage <= 3'h0;
                                busy <= `FALSE;
                                uart <= `FALSE;
                                ram_rdy_o <= `TRUE;
                                inst_rdy_o <= `FALSE;
                                ram_data <= 24'b0;
                            end
                        end
                    end else begin
                        case (stage)
                            3'h3: begin
                                mem_addr_o <= ram_addr + 2;
                                mem_dout_o <= ram_data[23:16];
                                mem_w_en_o <= `TRUE;
                                stage <= 3'h2;
                                ram_rdy_o <= `FALSE;
                                inst_rdy_o <= `FALSE;
                            end
                            3'h2: begin
                                mem_addr_o <= ram_addr + 1;
                                mem_dout_o <= ram_data[15:8];
                                mem_w_en_o <= `TRUE;
                                stage <= 3'h1;
                                ram_rdy_o <= `FALSE;
                                inst_rdy_o <= `FALSE;
                            end
                            3'h1: begin
                                mem_addr_o <= ram_addr;
                                mem_dout_o <= ram_data[7:0];
                                mem_w_en_o <= `TRUE;
                                stage <= 3'h0;
                                busy <= `FALSE;
                                ram_rdy_o <= `TRUE;
                                inst_rdy_o <= `FALSE;
                                ram_data <= 24'b0;
                            end
                        endcase
                    end
                end
            end else begin // idle
                if (r_en_i) begin
                    ram_addr <= ram_addr_i;
                    stage <= 3'h1 + {1'b0, ram_length_i};
                    busy <= `TRUE;
                    uart <= `FALSE;
                    rw_stat <= `MEM_STAT_READ;
                    data_type <= `MEM_STAT_RAM;
                    mem_addr_o <= ram_addr_i + ram_length_i;
                    mem_w_en_o <= `FALSE;
                    ram_rdy_o <= `FALSE;
                    inst_rdy_o <= `FALSE;
                end else if (w_en_i) begin
                    ram_addr <= ram_addr_i;
                    ram_data <= ram_data_i[23:0];
                    rw_stat <= `MEM_STAT_WRITE;
                    data_type <= `MEM_STAT_RAM;
                    inst_rdy_o <= `FALSE;
                    if (ram_addr_i >= 32'h30000) begin
                        mem_w_en_o <= `FALSE;
                        uart <= `TRUE;
                        stage <= 3'h2;
                        mem_addr_o <= ram_addr_i + ram_length_i;
                        mem_dout_o <= 8'b0;
                        busy <= `TRUE;
                        ram_rdy_o <= `FALSE;
                    end else begin
                        mem_w_en_o <= `TRUE;
                        uart <= `FALSE;
                        stage <= {1'b0, ram_length_i};
                        mem_addr_o <= ram_addr_i + ram_length_i;
                        busy <= (ram_length_i != 2'h0);
                        ram_rdy_o <= (ram_length_i == 2'h0);
                        case (ram_length_i)
                            2'h3: begin
                                mem_dout_o <= ram_data_i[31:24];
                            end
                            2'h1: begin
                                mem_dout_o <= ram_data_i[15:8];
                            end
                            2'h0: begin
                                mem_dout_o <= ram_data_i[7:0];
                            end
                        endcase
                        end
                end else if (inst_en_i) begin
                    ram_addr <= pc_i;
                    stage <= 3'h4;
                    busy <= `TRUE;
                    uart <= `FALSE;
                    rw_stat <= `MEM_STAT_READ;
                    data_type <= `MEM_STAT_INST;
                    mem_addr_o <= pc_i + 3;
                    mem_w_en_o <= `FALSE;
                    ram_rdy_o <= `FALSE;
                    inst_rdy_o <= `FALSE;
                end else begin
                    ram_addr <= `ZERO_WORD;
                    ram_data <= 24'b0;
                    stage <= 3'h0;
                    busy <= `FALSE;
                    uart <= `FALSE;
                    mem_w_en_o <= `FALSE;
                    mem_addr_o <= `ZERO_WORD;
                    mem_dout_o <= 8'b0;
                    ram_rdy_o <= `FALSE;
                    inst_rdy_o <= `FALSE;
                end
            end
        end
    end

endmodule: mem_ctrl