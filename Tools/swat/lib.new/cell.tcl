#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library -- Cell
# FILE:		cell.tcl
# AUTHOR:	John Wedgwood, August 13th, 1991
#
# COMMANDS:
#	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	john	 8/13/91	Initial revision
#
# DESCRIPTION:
#	This file contains TCL routines to assist in debugging the cell library.
#
#	$Id: cell.tcl,v 1.4 93/07/31 22:22:37 jenny Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

#
# We make use of stuff in the dbase tcl library.
#
[require map-db-item-to-addr    db.tcl]

##############################################################################
#				print-row
##############################################################################
#
# SYNOPSIS:	Print the contents of a cell library row given a pointer.
# PASS:		address	= Address of the row (defaults to *ds:si)
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	?
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/13/91	Initial Revision
#
##############################################################################
[defcmd print-row {{address *ds:si}} lib_app_driver.cell
{Usage:
    print-row [<address *ds:si>]

Examples:
    "print-row"	    	print the row at *ds:si
    "print-row ds:si"  	print the row at ds:si

Synopsis:
    Print a single row in the cell file given a pointer to the row.

Notes:

See also:
    print-column-element
    print-cell-params
    print-row-block
    print-cell
}
{
    #
    # First parse the address into a handle/offset.
    #
    var addr [addr-parse $address]
    var han  [handle id [index $addr 0]]
    var seg  [handle segment [index $addr 0]]
    var off  [index $addr 1]
    
    echo
    print-file-info-from-block $han
    echo

    #
    # Extract the header and print it.
    #
    var header [value fetch $seg:$off ColumnArrayHeader]
    var count  [field $header CAH_numEntries]
    var	size   [value fetch $seg:$off-2 [type word]]

    #
    # Find the chunk for this row.
    #
    var chunk [_cell-find-chunk $seg $off]
    if {$chunk == 0} {
    	echo {Unable to find a chunk for this row}
	return
    }
    
    #
    # Set up the 'plural' for pretty printing
    #
    var s {s}
    if {$count == 1} {
    	var s {}
    }
    echo [format {Row (%d element%s) at %04xh:%04xh (^l%04xh:%04xh), %d bytes}
    	    	    	$count $s
    	    	    	$seg $off 
			$han $chunk
			$size]
    echo

    if {$count > 256} {
	echo
    	echo [format {WARNING: Number of rows is not valid (>256): %d} $count]
	echo {Only printing the first 256 entries}
	echo
	var count 256
    }
    
    echo {COLUMN  GROUP  ITEM   OFFSET   ENTRY PTR   VM-BLK    POINTER      HAN/CHUNK}
    echo {------  -----  -----  ------  -----------  ------  -----------  -------------}
#   123   1234h  1234h  +1234h  1234h:1234h  1234h   1234h:1234h  ^l1234h:1234h

    #
    # Map the block handle to a file handle
    #
    var owner   [value fetch kdata:$han.HM_owner]
    var fileHan [value fetch kdata:$owner.HVM_fileHandle]

    #
    # Advance the pointer to get at the first element of the array
    #
    var base $off
    var off [expr $off+[type size [sym find type ColumnArrayHeader]]]

    while {$count > 0} {
    	var entry  [value fetch $seg:$off ColumnArrayElement]
	var column [field $entry CAE_column]
	var group  [field [field $entry CAE_data] DBI_group]
	var item   [field [field $entry CAE_data] DBI_item]

	var itemInfo    [map-db-item-to-addr $fileHan $group $item]
	var itemVM      [index $itemInfo 0]
	var itemHan     [index $itemInfo 1]
	var itemSegment [index $itemInfo 2]
	var itemChunk   [index $itemInfo 3]
	var itemOffset  [index $itemInfo 4]

	echo [format {  %3d   %04xh  %04xh  +%04xh  %04xh:%04xh  %04xh   %04xh:%04xh  ^l%04xh:%04xh}
    	    	    $column
		    $group
		    $item
		    [expr $off-$base]
		    $seg $off
		    $itemVM
		    $itemSegment $itemOffset
		    $itemHan $itemChunk]

	#
	# Move to the next entry
	#
	var off [expr $off+[type size [sym find type ColumnArrayElement]]]
	var count [expr $count-1]
    }
    
    #
    # Put out one blank line.
    #
    echo
}]

