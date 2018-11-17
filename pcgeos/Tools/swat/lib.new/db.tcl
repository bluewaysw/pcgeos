#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library -- DBase
# FILE:		dbase.tcl
# AUTHOR:	John Wedgwood, August 19th, 1991
#
# COMMANDS:
#	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	john	 8/19/91	Initial revision
#
# DESCRIPTION:
#	This file contains TCL routines to assist in debugging the dbase library.
#
#	$Id: db.tcl,v 1.12.2.1 97/03/29 11:26:44 canavese Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

##############################################################################
#				print-db-item
##############################################################################
#
# SYNOPSIS:	Print information about a dbase item.
# PASS:		file, group, item
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	?
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/19/91	Initial Revision
#
##############################################################################
[defcmd print-db-item {file group item} lib_app_driver.dbase
{Usage:
    print-db-item <file> <group> <item>

Examples:
    "print-db-item bx ax di"   	print the item at bx/ax/di

Synopsis:
    Print information about a single dbase item

Notes:

See also:
    print-db-group
}
{
    #
    # Get the numeric values of the arguments
    #
    var file        [getvalue $file]
    var group       [getvalue $group]
    var item        [getvalue $item]

    var itemInfo    [map-db-item-to-addr $file $group $item]

    var itemVM      [index $itemInfo 0]
    var itemHan     [index $itemInfo 1]
    var itemSegment [index $itemInfo 2]
    var itemChunk   [index $itemInfo 3]
    var itemOffset  [index $itemInfo 4]

    #
    # Map the group-block to a memory handle.
    #
    var grpAddr [addr-parse ^v$file:$group]
    var grpHan  [handle id [index $grpAddr 0]]

    echo {FILE   GROUP  ITEM   GRP-BLK    POINTER      HAN/CHUNK}
    echo {-----  -----  -----  -------  -----------  -------------}

#    	  1234h  1234h  1234h  ^h1234h  1234h:1234h  ^l1234h:1234h

    echo [format {%04xh  %04xh  %04xh  ^h%04xh  %04xh:%04xh  ^l%04xh:%04xh}
    	    	$file
		$group
		$item
		$grpHan
		$itemSegment $itemOffset
		$itemHan $itemChunk]
}]

##############################################################################
#				print-db-group
##############################################################################
#
# SYNOPSIS:	Print information about a group block.
# PASS:		file, group
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	?
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/19/91	Initial Revision
#
##############################################################################
[defcmd print-db-group {file group} lib_app_driver.dbase
{Usage:
    print-group file group

Examples:
    "print-db-group bx ax"   	print the group at bx/ax

Synopsis:
    Print information about a dbase group block

Notes:

See also:
    print-db-item
}
{
    #
    # Get the numeric values of the arguments
    #
    var file         [getvalue $file]
    var group        [getvalue $group]

    #
    # Get information about the group block.
    #
    var gbHdr [value fetch ^v$file:$group [sym find type DBGroupHeader]]
    
    var gbVM	     [field $gbHdr DBGH_vmemHandle]
    var gbHan	     [field $gbHdr DBGH_handle]
    var gbFlags	     [field $gbHdr DBGH_flags]
    var gbItemBlocks [field $gbHdr DBGH_itemBlocks]
    var gbItemFree   [field $gbHdr DBGH_itemFreeList]
    var gbBlockFree  [field $gbHdr DBGH_blockFreeList]
    var gbBlockSize  [field $gbHdr DBGH_blockSize]
    
    var gbAddr 	   [addr-parse ^v$file:$group]
    var gbHan  	   [handle id [index $gbAddr 0]]
    var gbSegment  [handle segment [index $gbAddr 0]]
    
    #
    # Now run through the group looking at the item blocks.
    #
    echo {ITEM BLK  HANDLE     ADDRESS    REF-COUNT  FLAGS}
    echo {--------  -------  -----------  ---------  -----------------}
#    	    1234h   ^h1234h  1234h:1234h    12345    <UNGROUPED DIRTY>

    var ibInfoType [sym find type DBItemBlockInfo]

    var flags {}
    if {[field $gbFlags GF_IS_UNGROUP]} {
    	var flags {UNGROUPED}
    }

    #
    # Print out all the information about the item-blocks that are in use.
    #
    var blockPtr $gbItemBlocks

    while {$blockPtr != 0} {
    	#
	# Process the current item block
	#
	var ibInfo [value fetch $gbSegment:$blockPtr $ibInfoType]
	var ibVM   [field $ibInfo DBIBI_block]

	var ibAddr    [addr-parse ^v$file:$ibVM]
	var ibHan     [handle id [index $ibAddr 0]]
	var ibSegment [handle segment [index $ibAddr 0]]
	
	var ibHanFlags [value fetch kdata:$ibHan.HM_flags]
	
	var hanFlags {}
	if {! [field $ibHanFlags HF_DISCARDABLE]} {
	    var hanFlags {DIRTY}
	}

	echo [format {  %04xh   ^h%04xh  %04xh:%04xh    %5d    <%s %s>}
		    $ibVM
		    $ibHan
		    $ibSegment
		    0
		    [field $ibInfo DBIBI_refCount]
		    $flags $hanFlags
    	    	    ]

    	var blockPtr [field $ibInfo DBIBI_next]
    }
    
    #
    # Now we build a list of offsets. These offsets will hold an unsorted
    # list of offsets. The offsets are the positions in the group block
    # at which the item-blocks fall (both free and allocated item-blocks.
    #
    # Using this block we figure out which offsets in the group block
    # correspond to items. Then we print these items out...
    #
    var blockList {}

    var blockPtr $gbItemBlocks
    while {$blockPtr != 0} {
    	var blockList [concat $blockList $blockPtr]

    	var blockPtr [value fetch $gbSegment:$blockPtr.DBIBI_next]
    }

    var blockPtr $gbBlockFree
    while {$blockPtr != 0} {
    	var blockList [concat $blockList $blockPtr]

    	var blockPtr [value fetch $gbSegment:$blockPtr.DBFBS_next]
    }
    
    #
    # Now that we have this list we need to make another one which contains
    # a list of the free items.
    #
    var freeList {}

    var blockPtr $gbItemFree
    while {$blockPtr != 0} {
    	var freeList [concat $freeList $blockPtr]

    	var blockPtr [value fetch $gbSegment:$blockPtr.DBFIS_next]
    }
    
    #
    # Now start at the beginning of the block and progress toward the end.
    # Foreach offset do the following:
    #	Same as entry in blockList
    #	    - Add size of a block-entry
    #	Same as entry in freeList
    #	    - Add size of a free item-entry
    #	Otherwise print it out as an in use item
    #
    echo
    echo {GROUP  ITEM   VM-BLK  HANDLE     ADDRESS      HAN/CHUNK}
    echo {-----  -----  ------  -------  -----------  -------------}
#    	  1234h  1234h  1234h   ^h1234h  1234h:1234h  ^l1234h:1234h

    var blockEntrySize [type size [sym find type DBItemBlockInfo]]
    var itemEntrySize  [type size [sym find type DBItemInfo]]

    var ptr [type size [sym find type DBGroupHeader]]
    
    while {$ptr < $gbBlockSize} {
    	if {[member $ptr $blockList]} {
	    var ptr [expr $ptr+$blockEntrySize]
	} elif {[member $ptr $freeList]} {
	    var ptr [expr $ptr+$itemEntrySize]
	} else {
	    #
	    # The entry is valid, print it out...
	    #
	    var itemInfo [map-db-item-to-addr $file $group $ptr]
	    
	    var itemVM      [index $itemInfo 0]
	    var itemHan     [index $itemInfo 1]
	    var itemSegment [index $itemInfo 2]
	    var itemChunk   [index $itemInfo 3]
	    var itemOffset  [index $itemInfo 4]
    	    
	    echo [format {%04xh  %04xh  %04xh   ^h%04xh  %04xh:%04xh  ^l%04xh:%04xh}
    	    	    	$group
			$ptr
			$itemVM
			$itemHan
			$itemSegment $itemOffset
			$itemHan $itemChunk]
	    
	    var ptr [expr $ptr+$itemEntrySize]
	}
    }
}]

