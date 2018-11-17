#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library -- Scanner
# FILE:		scan.tcl
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
#	This file contains TCL routines to assist in debugging the scanner.
#
#	$Id: scan.tcl,v 1.1 97/04/05 01:27:02 newdeal Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

[load pseutils.tcl]

#
# It is useful to know what labels we can stop at in order to get useful
# information. Here they are:
#
#   	    SCANNER
# ScannerInit			- Start scanning
# ScannerGetNextToken::done	- Should have a token (if no error)
# ScannerLookAheadToken::done	- Should have a token (if no error)
# ScannerReportError		- al holds the error code
#

[defcommand scanner-watch {onOff} parser
{scanner-watch prints out information about the progress of the scanner}
{
    global  sw_breakpoints

    if {[string compare $onOff off] == 0} {
    	pw_remove-brk sw_breakpoints
	var sw_breakpoints {}
    } elif {![null $sw_breakpoints]} {
    	echo "Already doing a scanner-watch"
    } else {
        var sw_breakpoints [list
    	    [brk aset parse::ScannerInit    	    	    sw_init]
	    [brk aset parse::ScannerGetNextToken    	    sw_getnext]
	    [brk aset parse::ScannerGetNextToken::done	    sw_token]
	    [brk aset parse::ScannerLookAheadToken  	    sw_lookahead]
	    [brk aset parse::ScannerLookAheadToken::done    sw_token]
	    [brk aset parse::ScannerReportError	    	    sw_error]
    	]
    }
}]

[defsubr sw_init {}
{
    echo [format {Init: %-50s  } [printString ds [read-reg si] 50]]
    echo
    return 0
}]

[defsubr sw_getnext {}
{
    var flags [value fetch es:di.PP_flags]
    
    if {[field $flags PF_HAS_LOOKAHEAD]} {
    	var str {**from look ahead**}
    } else {
        var str [printString ds [read-reg si] 30]
    }
    
    echo -n [format {Get : %-30s  } $str]
    return 0
}]

[defsubr sw_lookahead {}
{
    echo -n [format {Peek: %-30s  } [printString ds [read-reg si] 30]]
    return 0
}]

[defsubr sw_token {}
{
    # es:bx holds the pointer to the token
    var ttype [range [type emap [value fetch es:bx.ST_type]
    	    	    	    [sym find type ScannerTokenType]]
    	    	    14 end chars]

    echo -n [format {    %-17s } $ttype]
    
    [case $ttype in
    	NUMBER {
	    #
	    # Print out the number
	    #
	    echo
	}
	STRING {
	    #
	    # Print the string out
	    #
	    var stringOffset [value fetch es:bx.ST_data.STSD_start word]
    	    var stringLength [value fetch es:bx.ST_data.STSD_length word]
	    
	    var textStart [value fetch es:di.PP_textStart word]
	    var stringStart [expr $textStart+$stringOffset]

	    echo [printString ds $stringStart [expr $stringLength+2]]
	}
	CELL {
	    #
	    # Print out the column/row
	    #
	    var ref [value fetch es:bx.ST_data ScannerTokenCellData]
	    echo -n {<}
	    print-cell-ref [field $ref STCD_cellRef] both
	    echo {>}
    	}
	RANGE {
	    #
	    # Print out the column/row
	    #
	    var r [value fetch es:bx.ST_data ScannerTokenRangeData]
	    print-cell-ref [field [field $r STRD_firstCell] STCD_cellRef] both
	    echo -n { : }
	    print-cell-ref [field [field $r STRD_lastCell] STCD_cellRef] both
	    if {[field $r STRD_name]} {
	        echo -n [format {    **%d**} [field $r STRD_name]]
	    }
    	}
	FUNCTION {
	    #
	    # Print out the function ID (if built in, map to name)
	    #
	    var funcType [type emap
    	    	[value fetch es:bx.ST_data.STFD_functionID]
    	    	    [sym find type FunctionID]]
	    echo [format {<%s>} [range $funcType 12 end chars]]
	}
	OPERATOR {
	    #
	    # Print out the operator
	    #
	    var opType [type emap [value fetch es:bx.ST_data.STOD_operatorID]
    	    	    	    [sym find type OperatorType]]
	    echo [format {<%s>} [range $opType 3 end chars]]
	}
	#
	# Do nothing for the following
	#
	# OPEN_PAREN
	# CLOSE_PAREN
	# RANGE_SEPARATOR
	# LIST_SEPARATOR
	# END_OF_EXPRESSION
	default {
       	    # Terminate the line
    	    echo
    	}
    ]
    return 0
}]
