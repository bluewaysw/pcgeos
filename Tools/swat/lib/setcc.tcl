##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat System Library -- Condition Code setting
# FILE: 	setcc.tcl
# AUTHOR: 	Adam de Boor, Jul 14, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	setcc	    	    	Set/Reset a condition code
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/14/89		Initial Revision
#
# DESCRIPTION:
#	Help for assignment
#
#	$Id: setcc.tcl,v 3.3 91/01/24 18:10:23 roger Exp $
#
###############################################################################
[defcommand setcc {flag {value 1}} top
{setcc flag [value]
"setcc c"   	sets the carry flag
"setcc z 0" 	clears the zero flag

Set a flag in the computer.

* The first argument is the first letter of the flag to set.  The
following is a list of the flags:

    t	trap
    i	interrupt enable
    d	direction
    o	overflow
    s	sign
    z	zero
    a	auxiliary carry
    p	parity
    c	carry

* The second argument is the value to assign the flag.  It defaults to
1 but may be 0 to clear the flag.

See also clrcc, compcc.
}
{
    global flags

    # force the flag character to uppercase.
    scan $flag %c flag
    var flag [format %c [expr $flag&~32]]

    #
    # Find the bit for the thing in the flags assoc list set up by
    # swat.tcl
    #
    var bit [assoc $flags ${flag}F]
    if {[null $bit]} {
	error [format {There is no %sF flag.  Type 'help setcc' for a list.} $flag]
    } elif {$value} {
	assign cc [expr {[read-reg cc]|[index $bit 1]}]
    } else {
	assign cc [expr {[read-reg cc]&~[index $bit 1]}]
    }
}]



[defdsubr clrcc {flag} top
{clrcc flag [value]
"clrcc c"   	clears the carry flag

Clear a flag in the computer.

* The first argument is the first letter of the flag to clear.  The
following is a list of the flags:

    t	trap
    i	interrupt enable
    d	direction
    o	overflow
    s	sign
    z	zero
    a	auxiliary carry
    p	parity
    c	carry

See also setcc, compcc.
}
{
    setcc $flag 0
}]


[defdsubr compcc {flag} top
{compcc flag
"compcc c"   	complements the carry flag

Complements a flag in the computer.

* The first argument is the first letter of the flag to complement.
The following is a list of the flags:

    t	trap
    i	interrupt enable
    d	direction
    o	overflow
    s	sign
    z	zero
    a	auxiliary carry
    p	parity
    c	carry

This command is handy to insert in a patch to flip a flag bit.

See also setcc, clrcc.
}
{
    global flags

    # force the flag character to uppercase.
    scan $flag %c flag
    var flag [format %c [expr $flag&~32]]

    #
    # Find the bit for the thing in the flags assoc list set up by
    # swat.tcl
    #
    var bit [assoc $flags ${flag}F]

    if {[null $bit]} {
	error [format {There is no %sF flag.  Type 'help compcc' for a list.} $flag]
    } elif {[expr {[read-reg cc]&[index $bit 1]}]} {
	assign cc [expr {[read-reg cc]&~[index $bit 1]}]
    } else {
	assign cc [expr {[read-reg cc]|[index $bit 1]}]
    }
}]
