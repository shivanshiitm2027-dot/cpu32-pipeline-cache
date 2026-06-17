module control_unit (
    input  [6:0] opcode,
    input  [2:0] funct3,
    input  [6:0] funct7,

    output reg       reg_write,
    output reg       mem_read,
    output reg       mem_write,
    output reg       alu_src,
    output reg       mem_to_reg,
    output reg       branch,
    output reg [2:0] alu_ctrl
);

    always @(*) begin
        // Default values
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        alu_src    = 1'b0;
        mem_to_reg = 1'b0;
        branch     = 1'b0;
        alu_ctrl   = 3'b000;

        case (opcode)

            7'b0010011: begin
                // ADDI instruction
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_to_reg = 1'b0;
                alu_ctrl   = 3'b000;   // ADD
            end

            7'b0110011: begin
                // R-type instructions
                reg_write  = 1'b1;
                alu_src    = 1'b0;
                mem_to_reg = 1'b0;

                case ({funct7, funct3})
                    {7'b0000000, 3'b000}: alu_ctrl = 3'b000; // ADD
                    {7'b0100000, 3'b000}: alu_ctrl = 3'b001; // SUB
                    {7'b0000000, 3'b111}: alu_ctrl = 3'b010; // AND
                    {7'b0000000, 3'b110}: alu_ctrl = 3'b011; // OR
                    {7'b0000000, 3'b100}: alu_ctrl = 3'b100; // XOR
                    default:              alu_ctrl = 3'b000;
                endcase
            end

            7'b0000011: begin
                // LW instruction
                reg_write  = 1'b1;
                mem_read   = 1'b1;
                alu_src    = 1'b1;
                mem_to_reg = 1'b1;
                alu_ctrl   = 3'b000;   // address = base + offset
            end

            7'b0100011: begin
                // SW instruction
                mem_write  = 1'b1;
                alu_src    = 1'b1;
                alu_ctrl   = 3'b000;   // address = base + offset
            end

            7'b1100011: begin
                // BEQ instruction
                branch     = 1'b1;
                alu_src    = 1'b0;
                alu_ctrl   = 3'b001;   // SUB for comparison
            end

            default: begin
                // NOP / unknown instruction
                reg_write  = 1'b0;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                alu_src    = 1'b0;
                mem_to_reg = 1'b0;
                branch     = 1'b0;
                alu_ctrl   = 3'b000;
            end
        endcase
    end

endmodule