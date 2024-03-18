/***********************************************************************
 * A SystemVerilog top-level netlist to connect testbench to DUT
 **********************************************************************/

module top;
  timeunit 1ns/1ns; //unitatea de timp este 1ns cu o rezolutie de 1ns - cand marim semnalele de unda

  // user-defined types are defined in instr_register_pkg.sv
  import instr_register_pkg::*;

  // clock variables - declarare variabile
  logic clk; 
  logic test_clk;

  // interconnecting signals
  logic          load_en;
  logic          reset_n;
  opcode_t       opcode; // _t inseamna template
  operand_t      operand_a, operand_b;
  address_t      write_pointer, read_pointer;
  instruction_t  instruction_word;

  // instantiate testbench and connect ports -   numele uni modul si denumirea instantei
  instr_register_test test (
    .clk(test_clk),
    .load_en(load_en),
    .reset_n(reset_n),
    .operand_a(operand_a),
    .operand_b(operand_b),
    .opcode(opcode),
    .write_pointer(write_pointer),
    .read_pointer(read_pointer),
    .instruction_word(instruction_word)
   );

  // instantiate design and connect ports
  instr_register dut (
    .clk(clk),
    .load_en(load_en),
    .reset_n(reset_n),
    .operand_a(operand_a),
    .operand_b(operand_b),
    .opcode(opcode),
    .write_pointer(write_pointer),
    .read_pointer(read_pointer),
    .instruction_word(instruction_word)
   );

  // clock oscillators
  initial begin //initial - cuv cheie in verilog, explica ca codul incepe de la 0
    clk <= 0; 
    forever #5  clk = ~clk; //#5 - asteapta 5 unitati de timp, vedem unde a fost declarat timeunit
  end

  initial begin
    test_clk <=0;
    // offset test_clk edges from clk to prevent races between
    // the testbench and the design
    #4 forever begin
      #2ns test_clk = 1'b1;
      #8ns test_clk = 1'b0;
    end
  end

endmodule: top
