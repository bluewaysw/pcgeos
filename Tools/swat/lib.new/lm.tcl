##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	SWAT -- System library.
# FILE: 	lm.tcl
# AUTHOR: 	John / Tony
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	lhwalk	    	    	Provide info for a local-memory heap
#   	objwalk	    	    	Provide info on all chunks in an object block
#
#
# DESCRIPTION:
#	Local memory stuff
#
#	$Id: lm.tcl,v 3.25.11.1 97/03/29 11:26:24 canavese Exp $
#
###############################################################################
#
# Functions for printing information about a local-memory heap.
#
[defcmd lhwalk {{addr ds}} {top.heap system.heap}
{Usage:
    lhwalk [<address>]

Examples:
    "lhwalk 1581h"  	list the lm heap at 1581h:0

Synopsis:
    Prints out information about a local-memory heap.

Notes:
    * The address argument is the address of the block to print. The 
      default is block pointed to by ds.

See also:
    hwalk, objwalk
}
{
    _lhwalk-set-vars $addr

    #
    # Print the global block information.
    #
    echo [format {Space allocated for heap : %d bytes.} $blockSize]
    echo [format {Number of handles : %d} $nHandles]
    echo [format {Free space        : %d} $totalFree]

    #
    # Now print out requested information.
    #
    global geos-release
    [if {${geos-release} >= 2 && 
	 [field [field $blockHeader LMBH_flags] LMF_NO_HANDLES]}
    {
        #
	# Special case for block with no handles
	#
	# Build a list holding the offsets of all the free blocks
	#
	var freeList {}
	[for {var f $firstFree} {$f != 0} {var f [value fetch $seg:$f word]}
	{
    	    var freeList [concat $freeList $f]
	}]
	
	echo {OFFSET SIZE  FREE  NEXT}
	echo {------ ----  ----  ----}
	[for {var base [expr $hTable+2]}
	     {$base < $blockSize}
	     {var base [expr $base+(($chunkSize+3)&~3)]}
	{
	    var chunkSize [value fetch $seg:$base-2 word]
	    if {![null [assoc $freeList $base]]} {
	    	var next [value fetch $seg:$base word]
    	    	if {$next != 0} {
	    	    echo [format { %04xh %5d  Free  %04xh}
		    	    $base $chunkSize $next]
    	    	} else {
	    	    echo [format { %04xh %5d  Free  none} $base $chunkSize]
    	    	}
    	    } else {
    	    	echo [format { %04xh %5d  Used} $base $chunkSize]
    	    }
    	}]
    } else {
	echo {CHUNK OFFSET SIZE  FREE  NEXT}
	echo {----- ------ ----  ----  ----}
	var curHandle $hTable
	for {} {$nHandles > 0} {var nHandles [expr $nHandles-1]} {
	    var chunkAddr [value fetch $seg:$curHandle word]
	    if {$chunkAddr != 0} {
		if {$chunkAddr == 0xffff} {
		    [echo [format {%04xh %4s %5d  %4s}
			$curHandle
			{-}
			0
			{Used}]]
		} else {
		    [echo [format {%04xh %4xh %5d  %4s}
			$curHandle
			$chunkAddr
			[expr [chunk-size $seg $chunkAddr]-2]
			{Used}]]
		}
	    }
	    var curHandle [expr $curHandle+2]
	}
	[for {} {$firstFree != 0} {} {
		[echo [format {      %4xh %5d  %4s  %4xh}
		    $firstFree
		    [chunk-size $seg $firstFree]
		    {Free}
		    [value fetch $seg:$firstFree word]]]
		var firstFree [value fetch $seg:$firstFree word]
	}]
    }]
}]


