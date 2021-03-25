class AutoWire
	attr_reader :template, :rm

	def initialize(rm)
		@rm = rm
		puts "Autowire started"
		$config.autowire_modules.each do |f|
			outfile = "#{File.dirname(f)}/#{File.basename(f,'.erb')}"
			puts "\tAutowire: Rendering #{f} to #{outfile}"

			FileUtils.rm(outfile, force: true)
			File.open(outfile,"w").puts render(f)
			FileUtils.chmod("ugo-w",outfile)

		end
	end

	def autoroute(type)
		str = []
		str_regs = []

		@rm.registers.each do |reg|

			case type
				when :reg_wires
					str << "wire [#{reg.width-1}:0] #{reg.get_name(:reg)};" if reg.type == "reg_port"
				when :reg_instantiation
					str << ",.#{reg.get_name(:reg)}(#{reg.get_name(:reg)})" if reg.type == "reg_port"
				else
					reg.fields.each do |field|				
						case type
							when :instantiation
								str << ", .#{field.get_name(:reg)}(#{field.get_name(:reg)})"
							when :wires
								str << "wire #{field.get_inst_str}  #{field.get_name(:reg)};" if field.destination != "top"
							when :ports
								str << ", output #{field.get_inst_str}  #{field.get_name(:reg)}" if field.destination == "top"
							when :top_ports
								str << ", output #{field.get_inst_str}  #{field.get_name(:autowire)}" if field.destination == "top"
							when :top_instantiation
								str << ", .#{field.get_name(:reg)}(#{field.get_name(:autowire)})" if field.destination == "top"
							else
								raise "Invalid autoroute type #{type.inspect}"
						end
					end
				end
		end

		str_final = ["// -> Start AutoRoute #{type}"]
		str_final << str
		str_final << "// <- End AutoRoute #{type}"
		str_final.join("\n")
	end

	def render(fname)
		ERB.new(File.read(fname)).result(binding)
	end
end