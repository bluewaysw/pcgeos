##############################################################################
#
# 	(c) Copyright Geoworks 1996 -- All Rights Reserved
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	PC GEOS
# MODULE:	XIP/Kernel profiling
# FILE: 	trackResourceCall.tcl
# AUTHOR: 	Jason Ho, Jul 30, 1996
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#       trackResourceCall       Reset track count or print number of 
#                               inter-resource call
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	kho	7/30/96   	Initial Revision
#
# DESCRIPTION:
#	Track inter-resource call in XIP
#       Mostly modified after "int21" command.
#
#	$Id: trackResourceCall.tcl,v 1.2.2.1 97/03/29 11:25:45 canavese Exp $
#
###############################################################################

[defcommand trackResourceCall {{command print} {lowBound 100}}
    {interrupt system.misc}
{Usage:
         trackResourceCall [print {lowBound} | reset]
}
{
    var countAddr [addr-preprocess callCountArray countSeg countOffset]
    var fromAddr [addr-preprocess fromResourceArray fromSeg fromOffset]
    var toAddr [addr-preprocess toResourceArray toSeg toOffset]
    var count 0
    var max [index [type aget [index $countAddr 2]] 2]
    var esize [type size [type int]]
    #
    # Determine which command to perform
    #
    if {[string match $command r*]} {
	#
	# Reset the call totals
	#
	echo {Resetting TrackResourceCall counts}
	[for {var count 0}
	     {$count <= $max}
	     {var count [expr $count+1]}
    	{
	    value store $countSeg:$countOffset 0 [type word]
	    var countOffset [expr $countOffset+$esize]
	}]
	assign geos::mapPageCount 0
    } elif {[string match $command p*]} {

	var data {}
	var key freq
	var sort {sort -rn}

	[for {var count 0}
	     {$count <= $max}
	     {
	     	var count [expr $count+1]
		var countOffset [expr $countOffset+$esize]
		var fromOffset [expr $fromOffset+$esize]
		var toOffset [expr $toOffset+$esize]
	     }
    	{
	    var freq [value fetch $countSeg:$countOffset word]
	    var fromRsc [value fetch $fromSeg:$fromOffset word]
	    var toRsc [value fetch $toSeg:$toOffset word]
	    #
	    # Only print entries with count >= $lowBound
	    #
	    if {$freq >= $lowBound} {
		var data [concat $data [list [list
				[var $key] [format {%7d  %13d  %11d}
					    $freq
					    $fromRsc
					    $toRsc]]]]
	    }
	}]

	#
	# sort and print
	#
	echo [format {Print mapping pairs whose counts >= %d}
	             $lowBound]
	echo {  Count  From Resource  To Resource}
	echo {-------  -------------  -----------}
	foreach lineData [eval [concat $sort [list $data]]] {
	    echo [index $lineData 1]
	}
	echo {}
	echo [format {Total XIP Page Mapping: %d\n}
	      [value fetch mapPageCount]]
    } else {
	echo {Command not understood}
	help trackResourceCall
    }
}]


