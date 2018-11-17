##############################################################################
#
# 	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	SWAT -- System library.
# FILE: 	mcount.tcl
# AUTHOR: 	Roger Flores
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#	mcount			keep a count of methods called
#
# DESCRIPTION:
#	For keeping count of method calls
#
#	$Id: mcount.tcl,v 3.6.12.1 97/03/29 11:25:56 canavese Exp $
#
###############################################################################


[defcmd mcount {args} object.message
{Usage:
    mcount [<args>]

Examples:
     "mcount"	    start the method count or print the count
    "mcount reset"  restart the method count
    "mcount stop"   stop the method count
    "mcount MyAppRecalcSize"	count methods handled by MyAppRecalcSize

Synopsis:
    Keep a count of the methods called.

Notes:
    * The args argument may be one of the following:
    	nothing	    	start the method count or print the current count
    	'reset'	    	reset the count to zero
    	'stop'	    	stop the method count and remove it's breakpoint
    	method handler	start the method count for a particular method

See also:
    mwatch, showcalls.
}
{
    global	mvar _mbrk

    if {[string c $args stop] == 0} {
    	if {[null $_mbrk]} {return 0}
    	echo $mvar
    	brk clear $_mbrk
    	var _mbrk {}
    	return
    }
    if {[null $args] && ![null $_mbrk]} {
    	echo $mvar
    	return
    }
    if {[string c $args reset] == 0} {
    	var mvar 0
    	return
    }

    var old_mbrk $_mbrk
    if {[null $args]} {
    	var args CallMethod
    	echo Counting all method calls.
    }
    var result [catch {[brk aset $args _mincr]} _mbrk]
    if {$result == 0} {
    	var mvar 0
    	if {![null $old_mbrk]} {
    	    brk clear $old_mbrk
    	}

    } else {
    	echo There is no method '$args'.
    	var _mbrk $old_mbrk
    }
}]

defsubr _mincr {} {
    global	mvar

    var mvar [expr $mvar+1]
}
