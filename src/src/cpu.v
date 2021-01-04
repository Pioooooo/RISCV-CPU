// RISCV32I CPU top module
// port modification allowed for debugging purposes

`include "consts.vh"

module cpu
    #(
        parameter DBG = 0
    )
    (
        input wire clk_in,
        input wire rst_in,
        input wire rdy_in,
        input wire [7:0] mem_din,
        output wire [7:0] mem_dout,
        output wire [31:0] mem_a,
        output wire mem_wr,
        input wire io_buffer_full,       // 1 if uart buffer is full
        output wire [31:0] dbgreg_dout
    );

    // implementation goes here

    // Specifications:
    // - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
    // - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
    // - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
    // - I/O port is mapped to address higher than 0x30000 (mem_a[17:16] == 2'b11)
    // - 0x30000 read: read a byte from input
    // - 0x30000 write: write a byte to output (write 0x00 is ignored)
    // - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
    // - 0x30004 write: indicates program stop (will output '\0' through uart tx)


    // stall
    wire if_stall, id_stall, mem_stall;
    wire [`StallBus]stall_stat;

    stall _stall(
        .rst(rst_in), .rdy(rdy_in),
        .if_stall(if_stall), .id_stall(id_stall), .mem_stall(mem_stall),
        .stall_stat(stall_stat)
    );

    // reg_file
    wire wb_reg_w_en, id_reg_r1_en, id_reg_r2_en;
    wire [`RegAddrLen-1:0] wb_reg_w_addr, id_reg_r1_addr, id_reg_r2_addr;
    wire [`RegLen-1:0] wb_reg_w_data, reg_id_r1_data, reg_id_r2_data;

    reg_file _reg_file(
        .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
        .w_en(wb_reg_w_en), .w_addr(wb_reg_w_addr), .w_data(wb_reg_w_data),
        .r1_en(id_reg_r1_en), .r1_addr(id_reg_r1_addr), .r1_data(reg_id_r1_data),
       . r2_en(id_reg_r2_en), .r2_addr(id_reg_r2_addr), .r2_data(reg_id_r2_data)
    );
    
    // id
    wire [`InstAddrBus] id_pc;
    // ex
    wire ex_is_branch, ex_ex_mem_reg_write_en;
    wire [`InstAddrBus] ex_branch_pc;
    // predictor
    wire [`InstAddrBus] pred_pc;
    // pc
    wire [`InstAddrBus] pc_pc;

    pc_reg _pc_reg(
        .clk(clk_in), .rst(rst_in), .rdy(rdy_in), .stall_stat(stall_stat),
        .pc(pc_pc), .next_pc(pred_pc),
        .ex_is_branch(ex_is_branch), .ex_branch_pc(ex_branch_pc), .id_pc(id_pc)
    );

    // ex
	wire ex_branch_en, ex_is_jalr;
	wire [`InstAddrBus] ex_pc;

    predictor _predictor(
        .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
        .pc(pc_pc), .next_pc(pred_pc),
        .ex_is_branch(ex_is_branch), .ex_is_jalr(ex_is_jalr), .ex_branch_en(ex_branch_en),
        .ex_pc(ex_pc), .ex_branch_pc(ex_branch_pc)
    );

    // mem_ctrl <---> mem
    wire mem_mem_ctrl_r_en, mem_mem_ctrl_w_en;
    wire [1:0] mem_mem_ctrl_ram_length;
    wire [`MemAddrBus] mem_mem_ctrl_ram_addr;
    wire [`RegBus] mem_mem_ctrl_ram_data;
    wire [`RegBus] mem_ctrl_mem_ram_data;
    wire mem_ctrl_mem_ram_rdy;
    // mem_ctrl <--> if
    wire if_mem_ctrl_inst_en;
    wire [`InstAddrBus] if_mem_ctrl_addr;
    wire [`InstBus] mem_ctrl_if_inst;
    wire mem_ctrl_if_inst_rdy;

    mem_ctrl _mem_ctrl(
        .clk(clk_in), .rst(rst_in), .rdy(rdy_in), .uart_full(io_buffer_full),
        .r_en_i(mem_mem_ctrl_r_en), .w_en_i(mem_mem_ctrl_w_en), .ram_length_i(mem_mem_ctrl_ram_length),
        .ram_addr_i(mem_mem_ctrl_ram_addr), .ram_data_i(mem_mem_ctrl_ram_data), .ram_data_o(mem_ctrl_mem_ram_data), .ram_rdy_o(mem_ctrl_mem_ram_rdy),
        .inst_en_i(if_mem_ctrl_inst_en), .pc_i(if_mem_ctrl_addr),
        .inst_o(mem_ctrl_if_inst), .inst_rdy_o(mem_ctrl_if_inst_rdy),
        .mem_din_i(mem_din), .mem_dout_o(mem_dout), .mem_addr_o(mem_a), .mem_w_en_o(mem_wr)
    );

    // if ----> if_id
    wire [`InstAddrBus] if_pc;
    wire [`InstBus] if_if_id_inst;

    IF _if(
        .clk(clk_in), .rst(rst_in), .rdy(rdy_in), .pc_i(pc_pc),
        .mem_en_o(if_mem_ctrl_inst_en), .mem_addr_o(if_mem_ctrl_addr),
        .mem_rdy_i(mem_ctrl_if_inst_rdy), .inst_i(mem_ctrl_if_inst),
        .pc_o(if_pc), .inst_o(if_if_id_inst), .if_stall(if_stall)
    );

    // if_id ----> id
    wire [`InstBus] if_id_id_inst;

    if_id _if_id(
        .clk(clk_in), .rst(rst_in), .rdy(rdy_in),
        .stall_stat(stall_stat), .ex_is_branch(ex_is_branch), .ex_branch_pc(ex_branch_pc),
        .if_pc(if_pc), .if_inst(if_if_id_inst),
        .id_pc(id_pc), .id_inst(if_id_id_inst)
    );

    // ex/mem ----> id
    wire ex_reg_write_en, mem_reg_write_en;
    wire [1:0] ex_mem_op;
    wire [`RegAddrBus] ex_reg_write_dest, mem_reg_write_dest;
    wire [`RegBus] ex_reg_write_data, mem_reg_write_data;
    // id ----> id_ex
    wire [`OpBus] id_id_ex_op;
    wire [`SelBus] id_id_ex_sel;
    wire [`RegBus] id_id_ex_reg1, id_id_ex_reg2;
    wire [`InstAddrBus] id_id_ex_pc, id_id_ex_offset;
    wire id_id_ex_reg_write_en;
    wire [`RegAddrBus] id_id_ex_reg_write_dest;

    id _id(
        .rst(rst_in), .rdy(rdy_in), .pc_i(id_pc), .inst_i(if_id_id_inst), .ex_mem_op(ex_mem_op),
        .ex_reg_write_en_i(ex_reg_write_en), .ex_reg_write_dest_i(ex_reg_write_dest), .ex_reg_write_data_i(ex_reg_write_data),
        .mem_reg_write_en_i(mem_reg_write_en), .mem_reg_write_dest_i(mem_reg_write_dest), .mem_reg_write_data_i(mem_reg_write_data),
        .reg1_read_en_o(id_reg_r1_en), .reg1_addr_o(id_reg_r1_addr), .reg1_data_i(reg_id_r1_data),
        .reg2_read_en_o(id_reg_r2_en), .reg2_addr_o(id_reg_r2_addr), .reg2_data_i(reg_id_r2_data),
        .op_o(id_id_ex_op), .sel_o(id_id_ex_sel), .reg1_o(id_id_ex_reg1), .reg2_o(id_id_ex_reg2), .pc_o(id_id_ex_pc), .offset_o(id_id_ex_offset),
        .reg_write_en_o(id_id_ex_reg_write_en), .reg_write_dest_o(id_id_ex_reg_write_dest), .id_stall(id_stall)
    );

    // id_ex ----> ex
    wire [`OpBus] id_ex_ex_op;
    wire [`SelBus] id_ex_ex_sel;
    wire [`RegBus] id_ex_ex_reg1, id_ex_ex_reg2;
    wire [`InstAddrBus] id_ex_ex_offset;
    wire id_ex_ex_reg_write_en;
    wire [`RegAddrBus] id_ex_ex_reg_write_dest;

    id_ex _id_ex(
        .clk(clk_in), .rst(rst_in), .rdy(rdy_in), .stall_stat(stall_stat),
        .ex_is_branch(ex_is_branch), .ex_branch_pc(ex_branch_pc),
        .id_op(id_id_ex_op), .id_sel(id_id_ex_sel), .id_reg1(id_id_ex_reg1), .id_reg2(id_id_ex_reg2),
        .id_reg_write_en(id_id_ex_reg_write_en), .id_reg_write_dest(id_id_ex_reg_write_dest), .id_pc(id_id_ex_pc), .id_offset(id_id_ex_offset),
        .ex_op(id_ex_ex_op), .ex_sel(id_ex_ex_sel), .ex_reg1(id_ex_ex_reg1), .ex_reg2(id_ex_ex_reg2),
        .ex_reg_write_en(id_ex_ex_reg_write_en), .ex_reg_write_dest(id_ex_ex_reg_write_dest), .ex_pc(ex_pc), .ex_offset(id_ex_ex_offset)
    );

    // ex ----> ex_mem
    wire [1:0] ex_ex_mem_mem_length;
    wire [`MemAddrBus] ex_ex_mem_mem_addr;

    ex #(
        .DBG(DBG)
    ) _ex(
        .rst(rst_in), .rdy(rdy_in),
        .op_i(id_ex_ex_op), .sel_i(id_ex_ex_sel), .reg1_i(id_ex_ex_reg1), .reg2_i(id_ex_ex_reg2), .reg_write_en_i(id_ex_ex_reg_write_en), .reg_write_dest_i(id_ex_ex_reg_write_dest), .pc_i(ex_pc), .offset_i(id_ex_ex_offset), .is_jalr_o(ex_is_jalr),
        .reg_write_dest_o(ex_reg_write_dest), .reg_write_en_o(ex_reg_write_en), .reg_write_data_o(ex_reg_write_data),
        .is_branch_o(ex_is_branch), .branch_en_o(ex_branch_en), .branch_pc_o(ex_branch_pc), .mem_op_o(ex_mem_op), .mem_length_o(ex_ex_mem_mem_length), .mem_addr_o(ex_ex_mem_mem_addr)
    );

    // ex_mem ----> mem
    wire ex_mem_mem_reg_write_en;
    wire [`RegAddrBus] ex_mem_mem_reg_write_dest;
    wire [`RegBus] ex_mem_mem_reg_write_data;
    wire [1:0] ex_mem_mem_mem_op, ex_mem_mem_mem_length;
    wire [`MemAddrBus] ex_mem_mem_mem_addr;

    ex_mem _ex_mem(
        .clk(clk_in), .rst(rst_in), .rdy(rdy_in), .stall_stat(stall_stat),
        .ex_reg_write_dest(ex_reg_write_dest), .ex_reg_write_en(ex_reg_write_en), .ex_reg_write_data(ex_reg_write_data),
        .ex_mem_op(ex_mem_op), .ex_mem_length(ex_ex_mem_mem_length), .ex_mem_addr(ex_ex_mem_mem_addr),
        .mem_reg_write_dest(ex_mem_mem_reg_write_dest), .mem_reg_write_en(ex_mem_mem_reg_write_en), .mem_reg_write_data(ex_mem_mem_reg_write_data),
        .mem_mem_op(ex_mem_mem_mem_op), .mem_mem_length(ex_mem_mem_mem_length), .mem_mem_addr(ex_mem_mem_mem_addr)
    );

    // mem

    mem _mem(
        .rst(rst_in), .rdy(rdy_in), .mem_stall(mem_stall),
        .reg_write_dest_i(ex_mem_mem_reg_write_dest), .reg_write_en_i(ex_mem_mem_reg_write_en), .reg_write_data_i(ex_mem_mem_reg_write_data),
        .mem_op_i(ex_mem_mem_mem_op), .mem_length_i(ex_mem_mem_mem_length), .mem_addr_i(ex_mem_mem_mem_addr),
        .reg_write_dest_o(mem_reg_write_dest), .reg_write_en_o(mem_reg_write_en), .reg_write_data_o(mem_reg_write_data),
        .ram_r_en_o(mem_mem_ctrl_r_en), .ram_w_en_o(mem_mem_ctrl_w_en), .ram_length_o(mem_mem_ctrl_ram_length), .ram_addr_o(mem_mem_ctrl_ram_addr),
        .ram_data_o(mem_mem_ctrl_ram_data), .ram_data_i(mem_ctrl_mem_ram_data), .ram_rdy_i(mem_ctrl_mem_ram_rdy)
    );

    // mem_wb

    mem_wb _mem_wb(
        .clk(clk_in), .rst(rst_in), .rdy(rdy_in), .stall_stat(stall_stat),
        .mem_reg_write_en(mem_reg_write_en), .mem_reg_write_dest(mem_reg_write_dest), .mem_reg_write_data(mem_reg_write_data),
        .wb_reg_write_en(wb_reg_w_en), .wb_reg_write_dest(wb_reg_w_addr), .wb_reg_write_data(wb_reg_w_data)
    );

    assign dbgreg_dout = DBG ? {mem_ctrl_if_inst_rdy, pc_pc[15:0]} : `ZERO_WORD;

endmodule: cpu
