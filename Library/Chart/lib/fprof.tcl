#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library -- 
# FILE:		fprof.tcl
# AUTHOR:	John Wedgwood, Oct 29, 1991
#
# COMMANDS:
#	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	john	10/29/91	Initial revision
#
# DESCRIPTION:
#	Code to profile the floating-point calls made by the
#   	charting code.
#
#	$Id: fprof.tcl,v 1.1 97/04/04 17:45:33 newdeal Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

[var float-routines {Float0Far
		     Float1Far
		     Float2Far
		     Float10Far
		     FloatAbsFar
		     FloatAddFar
		     FloatArcCosFar
		     FloatArcCoshFar
		     FloatArcSinFar
		     FloatArcSinhFar
		     FloatArcTanFar
		     FloatArcTan2Far
		     FloatArcTanhFar
		     FloatCompAndDropFar
		     FloatCompFar
		     FloatCompESDIFar
		     FloatCosFar
		     FloatCoshFar
		     FloatDepthFar
		     FloatDIVFar
		     FloatDivideFar
		     FloatDivide2Far
		     FloatDivide10Far
		     FloatDropFar
		     FloatDupFar
		     FloatDwordToFloatFar
		     FloatEntry
		     FloatEq0Far
		     FloatExit
		     FloatExpFar
		     FloatExponentialFar
		     FloatFloatToAscii
		     FloatFloatToAscii_StdFormat
		     FloatFactorialFar
		     FloatFracFar
		     FloatGenerateFormatStr
		     FloatGt0Far
		     FloatInit
		     FloatIntFar
		     FloatIntFracFar
		     FloatInverseFar
		     FloatLgFar
		     FloatLnFar
		     FloatLn1plusXFar
		     FloatLn2Far
		     FloatLn10Far
		     FloatLogFar
		     FloatLt0Far
		     FloatMaxFar
		     FloatMinFar
		     FloatModFar
		     FloatMultiplyFar
		     FloatMultiply2Far
		     FloatMultiply10Far
		     FloatNegateFar
		     FloatOverFar
		     FloatPiFar
		     FloatPickFar
		     FloatPopNumberFar
		     FloatPushNumberFar
		     FloatRandomFar
		     FloatRandomizeFar
		     FloatRandomNFar
		     FloatRollFar
		     FloatRollDownFar
		     FloatRotFar
		     FloatRoundFar
		     FloatSinFar
		     FloatSinhFar
		     FloatSqrFar
		     FloatSqrtFar
		     FloatSqrt2Far
		     FloatAsciiToFloat
		     FloatSubFar
		     FloatSwapFar
		     FloatTanFar
		     FloatTanhFar
		     Float10ToTheXFar
		     FloatTruncFar
		     FloatFloatToDwordFar
		     FloatWordToFloatFar
		     FloatCheckStackCount
		     FloatGetStackPointer
		     FloatSetStackPointer
		     FloatGetDateNumber
		     FloatDateNumberGetYear
		     FloatDateNumberGetMonthAndDay
		     FloatDateNumberGetWeekday
		     FloatGetTimeNumber
		     FloatStringGetDateNumber
		     FloatStringGetTimeNumber
		     FloatTimeNumberGetHour
		     FloatTimeNumberGetMinutes
		     FloatTimeNumberGetSeconds
}]

var cf_brks   {}
var cf_status off
var cf_stats  0

##############################################################################
#				cf-prof
##############################################################################
#
# SYNOPSIS:	Initiate profiling of the floating point calls of the chart code
# PASS:		onOff	- "on", "off", or nothing
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
[defcommand cfprof {{onOff {}}} chart
{Usage:
    cfprof [onOff]

Examples:
    "cfprof"	    	Get the chart-profiling status
    "cfprof on"    	Turn chart-profiling on
    "cfprof off"    	Turn chart-profiling off

Synopsis:
    Set or clear breakpoints designed to give information about the floating
    point library calls made by the chart library.

Notes:

See also:
    cfsum   	    	Generate a summary of the profiling stats.
}
{
    global  cf_status
    global  cf_brks
    global  float-routines

    if {[string compare $onOff {on}]==0} {
	#
	# Set breakpoints
	#
	var cf_status on
	var cf_brks   {}
	var cf_stats  0

	for {var i [var float-routines]} {![null $i]} {var i [cdr $i]} {
	    var theBrk [brk aset float::[car $i]]
    	    var cf_brks [concat $cf_brks $theBrk]
	    brk cmd $theBrk cf-add
	}
    } elif {[string compare $onOff {off}]==0} {
	#
	# Clear breakpoints
	#
	for {var i $cf_brks} {![null $i]} {var i [cdr $i]} {
    	    brk clear [car $i]
	}

	var cf_status off
	var cf_brks {}
    } else {
    	echo $cf_status
    }
}]

##############################################################################
#				cf-add
##############################################################################
#
# SYNOPSIS:	Add stats to the chart profiling
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
[defsubr cf-add {}
{
    global  cf_stats
    
    echo [func]
    var cf_stats [expr $cf_stats+1]
    
    return 0
}]

##############################################################################
#				cfsum
##############################################################################
#
# SYNOPSIS:	Generate statistics.
# PASS:		nothing
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
[defcommand cfsum {} chart
{Usage:
    cfsum

Examples:
    "cfsum"	    	Generate statistics for fp-calls by charting code.

Synopsis:

Notes:

See also:
    cfprof
}
{
    global  cf_stats
    
    echo [format {%d calls to the float library} $cf_stats]
}]
