##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	SWAT -- System library.
# FILE: 	whatat.tcl
# AUTHOR: 	Tony
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	whatat	    	    	Print an object out given its address.
#
# DESCRIPTION:
#	A function to print the name of a variable at an address
#
#	$Id: whatat.tcl,v 3.0 90/02/04 23:48:39 adam Exp $
#
###############################################################################

[defcommand whatat {addr} output
{Given an address, print the name of the variable at that address}
{
    var a [sym faddr var $addr]
    if {[null $a]} {
	echo *nil*
    } else {
	echo [sym name $a]
    }
}]
