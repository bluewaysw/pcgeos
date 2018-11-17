#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library -- Parse
# FILE:		pexpr.tcl
# AUTHOR:	John Wedgwood, September 18th, 1991
#
# COMMANDS:
#	Name			Description
#	----			-----------
#   	pexpr	    	    	Print a tokenized expression
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	john	 9/18/91	Initial revision
#
# DESCRIPTION:
#	Contains TCL routines to assist in debugging the parse library.
#
#	$Id: pexpr.tcl,v 1.1 97/04/05 01:27:00 newdeal Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

##############################################################################
#			  token-handler-list
#
# An assoc list of parser tokens and handlers for printing them.
# Each entry is of the form
#   	    {PARSER_TOKEN dataType handler tokenName}
#
##############################################################################
[var token-handler-list {
    {NUMBER 	    	ParserTokenNumberData   ptoken-number	    Number}
    {STRING 	    	ParserTokenStringData   ptoken-string	    String}
    {CELL   	    	ParserTokenCellData     ptoken-cell 	    Cell}
    {END_OF_EXPRESSION	nil 	    	    	ptoken-eoe  	    EOE}
    {OPEN_PAREN	    	nil 	    	    	ptoken-open-paren   OpenParen}
    {CLOSE_PAREN    	nil 	    	    	ptoken-close-paren  CloseParen}
    {NAME   	    	ParserTokenNameData     ptoken-name 	    Name}
    {FUNCTION	    	ParserTokenFunctionData ptoken-function	    Function}
    {CLOSE_FUNCTION 	nil 	    	    	ptoken-close-func   CloseFunc}
    {ARG_END	    	nil 	    	    	ptoken-arg-end	    ArgEnd}
    {OPERATOR	    	ParserTokenOperatorData ptoken-operator	    Operator}
}]

##############################################################################
#				pexpr
##############################################################################
#
# SYNOPSIS:	Print a tokenized expression in human readable form.
# PASS:		address	= Address of the row (defaults to ds:si)
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	?
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 9/18/91	Initial Revision
#
##############################################################################
[defcommand pexpr {{address ds:si}} parse
{Usage:
    pexpr [<address ds:si>]

Examples:
    "pexpr"	    	print the expression at ds:si
    "pexpr es:0"  	print the expression at es:0

Synopsis:
    Print a parsed expression in human readable form.

Notes:

See also:
}
{
    global  token-handler-list

    #
    # First parse the address.
    #
    var addr [addr-parse $address]
    var han  [handle id [index $addr 0]]
    var seg  [handle segment [index $addr 0]]
    var off  [index $addr 1]
    
    #
    # Grab a byte, process the byte...
    #
    var ptt [sym find type ParserTokenType]

    while {1} {
    	var t [type emap [value fetch $seg:$off $ptt] $ptt]

	if {[null $t]} {
	    echo [format {Illegal token at: %04xh:%04xh} $seg $off]
	    break
	}

	#
	# Find the token and extract data associated with it.
	#
	var t [range $t 13 end chars]

    	var tokenList [assoc [var token-handler-list] $t]
	
	var dataName   	[index $tokenList 1]
	var rout    	[index $tokenList 2]
	var tokenName	[index $tokenList 3]

	#
	# Check for not found.
	#
	if {[null $tokenList]} {
	    echo [format {Token not in the list: %s} $t]
	    break
	}

	#
	# Move offset to point after the token
	#
	var off [expr $off+1]

	#
	# Fetch the related data from the buffer
	#
	var dataType [sym find type $dataName]

	var data {}
	if {! [null $dataType]} {
	    var data [value fetch $seg:$off $dataType]
	}

	#
	# Call the handler passing the data.
	# The handler prints stuff out, not including a <cr> at the end.
	#
	ptoken-title $tokenName
	var more [$rout $data $seg $off]
	echo
	
	#
	# Check for done.
	#
    	if {[string compare $t END_OF_EXPRESSION] == 0} {
	    break
	}

	#
	# Move to the next token
	#
	if {! [null $dataType]} {
	    var off [expr $off+[type size $dataType]+$more]
	}
    }
}]

##############################################################################
#			    ptoken-number
##############################################################################
#
# SYNOPSIS:	Print a floating point number in a human-readable form.
# PASS:		data	    - ParserTokenNumberData
#   	    	seg, off    - Pointer to additional data
# CALLED BY:	pexpr
# RETURN:	additional size needed beyond the passed data
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 9/18/91	Initial Revision
#
##############################################################################
[defsubr ptoken-number {data seg off}
{
    var num 	[field $data PTND_value]
    
    fmtstruct [sym find type FloatNum] $num 0 0

    return 0
}]

