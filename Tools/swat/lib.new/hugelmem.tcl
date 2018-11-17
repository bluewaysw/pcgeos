##############################################################################
#
# 	Copyright (c) Geoworks 1996 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	
# FILE: 	hugelmem.tcl
# AUTHOR: 	Chris Thomas, Mar  4, 1996
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#	print-huge-lmem		Prints info about a huge lmem heap
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	CT	3/ 4/96   	Initial Revision
#
# DESCRIPTION:
#	Swat Commands to deal with HugeLMem heaps in the netutils lib
#
#	$Id: hugelmem.tcl,v 1.1.6.1 97/03/29 11:27:33 canavese Exp $
#
###############################################################################

##############################################################################
#	print-huge-lmem
##############################################################################
#
# SYNOPSIS:	prints info about a HugeLMem heap
# PASS:		
# CALLED BY:	COMMAND
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       CT 	3/ 4/96   	Initial Revision
#
##############################################################################
[defcommand  print-huge-lmem {args} print 
{Usage:
    print-huge-lmem [<flags>] handle

Examples:
    "print-huge-lmem 5ac0h"		print basic info about HugeLMem
					rooted at ^h5ac0h

    "print-huge-lmem -b ^h5ac0h"	print basic info and block info

    "print-huge-lmem -bc ^h5ac0h"	print basic info, block info
					


Synopsis:

    Prints information about a HugeLMem heap

Notes:

    Flags:

      -b      Prints info on each block in the HugeLMem heap

      -c      Prints info on each chunk in the HugeLMem heap
}
{

    var listBlocks 0
    var listChunks 0
    var mapBlock

    while {[string m [index $args 0] -*]} {
	#
	# Gave us some flags
	#
    	var arg [range [index $args 0] 1 end chars]
    	while {![null $arg]} {
	    [case [range $arg 0 0 chars] in
		b {
		    var listBlocks 1
		}
    	    	c {
    	    	    var listChunks 1
    	    	}
	    ]
    	    if {![null $arg]} {
    	    	var arg [range $arg 1 end chars]
    	    }
    	}
	var args [cdr $args]
    }

    if {[length $args] == 0} {
	error [list bad args: $args]
    } else {
	var mapBlock [index $args 0]
    }

    #
    # Steal code from phandle so that we accept handles the same
    # arguments it does.
    #
    var a [addr-parse $mapBlock 0]
    if {[null [index $a 0]] || [string c [index $a 0] value] == 0} {
    	# $num is a constant, so just use the offset portion.
    	var mapBlock [index $a 1]
    } else {
    	var mapBlock [value fetch $mapBlock [type word]]
    }

    var mapBlock ^h$mapBlock

    #
    # Print the map block header
    #

    print netutils::HugeLMemMap $mapBlock

    #
    # If desired, list all the blocks in the heap
    #

    var t [symbol find type netutils::HugeLMemBlockEntry]
    var s [type size $t]
    var n [getvalue $mapBlock:netutils::HLMM_maxNumBlock]

    if {$listBlocks} {
	var off [expr {[index [symbol get [symbol find field netutils::HLMM_blockTable]] 0] / 8}]

	var ct 0
	var at 0

	echo {Block	Handle	Chunks	Allocated}
	echo {--------------------------------------}

	for {var i 0} {$i < $n} {var i [expr $i+1]} {
	    var be [value fetch $mapBlock:$off $t]
	    if {[field $be HLMBE_block]} {
		echo [format {%d\t^h%04xh\t%5d\t  %04xh  (%d)}
		      $i
		      [field $be HLMBE_block]
		      [field $be HLMBE_numChunks]
		      [field $be HLMBE_blockSize]
		      [field $be HLMBE_blockSize]
		     ]
		var ct [expr $ct+[field $be HLMBE_numChunks]]
		var at [expr $at+[field $be HLMBE_blockSize]]

		#
		# If desired, list all the chunks in the block
		#

		if {$listChunks} {
		    lhwalk ^h[field $be HLMBE_block]
		    echo {======================================}
		    echo
		}
	
	    }

	    var off [expr $off+$s]
	}
	
	echo {--------------------------------------}
	echo [format {TOTAL\t\t%5d\t%06xh  (%d)} $ct $at $at]
    }

}]
