##############################################################################

# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
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
#	$Id: wintree.tcl,v 3.12 93/07/31 21:51:04 jenny Exp $
#
###############################################################################

[defcmd wintree {{win {}} {extrafield 0} {indent 0}} object.hierarchies
{Usage:
    wintree <window handle> [<data field>]

Examples:
    "wintree ^hd060h"	    print a window tree starting at the handle d060h

Synopsis:
    Print a window tree starting with the root specified.

Notes:
    * The window address argument is the address to a window.

    * The data field argument is the offsest to any instance data 
      within a window (like W_ptrFlags).

See also:
    vistree, gentree.
}
{	
    #Set default window tree
    if {[null $win]} {
    	require screenwin user.tcl

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
    var a [addr-preprocess $win seg off]

    # Store window address away in value history
    var hist [value hstore [concat [range $a 0 1] 
				   [list [symbol find type Window]]]]

    # Do some indenting to make things pretty, and print the object info
    echo -n [format {%*s} [expr $indent*4] {}]
    echo [format {@%s Window block ^h%xh at %xh:0 = \{} $hist $handle 
    	    [handle segment [index $a 0]]]

    echo -n [format {%*s} [expr ($indent+1)*4] {}]
    print $win.W_inputObj
    echo

    echo -n [format {%*s} [expr ($indent+1)*4] {}]
    echo [format {W_winRect = %d, %d, %d, %d} $left $top $right $bottom]

    if {[string c $extrafield 0] != 0} {
        foreach i $extrafield {
            print $win.$i
        }
    }


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