##############################################################################
#				print-column-element
##############################################################################
#
# SYNOPSIS:	Print the contents of a ColumnArrayElement
# PASS:		address	= Address of the element (defaults to ds:si)
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	?
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/13/91	Initial Revision
#
##############################################################################
[defcmd print-column-element {{address ds:si}} lib_app_driver.cell
{Usage:
    print-column-element [<address ds:si>]

Examples:
    "print-column-element"	    	print the ColumnArrayElement at ds:si
    "print-column-element ds:bx"  	print the ColumnArrayElement at ds:bx

Synopsis:
    Print a single ColumnArrayElement at a given address

Notes:

See also:
    print-row
    print-cell-params
    print-row-block
    print-cell
}
{
    #
    # First parse the address into a handle/offset.
    #
    var addr [addr-parse $address]
    var han  [handle id [index $addr 0]]
    var seg  [handle segment [index $addr 0]]
    var off  [index $addr 1]

    echo
    print-file-info-from-block $han
    echo

    echo {COLUMN  ROW-POINTER  GROUP  ITEM   VM-BLK   CELL_ADDR     HAN/CHUNK}
    echo {------  -----------  -----  -----  ------  -----------  ------------}
#           123   1234h:1234h  1234h  1234h  1234h   1234h:1234h  ^l1234h:1234h

    var chunk [_cell-find-chunk $seg $off]
    if {$chunk == 0} {
    	echo {Unable to find a chunk for this elements row}
	return
    }
    
    var element   [value fetch $seg:$off ColumnArrayElement]
    var column    [field $element CAE_column]
    var group     [field [field $element CAE_data] DBI_group]
    var item      [field [field $element CAE_data] DBI_item]
    var rowChunk  [_cell-find-chunk $seg $off]
    var rowOffset [value fetch $seg:$rowChunk [type word]]
    
    #
    # Map the block handle to a file handle.
    #
    var owner   [value fetch kdata:$han.HM_owner]
    var fileHan [value fetch kdata:$owner.HVM_fileHandle]
    
    var itemInfo    [map-db-item-to-addr $fileHan $group $item]
    var itemVM	    [index $itemInfo 0]
    var itemHan	    [index $itemInfo 1]
    var itemSegment [index $itemInfo 2]
    var itemChunk   [index $itemInfo 3]
    var itemOffset  [index $itemInfo 4]
    
    echo [format {  %3d   %04xh:%04xh  %04xh  %04xh  %04xh   %04xh:%04xh  ^l%04xh:%04xh}
    	    	    $column
		    $seg $rowOffset
		    $group
		    $item
		    $itemVM
		    $itemSegment $itemOffset
		    $itemHan $itemChunk]
    echo
}]

