##############################################################################
#
# 	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat System Library -- VM analysis
# FILE: 	vm.tcl
# AUTHOR: 	Adam de Boor, Mar 11, 1990
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/11/90		Initial Revision
#
# DESCRIPTION:
#	Functions to examine VM file structures.
#
#	$Id: vm.tcl,v 1.30.2.1 97/03/29 11:27:43 canavese Exp $
#
###############################################################################
##############################################################################
#				map-file-to-vm-handle
##############################################################################
#
# SYNOPSIS:	Given the ID of a file handle, return the id of the
#   	    	associated VM handle. If the passed handle is a VM handle,
#   	    	it is returned.
# PASS:		h   = handle ID of type SIG_FILE or SIG_VM
# CALLED BY:	pvmt, pvmb, pdb
# RETURN:	the ID of the associated SIG_VM handle
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/11/90		Initial Revision
#
##############################################################################
[defsubr map-file-to-vm-handle {h}
{
    [case [format {%02xh} [value fetch kdata:$h.HG_type]] in
    	fch {return $h}
	fdh {return [value fetch kdata:$h.HF_otherInfo]}
	default {error {not vm or file handle}}]
}]
##############################################################################
#				get-map-block-from-vm-file
##############################################################################
#
# SYNOPSIS:	Given a VM file handle return the map block
# PASS:		h   = handle ID of type SIG_FILE or SIG_VM
# CALLED BY:	utility (pwritedoc, ...)
# RETURN:	the vm block handle of the map block
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/11/90		Initial Revision
#
##############################################################################
[defsubr get-map-block-from-vm-file {h}
{
    var hdr [value fetch kdata:[map-file-to-vm-handle $h].HVM_headerHandle]
    return [value fetch ^h$hdr:VMH_mapBlock]
}]
##############################################################################
#				pvmt
##############################################################################
#
# SYNOPSIS:	Produce a map of the blocks allocated in a VM file
# PASS:		h   = handle ID of the file handle or SIG_VM handle for the
#		      file.
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	a map is printed
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/11/90		Initial Revision
#
##############################################################################
[defcommand pvmt {args} {system.vm lib_app_driver.vm}
{Usage:
    pvmt [-p] [-a] [-s] [-c] (<handle> | <segment>)

Examples:
    "pvmt bx"	    	    	Print out all used blocks for the open
				VM file whose file handle is in BX
    "pvmt -as ds"   	    	Print out all blocks for the open VM file
				the segment of whose header block is in DS.

Synopsis:
    Prints out a map of the VM block handles for a VM file.

Notes:
    * The -p flag will only print out blocks that have the Preserve
      flag set.  Useful for examining object blocks in GeoCalc files,
      for example

    * The -a flag causes pvmt to print out all block handles, not just those
      that have been allocated. The other two types of block handles are
      "assigned" (meaning they're available for use, but currently are tracking
      unused space in the file) and "unassigned" (they're available for use).

    * The -s indicates the final argument is a segment, not a file handle. This
      is used only if you're inside the VM subsystem of the kernel, where DS
      always holds the segment of the header block for the file.

    * The -c flag requests a count of the different types of blocks at the end
      of the printout.
      
    * The blocks are printed in a table with the following columns:
	han	    	VM block handle (in hex)
	flags    	D if the block is dirty, C if the block is clean, - if
			the block is non-resident, L if the block is LMem, B if
			the block has a backup, P if the preserve handle bit is
			set for the block, ! if the block is locked, U if the
			block is a member of the set of "ungrouped" DB group
			blocks and can accept more DB items, Z if the block is
    			compressed.
	memhan  	Associated memory handle. Followed by "(d)" if the
			memory for the block was discarded but the handle
			retained. Followed by (s) if the memory has been swapped
			out.
	block type	The type of block:
			VMBT_USED	a normal in-use block,
			VMBT_DUP 	an in-use block that has been backed up
					or allocated since the last call to
					VMSave
			VMBT_BACKUP	a place-holder to keep track of the
					previous version of a VMBT_DUP block.
					The uid is the VM block handle to which
					the file space used to belong.
			VMBT_ZOMBIE	a block that has been freed since the
					last VMSave. The handle is preserved in
					case of a VMRevert (a VMBT_BACKUP block
					retains the file space).
	uid	    	The "used ID" bound to the block.
	size    	Number of bytes allocated for the block in the file.
	pos	   	The position of those bytes in the file.

See also:
    pgs.
}
{
    var allBlocks 0 isSegment 0 countem 0 ec 0 preserve 0 noblocks 0

    var h [eval [concat concat [map i $args {
    	if {[string match $i -*]} {
	    foreach f [explode $i] {
	    	[case $f in
    	    	    a	{var allBlocks 1}
    	    	    s	{var isSegment 1}
    	    	    c	{var countem 1}
    	    	    p	{var preserve 1}
		    e	{var ec 1}
		    n	{var noblocks 1}]
    	    }
    	} else {
	    getvalue $i
    	}
    }]]]
    
    if {$isSegment} {
    	var hdr [handle id [handle find $h:0]]
    } else {
    	var h [map-file-to-vm-handle $h]
	#
	# Fetch the header handle for fetching VMBlockHandles
	#
	var hdr [value fetch kdata:$h.geos::HandleVM::HVM_headerHandle]
    }

    if {$hdr == 0} {
    	error {header not resident, sorry}
    }

    # Print the table header first
    if {!$noblocks} {
        echo {han:  flags     memhan       block type    uid      size       pos}
        echo {------------------------------------------------------------------}
    }
    #
    # Set up variables needed in the loop:
    #	$end	one beyond the last valid VMBlockHandle in the header
    #	$t  	type descriptor for fetching the VMBlockHandles
    #	$bts	type descriptor for mapping the VMBH_sig field
    #	$inc	size of a VMBlockHandle for incrementing our offset
    #
    var end [value fetch ^h$hdr:geos::VMHeader::VMH_lastHandle]
    var t [sym find type geos::VMBlockHandle]
    var ft [sym find type geos::VMFreeBlockHandle]
    var bts [sym find type geos::VMBlockType]
    var inc [type size $t] used 0 ass 0 unass 0 res 0
    
    [for {var i [getvalue geos::VMHeader::VMH_blockTable]}
	 {$i < $end && !$noblocks}
	 {var i [expr $i+$inc]}
    {
    	#
	# Fetch the next block descriptor
	#
    	var b [value fetch ^h$hdr:$i $t]
        var fl [field $b VMBH_flags]

	#
	# If we only want to look at "Preserve" blocks, then make sure
	# this one is of that type
	#
	if {($preserve==0) ||  ([field $fl VMBF_PRESERVE_HANDLE]==1)} {
	    #
	    # If the VMBH_sig maps to something in VMBlockType, the block is
	    # in-use
	    #
	    var bt [type emap [field $b VMBH_sig] $bts]
	    if {![null $bt]} {
		#
		# Figure the value for the D/C field and, if the block
		# has a memory handle, whether the block is discarded.
		#
		var h [field $b VMBH_memHandle]
		if {$h != 0} {
		    if {[field [value fetch kdata:$h.HM_flags] HF_DISCARDABLE]} {
			var D C
		    } else {
			var D D
		    }
		    if {[field [value fetch kdata:$h.HM_flags] HF_DISCARDED]} {
			var s (d)
		    } elif {[value fetch kdata:$h.HM_addr] == 0} {
			var s (s) res [expr $res+1]
		    } else {
			var s {} res [expr $res+1]
		    }
		} else {
		    var D - s {}
		}
		var fsz [field $b VMBH_fileSize]
		if {$fsz < 0} {
		    var fsz [expr 65536+$fsz]
		}
		var uid [penum geos::SystemVMID [field $b VMBH_uid]]
		[case $uid in
		    DB_MAP_ID {var uid {*Map*}}
		    DB_GROUP_ID {var uid {Group}}
		    DB_ITEM_BLOCK_ID {var uid {ItemB}}
		    SVMID_HA_DIR_ID {var uid {HADir}}
		    SVMID_HA_BLOCK_ID {var uid {HADat}}
		    nil {
			var uid [format {%04xh} [field $b VMBH_uid]]
			if {$uid == adebh} {
			    var uid Headr
			}
		    }
		]
		# special extraction of VMBF_UNGROUPED_AVAIL to allow use with
		# kernel that doesn't have this flag defined...
    	    	var u [field $fl VMBF_UNGROUPED_AVAIL]
		if {[null $u]} {
		    var u 0
    	    	}
			
		echo [format {%04xh:  %s%1s%1s%1s%1s%1s%1s ^h%04xh%3s  %12s   %s    %5d  %8d}
			$i $D 
			[if {[field $fl VMBF_COMPRESSED]} {concat Z}]
			[if {[field $fl VMBF_LMEM]} {concat L}]
			[if {[field $fl VMBF_HAS_BACKUP]} {concat B}]
			[if {[field $fl VMBF_PRESERVE_HANDLE]} {concat P}]
			[if {($h != 0) &&
			     ([value fetch kdata:$h.HM_lockCount] != 0)} {concat !}]
			[if {$u} {concat U}]
			$h $s $bt $uid $fsz
			[field $b VMBH_filePos]]
		case $bt in {VMBT_USED VMBT_DUP} {var used [expr $used+1]}
	    } elif {$allBlocks} {
		var b [value fetch ^h$hdr:$i $ft]
		echo [format {%04xh:  %s%1s%1s     ->%04xh%3s  %12s   %04xh    %5d  %8d}
			    $i - {} {}
			    [field $b VMFBH_nextPtr] {}
			    [if {[field $b VMFBH_fileSize] != 0}
			     {[var ass [expr $ass+1]] [concat assigned]}
			     {[var unass [expr $unass+1]] [concat unassigned]}]
			    0 [field $b VMFBH_fileSize] [field $b VMFBH_filePos]]
	    } elif {$countem} {
		if {[value fetch ^h$hdr:$i.VMFBH_fileSize] != 0} {
		    var ass [expr $ass+1]
		} else {
		    var unass [expr $unass+1]
		}
	    }
	}
    }]
    if {$countem && !$noblocks} {
    	[foreach i
	    {{Used used} {Resident res} {Assigned ass} {Unassigned unass}}
    	{
	    echo [format {%30s: %d} [concat [index $i 0] blocks] 
	    	    [var [index $i 1]]]
    	}]
    }
    if {$ec} {
    	#
	# First check free-list integrity
	#
    	echo -n Checking free-list integrity...
	flush-output
    	var prev 0 n 0
    	[for {var i [value fetch ^h$hdr.VMH_assignedPtr]}
	     {$i != 0}
	     {var i $next n [expr $n+1]}
    	{
    	    echo -n [format %04xh $i]
	    flush-output
	    wmove -5 +0
	    
    	    var next [value fetch ^h$hdr:$i.VMFBH_nextPtr]
	    if {[value fetch ^h$hdr:$i.VMFBH_prevPtr] != $prev} {
	    	echo [format {error: %04xh: prev pointer should be %04xh, is %04xh}
		    	$i $prev [value fetch ^h$hdr:$i.VMFBH_prevPtr]]
    	    }
    	    if {$next} {
	    	var end [expr [value fetch ^h$hdr:$i.VMFBH_filePos]+[value fetch ^h$hdr:$i.VMFBH_fileSize]]
	    	if {$end > [value fetch ^h$hdr:$next.VMFBH_filePos]} {
		    echo [format {error: %04xh: end position (%d) overlaps next free block start (%d)}
    	    	    	    $i $end [value fetch ^h$hdr:$next.VMFBH_filePos]]
    	    	} elif {$end == [value fetch ^h$hdr:$next.VMFBH_filePos]} {
		    echo [format {error: %04xh: should have been coalesced with %04xh}
    	    	    	    $i $next]
    	    	}
    	    }
	    var prev $i
    	}]
	echo

    	if {$n != [value fetch ^h$hdr:VMH_numAssigned]} {
	    echo [format {error: %d free blocks in list, should be %d}
	    	    $n [value fetch ^h$hdr:VMH_numAssigned]]
    	}
	
	#
	# Now make sure no block overlaps any other, and that all blocks
	# form a continuous range of file space without any gaps.
	#
    	echo -n Looking for overlaps & gaps...
	flush-output
    	#
	# First gather all the starts & ends of all the blocks that have
	# file space.
	#
    	var end [value fetch ^h$hdr:geos::VMH_lastHandle]
    	var fblocks
    	[for {var i [getvalue VMH_blockTable]}
	     {$i < $end}
	     {var i [expr $i+$inc]}
    	{
    	    echo -n [format %04xh $i]
	    flush-output
	    wmove -5 +0

	    var s [value fetch ^h$hdr:$i.VMFBH_filePos]
	    if {$s == 0} {
	    	continue
    	    }
	    if {[value fetch ^h$hdr:$i.VMBH_sig] & 1} {
	    	var e [expr $s+[value fetch ^h$hdr:$i.VMBH_fileSize]]
		var type used
    	    } else {
	    	var e [expr $s+[value fetch ^h$hdr:$i.VMFBH_fileSize]]
		var type free
    	    }
    	    var fblocks [concat $fblocks [list [list $s $e $i $type]]]
	}]
    	#
	# Now loop through the sorted version of the list we just
	# constructed. Each entry's start should match the previous entry's
	# end value.
	#
    	var last [list 0 [size VMFileHeader] 0 fake]
	foreach b [sort -n $fblocks] {
	    [if {[index $b 0] < [index $last 1] && 
	    	 [index $b 1] >= [index $last 0]}
    	    {
	    	echo [format
		    	{error: %04xh: %s block overlaps with %s block %04xh}
		    	[index $b 2] [index $b 3] [index $last 3] 
			[index $last 2]]
    	    } elif {[index $last 1] != [index $b 0]} {
	    	echo [format {error: %04xh: %s block has no following block (next block begins at %d)}
		    	    [index $last 2] [index $last 3] [index $b 0]]
    	    }]
	    var last $b
    	}
	echo
    }
}]

##############################################################################
#				pvmb
##############################################################################
#
# SYNOPSIS:	Print the VMBlockHandle for a VM block
# PASS:		h   = SIG_FILE/SIG_VM handle for the VM file
#   	    	b   = VM block handle
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	The VMBlockHandle for the block is printed
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/11/90		Initial Revision
#
##############################################################################
[defcommand pvmb {h b} {system.vm lib_app_driver.vm}
{Prints out the VMBlockHandle for a VM block given the file handle H and the
VM block handle B}
{
    var h [map-file-to-vm-handle $h]
    _print geos::VMBlockHandle ^h[value fetch kdata:$h.HVM_headerHandle]:$b
}]

##############################################################################
#				pdb
##############################################################################
#
# SYNOPSIS:	Produce pertinent information for a DBase block in a VM file
# PASS:		h   = SIG_FILE/SIG_VM handle for the dbase file
#   	    	b   = VM block handle of the block
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/11/90		Initial Revision
#
##############################################################################
[defcommand pdb {h b} {lib_app_driver.dbase}
{Produces useful information about a DBase block. For now, only info about the
map block of the DBase file is produced. First arg H is the SIG_FILE or SIG_VM
handle's ID. Second arg B is the VM block handle for which information is
desired}
{
    var h [map-file-to-vm-handle $h]
    var hdr ^h[value fetch kdata:$h.HVM_headerHandle]
    var b [value fetch {geos::VMBlockHandle $hdr:$b}]

    var bt [type emap [field $b VMBH_sig] [sym find type VMBlockType]]
    [case $bt in
    	{VMBT_USED VMBT_DUP} {}
	VMBT_BACKUP {error {given block is a backup copy and not in memory}}
	VMBT_ZOMBIE {error {given block has been freed and is not in memory}}
	nil {error {given block is not in-use}}]

    if {[field $b VMBH_memHandle] == 0} {
    	error {given block is not in memory}
    }
    
    [case [type emap [field $b VMBH_uid] [sym find type SystemVMID]] in
    	DB_ITEM_BLOCK_ID {
	    #
	    # Item block. Print the header and info and do an lhwalk of it
	    #
	}
	DB_GROUP_ID {
	    #
	    # Group block. Print both lists in the thing
	    #
	}
	DB_MAP_ID {
	    #
	    # Map block. Describe the file
	    #
    	    require db-to-addr dbwatch
    	    var mb [value fetch ^h[field $b VMBH_memHandle]
	    	    	[sym find type DBMapBlock]]

    	    echo MapBlock:
	    echo [format {\tMemory handle = ^h%04xh} [field $mb DBMB_handle]]
	    echo [format {\tMap group block = %xh} [field $mb DBMB_mapGroup]]
	    echo [format {\tMap item = %xh} [field $mb DBMB_mapItem]]
    	    echo [format {\tMap address = %s}
	    	    [db-to-addr $h [field $mb DBMB_mapGroup] 
		    	    	[field $mb DBMB_mapItem]]]
	    echo [format {\tCurrent group for ungrouped mode = %xh} 
	    	    	[field $mb DBMB_ungrouped]]
	    
    	}
    	default {
	    error {given block is not a DBase block}
	}
    ]
}]

[defsubr checkvm {h}
{
    var h [map-file-to-vm-handle $h]
    var hdr [value fetch kdata:$h.HVM_headerHandle]
    
    var off [expr [index [sym get [sym find field VMH_blockTable]] 0]/8]
    var vmbhSize [size VMBlockHandle]
    var n [expr ([value fetch ^h$hdr:VMH_lastHandle]-$off)/$vmbhSize]
    
    var blocks [sort -n [
    	map i [value fetch ^h$hdr:VMH_blockTable
	    	     [type make array $n [sym find type VMBlockHandle]]]
    	{
    	    var j $off off [expr $off+$vmbhSize]
	    concat [field $i VMBH_filePos] $j [range $i 0 4]
    	}]]

    var last {} prevAssigned 0
    foreach i $blocks {
    	if {[index $i 0] != 0} {
	    if {![null $last]} {
	    	var vmbh [range $last 2 end]
	    	if {[field $vmbh VMBH_sig] & 1} {
		    var size [field $vmbh VMBH_fileSize]
		    if {$size < 0} {
		    	var size [expr 65536+$size]
    	    	    }
    	    	} else {
		    var size [value fetch ^h$hdr:[index $last 1].VMFBH_fileSize]
    	    	    if {$prevAssigned && [value fetch ^h$hdr:$prevAssigned.VMFBH_nextPtr] != [index $i 1]} {
    	    	    	echo [format {%04xh: assigned list out of order. prev = %04xh w/ nextPtr of %04xh}
			    	[index $i 1] $prevAssigned
				[value fetch ^h$hdr:$prevAssigned.VMFBH_nextPtr]]
    	    	    }
    	    	    var prevAssigned [index $i 1]
    	    	}
		var sb [expr [index $last 0]+$size]
		if {[index $i 0] != $sb} {
		    echo [format {%04xh: filePos == %d, s/b %d (prev is %04xh)}
			    [index $i 1] [index $i 0] $sb [index $last 1]]
		}
    	    }
	    var last $i
    	}
    }
}]
    	
##############################################################################
#				ensure-vm-block-resident
##############################################################################
#
# SYNOPSIS:	Make sure that a VM block for a file is loaded so we can use
#		^v to reference into it.
# PASS:		file	= handle of the open VM file
#		block	= VM block handle
# CALLED BY:	EXTERNAL
# RETURN:	nothing
# SIDE EFFECTS:	error is declared if block handle is invalid
#		machine may be continued to call VMLock and VMUnlock
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	9/20/94		Initial Revision
#
##############################################################################
[defsubr ensure-vm-block-resident {file block}
{
    if {$block >= 32 && (($block-32)%12) == 0} {
	if {[catch {addr-parse ^v$file:$block} addr] != 0} {
	    var dstate 0
    	} else {
	    var dstate [handle state [index $addr 0]]
    	}
	if {($dstate & 0x0021) == 0} {
	    #
	    # If the handle isn't resident & isn't swapped, then lock/unlock
	    # it. 
	    #
		save-state
		if {[call-patient VMLock bx $file ax $block]} {
		    if {![call-patient VMUnlock]} {
			echo {ERROR: unable to to call VMUnlock}
			top-level-read
    	    	    }
		    discard-state
		    discard-state
		} else {
    	    	    echo {ERROR: unable to to call VMLock}
		    top-level-read
		    discard-state
		}
		restore-state
	}
    } elif {$block != 0} {
    	error {invalid VM block handle}
    }
}]

