##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	active.tcl
# FILE: 	active.tcl
# AUTHOR: 	Gene Anderson, Jun 10, 1992
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	pactive	    	    	Print the active list for an object
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	6/10/92		Initial Revision
#
# DESCRIPTION:
#	TCL commands for dealing with the active list.
#
#	$Id: active.tcl,v 1.1.30.1 97/03/29 11:25:54 canavese Exp $
#
###############################################################################

##############################################################################
#				pactive
##############################################################################
#
# SYNOPSIS:	print the active list for an object
# PASS:		obj - object to print active list for
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	6/10/92		Initial Revision
#
##############################################################################

[defcommand pactive {{obj {*ds:si}}} {ui object}
{Usage:
    pactive [<obj>]

Examples:
    "pactive"		print the active list for the object at *ds:si
    "pactive ^lbx:si"	print the active list for the object at ^lbx:si

Synopsis:
    Print the active list for an object.

Notes:
    * If no object is specified, *ds:si is used.

    * The object must be subclassed off GenActiveListClass, or it doesn't
      have any active list.  A GenPrimary has an active list, and is the
      most common object to print the active list for.

See also:
    printobj
}
{
    	#
    	# Make sure the object has an active list
    	#
    	if {[is-obj-in-class $obj GenActiveListClass]} {
	    #
    	    # Get the address of the object
    	    #
    	    var addr [addr-parse ($obj)]
            var seg [handle segment [index $addr 0]]
    	    var off [index $addr 1]
            var masteroff [value fetch $seg:$off.ui::Gen_offset]
    	    var master [expr $off+$masteroff]
    	    if {$masteroff == 0} {
    	        echo { -- not yet built}
    	    } else {
    	    	#
    	    	# Get the address of the active list, if any
    	    	#
	    	var lchk [value fetch $seg:$master.ui::GALI_list word]
	    	if {$lchk != 0} then {
    	    	    pcarray -tui::ActiveListEntry *$seg:$lchk
    	    	} else {
    	    	    echo {active list is empty}
    	    	}
    	    }
    	} else {
    	    error {object is of wrong class}
    	}
}]
