##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat System Library -- Source Handling
# FILE: 	srclist.tcl
# AUTHOR: 	Adam de Boor, Feb  4, 1990
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	slist	    	    	List source lines
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/ 4/90		Initial Revision
#
# DESCRIPTION:
#	Functions for handling source code.
#
#	$Id: srclist.tcl,v 3.2 90/03/11 17:55:47 adam Exp $
#
###############################################################################
[defcommand slist {args} top
{List source lines in a given range. The range may be any of the following:
    <address>	    	    Lists the 10 lines around the given address
    <line>		    Lists the given line in the current file
    <file>::<line>	    Lists the line in the given file
    <line1>,<line2>	    Lists the lines between line1 and line2,
			    inclusive, in the current file
    <file>::<line1>,<line2>  Lists the range from <file>
}
{
    global src-last-line repeatCommand lastCommand

    if {[length $args] == 0} {
	[if {[catch {src line [get-address $args]} fileLine] != 0 ||
	     [null $fileLine]}
	{
	    error {No line information available for current address}
	} else {
	    var file [index $fileLine 0]
	    var start [index $fileLine 1]
	    var end [expr $start+9]
	}]
    } else {
	[if {[string first : [index $args 0]] != -1 &&
	     [scan [index $args 0] {%[^:]::%d,%d} file start end] > 1}
    	{
    	    if {[null $end]} {
		var end $start
	    }
	} else {
	    var i [scan [index $args 0] {%d,%d} start end]
	    if {$i == 0} {
    	    	[if {[catch {src line $args} fileLine] != 0 ||
		     [null $fileLine]}
    	    	{
		    error [format {No line information available for %s}
		    	    	$args]
    	    	} else {
		    var file [index $fileLine 0] start [expr [index $fileLine 1]-4]
		    var end [expr $start+9]
    	    	}]
	    } else {
		if {$i == 1} {
		    var end $start
		}
    	    	#XXX: record last file used...
    	    	[if {[catch {src line [get-address {}]} fileLine] != 0 ||
		     [null $fileLine]}
		{
		    error {Cannot determine file you want}
    	    	} else {
		    var file [index $fileLine 0]
		}]
	    }
	}]
    }
    [for {var i $start}
	 {$i <= $end}
	 {var i [expr $i+1]}
     {
    	if {[catch {src read $file $i} line] == 0} {
	    echo $i: [src read $file $i]
    	} else {
	    break
    	}
     }]
    var repeatCommand [format {%s %s::%d,%d} [index $lastCommand 0]
    	    	    	    $file [expr $end+1] [expr $end+($end-$start)+1]]
}]

