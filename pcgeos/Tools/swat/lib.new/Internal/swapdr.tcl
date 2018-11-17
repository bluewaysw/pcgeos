##############################################################################
#
# 	Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	
# FILE: 	swapdr.tcl
# AUTHOR: 	Adam de Boor, Sep  9, 1993
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	9/ 9/93		Initial Revision
#
# DESCRIPTION:
#	misc functions for debugging swap drivers.
#
#	$Id: swapdr.tcl,v 1.2 94/11/10 13:58:29 adam Exp $
#
###############################################################################

##############################################################################
#				fu
##############################################################################
#
# SYNOPSIS:	Find the used pages in a swap map and print them out
#		in their linked list format
# PASS:		[mapvar]    = name of the variable defined as sptr.SwapMap
#			      the map for the EMM driver is the default
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	9/ 9/93		Initial Revision
#
##############################################################################

[defsubr fu {{mapvar emSwapMap}}
{
    var sm [value fetch *$mapvar]
    var ss [value fetch $mapvar]
    var off [getvalue SM_pages]
    var base $off
    if {[field $sm SM_freeList] != $off} {
    	var nextFree [field $sm SM_freeList]
	var isfree 0
    } else {
    	var isfree 1
    }
    var lim [expr [field $sm SM_total]*2+$off]
    for {} {$off < $lim} {var off [expr $off+2]} {
    	var next [value fetch $ss:$off word]

    	if {$isfree || $off == $nextFree} {
	    if {$next != [expr $off+2]} {
	    	var isfree 0 nextFree [value fetch $ss:$off word]
    	    } else {
	    	var isfree 1
    	    }
    	} else {
	    #var page  [expr ($off-$base)/2]
    	    if {$next != 0xfffe} {
	    	var fmt {%04x -> }
	    } else {
	    	var fmt {%04x -|\n}
    	    }
	    echo -n [format $fmt $off]
    	}
    }
}]

##############################################################################
#				emmlog
##############################################################################
#
# SYNOPSIS:	Print out the most recent EMM function calls, either by
#		GEOS or by TSRs, giving the registers that were passed for each
# PASS:		[n] = number of most-recent calls to print (all calls is
#		      the default)
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	9/ 9/93		Initial Revision
#
##############################################################################
[defsubr emmlog {{n 0}}
{
    var a [addr-preprocess emm::callLog seg off]
    
    var d [type aget [index $a 2]]
    if {$n == 0 || $n > [index $d 2]+1} {
    	var n [expr [index $d 2]+1]
    }
    var functype [symbol find type emm::EMMFunctions]
    var eltype [index $d 0]
    var esize [type size $eltype]

    var p [expr [value fetch callPrevPtr]/$esize]
    var curoff [value fetch callLogPtr]
    var cur [expr $curoff/$esize]
    
    while {$n > 0} {
    	var curoff [expr $curoff-$esize]
	var cur [expr $cur-1]
	if {$curoff < 0} {
	    var curoff [expr [index $d 2]*$esize]
	    var cur [index $d 2]
    	}
    	var e [value fetch $seg:$off+$curoff $eltype]
	var name [type emap [field $e EC_ax] $functype]
	if {[null $name]} {
	    var name [type emap [expr [field $e EC_ax]&0xff00] $functype]
	    if {[null $name]} {
	    	var name [format %04xh [field $e EC_ax]]
    	    } else {
	    	var name [format {%s, AL = %02xh} $name
		    	    [expr [field $e EC_ax]&0xff]]
    	    }
    	}
	if {$cur == $p} {
	    var isprev {PREV -> }
    	} else {
	    var isprev {}
    	}
	
        echo {-----------------------}
	echo [format {%-10s %s%s} $isprev $name
	    	[if [field $e EC_inProgress] {format { (in progress)}}]]

	global regnums flags
	#
	# Print out the general registers in both hex and decimal
	#
	var j 0
	[foreach i {{EC_ax AX}
		    {EC_bx BX}
		    {EC_cx CX}
		    {EC_dx DX}
		    {EC_si SI}
		    {EC_di DI}
		    {{} {}}
		    {EC_sp SP}}
    	{
	    var regval [field $e [index $i 0]]
	    if {![null $regval]} {
	    	echo -n [format {%-4s%04xh%8d} [index $i 1] $regval $regval]
    	    } else {
	    	echo -n [format {%-4s%4s%8s} {} {} {}]
    	    }	    	
	    var j [expr ($j+1)%3]
	    if {$j == 0} {echo} else {echo -n \t}
	}]
	#
	# Blank line.
	#
	echo
	echo
	#
	# Now the segment registers in hex followed by the handle ID and name, if
	# they point at one.
	#
	foreach i {{EC_ds DS} {EC_ss SS} {EC_es ES}} {
	    var regval [field $e [index $i 0]]
	    var handle [handle find [format %04xh:0 $regval]]
	    if {![null $handle]} {
		if {[handle state $handle] & 0x480} {
		    #
		    # Handle is a resource/kernel handle, so it's got a symbol in
		    # its otherInfo field. We want its name.
		    #
		    echo -n [format {%-4s%04xh   handle %04xh (%s)}
				[index $i 1] $regval [handle id $handle]
				[symbol fullname [handle other $handle]]]
		} else {
		    echo -n [format {%-4s%04xh   handle %04xh}
				[index $i 1] $regval [handle id $handle]]
		}
		if {[handle segment $handle] != $regval} {
		    echo [format { [handle segment = %xh]}
				 [handle segment $handle]]
		} else {
		    echo
		}
	    } else {
		echo [format {%-4s%04xh   no handle} [index $i 1] $regval]
	    }
	}
	
	var n [expr $n-1]
    }
}]
    

##############################################################################
#				emmacts
##############################################################################
#
# SYNOPSIS:	
# PASS:		
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/24/94		Initial Revision
#
##############################################################################
[defsubr emmacts {{n 0} {size 0}}
{
    var a [addr-preprocess emm::opLog seg off]
    
    var d [type aget [index $a 2]]
    var max [expr [index $d 2]+1]
    
    if {$n == 0 || $n > $max} {
    	var n $max
    }
    
    echo {Op  Addr       # Bytes   Page  Mins Ago}
    echo {--  ---------  -------  -----  --------}

    var now [value fetch systemCounter]
    
    [for {
    	    var cur [expr [value fetch emm::logPtr]/2-$n]
	    if {$cur < 0} {
	    	var cur [expr $max+$cur]
    	    }
    	 }
    	 {$n > 0}
	 {
	    var n [expr $n-1] cur [expr $cur+1]
	    if {$cur == $max} {
	    	var cur 0
    	    }
    	 }
    {
    	var op [value fetch {emm::opLog[$cur]}]
	var s  [value fetch {emm::segLog[$cur]}]
	var o  [value fetch {emm::offLog[$cur]}]
	var sz  [value fetch {emm::sizeLog[$cur]}]
	var pg  [value fetch {emm::pageLog[$cur]}]
	var time [expr [value fetch {emm::timeLowLog[$cur]}]|([value fetch {emm::timeHighLog[$cur]}]<<16)]

    	if {$size == 0 || $sz == $size} {
	    var mins [expr ($now-$time)/3600]
	    echo [format {%s   %04x:%04x  %7d  %5d  %3d:%02.2f}
		    [index {R W} $op]
		    $s $o $sz $pg
		    $mins
		    [expr ($now-$time-($mins*3600))/60 f]]
    	}
    }]
}]
