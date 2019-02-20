##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	loop.tcl
# FILE: 	loop.tcl
# AUTHOR: 	Adam de Boor, Feb  9, 1990
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	loop	    	    	simple integer loop procedure
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/ 9/90		Initial Revision
#
# DESCRIPTION:
#	Extra looping constructs for use by tcl procedures.
#
#	$Id: loop.tcl,v 3.2 90/02/26 23:39:12 adam Exp $
#
###############################################################################
[defdsubr loop {v range args} prog
{Simple integer loop procedure. Usage is:

	loop <loop-variable> <start>,<end> [step <step>] <body>

<start>, <end>, and <step> are integers. <body> is a string for
TCL to evaluate. If no <step> is given, 1 or -1 (depending as <start>
is less than or greater than <end>, respectively) is used. <loop-variable>
is any legal TCL variable name.}
{
    #
    # Fetch the start and end from the second argument
    #
    if {[scan $range {%d,%d} start end] != 2} {
	error {Improper format for range}
    } else {
	[if {([length $args] == 3) &&
	    ([string compare [index $args 0] step] == 0)}
	{
	    #
	    # step given -- set step value from 4th arg and body from 5th
	    #
	    var step [index $args 1]
	    var body [index $args 2]
	} else {
	    if {$start > $end} {
		#
		# start greater than end -- count down
		#
		var step -1
	    } else {
		#
		# end greater than start -- count up
		#
		var step 1
	    }
	    var body [index $args 0]
	}]
	#
	# Figure out end condition based on relation of start to end
	#
	if {$start < $end} {
	    var cmp {<=}
	} else {
	    var cmp {>=}
	}
	#
    	# Execute a 'for' loop in our caller's context.
	#
    	uplevel 1 [list for [list var $v $start]
	     	    	    [format {$%s %s %s}  $v $cmp $end]
	     	    	    [format {var %s [expr $%s+(%s)]} $v $v $step]
	     	    	    $body]
    }
}]
