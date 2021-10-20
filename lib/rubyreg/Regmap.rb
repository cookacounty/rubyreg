class Regmap
	attr_accessor :registers, :xlsx
	@current_addr
	@current_reg

	def initialize(xlsx)
		@current_addr = 0
		@registers = Array.new
		@xlsx = xlsx
	end

	def addreg(headings)
		offset = headings[:regoffset]
		if !offset
			addr = @current_addr
			@current_addr=@current_addr+1
		else
			# Check the address
			addr = toint(offset)
			if !addr
				raise "Invalid address offset format #{headings[:regname]} #{offset}"
			end
			@current_addr = addr + 1
		end
		nr = Register.new(rm:self,addr:addr,headings: headings)
		@current_reg = nr
		@registers.append(nr)
		puts nr if $options[:verbose]
	end
	def addfield(headings)
		if !["reserved"].member?(headings[:type])
			nf = RegisterField.new(register: @current_reg, headings: headings)
			@current_reg.addfield(nf)
			puts nf if $options[:verbose]
		end
	end
	def assign_bitfields
		@registers.each {|reg| reg.assign_bitfields}
	end

	def run_checks
		
		# Redundant addresses
		addr = registers.map {|r| r.addr}
		det = addr.detect{ |a| addr.count(a) > 1}
		if det
			raise "Redundant addresses found!! Each Register should have a unique address\n Address number(s) (decimal): #{det}"
		end

	end

end

class Register
	attr_accessor :addr
	attr_accessor :name
	attr_accessor :fields
	attr_accessor :rm
	attr_accessor :width
	attr_accessor :bitfields
	attr_accessor :type

	def initialize(rm: [], addr: 0, headings: [])
		@rm=rm
		@addr=addr
		@fields = Array.new
		@width = $config.register_width
		@type = headings[:regtype]

		name = headings[:regname]
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
	def get_name(type)
		names = {reg: "reg_#{self.addr_hex}", alias: "#{self.name}"}
		names[type]		
	end
	def assign_bitfields
		bitfields = Array.new(@width)
		@fields.each do |field|
			regidx = 0
			(field.lsb..field.msb).each do |i|
				raise "Bitfield already assigned in Register #{@addr} #{@name} Field #{field.name}" if bitfields[i]
				bitfields[i] = {field: field, idx: regidx}
				regidx+=1
			end
		end
		@bitfields = bitfields
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
	attr_accessor :wr_enable
	attr_accessor :destination

	def initialize(register: nil, headings: nil)

		@register=register
		@name = headings[:name]
		@assignment = headings[:assignment]
		@initial_value = toint(headings[:initial_value])
		@type = headings[:type]
		@wr_enable = headings[:wr_enable]
		@destination = headings[:destination]

		raise "Invalid register assignment Name #{@name} assignment #{@assignment} register #{@register.name}\n\t#{headings.inspect}" if !@assignment
		get_indexes(@assignment) if @assignment

		raise "Invalid register Name #{name} type #{@type} #{@register.name}\n\t#{headings.inspect}" if !check_type(@type)
		@type = @type.strip

		# External registers are implemented as "ro"
		@type = "ro" if @register.type == "external"

		raise "Invalid register initial value #{name} value #{@initial_value.inspect} #{@register.name}\n\t#{headings.inspect}" if !@initial_value
		raise "Initial value outside of range #{name} value #{@initial_value.inspect} #{@register.name}\n\t#{headings.inspect}" if !check_initial_value
		raise "Invalid register width #{name} width #{@assignment.inspect} register #{@register.name}\n\t#{headings.inspect}" if @width < 1
		#raise "Invalid register destination  #{name} destination #{@destination .inspect} register #{@register.name}\n\t#{headings.inspect}" if !["top",nil].member?(@destination)

	end
	def check_type(type)
		if type
			["rw","ro","w1trg","reserved"].member?(type.strip)
		else
			nil
		end
	end
	def check_initial_value()
		# Check if the default value is representable by the WL
		max_val = (2**@width)-1
		if (@initial_value > max_val || @initial_value < 0)
			nil
		else
			true
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
	def get_name(type)
		case (self.type)
			when "ro" then names = {reg: "#{@name}",   next: "#{@name}_nxt", autowire: "#{@name}", decoder: "#{@name}"}
			else           names = {reg: "r_#{@name}", next: "#{@name}_nxt", autowire: "#{@name}", decoder: "#{@name}"}
		end
		names[type]
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
			myin.gsub!("_","")
			case myin
				when /^0x[A-Fa-f0-9]+$/
					intnum = Integer(myin)
				when /^0b[01]+$/
					intnum = Integer(myin)
				when /^0d[0-9]+$/
					intnum = Integer(myin)
				when /^[0-9]+$/
					intnum = Integer(myin)
				else
					return false
			end
	end

	return intnum

end
