##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
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
#   	fhan
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/13/89		Initial Revision
#
# DESCRIPTION:
#	Functions for examining heap structures
#
#	$Id: heap.tcl,v 3.99 97/04/29 19:17:22 dbaumann Exp $
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
    global geos-release

    if {![null $ownerHandle]} {
    	var s nil i 0 
	foreach h [patient resources [handle patient $ownerHandle]] {
	    if {[handle id $h] == $cur} {
    	    	var s [handle other $h]
	    	break
	    } else {
	    	var i [expr $i+1]
	    }
    	}
	    
    	if {![null $s] && ([handle state $h] & 0x80)} {
	    echo [format {R#%d (%s)} $i [symbol name $s]]
	    return
    	}
    }

    if {![null $ownerHandle] && [handle isvm $ownerHandle]} {
	#
	# Owned by a VM handle.
	#
	echo -n [format {VM(%04xh):}
			[value fetch kdata:$own.HVM_fileHandle]]
    }
    [if {[field $flags HF_LMEM]}
    {
    	if {$addr == 0} {
	    echo 
    	} else {
	    var i [value fetch $addr:LMBH_lmemType]
	    var t [type emap $i [if {[not-1x-branch]}
				    {sym find type LMemType}
				    {sym find type LMemTypes}]]
	    if {![null $t]} {
		#10 is length of "LMEM_TYPE_"
		[case $t in
		    *OBJ_BLOCK {
		    	echo -n {OBJ}
	    	    	if {![null $ownerHandle] &&
    	    	    	    	    	    [handle isvm $ownerHandle]} {
    	    	    	    var exect [value fetch kdata:$own.HVM_execThread]
    	    	    	} else {
    	    	    	    var exect $other
    	    	    	}
			foreach i [thread all] {
			    if {[thread id $i] == $exect} {
				echo -n ([patient name [handle patient
    	    	    	    	    	[thread handle $i]]]:[thread number $i])
				break
			    }
			}
		    }
		    *DB_ITEMS {
		    	echo -n [range $t 10 end chars]
			echo -n ([format %04xh $own])
		    }
    	    	    *GENERAL {
    	    	    	echo -n $t
    	    	    }
    	    	    * {
		    	echo -n [range $t 10 end chars]
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
    } elif {[field $flags HF_FIXED] &&
    	    ![null [handle lookup $cur]] &&
    	    ([value fetch kdata:$cur.HM_otherInfo] == 1) &&
	    ([value fetch ^h$cur:TPD_blockHandle] == $cur) &&
    	    ![null [handle lookup [value fetch ^h$cur:TPD_threadHandle]]] &&
	    [handle isthread
	     [handle lookup [value fetch ^h$cur:TPD_threadHandle]]]}
    {
	echo Stack([threadname [value fetch ^h$cur.TPD_threadHandle]])
    } elif {((${geos-release} >= 2 &&
    	      $own == [value fetch loaderVars.KLV_kernelHandle]) ||
	      $own == 0x10) &&
    	    !([handle state [handle lookup $cur]] & 0x80)}
    {
	#
	# Owned by kernel and not one of its resources (0x80 of state is
	# clear)
	#
	var iniBufNum 0 ibn 0
    	[if {(${geos-release} >= 2 &&
	      ![null [patient find geos]] &&
	      ![null [mapconcat ifbh
	      	    	    	 [value fetch loaderVars.KLV_initFileBufHan]
		      {
	       	   	   if {$ifbh == $cur} {
    	    	   	       # just something non-nil...
			       var iniBufNum $ibn
			       var cur
    	    	   	   } else {
			       var ibn [expr $ibn+1]
    	    	    	   }
    	    	      }]]) ||
	      (${geos-release} < 2 &&
    	       ![null [patient find klib]] &&
	       $cur == [value fetch klib::dgroup::initFileBufHan])}
    	{
    	    echo INI Buffer $iniBufNum
    	} elif {${geos-release} < 2 && $cur == [value fetch diskTblHan]} {
	    echo Disk Table
    	} elif {$addr != 0 &&
	    	((${geos-release} < 2 && 
		  [value fetch kdata:$cur.HM_size] == 0xd) ||
		 (${geos-release} >= 2 &&
		  [value fetch kdata:$cur.HM_size] == 0x10)) &&
	        [string c [type emap [value fetch ^h$cur:LMBH_lmemType]
				[if {[not-1x-branch]}
				    {sym find type LMemType}
				    {sym find type LMemTypes}]]
		    LMEM_TYPE_GSTATE] == 0}
    	{
    	    echo Cached GState
    	} elif {$addr >= 0x9fff &&
	        [value fetch kdata:$cur.HM_lockCount] == 1 &&
		[value fetch kdata:$cur.HM_usageValue] < 1000 &&
		([value fetch kdata:$cur.HM_flags byte] == 0 ||
		 [value fetch kdata:$cur.HM_flags byte]==[fieldmask HF_DEBUG])}
    	{
	    echo Fake
    	} elif {${geos-release} >= 2 && $cur == 
	        [value fetch loaderVars.KLV_stdDirPaths]}
    	{
	    echo StdPaths
    	} else {
    	    var t [sym find type KBlockTypes]
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
    } else {
	#
	# Something else -- don't forget the newline, though.
	#
	echo
    }]
}]

#############################################################################
#		is-code-resource
#############################################################################
#
# SYNOPSIS:	Returns non-zero if this is a code resource
#
# CALLED BY:	GLOBAL
# PASS:		cur - handle to check to see if it is a code resource
#   	    	ownerHandle - handle that owns $cur
#   	    	flags - HM_flags record for $cur
#   	    	val - HandleMem record for $cur		
# RETURN:	nada
#
# KNOWN BUGS/SIDE EFFECTS/IDEAS:
# 
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	atw	8/20/93  	Initial version
#
############################################################################
[defsubr is-code-resource {cur ownerHandle flags val}
{
    var s nil i 0 
    if {![null $ownerHandle]} {
	foreach h [patient resources [handle patient $ownerHandle]] {
	    if {[handle id $h] == $cur} {
    	    	var s [handle other $h]
	    	break
	    } else {
	    	var i [expr $i+1]
	    }
    	}
    }
    if {[null $s] || $i<2
        || !([field $flags HF_FIXED] || [field $flags HF_DISCARDABLE])
    	|| [field $flags HF_LMEM]} {
	return 0
    } else {
	return 1
    }
	
}]


##############################################################################
#				owner-name
##############################################################################
#
# SYNOPSIS:	Convert a handle ID from HM_owner or HG_owner into a name
#   	    	for the user.
# PASS:		owner	= handle ID
# CALLED BY:	INTERNAL
# RETURN:	string representation of the owner
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	10/26/92	Initial Revision
#
##############################################################################
[defsubr owner-name {owner}
{
    if {$owner == 0x10} {
       return kernel
    } elif {$owner == 0x20} {
	return fontman
    } elif {[value fetch kdata:$owner.HG_type] == 0xfc} {
	return geos::VMem
    } else {
    	var h [handle lookup $owner]
	if {[null $h]} {
	    return !LOADED
    	} else {
	    return [patient name [handle patient [handle lookup $owner]]]
    	}
    }
}]

[defsubr get-real-owner {val}
{
    var own [field $val HM_owner]
    var ownerHandle [handle lookup $own]
    if {![null $ownerHandle] && [handle isvm $ownerHandle]} {
    	var file [value fetch kdata:$own.HVM_fileHandle]
    	var own [value fetch kdata:$file.HF_owner]
    }
    return $own
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
    var own [get-real-owner $val]
    var ownerHandle [handle lookup $own]
    if {[null $ownerHandle]} {
    	if {$own == 0x20} {
    	    var name {fontman}
    	} else {
    	    var name [format %04xh $own]
    	}
    } else {
    	var name [patient name [handle patient $ownerHandle]]
    }

    #
    # if the block is free then bail
    #
    if {$own == 0} {
    	return
    }
    #
    # Print the owner of the block
    #
    echo -n [format {%-9s} $name]
    #
    # Print the idle time for the block (in minutes:seconds)
    #
    if {([field [field $val HM_flags] HF_FIXED]) ||
    	    	    	    ([field $val HM_lockCount] == 255)} {
    	echo -n { n/a  }
    } elif {[field $val HM_lockCount]} {
    	echo -n [format {%04xh } $usage]
    } else {
    	var sc [value fetch geos::systemCounter.low]
	if {$usage > $sc} {
	    var sc [expr $sc+65536]
    	}
    	var idle [expr $sc-$usage]
	echo -n [format {%2d:%02d }
	    	    [expr $idle/3600] [expr ($idle%3600)/60]]
    }
    #
    # Print the otherinfo of the block
    #
    echo -n [format {%4xh  } $oi]
}]

##############################################################################
#				hwalk
##############################################################################
#
# SYNOPSIS:	Print out the status of all blocks on the heap.
# PASS:		flags detailed below
# CALLED BY:	the user
# RETURN:	nothing
# SIDE EFFECTS:	lots of stuff is printed
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/24/90		Initial Revision
#
##############################################################################
[defcmd hwalk {args} {top.heap system.heap patient.handle}
{Usage:
    hwalk [<flags>] [<patient>]

Examples:
    "hwalk" 	    	display the heap
    "hwalk -e"	    	display the heap and perform error checking
    "hwalk -r ui"   	display the heap owned by the ui in reverse order
    "hwalk -L 1000h" 	display all blocks 4K or larger.
Synopsis:
    Print the status of all blocks on the global heap.

Notes:
    * The flags argument is a collection of flags, beginning with '-',
      from the following set:

        r	print heap in reverse order (decreasing order of addresses)
    	p	print prevPtr and nextPtr as well.
        e	do error-checking on the heap.
        l	just print out locked blocks
        f	fast print-out - this doesn't try to figure out the block type
	F	just print out fixed blocks
	c	just print out code resources
        s <num> start at block <num>
    	L <num>	print blocks larger than <num> bytes large
	d	print out non-discardable blocks
    	x   	just print out xip blocks

    * The patient argument is a patient whose blocks are to be selectively
      printed (either a name or a core-block's handle ID). The default is to
      print all the blocks on the heap.

    * The following columns can appear in a listing:
    	HANDLE	The handle of the block
    	ADDR	The segment address of the block
    	SIZE	Size of the block in bytes
    	PREV	The previous block handle (appears with the -p flag)
    	NEXT	The next block handle (appears with the -p flag)
    	FLAGS	The following letters appear in the FLAGS column:
        	    s	  sharable
        	    S	  swapable
        	    D	  discardable
        	    L	  contains local memory heap
        	    d	  discarded (by LMem module: discarded blocks 
        	    	  don't appear here)
        	    a	  attached (notice given to Swat whenever state changes)
    	LOCK	Number of times the block is locked or n/a if FIXED.
    	OWNER	The process which owns the block
    	IDLE	The time since the block has been accessed in minutes:seconds
    	OINFO	The otherInfo field of the handle (block type dependent)
    	TYPE	Type of the block, for example:
    	    	R#1 (dgroup)        Resource number one, named "dgroup"
    	    	Geode   	    Internal control block for a geode
    	    	WINDOW, GSTATE,	    Internal structures of the given type
    	    	GSTRING, FID_BLK,
    	    	FONT
    	    	OBJ(write:0)	    Object block run by thread write:0
    	    	VM(3ef0h)...	    VM block from VM file 3ef0h

    * This only prints those handles in memory while 'handles' prints
      all handles used.

    * Information about a particular block may be obtained with the lhwalk or
      phandle command.

See also:
    lhwalk, phandle, handles, hgwalk.
}
{
    var owner nil fast 0 ptrs 0 echeck 0 totsz 0 fake 0 fakesz 0 disc 0
    global geos-release
    
    if {${geos-release} >= 2} {
    	var start [value fetch loaderVars.KLV_handleBottomBlock]
    	var kernel [value fetch loaderVars.KLV_kernelHandle]
    } else {
    	var start [value fetch geos::handleBottomBlock]
	var kernel 16
    }

    [var nextField HM_next
	 prevField HM_prev
	 lowVal val
	 highVal nextStruct
	 lowID cur
	 highID next]

    var locked 0 codeOnly 0 fixed 0
    if {[length $args] > 0 && [string m [index $args 0] -*]} {
	#
	# Examine the flags word for things we know and set vars
	# accordingly.
	#
	foreach i [explode [range [index $args 0] 1 end chars]] {
	    [case $i in
		l {var locked 1}
		c {var codeOnly 1}
		p {var ptrs 1}
		f {var fast 1}
		F {var fixed 1}
		d {var disc 1}
    	    	s {
    	    	    var start [index $args 1]
    	    	    var args [range $args 1 end]
    	    	}
    	    	L { 
    	    	    var minsize [index $args 1]
    	    	    var args [range $args 1 end] 
    	    	}
		e {var echeck 1}
		r {
		    [var nextField HM_prev
			 prevField HM_next
			 lowVal nextStruct
			 highVal val
			 lowID next
			 highID cur]
		    var start [value fetch kdata:$start.HM_prev]
    	    	}
	    ]
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
	    echo {HANDLE  ADDR   SIZE  PREV  NEXT  FLAGS  LOCK   OWNER    IDLE  OINFO}
	    echo {-------------------------------------------------------------------}
	}
    	10 {
	    echo {HANDLE  ADDR   SIZE  PREV  NEXT  FLAGS  LOCK   OWNER    IDLE  OINFO  TYPE}
	    echo {----------------------------------------------------------------------------}
    	}
	01 {
	    echo {HANDLE  ADDR   SIZE  FLAGS  LOCK   OWNER    IDLE  OINFO}
	    echo {-------------------------------------------------------}
    	}
	00 {
	    echo {HANDLE  ADDR   SIZE  FLAGS  LOCK   OWNER    IDLE  OINFO  TYPE}
	    echo {----------------------------------------------------------------}
    	}]

    #
    # Set up initial conditions.
    #
    var first 1 errFlag 0 free 0 largeFree 0
    var nextStruct [value fetch kdata:$start HandleMem] used 0
    var val [value fetch kdata:[field $nextStruct HM_prev] HandleMem]
    if {$echeck} {
    	if {${geos-release} >= 2} {
	    var heapStart [value fetch loaderVars.KLV_heapStart]
	    var heapEnd [value fetch loaderVars.KLV_heapEnd]
    	} else {
	    var heapStart [value fetch geos::heapStart]
	    var heapEnd [value fetch geos::heapEnd]
    	}
    }

    [for {var cur $start}
    	 {($cur != $start) || $first}
	 {var cur $next}
    {
    	var val $nextStruct

	var next [field $val $nextField] prev [field $val $prevField]
	[var nextStruct [value fetch kdata:$next HandleMem]
	     addr [field $val HM_addr]
	     oi [field $val HM_otherInfo]
	     own [field $val HM_owner]
	     realown [get-real-owner $val]]

	if {$echeck} {
	    if {$addr < $heapStart || $addr > $heapEnd} {
		echo [format {\nError: %04xh: dataAddress not legal} $cur]
		break
	    }
	}
	if {[null $owner] || $realown == $owner} {
	    [var first 0
		 size [expr [field $val HM_size]<<4]
		 flags [field $val HM_flags]]

	    if {$echeck && 
		(([field $flags HF_DISCARDED] && ![field $flags HF_LMEM])
					 || [field $flags HF_SWAPPED])} {
		echo
		echo [format {Error: %04xh: Discarded/swapped block on heap}
		      $cur]
		break
	    }
	    [if {(!$locked ||
		  [field $val HM_lockCount] != 0) &&
		 (!$disc ||
		  [field $flags HF_DISCARDABLE] == 0) &&
	         (!$fixed || 
		  ([field $flags HF_FIXED] ||
		   ([field $val HM_lockCount] == -1))) &&
	         (!$codeOnly ||
		  [is-code-resource $cur [handle lookup $own] $flags $val])}    	    {
		[if {[field $val HM_owner] == $kernel &&
		     [field $val HM_usageValue] < 1000 &&
		     [field $val HM_addr] >= 0x9fff &&
		     [field $val HM_lockCount] == 1 &&
		     ([value fetch kdata:$cur.HM_flags byte] == 0 ||
		      [value fetch kdata:$cur.HM_flags byte] == [fieldmask HF_DEBUG])}
		{
		    var fake [expr $fake+1] fakesz [expr $fakesz+$size]
		} else {
		    var totsz [expr $totsz+$size]
		}]
    	    	if {![null $minsize] && $minsize > $size} {
    	    	    continue
    	    	}    	
		echo -n [format {%04xh  %04xh %6d  } $cur $addr $size]
		if {$ptrs} {
		    echo -n [format {%04xh  %04xh  } $prev $next]
		}

		if {$own == 0} {
		    echo -n {FREE    n/a   }
		    var free [expr $free+$size]
    	    	    if {$size > $largeFree} {
    	    	    	var largeFree $size
    	    	    }
		} elif {[field $flags HF_FIXED]} {
		    echo -n {FIXED   n/a   }
		    var used [expr $used+1]
		} elif {[field $val HM_lockCount] == -1} {
		    echo -n {PFIXED  n/a   }
		    var used [expr $used+1]
		} else {
		    if {[field $flags HF_SHARABLE]} {echo -n s} {echo -n { }}
		    if {[field $flags HF_DISCARDABLE]} {echo -n D} {echo -n { }}
		    if {[field $flags HF_SWAPABLE]} {echo -n S} {echo -n { }}
		    if {[field $flags HF_LMEM]} {echo -n L} {echo -n { }}
		    if {[field $flags HF_DISCARDED]} {echo -n d} {echo -n { }}
		    if {[field $flags HF_DEBUG]} {echo -n a} {echo -n { }}
		    echo -n [format {  %-4d  } [field $val HM_lockCount]]
		    var used [expr $used+1]
		}
		var ownerHandle [handle lookup $own]
		print-handle-info $val
		if {$own == 0 || $fast} {
		    echo
		} elif {!$fast} {
		    heap-print-type $flags $cur $own $ownerHandle $addr $oi
		}
	    }]
	}
    	if {$echeck} {
	    if {[field $nextStruct $prevField] != $cur} {
		echo [format {\nError: %04xh: next block's %s not correct}
			$cur $prevField]
		break
	    }
    	    [if {([var $highID] != $start) &&
	    	 ([field [var $lowVal] HM_addr]+[field [var $lowVal] HM_size] !=
	    	  [field [var $highVal] HM_addr])}
    	    {
	    	echo [format {\nError: %04xh: block doesn't reach to next block (%04xh)\n}
		    	[var $lowID] [var $highID]]
    	    }]
	    if {[field $val HM_owner]==0 && [field $nextStruct HM_owner]==0} {
	    	echo [format {\nError: %04xh: block not coalesced with following block (%04xh)\n}
		    	[var $lowID] [var $highID]]
    	    }
    	}
    }]
    if {[null $owner] && !$locked && !$fixed && !$codeOnly} {
	echo [format {\nTotal bytes free: %d} $free]
    	echo [format {Largest free block: %d} $largeFree]
	echo [format {Total bytes allocated: %d} [expr $totsz-$free]]
    	echo [format {Average used block size: %f} 
	    	[if {$used != 0} {expr ($totsz-$free)/$used float} {expr 0}]]
    	if {$fake} {
	    echo [format {%d fake %s covering %d bytes} $fake 
	    	    [pluralize block $fake] $fakesz]
    	}
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
[defcmd phandle {num} {top.print system.heap patient.handle}
{Usage:
    phandle <handle ID>

Examples:
    "phandle 1a80h" 	print the handle 1a80h

Synopsis
    Print out a handle.

Notes:
    * The handle ID argument is just the handle number.  Make sure that
      the proper radix is used.

    * The size is in paragraphs.

See also:
    hwalk, lhwalk, psegment.
}
{
    #
    # Parse the thing down to an address list. If the thing actually resides
    # in memory ([index $a 0] is non-null), we assume the user wants to print
    # information about a MemHandle variable and use $num as the address from
    # which to fetch a word, using that as the handle itself.
    #
    var a [addr-parse $num 0]
    if {[null [index $a 0]] || [string c [index $a 0] value] == 0} {
    	# $num is a constant, so just use the offset portion.
    	var num [index $a 1]
    } else {
    	var num [value fetch $num [type word]]
    }

    if {($num & 0xf) ||
	($num < [value fetch loaderVars.KLV_handleTableStart]) ||
	($num >= [value fetch loaderVars.KLV_lastHandle])} {
	error [format {%04xh: Not a valid handle} $num]
    }

    var	val [value fetch kdata:$num HandleMem]
    if {[expr [field $val HM_addr]>=0xf000]} {
        [case [format %x [expr [field $val HM_addr]>>8]] in
    	    ff {
    	    	echo [format {GString handle}]
    	    }
    	    fe {
    	    	echo Thread Handle:
    	    	pthread $num
    	    }
    	    fd {
    	    	echo File Handle:
    	    	fhandle $num
    	    }
    	    fc {
    	    	echo VM Handle:
		var ethread [value fetch kdata:$num.HVM_execThread]
		if {$ethread != 0} {
		    var etname [threadname $ethread]
		} else {
		    etname none
    	    	}
    	    	#
		# Basic info first
		#
		echo [format {file = %04xh, execThread = %04xh (%s), header = ^h%04xh, refCount = %d}
		    	[value fetch kdata:$num.HVM_fileHandle]
			$ethread $etname
			[value fetch kdata:$num.HVM_headerHandle]
			[value fetch kdata:$num.HVM_refCount]]

    	    	#
		# Print relocation routine, if any
		#
		var rs [value fetch kdata:$num.HVM_relocRoutine.segment]
		var ro [value fetch kdata:$num.HVM_relocRoutine.offset]
    	    	if {$rs != 0} {
		    var s [symbol faddr proc ${rs}:${ro}]
		    if {[null $s]} {
		    	echo [format {reloc routine = %04xh:%04xh} $rs $ro]
    	    	    } elif {[index [symbol get $s] 0] == $ro} {
		    	echo reloc routine = [symbol fullname $s]
    	    	    } else {
		    	echo [format {reloc routine = %s+%d}
			    	[symbol fullname $s]
				$ro-[expr [index [symbol get $s] 0]]]
    	    	    }
    	    	}
		#
		# Print flags
		#
		echo -n flags = 
		require fmtval print
		fmtval [value fetch kdata:$num.HVM_flags] [symbol find type InternalVMFlags] 0 {} 1
    	    	echo
    	    	#
		# Print anyone waiting for access.
		#
    	    	var sem [value fetch kdata:$num.HVM_semaphore]
		if {$sem != 1} {
		    require print-queue thread
		    
		    echo {P'ed; Waiting for access:}
		    print-queue $sem
    	    	}
    	    }
    	    fb {
    	    	echo Semaphore handle:
		var owner [value fetch kdata:$num.HS_owner]
    	    	echo [format {owner = %04xh (%s)} $owner [owner-name $owner]]
		var sv [value fetch kdata:$num.HS_moduleLock.TL_sem.Sem_value]
		
		if {$sv < 1} {
		    var lown [value fetch kdata:$num.HS_moduleLock.TL_owner]
		    if {$lown != 0xffff} {
			var nest [value fetch kdata:$num.HS_moduleLock.TL_nesting]
		    	echo [format {Grabbed %d %s by %04xh (%s)} $nest
			    	[pluralize time $nest] $lown
				[threadname $lown]]
    	    	    }
    	    	}
		echo value = $sv, blocked:
    	    	require print-queue thread
		print-queue [value fetch kdata:$num.HS_moduleLock.TL_sem.Sem_queue]
    	    }
    	    fa {
    	    	echo Saved block handle:
		echo [format {duplicate's handle: %04xh, owned by %04xh (%s)}
		    	[value fetch kdata:$num.HSB_handle]
			[value fetch kdata:$num.HSB_owner]
			[owner-name [value fetch kdata:$num.HSB_owner]]]
    	    }
    	    f9 {
    	    	echo Event handle:
    	    	pevent $num
    	    }
    	    f8 {
    	    	echo Event handle, data on stack:
    	    	pevent $num
    	    }
    	    f7 {
    	    	echo [format {Event data handle}]
    	    }
    	    f6 {
	    	echo Timer handle:
    	    	ptimer $num
    	    }
    	    f5 {
	    	# NOT USED FOR 2.0
    	    	echo [format {Disk handle}]
    	    }
    	    f4 {
    	    	echo Queue handle:
		echo -n [format {owner: %04xh (%s),} 
		    	    [value fetch kdata:$num.HQ_owner]
			    [owner-name [value fetch kdata:$num.HQ_owner]]]
    	    	if {[value fetch kdata:$num.HQ_thread]} {
		    echo [format {thread = %04xh (%s)}
		    	    [value fetch kdata:$num.HQ_thread]
			    [threadname [value fetch kdata:$num.HQ_thread]]]
    	    	} else {
		    echo no thread
    	    	}
		var n [value fetch kdata:$num.HQ_semaphore.Sem_value]
		if {$n < 0} {
		    echo no events, waiting for event:
		    require print-queue thread
		    print-queue [value fetch kdata:$num.HQ_semaphore.Sem_queue]
    	    	} else {
		    echo $n [pluralize event $n]
    	    	}
    	    }
	    f3 {
	    	echo [format {FREE HANDLE}]
	    }
	    f2 {
		echo Heap Reservation handle:
		echo [format {%dk Reserved for %04xh (%s)}
		      [value fetch kdata:$num.HR_size]
		      [value fetch kdata:$num.HR_owner]
		      [owner-name [value fetch kdata:$num.HR_owner]]]
	    }
    	]
    } else {

	global kernelVersion
	var han [handle lookup $num]
	if {$kernelVersion >= 2 && ![null $han]} {
		var xipPage [handle xippage $han]
	} else {
		var xipPage -1
	}
    	if {$xipPage != -1} {
    	    var	addr [handle segment $han]
    	} else {
    	    var addr [field $val HM_addr]
    	}
    	echo [format {address: %#x  size: %#x  prev: %#x  next: %#x}
    	      $addr [field $val HM_size]
    	      [field $val HM_prev] [field $val HM_next]]
    	var owner [field $val HM_owner]
    	echo -n [format {owner: %#x (} $owner]
    	if {$owner != 0} {
    	    echo -n [owner-name $owner]
	} else {
	    echo -n FREE
	}
    	echo -n {)  }
    	var flags [field $val HM_flags]
	if {[field $flags HF_FIXED]} {echo -n {Fixed }}
	if {[field $flags HF_SHARABLE]} {echo -n {Sharable }}
	if {[field $flags HF_DISCARDABLE]} {echo -n {Discardable }}
	if {[field $flags HF_SWAPABLE]} {echo -n {Swapable }}
	if {[field $flags HF_LMEM]} {
	    echo -n [format {LMem %s } [type emap
					   [value fetch ^h$num:LMBH_lmemType] 
					    [if {[not-1x-branch]}
						{sym find type LMemType}
						{sym find type LMemTypes}]]]
	}
	if {[field $val HM_addr] == 0} {
	    if {[field $flags HF_DISCARDED]} {
		echo -n {Discarded }
	    } elif {[field $flags HF_SWAPPED]} {
		echo -n {Swapped }
	    }
	} else  {
	    if {[field $flags HF_DISCARDED]} {
		echo -n {Discarded?! }
	    } elif {[field $flags HF_SWAPPED]} {
		echo -n {Swapped?! }
	    }
	}


	if {[field $flags HF_DEBUG]} {echo -n {Debugged }}
    	echo
    	var lc [field $val HM_lockCount]
    	if {$lc != 1} {var lsuff s}

    	echo [format {Locked %d time%s  Last Use: %xh  OtherInfo: %xh}
    	      $lc $lsuff [field $val HM_usageValue]
    	      [field $val HM_otherInfo]]


	if {$xipPage != -1} {
		global	curXIPPage

		echo -n  [format {XIP resource (page %d) currently } $xipPage]
		if {$xipPage != $curXIPPage} {
			echo -n {not }
    	    	}
    	    	echo {mapped in.}
	}
    }
}]

##############################################################################
#				_tmem_catch
##############################################################################
#
# SYNOPSIS:	handling routine for a breakpoint at FarDebugMemory to tell you
#   	    	everything that's hapenning in the heap code
# PASS:		nothing
# CALLED BY:	breakpoint at FarDebugMemory
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
    echo -n $func of [format %04xh $hid]
    [case $func in
    	realloc {
	    echo [format {:\t address = %04xh, size = %04xh}
	    	    [value fetch kdata:bx.HM_addr]
		    [value fetch kdata:bx.HM_size]]
    	}
	{discard swapout free} {
	    echo
	}
    	swapin {
	    echo [format {:\t data address = %04xh}
	    	     [value fetch kdata:bx.HM_addr]]
    	}
	move {
    	    echo [format {:\t\t new address = %04xh} [read-reg es]]
    	}
	modify {
    	    var flags [value fetch kdata:bx.HM_flags]
    	    echo -n [format {:\t flags now = }]
	    if {[field $flags HF_SHARABLE]} {echo -n s} else {echo -n { }}
	    if {[field $flags HF_DISCARDABLE]} {echo -n D} else {echo -n { }}
	    if {[field $flags HF_SWAPABLE]} {echo -n S} else {echo -n { }}
	    if {[field $flags HF_LMEM]} {echo -n L} else {echo -n { }}
    	    echo
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
# SYNOPSIS:	Trace memory usage. Catches all calls to FarDebugMemory 
#               and prints out their parameters in some meaningful fashion
# PASS:		nothing
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	breakpoint is set at FarDebugMemory
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/24/90		Initial Revision
#
##############################################################################
[defcmd tmem {} {system.misc profile}
{Usage:
    tmem

Examples:
    "tmem"  	turn on memory tracing.

Synopsis:
    Trace memory usage.

Notes:
    * Tmem catches calls to FarDebugMemory, printing out the parameters
      passed (move, free, realloc, discard, swapout, swapin, modify).

}
{
    return [brk aset FarDebugMemory _tmem_catch]
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
[defcommand handles {args} {system.heap patient.handle}
{Usage:
    handles [<flags>] [<patient>]

Examples:
    "handles"
    "handles -f"
    "handles ui"
    "handles -mL 1000"	shows all memory handles for resources > 1000 bytes
Synopsis:
    Print all handles in-use.

Notes:
    * The flags argument is a collection of flags, beginning with '-',
      from the following set:

    	s  	print summary only
    	e   	events only
    	p	don't print prevPtr and nextPtr.
        f	fast print-out - this doesn't try to figure out the block type
    	r   	reverse, i.e. starts at the end of the handle table.
    	u   	print only those handles that are in-use.
    	m   	print mem handles only
    	L <num> print only those handles that are greater than num bytes large
    * The patient argument is a patient whose blocks are to be selectively
      printed (either a name or a core-block's handle ID). The default is to
      print all the blocks on the heap.

    * The following columns can appear in a listing:
    	HANDLE	The handle of the block
    	ADDR	The segment address of the block
    	SIZE	Size of the block in bytes
    	PREV	The previous block handle (appears with the p flag)
    	NEXT	The next block handle (appears with the p flag)
    	FLAGS	The following letters appears in the FLAGS column:
        	    s	  sharable
        	    S	  swapable
        	    D	  discardable
        	    L	  contains local memory heap
        	    d	  discarded (by LMem module: discarded blocks 
        	    	  don't appear here)
        	    a	  attached (notice given to swat whenever state changes)
    	LOCK	Number of times the block is locked or n/a if FIXED.
    	OWNER	The process which owns the block
    	IDLE	The time since the block has been accessed in minutes:seconds
    	OINFO	The otherInfo field of the handle (block type dependent)
    	TYPE	Type of the block, for example:
    	    	    R#1 (dgroup)    resource number one

See also:
    lhwalk, phandle, hwalk, hgwalk, handsum.
}
{
    var owner nil ptrs 1 fast 0 summaryOnly 0 eventsOnly 0 reverse 0 usedonly 0
    global geos-release

    if {${geos-release} < 2} {
    	return [old_handles $args]
    }

    if {[length $args] > 0 && [string m [index $args 0] -*]} {
	#
	# Examine the flags word for things we know and set vars
	# accordingly.
	#
	foreach i [explode [range [index $args 0] 1 end chars]] {
	    [case $i in
		p {var ptrs 0}
		s {var summaryOnly 1}
		e {var eventsOnly 1}
		f {var fast 1}
		r {var reverse 1}
	    	u {var usedonly 1}
    	    	m {var memonly 1}
    	    	L { 
    	    	    var minsize [index $args 1]
    	    	    var args [range $args 1 end] 
    	    	}]
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
    # Print out a summary
    #
    var totalHandles [expr ([value fetch loaderVars.KLV_lastHandle]-[value
    	    	    	    	    fetch loaderVars.KLV_handleTableStart])/16]
    var freeHandles [value fetch loaderVars.KLV_handleFreeCount]
    echo [format {There are %d handles total, %d used and %d free}
    	    	$totalHandles [expr $totalHandles-$freeHandles] $freeHandles]
    echo
    if {$summaryOnly} { return }

    #
    # Print out the proper banner
    #
    if {$eventsOnly} {
	    echo {HANDLE  OWNER     DATA}
	    echo {---------------------------------------------------------------------}
    } else {
	[case $ptrs$fast in
	    11 {
		echo {HANDLE  ADDR   SIZE  PREV  NEXT  FLAGS   LOCK  OWNER     IDLE OINFO}
		echo {---------------------------------------------------------------------}
	    }
	    10 {
		echo {HANDLE  ADDR   SIZE  PREV  NEXT  FLAGS   LOCK  OWNER     IDLE OINFO  TYPE}
		echo {------------------------------------------------------------------------------}
	    }
	    01 {
		echo {HANDLE  ADDR   SIZE FLAGS   LOCK  OWNER     IDLE OINFO}
		echo {---------------------------------------------------------}
	    }
	    00 {
		echo {HANDLE  ADDR   SIZE FLAGS   LOCK  OWNER     IDLE OINFO TYPE}
		echo {------------------------------------------------------------------}
	    }]
    }

    #
    # Set up initial conditions.
    #
    [var start [value fetch loaderVars.KLV_handleTableStart] totsz 0 free 0
    	    end [value fetch loaderVars.KLV_lastHandle] tothan 0]
    var hs [type size [sym find type HandleMem]]
    if {$reverse} {
    	var s $start
    	var start [expr $end-$hs]
	var end [expr $s-$hs]
	var hs [expr -$hs]
    }
    var nextStruct [value fetch kdata:$start HandleMem]

    if {$eventsOnly} {
    	var totalEvents 0
	for {var cur $start} {$cur != $end} {var cur [expr $cur+$hs]} {
    	    var han_type [value fetch kdata:$cur.HG_type]
	    if {($han_type == 0xf8) || ($han_type == 0xf9)} {
    	    	var val [value fetch kdata:$cur HandleEvent]
    	    	var own [field $val HE_next]
    	    	var ownhan [handle lookup $own]
    	    	if {[handle ismem $ownhan]} {
    	    	    var ownstr [format {%-10s}
    	    	    	    	    [patient name [handle patient $ownhan]]]
    	    	    var continue [expr {[null $owner] || $own == $owner}]
    	    	} else {
    	    	    var ownstr {LINKED    }
    	    	    var continue 1
    	    	}
	    	if {$continue} {
    	    	    var totalEvents [expr $totalEvents+1]
		    echo -n [format {%04xh   %s} $cur $ownstr]
		    #
		    # See if the OD is actually a far pointer, which means
		    # this is a classed event rather than a regular event.
		    #
		    var seg [value fetch kdata:$cur.HE_OD.segment]
		    var odhan [handle lookup $seg]
		    var off [value fetch kdata:$cur.HE_OD.offset]
		    [if {[isclassptr $seg:$off] || (($seg | $off) == 0) || [null $odhan]}
    	    	    {
			if {($seg | $off) == 0} {
			    var symb [symbol find var MetaClass]
			} else {
			    var symb [symbol faddr var $seg:$off]
			    if {[null $symb]} {
			    	var symb [symbol find var MetaClass]
    	    	    	    }
			}
			echo -n {CLASSED, }
			print-event-method $val [symbol fullname $symb]
			echo [format {, %s} [symbol name $symb]]
		    } else {
			var caller [expr (([field $val HE_next]>>16)&0xf)<<4]
			var caller [expr $caller|([field
					$val HE_callingThreadHigh]<<8)]
			if {$caller == 0} {
			    echo -n {SEND, }
			} else {
			    var chan [handle lookup $caller]
			    if {[null $chan]} {
				echo -n [format {CALL (%04xh), } $caller]
			    } else {
				echo -n [format {CALL (%s), } [patient name 
					    [handle patient $chan]]]
			    }
			}
    	    	    	echo -n [format {^l%04xh:%04xh, } $seg $off]
    	    	    	if {$seg == 0} {
			    print-event-method $val MetaClass
    	    	    	    #echo [map-method [field $val HE_method] MetaClass]
    	    	    	} else {
			    var h [handle lookup $seg]
			    var type [format {%05x} [expr [handle state $h]&0xf8000]]
			    [case $type in
			    	08000 {
				    #
				    #   Memory handle - normal lmem object
				    #
				    if {$h  == [handle owner $h]} {
				    	var thread [value fetch kdata:[handle id $h].HM_otherInfo]
			     	    	var ss [value fetch kdata:$thread.HT_saveSS]
				    	var s [sym faddr var *$ss:TPD_classPointer]
				    	var sn [sym fullname $s]
				    	echo [map-method [field $val HE_method] $sn], [sym name $s]
					
				    } else {
					print-event-method $val ^l$seg:$off
				    	#echo -n [map-method [field $val HE_method] ^l$seg:$off]
					echo -n {, }
				    	echo [pclass ^l$seg:$off]
				    }
				}
				e0000 {
				    #
				    # Thread handle
				    #
			     	    var ss [value fetch kdata:$seg.HT_saveSS]
				    var s [sym faddr var *$ss:TPD_classPointer]
				    var sn [sym fullname $s]
				    echo [map-method [field $val HE_method] $sn], [sym name $s]
			    	}
				40000 {
				    #
				    # Queue handle
				    #
				     echo {QUEUE}
				}
				default {
				    echo {BAD ADDR}
				}    
			    ]	
		    	}
    	    	    }]
		}
	    }
    	}
    	echo
    	echo [format {Total events: %d} $totalEvents]
    	echo
    } else {
	var skipped 0 
	for {var cur $start} {$cur != $end} {var cur $next} {
	    var val $nextStruct

	    var next [expr $cur+$hs]
	    [var nextStruct [value fetch kdata:$next HandleMem]
		 addr [field $val HM_addr]
		 oi [field $val HM_otherInfo]
		 own [field $val HM_owner]]

	    if {[null $owner] || $own == $owner} {
		[var size [expr [field $val HM_size]<<4]
		     flags [field $val HM_flags]]

		var tothan [expr $tothan+1]
		var han_type [expr $addr>>8]
    	    	if {![null $minsize] && $minsize > $size} {
    	    	    continue
    	    	}
		if {$addr >= 0xf000 || ($addr == 0 && $own == 0)} {
    	    	    if {$usedonly && $han_type == 0xf3} {
		    	continue
    	    	    }
    	    	    if {![null $memonly]} {
    	    	    	continue
    	    	    }
		    echo -n [format {%04xh } $cur]
		    #XXX: give info for the handle...
		    [case [format %x $han_type] in
		     00 {echo FREE}
		     f2 {
			 echo [format {HEAP RESERVATION of %dk for %04xh (%s)}
			       [value fetch kdata:$cur.HR_size]
			       $own
			       [owner-name $own]]
		     }
		     f3 {echo FREE}
		     f4 {
		     	echo -n [format {EVENT QUEUE %s, } [owner-name $own]]
			var t [value fetch kdata:$cur.HQ_thread]
			if {$t} {
			    echo -n thread = [threadname $t],
    	    	    	} else {
			    echo -n no thread,
			}
			var n [value fetch kdata:$cur.HQ_semaphore.Sem_value]
			if {$n <= 0} {
			    echo { no events}
    	    	    	} else {
			    echo [format { %d %s} $n [pluralize event $n]]
    	    	    	}
		     }
		     f5 {echo DISK}
		     f6 {
		     	var t [penum geos::TimerType [value fetch kdata:$cur.HTI_type]]
		     	echo -n [format {%s } $t]
			[case $t in
			    *EVENT* {
			    	[print-obj-and-method [value fetch kdata:$cur.HTI_OD.handle]
				 [value fetch kdata:$cur.HTI_OD.chunk] {}
				 [value fetch kdata:$cur.HTI_method]]
    	    	    	    }
			    *ROUTINE* {
			    	var seg [value fetch kdata:$cur.HTI_OD.segment]
				var off [value fetch kdata:$cur.HTI_OD.offset]
			    	var s [symbol faddr proc $seg:$off]
				if {[null $s]} {
				    echo [format {%04xh:%04xh} $seg $off]
				} elif {[index [symbol get $s] 0] != $off} {
				    echo [symbol fullname $s]+[expr $off-[index [symbol get $s] 0]]
    	    	    	    	} else {
				    echo [symbol fullname $s]
    	    	    	    	}
    	    	    	    }
			    *SEMAPHORE* {
			    	var seg [value fetch kdata:$cur.HTI_OD.segment]
				var off [expr [value fetch kdata:$cur.HTI_OD.offset]-2]
			    	var s [symbol faddr var $seg:$off]
				if {[null $s]} {
				    echo [format {%04xh:%04xh} $seg $off]
				} elif {[index [symbol get $s] 0] != $off} {
				    echo [symbol fullname $s]+[expr $off-[index [symbol get $s] 0]]
    	    	    	    	} else {
				    echo [symbol fullname $s]
    	    	    	    	}
    	    	    	    }
			    *SLEEP* {
			    	if {[value fetch kdata:$cur.HTI_method]} {
				    echo [threadname [value fetch kdata:$cur.HTI_method]]
    	    	    	    	} else {
				    echo awake
    	    	    	    	}
			    }
    	    	    	]
    	    	     }
		     f7 {
		     	[for {var e $cur}
			     {[value fetch kdata:$e.HG_type] == 0xf7}
			     {var e [value fetch kdata:$e.HED_next]}
    	    	    	{}]
		        echo [format {EVENT DATA for %04xh} $e]
	    	     }
		     f8 {
		     	echo -n {EVENT w/STACK }
			[print-obj-and-method 
			 [value fetch kdata:$cur.HE_OD.handle]
			 [value fetch kdata:$cur.HE_OD.chunk]
			 {}
			 [value fetch kdata:$cur.HE_method]]
    	    	     }
		     f9 {
		     	echo -n {EVENT }
			[print-obj-and-method 
			 [value fetch kdata:$cur.HE_OD.handle]
			 [value fetch kdata:$cur.HE_OD.chunk]
			 {}
			 [value fetch kdata:$cur.HE_method]]
		     }
		     fa {
		     	echo [format {SAVED BLOCK %04xh for %04xh (%s)}
			      [value fetch kdata:$cur.HSB_handle]
			      [value fetch kdata:$cur.HSB_owner]
			      [owner-name [value fetch kdata:$cur.HSB_owner]]]
    	    	     }
		     fb {
		     	if {[value fetch kdata:$cur.HS_moduleLock.TL_owner] == 0xffff} {
		            echo [format {SEMAPHORE owned by %04xh (%s), value = %d}
				  [value fetch kdata:$cur.HS_owner]
				  [owner-name [value fetch kdata:$cur.HS_owner]]
				  [value fetch kdata:$cur.HS_moduleLock.TL_sem.Sem_value]]
    	    	    	} else {
			    echo [format {THREAD LOCK owned by %04xh (%s), grabbed by %04xh (%s)}
				  [value fetch kdata:$cur.HS_owner]
				  [owner-name [value fetch kdata:$cur.HS_owner]]
				  [value fetch kdata:$cur.HS_moduleLock.TL_owner]
				  [threadname [value fetch kdata:$cur.HS_moduleLock.TL_owner]]]
    	    	    	}
    	    	     }
		     fc {
    	    	    	if {[value fetch kdata:$cur.HVM_execThread]} {
			    echo [format {VM file = %04xh, header = ^h%04xh, execThread = %04xh (%s)}
				    [value fetch kdata:$cur.HVM_fileHandle]
				    [value fetch kdata:$cur.HVM_headerHandle]
				    [value fetch kdata:$cur.HVM_execThread]
				    [threadname [value fetch kdata:$cur.HVM_execThread]]]
		    	} else {
			    echo [format {VM file = %04xh, header = ^h%04xh}
				    [value fetch kdata:$cur.HVM_fileHandle]
				    [value fetch kdata:$cur.HVM_headerHandle]]
    	    	    	}
    	    	     }
		     fd {
		     	echo [format {FILE sfn = %d, owner = %04xh (%s)}
			    	[value fetch kdata:$cur.HF_sfn]
				[value fetch kdata:$cur.HF_owner]
				[owner-name [value fetch kdata:$cur.HF_owner]]]
    	    	     }
		     fe {
		     	echo THREAD [threadname $cur]
    	    	     }
		     ff {echo GSEG}
		     default {
			echo Signature: [format %xh [expr $addr>>8]]
		     }]
		} else {
		    if {$addr == 0 && [field $flags HF_SWAPPED]} {
			var sstrat [value fetch kdata:[field $val HM_prev].SD_strategy]
			var sdSym [symbol faddr func [expr $sstrat>>16]:[expr $sstrat&0xffff]]
			if {![null $sdSym]} {
			    var pname [patient name [symbol patient $sdSym]]
			} else {
			    var pname swapped
			}
			#XXX: -7 is so it all fits, even though swap driver names
			# can be 8 chars...
			echo -n [format {%04xh %-7s%5d } $cur $pname $size]
			var swapped 1
		    } else {
			echo -n [format {%04xh %04xh%7d } $cur $addr $size]
			var swapped 0
		    }
		    if {$ptrs} {
			if {$swapped} {
			    echo -n [format {page %6d  } [field $val HM_next]]
			} else {
			    echo -n [format {%04xh %04xh  } [field $val HM_prev]
				     [field $val HM_next]]
			}
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
	    } else {
		var skipped [expr $skipped+1]
		if {$skipped == 10} {
		    if {![null [info command wmove]]} {
			echo -n [format {%04xh} $cur]
			flush-output
			wmove -5 +0
			var skipped 0
		    }
		}
	    }
	}
	if {[null $owner]} {
	    echo [format {\nTotal bytes free: %d} $free]
	    echo [format {Total bytes allocated: %d} [expr $totsz-$free]]
	} else {
	    echo [format {\nTotal bytes allocated: %d, total handles: %d}
			    $totsz $tothan]
        }
    }
}]


[defsubr print-event-method {val sn}
{
	var msg [map-method [field $val HE_method] $sn]
	if { ![string compare $msg MSG_META_NOTIFY_WITH_DATA_BLOCK] &&
			 ([field $val HE_cx] == 0)
	} {
		echo -n [penum GeoWorksNotificationType 
			 [field $val HE_dx]]
		echo -n [format {(^h%04xh)} [field $val HE_bp]]
	} elif { ![string compare $msg MSG_META_NOTIFY] &&
			 ([field $val HE_cx] == 0)
	} {
		echo -n [penum GeoWorksNotificationType 
			 [field $val HE_dx]]
		echo -n [format {(%04xh)} [field $val HE_bp]]
	} else {
		echo -n $msg
		echo -n [format { (%04xh %04XH %04xh)}
			[field $val HE_cx]
			[field $val HE_dx]
			[field $val HE_bp]]
	}
}]

##############################################################################
#				check-heap
##############################################################################
#
# SYNOPSIS:	Error-check the heap.
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
#	ardeb	1/ 8/93		Initial Revision
#
##############################################################################
[defsubr check-heap {}
{
    if {[uplevel 0 {var geos-release}] >= 2} {
    	var cur [value fetch loaderVars.KLV_handleBottomBlock]
    } else {
    	var cur [value fetch geos::handleBottomBlock]
    }
    
    var end $cur
    
    do {
    	if {[value fetch kdata:$cur.HM_addr] == 0} {
	    echo [format {Handle %04xh has address 0} $cur]
    	}
	var cur [value fetch kdata:$cur.HM_next]
    } while {$cur != $end}
}]

##############################################################################
#				handsum
##############################################################################
#
# SYNOPSIS:	Summarize the purpose to which all handles are being put.
# PASS:		nothing
# CALLED BY:	user
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#   	Counts are stored in a table indexed by owner handle ID. Each table
#   	entry is a list whose elements are:
#
#   	Category  	    Index
#   	resource    	    0
#   	non-resource mem    1
#	file	    	    2
#   	thread	    	    3
#   	event	    	    4
#   	queue	    	    5
#   	semaphore   	    6
#    	event data  	    7
#   	timer	    	    8
#   	saved block 	    9
#   	vm file	    	    10
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	1/ 8/93		Initial Revision
#
##############################################################################
[defcommand handsum {args} system.heap
{Usage:
    handsum

Examples:
    "handsum"	Summarize the use to which the handle table is being put.

Synopsis:
    This command analyzes the handle table and prints out a list of the
    number of handles being used by each geode, and for what purpose.

Notes:
    * The columns of the output are labeled somewhat obscurely, owing to
      horizontal-space constraints. The headings, and their meanings are:
      	Res 	Resource handles (i.e. handles for data stored
		in the geode's executable)
    	Mem 	Non-resource memory handles
    	File	Open files
    	Thds	Threads
	Evs 	Recorded events
	Qs  	Event queues
	Sems	Semaphores
	EDat	Data for recorded events
	Tim 	Timers
	SB  	Saved blocks (handles tracking memory/resource handles whose
		contents will go to an application's state file)
	VMF 	VM files

    * The "handles" command is good at printing out all the handles for a
      particular geode, but it's generally too verbose to use for the entire
      handle table. That's why this command exists.

    * It's a good idea to issue the command "dcache length 4096" before
      executing this command, as it ensures the entire handle table will end
      up in Swat's data cache, for quick access if you want to use the
      "handles" command immediately afterward.

See also:
    handles
}
{
    protect {
    	var t [table create]
	
	var hgt [symbol find type geos::HandleGen]
	var hs [type size $hgt]
	var start [value fetch loaderVars.KLV_handleTableStart]
	var end [value fetch loaderVars.KLV_lastHandle]
	var freeMem 0
	var queuedEvents 0
	var freeHandles 0
	var owners {}
	var feedbackInterval 25
	var feedback $feedbackInterval
	
	echo -n Tabulating data...
	flush-output

	for {var cur $start} {$cur < $end} {var cur [expr $cur+$hs]} {
	    # allow loop to only be interrupted at the beginning, otherwise
	    # swat would abort when cntl-c hit later in loop
	    if {[irq] != 0} {
		# cntl-c detected, turn interrupts back on and get outta here
		irq yes
		return
	    }
	    irq no

	    var feedback [expr $feedback-1]
	    if {$feedback == 0} {
	    	echo -n .
		flush-output
		var feedback $feedbackInterval
    	    }

    	    var h [value fetch kdata:$cur $hgt]
	    
	    var sig [field $h HG_type]
	    if {$sig == 0xf3} {
	    	# Free handle
		var freeHandles [expr $freeHandles+1]
	    	continue
    	    }
	    var owner [field $h HG_owner]
	    [case [format %2x $sig] in
	     f4 {
	     	# event queue
	     	var index 5
	     }
	     f6 {
	     	# timer
		var index 8
	     }
	     f7 {
	     	# event data
		# HED_next fields link back to event, so find event
		[for {var e [value fetch kdata:$cur.HED_next]}
		     {1}
		     {var e [value fetch kdata:$e.HED_next]}
    	    	{
		    var et [value fetch kdata:$e.HG_type]
		    if {$et == 0xf8 || $et == 0xf9} {
		    	break
    	    	    }
    	    	}]
		# for recorded events, owner is in HE_next field (high
		# 12 bits). For events awaiting delivery, HE_next points
		# to another event, or is 0. Rather than search for all
		# event queues to find on which one the event resides, we
		# just keep track the number of events awaiting delivery.
		var owner [expr [value fetch kdata:$e.HE_next]&0xfff0]
		var et [value fetch kdata:$owner.HG_type]
		if {$owner == 0 || $et == 0xf8 || $et == 0xf9} {
		    var queuedEvents [expr $queuedEvents+1]
		    continue
    	    	}
	     	var index 7
	     }
	     {f8 f9} {
	     	# event

		# for recorded events, owner is in HE_next field (high
		# 12 bits). For events awaiting delivery, HE_next points
		# to another event, or is 0. Rather than search for all
		# event queues to find on which one the event resides, we
		# just keep track the number of events awaiting delivery.
		var owner [expr [value fetch kdata:$cur.HE_next]&0xfff0]
		var et [value fetch kdata:$owner.HG_type]
		if {$owner == 0 || $et == 0xf8 || $et == 0xf9} {
		    var queuedEvents [expr $queuedEvents+1]
		    continue
    	    	}
    	    	var index 4
    	     }
	     fa {
	     	# saved block
    	    	var index 9
    	     }
	     fb {
	     	# semaphore
		var index 6
	     }
	     fc {
	     	# VM file
		# use owner of file handle...
		var owner [value fetch kdata:[value fetch kdata:$cur.HVM_fileHandle].HF_owner]
		var index 10
	     }
	     fd {
	     	# file
		var index 2
	     }
	     fe {
	     	# thread
		var index 3
	     }
	     default {
	    	# memory. maybe free space
		if {$owner == 0} {
		    var freeMem [expr $freeMem+1]
		    continue
    	    	}
		# not free space. see if it's resource or non-resource
		var oh [handle lookup $owner]
    	    	# assume non-resource
		var index 1
		if {![null $oh]} {
		    if {[handle isvm $oh]} {
		    	# use owner of file handle...clearly non-resource
			var owner [value fetch kdata:[value fetch kdata:$owner.HVM_fileHandle].HF_owner]
    	    	    } else {
			foreach r [patient resources [handle patient $oh]] {
			    if {[handle id $r] == $cur} {
				# is resource
				var index 0
				break
			    }
			}
    	    	    }
    	    	}
    	     }
    	    ]
	    var d [table lookup $t $owner]
	    if {[null $d]} {
	    	var d {0 0 0 0 0 0 0 0 0 0 0}
		var owners [concat [list $owner] $owners]
    	    }
	    aset d $index [expr [index $d $index]+1]
	    table enter $t $owner $d
    	}
	echo
    	#
	# now get names for all the owners.
	#
	var owners [sort [map o $owners {
	    var h [handle lookup $o]
	    if {![null $h]} {
	    	var p [patient name [handle patient $h]]
    	    } elif {$o == 32} {
	    	var p fontman
    	    } else {
	    	var p [format {^h%04xh} $o]
    	    }
	    list $p $o
    	}]]
	echo {Owner     Res  Mem  File  Thds  Evs  Qs  Sems  EDat  Tim  SB  VMF  | Total}
	echo {-------------------------------------------------------------------+------}
    	var totals {0 0 0 0 0 0 0 0 0 0 0}
    	foreach o $owners {
	    var d [table lookup $t [index $o 1]] tot 0
	    echo [eval
		  [concat
		   [list format
			 {%-9s %3s  %3s  %4s  %4s  %3s  %2s  %4s  %4s  %3s  %2s  %3s  | %5s}]
		   [index $o 0]
		   [map s $d {
		       var tot [expr $tot+$s]
		       if {$s != 0} {var s}
		   }]
		   $tot]]
    	    var totals [map {tot s} $totals $d {
	    	expr $tot+$s
    	    }]
    	}
	
	echo {-------------------------------------------------------------------+------}
    	var tot 0
	echo [eval
	      [concat
	       [list format
		     {%-9s %3s  %3s  %4s  %4s  %3s  %2s  %4s  %4s  %3s  %2s  %3s  | %5s}]
	       Total
	       [map s $totals {
		   var tot [expr $tot+$s]
		   if {$s != 0} {var s}
	       }]
	       $tot]]
	echo
	echo Handles for free memory: $freeMem
	echo Handles for queued events: $queuedEvents
	echo Free Handles: $freeHandles
    } {
    	if {![null $t]} {
    	    table destroy $t
    	}
	echo
    }
    irq yes
}]

##############################################################################
#				old_handles
##############################################################################
#
# SYNOPSIS:	1.2 version on handles
#
##############################################################################
[defcommand old_handles {args} obscure
{1.2 version of handles
}
{
    var owner nil ptrs 1 fast 0 summaryOnly 0

    if {[length $args] > 0 && [string m [index $args 0] -*]} {
	#
	# Examine the flags word for things we know and set vars
	# accordingly.
	#
	foreach i [explode [range [index $args 0] 1 end chars]] {
	    [case $i in
		p {var ptrs 0}
		s {var summaryOnly 1}
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
	    echo {HANDLE  ADDR   SIZE  PREV  NEXT  FLAGS   LOCK  OWNER     IDLE OINFO}
	    echo {---------------------------------------------------------------------}
	}
    	10 {
	    echo {HANDLE  ADDR   SIZE  PREV  NEXT  FLAGS   LOCK  OWNER     IDLE OINFO  TYPE}
	    echo {------------------------------------------------------------------------------}
    	}
	01 {
	    echo {HANDLE  ADDR   SIZE FLAGS   LOCK  OWNER     IDLE OINFO}
	    echo {---------------------------------------------------------}
    	}
	00 {
	    echo {HANDLE  ADDR   SIZE FLAGS   LOCK  OWNER     IDLE OINFO TYPE}
	    echo {------------------------------------------------------------------}
    	}]

    #
    # Set up initial conditions.
    #
    [var start [sym addr [sym find var HandleTable]] totsz 0 free 0
	     end [value fetch lastHandle]]
    var nextStruct [value fetch kdata:$start HandleMem]
    var hs [type size [sym find type HandleMem]]

    for {var cur $start} {$cur != $end} {var cur $next} {
    	var val $nextStruct

	var next [expr $cur+$hs]
	[var nextStruct [value fetch kdata:$next HandleMem]
	     addr [field $val HM_addr]
	     oi [field $val HM_otherInfo]
	     own [field $val HM_owner]]

	if {[null $owner] || $own == $owner} {
	    [var size [expr [field $val HM_size]<<4]
		 flags [field $val HM_flags]]

    	    if {$addr >= 0xf000 || ($addr == 0 && $own == 0)} {
    	    	echo -n [format {%04xh } $cur]
    	    	#XXX: give info for the handle...
	    	[case [format %x [expr $addr>>8]] in
    	    	 00 {echo FREE}
    	    	 f3 {echo FREE}
    	      	 f4 {echo EVENT QUEUE}
    	    	 f5 {echo DISK}
    	    	 f6 {echo TIMER}
    	    	 f7 {echo EVENT DATA}
		 f8 {echo EVENT w/STACK}
		 f9 {echo EVENT}
		 fa {echo SAVED BLOCK}
		 fb {echo SEMAPHORE}
    	    	 fc {echo VM}
		 fd {echo FILE}
		 fe {echo THREAD}
		 ff {echo GSEG}
		 default {
		    echo Signature: [format %xh [expr $addr>>8]]
		 }]
    	    } else {
    	    	if {$addr == 0 && [field $flags HF_SWAPPED]} {
		    var sstrat [value fetch kdata:[field $val HM_prev].SD_strategy]
		    var sdSym [symbol faddr func [expr $sstrat>>16]:[expr $sstrat&0xffff]]
		    if {![null $sdSym]} {
			var pname [patient name [symbol patient $sdSym]]
		    } else {
		    	var pname swapped
		    }
    	    	    #XXX: -7 is so it all fits, even though swap driver names
		    # can be 8 chars...
    	    	    echo -n [format {%04xh %-7s%5d } $cur $pname $size]
		    var swapped 1
		} else {
		    echo -n [format {%04xh %04xh%7d } $cur $addr $size]
		    var swapped 0
    	    	}
		if {$ptrs} {
    	    	    if {$swapped} {
		    	echo -n [format {page %6d  } [field $val HM_next]]
    	    	    } else {
		        echo -n [format {%04xh %04xh  } [field $val HM_prev]
			         [field $val HM_next]]
    	    	    }
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

##############################################################################
#				hgwalk
##############################################################################
#
# SYNOPSIS:	Print out the status of all blocks on the heap with respect
#		to the geode that owns them
# PASS:		flags detailed below
# CALLED BY:	the user
# RETURN:	nothing
# SIDE EFFECTS:	lots of stuff is printed
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	tony	6/24/90		Initial Revision
#
##############################################################################
[defcmd hgwalk {args} system.heap
{Usage:
    hgwalk

Examples:
    "hgwalk"	    print statistics on all geodes

Synopsis:
    Print out all geodes and their memory usage.

Notes:

}
{
    var owner nil
    var t [table create]
    protect {
    	var objlibs {}
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
    	if {[uplevel 0 {var geos-release}] >= 2} {
	    [var start [value fetch loaderVars.KLV_handleBottomBlock] first 1
	    	errFlag 0 free 0]
     	} else {
	    [var start [value fetch geos::handleBottomBlock] first 1
	    	errFlag 0 free 0]
    	}
	var nextStruct [value fetch kdata:$start HandleMem] used 0
	var val [value fetch kdata:[field $nextStruct HM_prev] HandleMem]
	var lmemused 0 lmemfree 0
	var kernel [handle id [index [patient resources [patient find geos]] 0]]

    #var foo 10
	for {var cur $start} {($cur != $start) || $first} {var cur $next} {
	    echo -n {.}
	    flush-output
    #echo -n [format {Working on %04xh, } $cur]
	    var first 0
	    var val $nextStruct

	    var next [field $val HM_next] prev [field $val HM_prev]
	    [var nextStruct [value fetch kdata:$next HandleMem]
		 addr [field $val HM_addr]
		 oi [field $val HM_otherInfo]
		 own [field $val HM_owner]]

    #var foo [expr $foo-1]
    #if {$foo == 0} {var next $start}
	    if {[null $owner] || $own == $owner} {
		[var size [expr [field $val HM_size]<<4]
		     flags [field $val HM_flags]
		     locks [field $val HM_lockCount]]
    #echo -n [format {size = %d, } $size]
		var gtotal [expr $gtotal+$size]
		if {$own == 0} {
    #echo [format {FREE}]
		    var free [expr $free+$size]
    	    	} elif {[field $val HM_otherInfo] == 0xfcb &&
		        $locks == 1 &&
			$own == $kernel} {
		    # fake block allocated by MemExtendHeap
		    var gtotal [expr $gtotal-$size]
		} else {
		    var oh [handle lookup $own]
		    if {![null $oh] && [handle isvm $oh]} {
    	    	    	var own [value fetch kdata:[value fetch geos::dgroup:$own.HVM_fileHandle].HF_owner]
		    }
		    var entry [table lookup $t $own]
		    if {[null $entry]} {
    #echo -n [format {new geode "%s", } $own]
			var entry {0 0 0 0 0 0 0 0}
			var glist [concat $glist $own]
		    }
                    if {[field $flags HF_FIXED] || $locks == -1} {
    #echo [format {adding to fixed}]
			var entry [listadd $entry 0 1]
			var entry [listadd $entry 1 $size]
                        # Also add free memory in fixed LMem (malloc!)
                        if {[field $flags HF_LMEM]} {
                            var lfree [value fetch $addr:LMBH_totalFree]
                            var lmemused [expr $lmemused+[value fetch $addr:LMBH_blockSize]-$lfree]
                            var lmemfree [expr $lmemfree+$lfree]
                        }
                    } elif {[field $flags HF_DISCARDABLE]} {
    #echo [format {adding to discardable}]
			var entry [listadd $entry 2 1]
			var entry [listadd $entry 3 $size]
                    } elif {[field $flags HF_LMEM]} {
			var lfree [value fetch $addr:LMBH_totalFree]
			var lmemused [expr $lmemused+[value fetch $addr:LMBH_blockSize]-$lfree]
			var lmemfree [expr $lmemfree+$lfree]
			if {[value fetch $addr:LMBH_lmemType]==2} {
    #echo [format {adding to objblock}]
			    var entry [listadd $entry 4 1]
			    var entry [listadd $entry 5 $size]
                        } else {
    #echo [format {adding to other}]
			    var entry [listadd $entry 6 1]
			    var entry [listadd $entry 7 $size]
			}
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

	var total {0 0 0 0 0 0 0 0 0 0}

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
	echo [format {Free lmem: %d (%2.2f%% of used lmem, %2.2f%% of total)}
		$lmemfree [expr $lmemfree/$lmemused*100 f]
		[expr $lmemfree/$gtotal*100 f]]
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
#				heapspace
##############################################################################
#
# SYNOPSIS:	Print out "heapspace" used by application
# PASS:		nothing
# CALLED BY:	the user
# RETURN:	nothing
# SIDE EFFECTS:	lots of stuff is printed
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	doug	3/17/93		Initial Revision
#	chris	4/ 6/93		Finished up to make work as advertised
#
##############################################################################
[defcmd heapspace {args} system.heap
{Usage:
    heapspace <geode>		   print out "heapspace" being used by app
    heapspace total		   print out total heapspace being used
    heapspace syslib		   print out total of heapspace being used by
					system libraries

Examples:
    "heapspace geomanager"	    print out "heapspace" value for geomanager
    "heapspace total"	  	    print out total space being used
    "heapspace syslib"	  	    print out space being used by system libs

Synopsis:
    Print out "heapspace" value for application, as calculated from current
    heap usage.  Run "heapspace" on your application at different times, after
    accessing all menus & dialogs, & generally "stressing" it, to see what
    value for "heapspace" should be put in its .gp file.  The value printed
    is roughly the non-discardable heap usage by the app & any transient
    libraries that it depends on.

Notes:
    '*' in the Tabulating data stream represent XIP'd blocks detected.  
    '*' before a Geode name mean the Geode is XIP'd.

    XIP'd blocks are any blocks:
           KLV_mapPageAddr <= addr < KLV_mapPageAddr+800h
               or
           KLV_heapEnd <= addr < 0xf000
    This may not catch everything on every device.
}
{
  if {[length $args] == 0} {
    echo {Usage:  heapspace <geode>	- heapspace for app}
    echo {        heapspace total	- total heapspace available}
    echo {        heapspace syslib	- heapspace for sys libraries}
  } else {
    var owner nil
    var t [table create]
    protect {
	var glist {}
	var free 0 discardable 0 gtotal 0

	if {([length $args] > 0) &&
        	([string compare  [index $args 0] total]) &&
        	([string compare  [index $args 0] syslib])
	} {
	    #
	    # For geode heapspace determination, figure out which geodes we
	    # have an interest in (i.e. which non-system, non-app libraries
	    # we depend on, in addition to our own geode).
	    #
	    var h [handle lookup [index $args 0]]
	    if {![null $h] && $h != 0} {
		var owner [handle id $h]
	    } else {
		var owner [handle id [index
			[patient resources [patient find [index $args 0]]] 0]]
	    }

	    if {[isapp $owner]} {
	        #
	        # Get a list of the libraries needed by the geode, if any.
		# Also, we'll count ourselves here, to make comparisons simple
		# later.  Also, we'll ignore libraries that are always
		# guaranteed to be in.
	        #
	        var objlibs $owner
	        var numLibs [value fetch ^h$owner.GH_libCount]
	        var libOffset [value fetch ^h$owner.GH_libOffset]
	        for {var cur 0} {($cur < $numLibs)} {var cur [expr $cur+1]} {
		    var libr [value fetch ^h$owner:$libOffset+$cur+$cur [type word]]
		    #
		    # Include if it is not a system geode, and not an app
		    #
		    if {![issysgeode $libr] && ![isapp $libr]} {
		        var objlibs [concat $objlibs $libr]
		    }
	        }
	    }

	}
	if {[length $args] > 0} {
	    #
	    # OK.  Now, walk the heap, & sum up Fixed, ObjBlock, & other memory
	    # usage by geode.  Also get a total for discardable space & free
	    # space.
 	    #	
	    # But first -- go through the entire handle table & make sure
	    # that swat is up-to-date on all the handles, as "handle all" only
	    # reports those swat knows about.
	    #
#	    handle-update
	    echo -n {Tabulating data}
	    var XIPmapPageAddr [field [value fetch kdata::loaderVars] KLV_mapPageAddr]
	    var XIPheapEnd [field [value fetch kdata::loaderVars] KLV_heapEnd]
            var start [value fetch loaderVars.KLV_handleTableStart]
	    var end [value fetch loaderVars.KLV_lastHandle]
	    var hs [type size [sym find type HandleMem]]
	    for {var i $start} {$i != $end} {var i [expr $i+$hs]} {
		var handle [handle lookup $i]
		if {[null $handle]} {
		    dospinner
		    #echo Event handle: $i
		} else {
		    var val [value fetch kdata:[handle id $handle] HandleMem]
		    var addr [field $val HM_addr]
		    var type [expr $addr/0x100]
		    if {($i>100) && ($addr < 0xf000)} {
			var own [owninggeode [field $val HM_owner]]
			var flags [field $val HM_flags]
			var locks [field $val HM_lockCount]
			var size [expr [field $val HM_size]<<4]
#			if {$size >= 10000h} {
#			    echo
#			    [echo -n check:]
#			    [echo [format %04xh [handle id $handle]]]
#			}
			var gtotal [expr $gtotal+$size]
			if {$own == 0} {
			    dospinner
			    var free [expr $free+$size]
			    #echo -n [format {U%x } [handle id $handle]]
			    #[echo $size]
			} elif {$size >= 65536} {
			    # fake block allocated by MemExtendHeap
			    var gtotal [expr $gtotal-$size]
			} elif {(($addr >= $XIPheapEnd) && ($addr < 0xf000))} {
			    echo -n *
			    #echo -n [format {X%x } [handle id $handle]]
			    #xip'd block
			} elif {(($XIPmapPageAddr != 0) && ($addr >= $XIPmapPageAddr)) && ($addr < [expr {$XIPmapPageAddr+800h}])} {
			    echo -n *
			    #echo -n [format {X%x } [handle id $handle]]
			    # xip'd block
			} elif {![field $flags HF_DISCARDED]} {
			    var oh [handle lookup [field $val HM_owner]]
			    if {![null $oh]} {
				var ohval [value fetch kdata:[handle id $oh] HandleMem]
				var ohaddr [field $ohval HM_addr]
				var ohtype [expr $ohaddr/0x100]
				if {$ohtype==0xfc} {
				    var vmfound 1
				} else {
				    var vmfound 0
				}
			    } else {
				var vmfound 0
			    }
			    var entry [table lookup $t $own]
			    if {[null $entry]} {
#				var entry {0 0 0 0 0 0 0}
#		Perhaps we use this if we count reserved heapspace, someday

				var entry {0 0 0 0 0 0}
				var glist [concat $glist $own]
			    }
			    if {([field $flags HF_FIXED])||($locks==-1)} {
				echo -n F
				#echo -n [format {F%x } [handle id $handle]]
				var entry [listadd $entry 0 $size]
			    } elif {[field $flags HF_SWAPPED]} {
				#echo -n [format {S%x } [handle id $handle]]
				var entry [listadd $entry 3 $size]
			    } elif {[field $flags HF_DISCARDABLE]} {
				if {($vmfound == 1) && ($locks != 0)} {
				    echo -n V
				    #echo -n [format {V%x } [handle id $handle]]
				    var entry [listadd $entry 4 $size]
				} elif {$locks != 0} {
				    echo -n L
				    #echo -n [format {L%x } [handle id $handle]]
				    var entry [listadd $entry 5 $size]
				} else {
				    echo -n D
				    #echo -n [format {D%x } [handle id $handle]]
				    var discardable [expr $discardable+$size]
				}
			    } elif {$vmfound == 1} {
				if {1} {
				    # we really want to know if this is async or not,
				    # but without access the the header we don't know, so
				    # assume the worst case and count it
				    #
				    # this will be addressed in the 3.0 version 
				    echo -n V
				    #echo -n [format {V%x } [handle id $handle]]
				    var entry [listadd $entry 4 $size]
				}
			    } elif {[field $flags HF_LMEM]} {
				#		    	    echo -n {.}
				flush-output
				if {![field $flags HF_SWAPPED]} {
				    if {[value fetch $addr:LMBH_lmemType]==2} {
					var nHandles [value fetch $addr:LMBH_nHandles]
					var hTable [value fetch $addr:LMBH_offset]
					var curHandle $hTable
					var objFlags [value fetch $addr:$hTable word]
					for {} {$nHandles > 0} {var nHandles [expr $nHandles-1]} {
					    var chunkAddr [value fetch $addr:$curHandle word]
					    #
					    # check for non-zero chunks and ignore flags chunk
					    #
					    if {($chunkAddr != 0) &&
						($chunkAddr != 0xffff) && ($curHandle != $hTable)} {
						    var fl [value fetch $addr:$objFlags geos::ObjChunkFlags]
						    #
						    # check for object chunk
						    #
						    if {[field $fl OCF_IS_OBJECT]} {
							#						    echo Object
						    }
						}
					    var objFlags [expr $objFlags+1]
					    var curHandle [expr $curHandle+2]
					}
					echo -n B
					#echo -n [format {B%x } [handle id $handle]]
					var entry [listadd $entry 1 $size]
				    } else {
					echo -n O
					#echo -n [format {O%x } [handle id $handle]]
					var entry [listadd $entry 2 $size]
				    }
				} else {
				    echo -n S
				    #echo -n [format {S%x } [handle id $handle]]
				    var entry [listadd $entry 3 $size]
				}
			    } else {
				if {![field $flags HF_SWAPPED]} {
				    echo -n O
				    #echo -n [format {O%x } [handle id $handle]]
				    var entry [listadd $entry 2 $size]
				} else {
				    echo -n S
				    #echo -n [format {S%x } [handle id $handle]]
				    var entry [listadd $entry 3 $size]
				}
			    }
			    table enter $t $own $entry
			} else {
				dospinner
			}
		    } else {
			if {$type == 242} {
#			    var own [owninggeode [field $val HR_owner]]
#			    var size [field $val HR_size]
#			    if {$size == nil} {
#				var size 0
#				echo -n Hey!!!!!  couldn't fetch a field:
#				echo [handle id $handle]
#				ph [handle id $handle]
#			    } else {
#				var size [expr $size<<10]
#			    }
#			    var entry [table lookup $t $own]
#			    if {[null $entry]} {
#				var entry {0 0 0 0 0 0 0}
#				var glist [concat $glist $own]
#			    }
#			    var entry [listadd $entry 6 $size]
#			    table enter $t $own $entry
			    echo Warning - does not handle reserved heap space
			} else { 
			    dospinner
			}
		    }
		}
	    }
	}
	if {[length $args] > 0} {
	    #
	    # Print out the proper banner
	    #
	    echo
	    echo { In this version, Document space figures are inaccurate counting}
	    echo {      all dirty blocks regardless of biffability.}
	    echo
	    echo {geode              Fixed  ObjBlk  Other  Swapped    Total   Docum    Exec}
	    echo {-----              -----  ------  -----  -------    -----   -----    ----}
    
	    var total {0 0 0 0 0 0 0}
	}

        if {![string compare  [index $args 0] total]} {
	    #
	    # Tally for total heapspace available in system.
	    #
	    foreach own $glist {
		var oldtotal $total
		var total {}
		var entry [table lookup $t $own]
		var entry [concat $entry [expr {
		    [index $entry 0]+[index $entry 1]+
		    [index $entry 2]+ [index $entry 3]
		}]]
		var oh [handle lookup $own]
		if {[null $oh]} {
		    if {$own == 0x20} {
			echo -n [format { %-9s} fontman]
		    } else {
			echo -n [format { %04xh%5s} $own {}]
		    }
		} else {
		    if {[isXIP $own]} {
			echo -n [format {*%-15s} [patient name [handle patient
							   [handle lookup $own]]]]
		    } else {
			echo -n [format { %-15s} [patient name [handle patient
								[handle lookup $own]]]]
		    }
		}
#		if {[index $entry 6] != 0} {
#		    echo -n [format {+%-5d} [index $entry 6]]
#		} else {
#		    echo -n [format {      }]
#		}
		for {var i 0} {$i < 4} {var i [expr $i+1]} {
		    echo -n [format {%8d} [index $entry $i]]
		    var total [concat $total
			       [expr [index $oldtotal $i]+[index $entry $i]]
			      ]
		}
		echo [format {%9d%8d%8d} [index $entry 6] [index $entry 4] [index $entry 5]]
		var total [concat $total [expr [index $oldtotal 4]+[index $entry 4]] 
			   [expr [index $oldtotal 5]+[index $entry 5]] 
			   [expr [index $oldtotal 6]+[index $entry 6]]]
	    }
	} elif {![string compare  [index $args 0] syslib]} {
	  #
	  # Tally for non-app system libraries
	  #
	  foreach own $glist {
	    #
	    # Include only if it is a non-app system geode
	    #
	    if {[issysgeode $own] && ![isapp $own]} {
	      var oldtotal $total
	      var total {}
	      var entry [table lookup $t $own]
	      var entry [concat $entry [expr {
					[index $entry 0]+[index $entry 1]+
					[index $entry 2]+[index $entry 3]
			}]]
	      var oh [handle lookup $own]
	      if {[null $oh]} {
		if {$own == 0x20} {
		    echo -n [format { %-9s} fontman]
		} else {
		    echo -n [format { %04xh%5s} $own {}]
		}
	      } else {
		  if {[isXIP $own]} {
		      echo -n [format {*%-15s} [patient name [handle patient
							      [handle lookup $own]]]]
		  } else {
		      echo -n [format { %-15s} [patient name [handle patient
							      [handle lookup $own]]]]
		  }
	      }
	      for {var i 0} {$i < 4} {var i [expr $i+1]} {
		echo -n [format {%8d} [index $entry $i]]
		var total [concat $total
		  [expr [index $oldtotal $i]+[index $entry $i]]
		]
	      }
	      echo [format {%9d%8d%8d} [index $entry 6] [index $entry 4] [index $entry 5]]
	      var total [concat $total [expr [index $oldtotal 4]+[index $entry 4]]
			 [expr [index $oldtotal 5]+[index $entry 5]]
			 [expr [index $oldtotal 6]+[index $entry 6]]]
	    }
	  }
	} elif {([length $args] > 0)} {
	  #
	  # Tally for heapspace on geode -- print & sum all info for geodes
	  # that we ealier determined we had an interest in.
	  #
	  foreach own $glist {
	    foreach geodeToMatch $objlibs {
	      #
	      # If the current geode matches one of our list of geodes to match,
	      # we'll print info about it and make some totals.
	      #
	      if {$own == $geodeToMatch} {
	        var oldtotal $total
	        var total {}
	        var entry [table lookup $t $own]
	        var entry [concat $entry [expr {
					[index $entry 0]+ [index $entry 1]+
					[index $entry 2]+[index $entry 3]
			}]
		]
	        var oh [handle lookup $own]
	        if {[null $oh]} {
	 	  if {$own == 0x20} {
	 	    echo -n [format { %-9s} fontman]
	 	  } else {
	 	    echo -n [format { %04xh%5s} $own {}]
	 	  }
	        } else {
		    if {[isXIP $own]} {
			echo -n [format {*%-15s} [patient name [handle patient
								[handle lookup $own]]]]
		    } else {
			echo -n [format { %-15s} [patient name [handle patient
								[handle lookup $own]]]]
		    }
		}
	        for {var i 0} {$i < 4} {var i [expr $i+1]} {
	  	  echo -n [format {%8d} [index $entry $i]]
	 	  var total [concat $total
	 		[expr [index $oldtotal $i]+[index $entry $i]]
	 	  ]
	        }
	        echo [format {%9d%8d%8d} [index $entry 6] [index $entry 4] [index $entry 5]]
		var total [concat $total [expr [index $oldtotal 4]+[index $entry 4]]
			   [expr [index $oldtotal 5]+[index $entry 5]]
			   [expr [index $oldtotal 6]+[index $entry 6]]]
	      }
	    }
	  }
	}

	if {[length $args] > 0} {
	    #
	    # print TOTAL (geode or global determination)
	    #
	    echo -n [format {%-16s} {TOTAL:}]
	    for {var i 0} {$i < 4} {var i [expr $i+1]} {
	        echo -n [format {%8d} [index $total $i]]
	    }
	    var subtotal [index $total 6]
	    echo [format {%9d%8d%8d} $subtotal [index $total 4] [index $total 5]]
	    echo [format {%57dk%7dk%7dk} [expr (($subtotal)+1023)/1024] [expr ([index $total 4]+1023)/1024] [expr ([index $total 5]+1023)/1024]]
	    if {[expr (($subtotal)+15)/16] >= 65536} {
		echo WARNING! heapspace value too large for .ini file
	    }
	}

        if {![string compare  [index $args 0] total]} {
	    #
	    # Extra for total heapspace determination:  Add in free &
	    # discardable space.
	    #
	    echo
	    echo -n [format {%-12s} heapSize:]
	    echo [format {%45dk} [value fetch heapSize]]
	    echo -n [format {%-22s} {discardable (not locked):}]
	    echo [format {%32d} $discardable]
	    echo -n [format {%-12s} free:]
	    echo [format {%45d} $free]
	} elif {[length $args] > 0} {

	}
    } {
    	table destroy $t
    }
  }
}]


[defsubr dospinner {}
{
	    global spinner
	    if {[null $spinner]} {
	    	var spinner 0
	    }
	    var spinner [expr $spinner+1]
	    if {$spinner > 3} {
	    	var spinner 0
	    }
	    echo -n [index {|/-\\} $spinner char]
	    
	    if {[index [wmove +0 +0] 0] == 0} {
		wmove +[expr [index [wdim [wfind 0 0]] 0]-1] -1
	    } else {
	    	wmove -1 +0
	    }
	    flush-output
}]
[defsubr handle-update {}
{
	echo -n {Updating handle info}
	var first [value fetch loaderVars.KLV_handleTableStart [type word]]
	var last [value fetch loaderVars.KLV_lastHandle [type word]]
	var kilobyte [expr $first>>10]
	for {var i $first} {$i<$last} {var i [expr $i+16]} {
#		echo [format {%04xh} $i]
		if {[expr $i>>10]!=$kilobyte} {
			echo -n {.}
		    	flush-output
			var kilobyte [expr $i>>10]
		}
		handle lookup $i
	}
	echo
}]

# 
# Return boolean to indicate whether geode is considered to be a system
# library or not (regardless of whether also an app)
#
[defsubr issysgeode {geode}
{
    # fontman is considered a system geode, so return non-zero.
    if {$geode == 0x20} {return 1}

    # get position of geode in the geode list, starting at 0
    var num [geodenum $geode]

    # if we can't find the geode, it isn't a system geode
    if {[null $num]} {return 0}

    # quick test -- if 13 or less, certainly a system geode, as this is
    # normally the text library, & there's generally a few more to go..
    if {$num <= 13} {return 1}

    #
    # Figure out what the highest #'d system library geode handle is
    # I've declared this to be anything whose main block is located at
    # or before the text library's.  (cbh)
    #
    # Changed to be nonts -- Doug
    #
    if [null [patient find contlog]] {
	var lastsysgeodename nonts
    } else {
	var lastsysgeodename contlog
    }
    if [null [patient find [var lastsysgeodename]]] {
	echo Could not find $lastsysgeodename
	error {System geodes not all loaded}
    }
    var lastsysgeode [geodenum
		[handle id [index [patient resources [patient find $lastsysgeodename]] 0]]]

    if {$num <= $lastsysgeode} {
	return 1
    } else {
	return 0
    }
}]

#
# Return boolean to indicate if the geode is an application
#
[defsubr isapp {geode}
{
    # fontman is not considered an app.
    if {$geode == 0x20} {return 0}

    # Otherwise, return answer based on bit in geode header
    if {[expr [value fetch ^h$geode.GH_geodeAttr [type word]]&0x0200]} {
	return 1
    } else {
	return 0
    }

}]

#
#prints out the names of the geodes on the geode list
#
[defsubr geodelist {} 
{
    var next_han [value fetch geodeListPtr]
    var count 0
    var nextgeode [patient name [handle patient [handle lookup $next_han]]]
    echo -n [format {%s } $nextgeode]
    var count [expr $count+[length $nextgeode char]+1]
    while {1} {
    	var gh [value fetch ^h$next_han [sym find type GeodeHeader]]
    	var next_han [field $gh GH_nextGeode]
    	if {$next_han == 0} break
    	var nextgeode [patient name [handle patient [handle lookup $next_han]]]
    	echo -n [format {%s } $nextgeode]
    	var count [expr $count+[length $nextgeode char]+1]
    	if {$count > [columns]-9} {
    	    echo
    	    var	count 0
    	}
    }
    echo
}]

#
# Return geode position in the global geode list, or null if not in the
# list.  First position is 0.
#
[defsubr geodenum {geode}
{
    var geodenum 0
    var nextGeode [value fetch geodeListPtr]
    do {
	if {$geode == $nextGeode} {return $geodenum}
	if {[null [handle lookup $nextGeode]]} {
	    echo {Error: Encountered an ignored geode.}
            error {Encountered an ignored geode.}
	}
	var nextGeode [value fetch ^h$nextGeode:GH_nextGeode]
	var geodenum [expr $geodenum+1]
    } while {$nextGeode}
    error [format {Geode %04xh not found in the geode list} $geode]
}]

[defsubr geodep {}
 {
     var nextGeode [value fetch geodeListPtr]
     do {
	 if {[null [handle lookup $nextGeode]]} {
	     error {Encountered ignored geode.}
	 }
	 ph $nextGeode
	 echo
	 var nextGeode [value fetch ^h$nextGeode:GH_nextGeode]
     } while {$nextGeode}
 }]

[defsubr isXIP {geode}
 {
     if {[expr [value fetch ^h$geode.GH_geodeAttr [type word]]&0x0002]} {
	 return 1
     } else {
	 return 0
     }
 }]

[defsubr owninggeode {handle}
{
   if {$handle == 0} {return $handle}
   # Special case for fontman, handle = 20h
   if {$handle == 0x20} {return $handle}
   do {
      var oldhandle $handle
      var handle [value fetch kdata:$handle.HM_owner]
   } while {($handle != $oldhandle) && ($handle != 0)}
   return $handle
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
[defcmd memsize {args} system.heap
{Usage:
    memsize [<memory size>]

Examples:
    "memsize"
    "memsize 512"

Synopsis:
    Change the amount of memory that GEOS thinks that it has.

Notes:
    * The memory size argument is the size to make the heap.  If none
      is specified then the current memory size is returned.

    * Memsize can only be run at startup, before the heap has been
      initialized.  Use this right after an 'att -s'.

    * Memsize accounts for the size of the stub.

}
{
    var stubSize [handle size [handle find loader::SwatSeg]]
    var dosSize [expr 16*[handle segment [handle find loader::PSP]]]

    if {![null $args]} {
    	if {![null [patient find geos]]} {
    	    echo [format {memsize can only change the memory size on startup.}]
    	    return
    	}
    	assign PSP:PSP_endAllocBlk [expr ($args*1024/16)+($stubSize/16)]
    }

    var curTop [value fetch PSP:PSP_endAllocBlk]

    echo [format {DOS, DOS drivers and TSRs occupy %d bytes.} $dosSize]

    echo [format {GEOS believes that this machine has %d bytes (%.1fK).}
    	    	    [expr ($curTop*16)-$stubSize]
    	    	    [expr (($curTop*16)-$stubSize)/1024 f]]
}]

##############################################################################
#				fhan
##############################################################################
#
# SYNOPSIS:	    Locate the ID of the handle whose memory block begins
#   	    	    at the given segment.
# PASS:		    seg	    = segment whose block wants finding
# RETURN:	    the ID of the handle, as a hexadecimal number, or {} if
#		    no handle points to that segment
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/ 1/92		Initial Revision
#
##############################################################################

[defsubr fhan {seg}
{
    var h [handle find $seg:0]
    if {![null $h] && [index [addr-parse $seg:0] 1] == [index [addr-parse ^h[handle id $h]:0] 1]} {
    	return [format {%04xh} [handle id $h]]
    }
}]

##############################################################################
#				hname
##############################################################################
#
# SYNOPSIS:	    Locate the name for a handle, if it has one.
# PASS:		    id	= handle ID
# RETURN:	    the name of the handle, or "unnamed"
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/12/92		Initial Revision
#
##############################################################################
[defsubr hname {id}
{
    var h [handle lookup [getvalue $id]]
    if {[null $h] || !([handle state $h] & 0x80)} {
    	return {unnamed}
    } else {
	return [symbol fullname [handle other $h]]
    }
}]



##############################################################################
#	psegment
##############################################################################
#
# SYNOPSIS:	Print the handle of a segment
# PASS:		segment ID
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       EW 	8/ 4/95   	Initial Revision
#
##############################################################################
[defcmd psegment {num} {top.print system.heap patient.handle}
{Usage:
    psegment <segment ID>

Examples:
    psegment 2f3ah    - show the handle for 2f3ah
    psegment ax       - show the handle for the segment in ax
    psegment ds:si    - show the handle for the segment at ds:si

Synopsis:
    Print out a segment's handle.

Notes:
    The segment ID can be an immediate segment value, or the address
    of a segment value in a register or memory location.

See Also:
    phandle, hwalk, lhwalk.
}
{
    
    #
    # Parse the thing down to an address list. If the thing actually resides
    # in memory ([index $a 0] is non-null), we assume the user wants to print
    # information about a segment variable and use $num as the address from
    # which to fetch a word, using that as the segment itself.
    #
    var a [addr-parse $num 0]
    if {[null [index $a 0]] || [string c [index $a 0] value] == 0} {
    	# $num is a constant, so just use the offset portion.
    	var num [index $a 1]
    } else {
    	var num [value fetch $num [type word]]
    }

    #
    # extract the actual handle, if any
    #
    var handle [handle find [format %04xh:0 $num]]

    if {![null $handle]} {
	if {[handle state $handle] & 0x480} {
	    #
	    # Handle is a resource/kernel handle, so it's got a symbol in
	    # its otherInfo field. We want its name.
	    #
	    echo -n [format {handle: %04xh (%s)}
		     [handle id $handle]
		     [symbol fullname [handle other $handle]]]
	} else {
	    #
	    # There's no symbol name, so just print the handle value
	    #
	    echo -n [format {handle: %04xh}
		     [handle id $handle]]
	}
	if {[handle segment $handle] != $num} {
	    #
	    # The segment isn't actually the base address for it's block,
	    # so print out the real segment
	    #
	    echo [format { [handle segment = %xh]}
		  [handle segment $handle]]
	} else {
	    echo
	}
    } else {
	#
	# The segment is bogus
	#
	echo [format {%04xh has no handle} $num]
    }
}
]


##############################################################################
#	alloclog
##############################################################################
#
# SYNOPSIS:	Manage a log of current unmatched global allocations.
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
#       pjc 	1/16/96   	Initial Revision
#
##############################################################################

[defcmd alloclog {args} {system.heap} 
{Usage:
    alloclog <command>

Examples:
    alloclog on    - turn on log
    alloclog off   - turn off log
    alloclog print - print all global allocations that have not yet
                     been freed

Synopsis:
    Manage a log of global allocations that have not yet been freed.

Notes:
    Simply keeps adds a handle to our list each time MemAllocLow is 
    called, and deletes a handle from our list each time MemFree is 
    called.
}
{
    global allocHandlesList
    global allocLogBreak1
    global allocLogBreak2

    # Make sure there are arguments.

    if {[null $args]} {
	echo No command specified.
	return
    }

    # Get command.
    
    var command [cutcar args]

    # Handle each command separately.

    [case $command in

     on {
	 if {![null $allocLogBreak1]} {
	     echo Allocation log is already on.
	 } else {
	     var allocLogBreak1 [brk MemAllocLow::done]
	     brk cmd $allocLogBreak1 log-alloc
	     var allocLogBreak2 [brk MemFree]
	     brk cmd $allocLogBreak2 log-free
	     
	     var allocHandlesList {}
	 }
     }

     off {
	 if {[null $allocLogBreak1]} {
	     echo Allocation log is already off.
	 } else {
	     brk clear $allocLogBreak1
	     var allocLogBreak1 {}
	     brk clear $allocLogBreak2
	     var allocLogBreak2 {}
	     var allocHandlesList {}
	 }
     }

     p* {
	 foreach allocHandle $allocHandlesList {
	     echo
	     echo [format 
		   {_%04xh______________________________________________________________} 
		   $allocHandle]
	     phan $allocHandle
	 }
     }
    ]
}
]

[defsubr log-alloc {} {
    global allocHandlesList
    var allocHandlesList [concat $allocHandlesList [read-reg bx]]
    return 0
} ]

[defsubr log-free {} {
    global allocHandlesList
    var allocHandlesList [delassoc $allocHandlesList [read-reg bx]]
    return 0
} ]

##############################################################################
#	heaprequest
##############################################################################
#
# SYNOPSIS:	print out "heapspace" reserved by an app
# PASS:		geode name
# CALLED BY:	the user
# RETURN:	nothing
# SIDE EFFECTS:	stuff is printed
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       EW 	3/ 8/96   	Initial Revision
#
##############################################################################
[defcmd heaprequest {args} system.heap
{Usage:
    heaprequest <geode>		   print out "heapspace" reserved by an app

Synopsis:
    Print out the amont of heap space this geode has reserved.  This the
    sum of all GeodeRequestSpace calls for this geode.
}
{
    # find geode core block
    var core [handle id 
	      [index [patient resources [patient find [index $args 0]]] 0]]

    # find geode privdata
    var  priv [value fetch ^h$core.GH_privData]

    # get geodeHeapVarsOffset from kernel
    # subtract FIRST_GEODE_PRIV_OFFSET (2)
    var ghvo [expr {[value fetch geos::geodeHeapVarsOffset] - 2}]

    # read at this offset
    var sz [value fetch ^h$priv:$ghvo [type word]]

    echo [format {%s: %dk} [index $args 0] $sz]
}]
