SHELL:=/bin/bash
RUBYREG_PATH=../

all: regs

regs:
	ruby ${RUBYREG_PATH}/lib/rubyreg.rb -i regmap_example.xlsx -o regmap_example.v -m regmap_example -c rubyreg.yml

clean:
	rm regmap_example.v regmap_example.xlsx.csv -f
