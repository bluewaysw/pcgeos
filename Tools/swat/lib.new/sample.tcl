##############################################################################
#
# 	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	sample.tcl
# FILE: 	sample.tcl
# AUTHOR: 	Chris Boyke, Jun 28, 1994
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#      chrisb	6/28/94		Initial Revision
#
# DESCRIPTION:
#	
#      This file contains sample tcl code to be used in training.
#
#
#	$Id: sample.tcl,v 1.1.12.1 97/03/29 11:27:14 canavese Exp $
#
###############################################################################

##############################################################################
#	psize
##############################################################################
#
# SYNOPSIS:	Display the size of a Vis object.   For functionality
#               similar to this, see "pvsize", and "pvis".
#               
# PASS:		addr - address of object
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       chrisb 	6/28/94   	Initial Revision
#
##############################################################################
[defsubr    psize {addr} {

    # We want to make sure that grab.tcl is loaded before we run,
    # since we use code from that file.

    require is-obj-in-class grab.tcl

    #
    # Allow the user to use any number of means of accessing the
    # object (example "psize -i").  Type "help addr-with-obj-flag" for more
    # info.  The "var" command is used to assign a value to a variable.

    var obj [addr-with-obj-flag $addr]

    #
    # Make sure our object is in VisClass. 
    #
    if {[is-obj-in-class $obj VisClass]} {
	# 
	# Since VisClass is a master class, we need to do some more
	# work to get the offset to the Vis-level instance data.
	#
	# The "value" command can be used to fetch and store data in
	# the computer's memory.  Type "help value" for more info.
	#
	var vis [value fetch $obj.ui::Vis_offset]

	# Now we use this offset to access the Vis-level instance data

	var bounds [value fetch $obj+$vis.ui::VI_bounds]


	# This time, the "bounds" variable is a list.  We can use the
	# "field" command to access various portions of the list.  The
	# "expr" command is used to compute mathematical expressions.

	echo [format {Width: %d  Height: %d} 
	      [expr [field $bounds R_right]-[field $bounds R_left]]
	      [expr [field $bounds R_bottom]-[field $bounds R_top]]]
	
    } else {
	echo [format {Object %s is not in VisClass} $obj]
    }
}]



