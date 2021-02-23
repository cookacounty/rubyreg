
# renderer.rb

class RenderVerilog 
	attr_reader :template, :rm

	def initialize(rm)
		@template = File.read(__dir__+'/verilog.erb')
		@rm = rm
	end

	#str_list[-1].chomp!(',')
	#str_list

	def get_registers(type)
		str_list = Array.new
		case type
			when "port"
				@rm.registers.each do |reg|
					str = "output [#{reg.width-1}:0] reg_#{reg.addr_hex},"
					str_list << str
				end
			when "wire"
				@rm.registers.each do |reg|
					reg.fields.each do |field|
						case field.type
							when "ro" then fieldname = "#{field.name}"
							else           fieldname = "r_#{field.name}"
						end
						str = "assign reg_#{reg.addr_hex}[#{field.get_idx_str}] = #{fieldname}"
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
					if field.width ==1
						str = "input #{field.name},"
					else
						str = "input #{field.get_inst_str} #{field.name},"
					end
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
					case type
						when "port"
							if field.width ==1
								str = "output reg r_#{field.name},"
							else
								str = "output reg #{field.get_inst_str} r_#{field.name},"
							end
						when "reg"
							str = "reg #{field.get_inst_str} r_#{field.name}"
						when "reset"
							str = "r_#{field.name} <= #{field.initial_value}"
						when "idle"
							str = "r_#{field.name} <= #{field.name}"
						when "wire"
							# mask is a 2-1 mux
							# 	old_data & !sel | new_data & sel

							case field.type
								when "rw"    then hold_value = "r_#{field.name}"
								when "w1trg" then hold_value = field.initial_value
							end
							str = "wire #{field.get_inst_str} #{field.name}_nxt = sw_rst ? #{field.initial_value} : #{reg.name}_en ? ((reg_mask[#{idx}] & reg_wdat[#{idx}]) | (~reg_mask[#{idx}] & r_#{field.name})) : #{hold_value}"
						when "active"
							str    = "r_#{field.name} <= #{field.name}_nxt"   
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
			case field.type
				when "ro" then str = "[#{idx}]= #{field.name}"
				else           str = "[#{idx}]=r_#{field.name}"
			end
			
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
		ERB.new(template).result(binding)
	end
end