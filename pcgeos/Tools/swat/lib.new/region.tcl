##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
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
#	$Id: region.tcl,v 3.12 94/01/18 13:40:36 jimmy Exp $
#
###############################################################################
##############################################################################
#				convert-param-region
##############################################################################
#
# SYNOPSIS:	convert a word taken from a possibly-parameterized region
#   	    	into the appropriate parameter name +/- an offset
# PASS:		val 	= word to convert, fetched as a short
#   	    	graph	= non-zero to return just the appropriate offset
#   	    	    	  zero to return printable string
# CALLED BY:	preg
# RETURN:	printable string or straight offset, with PARAM_? constant
#   	    	removed, depending on $graph
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/ 9/92		Initial Revision
#
##############################################################################
[defsubr convert-param-region {val graph}
{
    var val [expr $val&0xffff]
    if {$val > 0x3fff && $val < 0xc000} {
    	[case [format %4x [expr $val&0xf000]] in
    	 4000 {var off [expr $val-0x5000] param PARAM_0}
    	 6000 {var off [expr $val-0x7000] param PARAM_1}
    	 8000 {var off [expr $val-0x9000] param PARAM_2}
    	 a000 {var off [expr $val-0xb000] param PARAM_3}

    	 5000 {var off [expr $val-0x5000] param PARAM_0+}
    	 7000 {var off [expr $val-0x7000] param PARAM_1+}
    	 9000 {var off [expr $val-0x9000] param PARAM_2+}
    	 b000 {var off [expr $val-0xb000] param PARAM_3+}]

    	if {$graph} {
	    return $off
    	} else {
    	    return $param$off
    	}
    } elif {$val > 0xc000} {
    	# negative coordinate, but we stripped off the sign-extension...
    	return [expr $val|0xffff0000]
    } else {
    	return $val
    }
}]
    	
    	
##############################################################################
#				region-get-bounds
##############################################################################
#
# SYNOPSIS:	    Figure the bounds of the passed region
# PASS:		    addr    = start of the region
#   	    	    [length]= max length of the region
# CALLED BY:	    EXTERNAL
# RETURN:	    5-list: {left top right bottom length}
#   	    	    empty list if region is bogus
# SIDE EFFECTS:	    none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/24/92		Initial Revision
#
##############################################################################
[defsubr region-get-bounds {addr size vertOffset}
{
    if {[value fetch ($addr)+2 [type word]] != 0x8000} {
	# if second word isn't EOREGREC, assume it's a region
	# with a bounding rectangle at the front.
	var left [value fetch ($addr).R_left]
	var right [value fetch ($addr).R_right]
	var top [value fetch ($addr).R_top]
	var bottom [value fetch ($addr).R_bottom]
	var cp $size
    } else {
	var left 32000
	var right -1
	# start out pointing at first yval
	var cp 4
	var yval [value fetch ($addr)+$cp short]
	var top [expr [value fetch ($addr) short]+1+$vertOffset]
	do {
	    # cp points at yValue
	    var bottom [expr $yval+$vertOffset]
	    var cp [expr $cp+2]
	    #cp points at first on value for line
	    var firstOn [value fetch ($addr)+$cp short]
	    if {$firstOn != -32768} {
		if {$firstOn < $left} {var left $firstOn}
		do {
		    var cp [expr $cp+4]
		} while {[value fetch ($addr)+$cp short] != -32768}
		# cp points at EOREGREC at end of line
		var lastOn [value fetch ($addr)+$cp-2 short]
		if {$lastOn > $right} {var right $lastOn}
	    }
	    var cp [expr $cp+2]
	    # cp points at yVal for start of next section
	    var yval [value fetch ($addr)+$cp short]
	} while {$yval != -32768 && $cp < $size}
	if {$yval != -32768} {
	    return {}
    	}
    }
    
    return [list $left $top $right $bottom $cp]
}]
    

