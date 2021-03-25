
# renderer.rb

class RenderVerilog 
	attr_reader :template, :rm

	def initialize(rm)
		@template = __dir__+'/verilog.erb'
		@rm = rm
	end

	#str_list[-1].chomp!(',')
	#str_list

	def get_registers(type)
		str_list = Array.new
		case type
			when "port"
				@rm.registers.each do |reg|
					if reg.type == "reg_port"
						str = "output [#{reg.width-1}:0] #{reg.get_name(:reg)}"
						str_list << str
					end
				end
			when "wire"
				@rm.registers.each do |reg|
					if reg.type == "reg_port"
						str = "assign #{reg.get_name(:reg)} = {"
						reg.bitfields.reverse.each do |bf| 
							if bf
								field = bf[:field]
								str += (field.width > 1) ? "#{field.get_name(:reg)}[#{bf[:idx]}]," :
								                           "#{field.get_name(:reg)},"
							else 
								str += "1'b0,"
							end
						end
						str.chomp!(",")
						str+="}"
						str_list << str
					end
				end
		end
		str_list
	end

	def get_inputs
		str_list = Array.new
		@rm.registers.each do |reg|
			reg.fields.each do |field|
				if field.type == "ro"
					str = (field.width==1)? "input #{field.get_name(:reg)}" :
					                        "input #{field.get_inst_str} #{field.get_name(:reg)}"
					str_list << str
				end
			end
		end
		str_list
	end

	def get_outputs(type)
		str_list = Array.new
		@rm.registers.each do |reg|
			reg.fields.each do |field|
				if ["w1trg","rw"].member?(field.type)
					idx = field.get_idx_str
					initial_str = "#{field.width}'d#{field.initial_value}"
					case type
						when "port"
							str = (field.width ==1 ) ? "output reg #{field.get_name(:reg)}" :
							                           "output reg #{field.get_inst_str} #{field.get_name(:reg)}"
						when "reg"
							str = "reg #{field.get_inst_str} #{field.get_name(:reg)}"
						when "reset"
							str = "#{field.get_name(:reg)} <= #{initial_str}"
						when "wire"
							# mask is a 2-1 mux
							# 	old_data & !sel | new_data & sel

							case field.type
								when "rw"    then hold_value = "#{field.get_name(:reg)}"
								when "w1trg" then hold_value = field.initial_value
							end
							enable_str = field.wr_enable ? "(#{reg.name}_en && #{field.wr_enable})" :
							                               "#{reg.name}_en"
							str = "wire #{field.get_inst_str} #{field.get_name(:next)} = sw_rst ? #{initial_str} : #{enable_str} ? ((~reg_mask[#{idx}] & reg_wdat[#{idx}]) | (reg_mask[#{idx}] & #{field.get_name(:reg)})) : #{hold_value}"
						when "active"
							str    = "#{field.get_name(:reg)} <= #{field.get_name(:next)}"   
					end
					str_list << str
				end
			end
		end
		str_list
	end

	def get_read_mux(reg)
		str_list = Array.new
		reg.fields.each do |field|
			idx = field.get_idx_str
			str = "[#{idx}]= #{field.get_name(:reg)}"
			str_list << str
		end
		str_list
	end

	def get_address_en()
		addr_list = Array.new
		@rm.registers.each do |reg|
			str = "assign #{reg.name}_en = reg_wr && (reg_wr_addr == #{reg.addr})"
			addr_list << str
		end
		addr_list
	end
	
	def render
		ERB.new(File.read(@template)).result(binding)
	end
end