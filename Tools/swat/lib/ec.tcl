##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	swat/lib
# FILE: 	ec.tcl
# AUTHOR: 	Doug Fults, May  5, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	doug	5/ 5/89		Initial Revision
#
# DESCRIPTION:
#	Error checking commands
#
#	$Id: ec.tcl,v 3.8 90/11/09 05:10:03 tony Exp $
#
###############################################################################

defvar ec-flags {
    {region 	    ECF_REGION}
    {heapFree 	    ECF_HEAP_FREE_BLOCKS}
    {lmemInternal   ECF_LMEM_INTERNAL}
    {lmemFree 	    ECF_LMEM_FREE_AREAS}
    {lmemObject     ECF_LMEM_OBJECT}
    {graphics 	    ECF_GRAPHICS}
    {segment 	    ECF_SEGMENT}
    {normal 	    ECF_NORMAL}
    {vm   	    ECF_VMEM}
    {lmemMove	    ECF_LMEM_MOVE}
    {unlockMove	    ECF_UNLOCK_MOVE}
    {vmemDiscard    ECF_VMEM_DISCARD}
}

[defcommand ec {args} output
{Gets or sets the error checking level.
	ec		- get the error checking level
	ec flag		- turn on "flag"
	ec +flag	- turn on "flag"
	ec -flag	- turn off "flag"
	ec all		- turn on all error checking flags
	ec none		- turn off all error checking flags
	ec sum handle	- turn on checksum checking for handle (ec sum bx)
	ec -sum		- turn off checksum checking

	flags are:

	region - region checking
	heapFree - heap free block checking
	lmemInternal - internal lmem error checking
	lmemFree - lmem free area checking
	lmemObject - lmem object checking
	graphics - graphics checking
	segment - extensive segment register checking
	normal - normal error checking
    	vm - vmem file structure checking
    	lmemMove - force lmem blocks to move whenever possible
    	unlockMove - force unlocked blocks to move whenever possible
    	vmemDiscard - force vmem blocks to be discarded if possible

}
{	
    global ec-flags
    var cur [value fetch sysECLevel [type word]]
    if {[null $args]} {
	echo -n {Current error checking flags: }
	precord ErrorCheckingFlags $cur 1
	if {$cur&0x400} {
	    echo [format {Checksum checking on block: %04xh (checksum is %04xh)}
			[value fetch sysECBlock] [value fetch sysECChecksum]]
	}
    } else {
	while {![null $args]} {
	    var i [car $args]
	    var args [cdr $args]
	    [case $i in
		sum {
		    assign {word sysECBlock} [car $args]
		    assign {word sysECChecksum} 0
		    var cur [expr $cur|[fieldmask ECF_BLOCK_CHECKSUM]]
		    var args [cdr $args]
		}
		-sum {var cur [expr $cur&~[fieldmask ECF_BLOCK_CHECKSUM]]}

		all {var cur 0xfb80}
		none {var cur 0}

    	    	+* {
		    var field [assoc ${ec-flags} [range $i 1 end chars]]
    	    	    if {[null $field]} {
		    	echo Invalid option: $i
    	    	    } else {
		    	var cur [expr $cur|[fieldmask [index $field 1]]]
    	    	    }
    	    	}
		-* {
		    var field [assoc ${ec-flags} [range $i 1 end chars]]
    	    	    if {[null $field]} {
		    	echo Invalid option: $i
    	    	    } else {
		    	var cur [expr $cur&~[fieldmask [index $field 1]]]
    	    	    }
    	    	}
		default {
		    var field [assoc ${ec-flags} $i]
    	    	    if {[null $field]} {
		    	echo Invalid option: $i
    	    	    } else {
		    	var cur [expr $cur|[fieldmask [index $field 1]]]
    	    	    }
    	    	}
	    ]
	}
	assign {word sysECLevel} $cur
    }
}]
