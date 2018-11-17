#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library -- 
# FILE:		cgeo.tcl
# AUTHOR:	John Wedgwood, Oct 29, 1991
#
# COMMANDS:
#	Name			Description
#	----			-----------
#   	cgwatch	    	    	Watch chart geometry happen
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	john	10/29/91	Initial revision
#
# DESCRIPTION:
#	Tcl code for profiling/debugging chart geometry code.
#
#	$Id: cgeo.tcl,v 1.1 97/04/04 17:45:32 newdeal Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

#
# Requirements
#
require	offset-to-chunk chart

#
# Global variables
#
var cg_status off
var cg_rbrk   {}
var cg_sbrk   {}
var cg_asbrk  {}
var cg_ccbrk  {}
var cg_indent 0

##############################################################################
#				cgwatch
##############################################################################
#
# SYNOPSIS:	What chart geometry happen.
# PASS:		onOff	- "on", "off", none
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/29/91	Initial Revision
#
##############################################################################
[defcommand cgwatch {{onOff {}}} chart
{Usage:
    cgwatch [onOff]

Examples:
    "cgwatch"	    	Get the chart-profiling status
    "cgwatch on"    	Turn chart-profiling on
    "cgwatch off"    	Turn chart-profiling off

Synopsis:
    Lets you watch chart geometry as it happens.

Notes:

See also:
}
{
    global  cg_status
    global  cg_rbrk
    global  cg_sbrk
    global  cg_asbrk
    global  cg_ccbrk
    global  cg_indent

    require getstring	cwd.tcl
    global  ini-read ini-write
    remove-brk ini-read 
    remove-brk ini-write

    if {![null $flags]} {
	 var cg-brk [list 
			[brk ChartObjectRecalcSize {showSize}]
		 ]
	 }
}]

##############################################################################
#	showSize
##############################################################################
#
# SYNOPSIS:	
# PASS:		
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       chrisb 	12/29/92   	Initial Revision
#
##############################################################################
[defsubr    showSize {} {
    require pointregs spline.tcl
    pointregs	cx dx

}]

##############################################################################
#				cg-recalc
##############################################################################
#
# SYNOPSIS:	Echo information about recalculation
# PASS:		nothing
# CALLED BY:	via breakpoint
# RETURN:	0 (to continue)
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/29/91	Initial Revision
#
##############################################################################
[defsubr cg-recalc {}
{
    var s [get-chart-obj-size]
    var w [index $s 0]
    var h [index $s 1]

    cg-echo [format {Recalc    %s: (%d,%d) -> (%d,%d)}
	    	[get-chart-obj-name]
		$w $h
    	    	[read-reg cx] [read-reg dx]]
    cg-indent
    
    return 0
}]

##############################################################################
#				cg-set
##############################################################################
#
# SYNOPSIS:	Echo information about setting size
# PASS:		nothing
# CALLED BY:	via breakpoint
# RETURN:	0 (to continue)
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/29/91	Initial Revision
#
##############################################################################
[defsubr cg-set {}
{
    cg-outdent

    if {[read-reg cc] & 1} {
    	cg-echo {Internal Size Change}
    }

    var s [get-chart-obj-size]
    var w [index $s 0]
    var h [index $s 1]

    cg-echo [format {Set Size  %s: (%d,%d) -> (%d,%d)}
	    	[get-chart-obj-name]
		$w $h
    	    	[read-reg cx] [read-reg dx]]
    return 0
}]

##############################################################################
#				cg-aset
##############################################################################
#
# SYNOPSIS:	Check for a change in size.
# PASS:		nothing
# CALLED BY:	via breakpoint
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/29/91	Initial Revision
#
##############################################################################
[defsubr cg-aset {}
{
    if {[read-reg cc] & 1} {
    	cg-echo {Size Change}
    }
    
    return 0
}]

##############################################################################
#				cg-cc
##############################################################################
#
# SYNOPSIS:	Check for no change in a recalculation
# PASS:		nothing
# CALLED BY:	via breakpoint
# RETURN:	0 to continue
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/29/91	Initial Revision
#
##############################################################################
[defsubr cg-cc {}
{
    if {[read-reg cc] & 0x40} {
	var s [get-chart-obj-size]
	var w [index $s 0]
	var h [index $s 1]

	cg-echo [format {No Change %s: (%d,%d) -> (%d,%d)}
		    [get-chart-obj-name]
		    $w $h
		    [read-reg cx] [read-reg dx]]
    }
    
    return 0
}]

##############################################################################
#				get-chart-obj-name
##############################################################################
#
# SYNOPSIS:	Get the name of a chart object.
# PASS:		nothing
# CALLED BY:	
# RETURN:	str 	- Name of the object
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/29/91	Initial Revision
#
##############################################################################
[defsubr get-chart-obj-name {}
{
    #
    # Figure the name from the chunk (in si)
    #
    var s [obj-class *ds:si]
    if {[null $s]} {
    	var str {Unknown}
    } else {
    	var str [sym name $s]
    }

    return [format {%s <*%04xh:%04xh>} $str [read-reg ds]
    	    	    [offset-to-chunk [read-reg ds] [read-reg si]]]
}]

##############################################################################
#				get-chart-obj-size
##############################################################################
#
# SYNOPSIS:	Get the size of a chart object
# PASS:		nothing
# CALLED BY:	cg-set
# RETURN:	l   - List containing width and height
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/29/91	Initial Revision
#
##############################################################################
[defsubr get-chart-obj-size {}
{
    var s [value fetch (*ds:si).COI_size [sym find type Point]]
    
    return [concat [field $s P_x] [field $s P_y]]
}]


##############################################################################
#				cg-indent
##############################################################################
#
# SYNOPSIS:	Indent the profiling output
# PASS:		nothing
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/29/91	Initial Revision
#
##############################################################################
[defsubr cg-indent {}
{
    global  cg_indent
    
    var cg_indent [expr $cg_indent+4]
}]

##############################################################################
#				cg-outdent
##############################################################################
#
# SYNOPSIS:	Outdent the profiling output
# PASS:		nothing
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/29/91	Initial Revision
#
##############################################################################
[defsubr cg-outdent {}
{
    global  cg_indent
    
    var cg_indent [expr $cg_indent-4]
}]

##############################################################################
#				cg-echo
##############################################################################
#
# SYNOPSIS:	Echo a string, indented appropriately
# PASS:		str - string to echo
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/29/91	Initial Revision
#
##############################################################################
[defsubr cg-echo {str}
{
    global cg_indent

    echo -n [format {%*s} $cg_indent {}]
    echo $str
}]

[defsubr cg-echo-n {str}
{
    global cg_indent

    echo -n [format {%*s} $cg_indent {}]
    echo -n $str
}]
