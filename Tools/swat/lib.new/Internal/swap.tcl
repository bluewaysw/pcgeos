##############################################################################
#
# 	Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	swap.tcl
# FILE: 	swap.tcl
# AUTHOR: 	Jim DeFrisco, Sep  9, 1993
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	pswap	    	    	Print swap device statistics
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jim	9/ 9/93		Initial Revision
#
# DESCRIPTION:
#	
#
#	$Id: swap.tcl,v 1.1 93/10/03 23:13:49 don Exp $
#
###############################################################################
##############################################################################
#				pswap
##############################################################################
#
# SYNOPSIS:	Print swap file statistics
# PASS:		nothing
# CALLED BY:	GLOBAL
# RETURN:	nothing
# SIDE EFFECTS:	nothing
#
# STRATEGY
#   	    	Needs a special swap library (see GATHER_SWAP_STATS constant 
#   	    	in Library/Swap/swap.asm).  Read the swap map and do some
#   	    	calculations.
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jim	9/ 9/93		Initial Revision
#
##############################################################################

[defcommand pswap {} {}
{Usage:
    pswap 	    	- needs a special swap library.  see swap.asm
    	    	    	  Prints out useful swap information.
}
{
    # Grab the segment address of the SwapMap block
    #
    var sm [value fetch swap::swapSegment word]

    # grab the basic info out of the swap map block, and calculate the
    # total size of the swap space.
    #
    var np [value fetch $sm:SM_total]
    var ps [value fetch $sm:SM_page]
    var nf [value fetch $sm:SM_numFree]
    var ss [expr $np*$ps]

    # Fixed size block is the SwapMap structure plus the link words.
    #
    var fs [expr [size SwapMap]+[expr $np*2]]

    # process the entire swap map, looking for used blocks.  For non-free 
    # blocks we assume that if they have a "next" pointer they are fully
    # utilized (no wasted space), while blocks with the -2 end pointer 
    # are not fully utilized.  In this case, our companion code in the 
    # swap library has recorded the actual used size of the page in a word 
    # later in the swap map.  
    #
    var usedSize 0
    var nonFreeSize 0
    var nextFree [value fetch $sm:SM_freeList]
    var next [getvalue SM_pages]

    # This is the offset between the links part of the SwapMap and our 
    # buffer of page sizes.
    #
    var uo [expr $np*2]
    var lim [expr $np*2+$next]
    for {} {$next < $lim} {var next [expr $next+2]} {
    	if {$next == $nextFree} {
	    var nextFree [value fetch $sm:$nextFree word]
    	} else {
    	    var nonFreeSize [expr $nonFreeSize+$ps]
    	    if {[value fetch $sm:$next word] == 0xfffe} {
	    	var usedSize [expr $usedSize+[value fetch $sm:$next+$uo word]]
	    } else {
	    	var usedSize [expr $usedSize+$ps]
    	    }
    	}
    }

    # calculate the percent usage of the nonFree blocks.
    #
    if {$nonFreeSize != 0} {
        var su [expr $usedSize*100/$nonFreeSize float]
    	var aps [expr $su*$ps/100 float]
    } else {
    	var su 0
    	var aps 0
    }

    var pused [expr [expr $np-$nf]*100/$np float]
    var magic [expr [expr $nf*$ps*$su-[expr $fs*4 float] float]/$ss float]

    # finally, print the results
    #
    echo [format {Swap Info:}]
    echo [format { Swap file size: %d bytes} $ss]
    echo [format {      Page size: %d bytes} $ps]
    echo [format {   SwapMap size: %d fixed bytes} $fs]
    echo [format {Number of pages: %d} $np]
    echo [format {Page Usage:}]
    echo [format {Pages Allocated: %d (%4.1f percent)} [expr $np-$nf] $pused]
    echo [format { Avg Page Usage: %d bytes (%4.1f percent)} $aps $su]
    echo [format {   Magic Number: %4.1f} $magic]
}]



