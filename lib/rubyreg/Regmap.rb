class Regmap
	attr_accessor :registers
	@current_addr
	@current_reg

	def initialize
		@current_addr = 0
		@registers = Array.new
	end

	def addreg(name: "",offset: nil)
		if !offset
			addr = @current_addr
			@current_addr=@current_addr+1
		else
			# Check the address
			addr = toint(offset)
			if !addr
				raise "Invalid address offset format #{name} #{offset}"
			end
			@current_addr = addr + 1
		end
		nr = Register.new(rm:self,name:name,addr:addr)
		@current_reg = nr
		@registers.append(nr)
		puts nr if $options[:verbose]
	end
	def addfield(name: "", assignment: 0, type: "", initial_value: 0)
		if !["reserved"].member?(type)
			nf = RegisterField.new(register: @current_reg,name: name,assignment: assignment,type: type,initial_value: initial_value)
			@current_reg.addfield(nf)
			puts nf if $options[:verbose]
		end
	end
	def assign_bitfields
		@registers.each {|reg| reg.assign_bitfields}
	end

end

class Register
	attr_accessor :addr
	attr_accessor :name
	attr_accessor :fields
	attr_accessor :rm
	attr_accessor :width
	attr_accessor :bitfields

	def initialize(rm: [],name: "",addr: 0)
		@rm=rm
		@addr=addr
		@fields = Array.new
		@width = 8

		name.strip!
		name_sub = name.strip.gsub(" ","_")

		puts "WARN: replaces spaces with _ in #{name} to #{name_sub}" if name != name_sub
		@name = name_sub
	end
	def to_s
		"Register Addr: #{@addr} Name: #{@name}"
	end
	def addfield(field)
		@fields << field
	end
	def addr_hex(places: 2)
		sprintf("0x%0#{places}X", @addr) #=> "0A"
	end
	def assign_bitfields
		bitfields = Array.new(@width)
		@fields.each do |field|
			regidx = 0
			(field.lsb..field.msb).each do |i|
				raise "Bitfield already assigned in Register #{@addr} #{@name} Field #{field.name}" if bitfields[i]
				bitfields[i] = "#{field.name}[#{regidx}]" if field.width > 1
				bitfields[i] = "#{field.name}"            if field.width == 1
				regidx+=1
			end
		end
		puts "Bitfield assignment: #{bitfields.inspect}" if $options[:verbose]
	end
end

class RegisterField
	attr_accessor :name
	attr_accessor :assignment
	attr_accessor :register
	attr_accessor :type
	attr_accessor :msb
	attr_accessor :lsb
	attr_accessor :width
	attr_accessor :initial_value

	def initialize(register: [],name: "",assignment: -1, type: "", initial_value: 0)
		@register=register
		@name = name
		@assignment = assignment
		@initial_value = toint(initial_value)

		get_indexes(assignment)

		raise "Invalid register Name #{name} type #{type} #{register.name}" if !check_type(type)
		@type = type.strip

		raise "Invalid register initial value #{name} value #{initial_value.inspect} #{register.name}" if !initial_value

		raise "Invalid register width #{name} width #{assignment.inspect} #{register.name}" if @width < 1

	end
	def check_type(type)
		if type
			["rw","ro","w1trg","reserved"].member?(type.strip)
		else
			false
		end
	end
	def get_indexes(assignment)
		as = assignment.split(":")
		case as.length
			when 1
				@msb = as[0].to_i
				@lsb = as[0].to_i
				@width = 1
			when 2
				@msb = as[0].to_i
				@lsb = as[1].to_i
				@width = msb-lsb+1
			else
				raise "Bad width"
		end
	end
	def get_idx_str()
		if @width > 1
			idx = "#{self.msb}:#{self.lsb}"
		else 
			idx = "#{self.msb}"
		end
	end
	def get_inst_str()
		if @width > 1
			str = "[#{@width-1}:0]"
		else
			str = ""
		end
	end
	def to_s
		"\tRegister Field Name: #{@name} Type: #{@type} Assignment: #{@assignment} MSB: #{@msb} LSB: #{@lsb} Width: #{@width}"
	end
end


def tohex(num)	
	return sprintf("%02x", 10).upcase
end

def toint(myin)
		# Check the address
	case myin
		when Integer
			intnum = myin
		when String
			myin.strip!
			case myin
				when /^0x[A-Fa-f0-9]+$/
					intnum = Integer(myin)
				when /^[0-9]$/
					intnum = Integer(myin)
				else
					return false
			end
	end

	return intnum

end