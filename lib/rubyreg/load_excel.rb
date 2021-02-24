

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

    rm = Regmap.new

    $ignored_reg = false
    p.each do |row|
    	parse_row(rm,row)
    end

    rm.assign_bitfields

    rm

end


def parse_row(rm,row)
	headings = {
		regname:       row[ 0]&.strip, 
		regoffset:     row[ 1],
		regtype:       row[ 2]&.strip, 
		name:          row[ 3]&.strip,
		assignment:    row[ 4],
		type:          row[ 5]&.strip,
		initial_value: row[ 6],
		description:   row[ 7],
		wr_enable:     row[ 8]&.strip,
		destination:   row[10]&.strip}

	if headings[:regname]
		valid_regtypes = ["reserved","external","reg_port"]

		raise "Invalid register type name #{headings[:regname]} type #{headings[:regtype]}\n\t#{headings.inspect}" if headings[:regtype] && !(valid_regtypes.member?(headings[:regtype]))
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