`timescale 1ns/1ps
module ALU (
    input  [7:0] A,
    input  [7:0] B,
    input  [3:0] instruction,
    output reg  [7:0] F            
);
    // TODO: write your design below
    // =================================================================
    // INSTRUCTION TABLE (OPCODES) FROM SPECIFICATION
    // =================================================================
    localparam OP_ROT_R     = 4'b0000; // Right_Rotate(A, B)
    localparam OP_ROT_L     = 4'b0001; // Left_Rotate(A, B)
    localparam OP_POPCNT    = 4'b0010; // Population_Count(A)
    localparam OP_ABS_DIFF  = 4'b0011; // Absolute_Difference(A, B)
    localparam OP_L_ZERO    = 4'b0100; // Leading_Zero_Count(A)
    localparam OP_SAT_ADD   = 4'b0101; // Saturated_Add(A, B)
    localparam OP_RST_TAIL  = 4'b0110; // ResetTailk(A, B)
    localparam OP_SET_TAIL  = 4'b0111; // SetTailk(A, B)
    localparam OP_XOR       = 4'b1000; // XOR(A, B)
    localparam OP_ADD       = 4'b1001; // ADD(A, B)
    localparam OP_SUB       = 4'b1010; // SUB(A, B)

    // =================================================================
    // TEMPORARY REGISTERS FOR COMPLEX COMPUTATIONS
    // =================================================================
    reg [3:0] popcount_B; // Population count of B (0 to 8)
    reg [2:0] rot_amount; // Shift/Rotate amount (B % 8)
    reg [8:0] sum_sat;    // 9-bit sum to detect overflow for Saturated Add

    // =================================================================
    // COMBINATIONAL LOGIC FOR ALU OPERATIONS
    // =================================================================
    always @(*) begin
        // Default assignments to prevent Latch synthesis
        F          = 8'd0;
        popcount_B = B[0] + B[1] + B[2] + B[3] + B[4] + B[5] + B[6] + B[7];
        rot_amount = B[2:0];
        sum_sat    = {1'b0, A} + {1'b0, B};

        case (instruction)
            // 1. Right_Rotate(A, B): Rotate right A by B[2:0] bits
            OP_ROT_R: begin
                F = (A >> rot_amount) | (A << (4'd8 - rot_amount));
            end

            // 2. Left_Rotate(A, B): Rotate left A by B[2:0] bits
            OP_ROT_L: begin
                F = (A << rot_amount) | (A >> (4'd8 - rot_amount));
            end

            // 3. Population_Count(A): Number of 1's in A (binary representation)
            OP_POPCNT: begin
                F = A[0] + A[1] + A[2] + A[3] + A[4] + A[5] + A[6] + A[7];
            end
            
            // 4. Absolute_Difference(A, B): F = |A - B| (unsigned)
            OP_ABS_DIFF: begin
                F = (A >= B) ? (A - B) : (B - A);
            end
            
            // 5. Leading_Zero_Count(A): Number of leading zeros in A (MSB down to LSB)
            OP_L_ZERO: begin
                if      (A[7]) F = 8'd0;
                else if (A[6]) F = 8'd1;
                else if (A[5]) F = 8'd2;
                else if (A[4]) F = 8'd3;
                else if (A[3]) F = 8'd4;
                else if (A[2]) F = 8'd5;
                else if (A[1]) F = 8'd6;
                else if (A[0]) F = 8'd7;
                else           F = 8'd8;
            end
            
            // 6. Saturated_Add(A, B): Unsigned addition clamped to 255 (8'hFF)
            OP_SAT_ADD: begin
                F = (sum_sat > 9'd255) ? 8'hFF : sum_sat[7:0];
            end
            
            // 7. ResetTailk(A, B): Reset the lowest Population_Count(B) bits of A to 0
            OP_RST_TAIL: begin
                F = A & (8'hFF << popcount_B);
            end
            
            // 8. SetTailk(A, B): Set the lowest Population_Count(B) bits of A to 1
            OP_SET_TAIL: begin
                F = A | ~(8'hFF << popcount_B);
            end
            
            // 9. XOR(A, B): Bitwise XOR
            OP_XOR: begin
                F = A ^ B;
            end

            // 10. ADD(A, B): Regular Unsigned Addition
            OP_ADD: begin
                F = A + B;
            end

            // 11. SUB(A, B): Regular Unsigned Subtraction
            OP_SUB: begin
                F = A - B;
            end

            // Default Case: Handles unused opcodes (4'b1011 to 4'b1111) safely
            default: begin
                F = 8'd0;
            end
        endcase
    end
 
endmodule