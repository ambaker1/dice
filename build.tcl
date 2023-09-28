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
set commas_in_quotes [fread $csvDir/comma_in_quotes.csv]
set empty [fread $csvDir/empty.csv]
set empty_crlf [fread $csvDir/empty_crlf.csv]
set escaped_quotes [fread $csvDir/escaped_quotes.csv]
set json [fread $csvDir/json.csv]
set newlines [fread $csvDir/newlines.csv]
set quotes_and_newlines [fread $csvDir/quotes_and_newlines.csv]
set simple [fread $csvDir/simple.csv]
set simple_crlf [fread $csvDir/simple_crlf.csv]
set utf8 [fread $csvDir/utf8.csv]

test commas_in_quotes {
    # from commas_in_quotes.csv
} -body {
    csv2mat [fread $csvDir/comma_in_quotes.csv]
} -result {{first last address city zip} {John Doe {120 any st.} {Anytown, WW} 08123}}

test empty {
    # from empty.csv
} -body {
    csv2mat [fread $csvDir/empty.csv]
} -result {{a b c} {1 {} {}} {2 3 4}}

test empty_crlf {

} -body {
    csv2mat [fread $csvDir/empty_crlf.csv]
} -result {{a b c} {1 {} {}} {2 3 4}}

assert [readMatrix $csvDir/comma_in_quotes.csv] eq \
{{first last address city zip} {John Doe {120 any st.} {Anytown, WW} 08123}}

assert [csv2mat $empty] eq \


assert [ $empty_crlf] eq \


assert [csv2mat $escaped_quotes] eq \
{{a b} {1 {ha "ha" ha}} {3 4}}

assert [csv2mat $json] eq \
{{key val} {1 {{"type": "Point", "coordinates": [102.0, 0.5]}}}}

assert [csv2mat $newlines] eq \
{{a b c} {1 2 3} {{Once upon 
a time} 5 6} {7 8 9}}

assert [csv2mat $quotes_and_newlines] eq \
{{a b} {1 {ha 
"ha" 
ha}} {3 4}}

assert [csv2mat $simple] eq \
{{a b c} {1 2 3}}

assert [csv2mat $simple_crlf] eq \
{{a b c} {1 2 3}}

assert [csv2mat $utf8] eq \
{{a b c} {1 2 3} {4 5 ʤ}}


# Reverse acid-test
assert [mat2csv [csv2mat $commas_in_quotes]] eq $commas_in_quotes
# SKIPPING WRITE TEST FOR EMPTY CELLS - EMPTY CELLS ARE WRITTEN LIKE ,, RATHER THAN ,"",
# assert [mat2csv [csv2mat $empty]] eq $empty
# assert [mat2csv [csv2mat $empty_crlf]] eq $empty_crlf
assert [mat2csv [csv2mat $escaped_quotes]] eq $escaped_quotes
assert [mat2csv [csv2mat $json]] eq $json
assert [mat2csv [csv2mat $newlines]] eq $newlines
assert [mat2csv [csv2mat $quotes_and_newlines]] eq $quotes_and_newlines
assert [mat2csv [csv2mat $simple]] eq $simple
assert [mat2csv [csv2mat $simple_crlf]] eq $simple_crlf
assert [mat2csv [csv2mat $utf8]] eq $utf8


# Conversion acid test
set table [csv2tbl $commas_in_quotes]
assert [txt2csv [mat2txt [tbl2mat $table]]] eq $commas_in_quotes

set table [csv2tbl $escaped_quotes]
assert [txt2csv [mat2txt [tbl2mat $table]]] eq $escaped_quotes

set table [csv2tbl $json]
assert [txt2csv [mat2txt [tbl2mat $table]]] eq $json

set table [csv2tbl $newlines]
assert [txt2csv [mat2txt [tbl2mat $table]]] eq $newlines

set table [csv2tbl $quotes_and_newlines]
assert [txt2csv [mat2txt [tbl2mat $table]]] eq $quotes_and_newlines

set table [csv2tbl $simple]
assert [txt2csv [mat2txt [tbl2mat $table]]] eq $simple

set table [csv2tbl $simple_crlf]
assert [txt2csv [mat2txt [tbl2mat $table]]] eq $simple_crlf

set table [csv2tbl $utf8]
assert [txt2csv [mat2txt [tbl2mat $table]]] eq $utf8

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
tin forget taboo
tin clear
tin import taboo -exact $version
