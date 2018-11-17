##############################################################################
#
# 	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	ignerr.tcl
# AUTHOR: 	???
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	ignerr	    	    	continue from the frame above the 
#    	    	    	    	fatal error handler
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	roger	5/27/91		First installed version
#
# DESCRIPTION:
#	Function to continue after a fatal error.
#
#	$Id: ignerr.tcl,v 1.11.11.1 97/03/29 11:27:36 canavese Exp $
#
###############################################################################

[defcmd ignerr {{addr {}}} top.crash
{Usage:
    ignerr [<address>]

Examples:
    "ignerr"	    	    ignore error and continue
    "ignerr MyFunc::done"   ignore error and continue at MyFunc::done

Synopsis:
    Ignore a fatal error and continue.

Notes:
    * The address argument is the address of where to continue
      execution.  If not specified then cs:ip is taken from the frame.

    * The stack is patched so that execution can continue in the frame
      above the fatal error handling routine.

See also:
    why, backtrace.
}
{
    assign geos::dgroup::errorFlag -1
    var t [frame top]
    var f [frame next $t] i 2
    if {[string c [frame function $f] AppFatalError] == 0} {
    	var f [frame next $f] i 6
    }
    if {[null $addr]} {
	frame setreg ip [frame register ip $f]+3 $t
	frame setreg cs [frame register cs $f] $t
    } else {
    	var a [addr-parse $addr]
	frame setreg ip [index $a 1] $t
	frame setreg cs [handle segment [index $a 0]] $t
    }
    #
    # Assign this *last* so it doesn't invalidate the frames we've got...
    #
    assign sp [frame register sp $f]+$i
    cont -f
}]
