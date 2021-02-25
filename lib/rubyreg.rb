# frozen_string_literal: true

require_relative "rubyreg/version"
require_relative "rubyreg/load_excel"
require_relative "rubyreg/load_config"
require_relative "rubyreg/RenderVerilog"
require_relative "rubyreg/Regmap"
require_relative "rubyreg/AutoWire"

require 'erb'
require 'roo'
require 'optparse'
require 'byebug'
require 'fileutils'



module Rubyreg
  class Error < StandardError; end
  # Your code goes here...
end


def parse_opts(args)
  options = {verbose: false, infile: 'myregmap.xlsx', outfile: 'out.v', modulename: 'regmap', config: nil}
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
    opts.on("-m", "--module MODULENAME", "Name of the verilog module") do |modulename|
      options[:modulename] = modulename
    end
    opts.on("-c", "--config CONFIGFILE", "Path to configuration file") do |config|
      options[:config] = config
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

load_config

# Read the Excel
rm = load_excel($options[:infile])
rv = RenderVerilog.new(rm)


ps = rm.xlsx.sheet(0).parse

File.open($options[:infile]+".csv","w") {|f| ps.each {|col| f.puts col.inspect}}
ps = ps.map{|row| row.map {|col| d = col ? col : ""}}

# Render the register map
FileUtils.rm($options[:outfile], force: true)
File.open($options[:outfile],"w").puts rv.render
FileUtils.chmod("ugo-w",$options[:outfile])

if $config.autowire_enable
  AutoWire.new(rm)
end