[defcommand preg {args} lib_app_driver.graphics
{Usage:
    preg [-g] <addr>

Examples:
    "preg *es:W_appReg"	    Prints the application-defined clipping region
			    for the window pointed to by es.
    "preg -g ds:si" 	    Prints a "graphical" representation of the
			    region beginning at ds:si
    "preg -d ds:si" 	    Prints a region based on document coordinates

Synopsis:
    Decodes a GEOS region and prints it out, either numerically, or as
    a series of x's and spaces.

Notes:
    * This command can deal with parameterized regions. When printing a
      parameterized region with the -g flag, the region is printed as if
      it were unparameterized, with the offsets from the various PARAM
      constants used as the coordinates.

    * If no address is given, this will use the last-accessed address (as
      the "bytes" and "words" commands do). It sets the last-accessed
      address, for other commands to use, to the first byte after the region
      definition.

See also:
}
{
    if {[string c [index $args 0] -g] == 0} {
    	var graph 1
    	var args [range $args 1 end]
    } else {
	var graph 0
    }
    if {[string c [index $args 0] -d] == 0} {
    	var vertOffset -1
    	var args [range $args 1 end]
    } else {
	var vertOffset 0
    }
    var addr $args
    
    var lsl -infinity paddr [addr-preprocess [get-address $addr] seg offset]

    if {[value fetch $seg:$offset word]==0x8000 &&
    	[value fetch $seg:$offset+2 word]==0x8000} {
    	echo {NULL region}
    	return
    }
    var bounds [region-get-bounds $seg:$offset 65536 $vertOffset]
    if {$graph} {
	var left [convert-param-region [index $bounds 0] 1]
	echo Left edge is at $left
    } else {
    	echo [format {Region bounds: (%s, %s) to (%s, %s)}
    	    	[convert-param-region [index $bounds 0] 0]
    	    	[convert-param-region [index $bounds 1] 0]
    	    	[convert-param-region [index $bounds 2] 0]
    	    	[convert-param-region [index $bounds 3] 0]]
    }
    if {[value fetch $seg:$offset+2 [type word]] != 0x8000} {
    	var offset [expr $offset+8]
    }

    
    while {![irq]} {
    	var sl [value fetch $seg:$offset [type word]]
	if {$sl == 0x8000} {
    	    # Hit the end of the region -- get out of here
	    break
    	}

    	var nsl [convert-param-region [expr $sl+1] $graph]
	var numsl $sl
	var sl [convert-param-region $sl $graph]
    	var offset [expr $offset+2] line {} first 1
	if {$graph} {
	    var lo $left
    	} else {
	    var lo 0
    	}
	while {![irq]} {
	    [var fo [value fetch $seg:$offset [type word]] 
		 offset [expr $offset+2]]
	    if {$fo == 0x8000} {
	    	break
	    }

	    var fo [convert-param-region $fo $graph]

	    if {$graph} {
	    	[var line $line[format {%*s} [expr $fo-$lo] {}]
	    	     lo [convert-param-region 
		     	    [value fetch $seg:$offset [type word]]
			    $graph]
		     offset [expr $offset+2]]
	    	for {var on {}} {$fo <= $lo} {var on ${on}x fo [expr $fo+1]} {}
	    	var line $line$on
	    } else {
	    	var line [format {%s%s%s to %s } $line
		    	    [if {$first} {format {}} {format {, }}]
		    	    $fo [convert-param-region
			    	 [expr [value fetch $seg:$offset [type word]]+$vertOffset]
				 $graph]]
		var offset [expr $offset+2]
	    }
	    var first 0
	}
	if {$graph} {
    	    if {[string c $lsl -infinity]} {
	    	while {$lsl <= $sl} {
		    echo $line
		    var lsl [expr $lsl+1+$vertOffset]
	    	}
    	    }
	} else {
	    echo [format {Lines %4s to %4s:} $lsl $sl] $line
	}
	var lsl [convert-param-region [expr $numsl+1+$vertOffset] $graph]
    }
    set-address $seg:$offset
}]
	
