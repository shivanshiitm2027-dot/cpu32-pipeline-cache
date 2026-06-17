module forwarding_unit (
    input [4:0] id_ex_rs1,
    input [4:0] id_ex_rs2,

    input [4:0] ex_mem_rd,
    input       ex_mem_reg_write,

    input [4:0] mem_wb_rd,
    input       mem_wb_reg_write,

    output reg [1:0] forward_a,
    output reg [1:0] forward_b
);

    always @(*) begin
        // Default: no forwarding
        forward_a = 2'b00;
        forward_b = 2'b00;

        // EX hazard: forward from EX/MEM stage
        if (ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs1)) begin
            forward_a = 2'b10;
        end

        if (ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs2)) begin
            forward_b = 2'b10;
        end

        // MEM hazard: forward from MEM/WB stage
        if (mem_wb_reg_write && (mem_wb_rd != 5'd0) &&
            !(ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs1)) &&
            (mem_wb_rd == id_ex_rs1)) begin
            forward_a = 2'b01;
        end

        if (mem_wb_reg_write && (mem_wb_rd != 5'd0) &&
            !(ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs2)) &&
            (mem_wb_rd == id_ex_rs2)) begin
            forward_b = 2'b01;
        end
    end

endmodule