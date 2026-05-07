# Ruby Reg

![Ruby Reg logo](assets/logo.svg)

Ruby Reg is a small Ruby-based Verilog register-map generator. It reads an
XLSX register description and emits a single flat Verilog register file.

The generator is intentionally simple: the register model is easy to inspect,
and the Verilog output is produced through ERB templates so projects can tune
the generated style when needed.

## Features

* Reads a basic XLSX spreadsheet defining registers and fields
* Generates flat Verilog register-map logic
* Supports software read/write fields, read-only inputs, trigger fields, and
  hardware/software read-write fields
* Supports whole-register customer and factory software access locks
* Supports project customization through ERB templates

## Non-Goals

Ruby Reg is not a full SystemVerilog register abstraction or verification
framework. It is meant to generate straightforward register logic that can be
reviewed, customized, and integrated into a larger RTL project.

## Quick Start

Generate the example register map:

```sh
cd example
make regs
```

Equivalent direct command:

```sh
ruby ../lib/rubyreg.rb \
  -i regmap_example.xlsx \
  -o regmap_example.v \
  -m regmap_example \
  -c rubyreg.yml
```

## Spreadsheet Format

Ruby Reg parses the first sheet of the input workbook. The XLSX input should
start with register data on the first row; do not include a header row in the
workbook that is passed to the generator.

Each register starts on a row with a register name. Additional fields for that
same register can be added on following rows by leaving the register-name
column blank.

| Column | Meaning | Example |
| --- | --- | --- |
| 1 | Register name | `trim_reg` |
| 2 | Register offset | `0x01`, `0b0001`, `0d1`, `1` |
| 3 | Register properties | `customer`, `reg_port factory` |
| 4 | Field name | `trim` |
| 5 | Field bit assignment | `0`, `7:4` |
| 6 | Field type | `rw`, `ro`, `w1trg`, `hwrw` |
| 7 | Initial value | `0`, `0x3` |
| 8 | Description | Free-form text |
| 9 | Optional write enable expression | `trim_we` |
| 10 | Unused | Leave blank |
| 11 | Optional destination | `top` |

## Register Properties

The third column contains register properties. Multiple properties can be
separated with spaces or commas. Property names are parsed case-insensitively,
but lowercase names are recommended in source spreadsheets.

Register type properties:

| Property | Behavior |
| --- | --- |
| `external` | Fields are implemented as read-only inputs, even when listed as `rw` |
| `reserved` | The register and its fields are ignored |
| `reg_port` | Generates an output port containing the full undecoded register value |

Access lock properties:

| Property | Behavior |
| --- | --- |
| `customer` | Software reads and writes require `cust_access == 1` |
| `factory` | Software reads and writes require `fact_access == 1` |

A register can have at most one access lock. For example, `customer factory`
is rejected because the generated register can only use one lock signal.

Valid property examples:

```text
customer
factory
reg_port customer
reg_port,factory
external factory
reserved customer
```

## Field Types

| Type | Behavior |
| --- | --- |
| `ro` | Read-only input wired directly into the read mux; no storage register is generated |
| `rw` | Software read/write storage register and output port |
| `w1trg` | Write-one trigger; creates a one-clock trigger when software writes `1` |
| `hwrw` | Hardware/software read-write field with hardware write input pins |

## Access-Lock Behavior

Generated Verilog always includes these input pins, even when no registers are
locked:

```verilog
input            cust_access
input            fact_access
```

Customer and factory locks apply to the whole register. If the lock input is
low, software reads return zero and software writes do not update the register.
Unlocked registers behave as before.

The hardware write side of `hwrw` fields is not gated by `cust_access` or
`fact_access`. Only the software read and software write paths are gated.

## Examples

### Unlocked Read/Write Register

Spreadsheet rows:

```text
plain_reg,0x00,,plain_rw,0,rw,0,Plain software register,,,
```

Representative generated write enable:

```verilog
assign plain_reg_en = reg_wr && (reg_wr_addr == 0);
```

### Customer-Locked Register

Spreadsheet rows:

```text
cust_reg,0x01,customer,cust_rw,0,rw,0,Customer locked register,,,
```

Representative generated write enable:

```verilog
assign cust_reg_en = reg_wr && (reg_wr_addr == 1) && cust_access;
```