##############################################################################
#				print-cell-params
##############################################################################
#
# SYNOPSIS:	Print a CellFunctionParameters block
# PASS:		address	= Address of the block (defaults to ds:si)
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	?
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/15/91	Initial Revision
#
##############################################################################
[defcmd print-cell-params {{address ds:si}} lib_app_driver.cell
{Usage:
    print-cell-params [<address ds:si>]

Examples:
    "print-cell-params"	    	print the CellFunctionParameters at ds:si
    "print-cell-params ds:bx"  	print the CellFunctionParameters at ds:bx

Synopsis:
    Print a CellFunctionParameters block

Notes:

See also:
    print-row
    print-column-element
    print-row-block
    print-cell
}
{
    #
    # First parse the address into a handle/offset.
    #
    var addr [addr-parse $address]
    var han  [handle id [index $addr 0]]
    var seg  [handle segment [index $addr 0]]
    var off  [index $addr 1]
    
    var params    [value fetch $seg:$off CellFunctionParameters]
    var flags     [field $params CFP_flags]
    var fileHan   [field $params CFP_file]

    echo
    print-file-info $fileHan
    echo
    #
    # Get the clean/dirty state.
    #
    var dirty {clean}	    	# Assume it's clean
    if {[field $flags CFPF_DIRTY]} {
    	var dirty {dirty}
    }
    
    echo [format {Cell Parameters at %04xh:%04xh, Block is %s}
    	    	$seg $off
		$dirty]

    echo
    
    #
    # Now print the row-block list, but do it in a fairly compact way.
    #
    echo {   ROW(S)   VM-BLOCK  HANDLE  ADDRESS}
    echo {----------- -------- -------  -------}

    #
    # Find the string of row-blocks that are empty and display them as such.
    #
    var rowBlocks [index [index [field $params CFP_rowBlocks] 0] 2]
    var curIndex 0
    
    var emptyCount 0
    while {$curIndex < [length $rowBlocks]} {
	var curBlock [index $rowBlocks $curIndex]
	if {$curBlock == 0} {
	    #
	    # Found another empty block...
	    #
	    var emptyCount [expr $emptyCount+1]
	} else {
	    if {$emptyCount != 0} {
	       #
	       # Spit out the empty blocks up to this point
	       # The last row is curIndex*N_ROWS_PER_ROW_BLOCK
	       #
	       echo [format {%5d-%-5d   EMPTY}
    	    	    	[expr ($curIndex-$emptyCount)*32]
			[expr ($curIndex*32)-1]]
	    }
	    #
	    # Now spit out information about the current row-block
	    #
    	    var blockHan [map-vm-handle-to-memory-handle $fileHan $curBlock]

	    echo [format {%5d-%-5d   %04xh  ^h%04xh  %04xh:0}
    	    	    	[expr $curIndex*32]
			[expr ($curIndex*32)+31]
			$curBlock
			$blockHan
			[value fetch kdata:$blockHan.HM_addr word]]

	    var emptyCount 0
	}
	var curIndex [expr $curIndex+1]
    }
    if {$emptyCount != 0} {
    	echo [format {%5d-%-5d   EMPTY}
    	    	[expr ($curIndex-$emptyCount)*32]
    	    	[expr ($curIndex*32)-1]]
    }
    echo
}]

