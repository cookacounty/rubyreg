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
					str << "   logic [#{reg.width-1}:0] #{reg.get_name(:reg)};" if reg.type == "reg_port"
				when :reg_instantiation
					str << "   ,.#{reg.get_name(:reg)}(#{reg.get_name(:reg)})" if reg.type == "reg_port"
				else
					reg.fields.each do |field|				
						case type
							when :instantiation
                                if field.type == "hwrw" 
                                    str << "      ,.#{field.get_name(:autowire)}_hw_wr(#{field.get_name(:autowire)}_hw_wr)"
                                    str << "      ,.#{field.get_name(:autowire)}_hw_val(#{field.get_name(:autowire)}_hw_val)"
                                end
								str << "      ,.#{field.get_name(:reg)}(#{field.get_name(:reg)})"
							when :wires
                                if field.type == "hwrw" 
					                str << "   logic       #{field.get_name(:autowire)}_hw_wr;"
                                    if field.width == 1
                                        str << "   logic       #{field.get_name(:autowire)}_hw_val;" 
                                    else
					                    str << "   logic #{field.get_inst_str} #{field.get_name(:autowire)}_hw_val;" 
                                    end
                                end
                                if (field.destination != "top" && field.destination != "top_inst") 
                                    if field.width == 1
								        str << "   logic       #{field.get_name(:reg)};" 
                                    else
								        str << "   logic #{field.get_inst_str} #{field.get_name(:reg)};" 
                                    end
                                end
							when :ports
                                if (field.destination == "top" || field.destination == "top_inst") 
                                    if field.width == 1
								        str << "   ,output       #{field.get_name(:reg)}" if field.type != "ro"   
								        str << "   ,input        #{field.get_name(:reg)}" if field.type == "ro"  
                                    else
								        str << "   ,output #{field.get_inst_str} #{field.get_name(:reg)}" if field.type != "ro"   
								        str << "   ,input  #{field.get_inst_str} #{field.get_name(:reg)}" if field.type == "ro"  
                                    end
                                end
							when :top_ports
                                if (field.type != "ro" && field.destination == "top")
                                    if field.width == 1
								        str << "   ,output       #{field.get_name(:autowire)}" 
                                    else
								        str << "   ,output #{field.get_inst_str} #{field.get_name(:autowire)}" 
                                    end
                                end
                                if (field.type == "ro" && field.destination == "top")
                                    if field.width == 1
								        str << "   ,input        #{field.get_name(:autowire)}" 
                                    else
								        str << "   ,input  #{field.get_inst_str} #{field.get_name(:autowire)}" 
                                    end
                                end
							when :top_instantiation
                                if (field.destination == "top" || field.destination == "top_inst")
								    str << "      ,.#{field.get_name(:reg)}(#{field.get_name(:autowire)})" 
                                end
							when :top_wires
                                if field.destination == "top_inst"
                                    if field.width == 1
								        str << "   logic       #{field.get_name(:autowire)};"   
                                    else
								        str << "   logic #{field.get_inst_str} #{field.get_name(:autowire)};"   
                                    end
                                end
							else
								raise "Invalid autoroute type #{type.inspect}"
						end
					end
				end
		end

		str_final = ["      // -> Start AutoRoute #{type}"]
		str_final << str
		str_final << "      // <- End AutoRoute #{type}"
		str_final.join("\n")
	end

	def render(fname)
		ERB.new(File.read(fname)).result(binding)
	end
end