Representative generated read mux:

```verilog
1: begin
  if (cust_access) begin
    reg_rdat_a[0]= r_cust_rw;
  end
end
```

When `cust_access` is low, `reg_rdat_a` remains at the default `8'b0`.

### Factory-Locked Register

Spreadsheet rows:

```text
fact_reg,0x02,factory,fact_rw,0,rw,0,Factory locked register,,,
```

Representative generated write enable:

```verilog
assign fact_reg_en = reg_wr && (reg_wr_addr == 2) && fact_access;
```

Representative generated read mux:

```verilog
2: begin
  if (fact_access) begin
    reg_rdat_a[0]= r_fact_rw;
  end
end
```

### `reg_port` With Access Lock

Spreadsheet rows:

```text
port_reg,0x03,reg_port customer,port_status,0,ro,0,Status bit,,,
```

Representative generated ports and logic:

```verilog
input            port_status
output [7:0]     reg_0x03

assign port_reg_en = reg_wr && (reg_wr_addr == 3) && cust_access;
assign reg_0x03 = {1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,port_status};
```

The `reg_port` output is still generated. The customer lock gates software
read/write access to the register address.

### Locked Register With Field Write Enable

Spreadsheet rows:

```text
we_reg,0x07,customer,we_field,0,rw,0,Customer locked write-enable register,field_we,,
```

Representative generated logic:

```verilog
assign we_reg_en = reg_wr && (reg_wr_addr == 7) && cust_access;

wire  we_field_nxt =
  sw_rst ? 1'd0 :
  (we_reg_en && field_we) ?
    ((~reg_mask[0] & reg_wdat[0]) | (reg_mask[0] & r_we_field)) :
    r_we_field;
```

The register-level lock and field-level write enable are both required for a
software write to update the field.

### Customer-Locked `hwrw` Register

Spreadsheet rows:

```text
hw_reg,0x05,customer,hw_field,0,hwrw,0,Customer locked hwrw register,,,
```

Representative generated ports:

```verilog
input            hw_field_hw_wr
input            hw_field_hw_val
output reg       r_hw_field
```

Representative generated next-state logic:

```verilog
assign hw_reg_en = reg_wr && (reg_wr_addr == 5) && cust_access;

wire  hw_field_nxt =
  sw_rst ? 1'd0 :
  hw_field_hw_wr ? hw_field_hw_val :
  (hw_reg_en ?
    ((~reg_mask[0] & reg_wdat[0]) | (reg_mask[0] & r_hw_field)) :
    r_hw_field);
```

The software write path is customer-gated through `hw_reg_en`. The hardware
write path, `hw_field_hw_wr`, is not gated by `cust_access`.

### Factory-Locked External Register

Spreadsheet rows:

```text
external_reg,0x06,external factory,external_ro,0,rw,0,Factory external register,,,
```

Representative generated behavior:

```verilog
input            external_ro
assign external_reg_en = reg_wr && (reg_wr_addr == 6) && fact_access;
```

Because the register has the `external` property, the field is treated as
read-only input logic even though the field row says `rw`.

## Test Environment

The test suite uses Ruby's Minitest through Rake. Test files live under
`test/`, and the access-lock fixture files live under `test/fixtures/`.

Important fixture files:

* `test/fixtures/access_lock_test.csv` - readable source fixture with a header
* `test/fixtures/access_lock_full_test.xlsx` - XLSX fixture used by generator tests

Install dependencies:

```sh
bundle install
```

Run the full test suite:

```sh
bundle exec rake test
```

Run the access-lock unit tests directly:

```sh
ruby -Itest test/render_verilog_access_lock_test.rb
```

Run the XLSX fixture test directly:

```sh
ruby -Itest test/xlsx_fixture_generation_test.rb
```

Run lint and tests through the default Rake task:

```sh
bundle exec rake
```

To manually generate Verilog from the access-lock XLSX fixture:

```sh
ruby lib/rubyreg.rb \
  -i test/fixtures/access_lock_full_test.xlsx \
  -o test/fixtures/access_lock_full_test.v \
  -m access_lock_full_test \
  -c config/default.yml
```

## Related Projects

Ruby Reg was inspired by RgGen, an open source register-map generation tool
with a broader feature set:

https://github.com/rggen/rggen
