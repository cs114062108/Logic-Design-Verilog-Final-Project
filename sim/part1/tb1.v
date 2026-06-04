`timescale 1ns/1ps
`define DELAY 10
`define NUM_OF_PAT 1000

module tb();

    reg [7:0] A;
    reg [7:0] B;
    reg [3:0] instruction;
    wire [7:0] F;

    ALU fu(
        .instruction(instruction),
        .A(A),
        .B(B),
        .F(F)
    );


    // waveform
    initial begin
        $fsdbDumpfile("./part1/part1_sim.fsdb");
        $fsdbDumpvars; 
    end

    // load pattern
    reg [7:0] pattern_A [0:`NUM_OF_PAT-1];
    reg [7:0] pattern_B [0:`NUM_OF_PAT-1];
    reg [3:0] pattern_instruction [0:`NUM_OF_PAT-1];
    reg [7:0] golden[0:`NUM_OF_PAT-1];

    integer file;
    integer r;
    integer i;
    reg [27:0] buff_in;

    initial begin
        file = $fopen("./part1/part1_pattern.dat","r");
        for(i=0;i<`NUM_OF_PAT;i=i+1) begin
            r=$fscanf(file,"%h",buff_in);
            {pattern_A[i], pattern_B[i], pattern_instruction[i], golden[i]} = buff_in;
        end
        $fclose(file);
    end

    integer pat_idx;
    initial begin
        A = 8'dx;
        B = 8'dx;
        instruction = 4'dx;
        for(pat_idx=0;pat_idx<`NUM_OF_PAT;pat_idx=pat_idx+1) begin
            #(`DELAY);
            A=pattern_A[pat_idx];
            B=pattern_B[pat_idx];
            instruction=pattern_instruction[pat_idx];
        end
    end

    integer error;
    integer j;
    initial begin
        #(`DELAY/2);

        error=0;
        for(j=0;j<`NUM_OF_PAT;j=j+1) begin
            #(`DELAY);
            if(F !== golden[j]) begin
                error = error + 1;
                $display("\n------------------------------------------------");
                $display("[ERROR]");
                $display("A = 8'h%h (8'b%b)", A, A);
                $display("B = 8'h%h (8'b%b)", B, B);
                $display("instruction = 4'h%h", instruction);
                $display("Your answer = 8'h%h (8'b%b)", F, F);
                $display("Golden      = 8'h%h (8'b%b)", golden[j], golden[j]);
                $display("------------------------------------------------\n");
            end
        end
    
        if(error == 0) begin
            $display("\n====================================");
            $display("  PASS  \\(^o^)/");
            $display("  You can move to part2.");
            $display("====================================\n");
        end
        else begin
            $display("\n====================================");
            $display("  FAIL  Q_Q");
            $display("  it exists errors = %d", error);
            $display("====================================\n");
        end
        $finish;
    end

endmodule