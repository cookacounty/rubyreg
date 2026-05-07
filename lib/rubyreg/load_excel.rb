

def load_excel(fname)

	puts "Loading Excel #{fname}"

	xlsx = Roo::Spreadsheet.open(fname)
	#puts xlsx.info
	# => Returns basic info about the spreadsheet file


    xlsx.default_sheet = xlsx.sheets.first
    header = xlsx.row(1)
    puts header[0] if $options[:verbose]
    
    (2..xlsx.last_row).each do |i|
      next unless xlsx.row(i)[0]
      row = xlsx.row(i) 
    end
    sheet = xlsx.sheet(0)
    p = sheet.parse()
    #puts p.inspect

    rm = Regmap.new(xlsx)

    $ignored_reg = false
    p.each do |row|
    	parse_row(rm,row)
    end

    rm.assign_bitfields

    rm.run_checks

    rm

end


def parse_row(rm,row)
	regtype, properties = parse_register_properties(row[2]&.strip)
	headings = {
		regname:       row[ 0]&.strip, 
		regoffset:     row[ 1],
		regtype:       regtype,
		properties:    properties,
		name:          row[ 3]&.strip,
		assignment:    row[ 4],
		type:          row[ 5]&.strip,
		initial_value: row[ 6],
		description:   row[ 7],
		wr_enable:     row[ 8]&.strip,
		destination:   row[10]&.strip}

	if headings[:regname]
		valid_regtypes = ["reserved","external","reg_port"]
		valid_properties = ["customer", "factory"]

		if headings[:regtype] && !(valid_regtypes.member?(headings[:regtype]))
			raise "Invalid register type name #{headings[:regname]} type #{headings[:regtype]}\n\t#{headings.inspect}"
		end
		invalid_properties = headings[:properties] - valid_properties
		if invalid_properties.length > 0
			raise "Invalid register properties name #{headings[:regname]} properties " \
			      "#{invalid_properties.join(",")}\n\t#{headings.inspect}"
		end
		if (headings[:properties] & valid_properties).length > 1
			raise "Register #{headings[:regname]} cannot be both customer and factory locked\n\t#{headings.inspect}"
		end
		if ["reserved"].member?(headings[:regtype])
			$ignored_reg = true
		else
			$ignored_reg = false
			rm.addreg(headings)
		end		
	end

	# Only add the row if its not ignored
	if !$ignored_reg && headings[:name]
		puts "ROW: #{row.join(",")}" if $options[:verbose]
		rm.addfield(headings)
	end
end

def parse_register_properties(regtype)
	return [nil, []] if !regtype || regtype.empty?

	tokens = regtype.split(/[,\s]+/).reject(&:empty?).map(&:downcase)
	base_types = ["reserved", "external", "reg_port"]
	base_type = tokens.find { |token| base_types.member?(token) }
	properties = tokens - [base_type]

	[base_type, properties]
end