[defsubr member {element {list {}}}
{
    if {[null $list]} {
    	return 0
    } elif {$element == [car $list]} {
    	return 1
    } else {
    	return [member $element [cdr $list]]
    }
}]

##############################################################################
#			map-db-item-to-addr
##############################################################################
#
# SYNOPSIS:	Map a dbase item to an address
# PASS:		file, group, item
# CALLED BY:	?
# RETURN:	list of item info
#   	    	  0: VM Block handle of the item
#   	    	  1: Memory block handle of the item	(0 for not loaded)
#   	    	  2: Segment address of the block
#   	    	  3: Chunk handle of the item
#   	    	  4: Offset of the item
# SIDE EFFECTS:	?
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/19/91	Initial Revision
#
##############################################################################
[defsubr map-db-item-to-addr {fileHan gVM item}
{

    require ensure-vm-block-resident vm

    #
    # Assume these are all zero...
    #
    var	itemVM	    0
    var	itemHan	    0
    var	itemSegment 0
    var	itemChunk   0
    var	itemOffset  0

    var fhan [handle lookup $fileHan]
    if {[null $fhan]} {
    	var fileHan [value fetch $fileHan word]
    }
    if {$gVM != 0} {
	#
	# Map the group vm-block to a memory block.
	#
    	ensure-vm-block-resident $fileHan $gVM
	var itemPos 	((^v$fileHan:$gVM):$item)
	var itemVM      [value fetch (*$itemPos.DBII_block).DBIBI_block]
	var itemChunk	[value fetch $itemPos.DBII_chunk]

	ensure-vm-block-resident $fileHan $itemVM

	var itemAddr    [addr-parse ^v$fileHan:$itemVM]
	
	var itemHan     [handle id [index $itemAddr 0]]
	var itemSegment [handle segment [index $itemAddr 0]]
	var itemOffset  [value fetch $itemSegment:$itemChunk [type word]]
    }
    return [list $itemVM $itemHan $itemSegment $itemChunk $itemOffset]
}]

##############################################################################
#	get-db-map
##############################################################################
#
# SYNOPSIS:	Return the db map item given a db file
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
#	cdb 	7/ 1/92   	Initial Revision
#
##############################################################################
[defsubr    get-db-map {h} {

    require map-file-to-vm-handle vm.tcl

    var fhan [handle lookup $h]
    if {[null $fhan]} {
    	var h [value fetch $h word]
    }
    var hdr [value fetch kdata:[map-file-to-vm-handle $h].HVM_headerHandle]
    var dbmap [value fetch ^h$hdr:VMH_dbMapBlock]

    var dbmapStruct [value fetch ^v$h:$dbmap [symbol find type DBMapBlock]]

    var group [field $dbmapStruct DBMB_mapGroup]
    var item [field $dbmapStruct DBMB_mapItem]

    var dbmapAddr [map-db-item-to-addr $h $group $item]
    return ^l[index $dbmapAddr 1]:[index $dbmapAddr 3]

}]


