
# renderer.rb

class RenderVerilog 
	attr_reader :template, :rm

	def initialize(rm)
		@template = File.read(__dir__+'/verilog.erb')
		@rm = rm
	end


	def get_inputs
		input_list = Array.new
		@rm.registers.each do |reg|
			reg.fields.each do |field|
				if field.type == "ro"
					if field.width ==1
						str = "input #{field.name}"
					else
						str = "input [#{field.width-1}:0] #{field.name}"
					end
					input_list << str
				end
			end
		end
		input_list
	end

	def get_outputs
		output_list = Array.new
		@rm.registers.each do |reg|
			reg.fields.each do |field|
				if ["w1trg","rw"].member?(field.type)
					if field.width ==1
						str = "output #{field.name}"
					else
						str = "output [#{field.width-1}:0] #{field.name}"
					end
					output_list << str
				end
			end
		end
		output_list
	end

	def get_output_reg(type)
		output_list = Array.new
		@rm.registers.each do |reg|
			reg.fields.each do |field|
				if ["w1trg","rw"].member?(field.type)
					idx = field.get_idx_str
					case type
						when "reg"
							str = "reg [#{idx}] #{field.name}"
						when "reset"
							str    = "#{field.name} <= #{field.initial_value}"
						when "idle"
							str    = "#{field.name} <= #{field.name}"
						when "active"
							# mask is a 2-1 mux
							# 	old_data & !sel | new_data & sel

							case field.type
								when "rw"    then hold_value = field.name
								when "w1trg" then hold_value = field.initial_value
							end

							mask_fun = "(reg_mask[#{idx}] & reg_wdat[#{idx}]) | (~reg_mask[#{idx}] & #{field.name})"

							str    = "#{field.name} <= #{reg.name}_en ? (#{mask_fun}) : #{hold_value}"   
					end
					output_list << str
				end
			end
		end
		output_list
	end

	def get_read_mux(reg)
		output_list = Array.new
		reg.fields.each do |field|
			idx = field.get_idx_str
			str = "reg_rdat_nxt[#{idx}]=#{field.name}"
			output_list << str
		end
		output_list
	end

	def get_address_en()
		addr_list = Array.new
		@rm.registers.each do |reg|
			str = "assign #{reg.name}_en = reg_wr && (addr == #{reg.addr})"
			addr_list << str
		end
		addr_list
	end
	
	def render
		ERB.new(template).result(binding)
	end
end