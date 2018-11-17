#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library -- Evaluator
# FILE:		parse.tcl
# AUTHOR:	John Wedgwood, January 28th, 1991
#
# COMMANDS:
#	Name			Description
#	----			-----------
#   	argstack    	    	Print out the argument stack
#   	opstack	    	    	Print out the operator stack
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	john	 1/28/91	Initial revision
#
# DESCRIPTION:
#	This file contains TCL routines to assist in debugging the evaluator.
#
#	$Id: eval.tcl,v 1.1 97/04/05 01:26:58 newdeal Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

##############################################################################
#			  eval-arg-token-handler-list
#
# An assoc list of eval argument tokens and handlers for printing them.
# Each entry is of the form
#   	    {value dataField handler tokenName dataType}
#
# The value may appear somewhat confusing because it is a record containg
# bits, special fields, combinations, etc... See EvalStackArgumentType in
# parse.def for more info.
#
##############################################################################
[var eval-arg-token-handler-list {
    {0x00  nil 	    	pa-stack-top  ***** 	nil}
    {0x08  nil 	    	pa-num-value  Number    nil}
    {0x09  nil 	    	pa-num-value  Boolean   nil}
    {0x0a  nil 	    	pa-num-value  DateTime  nil}
    {0x10  ESAD_string	pa-string     String    EvalStringData}
    {0x20  ESAD_range  	pa-range      Range 	EvalRangeData}
    {0x40  ESAD_error  	pa-error      Error 	EvalErrorData}
    {0x28  nil 	    	pa-name	      Name  	nil}
    {0x18  nil 	    	pa-func	      Function	nil}
}]

##############################################################################
#				argstack
##############################################################################
#
# SYNOPSIS:	Print out the argument stack
# PASS:		address	- Address of the argument stack (default es:bx)
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/ 2/91	Initial Revision
#
##############################################################################
[defcommand argstack {{address es:bx}} group
{Usage:
    argstack [<address es:bx>]

Examples:
    "argstack"	    	print the argument stack at es:bx
    "argstack ss:di"	print the argument stack at ss:di

Synopsis:
    Print the argument stack in a human readable form.

Notes:

See also:
    opstack
}
{
    global eval-arg-token-handler-list

    #
    # First parse the address.
    #
    var addr [addr-parse $address]
    var han  [handle id [index $addr 0]]
    var seg  [handle segment [index $addr 0]]
    var off  [index $addr 1]
    
    var aseType  [sym find type ArgumentStackElement]

    var type 1
    while {$type} {
    	#
	# Fetch the next structure and info about it.
	#
	var data [value fetch $seg:$off $aseType]
	var type [value fetch $seg:$off.ASE_type [type byte]]
	var type [format {0x%02x} $type]
	var info [assoc [var eval-arg-token-handler-list] $type]

	#
	# Echo the type of the argument
	#
	echo [index $info 3]

	#
	# Call the handler, passing it the data.
	#
	var off [expr $off+1]

	if {![null [index $info 1]]} {
	    var data  [field [field $data ASE_data] [index $info 1]]

	    var dSize [type size [sym find type [index $info 4]]]
	    var off   [expr $off+$dSize]
	}
	var routine [index $info 2]
	var dSize   [$routine $data $seg $off]
	
	#
	# Move to the next structure.
	#
	var off [expr $off+$dSize]
    }
}]

##############################################################################
#				pa-stack-top
##############################################################################
#
# SYNOPSIS:	Print out information about the stack-top (ie: do nothing)
# PASS:		data	- ASE_data field
#   	    	seg 	- segment of start of data
#		off 	- offset of start of data
# CALLED BY:	argstack
# RETURN:	size of additional data
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/ 2/91	Initial Revision
#
##############################################################################
[defsubr pa-stack-top {data seg off}
{
    return 0
}]

##############################################################################
#				pa-num-value
##############################################################################
#
# SYNOPSIS:	Print out information about a number value
# PASS:		data	- ASE_data field
#   	    	seg 	- segment of start of data
#		off 	- offset of start of data
# CALLED BY:	argstack
# RETURN:	size of additional data
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/ 2/91	Initial Revision
#
##############################################################################
[defsubr pa-num-value {data seg off}
{
    return 0
}]

