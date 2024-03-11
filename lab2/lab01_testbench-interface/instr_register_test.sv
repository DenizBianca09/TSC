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

  parameter  RD_NR= 20;
  parameter  WRITE_NR= 20;

  int seed = 555; //initializare variabila


  initial begin //timpul 0 al simularii se executa codul
    $display("\n\n***********************************************************");
    $display(    "***  THIS IS NOT A SELF-CHECKING TESTBENCH (YET).  YOU  ***");
    $display(    "***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    $display(    "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    $display(    "***********************************************************");

    $display("\nReseting the instruction register...");
    write_pointer  = 5'h00;         // initialize write pointer
    read_pointer   = 5'h1F;         // initialize read pointer
    load_en        = 1'b0;          // initialize load control line
    reset_n       <= 1'b0;          // assert reset_n (active low)
    repeat (2) @(posedge clk) ;     // hold in reset for 2 clock cycles - 16ns
    reset_n        = 1'b1;          // deassert reset_n (active low)

    $display("\nWriting values to register stack...");
    @(posedge clk) load_en = 1'b1;  // enable writing to register - 26ns
    //repeat (3) begin modificat 11.03.2024 Bianca Iorga
    //repeat (10) begin modificat 11.03.2024 Bianca Iorga
    repeat (WRITE_NR) begin
      @(posedge clk) randomize_transaction;
      @(negedge clk) print_transaction;
    //punem check_result
    check_result;
    end
    @(posedge clk) load_en = 1'b0;  // turn-off writing to register

    // read back and display same three register locations
    $display("\nReading back the same register locations written...");
    //for (int i=0; i<=2; i++) begin modificat 11.03.2024 Bianca Iorga
    //for (int i=0; i<=9; i++) begin modificat 11.03.2024 Bianca Iorga
    for (int i=0; i<=RD_NR; i++) begin
      // later labs will replace this loop with iterating through a
      // scoreboard to determine which addresses were written and
      // the expected values to be read back
      @(posedge clk) read_pointer = i;
      @(negedge clk) print_results; // pentru locatie 0 - 84ns, locatie 1 - 94ns , locatie 2 - 104ns
    end

    @(posedge clk) ;
    $display("\n***********************************************************");
    $display(  "***  THIS IS NOT A SELF-CHECKING TESTBENCH (YET).  YOU  ***");
    $display(  "***  NEED TO VISUALLY VERIFY THAT THE OUTPUT VALUES     ***");
    $display(  "***  MATCH THE INPUT VALUES FOR EACH REGISTER LOCATION  ***");
    $display(  "***********************************************************\n");
    $finish;
  end

  function void randomize_transaction;
    // A later lab will replace this function with SystemVerilog
    // constrained random values
    //
    // The stactic temp variable is required in order to write to fixed
    // addresses of 0, 1 and 2.  This will be replaceed with randomizeed
    // write_pointer values in a later lab
    //
    static int temp = 0; //static - pastreaza valoarea indiferent de instanta (aceeasi locatie de memorie)
    operand_a     <= $random(seed)%16;                 // between -15 and 15; random genereaza o variab pe 32 de biti, generat in fucntie de vendor
    operand_b     <= $unsigned($random)%16;            // between 0 and 15; unsigned - converteste nr negative in nr pozitive
    opcode        <= opcode_t'($unsigned($random)%8);  // between 0 and 7, cast to opcode_t type; cast - este convertit de la un tip de date la altul
    write_pointer <= temp++;//se initializeaza si apoi incremeteaza pt temp++, pentru ++temp e invers
  endfunction: randomize_transaction 

  function void print_transaction; //afiseaza pe semnale
    $display("Writing to register location %0d: ", write_pointer);
    $display("  opcode = %0d (%s)", opcode, opcode.name);
    $display("  operand_a = %0d",   operand_a);
    $display("  operand_b = %0d\n", operand_b);
  endfunction: print_transaction

  function void print_results;
    $display("Read from register location %0d: ", read_pointer);
    $display("  opcode = %0d (%s)", instruction_word.opc, instruction_word.opc.name);
    $display("  operand_a = %0d",   instruction_word.op_a);
    $display("  operand_b = %0d\n", instruction_word.op_b);
    $display("  rezultat = %0d\n", instruction_word.rezultat);
  endfunction: print_results

function void check_result
//functie check register if-else in loc de case si la final facem un if care se faca comparatia intre 
//rezultatul calculat de noi si cel primit, functia nu returneaza nimic, este void
endfunction: check_result

endmodule: instr_register_test
