module pipeline_instruction_memory (
    input  [31:0] addr,
    output [31:0] instruction
);

    reg [31:0] memory [0:31];

    initial begin
        // Stage 3 test program: no manual NOPs
        // Forwarding unit should handle data hazards.

        memory[0] = 32'h00500093; // ADDI x1, x0, 5
        memory[1] = 32'h00300113; // ADDI x2, x0, 3
        memory[2] = 32'h002081B3; // ADD  x3, x1, x2
        memory[3] = 32'h00302023; // SW   x3, 0(x0)
        memory[4] = 32'h00000063; // BEQ  x0, x0, 0

        memory[5]  = 32'h00000013; // NOP
        memory[6]  = 32'h00000013; // NOP
        memory[7]  = 32'h00000013; // NOP
        memory[8]  = 32'h00000013; // NOP
        memory[9]  = 32'h00000013; // NOP
        memory[10] = 32'h00000013; // NOP
        memory[11] = 32'h00000013; // NOP
        memory[12] = 32'h00000013; // NOP
        memory[13] = 32'h00000013; // NOP
        memory[14] = 32'h00000013; // NOP
        memory[15] = 32'h00000013; // NOP
        memory[16] = 32'h00000013; // NOP
        memory[17] = 32'h00000013; // NOP
        memory[18] = 32'h00000013; // NOP
        memory[19] = 32'h00000013; // NOP
        memory[20] = 32'h00000013; // NOP
        memory[21] = 32'h00000013; // NOP
        memory[22] = 32'h00000013; // NOP
        memory[23] = 32'h00000013; // NOP
        memory[24] = 32'h00000013; // NOP
        memory[25] = 32'h00000013; // NOP
        memory[26] = 32'h00000013; // NOP
        memory[27] = 32'h00000013; // NOP
        memory[28] = 32'h00000013; // NOP
        memory[29] = 32'h00000013; // NOP
        memory[30] = 32'h00000013; // NOP
        memory[31] = 32'h00000013; // NOP
    end

    assign instruction = memory[addr[6:2]];

endmodule