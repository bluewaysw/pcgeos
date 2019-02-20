##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	uiperf.tcl
# AUTHOR: 	Tony Requist
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	tony	9/16/90		Initial Revision
#
# DESCRIPTION:
#	Functions for examining ui performance
#
#	$Id: uiperf.tcl,v 1.1 90/09/16 18:11:18 tony Exp $
#
###############################################################################

##############################################################################
#				kbdperf
##############################################################################
#
# SYNOPSIS:	Print out the perfomance data on VisTextKbd
# PASS:		-
# CALLED BY:	the user
# RETURN:	nothing
# SIDE EFFECTS:	lots of shit is printed
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	tony	9/16/90		Initial Revision
#
##############################################################################
[defcommand kbdperf {args} ui
{Print out timing information for VisTextKbd
}
{
    var index [expr [value fetch ui::perfIndex]-2]
    var arraySize [expr [type size [sym tget [sym find var perfArray]]]/2]
    var nextStartTick -1
    var totalVTK 0
    var totalTotal 0

    for {var i 0} {$i != $arraySize-1} {var i [expr $i+1]} {
    	var vtk [value fetch ui::perfArray+$index [type word]]
    	var startTick [value fetch ui::perfStartArray+$index [type word]]
    	echo -n [format {Char #%d, VTK = %d} $i $vtk]
    	if {$nextStartTick != -1} {
    	    var ticks [expr $nextStartTick-$startTick]
    	    var totalVTK [expr $totalVTK+$vtk]
    	    var totalTotal [expr $totalTotal+$ticks]
    	    echo [format {, time to next = %d, ave vtk = %.2f, ave total = %.2f}
    	    	    	 $ticks [expr $totalVTK/$i f] [expr $totalTotal/$i f]]
    	} else {
    	    echo
    	}
    	var nextStartTick $startTick
    	var index [expr $index-2]
    	if {$index == 0} {
    	    var index [expr $arraySize-2]
    	}
    }
}]
