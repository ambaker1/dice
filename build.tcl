package require tin 1.0
tin import assert from tin
tin import tcltest
tin import flytrap
set version 0.1
set config ""
dict set config VERSION $version
dict set config NDLIST_VERSION 0.2
tin bake src build $config
tin bake doc/template/version.tin doc/template/version.tex $config

# Import 
source build/tio.tcl 
namespace import tio::*

test file_io {
    # Write to file and read back the result
} -body {
    # Export data to file (creates or overwrites the file)
    fputs tests/example.txt "hello world"
    # Import the contents of the file (requires that the file exists)
    fread tests/example.txt
} -result {hello world}

test binary_io {
    # fconfigure feature of fread
} -body {
    # Binary files
    # Example modified from example on tcl wiki written by Mac Cody and Jeff David
    # https://wiki.tcl-lang.org/page/Working+with+binary+data
    set outBinData [binary format s2Sa6B8 {100 -2} 100 foobar 01000001]
    fputs -translation binary tests/binfile.bin $outBinData
    set inBinData [fread -translation binary tests/binfile.bin]
    assert [binary scan $inBinData s2Sa6B8 val1 val2 val3 val4] == 4
    list $val1 $val2 $val3 $val4
} -result {{100 -2} 100 foobar 01000001}

# Acid test for csv parser/writer
# Acid test files from https://github.com/maxogden/csv-spectrum
set csvDir "tests/csv_samples"
set csv1 [fread $csvDir/comma_in_quotes.csv]
set csv2 [fread $csvDir/empty.csv]
set csv3 [fread $csvDir/empty_crlf.csv]
set csv4 [fread $csvDir/escaped_quotes.csv]
set csv5 [fread $csvDir/json.csv]
set csv6 [fread $csvDir/newlines.csv]
set csv7 [fread $csvDir/quotes_and_newlines.csv]
set csv8 [fread $csvDir/simple.csv]
set csv9 [fread $csvDir/simple_crlf.csv]
set csv10 [fread $csvDir/utf8.csv]

puts "Checking csv reader"
assert [csv2mat $csv1] eq {{first last address city zip} {John Doe {120 any st.} {Anytown, WW} 08123}}
assert [csv2mat $csv2] eq {{a b c} {1 {} {}} {2 3 4}}
assert [csv2mat $csv3] eq {{a b c} {1 {} {}} {2 3 4}}
assert [csv2mat $csv4] eq {{a b} {1 {ha "ha" ha}} {3 4}}
assert [csv2mat $csv5] eq {{key val} {1 {{"type": "Point", "coordinates": [102.0, 0.5]}}}}
assert [csv2mat $csv6] eq {{a b c} {1 2 3} {{Once upon 
a time} 5 6} {7 8 9}}
assert [csv2mat $csv7] eq {{a b} {1 {ha 
"ha" 
ha}} {3 4}}
assert [csv2mat $csv8] eq {{a b c} {1 2 3}}
assert [csv2mat $csv9] eq {{a b c} {1 2 3}}
assert [csv2mat $csv10] eq {{a b c} {1 2 3} {4 5 ʤ}}

puts "Checking conversions"
assert [txt2csv [tbl2txt [csv2tbl $csv1]]]] eq $csv1
# Skipping empty.csv and empty_crlf.csv - blanks are represented by "".
# assert [txt2csv [tbl2txt [csv2tbl $csv2]]]] eq $csv2
# assert [txt2csv [tbl2txt [csv2tbl $csv3]]]] eq $csv3
assert [txt2csv [tbl2txt [csv2tbl $csv4]]]] eq $csv4
assert [txt2csv [tbl2txt [csv2tbl $csv5]]]] eq $csv5
assert [txt2csv [tbl2txt [csv2tbl $csv6]]]] eq $csv6
assert [txt2csv [tbl2txt [csv2tbl $csv7]]]] eq $csv7
assert [txt2csv [tbl2txt [csv2tbl $csv8]]]] eq $csv8
assert [txt2csv [tbl2txt [csv2tbl $csv9]]]] eq $csv9
assert [txt2csv [tbl2txt [csv2tbl $csv10]]]] eq $csv10
>>>>>>> Stashed changes

# Check number of failed tests
set nFailed $::tcltest::numTests(Failed)

# Clean up and report on tests
cleanupTests

# If tests failed, return error
if {$nFailed > 0} {
    error "$nFailed tests failed"
}

# Tests passed, copy build files to main folder and install
file copy -force {*}[glob -directory build *] [pwd]

exec tclsh install.tcl

# Verify installation
tin forget tio
tin clear
tin import tio -exact $version
