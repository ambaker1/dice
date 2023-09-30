package require tin
tin import dice

puts "File input/output"
# Export data to file (creates or overwrites the file)
fputs example.txt "hello world"
# Import the contents of the file (requires that the file exists)
puts [fread example.txt]
file delete example.txt

puts "Example data (mat):"
set mat {{step disp force} {1 0.02 4.5} {2 0.03 4.8} {3 0.07 12.6}}

puts "Example data (tbl):"
puts [mat2tbl $mat]

puts "Example data (txt):"
puts [mat2txt $mat]

puts "Example data (csv):"
puts [mat2csv $mat]

puts "Combining data conversions"
# Convert from table to csv, using mat as an intermediate datatype.
set tbl {step {1 2 3} disp {0.02 0.03 0.07} force {4.5 4.8 12.6}}
set csv [mat2csv [tbl2mat $tbl]]; # also could use tbl2csv
puts $csv

