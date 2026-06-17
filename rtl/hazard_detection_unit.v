module hazard_detection_unit (
    input        id_ex_mem_read,
    input [4:0] id_ex_rd,

    input [4:0] if_id_rs1,
    input [4:0] if_id_rs2,

    output reg pc_write,
    output reg if_id_write,
    output reg control_stall
);

    always @(*) begin
        // Default: no stall
        pc_write      = 1'b1;
        if_id_write   = 1'b1;
        control_stall = 1'b0;

        // Load-use hazard:
        // Example:
        // LW  x1, 0(x0)
        // ADD x2, x1, x3
        //
        // ADD needs x1 immediately, but LW data is not ready yet.
        if (id_ex_mem_read &&
            (id_ex_rd != 5'd0) &&
            ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2))) begin

            pc_write      = 1'b0;  // freeze PC
            if_id_write   = 1'b0;  // freeze IF/ID register
            control_stall = 1'b1;  // insert bubble into ID/EX
        end
    end

endmodule