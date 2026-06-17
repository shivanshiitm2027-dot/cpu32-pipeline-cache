module fpga_top (
    input clk,
    input rst,
    output [7:0] result_led
);

    wire [31:0] pc_out;
    wire [31:0] if_id_instruction_out;
    wire [31:0] ex_alu_result_out;
    wire [31:0] mem0_out;

    pipeline_cpu_top cpu_inst (
        .clk(clk),
        .rst(rst),
        .pc_out(pc_out),
        .if_id_instruction_out(if_id_instruction_out),
        .ex_alu_result_out(ex_alu_result_out),
        .mem0_out(mem0_out)
    );

    // Show final memory result on 8 output pins
    assign result_led = mem0_out[7:0];

endmodule