##############################################################################
#				print-row-block
##############################################################################
#
# SYNOPSIS:	Print the contents of a row block
# PASS:		address	= Segment address of the element (defaults to ds)
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	?
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/13/91	Initial Revision
#
##############################################################################
[defcmd print-row-block {{address ds}} lib_app_driver.cell
{Usage:
    print-row-block [<address ds>]

Examples:
    "print-row-block"	    	print the row-block at ds:0
    "print-row-block es"  	print the row-block at es:0

Synopsis:
    Print a row-block

Notes:

See also:
    print-row
    print-cell-params
    print-column-element
    print-cell
}
{
    #
    # First parse the address into a handle/offset.
    #
    var addr [addr-parse $address:0]
    var han  [handle id [index $addr 0]]
    var seg  [handle segment [index $addr 0]]
    var off  [index $addr 1]
    
    #
    # Print the file information first...
    #
    var owner   [value fetch kdata:$han.HM_owner]
    var fileHan [value fetch kdata:$owner.HVM_fileHandle]

    echo
    print-file-info $fileHan
    echo

    echo [format {Row-block at %04xh:0 (^h%04xh)} $seg $han]
    
    echo {ROW(S)    CHUNK(S)    ADDRESS    SIZE  COUNT   RANGE}
    echo {-------  ---------  -----------  ----  -----  -------}

    #
    # Get the offset to the handle table
    #
    var off [expr $off+[value fetch $seg:LMBH_offset [type word]]]

    #
    # Now start processing the chunks
    #
    var curIndex 0
    var emptyCount 0
    while {$curIndex < 32} {
	var curChunk [expr $off+[expr $curIndex*2]]
	var curPtr   [value fetch $seg:$curChunk [type word]]

	if {$curPtr == 0xffff} {
	    #
	    # Found another empty row...
	    #
	    var emptyCount [expr $emptyCount+1]
	} else {
    	    if {$emptyCount != 0} {
    	    	#
	        # Spit out the empty blocks up to this point
	        #
		_cell-print-empty-row-info $emptyCount $curIndex $curChunk
	    }
	    #
	    # Now spit out information about the current row.
	    #
	    var numEntries  [value fetch $seg:$curPtr.CAH_numEntries [type word]]
	    var chunkSize   [value fetch $seg:$curPtr-2 [type word]]

	    var headerSize  [type size [sym find type ColumnArrayHeader]]
	    var entrySize   [type size [sym find type ColumnArrayElement]]

	    var firstOffset [expr $curPtr+$headerSize]
	    var lastOffset  [expr $firstOffset+(($numEntries-1)*$entrySize)]

	    echo -n [format {  %-2d        %2xh     %04xh:%04xh  %4d   %3d   }
    	    	    	$curIndex
			$curChunk
			$seg $curPtr
			$chunkSize
			$numEntries]

    	    echo -n [format {%3d}
    	    	    [value fetch $seg:$firstOffset.CAE_column [type byte]]]

    	    if {$firstOffset != $lastOffset} {
    	    	echo [format {-%-3d}
			[value fetch $seg:$lastOffset.CAE_column [type byte]]]
	    } else {
		echo
	    }
	    var emptyCount 0
	}
	var curIndex [expr $curIndex+1]
    }

    if {$emptyCount != 0} {
    	_cell-print-empty-row-info $emptyCount $curIndex $curChunk
    }
    echo
}]

##############################################################################
#				print-cell
##############################################################################
#
# SYNOPSIS:	Print information about a cell.
# PASS:		row, column, cfp
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
[defcmd print-cell {row column {cfp ds:si}} lib_app_driver.cell
{Usage:
    print-cell [row column <cfp ds:si>]

Examples:
    "print-cell 1 1"	    	print the cell <1,1>
    "print-cell 1 2 *ds:si"  	print the cell <1,2> given cfp of *ds:si

Synopsis:
    Print information about a cell

Notes:

See also:
    print-row
    print-row-block
    print-cell-params
    print-column-element
}
{
    #
    # Get the cell and item information
    #
    var rowInfo	    [get-row-info $cfp $row]
    var fileHan	    [index $rowInfo 0]
    var rowVM	    [index $rowInfo 1]
    var rowHan	    [index $rowInfo 2]
    var rowSegment  [index $rowInfo 3]
    var rowChunk    [index $rowInfo 4]
    var rowOffset   [index $rowInfo 5]
    
    var	cellInfo    [get-cell-info $rowSegment $rowOffset $column]
    var entryOffset [index $cellInfo 0]
    var group	    [index $cellInfo 1]
    var item	    [index $cellInfo 2]

    var itemInfo    [map-db-item-to-addr $fileHan $group $item]
    var itemVM	    [index $itemInfo 0]
    var itemHan	    [index $itemInfo 1]
    var itemSegment [index $itemInfo 2]
    var itemChunk   [index $itemInfo 3]
    var itemOffset  [index $itemInfo 4]

    #
    # Parse the cfp address into something useful too.
    #
    var cfpAddr    [addr-parse $cfp]
    var cfpHan     [handle id [index $cfpAddr 0]]
    var cfpSegment [handle segment [index $cfpAddr 0]]
    var cfpOffset  [index $cfpAddr 1]
    
    #
    # Spit out information about the file and parameters.
    #
    echo

    echo -n [format {Cell <%d,%d>    }
    	    	$row
		$column]

    #
    # Print the file info out...
    #
    print-file-info $fileHan
    echo
    	    	
    echo [format {Cell Parameters at %04xh:%04xh (^h%04xh:%04xh)}
    	    	$cfpSegment $cfpOffset $cfpHan $cfpOffset]

    echo

    echo { ROW    ROW-ADDR    ENTRY  GROUP  ITEM   VM-BLK  CELL-ADDR     HAN/CHUNK}
    echo {-----  -----------  -----  -----  -----  ------  -----------  -------------}

# 12345  1234h:1234h  1234h  2345h  1234h  1234h   1234h:1234h  ^l1234h:1234h

    #
    # Row information.
    #
    echo -n [format {%5d  } $row]
    
    if {$rowSegment == 0} {
    	echo -n {<EMPTY ROW BLOCK>}
    } elif {$rowOffset == -1} {
    	echo -n {<EMPTY ROW>}
    } else {
    	echo -n [format {%04xh:%04xh  } $rowSegment $rowOffset]
    }

    #
    # Entry information next
    #
    if {$entryOffset != 0} {
    	echo -n [format {%04xh  %04xh  %04xh  %04xh   }
			$entryOffset
			$group
			$item
			$itemVM]

    	if {$itemOffset != -1} {
    	    echo [format {%04xh:%04xh  ^l%04xh:%04xh}
	    	    $itemSegment $itemOffset
		    $itemHan $itemChunk]
    	} else {
	    echo {  <CELL BLOCK NOT LOADED>}
	}
    } else {
    	echo {  <CELL DOES NOT EXIST>}
    }
    
    echo
}]

