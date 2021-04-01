class RenderDecoder

	attr_reader :template, :rm

	def initialize(rm,genfile)
		@template = __dir__+'/decoder.erb'
		@rm = rm

		outfile = "#{File.dirname(genfile)}/#{File.basename(genfile,'.v')}_decoder.v"
		puts "\tDecoder: Rendering decoder to #{outfile}"

		File.open(outfile,"w").puts render()

	end

	def get_registers(type)
		str_list = Array.new
		case type
			when "wire"
				@rm.registers.each do |reg|
					str = "wire [#{reg.width-1}:0] #{reg.get_name(:alias)}_val; assign #{reg.get_name(:alias)}_val = {"
					reg.bitfields.reverse.each do |bf| 
						if bf
							field = bf[:field]
							str += (field.width > 1) ? "#{field.get_name(:decoder)}[#{bf[:idx]}]," :
							                           "#{field.get_name(:decoder)},"
						else 
							str += "1'b0,"
						end
					end
					str.chomp!(",")
					str+="}"
					str_list << str
				end
			when "aliases"
				@rm.registers.each do |reg|
					str = "localparam #{reg.get_name(:alias)}=#{reg.addr}"
					str_list << str
				end
		end
		str_list
	end

	def get_outputs(type)
		str_list = Array.new
		@rm.registers.each do |reg|
			reg.fields.each do |field|
				if ["w1trg","rw","ro"].member?(field.type)
					idx = field.get_idx_str
					initial_str = "#{field.width}'d#{field.initial_value}"
					case type
						when "reg"
							str = "reg #{field.get_inst_str} #{field.get_name(:decoder)} = #{initial_str}"
					end
					str_list << str
				end
			end
		end
		str_list
	end

	def render()
		ERB.new(File.read(@template)).result(binding)
	end

end