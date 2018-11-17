#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library -- Parser
# FILE:		parse.tcl
# AUTHOR:	John Wedgwood, January 22nd, 1991
#
# COMMANDS:
#	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	john	 1/22/91	Initial revision
#
# DESCRIPTION:
#	This file contains TCL routines to assist in debugging the parser.
#
#	$Id: parse.tcl,v 1.1 97/04/05 01:26:59 newdeal Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

[load pseutils.tcl]

#
# It is useful to know what labels we can stop at in order to get useful
# information. Here they are:
#
#   	    PARSER
# ParseString			- Start parsing
# ParseFullExpression		- Parse an expression
# ParseMoreExpression		- Parse a partial expression
# ParseFunctionCall		- Parse a function call
# ParseArgList			- Parse an argument list
# ParseMoreArgs			- Parse more arguments
# ParserReportError		- al holds the error code
# 

[defcommand parser-watch {onOff} parser
{parser-watch prints out information about the progress of the parser}
{
    global  pw_breakpoints

    if {[string compare $onOff off] == 0} {
    	pw_remove-brk pw_breakpoints
	var pw_breakpoints {}
    } elif {![null $pw_breakpoints]} {
    	echo "Already doing a parser-watch"
    } else {
        var pw_breakpoints [list
	    [brk aset parse::ParserReportError	    	    pw_error]
	    [brk aset parse::AllocateParserToken    	    pw_token]
	    
	    [brk aset parse::ParseFullExpression   	    pw_full_expr]
	    [brk aset parse::ParseMoreExpression   	    pw_more_expr]
	    [brk aset parse::ParseFunctionArgs   	    pw_func_args]
	    [brk aset parse::ParseArgList   	   	    pw_arg_list]
	    [brk aset parse::ParseMoreArgs   	   	    pw_more_args]
    	]
    }
}]
[defsubr pw_token {}
{
    # al holds the token
    var ttype [range [type emap [read-reg al] [sym find type ParserTokenType]]
    	    	    13
		    end
		    chars]

    echo -n [format {Parsed Token: %s} $ttype]
    if {![string compare $ttype OPERATOR]} {
	var opType [type emap [read-reg dl] [sym find type OperatorType]]
	echo [format {   %s} [range $opType 3 end chars]]
    } else {
    	echo
    }
    return 0
}]


[defsubr pw_full_expr {}
{
    echo {Parsing... Full Expression}
    return 0
}]

[defsubr pw_more_expr {}
{
    echo {Parsing... More Expression}
    return 0
}]

[defsubr pw_func_args {}
{
    echo {Parsing... Function Arguments}
    return 0
}]

[defsubr pw_arg_list {}
{
    echo {Parsing... Argument List}
    return 0
}]

[defsubr pw_more_args {}
{
    echo {Parsing... More Arguments}
    return 0
}]

[defcommand pexpr {{address ds:si}} parser
{pexpr - prints a parsed expression using a passed token stream}
{
    #
    # Basically we just cruise through each token figuring out what type
    # it is and displaying something meaningful.
    #
    var addr [addr-parse $address]
    var seg [handle segment [index $addr 0]]
    var off [index $addr 1]
    
    while {$off != -1} {
	var off [print-single-parser-token $seg $off]
    }
}]

#
# Print a single parser-token
# Returns the offset to the next token.
# Returns -1 if the token printed was END_OF_EXPRESSION.
#
[defsubr print-single-parser-token {seg off {typeByte {}}} {
    #
    # Grab the type.
    #
    if {[null $ttype]} {
	var typeByte [value fetch $seg:$off byte]
	var off [expr $off+1]
    }
    var ttype [range [type emap $typeByte
			 [sym find type ParserTokenType]]
			13 end chars]
    echo -n [format {%-20s} $ttype]

    [case $ttype in
	NUMBER {
	    echo -n {** Some Number **}
	    var off [expr $off+[type size
			[sym find type ParserTokenNumberData]]]
	}
	STRING {
	    var stringLength [value fetch $seg:$off.PTSD_length word]

	    var off [expr $off+[type size 
			[sym find type ParserTokenStringData]]]

	    echo -n [printString ds $off [expr $stringLength+2]]

	    var off [expr $off+$stringLength]

	}
	CELL {
	    var ref [value fetch $seg:$off
					ParserTokenCellData]
	    print-cell-ref [field $ref PTCD_cellRef] both

	    var off [expr $off+[type size
			[sym find type ParserTokenCellData]]]
	}
	FUNCTION {
	    var funcType [type emap
		[value fetch $seg:$off.PTFD_functionID]
		    [sym find type FunctionID]]
	    echo -n [range $funcType 12 end chars]

	    var off [expr $off+[type size
			[sym find type ParserTokenFunctionData]]]
	}
	END_OF_EXPRESSION {
	}
	NAME {
	    echo -n [value fetch $seg:$off.PTND_name]
	    var off [expr $off+[type size
			[sym find type ParserTokenNameData]]]
	}
	RANGE {
	    var ref [value fetch $seg:$off ParserTokenRangeData]
	    print-cell-ref [field $ref PTRD_firstCell] letters
	    echo -n {:}
	    print-cell-ref [field $ref PTRD_lastCell] letters

	    echo -n {    }
	    print-cell-ref [field $ref PTRD_firstCell] numbers
	    echo -n {:}
	    print-cell-ref [field $ref PTRD_lastCell] numbers

	    var off [expr $off+[type size 
			    [sym find type ParserTokenRangeData]]]
	}
	OPERATOR {
	    var opType [type emap
			[value fetch $seg:$off.PTOD_operatorID]
			[sym find type OperatorType]]
	    echo -n [format {%s} [range $opType 3 end chars]]
	    var off [expr $off+[type size
				[sym find type ParserTokenOperatorData]]]
	}
	OPEN_PAREN {
	    echo -n OPEN_PAREN
	}
	CLOSE_PAREN {
	    echo -n CLOSE_PAREN
	}
	CLOSE_FUNCTION {
	    echo -n CLOSE_FUNCTION
	}
	ARG_END {
	    echo -n ARG_END
	}
	RANGE_SEPARATOR {
	    echo -n RANGE_EXTENSION
	}
	default {
	    echo -n {Unknown token type.}
	}
    ]
    echo
    if {[string compare $ttype END_OF_EXPRESSION] == 0} {
    	var off -1
    }
    return $off
}]