##############################################################################
#			   print-file-info
##############################################################################
#
# SYNOPSIS:	Print information about a file
# PASS:		fileHan
# CALLED BY:	print-cell
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
[defsubr print-file-info {fileHan}
{
    var fileInfo    [get-vm-file-info $fileHan]

    var fileName    [index $fileInfo 0]
    var fileOwner   [index $fileInfo 1]
    var fileFlags   [index $fileInfo 2]
    var fileDrive   [index $fileInfo 3]
    var fileDisk    [index $fileInfo 4]
    
    echo [format {File %s (%04xh)    Disk <%s> in Drive %c}
		$fileName
		$fileHan
    	    	$fileDisk
		[expr 65+$fileDrive]]
}]

##############################################################################
#			   print-file-info-from-block
##############################################################################
#
# SYNOPSIS:	Print information about a file given a block in the file.
# PASS:		han
# CALLED BY:	?
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
[defsubr print-file-info-from-block {han}
{
    #
    # Print the file information first...
    #
    var owner   [value fetch kdata:$han.HM_owner]
    var fileHan [value fetch kdata:$owner.HVM_fileHandle]

    print-file-info $fileHan
}]

    
##############################################################################
#				_cell-print-empty-row-info
##############################################################################
#
# SYNOPSIS:	Print information about a set of empty rows
# PASS:		emptyCount, curIndex, curChunk
# CALLED BY:	print-row-block
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
[defsubr _cell-print-empty-row-info {emptyCount curIndex curChunk}
{
    if {$emptyCount == 1} {
	echo [format {  %2d     %2xh        EMPTY}
		[expr $curIndex-$emptyCount]
		[expr $curChunk-2]]
    } else {
	echo [format {%2d...%-2d  %2xh...%2xh     EMPTY}
		[expr $curIndex-$emptyCount]
		[expr $curIndex-1]
		[expr $curChunk-($emptyCount*2)]
		[expr $curChunk-2]]
    }
}]

