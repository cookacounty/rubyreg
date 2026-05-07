# frozen_string_literal: true

require_relative "test_helper"

class RenderVerilogAccessLockTest < Minitest::Test
  ROWS = [
    ["plain_reg", "0x00", nil, "plain_rw", "0", "rw", "0", nil, nil, nil, nil],
    ["cust_reg", "0x01", "customer", "cust_rw", "0", "rw", "0", nil, nil, nil, nil],
    ["fact_reg", "0x02", "factory", "fact_rw", "0", "rw", "0", nil, nil, nil, nil],
    [
      "comma_cust_reg", "0x03", "reg_port,customer", "comma_cust_ro", "0",
      "ro", "0", nil, nil, nil, nil
    ],
    [
      "space_fact_reg", "0x04", "reg_port factory", "space_fact_rw", "0",
      "rw", "0", nil, nil, nil, nil
    ],
    ["hw_reg", "0x05", "customer", "hw_field", "0", "hwrw", "0", nil, nil, nil, nil],
    [
      "external_reg", "0x06", "external, FACTORY", "external_ro", "0",
      "rw", "0", nil, nil, nil, nil
    ],
    ["we_reg", "0x07", "customer", "we_field", "0", "rw", "0", nil, "field_we", nil, nil],
    ["trig_reg", "0x08", "factory", "trig_field", "0", "w1trg", "0", nil, nil, nil, nil],
    [
      "ignored_reg", "0x09", "reserved customer", "ignored_field", "0",
      "rw", "0", nil, nil, nil, nil
    ]
  ].map(&:freeze).freeze

  def setup
    @verilog = render_regmap(ROWS)
  end

  def test_property_parser_accepts_space_comma_case_and_order_variants
    assert_equal [nil, []], parse_register_properties(nil)
    assert_equal ["reg_port", ["customer"]], parse_register_properties("reg_port,customer")
    assert_equal ["reg_port", ["factory"]], parse_register_properties("Factory reg_port")
    assert_equal ["external", ["customer"]], parse_register_properties("external customer")
  end

  def test_parser_rejects_unknown_properties_and_multiple_locks
    bad_property_rows = [
      ["bad_prop", "0x00", "debug", "field", "0", "rw", "0", nil, nil, nil, nil]
    ]
    assert_raises(RuntimeError) do
      build_regmap(bad_property_rows)
    end

    bad_lock_rows = [
      ["bad_lock", "0x00", "customer factory", "field", "0", "rw", "0", nil, nil, nil, nil]
    ]
    assert_raises(RuntimeError) do
      build_regmap(bad_lock_rows)
    end
  end

  def test_access_pins_are_always_rendered
    assert_includes @verilog, "input            cust_access"
    assert_includes @verilog, "input            fact_access"

    unlocked_rows = [
      ["plain_reg", "0x00", nil, "plain_rw", "0", "rw", "0", nil, nil, nil, nil]
    ]
    unlocked_verilog = render_regmap(unlocked_rows)
    assert_includes unlocked_verilog, "input            cust_access"
    assert_includes unlocked_verilog, "input            fact_access"
  end

  def test_customer_register_reads_and_writes_are_gated
    assert_equal 8, @verilog.scan("if (cust_access) begin").length
    assert_includes @verilog, "if (cust_access) begin reg_rdat_a[0]= r_cust_rw; end"
    assert_includes @verilog, "assign cust_reg_en = reg_wr && (reg_wr_addr == 1) && cust_access;"
    assert_includes @verilog, "assign comma_cust_reg_en = reg_wr && (reg_wr_addr == 3) && cust_access;"
    assert_includes @verilog, "assign we_reg_en = reg_wr && (reg_wr_addr == 7) && cust_access;"
    assert_includes @verilog, "(we_reg_en && field_we) ?"
  end

  def test_factory_register_reads_and_writes_are_gated
    assert_equal 8, @verilog.scan("if (fact_access) begin").length
    assert_includes @verilog, "if (fact_access) begin reg_rdat_a[0]= r_fact_rw; end"
    assert_includes @verilog, "if (fact_access) begin reg_rdat_b[0]= r_fact_rw; end"
    assert_includes @verilog, "assign fact_reg_en = reg_wr && (reg_wr_addr == 2) && fact_access;"
    assert_includes @verilog, "assign space_fact_reg_en = reg_wr && (reg_wr_addr == 4) && fact_access;"
    assert_includes @verilog, "assign trig_reg_en = reg_wr && (reg_wr_addr == 8) && fact_access;"
    assert_includes @verilog, "wire  trig_field_nxt = sw_rst ? 1'd0 : trig_reg_en ?"
  end

  def test_plain_register_is_not_gated
    assert_includes @verilog, "assign plain_reg_en = reg_wr && (reg_wr_addr == 0);"
    refute_includes @verilog, "assign plain_reg_en = reg_wr && (reg_wr_addr == 0) &&"
  end

  def test_hwrw_hardware_write_path_is_not_gated_by_customer_access
    assert_includes @verilog,
                    "wire  hw_field_nxt = sw_rst ? 1'd0 : hw_field_hw_wr ? hw_field_hw_val :"
    refute_includes @verilog, "hw_field_hw_wr && cust_access"
  end

  def test_external_register_is_locked_and_forced_to_read_only
    assert_includes @verilog, "assign external_reg_en = reg_wr && (reg_wr_addr == 6) && fact_access;"
    assert_includes @verilog, "input            external_ro"
    refute_includes @verilog, "output reg       r_external_ro"
  end

  def test_reg_port_and_reserved_properties_keep_existing_behavior
    assert_includes @verilog, "output [7:0] reg_0x03"
    assert_includes @verilog, "output [7:0] reg_0x04"
    assert_includes @verilog, "assign reg_0x03 = {"
    refute_includes @verilog, "ignored_reg_en"
    refute_includes @verilog, "ignored_field"
  end
end
