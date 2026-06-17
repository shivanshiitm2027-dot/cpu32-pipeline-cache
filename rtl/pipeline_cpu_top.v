module pipeline_cpu_top (
    input clk,
    input rst,

    output [31:0] pc_out,
    output [31:0] if_id_instruction_out,
    output [31:0] ex_alu_result_out,
    output [31:0] mem0_out
);

    // =====================================================
    // IF STAGE
    // =====================================================
    reg [31:0] pc;

    wire [31:0] if_instruction;
    wire [31:0] pc_plus_4;

    assign pc_plus_4 = pc + 32'd4;

    bram_instruction_memory imem (
        .clk(clk),
        .addr(pc),
        .instruction(if_instruction)
    );

    // =====================================================
    // IF/ID PIPELINE REGISTER
    // =====================================================
    reg [31:0] if_id_pc;
    reg [31:0] if_id_instruction;

    // =====================================================
    // ID STAGE
    // =====================================================
    wire [6:0] id_opcode;
    wire [4:0] id_rd;
    wire [2:0] id_funct3;
    wire [4:0] id_rs1;
    wire [4:0] id_rs2;
    wire [6:0] id_funct7;

    assign id_opcode = if_id_instruction[6:0];
    assign id_rd     = if_id_instruction[11:7];
    assign id_funct3 = if_id_instruction[14:12];
    assign id_rs1    = if_id_instruction[19:15];
    assign id_rs2    = if_id_instruction[24:20];
    assign id_funct7 = if_id_instruction[31:25];

    wire [31:0] id_imm_i;
    wire [31:0] id_imm_s;
    wire [31:0] id_imm_b;
    wire [31:0] id_imm;

    assign id_imm_i = {{20{if_id_instruction[31]}}, if_id_instruction[31:20]};
    assign id_imm_s = {{20{if_id_instruction[31]}}, if_id_instruction[31:25], if_id_instruction[11:7]};
    assign id_imm_b = {{19{if_id_instruction[31]}}, if_id_instruction[31],
                       if_id_instruction[7], if_id_instruction[30:25],
                       if_id_instruction[11:8], 1'b0};

    assign id_imm = (id_opcode == 7'b0100011) ? id_imm_s :
                    (id_opcode == 7'b1100011) ? id_imm_b :
                                                  id_imm_i;

    wire id_reg_write;
    wire id_mem_read;
    wire id_mem_write;
    wire id_alu_src;
    wire id_mem_to_reg;
    wire id_branch;
    wire [2:0] id_alu_ctrl;

    control_unit cu (
        .opcode(id_opcode),
        .funct3(id_funct3),
        .funct7(id_funct7),
        .reg_write(id_reg_write),
        .mem_read(id_mem_read),
        .mem_write(id_mem_write),
        .alu_src(id_alu_src),
        .mem_to_reg(id_mem_to_reg),
        .branch(id_branch),
        .alu_ctrl(id_alu_ctrl)
    );

    wire [31:0] id_read_data1;
    wire [31:0] id_read_data2;

    wire [4:0]  wb_rd;
    wire [31:0] wb_write_data;
    wire        wb_reg_write;

    register_file rf (
        .clk(clk),
        .rst(rst),
        .rs1(id_rs1),
        .rs2(id_rs2),
        .rd(wb_rd),
        .write_data(wb_write_data),
        .reg_write(wb_reg_write),
        .read_data1(id_read_data1),
        .read_data2(id_read_data2)
    );

    // =====================================================
    // HAZARD DETECTION UNIT
    // =====================================================
    wire pc_write;
    wire if_id_write;
    wire control_stall;

    hazard_detection_unit hdu (
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_rd(id_ex_rd),
        .if_id_rs1(id_rs1),
        .if_id_rs2(id_rs2),
        .pc_write(pc_write),
        .if_id_write(if_id_write),
        .control_stall(control_stall)
    );

    // =====================================================
    // ID/EX PIPELINE REGISTER
    // =====================================================
    reg [31:0] id_ex_pc;
    reg [31:0] id_ex_read_data1;
    reg [31:0] id_ex_read_data2;
    reg [31:0] id_ex_imm;

    reg [4:0]  id_ex_rs1;
    reg [4:0]  id_ex_rs2;
    reg [4:0]  id_ex_rd;

    reg        id_ex_reg_write;
    reg        id_ex_mem_read;
    reg        id_ex_mem_write;
    reg        id_ex_alu_src;
    reg        id_ex_mem_to_reg;
    reg        id_ex_branch;
    reg [2:0]  id_ex_alu_ctrl;

    // =====================================================
    // FORWARDING UNIT
    // =====================================================
    wire [1:0] forward_a;
    wire [1:0] forward_b;

    forwarding_unit fu (
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_rd(mem_wb_rd),
        .mem_wb_reg_write(mem_wb_reg_write),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    // =====================================================
    // EX STAGE
    // =====================================================
    wire [31:0] forward_data_a;
    wire [31:0] forward_data_b;
    wire [31:0] ex_alu_b;
    wire [31:0] ex_alu_result;
    wire        ex_zero;
    wire [31:0] ex_branch_target;

    assign forward_data_a = (forward_a == 2'b10) ? ex_mem_alu_result :
                            (forward_a == 2'b01) ? wb_write_data :
                                                    id_ex_read_data1;

    assign forward_data_b = (forward_b == 2'b10) ? ex_mem_alu_result :
                            (forward_b == 2'b01) ? wb_write_data :
                                                    id_ex_read_data2;

    assign ex_alu_b = id_ex_alu_src ? id_ex_imm : forward_data_b;
    assign ex_branch_target = id_ex_pc + id_ex_imm;

    alu alu_inst (
        .a(forward_data_a),
        .b(ex_alu_b),
        .alu_ctrl(id_ex_alu_ctrl),
        .result(ex_alu_result),
        .zero(ex_zero)
    );

    // =====================================================
    // EX/MEM PIPELINE REGISTER
    // =====================================================
    reg [31:0] ex_mem_branch_target;
    reg [31:0] ex_mem_alu_result;
    reg [31:0] ex_mem_write_data;
    reg [4:0]  ex_mem_rd;
    reg        ex_mem_zero;

    reg        ex_mem_reg_write;
    reg        ex_mem_mem_read;
    reg        ex_mem_mem_write;
    reg        ex_mem_mem_to_reg;
    reg        ex_mem_branch;

    // =====================================================
    // MEM STAGE WITH D-CACHE
    // =====================================================
    wire [31:0] cache_read_data;
    wire        cache_hit;
    wire        cache_miss;

    wire [31:0] cache_mem_addr;
    wire [31:0] cache_mem_write_data;
    wire        cache_mem_read;
    wire        cache_mem_write;
    wire [31:0] main_mem_read_data;

    wire        mem_branch_taken;

    assign mem_branch_taken = ex_mem_branch && ex_mem_zero;

    dcache dcache_inst (
        .clk(clk),
        .rst(rst),

        .cpu_addr(ex_mem_alu_result),
        .cpu_write_data(ex_mem_write_data),
        .cpu_mem_read(ex_mem_mem_read),
        .cpu_mem_write(ex_mem_mem_write),
        .cpu_read_data(cache_read_data),

        .cache_hit(cache_hit),
        .cache_miss(cache_miss),

        .mem_addr(cache_mem_addr),
        .mem_write_data(cache_mem_write_data),
        .mem_read(cache_mem_read),
        .mem_write(cache_mem_write),
        .mem_read_data(main_mem_read_data)
    );

    bram_data_memory dmem (
        .clk(clk),
        .rst(rst),
        .addr(cache_mem_addr),
        .write_data(cache_mem_write_data),
        .mem_read(cache_mem_read),
        .mem_write(cache_mem_write),
        .read_data(main_mem_read_data)
    );

    // =====================================================
    // MEM/WB PIPELINE REGISTER
    // =====================================================
    reg [31:0] mem_wb_read_data;
    reg [31:0] mem_wb_alu_result;
    reg [4:0]  mem_wb_rd;

    reg        mem_wb_reg_write;
    reg        mem_wb_mem_to_reg;

    // =====================================================
    // WB STAGE
    // =====================================================
    assign wb_write_data = mem_wb_mem_to_reg ? mem_wb_read_data : mem_wb_alu_result;
    assign wb_rd         = mem_wb_rd;
    assign wb_reg_write  = mem_wb_reg_write;

    // =====================================================
    // PIPELINE REGISTER UPDATE
    // =====================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 32'd0;

            if_id_pc <= 32'd0;
            if_id_instruction <= 32'h00000013;

            id_ex_pc <= 32'd0;
            id_ex_read_data1 <= 32'd0;
            id_ex_read_data2 <= 32'd0;
            id_ex_imm <= 32'd0;
            id_ex_rs1 <= 5'd0;
            id_ex_rs2 <= 5'd0;
            id_ex_rd <= 5'd0;

            id_ex_reg_write <= 1'b0;
            id_ex_mem_read <= 1'b0;
            id_ex_mem_write <= 1'b0;
            id_ex_alu_src <= 1'b0;
            id_ex_mem_to_reg <= 1'b0;
            id_ex_branch <= 1'b0;
            id_ex_alu_ctrl <= 3'b000;

            ex_mem_branch_target <= 32'd0;
            ex_mem_alu_result <= 32'd0;
            ex_mem_write_data <= 32'd0;
            ex_mem_rd <= 5'd0;
            ex_mem_zero <= 1'b0;

            ex_mem_reg_write <= 1'b0;
            ex_mem_mem_read <= 1'b0;
            ex_mem_mem_write <= 1'b0;
            ex_mem_mem_to_reg <= 1'b0;
            ex_mem_branch <= 1'b0;

            mem_wb_read_data <= 32'd0;
            mem_wb_alu_result <= 32'd0;
            mem_wb_rd <= 5'd0;
            mem_wb_reg_write <= 1'b0;
            mem_wb_mem_to_reg <= 1'b0;
        end else begin

            // PC update
            if (pc_write) begin
                if (mem_branch_taken)
                    pc <= ex_mem_branch_target;
                else
                    pc <= pc_plus_4;
            end

            // IF/ID update
            if (if_id_write) begin
                if_id_pc <= pc;
                if_id_instruction <= if_instruction;
            end

            // ID/EX update
            id_ex_pc <= if_id_pc;
            id_ex_read_data1 <= id_read_data1;
            id_ex_read_data2 <= id_read_data2;
            id_ex_imm <= id_imm;
            id_ex_rs1 <= id_rs1;
            id_ex_rs2 <= id_rs2;
            id_ex_rd <= id_rd;

            if (control_stall) begin
                id_ex_reg_write <= 1'b0;
                id_ex_mem_read <= 1'b0;
                id_ex_mem_write <= 1'b0;
                id_ex_alu_src <= 1'b0;
                id_ex_mem_to_reg <= 1'b0;
                id_ex_branch <= 1'b0;
                id_ex_alu_ctrl <= 3'b000;
            end else begin
                id_ex_reg_write <= id_reg_write;
                id_ex_mem_read <= id_mem_read;
                id_ex_mem_write <= id_mem_write;
                id_ex_alu_src <= id_alu_src;
                id_ex_mem_to_reg <= id_mem_to_reg;
                id_ex_branch <= id_branch;
                id_ex_alu_ctrl <= id_alu_ctrl;
            end

            // EX/MEM update
            ex_mem_branch_target <= ex_branch_target;
            ex_mem_alu_result <= ex_alu_result;
            ex_mem_write_data <= forward_data_b;
            ex_mem_rd <= id_ex_rd;
            ex_mem_zero <= ex_zero;

            ex_mem_reg_write <= id_ex_reg_write;
            ex_mem_mem_read <= id_ex_mem_read;
            ex_mem_mem_write <= id_ex_mem_write;
            ex_mem_mem_to_reg <= id_ex_mem_to_reg;
            ex_mem_branch <= id_ex_branch;

            // MEM/WB update
            mem_wb_read_data <= cache_read_data;
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_rd <= ex_mem_rd;

            mem_wb_reg_write <= ex_mem_reg_write;
            mem_wb_mem_to_reg <= ex_mem_mem_to_reg;
        end
    end

    // =====================================================
    // DEBUG OUTPUTS
    // =====================================================
    assign pc_out = pc;
    assign if_id_instruction_out = if_id_instruction;
    assign ex_alu_result_out = ex_alu_result;

    // Main memory address 0 result
    assign mem0_out = dmem.memory[0];

endmodule