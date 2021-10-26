# ASSURE

ASSURE is a prototype tool for RTL obfuscation jointly developed by Politecnico di Milano and New York University.

Welcome to ASSURE!

This is a tool for logic locking at register-transfer level. With ASSURE, designers can apply logic locking to existing
RTL designs, including manually-designed intellectual property (IP) cores or HLS-generated components. Currently, 
ASSURE supports only Verilog designs.

For any questions/concerns, please email [Christian Pilato](christian.pilato@polimi.it).

## Requirements ##

### ASSURE dependencies ####

To execute ASSURE, you will need to satisfy the following dependencies:
1. Python (ver. 3.6 or greater)
2. Icarus Verilog

## Installation ##

ASSURE does not require any installation and can be directly used.

## Key Generation

ASSURE uses a locking key for obfuscation. This locking key has a user-defined number of bits and should be created in advance. For example, it is possible to create a 512-bit pseudo-random key by using the following command:

```
   $ python3 tests/generate_key.py -b 512 -o input.key
```
This command generates the file `input.key` that contains a sequence of bits. The number of bits is defined by the command-line option `-b`.

## Running ASSURE ##

### Basic execution ###

ASSURE is a command-line tool and requires the following elements to obfuscate a given design:
- The Verilog files of the design (together with compilation flags)
- The name of the top module (`--top` option) 
- The locking key for obfuscation (`--locking-key` option)
- The obfuscation options

For example, let us assume that the designer wants to obfuscate the following design with an 8-bit key (01010111):

```
module alu_top(in1, in2, in3, sel, out1, out2);
   input  [7:0] in1;
   input  [7:0] in2;
   input  [7:0] in3;
   input        sel;
   
   output [7:0] out1;
   output [7:0] out2;

   assign out1 = sel ? in1 + in2 : in1 - in2;
   assign out2 = in3 * 8'd12;

endmodule 
```

The design is saved into a file `alu.v`. The designer must create a text file to contain all bits of the locking key:
 
```
01010111
```

Let us assume this file is named `locking_key.txt`. ASSURE can selectively apply the different obfuscation techniques:
- `--obfuscate-const <min_size>`: applies constant obfuscation, where `min-size` represents the minimum bit-width of
the constants to obfuscate. For example, with `--obfuscate-const 8`, all constants equals or larger than 8 bits are 
obfuscated. With  `--obfuscate-const 0`, all constants are obfuscated. Requires as many key bits as the total bit-widths
of the constants.
- `--obfuscate-ops`: applies operation obfuscation to arithmetic operations. Currently, the type of operation variants
is fixed for each operator. For example, multiplications are always paired with bogus additions. Requires one key bit
per operation.
- `--obfuscate-branch`: applies control-flow obfuscation to ternary operators and `if-else` statements. Requires one key
bit per control construct.

For example, it is possible to apply constant and control-flow obfuscation to the `alu_top` module as follows:

```
   $ python3 assure.py alu.v --top alu_top.v --locking-key locking_key.txt --obfuscate-const 0 --obfuscate-branch
```

ASSURE also feature a single option (`--obfuscate`) to apply all obfuscation techniques mentioned above. It is 
equivalent to the following string:
```
--obfuscate-const 0 --obfuscate-ops --obfuscate-branch
```
  
### Analysis of display output and output files  ###

