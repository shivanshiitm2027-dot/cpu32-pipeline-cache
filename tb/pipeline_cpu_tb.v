`timescale 1ns/1ps

module pipeline_cpu_tb;

    reg clk;
    reg rst;

    wire [31:0] pc_out;
    wire [31:0] if_id_instruction_out;
    wire [31:0] ex_alu_result_out;
    wire [31:0] mem0_out;

    // DUT: 5-stage pipelined CPU
    pipeline_cpu_top dut (
        .clk(clk),
        .rst(rst),
        .pc_out(pc_out),
        .if_id_instruction_out(if_id_instruction_out),
        .ex_alu_result_out(ex_alu_result_out),
        .mem0_out(mem0_out)
    );

    // 100 MHz clock
    // Period = 10 ns
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        rst = 1;

        #20;
        rst = 0;

        // Pipeline needs more cycles because instructions pass through IF-ID-EX-MEM-WB
        #400;

        $display("=========================================");
        $display("5-Stage Pipeline CPU Simulation Complete");
        $display("PC                  = %h", pc_out);
        $display("IF/ID Instruction   = %h", if_id_instruction_out);
        $display("EX ALU Result       = %d", ex_alu_result_out);
        $display("Data Memory[0]      = %d", mem0_out);
        $display("Expected Result     = 8");
        $display("=========================================");

        if (mem0_out == 32'd8) begin
            $display("PASS: Pipeline CPU stored correct result in memory[0]");
        end else begin
            $display("FAIL: Pipeline CPU result is wrong");
        end

        $finish;
    end

    // Waveform dump
    initial begin
        $dumpfile("sim/pipeline_cpu_wave.vcd");
        $dumpvars(0, pipeline_cpu_tb);
    end

endmodule