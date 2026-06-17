module bram_data_memory (
    input         clk,
    input         rst,

    input  [31:0] addr,
    input  [31:0] write_data,
    input         mem_read,
    input         mem_write,

    output reg [31:0] read_data
);

    reg [31:0] memory [0:31];
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                memory[i] <= 32'd0;
            end
            read_data <= 32'd0;
        end else begin
            if (mem_write) begin
                memory[addr[6:2]] <= write_data;
            end

            if (mem_read) begin
                read_data <= memory[addr[6:2]];
            end else begin
                read_data <= 32'd0;
            end
        end
    end

endmodule