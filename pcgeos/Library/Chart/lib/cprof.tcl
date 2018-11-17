#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library -- 
# FILE:		cprof.tcl
# AUTHOR:	John Wedgwood, Nov 14, 1991
#
# COMMANDS:
#	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	john	11/14/91	Initial revision
#
# DESCRIPTION:
#	Tcl code intended to help in profiling the charting code.
#
#	$Id: cprof.tcl,v 1.1 97/04/04 17:45:34 newdeal Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

#
# This is a list of all of the routines that we want to count calls for.
#
[var cprof_calls {Float0
    Float1Far
    Float10Far
    Float2Far
    FloatAbsFar
    FloatAddFar
    FloatCompAndDropFar
    FloatDivideFar
    FloatDropFar
    FloatDupFar
    FloatDwordToFloatFar
    FloatEq0Far
    FloatExponentialFar
    FloatFloatToAscii_StdFormat
    FloatFloatToDwordFar
    FloatFracFar
    FloatIntFar
    FloatLogFar
    FloatLt0Far
    FloatMaxFar
    FloatMinFar
    FloatMultiplyFar
    FloatNegateFar
    FloatPickFar
    FloatPopNumberFar
    FloatPushNumberFar
    FloatRollDownFar
    FloatRotFar
    FloatSubFar
    FloatSwapFar
    FloatTruncFar
    FloatCeiling
    FloatFloor
    ObjCallInstanceNoLock
    ObjMessage
}]

#
# Global variables
#
var cprof_startBrk  {}
var cprof_endBrk    {}

var cprof_brkList   {}
var cprof_table     {}
var cprof_routines  {}

##############################################################################
#				cprof
##############################################################################
#
# SYNOPSIS:	Profile creation of a chart.
# CALLED BY:	user
# PASS:		nothing
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	11/14/91	Initial Revision
#
##############################################################################
[defcommand cprof {} chart
{Usage:
    cprof

Examples:
    "cprof"	    	Profile creation of a chart.

Synopsis:
    Profile creation of a chart

Notes:

See also:
}
{
    global cprof_startBrk

    #
    # Set a breakpoint at the start of the chart-create routine
    #
    if {[null $cprof_startBrk]} {
    	var cprof_startBrk [brk aset chart::ChartCreateChart]
    } else {
    	brk enable $cprof_startBrk
    }
    brk cmd $cprof_startBrk cprof-start
}]

##############################################################################
#				cprof-start
##############################################################################
#
# SYNOPSIS:	Start profiling
# CALLED BY:	via breakpoint
# PASS:		nothing
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	11/14/91	Initial Revision
#
##############################################################################
[defsubr cprof-start {}
{
    global cprof_endBrk
    global cprof_table
    global cprof_routines
    global cprof_calls
    global cprof_brkList

    #
    # Set final breakpoint
    #
    var cprof_endBrk [brk aset chart::ChartCreateChart::quit]
    brk cmd $cprof_endBrk cprof-end
    
    #
    # Create and initialize a table to hold the information.
    #
    if {![null $cprof_table]} {
    	table destroy $cprof_table
    	var cprof_table {}
    }
    var cprof_table [table create]

    var cprof_routines {}

    #
    # Create the list of breakpoints.
    #
    for {var q $cprof_calls} {![null $q]} {var q [cdr $q]} {
	var b [brk aset [car $q]]
	brk cmd $b cprof-add-stat
    	var cprof_brkList [concat $cprof_brkList $b]
    }

    return 0
}]

##############################################################################
#				cprof-add-stat
##############################################################################
#
# SYNOPSIS:	Add a statistic for the current routine to the table.
# CALLED BY:	via breakpoint
# PASS:		nothing
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	11/14/91	Initial Revision
#
##############################################################################
[defsubr cprof-add-stat {}
{
    global cprof_table
    global cprof_routines
    
    var f [func]
    var old [table lookup $cprof_table $f]
    
    if {[null $old]} {
    	table enter $cprof_table $f 1
	var cprof_routines [concat $cprof_routines $f]
    } else {
    	table enter $cprof_table $f [expr $old+1]
    }
    
    return 0
}]


##############################################################################
#				cprof-end
##############################################################################
#
# SYNOPSIS:	Called when we are done with profiling
# CALLED BY:	via breakpoint
# PASS:		nothing
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	11/14/91	Initial Revision
#
##############################################################################
[defsubr cprof-end {}
{
    global cprof_table
    global cprof_routines
    
    #
    # Nuke breakpoints
    #
    cprof-del-breakpoints

    #
    # Echo the statistics for each entry in the table
    #
    # Create a list which contains pairs of elements with the number of calls
    # first and the routine second
    #
    var l {}
    for {var q $cprof_routines} {![null $q]} {var q [cdr $q]} {
	var l [concat $l [format {%d&%s}
    	    	    	    [table lookup $cprof_table [car $q]]
			    [car $q]]]
    }

    var l [sort -n -r $l]

    echo {ROUTINE                         CALLS}
    echo {-------                         -----}

    for {var q $l} {![null $q]} {var q [cdr $q]} {
    	#
	# Convert something of the form ###&label into two pieces
	#
	var andPos [string first & [car $q]]
    	echo [format {%-30s  %5d}
	    	    [range [car $q] [expr $andPos+1] end chars]
	    	    [range [car $q] 0 [expr $andPos-1] chars]]
    }
    return 0
}]

##############################################################################
#				cprof-del-breakpoints
##############################################################################
#
# SYNOPSIS:	Nuke breakpoints associated with profiling
# CALLED BY:	cprof-end
# PASS:		nothing
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	11/14/91	Initial Revision
#
##############################################################################
[defsubr cprof-del-breakpoints {}
{
    global cprof_startBrk
    global cprof_endBrk
    global cprof_brkList

    #
    # Remove breakpoints
    #
    if {![null $cprof_startBrk]} {
    	brk del $cprof_startBrk
    }
    if {![null $cprof_endBrk]} {
    	brk del $cprof_endBrk
    }
    
    for {var q $cprof_brkList} {![null $q]} {var q [cdr $q]} {
    	brk del [car $q]
    }

    var cprof_startBrk {}
    var cprof_endBrk   {}
    var cprof_brkList  {}
}]
