# dice.tcl
################################################################################
# Data import, conversion, and export

# Copyright (C) 2023 Alex Baker, ambaker1@mtu.edu
# All rights reserved. 

# See the file "LICENSE" in the top level directory for information on usage, 
# redistribution, and for a DISCLAIMER OF ALL WARRANTIES.
################################################################################

# Required packages
package require ndlist 0.2

# Define namespace
namespace eval ::dice {
    # File input/output
    namespace export fread fputs; # basic read/write
    # Data conversions
    namespace export mat2tbl tbl2mat; # matrix <-> table
    namespace export mat2txt txt2mat; # matrix <-> text
    namespace export mat2csv csv2mat; # matrix <-> CSV
    namespace export tbl2txt txt2tbl; # table <-> text
    namespace export tbl2csv csv2tbl; # table <-> CSV
    namespace export txt2csv csv2txt; # text <-> CSV
}

# File input/output
################################################################################

# fread --
#
# Loads data from file, ignoring last newline
#
# Syntax:
# fread <$options ...> <-newline> $file
#
# Arguments:
# options:          Options to pass to "fconfigure".
# -newline:         Read the last newline (default ignores last newline).
# file:             File to read from.

proc ::dice::fread {args} {
    # Check for -newline option
    if {[lindex $args end-1] eq "-newline"} {
        set nonewline false
        set args [lreplace $args end-1 end-1]
    } else {
        set nonewline true
    }
    # Check arity
    if {[llength $args] == 0 || [llength $args] % 2 == 0} {
        return -code error "wrong # args: should be\
                \"fread ?option value ...? ?-newline? file\""
    }
    # Interpret input
    set options [lrange $args 0 end-1]
    set file [lindex $args end]
    # Open file for reading, and try to configure and read data.
    set fid [open $file r]
    try {
        fconfigure $fid {*}$options
        # Read string from file
        if {$nonewline} {
            set string [read -nonewline $fid]
        } else {
            set string [read $fid]
        }
    } finally {
        close $fid
    }
    return $string
}

# fputs --
# 
# Overwrite file with data, with additional options
#
# Syntax:
# fputs <$options ...> $file $string
#
# Arguments:
# options:          Options to pass to "fconfigure".
# -nonewline:       Option to not write a final newline.
# file:             File to write to.
# string:           String to write to file.

proc ::dice::fputs {args} {
    # Check for -nonewline option
    if {[lindex $args end-2] eq "-nonewline"} {
        set nonewline true
        set args [lreplace $args end-2 end-2]
    } else {
        set nonewline false
    }
    # Check arity
    if {[llength $args] < 2 || [llength $args] % 2 == 1} {
        return -code error "wrong # args: should be \
                \"fputs ?option value ...? ?-nonewline? file string\""
    }
    # Interpret input
    set options [lrange $args 0 end-2]
    set file [lindex $args end-1]
    set string [lindex $args end]
    # Open file for writing, and try to configure and write data.
    file mkdir [file dirname $file]
    set fid [open $file w]
    try {
        fconfigure $fid {*}$options
        # Write data to file
        if {$nonewline} {
            puts -nonewline $fid $string
        } else {
            puts $fid $string
        }
    } finally {
        close $fid
    }
    return
}

# Data conversions
################################################################################
# mat: Base type. List of rows, using Tcl lists. See ndlist package.
# tbl: Zipped list of header row and columns. See taboo package.
# txt: Space-delineated with newlines to separate rows (actually Tcl lists)
# csv: Comma-separated values, with newlines to separate rows.
################################################################################

# mat2tbl --
#
# Convert from matrix to table
#
# Syntax:
# mat2tbl $matrix
#
# Arguments:
# matrix:       Matrix value to convert

proc ::dice::mat2tbl {matrix} {
    # Validate matrix
    set matrix [::ndlist::ndlist 2D $matrix]
    # Extract header from matrix
    set rows [lassign $matrix header]
    # Construct table
    set table ""
    foreach field $header column [::ndlist::Transpose $rows] {
        lappend table $field $column
    }
    # Return table value
    return $table
}

# tbl2mat --
#
# Convert from table value to matrix value.
#
# Syntax:
# tbl2mat $table
#
# Arguments:
# table:        Table value to convert

