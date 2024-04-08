/***********************************************************************
 * A SystemVerilog testbench for an instruction register.
 * The course labs will convert this to an object-oriented testbench
 * with constrained random test generation, functional coverage, and
 * a scoreboard for self-verification.
 **********************************************************************/

module instr_register_test
  import instr_register_pkg::*;  // user-defined types are defined in instr_register_pkg.sv - :* inseamna ca importeaza tot
  (input  logic          clk,
   output logic          load_en,
   output logic          reset_n,
   output operand_t      operand_a,
   output operand_t      operand_b,
   output opcode_t       opcode,
   output address_t      write_pointer,
   output address_t      read_pointer,
   input  instruction_t  instruction_word
  );

  timeunit 1ns/1ns;

  int tests_passed = 0;
  int tests_failed = 0;
  
  parameter RD_NR = 31;
  parameter WRITE_NR = 20;
  parameter WR_ORDER = 0; // 0 -> inc, 1 -> random, 2 -> dec
  parameter RD_ORDER = 0;
  //parameter TEST_SG

  int seed = 555;
  instruction_t iw_reg_test [0:31];

  // Initial block
  initial begin
    $display("\n\n***********************************************************");
    $display("***  THIS IS A SELF-CHECKING TESTBENCH.  YOU  ***");
    $display("***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    $display("***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    $display("***********************************************************");

    // Reset instruction register
    $display("\nReseting the instruction register...");
    write_pointer = 5'h00;
    read_pointer = 5'h1F;
    load_en = 1'b0;
    reset_n = 1'b0;
    repeat (2) @(posedge clk);
    reset_n = 1'b1;

    // Writing values to register stack
    $display("\nWriting values to register stack...");
    @(posedge clk) load_en = 1'b1;
    repeat (WRITE_NR) begin
      @(posedge clk) randomize_transaction;
      @(negedge clk) print_transaction;
      save_data;
    end
    @(posedge clk) load_en = 1'b0;

    // Reading back the same register locations written
    $display("\nReading back the same register locations written...");
    for (int i=0; i<=RD_NR; i++) begin
      @(posedge clk) read_pointer = i;
      @(negedge clk) print_results;
      check_result;
    end

    // Display total tests passed and failed
    $display("\nTotal tests passed: %0d", tests_passed);
    $display("Total tests failed: %0d", tests_failed);

    $display("\n***********************************************************");
    $display("***  THIS IS A SELF-CHECKING TESTBENCH.  YOU  ***");
    $display("***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    $display("***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    $display("***********************************************************\n");

    // Finish simulation
    $finish;
  end

  // Randomize transaction function
  function void randomize_transaction;
    static int temp = 0; 
    operand_a = $random(seed) % 16;                 
    operand_b = $unsigned($random) % 16;            
    opcode = opcode_t'($unsigned($random) % 8);  
    case (temp % 3)
        0: begin
            write_pointer = temp % 32;
            read_pointer = temp % 32;
        end
        1: begin
            write_pointer = $random(seed) % 32;
            read_pointer = $random(seed) % 32;
        end
        2: begin
            write_pointer = 31 - (temp % 32);
            read_pointer = 31 - (temp % 32);
        end
    endcase
    temp++;
  endfunction

  // Print transaction function
  function void print_transaction;
    $display("Writing to register location %0d: ", write_pointer);
    $display("  opcode = %0d (%s)", opcode, opcode.name);
    $display("  operand_a = %0d", operand_a);
    $display("  operand_b = %0d\n", operand_b);
  endfunction

  // Print results function
  function void print_results;
    $display("Read from register location %0d: ", read_pointer);
    $display("  opcode = %0d (%s)", instruction_word.opc, instruction_word.opc.name);
    $display("  operand_a = %0d", instruction_word.op_a);
    $display("  operand_b = %0d\n", instruction_word.op_b);
    $display("  rezultat = %0d\n", instruction_word.rezultat);
  endfunction

  // Check result function
  function void check_result;
    result_t exp_result;

    case (iw_reg_test[read_pointer].opc)
      ZERO: exp_result = {64{1'b0}};
      PASSA: exp_result = iw_reg_test[read_pointer].op_a;
      PASSB: exp_result = iw_reg_test[read_pointer].op_b;
      ADD: exp_result = iw_reg_test[read_pointer].op_a + iw_reg_test[read_pointer].op_b;
      SUB: exp_result = iw_reg_test[read_pointer].op_a - iw_reg_test[read_pointer].op_b;
      MULT: exp_result = iw_reg_test[read_pointer].op_a * iw_reg_test[read_pointer].op_b;
      DIV: exp_result = (iw_reg_test[read_pointer].op_b != 0) ? iw_reg_test[read_pointer].op_a / iw_reg_test[read_pointer].op_b : 'x;
      MOD: exp_result = iw_reg_test[read_pointer].op_a % iw_reg_test[read_pointer].op_b;
      default: exp_result = 'x;
    endcase

    if (exp_result == instruction_word.rezultat) begin
      $display("Check PASSED: Calculated result matches DUT result. Opcode: %s, OpA: %0d, OpB: %0d, Expected Result: %0d", instruction_word.opc.name, instruction_word.op_a, instruction_word.op_b, exp_result);
      tests_passed++;
    end else begin
      $display("Check FAILED: Mismatch between calculated and DUT result. Opcode: %s, OpA: %0d, OpB: %0d, Expected: %0d, Received: %0d", instruction_word.opc.name, instruction_word.op_a, instruction_word.op_b, exp_result, instruction_word.rezultat);
      tests_failed++;
    end
    // Afisare numar teste trecute si picate la fiecare verificare
    $display("Total tests passed: %0d", tests_passed);
    $display("Total tests failed: %0d", tests_failed);
  endfunction

  // Initial block to print total tests passed and failed
  initial begin
    $display("Total tests passed: %0d", tests_passed);
    $display("Total tests failed: %0d", tests_failed);
  end

  //aici un fopen ("..reports/regression...")
  //$display ("Denumirea testului luata din %")
  //ori facem aici, ori facem o alta functie
  //cand rulam toata regresia, in regression_status ar trebui sa avem denumirea testului si pass sau fail
  // Function to save data to instruction register
  function void save_data;
    iw_reg_test[write_pointer] = {opcode, operand_a, operand_b, 'b0};
  endfunction

endmodule

