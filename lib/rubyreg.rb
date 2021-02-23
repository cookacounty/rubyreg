# frozen_string_literal: true

require_relative "rubyreg/version"
require_relative "rubyreg/load_excel"
require_relative "rubyreg/RenderVerilog"
require_relative "rubyreg/Regmap"

require 'erb'
require 'roo'
require 'optparse'


module Rubyreg
  class Error < StandardError; end
  # Your code goes here...
end


# default options:

 
def parse_opts(args)
  options = {verbose: false, infile: 'myregmap.xlsx', outfile: 'out.v'}
  opts = OptionParser.new do |opts|
    # banner and separator are the usage description showed with '--help' or '-h'
    opts.banner = "Usage: rubyreg.rb [options] [output file]"
    opts.separator "Reads input XLS, generates output verilog"
    opts.separator "Options:"
    # options (switch - true/false)
    opts.on("-i", "--infile INFILE", "Path to input file") do |infile|
      options[:infile] = infile
    end
    opts.on("-o", "--outfile OUTFILE", "Path to output file") do |outfile|
      options[:outfile] = outfile
    end
    opts.on("-v", "--verbose", "Verbose mode") do |v|
      options[:verbose] = v
    end
  end

  begin
    opts.parse(args)
  rescue Exception => e
    puts "Exception encountered: #{e}"
    exit 1
  end

  options
end

$options = parse_opts(ARGV)
puts "User Options"
puts "\t#{$options.inspect}"

rm = load_excel($options[:infile])
rv = RenderVerilog.new(rm)

fout=File.open($options[:outfile],"w")
fout.puts rv.render