ASSURE produces a report that contains the following information:
- Number of input key bits
- List of obfuscated modules (uniquify is performed), where the number of obfuscated constants, operations and branches
are reported, together with the number of used key bits for each of them.
- List of generated Verilog files. For example, the previous command generates the following output:
```
------------------------------------------------------------------------------------
| Number of input key bits         = 8
------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
| Original module                    = "alu_top"
| Obfuscated module                  = "alu_top_0_obf"
------------------------------------------------------------------------------------
| Number of obfuscated constants     = 0 CONSTANTS  / 0 BITS
| Number of obfuscated branches      = 1 BRANCHES   / 1 BITS
| Number of obfuscated operations    = 3 OPERATIONS / 3 BITS
| Number of module logic key bits    = 4 BITS
| Current number of used key bits    = 4 BITS
------------------------------------------------------------------------------------
| 0.CORRECT KEY = wrappers/0/alu_top_0_obf_golden_wrap.v
------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
| alu_top_0_obf                  | File = "hdl/alu_top_0_obf.v"
------------------------------------------------------------------------------------
``` 
In each module:
- `Original module` is the original module in the input design
- `Obfuscated module` is the resulting instance in the obfuscated design
- `Number of module logic key bits` represents the number of key bits used for the module logic (excluding submodules)
- `Current number of used key bits` represents the progressive number of modules used for obfuscation. For the top
module, it represents the total number of key bits used for the entire design.
- `0.CORRECT KEY =` lists the file where the current module is wrapped to have the same interface as the original one
and the correct key is given for validation.

Indeed, ASSURE produces three folders:
- `hdl` contains the list of files with the obfuscated modules.
- `scripts` contains the script for formal verification with Synopsys Formality
- `wrappers` contains the wrappers around the obfuscated modules

### Formal Verification and RTL simulation ###

Formal verification of the obfuscated design mentioned above can be run in the directory where ASSURE has been executed
as follows:
```
$ fm_shell -f scripts/0/alu_top_0_obf_golden_verify.tcl
```

The designer can also change the key value in the wrapper file to test alternative cases where a wrong key (i.e., a key
different from the one used for obfuscation) is inserted. 

The same wrapper file, together with the ones describing the obfuscated modules, can replace the original module in the 
testbench for RTL validation.  

## Advanced use of ASSURE ## 

ASSURE also feature a single option (`--obfuscate`) to apply all obfuscation techniques mentioned above. It is 
equivalent to the following string:
```
--obfuscate-const 0 --obfuscate-ops --obfuscate-branch
```

However, the analysis is performed in deep-first search and obfuscation stops when the number of available key bits is
reached. For example, when executing the following command:

```
   $ python3 assure.py alu.v --top alu_top.v --locking-key locking_key.txt --obfuscate
```

ASSURE uses only 4 bits even if the entire design requires 12 bits for obfuscation. Indeed, after obfuscating the three
operations and the ternary operator, there are no enough bits to obfuscate also the 8-bit constant. So, ASSURE offers 
two alternatives:
- full obfuscation
- selective obfuscation

### Full obfuscation ###

It is possible to apply obfuscation beyond the key limit by specifying the option `--obfuscate-entire-design`. For 
example, the previous design can obfuscate all elements as follows:

```
   $ python3 assure.py alu.v --top alu_top.v --locking-key locking_key.txt --obfuscate --obfuscate-entire-design
```
The resulting design uses 12 bits that are obtained by replicating the input locking key as many times as needed.

### Selective obfuscation ###

It is also possible to exclude some portions of the original design from obfuscation to spare key bits that can be used
for other parts of the design. This is achieved by specifying custom pragrams. For example, the previous design can be
modified as follows:
 ```
module alu_top(in1, in2, in3, sel, out1, out2);
   input  [7:0] in1;
   input  [7:0] in2;
   input  [7:0] in3;
   input        sel;
   
   output [7:0] out1;
   output [7:0] out2;

(* obfuscation_off *) 
   assign out1 = sel ? in1 + in2 : in1 - in2;
(* obfuscation_on *) 
   assign out2 = in3 * 8'd12;

endmodule 
```
In this case, the first `assign` is excluded from obfuscation and the key bits can be used for the constant. However, 
the multiplication is not obfuscated because there are no other bits.
 

-----------------------

### Contact ###

Christian Pilato (Politecnico di Milano): [christian.pilato@polimi.it](christian.pilato@polimi.it)

Ramesh Karri (New York University): [rkarri@nyu.edu](rkarri@nyu.edu)

Siddharth Garg (New York University): [siddharth.garg@nyu.edu](siddharth.garg@nyu.edu)

