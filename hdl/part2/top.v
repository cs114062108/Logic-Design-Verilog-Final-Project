`timescale 1ns/1ps
module top #(parameter K = 3) (
    input clk,
    input rst_n,
    input start,
    input valid,
    input [7:0] data_A,
    input [7:0] data_B,
    input [3:0] instruction,
    input [7:0] count,
    output [7:0] kth_largest,
    output finish
);
   //TODO: write your design below

endmodule