##############################################################################
#				_cell-find-chunk
##############################################################################
#
# SYNOPSIS:	Find a chunk handle for a given offset into an lmem block
# PASS:		seg, off
# CALLED BY:	print-row, print-column-element
# RETURN:	chunk handle for the offset, 0 for none found
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
[defsubr _cell-find-chunk {seg off}
{
    var table [value fetch $seg:LMBH_offset [type word]]
    var count [value fetch $seg:LMBH_nHandles [type word]]
    
    if {$count > 32} {
    	#
	# This can't possible be a row
	#
	return 0
    }

    while {$count > 0} {
    	var base [value fetch $seg:$table [type word]]
	var size [value fetch $seg:$base-2 [type word]]
	var size [expr $size-2]

	if {($off >= $base) && ($off < [expr $base+$size])} {
	    #
	    # Found the chunk handle
	    #
	    return $table
    	}
	var table [expr $table+2]
    	var count [expr $count-1]
    }
    #
    # Didn't find the chunk handle
    #
    return 0
}]

##############################################################################
#			get-row-info
##############################################################################
#
# SYNOPSIS:	Get information about a row
# PASS:		cfp, row
# CALLED BY:	print-cell
# RETURN:	list of row info
#   	    	  0: file handle
#   	    	  1: vm block handle of the row block	    (0 for none)
#   	    	  2: memory handle of the row block 	    (0 for not loaded)
#   	    	  3: segment address of the row block
#   	    	  4: chunk handle for the row
#   	    	  5: offset of the row	    	    	    (-1 for empty)
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
[defsubr get-row-info {cfp row}
{
    #
    # Convert the cfp to an address we can use.
    #
    var cfpAddr    [addr-parse $cfp]
    var cfpHan     [handle id [index $cfpAddr 0]]
    var cfpSegment [handle segment [index $cfpAddr 0]]
    var cfpOffset  [index $cfpAddr 1]
    
    #
    # Fetch the file
    #
    var fileHan [value fetch $cfpSegment:$cfpOffset.CFP_file [type word]]
    
    #
    # Fetch the vm-block of the row
    #
    var off   [expr 2*($row/32)]
    var rowVM [value fetch $cfpSegment:$cfpOffset.CFP_rowBlocks+$off [type word]]
    
    #
    # Map the vm block to a memory handle
    #
    var rowHan 0
    if {$rowVM != 0} {
        var rowHan [map-vm-handle-to-memory-handle $fileHan $rowVM]
    }
    
    #
    # Assume a lot of things will be zero...
    #
    var rowSegment  0
    var rowChunk    0
    var rowOffset   -1

    #
    # Get the handle and offset
    #
    if {$rowHan != 0} {
	#
	# Row-block exists. Get the segment/chunk
	#
	var hdrSize    [type size [sym find type LMemBlockHeader]]

	var rowSegment [handle segment [handle lookup $rowHan]]
	var rowChunk   [expr $hdrSize+(2*($row%32))]
    	var rowOffset  [value fetch $rowSegment:$rowChunk [type word]]
    }
    return [list $fileHan $rowVM $rowHan $rowSegment $rowChunk $rowOffset]
}]

##############################################################################
#			get-cell-info
##############################################################################
#
# SYNOPSIS:	Get information about a cell
# PASS:		rowSegment, rowOffset, column
# CALLED BY:	print-cell
# RETURN:	list of cell info
#   	    	  0: offset to the entry    	    	    (0 for none)
#   	    	  1: group
#   	    	  2: item
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
[defsubr get-cell-info {rowSegment rowOffset column}
{
    var entryOffset 0
    var group	    0
    var item	    0

    if {$rowOffset != -1} {
    	#
	# The row exists, search it...
	#
	var count [value fetch $rowSegment:$rowOffset.CAH_numEntries [type word]]
	var off	  [expr $rowOffset+[type size [sym find type ColumnArrayHeader]]]
	
	var entryType [sym find type ColumnArrayElement]

	while {$count != 0} {
	    var entry [value fetch $rowSegment:$off $entryType]
	    
	    if {[field $entry CAE_column] == $column} {
	    	#
		# Found the entry
		#
		var entryOffset [expr $off-$rowOffset]
		var group   	[field [field $entry CAE_data] DBI_group]
		var item    	[field [field $entry CAE_data] DBI_item]

		var count 0
	    } else {
		var off [expr $off+[type size $entryType]]
	    	var count [expr $count-1]
	    }
    	}
    }
    return [list $entryOffset $group $item]
}]

