# Ruby Reg
Customizable Verilog Register Generator written in Ruby

## What this does
* Reads a basic excel sheet defining registers
* Creates a single flat verilog register file output
* Implements a very basic register structure than can be extended on
* Allows for easy user customization using ERB (enbeded ruby) template files

## What this isn't
* A complex tool that will deal with systemVerilog verification

# Rubyreg

See the example folder and  makefile for usage as well as formatting
```
cd example
make regs
```

# Supported Register Types
* external/reserved
* reg_port - generates a port with the full undecoded register value
* 
# Supported Field Types
* ro - Read Only - creates input ports for the register fields that go directly to the read mux (no physical register)
* rw - Read/Write - Creates a register and associated output port
* w1trig - Write 1 to trigger - Creates a single clock trigger when a 1 is written to the field

# Special columes
* write enable - The value here is ANDED with the register write enable for the field.

