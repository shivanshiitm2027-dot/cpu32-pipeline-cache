module dcache (
    input         clk,
    input         rst,

    // CPU side
    input  [31:0] cpu_addr,
    input  [31:0] cpu_write_data,
    input         cpu_mem_read,
    input         cpu_mem_write,
    output reg [31:0] cpu_read_data,

    // Debug outputs
    output reg        cache_hit,
    output reg        cache_miss,

    // Memory side
    output reg [31:0] mem_addr,
    output reg [31:0] mem_write_data,
    output reg        mem_read,
    output reg        mem_write,
    input      [31:0] mem_read_data
);

    // Direct-mapped cache
    // 4 lines, each line stores one 32-bit word
    reg        valid [0:3];
    reg [27:0] tag   [0:3];
    reg [31:0] data  [0:3];

    wire [1:0] index;
    wire [27:0] current_tag;

    assign index = cpu_addr[3:2];
    assign current_tag = cpu_addr[31:4];

    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 4; i = i + 1) begin
                valid[i] <= 1'b0;
                tag[i]   <= 28'd0;
                data[i]  <= 32'd0;
            end

            cpu_read_data <= 32'd0;
            cache_hit     <= 1'b0;
            cache_miss    <= 1'b0;

            mem_addr       <= 32'd0;
            mem_write_data <= 32'd0;
            mem_read       <= 1'b0;
            mem_write      <= 1'b0;
        end else begin
            cache_hit  <= 1'b0;
            cache_miss <= 1'b0;
            mem_read   <= 1'b0;
            mem_write  <= 1'b0;

            // Cache read
            if (cpu_mem_read) begin
                if (valid[index] && tag[index] == current_tag) begin
                    // Cache hit
                    cpu_read_data <= data[index];
                    cache_hit <= 1'b1;
                end else begin
                    // Cache miss
                    mem_addr <= cpu_addr;
                    mem_read <= 1'b1;

                    // For this simple model, capture memory data on same cycle path
                    data[index]  <= mem_read_data;
                    tag[index]   <= current_tag;
                    valid[index] <= 1'b1;

                    cpu_read_data <= mem_read_data;
                    cache_miss <= 1'b1;
                end
            end

            // Cache write: write-through policy
            if (cpu_mem_write) begin
                data[index]  <= cpu_write_data;
                tag[index]   <= current_tag;
                valid[index] <= 1'b1;

                mem_addr       <= cpu_addr;
                mem_write_data <= cpu_write_data;
                mem_write      <= 1'b1;

                cache_hit <= 1'b1;
            end
        end
    end

endmodule