# frozen_string_literal: true

require "minitest/autorun"
require "ostruct"
require "erb"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "rubyreg/Regmap"
require "rubyreg/load_excel"
require "rubyreg/RenderVerilog"

$options = { modulename: "access_lock_test", verbose: false }
$config = OpenStruct.new(register_width: 8, dual_channel: true)

def build_regmap(rows)
  rm = Regmap.new(nil)
  $ignored_reg = false
  rows.each { |row| parse_row(rm, row) }
  rm.assign_bitfields
  rm.run_checks
  rm
end

def render_regmap(rows)
  RenderVerilog.new(build_regmap(rows)).render
end
