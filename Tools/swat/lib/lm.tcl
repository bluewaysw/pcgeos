##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	SWAT -- System library.
# FILE: 	lm.tcl
# AUTHOR: 	John / Tony
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
#
# DESCRIPTION:
#	Local memory stuff
#
#	$Id: lm.tcl,v 3.3 90/05/31 04:23:36 adam Exp $
#
###############################################################################
#
# Functions for printing information about a local-memory heap.
#
[defcommand lhwalk {{addr ds}} kernel
{Prints out information about a local-memory heap. Takes one argument:
The address of the block to print. If no argument is supplied then the block
pointed at by ds is used.}

{
    do-lhwalk $addr LHWALK
}]


[defcommand objwalk {{addr ds}} object
{Prints out information about an object block.  The address of the block to
print. If no argument is supplied then the block pointed at by ds is used.}

{
    do-lhwalk $addr OBJWALK
}]

[defsubr do-lhwalk {addr type}
{
    #
    # Set various variables that will be needed.
    #
    var address	    [addr-parse $addr:0]
    var	seg	    [handle segment [index $address 0]]
    var blockHeader [value fetch $addr:0 LMemBlockHeader]
    var blockHandle [field $blockHeader LMBH_handle]
    #
    # Get the information from the LMemInfo structure.
    #
    var lmemType    [field $blockHeader LMBH_lmemType]
    var blockSize   [field $blockHeader LMBH_blockSize]
    var nHandles    [field $blockHeader LMBH_nHandles]
    var firstFree   [field $blockHeader LMBH_freeList]
    var totalFree   [field $blockHeader LMBH_totalFree]
    var hTable	    [field $blockHeader LMBH_offset]
    var heapPtr	    [expr $hTable+($nHandles*2)+2]
    #
    # Print out object block info
    #
    if {![string c $type OBJWALK]} {
	#
	# Print the global block information.
	#
	echo
	echo [format {Heap at %04x:0 (^l%04x), Type = %s} $seg $blockHandle
		[type emap $lmemType [symbol find type LMemTypes]]]
	echo -n [format {In use count = %d, Block size = %d}
			[value fetch $addr:OLMBH_inUseCount] $blockSize]
	echo  [format {, Resource size = %d para (%d bytes)}
			[value fetch $addr:OLMBH_resourceSize]
			[expr [value fetch $addr:OLMBH_resourceSize]*16]]
	echo
	#
	echo {Handle	Address	Size	Flags	Type}
	echo {------	-------	----	-----	----}
	var curHandle $hTable
	var freeHandles 0
	var nullHandles 0
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
		echo -n [format {%-8.04x%-8.04x%-8.04x} $curHandle $chunkAddr
					$size]
		if {$curHandle == $hTable} {
		    echo {-	*flags*}
		} else {
		    var fl [value fetch $addr:$flags ObjChunkFlags]
		    if {[field $fl OCF_IGNORE_DIRTY]} {echo -n {I}
							} else {echo -n { }}
		    if {[field $fl OCF_DIRTY]} {echo -n {D}
							} else {echo -n { }}
		    if {[field $fl OCF_IN_RESOURCE]} {echo -n {R}
							} else {echo -n { }}
		    if {[field $fl OCF_IS_OBJECT]} {
    	    	    	    var class [obj-class $seg:$chunkAddr]
			    if {[null $class]} {
			    	echo {O   } class unknown
    	    	    	    } else {
			        echo {O   } [sym fullname $class]
			    }
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
	echo
    } else {
	#
	# Print the global block information.
	#
	[echo [format {Heap at %04x, Handle %04x, Heap-Type %s.}
		$seg
		$blockHandle
		[type emap $lmemType [symbol find type LMemTypes]]]]
	echo [format {Space allocated for heap : %d bytes.} $blockSize]
	echo [format {Number of handles : %d} $nHandles]
	echo [format {Free space        : %d} $totalFree]
	#
	# Now print out requested information.
	#
	echo {Handle	Address	Size	Free	Next}
	echo {------	-------	----	----	----}
	var curHandle $hTable
	for {} {$nHandles > 0} {var nHandles [expr $nHandles-1]} {
	    var chunkAddr [value fetch $seg:$curHandle word]
	    if {$chunkAddr != 0} {
		if {$chunkAddr == 0xffff} {
		    [echo [format {%-8.04x%-8.04s%-8.04x%-8s}
			$curHandle
			{-}
			0
			{Used}]]
		} else {
		    [echo [format {%-8.04x%-8.04x%-8.04x%-8s}
			$curHandle
			$chunkAddr
			[chunk-size $seg $chunkAddr]
			{Used}]]
		}
	    }
	    var curHandle [expr $curHandle+2]
	}
	[for {} {$firstFree != 0} {} {
		[echo [format {	%-8.04x%-8.04x%-8s%-8.04x}
		    $firstFree
		    [chunk-size $seg $firstFree]
		    {Free}
		    [value fetch $seg:$firstFree word]]]
		var firstFree [value fetch $seg:$firstFree word]
	}]
    }
}]

[defsubr chunk-size {seg addr}
{
    if {$addr == -1} {
	return 0
    } else {
        return [value fetch $seg:$addr-2 word]
    }
}]
