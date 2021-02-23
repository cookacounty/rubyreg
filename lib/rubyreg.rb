# frozen_string_literal: true

require_relative "rubyreg/version"
require_relative "rubyreg/load_excel"
require_relative "rubyreg/write_verilog"
require_relative "rubyreg/Regmap"

require 'erb'
require 'roo'

module Rubyreg
  class Error < StandardError; end
  # Your code goes here...

  def main
  	puts "HI"
  end

end

puts "LOADING EXCEL"
rm = load_excel('myregmap.xlsx')
rv = RenderVerilog.new(rm)

fout=File.open("out.v","w")
fout.puts rv.render