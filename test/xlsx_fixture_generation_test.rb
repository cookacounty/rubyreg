# frozen_string_literal: true

require_relative "test_helper"
require "roo"

class XlsxFixtureGenerationTest < Minitest::Test
  def test_access_lock_xlsx_fixture_loads_and_generates_verilog
    xlsx = File.expand_path("fixtures/access_lock_full_test.xlsx", __dir__)
    verilog = RenderVerilog.new(load_excel(xlsx)).render

    assert_includes verilog, "input            cust_access"
    assert_includes verilog, "input            fact_access"
    assert_includes verilog, "assign cust_reg_en = reg_wr && (reg_wr_addr == 1) && cust_access;"
    assert_includes verilog, "assign fact_reg_en = reg_wr && (reg_wr_addr == 2) && fact_access;"
    assert_includes verilog, "wire  hw_field_nxt = sw_rst ? 1'd0 : hw_field_hw_wr ? hw_field_hw_val :"
    refute_includes verilog, "hw_field_hw_wr && cust_access"
  end
end
