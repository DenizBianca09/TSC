/***********************************************************************
 * A SystemVerilog RTL model of an instruction regisgter:
 * User-defined type definitions
 **********************************************************************/
package instr_register_pkg;
  timeunit 1ns/1ns;

  typedef enum logic [3:0] {
  	ZERO,
    PASSA,
    PASSB,
    ADD,
    SUB,
    MULT,
    DIV,
    MOD
  } opcode_t; //definire tip de data de utilizator, enumerare; 3:0 folosit pentru ca folosim operatii

   typedef logic signed [31:0] operand_t;

  typedef logic signed [63:0] result_t;
  //daca nu specificam logic e unsigned
  typedef logic [4:0] address_t; //32 de adrese adica 2 la puterea a patra
  
  typedef struct {
    opcode_t  opc;
    operand_t op_a;
    operand_t op_b; //adaug rezultat
    result_t rezultat;
  } instruction_t; // opc este pe 4 biti, op_a si op_b sunt pe 32 de biti deci in total avel 68 de biti

endpackage: instr_register_pkg