##############################################################################
#			map-vm-handle-to-memory-handle
##############################################################################
#
# SYNOPSIS:	Map a vm-block handle to a memory handle
# PASS:		file, vm-block
# CALLED BY:	?
# RETURN:	memory handle address	    (0 for not loaded)
# SIDE EFFECTS:	?
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/19/91	Initial Revision
#
##############################################################################
[defsubr map-vm-handle-to-memory-handle {fileHan vmBlock}
{
    var vmFileHan [value fetch kdata:$fileHan.HF_otherInfo]
    var hdr       [value fetch kdata:$vmFileHan.HVM_headerHandle]
    var vmHanType [sym find type VMBlockHandle]
    var blockInfo [value fetch ^h$hdr:$vmBlock $vmHanType]
    var memHan	  [field $blockInfo VMBH_memHandle]
    
    return $memHan
}]

##############################################################################
#			   get-vm-file-info
##############################################################################
#
# SYNOPSIS:	Get information about a vm file
# PASS:		fileHan
# CALLED BY:	?
# RETURN:	List of information:
#   	    	    0: file name (string)
#   	    	    1: owner
#   	    	    2: flags
#   	    	    3: drive number
#   	    	    4: disk name (string)
# SIDE EFFECTS:	?
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 8/19/91	Initial Revision
#
##############################################################################
[defsubr get-vm-file-info {fileHan}
{
    var fileInfo [value fetch kdata:$fileHan [sym find type HandleFile]]

    #
    # Some easy stuff is just located in the file handle
    #
    var fileDrive [field $fileInfo HF_drive]
    var fileFlags [field $fileInfo HF_accessFlags]
    var fileOwner [field $fileInfo HF_owner]
    
    var fileName  {Unknown}
    var diskName  {Unknown}

    #
    # Get the file name. We need to fetch the sft entry...
    #
    var sfn 	 [field $fileInfo HF_sfn]
    
    var sftHeaderType [sym find type SFTBlockHeader]
    var sftEntryType  [sym find type SFTEntry]

    [for {
    	    var base [value fetch sftStart]
    	 }
	 {$sfn != 0}
	 {
	    var base [field $sftBlock SFTBH_next]
	 }
     {
    	#
	# Figure out the number of entries in this block.
	# If the current entry falls in this block, get it...
	#
	var addr     [expr $base>>16]:[expr $base&0xffff]
	var sftBlock [value fetch $addr $sftHeaderType]
	
	var limit    [field $sftBlock SFTBH_numEntries]
	
	if {$sfn <= $limit} {
	    #
	    # Entry is in this block
	    #
	    var headerSize [type size $sftHeaderType]
	    var entrySize  [type size $sftEntryType]
	    var offset	   [expr ($entrySize*$sfn)+$headerSize]
    	    var sft        [value fetch $addr+$offset $sftEntryType]

    	    var fileName   [format {%s.%s}
    	    	    [mapconcat c [range [field $sft SFTE_name] 0 7] {var c}]
    	    	    [mapconcat c [range [field $sft SFTE_name] 8 end] {var c}]
    	    	    ]
	    var sfn    0
	} else {
	    var sfn [expr $sfn-$limit]
	}
    }]
    
    #
    # Get some disk information.
    #
    var diskHan  [field $fileInfo HF_disk]
    var diskInfo [value fetch kdata:$diskHan [sym find type HandleDisk]]
    
    var fileDisk [field $diskInfo HD_volumeLabel]
    var fileDisk [mapconcat c [range $fileDisk 0 10] {var c}]

    #
    # Return a list of the information.
    #
    return [list $fileName $fileOwner $fileFlags $fileDrive $fileDisk]
}]