######################################################################
[defcmd objwalk {{addr ds}} {top.object object.print}
{Usage:
    objwalk [<address>]

Examples:
    "objwalk"

Synopsis:
    Prints out information about an object block.

Notes:
    * The address argument is the address of the block to print. The
      default is the block pointed at by ds.

    * Since the block is an object block, each chunk has a set of
    ObjChunkFlags associated with it.  These flags are displayed in
    the FLAGS column, and have the following meanings:

       I - OCF_IGNORE_DIRTY.  The chunk won't be saved to state (or to
       its VM file, even it the chunk is dirty.

       D - OCF_DIRTY - the chunk is dirty, and will be saved to state
       (unless OCF_IGNORE_DIRTY is set).

       R - OCF_IN_RESOURCE - the chunk is defined in a resource, and thus
       it will be resized to zero, rather than freed, if it's not dirty.

       O - OCF_IS_OBJECT - the chunk is an object.


See also:
    lhwalk, pobject
}
{
    require print-obj-and-method object

    _lhwalk-set-vars $addr
    #
    # User-is-silly checks.
    #
    if {[string c $lmemType LMEM_TYPE_OBJ_BLOCK] != 0} {
    	error {objwalk should not be used on something that's not an object block}
    }
    #
    # Print the global block information.
    #
    echo -n [format {In use count = %d, Block size = %d}
		    [value fetch $seg:OLMBH_inUseCount] $blockSize]
    echo  [format {, Resource size = %d para (%d bytes)}
		    [value fetch $seg.OLMBH_resourceSize]
		    [expr [value fetch $seg:OLMBH_resourceSize]*16]]
    if {![field [value fetch $seg:LMBH_flags] LMF_RELOCATED]} {
	echo (relocating object classes)
    }
    echo
    #
    echo {CHUNK OFFSET SIZE FLAGS OBJECT}
    echo {----- ------ ---- ----- ------}

    var curHandle $hTable
    var freeHandles 0
    var nullHandles 0
    var objects 0 igdirtObjects 0

    var flags [value fetch $seg:$hTable word]
    for {} {$nHandles > 0} {var nHandles [expr $nHandles-1]} {
	var chunkAddr [value fetch $seg:$curHandle word]
	if {$chunkAddr == 0} {
	    var freeHandles [expr $freeHandles+1]
	} else {
	    if {$chunkAddr == 0xffff} {
		var nullHandles [expr $nullHandles+1]
		var size 0
	    } else {
		var size [chunk-size $seg $chunkAddr]
	    }
	    echo -n [format {%04xh %4xh %5d }
			$curHandle $chunkAddr $size]
	    if {$curHandle == $hTable} {
		echo {----- *flags*}
	    } else {
		var fl [value fetch $seg:$flags geos::ObjChunkFlags]
		if {[field $fl OCF_IGNORE_DIRTY]} {echo -n I} else {echo -n { }}
		if {[field $fl OCF_DIRTY]} {echo -n D} else {echo -n { }}
    	    	if {[field $fl OCF_VARDATA_RELOC]} {echo -n V} {echo -n { }}
		if {[field $fl OCF_IN_RESOURCE]} {
		    echo -n R
    	    	} else {
		    echo -n { }
    	    	}
		if {[field $fl OCF_IS_OBJECT]} {
    	    	    var objects [expr $objects+1]
		    if {[field $fl OCF_IGNORE_DIRTY]} {
		    	var igdirtObjects [expr $igdirtObjects+1]
    	    	    }
		    echo -n [format {O }]
		    print-obj-and-method $blockHandle $curHandle
		} else {
		    echo
		}
	    }
	}
	var flags [expr $flags+1]
	var curHandle [expr $curHandle+2]
    }
    echo
    echo [format {Free handles = %d, null handles = %d} $freeHandles
						    $nullHandles]
    echo [format {Objects = %d, %d of them marked ignoreDirty} $objects
    	    	$igdirtObjects]
    echo
}]


##############################################################################
#				_lhwalk-set-vars
##############################################################################
#
# SYNOPSIS:	Internal function to set various variables required by those
#   	    	who would walk an lmem heap.
# PASS:		addr	= address-expression (not just a segment) for the
#			  location of the heap.
# CALLED BY:	objwalk, lhwalk, absobjwalk, abslhwalk
# RETURN:	the following variables set in the caller's context:
#   	    	    address 	= 3-list of parsed $addr
#		    seg	    	= the actual segment of the heap.
#		    blockHeader	= value list containing LMemBlockHeader at
#				  the address.
#   	    	    blockHandle	= the LMBH_handle field of the header
#   	    	    lmemType	= the LMBH_lmemType field of the header as
#				  its named member of the LMemType enum
#   	    	    blockSize	= the LMBH_blockSize field of the header
#   	    	    nHandles	= the LMBH_nHandles field of the header
#   	    	    firstFree	= the offset of the first free chunk in the
#				  lmem heap.
#   	    	    totalFree	= the LMBH_totalFree field of the header
#   	    	    hTable  	= start of the chunk-handle table
#   	    	    heapPtr 	= start of the data heap
# SIDE EFFECTS:	see above, plus the opening information about the heap
#		(its address and type and handle) is printed.
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/28/91		Initial Revision
#
##############################################################################
[defsubr _lhwalk-set-vars {addr}
{
    #
    # Set various variables that will be needed.
    #
    uplevel 1 [format {
    	var a %s
    	var address [addr-parse $a 0]
    	#
	# Deal with being given the address of the base of the block, rather
	# than just its segment. If the address evaluates to an integer,
	# assume we got the segment, and reparse it with a :0 tacked onto
	# the end. Else reparse it as an address, rather than accepting a value
	# back, assuming the thing is a pointer that needs to be dereferenced.
	#
	if {[string c [index $address 0] value] == 0} {
	    if {![string c [type class [index $address 2]] int]} {
	    	var a $a:0
    	    }
	    var address [addr-parse $a]
    	}
    	if {[null [index $address 0]]} {
	    var seg [expr [index $address 1]>>4]
	    var fmt_seg [format %%04xh $seg]
	} else {
	    var seg [handle segment [index $address 0]]
	    if {$seg == 0} {
		# handle not resident, so use ^h<handle id> to allow
		# Swat to fetch data from the executable...
		var seg ^h[handle id [index $address 0]]
		var fmt_seg [format ^h%%04xh [handle id [index $address 0]]]
	    } else {
	    	var fmt_seg [format %%04xh $seg]
    	    }
    	}
        var blockHeader [value fetch $seg:0 geos::LMemBlockHeader]
	var blockHandle [field $blockHeader LMBH_handle]
	#
	# Get the information from the LMemInfo structure.
	#
	var lmemType    [type emap [field $blockHeader LMBH_lmemType]
				    [if {[not-1x-branch]}
					{sym find type LMemType}
					{sym find type LMemTypes}]]
	var blockSize   [field $blockHeader LMBH_blockSize]
	var nHandles    [field $blockHeader LMBH_nHandles]
	var firstFree   [field $blockHeader LMBH_freeList]
	var totalFree   [field $blockHeader LMBH_totalFree]
	var hTable      [field $blockHeader LMBH_offset]
	var heapPtr	[expr $hTable+($nHandles*2)+2]
	echo
	echo [format {Heap at %%s:0 (^h%%04xh), Type = %%s} $fmt_seg $blockHandle
		$lmemType]
    } $addr]
}]

[defsubr chunk-size {seg addr}
{
    if {$addr == -1 || $addr == 0xffff} {
	return 0
    } else {
        return [value fetch $seg:$addr-2 word]
    }
}]
