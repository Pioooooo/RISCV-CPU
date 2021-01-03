`include "consts.vh"

module stall
    (
        input wire rst, rdy,
        input wire if_stall, id_stall, mem_stall,

        output reg [`StallBus] stall_stat
    );

    always @(*) begin
        if (rst)
            stall_stat = `NO_STALL;
        else if (!rdy)
            stall_stat = `ALL_STALL;
        else if (mem_stall)
            stall_stat = `MEM_STALL;
        else if (id_stall)
            stall_stat = `ID_STALL;
        else if (if_stall)
            stall_stat = `IF_STALL;
        else
            stall_stat = `NO_STALL;
    end

endmodule: stall