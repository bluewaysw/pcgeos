#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library -- Parser, Scanner, Evaluator Utilities
# FILE:		parse.tcl
# AUTHOR:	John Wedgwood, January 28th, 1991
#
# COMMANDS:
#	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	john	 1/28/91	Initial revision
#
# DESCRIPTION:
#	This file contains TCL utilities used by parse.tcl, scan.tcl, and
#   	eval.tcl
#
#	$Id: pseutils.tcl,v 1.1 97/04/05 01:26:56 newdeal Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

#
# Remove a list of breakpoints.
#
[defsubr pw_remove-brk {bname} {
    global	$bname

    if {![null $[var $bname]]} {
	foreach i [var $bname] {
	    catch {brk clear $i}
	}
	var $bname {}
    }
}]


[defsubr printString {seg offset nchars}
{
    #
    # Return characters as we get them w/no intervening commas -- use
    # format to take care of \\, \{ and \} things. All other things are
    # printed as returned by value...
    #
    # Account for the quotes by subtracting 2 from the field width.
    #
    var result {"}
    
    var nchars [expr $nchars-2]
    do {
	var ch [value fetch $seg:$offset [type char]]
	if {[string c $ch \\000]} {
	    if {[string m $ch {\\[\{\}\\]}]} {
		var result $result[format $ch]
	    } else {
		var result $result$ch
	    }
	}
	var offset [expr $offset+1]
	var nchars [expr $nchars-1]
    } while {[expr ($nchars!=0)&&[string c $ch \\000]]}
    
    var result $result"
    return $result
}]

[defsubr print-cell-ref {cell form}
{
    var rowRec    [field $cell CR_row]
    var columnRec [field $cell CR_column]

    var row    [field $rowRec CRC_VALUE]
    var column [field $columnRec CRC_VALUE]
    #
    # First decide if the references are absolute or not
    #
    var rowAbs	{}
    if {[field $rowRec CRC_ABSOLUTE]} {
	var rowAbs {$}
    }
    var colAbs {}
    if {[field $columnRec CRC_ABSOLUTE]} {
	var colAbs {$}
    }

    #
    # Columns are converted to the form ABC (a three digit base-26
    # number.
    #
    var colDig {}

    var col $column
    while {$col != 0} {
    	var remainder [expr $col%26]
	var col [expr $col/26]

	if {$remainder == 0} {
	    var remainder 26
	    if {$col == 0} {
	        var col [expr $col-1]
	    }
	}
	var colDig [index { ABCDEFGHIJKLMNOPQRSTUVWXYZ}
	    	    	$remainder chars][var colDig]
    }

    if {![string compare $form both] || ![string compare $form letters]} {
    	echo -n [format {%s%s%s%s} $colAbs $colDig $rowAbs $row]
    }
    if {![string compare $form both]} {
    	echo -n {    }
    }
    if {![string compare $form both] || ![string compare $form numbers]} {
    	echo -n [format {%s%s.%s%s} $colAbs $column $rowAbs $row]
    }
}]

#
# Print out an error code.
#
[defsubr pw_error {}
{
    # al holds the error code
    echo [format {*** Parser/Scanner/Evaluator Error: %s}
    	    [range
	    	[type emap [read-reg al]
		    	[sym find type ParserScannerEvaluatorError]]
		5
		end
		chars]]
    return 0
}]