##############################################################################
#			    ptoken-string
##############################################################################
#
# SYNOPSIS:	Print a string constant in a human-readable form.
# PASS:		data	    - ParserTokenStringData
#   	    	seg, off    - Pointer to additional data
# CALLED BY:	pexpr
# RETURN:	additional size needed beyond the passed data
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 9/18/91	Initial Revision
#
##############################################################################
[defsubr ptoken-string {data seg off}
{
    #
    # Kick the offset to the start of the string.
    #
    var off [expr $off+[type size [sym find type ParserTokenStringData]]]

    var length 	[field $data PTSD_length]
    
    echo -n {"}
    for {var i 0} {$i < $length} {var i [expr $i+1]} {
    	echo -n [value fetch $seg:$off+$i [type char]]
    }

    echo -n {"}
    
    return [expr $length+1]
}]

##############################################################################
#			    ptoken-cell
##############################################################################
#
# SYNOPSIS:	Print a cell reference in a human-readable form.
# PASS:		data	    - ParserTokenCellData
#   	    	seg, off    - Pointer to additional data
# CALLED BY:	pexpr
# RETURN:	additional size needed beyond the passed data
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 9/18/91	Initial Revision
#
##############################################################################
[defsubr ptoken-cell {data seg off}
{
    var cell	[field $data PTCD_cellRef]
    var row 	[field $cell CR_row]
    var col 	[field $cell CR_column]
    
    var rowVal	[field $row CRC_VALUE]
    var rowAbs	[field $row CRC_ABSOLUTE]

    var colVal	[field $col CRC_VALUE]
    var colAbs	[field $col CRC_ABSOLUTE]

    #
    # Sign-extend the column and row values.
    #
    if {$colVal > 0x4000} {
    	var colVal [expr $colVal+0xffff8000]
    }
    if {$rowVal > 0x4000} {
    	var rowVal [expr $rowVal+0xffff8000]
    }
    
    var rowA {}
    if {$rowAbs} {
    	var rowA {$}
    }

    var colA {}
    if {$colAbs} {
    	var colA {$}
    }

    echo -n [format {<R = %s%d, C = %s%d>}
    	    	$rowA $rowVal $colA $colVal
		    ]
    return 0
}]

##############################################################################
#			    ptoken-eoe
##############################################################################
#
# SYNOPSIS:	Print an end-of-expression token
# PASS:		data	    - nil
#   	    	seg, off    - Pointer to additional data
# CALLED BY:	pexpr
# RETURN:	additional size needed beyond the passed data
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 9/18/91	Initial Revision
#
##############################################################################
[defsubr ptoken-eoe {data seg off}
{
    echo -n {End Of Expression}
    
    return 0
}]

##############################################################################
#			    ptoken-open-paren
##############################################################################
#
# SYNOPSIS:	Print an open-paren token
# PASS:		data	    - nil
#   	    	seg, off    - Pointer to additional data
# CALLED BY:	pexpr
# RETURN:	additional size needed beyond the passed data
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 9/18/91	Initial Revision
#
##############################################################################
[defsubr ptoken-open-paren {data seg off}
{
    echo -n {(}
    
    return 0
}]

##############################################################################
#			    ptoken-close-paren
##############################################################################
#
# SYNOPSIS:	Print a close-paren token
# PASS:		data	    - nil
#   	    	seg, off    - Pointer to additional data
# CALLED BY:	pexpr
# RETURN:	additional size needed beyond the passed data
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 9/18/91	Initial Revision
#
##############################################################################
[defsubr ptoken-close-paren {data seg off}
{
    echo -n {)}
    
    return 0
}]

##############################################################################
#			    ptoken-name
##############################################################################
#
# SYNOPSIS:	Print a name token
# PASS:		data	    - ParserTokenNameData
#   	    	seg, off    - Pointer to additional data
# CALLED BY:	pexpr
# RETURN:	additional size needed beyond the passed data
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 9/18/91	Initial Revision
#
##############################################################################
[defsubr ptoken-name {data seg off}
{
    var name [field $data PTND_name]
    
    echo -n [format {%04x} $name]
    
    return 0
}]

##############################################################################
#			    ptoken-function
##############################################################################
#
# SYNOPSIS:	Print a function token
# PASS:		data	    - ParserTokenFunctionData
#   	    	seg, off    - Pointer to additional data
# CALLED BY:	pexpr
# RETURN:	additional size needed beyond the passed data
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 9/18/91	Initial Revision
#
##############################################################################
[defsubr ptoken-function {data seg off}
{
    var func [field $data PTFD_functionID]

    var funcName [type emap $func [sym find type FunctionID]]
    
    echo -n [format {%s} $funcName]

    return 0
}]

##############################################################################
#			    ptoken-close-func
##############################################################################
#
# SYNOPSIS:	Print a close-function token
# PASS:		data	    - nil
#   	    	seg, off    - Pointer to additional data
# CALLED BY:	pexpr
# RETURN:	additional size needed beyond the passed data
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 9/18/91	Initial Revision
#
##############################################################################
[defsubr ptoken-close-func {data seg off}
{
    echo -n {)}

    return 0
}]

##############################################################################
#			    ptoken-arg-end
##############################################################################
#
# SYNOPSIS:	Print an arg-end token
# PASS:		data	    - nil
#   	    	seg, off    - Pointer to additional data
# CALLED BY:	pexpr
# RETURN:	additional size needed beyond the passed data
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 9/18/91	Initial Revision
#
##############################################################################
[defsubr ptoken-arg-end {data seg off}
{
    echo -n {,}

    return 0
}]

##############################################################################
#			    ptoken-operator
##############################################################################
#
# SYNOPSIS:	Print an operator token
# PASS:		data	    - ParserTokenOperatorData
#   	    	seg, off    - Pointer to additional data
# CALLED BY:	pexpr
# RETURN:	additional size needed beyond the passed data
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 9/18/91	Initial Revision
#
##############################################################################
[defsubr ptoken-operator {data seg off}
{
    var op [field $data PTOD_operatorID]
    
    var opName [type emap $op [sym find type OperatorType]]

    echo -n [format {%s} $opName]

    return 0
}]

##############################################################################
#			    ptoken-title
##############################################################################
#
# SYNOPSIS:	Print a title for a token line
# PASS:		token	    - Name of the token type
# CALLED BY:	pexpr
# RETURN:	additional size needed beyond the passed data
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 9/18/91	Initial Revision
#
##############################################################################
[defsubr ptoken-title {token}
{
    echo -n [format {%-14s} $token]
}]
