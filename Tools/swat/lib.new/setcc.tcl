##############################################################################
#
# 	Copyright (c) GeoWorks 1989 -- All Rights Reserved
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
#	$Id: setcc.tcl,v 3.10 93/07/31 22:15:49 jenny Exp $
#
###############################################################################
[defcmd setcc {flag {value 1}} flag
{Usage:
    setcc <flag> [<value>]

Examples:
    "setcc c"   	set the carry flag
    "setcc z 0" 	clear the zero flag

Synopsis:
    Set a flag in the computer.

Notes:
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

    * The second argument is the value to assign the flag.  It
      defaults to 1 but may be 0 to clear the flag.

See also:
    getcc, clrcc, compcc.
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



[defcommand clrcc {flag} flag
{Usage:
    clrcc <flag> [<value>]

Examples:
    "clrcc c"       clear the carry flag

Synopsis:
    Clear a flag in the computer.

Notes:
    * The first argument is the first letter of the flag to clear.
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

See also:
    setcc, compcc, getcc.
}
{
    setcc $flag 0
}]


[defcommand compcc {flag} flag
{Usage:
    compcc <flag>

Examples:
    "compcc c"   	complement the carry flag

Synopsis:
    Complement a flag in the computer.

Notes:
    * The first argument is the first letter of the flag to
      complement.  The following is a list of the flags:

        t	trap
        i	interrupt enable
        d	direction
        o	overflow
        s	sign
        z	zero
        a	auxiliary carry
        p	parity
        c	carry

    * This command is handy to insert in a patch to flip a flag bit.

See also:
    setcc, clrcc, getcc.
}
{
    setcc $flag [expr [getcc $flag]^1]
}]


[defcommand clrcc {flag} flag
{Usage:
    clrcc <flag> [<value>]

Examples:
    "clrcc c"       clear the carry flag

Synopsis:
    Clear a flag in the computer.

Notes:
    * The first argument is the first letter of the flag to clear.
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

See also:
    setcc, getcc, compcc.
}
{
    setcc $flag 0
}]


[defcommand getcc {flag} flag
{Usage:
    getcc <flag>

Examples:
    "getcc c"   	get the carry flag

Synopsis:
    Get a flag in the computer.

Notes:
    * The first argument is the first letter of the flag to
      get.  The following is a list of the flags:

        t	trap
        i	interrupt enable
        d	direction
        o	overflow
        s	sign
        z	zero
        a	auxiliary carry
        p	parity
        c	carry

    * This command is handy to run with a breakpoint to stop if a flag is set.
      
See also:
    setcc, clrcc, compcc.
}
{
    global flags

    # force the flag character to uppercase.
    scan $flag %c flag
    var convflag [format %c [expr $flag&~32]]

    #
    # Find the bit for the thing in the flags assoc list set up by
    # swat.tcl
    #
    var bit [assoc $flags ${convflag}F]

    if {[null $bit]} {
	error [format {There is no "%c" flag.  Type 'help getcc' for a list.} $flag]
    } else {
    	if {[read-reg cc] & [index $bit 1]} {
		return 1
	} else {
		return 0
	}
    }
}]
