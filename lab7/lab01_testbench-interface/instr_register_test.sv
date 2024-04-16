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
  
  parameter RD_NR = 3;
  parameter WRITE_NR = 3;
  parameter WR_ORDER = 0; // 0 -> inc, 1 -> random, 2 -> dec
  parameter RD_ORDER = 0;
  parameter NAME_OF_TEST;
  parameter SEED_VAL = 555;

  instruction_t iw_reg [0:31];
  instruction_t iw_reg_test [0:31]; 


  //int seed = 555;
  int seed = SEED_VAL;
  int pass = 0;
  int fail = 0;

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
    foreach (iw_reg_test[i])        // resetam iw_reg_test
    iw_reg_test[i] = '{opc:ZERO,default:0};

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
    for (int i=0; i<RD_NR; i++) begin
      //@(posedge clk) read_pointer = i;
      @(posedge clk) case (RD_ORDER)
        0: read_pointer = i;
        1: read_pointer = ($unsigned($random)%32);
        2: read_pointer = 31 - (i % 32);
     endcase 
      @(negedge clk) print_results;
      check_result;
    end

    write_file;

    final_report;

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
      write_pointer = (WR_ORDER == 2) ? 31 - (temp % 32) : temp % 32;
      read_pointer = (WR_ORDER == 2) ? 31 - (temp % 32) : temp % 32;
    end
    1: begin
      write_pointer = (WR_ORDER == 1) ? $random(seed) % 32 : temp % 32;
      read_pointer = (WR_ORDER == 1) ? $random(seed) % 32 : temp % 32;
    end
    2: begin
      write_pointer = (WR_ORDER == 2) ? 31 - (temp % 32) : temp % 32;
      read_pointer = (WR_ORDER == 2) ? 31 - (temp % 32) : temp % 32;
    end
  endcase

  temp++;
  endfunction:randomize_transaction

  // Print transaction function
  function void print_transaction;
    $display("Writing to register location %0d: ", write_pointer);
    $display("  opcode = %0d (%s)", opcode, opcode.name);
    $display("  operand_a = %0d", operand_a);
    $display("  operand_b = %0d\n", operand_b);
  endfunction: print_transaction

  // Print results function
  function void print_results;
    $display("Read from register location %0d: ", read_pointer);
    $display("  opcode = %0d (%s)", instruction_word.opc, instruction_word.opc.name);
    $display("  operand_a = %0d", instruction_word.op_a);
    $display("  operand_b = %0d\n", instruction_word.op_b);
    $display(" exp_result = %0d\n", instruction_word.exp_result);
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
      DIV: if (iw_reg_test[read_pointer].op_b == {32{1'b0}})
               exp_result = {64{1'b0}}; 
             else
               exp_result = iw_reg_test[read_pointer].op_a / iw_reg_test[read_pointer].op_b;
      MOD: exp_result = iw_reg_test[read_pointer].op_a % iw_reg_test[read_pointer].op_b;
      //default: exp_result = {64{1'b0}};
    endcase

    // Display the check result
    $display("\nVerification Result:");
    $display("  Read Pointer: %0d", read_pointer);
    $display("  Opcode: %0d (%s)", iw_reg_test[read_pointer].opc, iw_reg_test[read_pointer].opc.name);
    $display("  Operand A: %0d", iw_reg_test[read_pointer].op_a);
    $display("  Operand B: %0d", iw_reg_test[read_pointer].op_b);
    $display("\nCalculated Result: %0d", exp_result);

    // Check if the opcode, operands, and result match the expected values
    if (iw_reg_test[read_pointer].opc === instruction_word.opc) 
        $display("Matching Opcode!");
    else
        $display("Mismatching Opcode!");

    if (iw_reg_test[read_pointer].op_a === instruction_word.op_a) 
        $display("Matching Operand A!");
    else
        $display("Mismatching Operand A!");

    if (iw_reg_test[read_pointer].op_b === instruction_word.op_b) 
        $display("Matching Operand B!");
    else
        $display("Mismatching Operand B!");

    if (exp_result === instruction_word.exp_result) 
        $display("Matching Results!");
    else 
        $display("Mismatching Results!");

    // Check if the test passed or failed
    if (iw_reg_test[read_pointer].opc === instruction_word.opc && 
        iw_reg_test[read_pointer].op_a === instruction_word.op_a && 
        iw_reg_test[read_pointer].op_b === instruction_word.op_b && 
        exp_result === instruction_word.exp_result) begin
        $display("TEST PASSED");
        pass = pass + 1; 
    end else begin
        $display("TEST FAILED");
        fail = fail + 1; 
    end
  endfunction: check_result

  //aici un fopen ("..reports/regression...")
  //$display ("Denumirea testului luata din %")
  //ori facem aici, ori facem o alta functie
  //cand rulam toata regresia, in regression_status ar trebui sa avem denumirea testului si pass sau fail
  // Function to save data to instruction register
  function void save_data;
  iw_reg_test[write_pointer].opc = opcode;
  iw_reg_test[write_pointer].op_a = operand_a;
  iw_reg_test[write_pointer].op_b = operand_b;
  iw_reg_test[write_pointer].exp_result = 1'b0; 
  endfunction: save_data


  function void final_report;
    real pass_percentage;
    real fail_percentage;

    pass_percentage = (pass * 100.0) / WRITE_NR;
    fail_percentage = (fail * 100.0) / WRITE_NR;

    $display("\n-------- Test Summary --------");
    $display("Total number of tests: %0d", WRITE_NR);
    $display("Number of failed tests: %0d", fail);
    $display("Number of passed tests: %0d", pass);
    $display("Pass percentage: %.2f%%", pass_percentage);
    $display("Fail percentage: %.2f%%", fail_percentage);

    // Afisare raport succinte bazat pe procentajele de trecere/esuare
    if (pass_percentage >= 90.0)
        $display("Overall Status: Excellent");
    else if (pass_percentage >= 80.0)
        $display("Overall Status: Very Good");
    else if (pass_percentage >= 70.0)
        $display("Overall Status: Good");
    else if (pass_percentage >= 60.0)
        $display("Overall Status: Satisfactory");
    else if (pass_percentage >= 50.0)
        $display("Overall Status: Average");
    else
        $display("Overall Status: Needs Improvement");

    $display("-------------------------------");
endfunction: final_report

function void write_file;
  int fd;

  fd = $fopen("../reports/regression_transcript/regression_status.txt", "a");
  if (pass == RD_NR) begin
    $fdisplay(fd, "%s : passed", NAME_OF_TEST);
  end
  else begin
    $fdisplay(fd, "%s : failed", NAME_OF_TEST);
  end

  $fclose(fd);
endfunction: write_file

endmodule: instr_register_test

