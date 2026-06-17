module bram_instruction_memory (
    input         clk,
    input  [31:0] addr,
    output reg [31:0] instruction
);

    reg [31:0] memory [0:31];

    initial begin
        // Stage 4 BRAM-style instruction memory
        // Program without manual NOPs, forwarding handles hazards

        memory[0] = 32'h00500093; // ADDI x1, x0, 5
        memory[1] = 32'h00300113; // ADDI x2, x0, 3
        memory[2] = 32'h002081B3; // ADD  x3, x1, x2
        memory[3] = 32'h00302023; // SW   x3, 0(x0)
        memory[4] = 32'h00000063; // BEQ  x0, x0, 0

        memory[5]  = 32'h00000013;
        memory[6]  = 32'h00000013;
        memory[7]  = 32'h00000013;
        memory[8]  = 32'h00000013;
        memory[9]  = 32'h00000013;
        memory[10] = 32'h00000013;
        memory[11] = 32'h00000013;
        memory[12] = 32'h00000013;
        memory[13] = 32'h00000013;
        memory[14] = 32'h00000013;
        memory[15] = 32'h00000013;
        memory[16] = 32'h00000013;
        memory[17] = 32'h00000013;
        memory[18] = 32'h00000013;
        memory[19] = 32'h00000013;
        memory[20] = 32'h00000013;
        memory[21] = 32'h00000013;
        memory[22] = 32'h00000013;
        memory[23] = 32'h00000013;
        memory[24] = 32'h00000013;
        memory[25] = 32'h00000013;
        memory[26] = 32'h00000013;
        memory[27] = 32'h00000013;
        memory[28] = 32'h00000013;
        memory[29] = 32'h00000013;
        memory[30] = 32'h00000013;
        memory[31] = 32'h00000013;
    end

    // Synchronous read: BRAM-style
    always @(posedge clk) begin
        instruction <= memory[addr[6:2]];
    end

endmodule