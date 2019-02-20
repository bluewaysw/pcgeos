##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	region.tcl
# AUTHOR: 	Adam de Boor, Apr 13, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	preg	    	    	Print out a region graphically
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/13/89		Initial Revision
#
# DESCRIPTION:
#	Functions related to regions
#
#	$Id: region.tcl,v 3.1 90/11/14 19:01:29 gene Exp $
#
###############################################################################
[defdsubr preg {args} output
{Print out the region at the given address. If first arg is -g, the region
is printed as a series of x's and spaces (useful only for small regions).
If no address given, uses the last-accessed address (as per "bytes" and
"words"). Sets the last address to the first byte after the region definition.}
{
    if {[string c [index $args 0] -g] == 0} {
    	var graph 1 addr [range $args 1 end]
    } else {
	var graph 0 addr $args
    }
    
    var lsl -0x4000 paddr [addr-parse [get-address $addr]]
    if {[null [index $paddr 0]]} {
    	var handle {}
    } else {
    	var handle ^h[handle id [index $paddr 0]]:
    }
    var offset [index $paddr 1]
    
    while {![irq]} {
    	var sl [value fetch $handle$offset [type short]]
	if {$sl == -32768} {
    	    # Hit the end of the region -- get out of here
	    break
    	}
    	var offset [expr $offset+2] line {} lo 0 first 1
	while {![irq]} {
	    [var fo [value fetch $handle$offset [type word]] 
		 offset [expr $offset+2]]
	    if {$fo == 0x8000} {
	    	break
	    }

	    if {$graph} {
	    	[var line $line[format {%*s} [expr $fo-$lo] {}]
	    	     lo [value fetch $handle$offset [type word]]
		     offset [expr $offset+2]]
	    	for {var on {}} {$fo <= $lo} {var on ${on}x fo [expr $fo+1]} {}
	    	var line $line$on
	    } else {
	    	var line [format {%s%s%d to %d } $line
		    	    [if {$first} {format {}} {format {, }}]
		    	    $fo [value fetch $handle$offset [type word]]]
		var offset [expr $offset+2]
	    }
	    var first 0
	}
	if {$graph} {
	    while {$lsl <= $sl} {
		echo $line
		var lsl [expr $lsl+1]
	    }
	} else {
	    echo [format {Lines %4d to %4d:} $lsl $sl] $line
	    var lsl $sl
	}
    }
    set-address $handle$offset
}]
	
