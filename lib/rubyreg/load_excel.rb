

def load_excel(fname)

	xlsx = Roo::Spreadsheet.open(fname)
	#puts xlsx.info
	# => Returns basic info about the spreadsheet file


    xlsx.default_sheet = xlsx.sheets.first
    header = xlsx.row(1)
    puts header[0]
    
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

    rm

end


def parse_row(rm,row)
	headings = {"regname"=>row[0],"regoffset"=>row[1],"regtype"=>row[2],"name"=>row[3],"assignment"=>row[4],"type"=>row[5],"initial_value"=>row[6]}

	if headings["regname"]
		if ["reserved","external"].member?(headings["regtype"])
			$ignored_reg = true
		else
			$ignored_reg = false
			rm.addreg(name: headings["regname"],offset: headings["regoffset"])
		end		
	end

	# Only add the row if its not ignored
	if !$ignored_reg
		puts "ROW: #{row.join(",")}"
		rm.addfield(name: headings["name"], assignment: headings["assignment"], type: headings["type"], initial_value: headings["initial_value"])
	end
end