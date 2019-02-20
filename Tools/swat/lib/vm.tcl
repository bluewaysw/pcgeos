##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
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
#	$Id: vm.tcl,v 1.4 90/06/27 12:06:19 steve Exp $
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
# CALLED BY:	pvmt, pvmb, prdb
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
    [case [format {%02x} [value fetch kdata:$h.HG_type]] in
    	fc {return $h}
	fd {return [value fetch kdata:$h.HF_otherInfo]}
	default {error {not vm or file handle}}]
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
[defdsubr pvmt {args} output|kernel
{Produces a map of the blocks allocated in a VM file given either the SIG_VM's
handle ID or a SIG_FILE's handle ID. Only the used blocks are listed. The
columns of the table are as follows:
    han	    	VM block handle (in hex)
    flags    	D if the block is dirty, C if the block is clean, - if the
		block is non-resident, L if the block is LMem, B if the block
		has a backup.
    memhan  	Associated memory handle. Followed by "(d)" if the memory for
		the block was discarded.
    block type	The type of block:
    	    	    VMBT_USED	a normal in-use block,
		    VMBT_DUP 	an in-use block that has been backed up or
				allocated since the last call to VMSave
		    VMBT_BACKUP	a place-holder to keep track of the previous
				version of a VMBT_DUP block. The uid is the
				VM block handle to which the file space used
				to belong.
		    VMBT_ZOMBIE	a block that has been freed since the last
				VMSave. The handle is preserved in case of a
				VMRevert.
    uid	    	The "used ID" bound to the block.
    size    	Number of bytes allocated for the block in the file.
    pos	   	The position of those bytes in the file.

Optional flags (preceded by '-') may appear before the handle:

    -a	    	Print all blocks, including assigned and unassigned blocks.
    -s	    	Handle is the segment of the header block, not the id of
    	    	a file or VM handle. E.g. 'pvmt -s ds' will print the 
		block table for the file whose VM header block is pointed
		to by ds
}
{
    var allBlocks 0 isSegment 0 countem 0

    var h [eval [concat concat [map i $args {
    	if {[string match $i -*]} {
	    foreach f [explode $i] {
	    	[case $f in
    	    	    a	{var allBlocks 1}
    	    	    s	{var isSegment 1}
    	    	    c	{var countem 1}]
    	    }
    	} else {
	    var i
    	}
    }]]]
    
    if {$isSegment} {
    	var hdr [handle id [handle find $h:0]]
    } else {
    	var h [map-file-to-vm-handle $h]
	#
	# Fetch the header handle for fetching VMBlockHandles
	#
	var hdr [value fetch kdata:$h.HVM_headerHandle]
    }

    # Print the table header first
    echo {han: flags  memhan       block type   uid      size       pos}
    echo {-------------------------------------------------------------}
    #
    # Set up variables needed in the loop:
    #	$end	one beyond the last valid VMBlockHandle in the header
    #	$t  	type descriptor for fetching the VMBlockHandles
    #	$bts	type descriptor for mapping the VMBH_sig field
    #	$inc	size of a VMBlockHandle for incrementing our offset
    #
    var end [value fetch ^h$hdr:VMH_lastHandle]
    var t [sym find type VMBlockHandle]
    var ft [sym find type VMFreeBlockHandle]
    var bts [sym find type VMBlockType]
    var inc [type size $t] used 0 ass 0 unass 0 res 0
    
    [for {var i [index [addr-parse VMH_blockTable] 1]}
	 {$i < $end}
	 {var i [expr $i+$inc]}
    {
    	#
	# Fetch the next block descriptor
	#
    	var b [value fetch ^h$hdr:$i $t]
	
    	#
	# If the VMBH_sig maps to something in VMBlockType, the block is in-use
	#
    	var bt [type emap [field $b VMBH_sig] $bts]
	if {![null $bt]} {
    	    #
	    # Figure the value for the D/C field and, if the block has a memory
	    # handle, whether the block is discarded.
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
	    var fl [field $b VMBH_flags]
	    echo [format {%03x:  %s%1s%1s  ^h%04xh%3s    %-12s %04x    %5d  %8d}
		    $i $D 
		    [if {[field $fl VMBF_LMEM]} {concat L}]
		    [if {[field $fl VMBF_HAS_BACKUP]} {concat B}]
    	    	    $h $s $bt [field $b VMBH_uid] [field $b VMBH_fileSize]
		    [field $b VMBH_filePos]]
    	    case $bt in VMBT_USED|VMBT_DUP {var used [expr $used+1]}
    	} elif {$allBlocks} {
	    var b [value fetch ^h$hdr:$i $ft]
	    echo [format {%03x:  %s%1s%1s  ->%04xh%3s    %-12s %04x    %5d  %8d}
	    	    	$i - {} {}
			[field $b VMFBH_nextPtr] {}
			[if {[field $b VMFBH_fileSize] != 0}
			 {[var ass [expr $ass+1]] [concat assigned]}
			 {[var unass [expr $unass+1]] [concat unassigned]}]
			0 [field $b VMFBH_fileSize] [field $b VMFBH_filePos]]
    	}
    }]
    if {$countem} {
    	[foreach i
	    {{Used used} {Resident res} {Assigned ass} {Unassigned unass}}
    	{
	    echo [format {%30s: %d} [concat [index $i 0] blocks] 
	    	    [var [index $i 1]]]
    	}]
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
[defdsubr pvmb {h b} output|kernel
{Prints out the VMBlockHandle for a VM block given the file handle H and the
VM block handle B}
{
    var h [map-file-to-vm-handle $h]
    print VMBlockHandle (*kdata:$h.HVM_headerHandle)+$b
}]

##############################################################################
#				prdb
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
[defdsubr prdb {h b} output|dbase
{Produces useful information about a DBase block. For now, only info about the
map block of the DBase file is produced. First arg H is the SIG_FILE or SIG_VM
handle's ID. Second arg B is the VM block handle for which information is
desired}
{
    var h [map-file-to-vm-handle $h]
    var b [value fetch {VMBlockHandle (*kdata:$h.HVM_headerHandle)+$b}]
    var hdr ^h[value fetch kdata:$h.HVM_headerHandle]

    var bt [type emap [field $b VMBH_sig] [sym find type VMBlockType]]
    [case $bt in
    	VMBT_USED|VMBT_DUP {}
	VMBT_BACKUP {error {given block is a backup copy and not in memory}}
	VMBT_ZOMBIE {error {given block has been freed and is not in memory}}
	nil {error {given block is not in-use}}]

    if {[field $b VMBH_memHandle] == 0} {
    	error {given block is not in memory}
    }
    
    [case [format %04x [field $b VMBH_uid]] in
    	3333 {
	    #
	    # Item block. Print the header and info and do an lhwalk of it
	    #
	}
	2222 {
	    #
	    # Group block. Print both lists in the thing
	    #
	}
	1111 {
	    #
	    # Map block. Describe the file
	    #
    	    require db-to-addr dbwatch
    	    var mb [value fetch ^h[field $b VMBH_memHandle]
	    	    	[sym find type dbase::DBMapBlock]]

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
