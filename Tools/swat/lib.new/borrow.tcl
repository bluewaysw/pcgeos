#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library -- ThreadBorrowStackSpace
# FILE:		borrow.tcl
# AUTHOR:	John Wedgwood,  1/14/93
#
# COMMANDS:
#	Name			Description
#	----			-----------
#   	bwatch    	    	Watch borrowing in action.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	john	 1/14/93	Initial revision
#
# DESCRIPTION:
#
#	$Id: borrow.tcl,v 1.4 93/10/11 16:27:41 joon Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


##############################################################################
#				bwatch
##############################################################################
#
# SYNOPSIS:	Watch stack-borrowing in action
# CALLED BY:	user
# PASS:	    	onOff	- "on" to turn it on, "off" to turn it off
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 1/14/93	Initial Revision
#
##############################################################################
defvar bwatchOnOff off

[defcommand bwatch {{onOff {}}} {profile thread}
{Usage:
    bwatch [on|off]

Examples:
    "bwatch on"	    	    Watch stack borrowing
    "bwatch"	    	    Check the status of bwatch

Synopsis:
    Watch stack borrowing in action
}
{
    global  bwatchOnOff
    global  bwatchIndent

    if {[null $onOff]} {
	#
	# No argument, print the status
	#
    	echo {bwatch is} [var bwatchOnOff]

    } elif {![string compare $onOff on]} {
    	#
	# User wants it on, turn it on and initialize stuff
	#
	nuke-bwatch-breakpoints

	var bwatchOnOff on
    	var bwatchIndent 0
	
	set-bwatch-breakpoints

    } elif {![string compare $onOff off]} {
    	#
	# User wants it off, turn it off...
	#
	nuke-bwatch-breakpoints

	var bwatchOnOff off
    
    } else {
    	#
	# User is confused...
	#
	echo {Usage: bwatch [on|off]}
    }
}]


[defsubr nuke-bwatch-breakpoints {}
{
    global  bwatchBreakpoints
    
    if {![null $bwatchBreakpoints]} {
    
    	foreach i $bwatchBreakpoints {
    	    catch {brk clear $i}
    	}

    	var bwatchBreakpoints {}
    }
}]


[defsubr set-bwatch-breakpoints {}
{
    global  bwatchBreakpoints

    if {[null $bwatchBreakpoints]} {
	
    	var bwatchBreakpoints [list
	    	[brk kcode::ThreadBorrowStackSpace borrow-start]
	    	[brk kcode::ThreadReturnStackSpace borrow-end]
	]
    }
}]


[defsubr borrow-start {}
{
    global bwatchIndent

    echo [format {%*s >>%s} $bwatchIndent {}
    	    [sym fullname [frame funcsym [frame next [frame top]]]]
    	    	]
    
    var bwatchIndent [expr $bwatchIndent+2]
    return 0
}]


[defsubr borrow-end {}
{
    global bwatchIndent

    var bwatchIndent [expr $bwatchIndent-2]

    echo [format {%*s <<%s (%04xh)} $bwatchIndent {}
    	    [sym fullname [frame funcsym [frame next [frame top]]]]
    	    [read-reg di]]
    
    return 0
}]


