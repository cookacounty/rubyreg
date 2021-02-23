class Regmap
	@addr_width
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
		puts nr
	end
	def addfield(name: "", assignment: 0, type: "", initial_value: 0)
		nf = RegisterField.new(register: @current_reg,name: name,assignment: assignment,type: type,initial_value: initial_value)
		@current_reg.addfield(nf)
		puts nf
	end

end

class Register
	attr_accessor :addr
	attr_accessor :name
	attr_accessor :fields
	attr_accessor :rm

	def initialize(rm: [],name: "",addr: 0)
		@rm=rm
		@addr=addr
		@name=name
		@fields = Array.new
	end
	def to_s
		"Register Addr: #{@addr} Name: #{@name}"
	end
	def addfield(field)
		@fields << field
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
		@initial_value = initial_value

		get_indexes(assignment)

		tf = check_type(type)
		if !tf
			raise "Invalid register Name #{name} type #{type} #{register.name}"
		else
			@type = type
		end
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
				@width = msb-lsb
			else
				raise "Bad width"
		end
	end
	def to_s
		"\tRegister Field Name: #{@name} Type: #{@type} Assignment: #{@assignment}"
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