proc ::dice::tbl2mat {table} {
    # Verify field-column format.
    if {[llength $table] % 2 == 1} {
        return -code error "missing value to go with key"
    }
    # Extract header and columns from table
    set header ""
    set columns ""
    foreach {field column} $table {
        lappend header $field
        lappend columns $column
    }
    # Construct matrix
    set rows [::ndlist::Transpose [::ndlist::ndlist 2D $columns]]
    set matrix [list $header {*}$rows]
    # Return matrix value
    return $matrix
}

# txt2mat --
#
# Convert from space-delimited text to matrix
# Newlines can be escaped inside curly braces
# Ignores blank lines
#
# Syntax:
# txt2mat $text
#
# Arguments:
# text:     Text to convert.

proc ::dice::txt2mat {text} {
    set matrix ""
    set row ""
    foreach line [split $text \n] {
        # Add to row, and handle escaped newlines
        append row $line
        if {[string is list $row]} {
            lappend matrix $row
            set row ""
        } else {
            append row \n
        }
    }
    # Validate and return matrix
    return [::ndlist::ndlist 2D $matrix]
}

# mat2txt --
#
# Convert from matrix to space-delimited text. 
# Note that rows are Tcl lists.
#
# Syntax:
# mat2txt $matrix
#
# Arguments:
# matrix:       Matrix value

proc ::dice::mat2txt {matrix} {
    join [::ndlist::ndlist 2D $matrix] \n
}

# csv2mat --
#
# Convert from comma-separated values to matrix
# Ignores blank lines
#
# Syntax:
# csv2mat $csv
#
# Arguments:
# csv:          CSV string to convert

proc ::dice::csv2mat {csv} {
    # Initialize variables
    set matrix ""; # Output matrix
    set csvRow ""; # CSV-formatted row of data
    set val ""; # Value in matrix row
    
    # Split csv by newline and loop through lines
    foreach line [split $csv \n] {
        append csvRow $line
        # Check for escaped newline condition
        if {[regexp -all "\"" $csvRow] % 2} {
            # Odd number of quotes
            append csvRow \n
            continue
        }
        # Split csv row by comma and loop through items, creating matrix row
        set row ""; # Matrix row of data
        set blanks 0; # Number of blanks (ignore blank rows)
        foreach item [split $csvRow ,] {
            append val $item
            # Check for escaped comma condition
            if {[regexp -all "\"" $val] % 2} {
                # Odd number of quotes
                append val ,
                continue
            }
            # Check if escaped (commas, newlines, or quotes)
            if {[regexp "\"" $val]} {
                # Remove outer escaping quotes
                set val [string range $val 1 end-1]
                # Check for escaped quotes
                if {[regexp "\"" $val]} {
                    # Replace with normal quotes
                    set val [regsub -all "\"\"" $val "\""]
                }
            }
            if {$val eq ""} {
                incr blanks
            }
            # Add to row
            lappend row $val
            # Clear val
            set val ""
        }
        # Add to matrix
        lappend matrix $row
        # Clear csv row
        set csvRow ""
    }
    # Validate and return matrix
    return [::ndlist::ndlist 2D $matrix]
}

# mat2csv --
#
# Convert from matrix to comma-separated values
#
# Arguments:
# matrix:       Matrix to convert

proc ::dice::mat2csv {matrix} {
    set csvLines ""
    # Validate matrix and loop through rows
    foreach row [::ndlist::ndlist 2D $matrix] {
        set csvRow ""
        foreach val $row {
            # Perform escaping if required
            if {[string match "*\[\",\r\n\]*" $val]} {
                set val "\"[string map [list \" \"\"] $val]\""
            }
            lappend csvRow $val
        }
        lappend csvLines [join $csvRow ,]
    }
    return [join $csvLines \n]
}

# Derived conversions
################################################################################

# From Table (tbl)
proc ::dice::tbl2csv {table} {mat2csv [tbl2mat $table]}
proc ::dice::tbl2txt {table} {mat2txt [tbl2mat $table]}

# From Text (txt)
proc ::dice::txt2tbl {text} {mat2tbl [txt2mat $text]}
proc ::dice::txt2csv {text} {mat2csv [txt2mat $text]}

# From CSV (csv)
proc ::dice::csv2tbl {csv} {mat2tbl [csv2mat $csv]}
proc ::dice::csv2txt {csv} {mat2txt [csv2mat $csv]}

# Finally, provide the package
package provide dice 0.1
