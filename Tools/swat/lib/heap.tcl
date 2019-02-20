##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	heap.tcl
# AUTHOR: 	Adam de Boor, Apr 13, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	hwalk	    	    	Walk the heap, printing out handles with memory
#   	phandle	    	    	Print out a handle using data from the PC
#   	handles	    	    	Print out the entire handle table
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/13/89		Initial Revision
#
# DESCRIPTION:
#	Functions for examining heap structures
#
#	$Id: heap.tcl,v 3.20 90/12/04 13:38:00 tony Exp $
#
###############################################################################
##############################################################################
#				heap-print-type
##############################################################################
#
# SYNOPSIS:	Figure the type of a handle and print it out (followed by
#		a newline)
# PASS:		flags	= value list from fetching the HM_flags field
#		cur 	= ID of handle being examined
#		own 	= ID of owner of handle
#		ownerHandle= handle token of owner
#		addr	= segment of associated memory
#   	    	other	= HM_otherInfo field value
# CALLED BY:	hwalk, handles
# RETURN:	nothing
# SIDE EFFECTS:	newline is printed
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/24/90		Initial Revision
#
##############################################################################
[defsubr heap-print-type {flags cur own ownerHandle addr other}
{
    [if {[field $flags HF_LMEM] && 
	 ([null $ownerHandle] || ![handle isvm $ownerHandle])}
    {
    	if {$addr == 0} {
	    echo 
    	} else {
	    var i [value fetch $addr:LMBH_lmemType]
	    var t [type emap $i [sym find type kernel::LMemTypes]]
	    if {![null $t]} {
		#10 is length of "LMEM_TYPE_"
		echo -n [range $t 10 end chars]
		[case $t in
		    *OBJ_BLOCK {
			foreach i [thread all] {
			    if {[thread id $i] == $other} {
				echo -n ([patient name [handle patient [thread handle $i]]]:[thread number $i])
				break
			    }
			}
		    }
		    *DB_ITEMS {
			echo -n ([format %04x $own])
		    }
		]
		echo
	    } else {
		echo LMem type $i
	    }
    	}
    } elif {$cur == $own} {
	#
	# Owns itself -- must be a core block
	#
	echo {Geode}
    } elif {$own == 0x10} {
	#
	# Owned by kernel
	#
    	[if {![null [patient find klib]] &&
	    	$cur == [value fetch klib::dgroup::initFileBufHan]} {
    	    echo INI Buffer
    	} elif {$cur == [value fetch kdata:diskTblHan]} {
	    echo Disk Table
    	} elif {$addr != 0 &&
	    	[value fetch kdata:$cur.HM_size] == 0xd &&
	        [string c [type emap [value fetch ^h$cur:LMBH_lmemType]
		    	    	[sym find type kernel::LMemTypes]]
		    LMEM_TYPE_GSTATE] == 0}
    	{
    	    echo Cached GState
    	} else {
    	    var t [sym find type kernel::KBlockTypes]
	    if {![null $t]} {
	    	var b [type emap $other $t]
		if {![null $b]} {
		    echo $b
		} else {
		    echo ?
    	    	}
    	    } else {
	    	echo {?}
    	    }
	}]
    } elif {$own == 0x20} {
    	#
    	# Owned by font manager
    	#
    	echo {FONT}
    } elif {![null $ownerHandle] && [handle isvm $ownerHandle]} {
	#
	# Owned by a VM handle.
	#
	echo [format {VMem (%04x)} [handle id $ownerHandle]]
    } elif {![null $ownerHandle]} {
    	var s nil i 0
	foreach h [patient resources [handle patient $ownerHandle]] {
	    if {[handle id $h] == $cur} {
    	    	var s [handle other $h]
	    	break
	    } else {
	    	var i [expr $i+1]
	    }
    	}
	
	if {![null $s]} {
	    echo [format {R#%d (%s)} $i [symbol name $s]]
    	} else {
    	    echo
    	}
    } else {
	#
	# Something else -- don't forget the newline, though.
	#
	echo
    }]
}]

##############################################################################
#				print-handle-info
##############################################################################
#
# SYNOPSIS:	Print owner, usage and other info for a handle
# PASS:		val - handle
# CALLED BY:	hwalk, handles
# RETURN:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	3/19/90		Initial Revision
#
##############################################################################
[defsubr print-handle-info {val}
{
    var oi [field $val HM_otherInfo]
    var usage [field $val HM_usageValue]
    var own [field $val HM_owner]
    var ownerHandle [handle lookup $own]
    if {[null $ownerHandle]} {
    	if {$own == 0x20} {
    	    var name {fontman}
    	} else {
    	    var name {?}
    	}
    } else {
    	var name [patient name [handle patient $ownerHandle]]
    }

    if {[field $val HM_lockCount]} {
    	echo -n [format {%-10s%04xh %-4x  } $name $usage $oi]
    } else {
    	var idle [expr [value fetch kernel::systemCounter]-$usage]
	echo -n [format {%-9s%2d:%02d  %-4x  } $name 
	    	    [expr $idle/3600] [expr ($idle%3600)/60] $oi]
    }
}]

##############################################################################
#				hwalk
##############################################################################
#
# SYNOPSIS:	Print out the status of all blocks on the heap.
# PASS:		flags detailed below
# CALLED BY:	the user
# RETURN:	nothing
# SIDE EFFECTS:	lots of shit is printed
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/24/90		Initial Revision
#
##############################################################################
[defcommand hwalk {args} kernel|heap
{Print out the status of all blocks on the heap. Takes two optional arguments.
First argument is a collection of flags, beginning with '-', from the following
set:
    p	print prevPtr and nextPtr as well.
    e	do error-checking on the heap.
    l	just print out locked blocks
    f	fast print-out -- doesn't try to figure out the type of the block.
    s #	start at block #
Second argument is the patient whose blocks are to be printed (either a name
or a core-block's handle ID). The default is to print all the blocks on the
heap.

The letters in the 'Flags' column mean the following:
    s	    sharable
    S	    swapable
    D	    discardable
    L	    contains local memory heap
    d	    discarded (by LMem module: discarded blocks don't appear here)
    a	    attached (notice given to swat whenever state changes)}
{
    var owner nil fast 0 ptrs 0 echeck 0 totsz 0
    var start [value fetch handleBottomBlock]

    if {[length $args] > 0 && [string m [index $args 0] -*]} {
	#
	# Examine the flags word for things we know and set vars
	# accordingly.
	#
	foreach i [explode [range [index $args 0] 1 end chars]] {
	    [case $i in
		l {var locked 1}
		p {var ptrs 1}
		f {var fast 1}
    	    	s {
    	    	    var start [index $args 1]
    	    	    var args [range $args 1 end]
    	    	}
		e {var echeck 1}]
	}
	#
	# Shift the first arg off the list
	#
	var args [range $args 1 end]
    }
    if {[length $args] > 0} {
	#
	# Gave an owner whose handles are to be printed. Figure out if it's
	# a handle ID or a patient name and set owner to the decimal equiv
	# of the handle ID.
	#
	if {![string compare [index $args 0] fontman]} {
    	    var owner 0x20
    	} else {
	    var h [handle lookup [index $args 0]]
	    if {![null $h] && $h != 0} {
	    	var owner [handle id $h]
	    } else {
	    	var owner [handle id
			[index [patient resources
					[patient find [index $args 0]]] 0]]
	    }
    	}
    }

    #
    # Print out the proper banner
    #
    [case $ptrs$fast in
	11 {
	    echo {Handle  Addr    Size  Prev  Next  Flags  Lock  Owner     Idle  oInfo}
	    echo {--------------------------------------------------------------------}
	}
    	10 {
	    echo {Handle  Addr    Size  Prev  Next  Flags  Lock  Owner     Idle  oInfo Type}
	    echo {-----------------------------------------------------------------------------}
    	}
	01 {
	    echo {Handle  Addr    Size  Flags  Lock  Owner     Idle  oInfo}
	    echo {--------------------------------------------------------}
    	}
	00 {
	    echo {Handle  Addr    Size  Flags  Lock  Owner     Idle  oInfo Type}
	    echo {-----------------------------------------------------------------}
    	}]

    #
    # Set up initial conditions.
    #
    var first 1 errFlag 0 free 0
    var nextStruc [value fetch kdata:$start HandleMem] used 0
    var val [value fetch kdata:[field $nextStruc HM_prev] HandleMem]
    if {$echeck} {
	var heapStart [value fetch heapStart] heapEnd [value fetch heapEnd]
    }

    for {var cur $start} {($cur != $start) || $first} {var cur $next} {
    	var val $nextStruc

	var next [field $val HM_next] prev [field $val HM_prev]
	[var nextStruc [value fetch kdata:$next HandleMem]
	     addr [field $val HM_addr]
	     oi [field $val HM_otherInfo]
	     own [field $val HM_owner]]

	if {$echeck} {
	    if {$addr < $heapStart || $addr > $heapEnd} {
		echo [format {\nError: %04x: dataAddress not legal} $cur]
		break
	    }
	    if {[field $nextStruc HM_prev] != $cur} {
		echo [format {\nError: %04x: next block's HM_prev not correct}
			$cur]
		break
	    }
	}
	if {[null $owner] || $own == $owner} {
	    [var first 0
		 size [expr [field $val HM_size]<<4]
		 flags [field $val HM_flags]]

	    if {$echeck && 
		(([field $flags HF_DISCARDED] && ![field $flags HF_LMEM])
					 || [field $flags HF_SWAPPED])} {
		echo
		echo {Error: Discarded/swapped block on heap}
		break
	    }

	if {[null $locked] || [field $val HM_lockCount] != 0} {
	    var totsz [expr $totsz+$size]
	    echo -n [format {%-8.04x%04x %7d  } $cur $addr $size]
	    if {$ptrs} {
		echo -n [format {%04x  %04x  } $prev $next]
	    }

	    if {$own == 0} {
		echo -n {FREE   n/a   }
		var free [expr $free+$size]
	    } elif {[field $flags HF_FIXED]} {
		echo -n {FIXED  n/a   }
		var used [expr $used+1]
	    } else {
	      	if {[field $flags HF_SHARABLE]} {echo -n s} {echo -n { }}
	      	if {[field $flags HF_DISCARDABLE]} {echo -n D} {echo -n { }}
	      	if {[field $flags HF_SWAPABLE]} {echo -n S} {echo -n { }}
	      	if {[field $flags HF_LMEM]} {echo -n L} {echo -n { }}
	      	if {[field $flags HF_DISCARDED]} {echo -n d} {echo -n { }}
    	    	if {[field $flags HF_DEBUG]} {echo -n a} {echo -n { }}
		echo -n [format { %-4d  } [field $val HM_lockCount]]
		var used [expr $used+1]
	    }
	    var ownerHandle [handle lookup $own]
    	    print-handle-info $val
	    if {$own == 0 || $fast} {
		echo
	    } elif {!$fast} {
    	    	heap-print-type $flags $cur $own $ownerHandle $addr $oi
	    }
	}
	}
    }
    if {[null $owner] && [null $locked]} {
	echo [format {\nTotal bytes free: %d} $free]
	echo [format {Total bytes allocated: %d} [expr $totsz-$free]]
    	echo [format {Average used block size: %f} [expr ($totsz-$free)/$used float]]
    } else {
	echo [format {\nTotal bytes allocated: %d} $totsz]
    }
}]

##############################################################################
#				phandle
##############################################################################
#
# SYNOPSIS:	Print out information about a single handle
# PASS:		the handle ID
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/24/90		Initial Revision
#
##############################################################################
[defcommand phandle {num} kernel|output
{Print out a handle. Single argument NUM is the handle's ID number (if you
want it in hex, you'll have to indicate that with the usual radix specifiers
at your disposal)}
{
    var	val [value fetch kdata:$num HandleMem]
    if {[expr [field $val HM_addr]>=0xf000]} {
        [case [format %x [expr [field $val HM_addr]>>8]] in
    	    ff {
    	    	echo [format {GString handle}]
    	    }
    	    fe {
    	    	pthread $num
    	    }
    	    fd {
    	    	echo [format {File handle}]
    	    }
    	    fc {
    	    	echo [format {VM handle}]
    	    }
    	    fb {
    	    	echo [format {UNUSED 0xfb handle}]
    	    }
    	    fa {
    	    	echo [format {Saved block handle}]
    	    }
    	    f9 {
    	    	echo [format {Event (in registers) handle}]
    	    }
    	    f8 {
    	    	echo [format {Event (on stack) handle}]
    	    }
    	    f7 {
    	    	echo [format {Event data handle}]
    	    }
    	    f6 {
    	    	echo [format {Timer handle}]
    	    }
    	    f5 {
    	    	echo [format {Disk handle}]
    	    }
    	    f4 {
    	    	echo [format {Queue handle}]
    	    }
    	]
    } else {
    	echo [format {address: %#x  size: %#x  prev: %#x  next: %#x}
    	      [field $val HM_addr] [field $val HM_size]
    	      [field $val HM_prev] [field $val HM_next]]
    	var owner [field $val HM_owner]
    	var owneraddr [value fetch kdata:$owner.HM_addr]
    	echo -n [format {owner: %#x (} $owner]
    	if {$owner != 0} {
            if {$owner == 0x10} {
    	       echo -n kernel
    	    } elif {$owner == 0x20} {
    	    	echo -n fontman
    	    } elif {($owneraddr & 0xff00) == 0xfc00} {
	    	echo -n kernel::VMem
	    } else {
    	        echo -n [format {%s} [patient name [handle patient
    	    	    	    	    	[handle lookup $owner]]] $owner]
	    }
	} else {
	    echo -n FREE
	}
    	echo -n {)  }
    	var flags [field $val HM_flags]
	if {[field $flags HF_FIXED]} {echo -n {Fixed }}
	if {[field $flags HF_SHARABLE]} {echo -n {Sharable }}
	if {[field $flags HF_DISCARDABLE]} {echo -n {Discardable }}
	if {[field $flags HF_SWAPABLE]} {echo -n {Swapable }}
	if {[field $val HM_addr] == 0} {
	    if {[field $flags HF_DISCARDED]} {
		echo -n {Discarded }
	    } elif {[field $flags HF_SWAPPED]} {
		echo -n {Swapped }
	    }
	}
	if {[field $flags HF_DEBUG]} {echo -n {Debugged }}
    	echo
    	var lc [field $val HM_lockCount]
    	if {$lc != 1} {var lsuff s}
    	echo [format {Locked %d time%s  Last Use: %x  OtherInfo: %x}
    	      $lc $lsuff [field $val HM_usageValue]
    	      [field $val HM_otherInfo]]
    }
}]

##############################################################################
#				_tmem_catch
##############################################################################
#
# SYNOPSIS:	handling routine for a breakpoint at DebugMemory to tell you
#   	    	everything that's hapenning in the heap code
# PASS:		nothing
# CALLED BY:	breakpoint at DebugMemory
# RETURN:	0 (continue the machine)
# SIDE EFFECTS:	stuff be printed
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/24/90		Initial Revision
#
##############################################################################
[defsubr _tmem_catch {}
{
    [var func [index {realloc discard swapout swapin move free modify}
    	    	[read-reg al]]
	 hid [read-reg bx]]
    echo -n $func of [format %04x $hid]
    [case $func in
    	realloc {
	    echo [format { addr = %04x, size = %04x}
	    	    [value fetch kdata:bx.HM_addr]
		    [value fetch kdata:bx.HM_size]]
    	}
	discard|swapout|free {
	    echo
	}
    	swapin {
	    echo [format { dataAddress = %04x}
	    	     [value fetch kdata:bx.HM_addr]]
    	}
	move {
    	    echo [format { newAddress = %04x} [read-reg es]]
    	}
	modify {
    	    var flags [value fetch kdata:bx.HM_flags]
    	    echo -n {Flags now = }
	    if {[field $flags HF_SHARABLE]} {echo -n s} else {echo -n { }}
	    if {[field $flags HF_DISCARDABLE]} {echo -n D} else {echo -n { }}
	    if {[field $flags HF_SWAPABLE]} {echo -n S} else {echo -n { }}
	    if {[field $flags HF_LMEM]} {echo -n L} else {echo -n { }}
    	}
    ]
    #
    # Continue machine
    #
    return 0
}]

##############################################################################
#				tmem
##############################################################################
#
# SYNOPSIS:	Trace memory usage. Catches all calls to DebugMemory and prints
#   	    	out their parameters in some meaningful fashion
# PASS:		nothing
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	breakpoint is set at DebugMemory
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/24/90		Initial Revision
#
##############################################################################
[defcommand tmem {} kernel
{Trace memory usage. Catches calls to DebugMemory, printing out the parameters
passed}
{
    return [brk aset DebugMemory _tmem_catch]
}]

##############################################################################
#				handles
##############################################################################
#
# SYNOPSIS:	Dump the entire handle table in a meaningful way
# PASS:		(optional) id/name of owner whose handles are to be printed
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/24/90		Initial Revision
#
##############################################################################
[defdsubr handles {args} kernel|heap
{Prints out info for all in-use handles}
{
    var owner nil ptrs 1 fast 0

    if {[length $args] > 0 && [string m [index $args 0] -*]} {
	#
	# Examine the flags word for things we know and set vars
	# accordingly.
	#
	foreach i [explode [range [index $args 0] 1 end chars]] {
	    [case $i in
		p {var ptrs 0}
		f {var fast 1}]
	}
	#
	# Shift the first arg off the list
	#
	var args [range $args 1 end]
    }
    if {[length $args] > 0} {
	#
	# Gave an owner whose handles are to be printed. Figure out if it's
	# a handle ID or a patient name and set owner to the decimal equiv
	# of the handle ID.
	#
	if {![string compare [index $args 0] fontman]} {
    	    var owner 0x20
    	} else {
	    var h [handle lookup [index $args 0]]
	    if {![null $h] && $h != 0} {
	    	var owner [handle id $h]
	    } else {
	    	var owner [handle id
			[index [patient resources
					[patient find [index $args 0]]] 0]]
    	    }
	}
    }

    #
    # Print out the proper banner
    #
    [case $ptrs$fast in
	11 {
	    echo {Handle  Addr    Size  Prev  Next  Flags   Lock  Owner     Idle  oInfo}
	    echo {---------------------------------------------------------------------}
	}
    	10 {
	    echo {Handle  Addr    Size  Prev  Next  Flags   Lock  Owner     Idle  oInfo Type}
	    echo {------------------------------------------------------------------------------}
    	}
	01 {
	    echo {Handle  Addr    Size  Flags   Lock  Owner     Idle  oInfo}
	    echo {---------------------------------------------------------}
    	}
	00 {
	    echo {Handle  Addr    Size  Flags   Lock  Owner     Idle  oInfo Type}
	    echo {------------------------------------------------------------------}
    	}]

    #
    # Set up initial conditions.
    #
    [var start [sym addr [sym find var HandleTable]] totsz 0 free 0
    	 end [value fetch lastHandle]]
    var nextStruc [value fetch kdata:$start HandleMem]
    var hs [type size [sym find type HandleMem]]

    for {var cur $start} {$cur != $end} {var cur $next} {
    	var val $nextStruc

	var next [expr $cur+$hs]
	[var nextStruc [value fetch kdata:$next HandleMem]
	     addr [field $val HM_addr]
	     oi [field $val HM_otherInfo]
	     own [field $val HM_owner]]

	if {[null $owner] || $own == $owner} {
	    [var size [expr [field $val HM_size]<<4]
		 flags [field $val HM_flags]]

    	    if {$addr >= 0xf000 || ($addr == 0 && $own == 0)} {
    	    	echo -n [format %-8.04x $cur]
    	    	#XXX: give info for the handle...
	    	[case [format %x [expr $addr>>8]] in
    	    	 00 {echo FREE}
    	      	 f4 {echo EVENT QUEUE}
    	    	 f5 {echo DISK}
    	    	 f6 {echo TIMER}
    	    	 f7 {echo EVENT DATA}
		 f8 {echo EVENT w/STACK}
		 f9 {echo EVENT}
		 fa {echo SAVED BLOCK}
    	    	 fc {echo VM}
		 fd {echo FILE}
		 fe {echo THREAD}
		 ff {echo GSEG}
		 default {
		    echo Signature: [format %x [expr $addr>>8]]
		 }]
    	    } else {
		echo -n [format {%-8.04x%04x %7d  } $cur $addr $size]
		if {$ptrs} {
		    echo -n [format {%04x  %04x  } [field $val HM_prev]
			     [field $val HM_next]]
		}

		if {$own == 0} {
		    echo -n {FREE    n/a   }
		    if {$addr != 0} {
			var free [expr $free+$size]
		    }
		} elif {[field $flags HF_FIXED]} {
		    var totsz [expr $totsz+$size]
		    echo -n {FIXED   n/a   }
		} else {
		    var totsz [expr $totsz+$size]
		    if {[field $flags HF_SHARABLE]} {echo -n s} {echo -n { }}
		    if {[field $flags HF_DISCARDABLE]} {echo -n D} {echo -n { }}
		    if {[field $flags HF_SWAPABLE]} {echo -n S} {echo -n { }}
		    if {[field $flags HF_LMEM]} {echo -n L} {echo -n { }}
		    if {[field $flags HF_DISCARDED]} {echo -n d} {echo -n { }}
		    if {[field $flags HF_DEBUG]} {echo -n a} {echo -n { }}
		    if {[field $flags HF_SWAPPED]} {echo -n w} {echo -n { }}
		    echo -n [format { %-4d  } [field $val HM_lockCount]]
		}
		var ownerHandle [handle lookup $own]
    	    	print-handle-info $val
		if {$own == 0 || $fast} {
		    echo
		} elif {!$fast} {
    	    	    heap-print-type $flags $cur $own $ownerHandle $addr $oi
		}
    	    }
	}
    }
    if {[null $owner]} {
	echo [format {\nTotal bytes free: %d} $free]
	echo [format {Total bytes allocated: %d} [expr $totsz-$free]]
    } else {
	echo [format {\nTotal bytes allocated: %d} $totsz]
    }
}]

[defsubr check-heap {}
{
    var cur [value fetch kernel::handleBottomBlock]
    
    var end $cur
    
    do {
    	if {[value fetch kdata:$cur.kernel::HM_addr] == 0} {
	    echo [format {Handle %04xh has address 0} $cur]
    	}
	var cur [value fetch kdata:$cur.kernel::HM_next]
    } while {$cur != $end}
}]

##############################################################################
#				hgwalk
##############################################################################
#
# SYNOPSIS:	Print out the status of all blocks on the heap with respect
#		to the geode that owns them
# PASS:		flags detailed below
# CALLED BY:	the user
# RETURN:	nothing
# SIDE EFFECTS:	lots of shit is printed
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	tony	6/24/90		Initial Revision
#
##############################################################################
[defcommand hgwalk {args} kernel|heap
{Print out all geodes and their memory usage.}
{
    var owner nil
    var t [table create]
    protect {
	var glist {}
	var free 0 gtotal 0

	if {[length $args] > 0} {
	    #
	    # Gave an owner whose handles are to be printed. Figure out if it's
	    # a handle ID or a patient name and set owner to the decimal equiv
	    # of the handle ID.
	    #
	    if {![string compare [index $args 0] fontman]} {
		var owner 0x20
	    } else {
		var h [handle lookup [index $args 0]]
		if {![null $h] && $h != 0} {
		    var owner [handle id $h]
		} else {
		    var owner [handle id
			    [index [patient resources
					    [patient find [index $args 0]]] 0]]
		}
	    }
	}
	echo -n {Tabulating data}
	#
	# Set up initial conditions.
	#
	var start [value fetch handleBottomBlock] first 1 errFlag 0 free 0
	var nextStruc [value fetch kdata:$start HandleMem] used 0
	var val [value fetch kdata:[field $nextStruc HM_prev] HandleMem]

    #var foo 10
	for {var cur $start} {($cur != $start) || $first} {var cur $next} {
	    echo -n {.}
	    flush-output
    #echo -n [format {Working on %04xh, } $cur]
	    var first 0
	    var val $nextStruc

	    var next [field $val HM_next] prev [field $val HM_prev]
	    [var nextStruc [value fetch kdata:$next HandleMem]
		 addr [field $val HM_addr]
		 oi [field $val HM_otherInfo]
		 own [field $val HM_owner]]

    #var foo [expr $foo-1]
    #if {$foo == 0} {var next $start}
	    if {[null $owner] || $own == $owner} {
		[var size [expr [field $val HM_size]<<4]
		     flags [field $val HM_flags]]
    #echo -n [format {size = %d, } $size]
		var gtotal [expr $gtotal+$size]
		if {$own == 0} {
    #echo [format {FREE}]
		    var free [expr $free+$size]
    	    	} elif {$size >= 65536} {
		    # fake block allocated by MemExtendHeap
		    var gtotal [expr $gtotal-$size]
		} else {
		    var oh [handle lookup $own]
		    if {![null $oh] && [handle isvm $oh]} {
    	    	    	var own [value fetch kdata:[value fetch kdata:$own.HVM_fileHandle].HF_owner]
		    }
		    var entry [table lookup $t $own]
		    if {[null $entry]} {
    #echo -n [format {new geode "%s", } $own]
			var entry {0 0 0 0 0 0 0 0}
			var glist [concat $glist $own]
		    }
		    if {[field $flags HF_FIXED]} {
    #echo [format {adding to fixed}]
			var entry [listadd $entry 0 1]
			var entry [listadd $entry 1 $size]
		    } elif {[field $flags HF_DISCARDABLE]} {
    #echo [format {adding to discardable}]
			var entry [listadd $entry 2 1]
			var entry [listadd $entry 3 $size]
		    } elif {[field $flags HF_LMEM] &&
				    [value fetch $addr:LMBH_lmemType]==2} {
    #echo [format {adding to objblock}]
			var entry [listadd $entry 4 1]
			var entry [listadd $entry 5 $size]
		    } else {
    #echo [format {adding to other}]
			var entry [listadd $entry 6 1]
			var entry [listadd $entry 7 $size]
		    }
		    table enter $t $own $entry
		}
	    }
	}
	echo
	echo

	#
	# Print out the proper banner
	#
	echo {            Fixed       Discardable ObjBlock    Other       Total}
	echo {geode       #/total     #/total     #/total     #/total     #/total}
	echo {-----       -------     -------     --------    -------     -------}

	#
	# Do the kernel
	#
	var ksize [expr {[handle size [handle lookup 1]]+
			 [handle size [handle lookup 8]]+
			 [handle size [handle lookup 16]]}]
	var gtotal [expr $gtotal+$ksize]
	echo [format {%-12s%2d/%-9d%2d/%-9d%2d/%-9d%2d/%-9d%2d/%d   %2.2f%%}
		    {non-heap}
		    3 $ksize 0 0 0 0 0 0 3 $ksize [expr $ksize/$gtotal*100 f]]

	var total {3 $ksize 0 0 0 0 0 0 3 $ksize}

	foreach own $glist {
	    var oldtotal $total
	    var total {}
	    var entry [table lookup $t $own]
	    var entry [concat $entry [expr {[index $entry 0]+[index $entry 2]+
					    [index $entry 4]+[index $entry 6]}]
				     [expr {[index $entry 1]+[index $entry 3]+
					    [index $entry 5]+[index $entry 7]}]]
	    var oh [handle lookup $own]
	    if {[null $oh]} {
		if {$own == 0x20} {
		    echo -n [format {%-12s} fontman]
		} else {
		    echo -n [format {%04xh%7s} $own {}]
		}
	    } else {
		echo -n [format {%-12s} [patient name [handle patient
						    [handle lookup $own]]]]
	    }
	    for {var i 0} {$i < 10} {var i [expr $i+2]} {
		echo -n [format {%2d/%-9d} [index $entry $i]
					   [index $entry [expr $i+1]]]
		var total [concat $total
		  [expr [index $oldtotal $i]+[index $entry $i]]
		  [expr [index $oldtotal [expr $i+1]]+[index $entry [expr $i+1]]]]
	    }
	    echo [format {%2.2f%%} [expr [index $entry 9]/$gtotal*100 f]]
	}
	echo
	echo -n [format {%-12s} {TOTAL:}]
	for {var i 0} {$i < 10} {var i [expr $i+2]} {
	    echo -n [format {%2d/%-9d} [index $total $i]
				       [index $total [expr $i+1]]]
	}
	echo
	echo -n [format {%-12s} {}]
	for {var i 0} {$i < 10} {var i [expr $i+2]} {
	    var j [expr [index $total [expr $i+1]]/$gtotal*100 f]
	    echo -n [format {%2.2f%%      } $j]
	    if {[expr $j<10 f]} {
		echo -n { }
	    }
	}
	echo
	echo
	echo [format {Total free space: %d (%2.2f%%)} $free
		    [expr $free/$gtotal*100 f]]
    } {
    	table destroy $t
    }
}]


[defsubr listadd {l i num}
{
# echo [format {listadd called with %d, %d, } $i $num] $l
    if {$i == 0} {
	var ret {}
    } else {
	var ret [range $l 0 [expr $i-1]]
    }
    return [concat $ret [expr [index $l $i]+$num] [range $l [expr $i+1] end]]
}]

##############################################################################
#				memsize
##############################################################################
#
# SYNOPSIS:	Tweak the system so that the heap is a given size
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	tony	7/12/90		Initial Revision
#
##############################################################################
[defcommand memsize {args} kernel|heap
{memsize changes the ammount of memory that GEOS thinks that it has.  It can
only be run at startup, before the heap has been initialized.  memsize accounts
for the size of the stub.
    memsize 	    	Report the current memory size
    memsize 512	    	Work like a 512K system
}
{
    var stubSize [handle size [handle find kernel::SwatSeg]]
    var dosSize [expr 16*[handle segment [handle find kernel::PSP]]]

    if {![null $args]} {
    	if {[value fetch msdosSS]!=0} {
    	    echo [format {memsize can only change the memory size on startup.}]
    	    return
    	}
    	assign PSP:PSP_endAllocBlk [expr ($args*1024/16)+($stubSize/16)]
    }

    var curTop [value fetch PSP:PSP_endAllocBlk]

    echo [format {DOS occupies %d bytes.} $dosSize]

    echo [format {GEOS believes that this machine has %d bytes (%.1fK).}
    	    	    [expr ($curTop*16)-$stubSize]
    	    	    [expr (($curTop*16)-$stubSize)/1024 f]]
}]