##############################################################################
#				pa-string
##############################################################################
#
# SYNOPSIS:	Print out information about a string value
# PASS:		data	- EvalStringData
#   	    	seg 	- segment of start of data
#		off 	- offset of start of data
# CALLED BY:	argstack
# RETURN:	size of string
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/ 2/91	Initial Revision
#
##############################################################################
[defsubr pa-string {data seg off}
{
    var nBytes [field $data ESD_length]

    echo [format {(length=%d)} $nBytes]
    echo -n {    "}
    var i 0
    while {$nBytes > 0} {
    	var c [value fetch $seg:$off+$i [type byte]]
	echo -n [format {%c} $c]

    	var i [expr $i+1]
	var nBytes [expr $nBytes-1]
    }
    echo {"}
    
    return [field $data ESD_length]
}]

##############################################################################
#				pa-range
##############################################################################
#
# SYNOPSIS:	Print out information about a range
# PASS:		data	- EvalRangeData
#   	    	seg 	- segment of start of data
#		off 	- offset of start of data
# CALLED BY:	argstack
# RETURN:	size of additional data
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/ 2/91	Initial Revision
#
##############################################################################
[defsubr pa-range {data seg off}
{
    var firstRef [field $data ERD_firstCell]
    var lastRef  [field $data ERD_lastCell]
    
    var frC [field [field $firstRef CR_column] CRC_VALUE]
    var frR [field [field $firstRef CR_row] CRC_VALUE]

    var lrC [field [field $lastRef CR_column] CRC_VALUE]
    var lrR [field [field $lastRef CR_row] CRC_VALUE]
    
    #
    # Convert the column to a "AB" format.
    #
    echo -n {    }
    echo -n [format {%s%d} [p-col $frC] [expr $frR+1]]
    echo -n {:}
    echo    [format {%s%d} [p-col $lrC] [expr $lrR+1]]
    
    return 0
}]

##############################################################################
#				p-col
##############################################################################
#
# SYNOPSIS:	Print a column in "AB" format
# PASS:		col 	- column number
# CALLED BY:	pa-range
# RETURN:	string	- the formatted column
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/ 2/91	Initial Revision
#
##############################################################################
[defsubr p-col {col}
{
    var ch {ABCDEFGHIJKLMNOPQRSTUVWXYZ}
    var c1 {}
    var c2 {}
    var c3 {}

    if {$col > [expr 26*26]} {
	var rem [expr $col%26]
	var c1  [index $ch $rem chars]

    	var col [expr $col/26]
    } 
    if {$col > 26} {
	var rem [expr $col%26]
	var c2  [index $ch $rem chars]

    	var col [expr $col/26]
    }

    var rem [expr $col%26]
    var c3  [index $ch $rem chars]
    
    return [format {%s%s%s} $c1 $c2 $c3]
}]


##############################################################################
#				pa-error
##############################################################################
#
# SYNOPSIS:	Print out information about a range
# PASS:		data	- EvalErrorData
#   	    	seg 	- segment of start of data
#		off 	- offset of start of data
# CALLED BY:	argstack
# RETURN:	size of additional data
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/ 2/91	Initial Revision
#
##############################################################################
[defsubr pa-error {data seg off}
{
    var n    [field $data EED_errorCode]
    var name [type emap $n [sym find type ParserScannerEvaluatorError]]
    
    echo [format {    %s} $name]
    return 0
}]

##############################################################################
#				pa-name
##############################################################################
#
# SYNOPSIS:	Print out information about a name
# PASS:		data	- EvalNameData
#   	    	seg 	- segment of start of data
#		off 	- offset of start of data
# CALLED BY:	argstack
# RETURN:	size of additional data
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/ 2/91	Initial Revision
#
##############################################################################
[defsubr pa-name {data seg off}
{
    return 0
}]

##############################################################################
#				pa-func
##############################################################################
#
# SYNOPSIS:	Print out information about a user defined function
# PASS:		data	- EvalFuncData
#   	    	seg 	- segment of start of data
#		off 	- offset of start of data
# CALLED BY:	argstack
# RETURN:	size of additional data
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/ 2/91	Initial Revision
#
##############################################################################
[defsubr pa-func {data seg off}
{
    echo {User Defined Function}
    return 0
}]


##############################################################################
#			  eval-op-token-handler-list
#
# An assoc list of eval operator/function tokens and handlers for printing them.
# Each entry is of the form
#   	    {opType dataType handler tokenName}
#
##############################################################################
[var eval-op-token-handler-list {
    {ESOT_OPERATOR  	ESOD_operator	    	po-operator	    Operator}
    {ESOT_FUNCTION  	ESOD_function	    	po-function	    Function}
    {ESOT_OPEN_PAREN	nil 	    	    	po-open-paren 	    OpenParen}
    {ESOT_TOP_OF_STACK	nil 	    	    	po-stack-top 	    *****}
}]

##############################################################################
#				opstack
##############################################################################
#
# SYNOPSIS:	Print the operator stack in human readable form.
# PASS:		addr	= Address of the operator stack (default es:di)
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	?
#
# STRATEGY
#   The operator stack grows from the bottom.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/ 2/91	Initial Revision
#
##############################################################################
[defcommand opstack {{address es:di}} parse
{Usage:
    opstack [<address es:di>]

Examples:
    "opstack"	    	print the operator stack at es:di
    "opstack ss:bx"  	print the operator stack at ss:bx

Synopsis:
    Print the operator stack in a human readable form.

Notes:

See also:
    argstack
}
{
    global eval-op-token-handler-list

    #
    # First parse the address.
    #
    var addr [addr-parse $address]
    var han  [handle id [index $addr 0]]
    var seg  [handle segment [index $addr 0]]
    var off  [index $addr 1]
    
    var oseType  [sym find type OperatorStackElement]
    var esotType [sym find type EvalStackOperatorType]
    
    var oseSize [type size $oseType]
    
    var type foo
    while {[string compare $type ESOT_TOP_OF_STACK]} {
    	#
	# Fetch the next structure and info about it.
	#
	var data [value fetch $seg:$off $oseType]
	var type [type emap [field $data OSE_type] $esotType]
	var info [assoc [var eval-op-token-handler-list] $type]

	#
	# Echo the type of the operator
	#
	echo [index $info 3]

	#
	# Call the handler, passing it the data.
	#
	if {![null [index $info 1]]} {
	    var data [field [field $data OSE_data] [index $info 1]]
	}
	var routine [index $info 2]
	[$routine $data]
	
	#
	# Move to the next structure.
	#
	var off [expr $off-$oseSize]
    }
}]

##############################################################################
#				po-operator
##############################################################################
#
# SYNOPSIS:	print an operator on the eval stack
# PASS:		data	- EvalOperatorData
# CALLED BY:	opstack
# RETURN:	nothing
# SIDE EFFECTS:	nothing
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/ 2/91	Initial Revision
#
##############################################################################
[defsubr po-operator {data}
{
    var type [type emap [field $data EOD_opType] [sym find type OperatorType]]
    
    echo [format {    %s} $type]
}]

##############################################################################
#				po-function
##############################################################################
#
# SYNOPSIS:	Print out a function
# PASS:		data	- EvalFunctionData
# CALLED BY:	opstack
# RETURN:	nothing
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/ 2/91	Initial Revision
#
##############################################################################
[defsubr po-function {data}
{
    var func [type emap [field $data EFD_functionID] [sym find type FunctionID]]
    var nArgs [field $data EFD_nArgs]
    
    echo [format {    %s, %d arg(s)} $func $nArgs]
}]

##############################################################################
#				po-open-paren
##############################################################################
#
# SYNOPSIS:	Print an open-paren (do nothing)
# PASS:		mystery data
# CALLED BY:	opstack
# RETURN:	nothing
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/ 2/91	Initial Revision
#
##############################################################################
[defsubr po-open-paren {data}
{
}]

##############################################################################
#				po-stack-top
##############################################################################
#
# SYNOPSIS:	Note that we're at the stack top (do nothing)
# PASS:		mystery data
# CALLED BY:	opstack
# RETURN:	nothing
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/ 2/91	Initial Revision
#
##############################################################################
[defsubr po-stack-top {data}
{
}]

