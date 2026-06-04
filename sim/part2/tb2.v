`timescale 1ns/1ps
`define DELAY 10
`define CYCLE 12000
`define NUM_OF_PAT 50

module tb2;
  reg clk;
  reg rst_n;
  reg start;
  reg valid;
  reg [7:0] A;
  reg [7:0] B;
  reg [3:0] instruction;
  reg [7:0] count;
  wire [7:0] kth_largest;
  reg [7:0] k_max;
  wire finish;
  wire [7:0] k_max1, k_max2, k_max3, k_max4, k_max5;
  wire finish1, finish2, finish3, finish4, finish5;

  // Module instantiation
  top #(.K(1))   
  k1_top (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .valid(valid),
        .data_A(A),
        .data_B(B),
        .instruction(instruction),
        .count(count),
        .kth_largest(k_max1),
        .finish(finish1)
      );

  top #(.K(2))   
  k2_top (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .valid(valid),
        .data_A(A),
        .data_B(B),
        .instruction(instruction),
        .count(count),
        .kth_largest(k_max2),
        .finish(finish2)
      );

  top #(.K(3))   
  k3_top (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .valid(valid),
        .data_A(A),
        .data_B(B),
        .instruction(instruction),
        .count(count),
        .kth_largest(k_max3),
        .finish(finish3)
      );

  top #(.K(4))   
  k4_top (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .valid(valid),
        .data_A(A),
        .data_B(B),
        .instruction(instruction),
        .count(count),
        .kth_largest(k_max4),
        .finish(finish4)
      );
  
  top #(.K(5))   
  k5_top (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .valid(valid),
        .data_A(A),
        .data_B(B),
        .instruction(instruction),
        .count(count),
        .kth_largest(k_max5),
        .finish(finish5)
      );
  
  assign kth_largest =
    (k_max == 1) ? k_max1 :
    (k_max == 2) ? k_max2 :
    (k_max == 3) ? k_max3 :
    (k_max == 4) ? k_max4 : k_max5;

  assign finish =
    (k_max == 1) ? finish1 :
    (k_max == 2) ? finish2 :
    (k_max == 3) ? finish3 :
    (k_max == 4) ? finish4 : finish5;

  // waveform
  initial begin
      $fsdbDumpfile("./part2/part2_sim.fsdb");
      $fsdbDumpvars; 
  end

  // load patterns
  reg [7:0] k_reg[0:`NUM_OF_PAT-1];
  reg [7:0] count_reg [0:`NUM_OF_PAT-1];
  reg [7:0] golden [0:`NUM_OF_PAT-1];

  reg [7:0] pattern_A [0:`NUM_OF_PAT*64];
  reg [7:0] pattern_B [0:`NUM_OF_PAT*64];
  reg [3:0] pattern_instruction [0:`NUM_OF_PAT*64];

  integer file;
  integer r_ans, r_seq;
  integer pat, c, idx;
  reg [23:0] buff_ans;
  reg [19:0] buff_seq;

  initial begin
      idx=0;
      file = $fopen("./part2/part2_pattern.dat","r");
      for (pat=0;pat<`NUM_OF_PAT;pat=pat+1) begin
        r_ans=$fscanf(file,"%h",buff_ans);
        {k_reg[pat], count_reg[pat], golden[pat]} = buff_ans;
        for(c=0; c<count_reg[pat]; c=c+1) begin
            r_seq=$fscanf(file,"%h",buff_seq);
            {pattern_A[idx], pattern_B[idx], pattern_instruction[idx]} = buff_seq;
            idx=idx+1;
        end
      end
      $fclose(file);
  end

  // clock
  always #(`DELAY) begin
    clk = ~clk;
  end 

  integer cnt;
  integer seq_idx;
  integer numTest;
  integer error;
  integer wait_finish = 0;
  integer last_pat;

  // setup
  initial begin
    error = 0;
    seq_idx = 0;
    clk = 0;
    rst_n = 1;
    start = 0;
    valid = 0;
  end

  // simulation
  initial begin
    A = 8'dx;
    B = 8'dx;
    instruction = 8'dx;
    count = 8'dx;

    #(`DELAY*4);
    @(negedge clk);
    rst_n = 0;
    @(negedge clk);
    @(negedge clk);
    @(negedge clk);
    rst_n = 1;
    for(numTest = 0; numTest < `NUM_OF_PAT; numTest = numTest + 1) begin
      @(negedge clk);
      start = 1;
      count = count_reg[numTest];
      k_max = k_reg[numTest];

      @(negedge clk);
      @(negedge clk);
      start = 0;
      count = 8'd0;
      for(cnt = 0; cnt < count_reg[numTest]; cnt = cnt + 1) begin
        @(negedge clk);
        A = pattern_A[seq_idx];
        B = pattern_B[seq_idx];
        instruction = pattern_instruction[seq_idx];
        seq_idx = seq_idx + 1;
        valid = 1;

        @(negedge clk);
        valid=0;
      end

      valid = 0;
      wait_finish = 1;
      wait (finish);
      wait_finish = 0;
      if(golden[numTest] !== kth_largest) begin
        error = error + 1;
        $display("[Error] Pattern%d: k =%d, your answer = %d, but the golden = %d.", numTest, k_max, kth_largest, golden[numTest]);
      end
      else begin
        $display("[Pass]  Pattern%d: k =%d, kth_largest = %d.", numTest, k_max, kth_largest);
      end
      #(`DELAY*4);
    end

    if(error == 0) begin
      $display("");
      $display(" █████  ██      ██          ██████   █████  ███████ ███████");
      $display("██   ██ ██      ██          ██   ██ ██   ██ ██      ██");
      $display("███████ ██      ██          ██████  ███████ ███████ ███████");
      $display("██   ██ ██      ██          ██      ██   ██      ██      ██");
      $display("██   ██ ███████ ███████     ██      ██   ██ ███████ ███████");
      $display("");
      $display("\n[SUCCESS] You can submit to eeclass.\n");
    end
    else begin
      $display("\n[FAIL] There are %3d errors ... QQQQQQ.\n", error);
    end
    $finish;
  end

  initial
  begin
    #(`DELAY*`CYCLE);
    $finish;
  end

  always
  begin
    forever
      if(wait_finish == 1)begin
        last_pat = numTest;
        #(`DELAY * 80);
        if(wait_finish == 1 && last_pat == numTest)begin
          $display("\n[FAIL] waiting for finish flag timeout.\n");
          $finish;
        end
      end else begin
        #(`DELAY);
      end
  end

  always
  begin
    forever
      if(finish)begin
          #(`DELAY*0.2);
          if(clk == 0)begin
            $display("-------------------------------------------------------\n");
            $display("[ERROR]");
            $display("Pattern %d, finish flag does not rise at positive edge", numTest);
            $display("-------------------------------------------------------\n");
            error = error + 1;
          end
          #(`DELAY*2+1);
          if(finish == 1)begin
            $display("-------------------------------------------------------\n");
            $display("[ERROR]");
            $display("Pattern %d, finish flag rise more than one cycle", numTest);
            $display("-------------------------------------------------------\n");
            error = error + 1;
          end
      end else begin
        #(`DELAY * 0.1);
      end
  end
endmodule