`timescale 1ns/1ps

// =================================================================
// Module Name: top
// Description: NTHU Logical Design Project - Part 2
//              Processes a stream of data through the Part 1 ALU,
//              maintains a sorted array of the top-K largest values,
//              and outputs the K-th largest value when done.
//              Optimized with 'reg_count' to latch the dynamic 'count'
//              input when 'start' is asserted.
// =================================================================

module top #(parameter K = 3) (
    input  wire       clk,         // System clock
    input  wire       rst_n,       // Active-low asynchronous reset
    input  wire       start,       // Start signal (active-high pulse)
    input  wire       valid,       // Input data valid indicator
    input  wire [7:0] data_A,      // Input operand A for ALU
    input  wire [7:0] data_B,      // Input operand B for ALU
    input  wire [3:0] instruction, // ALU instruction control code
    input  wire [7:0] count,       // Total data items to process (valid on start pulse only)
    output reg  [7:0] kth_largest, // Output: The K-th largest value
    output reg        finish       // Output: Completed indicator (active-high pulse for 1 cycle)
);
    // TODO: write your design below
    // =================================================================
    // 1. FSM State Definitions
    // =================================================================
    localparam IDLE = 2'b00; // Waiting for start pulse and initializing registers
    localparam PROC = 2'b01; // Processing and sorting data on-the-fly
    localparam DONE = 2'b10; // Outputting result and raising finish pulse
    
    reg [1:0] state;
    reg [1:0] next_state;
    reg [7:0] input_count;   // Counter for processed valid data items
    reg [7:0] top_k [0:K-1]; // Sorted array storing top-K largest values (descending)
    reg [7:0] reg_count;     // Latch register to store 'count' value at start assertion

    // =================================================================
    // 2. ALU Instantiation (Combinational Logic)
    // =================================================================
    wire [7:0] alu_out; // Output from the ALU module

    ALU my_alu (
        .A(data_A),
        .B(data_B),
        .instruction(instruction),
        .F(alu_out)
    );

    // =================================================================
    // 3. FSM State Register (Sequential)
    // =================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // =================================================================
    // 4. FSM Next-State Logic (Combinational)
    // =================================================================
    always @(*) begin
        case (state)
            IDLE: begin
                if (start) begin
                    next_state = PROC;
                end else begin
                    next_state = IDLE;
                end
            end
            
            PROC: begin
                // Compare with the latched reg_count instead of the unstable input port.
                // Also ensures that reg_count is non-zero to prevent false startup transitions.
                if (input_count == reg_count && reg_count != 8'd0) begin
                    next_state = DONE;
                end else begin
                    next_state = PROC;
                end
            end
            
            DONE: begin
                // Unconditionally return to IDLE in the next cycle to form a 1-cycle finish pulse
                next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // =================================================================
    // 5. Register Updates and On-the-fly Insertion Sort (Sequential)
    // =================================================================
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_count <= 8'd0;
            reg_count   <= 8'd0;
            for (i = 0; i < K; i = i + 1) begin
                top_k[i] <= 8'd0;
            end
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        // Latch the 'count' value exactly when 'start' is asserted
                        reg_count   <= count;
                        input_count <= 8'd0;
                        for (i = 0; i < K; i = i + 1) begin
                            top_k[i] <= 8'd0;
                        end
                    end
                end
                
                PROC: begin
                    if (valid) begin
                        input_count <= input_count + 8'd1;

                        // Parallel Shift and Insert Algorithm (Descending)
                        if (alu_out > top_k[0]) begin
                            top_k[0] <= alu_out;
                        end
                        for (i = 1; i < K; i = i + 1) begin
                            if (alu_out > top_k[i-1]) begin
                                top_k[i] <= top_k[i-1];
                            end else if (alu_out > top_k[i]) begin
                                top_k[i] <= alu_out;
                            end
                        end
                    end
                end

                DONE: begin
                    // Keep internal values stable during output phase
                end
            endcase
        end
    end

    // =================================================================
    // 6. Output Assignments (Combinational)
    // =================================================================
    always @(*) begin
        if (state == DONE) begin
            finish      = 1'b1;
            kth_largest = top_k[K-1]; // Since sorted descending, last element is the K-th largest
        end else begin
            finish      = 1'b0;
            kth_largest = 8'd0;
        end
    end

endmodule