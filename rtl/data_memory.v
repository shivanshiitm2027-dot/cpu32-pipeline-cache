module data_memory (
    input         clk,
    input         rst,

    input  [31:0] addr,
    input  [31:0] write_data,
    input         mem_read,
    input         mem_write,

    output [31:0] read_data
);

    reg [31:0] memory [0:15];
    integer i;

    // Read memory
    assign read_data = (mem_read) ? memory[addr[5:2]] : 32'd0;

    // Write memory
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 16; i = i + 1) begin
                memory[i] <= 32'd0;
            end
        end else begin
            if (mem_write) begin
                memory[addr[5:2]] <= write_data;
            end
        end
    end

endmodule