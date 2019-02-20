##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	wintree.tcl
# AUTHOR: 	Doug Fults, May 2, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	wintree		    	Print out window tree
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	doug	5/2/89		Initial Revision
#
# DESCRIPTION:
#	Window commands
#
#	$Id: wintree.tcl,v 3.1 90/03/02 03:19:08 doug Exp $
#
###############################################################################

[defcommand wintree {{win 0} {extrafield 0} {indent 0}} output
{Prints out a window tree starting with the root specified.  A second
argument may be passed, which is the offset to any instance data within
a Window which should be printed out.  (For isntance, W_ptrFlags)}
{	
    #Set default window tree
    if {[string compare $win 0]==0} {
        var win [screenwin]
    }
    if {$indent == 0} {
        echo
    	echo Window tree
	echo -----------
    }
    windowtree $win $extrafield $indent
    if {$indent == 0} {
	echo
    }
}]
	
[defsubr windowtree {win extrafield indent}
{
    # Fetch data out of the window structure
    var handle [value fetch $win.LMBH_handle]
    var left [value fetch $win.W_winRect.R_left]
    var top [value fetch $win.W_winRect.R_top]
    var right [value fetch $win.W_winRect.R_right]
    var bottom [value fetch $win.W_winRect.R_bottom]

    # Figure out the segment address of the window block
    var seg [handle segment [index [addr-parse $win] 0]]

    # Store window address away in value history
    var hist [value hstore [addr-parse {Window $win}]]

    # Do some indenting to make things pretty, and print the object info
    echo -n [format {%*s} [expr $indent*4] {}]
    echo [format {@%s Window block ^h%x at %x:0 = \{} $hist $handle $seg]

    echo -n [format {%*s} [expr ($indent+1)*4] {}]
    echo -n W_inputOD = 
    printOD [value fetch $win.W_inputOD]
    echo

    echo -n [format {%*s} [expr ($indent+1)*4] {}]
    echo [format {W_winRect = %d, %d, %d, %d} $left $top $right $bottom]

    if {[string c $extrafield 0] != 0} {print $win.$extrafield}

    if {[value fetch $win.W_firstChild] != 0} {
    echo -n [format {%*s} [expr ($indent+1)*4] {}]
    echo W_children = \[
    echo
    }

    # call windowtree on each child, upping the level of indentation each time
     [for {var child [value fetch $win.W_firstChild]}
	{$child != 0}
	{var child [value fetch ^h$child.W_nextSibling]}
	{windowtree ^h$child $extrafield [expr $indent+2]}
    ]
    if {[value fetch $win.W_firstChild] != 0} {
    echo [format {%*s} [expr ($indent+1)*4] {}]\]
    }

    echo [format {%*s} [expr $indent*4] {}]\}
    
    return
}]

[defsubr printOD {val}
{
    var odoff [index [index $val 0] 2]
    var odseg [index [index $val 1] 2]
    if {$odseg == 0} {
	echo -n Unconnected
	return 1
    }
    var odhan [handle lookup $odseg]
    if {[null $odhan] || ![handle ismem $odhan]} {
	echo -n [format {Invalid (%04x:%04x)} $odseg $odoff]
    } else {
	if {$odhan == [handle owner $odhan]} {
	    echo -n [format {Process "%s", data = %04x}
			    [patient name [handle patient $odhan]]
			    $odoff]
	} else {
    	    var csym [sym faddr var *(^l$odseg:$odoff).MB_class]
	    if {[null $csym]} {
		echo -n [format {Obj, class ? at ^l%04x:%04x}
				$odseg $odoff]
	    } else {
		var cname [sym fullname $csym]
		echo -n [format {Obj, class "%s", at ^l%04x:%04x}
		    	    [obj-name $cname {}] $odseg $odoff]
	    }
	}
    }
    return 1
}]


