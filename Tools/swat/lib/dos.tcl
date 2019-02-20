##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	dos.tcl
# AUTHOR: 	Adam de Boor, Apr 13, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#	sysfiles		print out all files open in the system
#	geosfiles		print out all files opened by GEOS
#	dosState		print out the state of the thread that's
#				in DOS when it entered DOS
#	dosMem			Print out dos memory blocks
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/13/89		Initial Revision
#
# DESCRIPTION:
#	Functions for examining DOS state
#
#	$Id: dos.tcl,v 3.4 90/10/12 14:20:43 tony Exp $
#
###############################################################################
#
# Enter these field symbols in the kernel's global scope
#
var p [patient data]
switch kernel
global segaddr
if {[null $segaddr]} {
    #
    # Basic far pointer
    #
    defvar segaddr [type make pstruct offset [type word] segment [type word]]

    #
    # Structure pointed to by $DOSTables variable
    #
    defvar ListOfLists [type make pstruct
			DCBS $segaddr
			SFT $segaddr
			clockDev $segaddr
			consoleDev $segaddr
			largestSector [type word]
			cacheBlocks $segaddr
			CDS $segaddr
			SFTFCB $segaddr
    	    	    	SFTFCBSize [type word]
			driveCount [type byte]
			lastDrive [type byte]
			nullDev [type make pstruct
				    nextDevice $segaddr
				    attr [type word]
				    strategy [type word]
				    interrupt [type word]
				    name [type make array 8 [type char]]
				    joins [type byte]]]


    #
    #   "sysfiles" prints the files in the system file table:
    #
    #   The system file table (SFT) consists of a chain of blocks, each
    #   containing a certain number of SFT entries (described by the sftEntry
    #   structure created below). Each block begins with a three-word header
    #   ($sftHeader). The final block in the chain has an offset of 0xffff. An
    #   empty entry  in a block is indicated by a refCnt field of 0.
    #
    defvar sftEntry [type make pstruct
		    refCnt [type word]
		    mode [type word] 
		    dirAttrib [type byte] 
		    flags [type word] 
		    DCB [type dword] 
		    firstCluster [type word] 
		    time [type word] 
		    date [type word] 
		    size [type dword] 
		    pos [type dword] 
		    relCluster [type word] 
		    curCluster [type word] 
		    blockNum [type word] 
		    dirIndex [type byte] 
		    filename [type make array 8 [type char]] 
		    extension [type make array 3 [type char]]
		    unknown [type make array 4 [type byte]] 
		    ownerMach [type word] 
		    ownerPSP [type word] 
		    status [type word]]
    defvar sftHeader [type make pstruct
		     next $segaddr
		     numEntries [type word]]
    gc register $sftHeader $sftEntry $ListOfLists $segaddr
}

defvar _cachedSFT nil
[if {[string c $_nuke_SFT_handler {}] == 0} {
    [var _nuke_SFT_handler [event handle CONTINUE _nuke_SFT]]
}]
[defsubr _nuke_SFT {args} {
    global _cachedSFT
    var _cachedSFT nil
    return EVENT_HANDLED
}]

[defdsubr read-sft {} prog.obscure
{Returns as a list of structure-values all files in the System File Table in
order}
{
    global DOSTables segaddr _cachedSFT

    var sftEntry [sym find type SFTEntry]
    var sftHeader [sym find type SFTBlockHeader]
    var sftEntrySize [type size $sftEntry]
    var retval {}

    if {[null $_cachedSFT]} {
    	echo -n {Reading System File Table...}
    	flush-output

    	[for {
    	    	#
	    	# Start looking at the beginning of the sft chain.
	    	#
            	var base [value fetch sftStart]
    	    }
    	    {($base & 0xffff)!=65535}
    	    {
    	    	#
	    	# Work down the chain...
	    	#
    	    	var base [field $sftBlock SFTBH_next]
    	    }
    	{
    	    #
	    # Figure how many entries are in the block and set addr to be the
	    # address of the first of them (just after the sftHeader)
	    #
    	    var addr [expr $base>>16]:[expr $base&0xffff]
    	    var sftBlock [value fetch $addr $sftHeader]
    	    var limit [field $sftBlock SFTBH_numEntries]
    	    var addr $addr+6

    	    [for {var i 0} {![irq] && ($i < $limit)} {var i [expr $i+1]} {
    	    	#
	    	# Fetch the next entry
	    	#
    	    	var entry [value fetch $addr $sftEntry]

    	    	if {[field $entry SFTE_refCount]} {
    	    	    var retval [concat $retval [list $entry]]
	    	} else {
    	    	    var retval [concat $retval {{}}]
	    	}
    	    	var addr [format {%s+$sftEntrySize} $addr]
    	    }]
    	}]
    
    	var _cachedSFT $retval
    	echo {done}
    } else {
    	var retval $_cachedSFT
    }
    return $retval
}]
    
#
# Print out the banner for what print-sft-entry produces
#
[defsubr print-sft-entry-header {}
{
    echo {#   Name    .Ext  Sharing  Access  Ref'd  Position    Size}
    echo {----------------------------------------------------------}
}]

#
# Format and print the info from a single SFT entry. Assumes the number
# has already been printed (i.e. it starts with the Name in the banner above)
#
[defsubr print-sft-entry {entry}
{
    var i 0
    [foreach j [field $entry SFTE_name] {
    	echo -n $j
    	var i [expr $i+1]
	if {$i == 8} {
	    echo -n .
    	}
    }]
    if {[null [field $entry SFTE_position]]} {
	echo [format {    %-4s    %-5s  %4d   %6d    %6d}
	      [index {OLD Exc NoW NoR All ??? ??? Net}
		     [field [field $entry SFTE_mode] FAF_EXCLUDE]]
	      [index {r w r/w ?} [field [field $entry SFTE_mode] FAF_MODE]]
	      [field $entry SFTE_refCount] [field $entry SFTE_relativeRec]
	      [field $entry SFTE_size]]
    } else {
	echo [format {    %-4s    %-5s  %4d   %6d    %6d}
	      [index {OLD Exc NoW NoR All ??? ??? Net}
		     [field [field $entry SFTE_mode] SFTM_DENY]]
	      [index {r w r/w ?} [field [field $entry SFTE_mode] SFTM_ACCESS]]
	      [field $entry SFTE_refCount] [field $entry SFTE_position]
	      [field $entry SFTE_size]]
    }
}]

[defcommand sysfiles {} kernel
{Prints out all open files in the system in tabular form.}
{
    #
    # Files are numbered from 0. 
    #
    var fnum 0

    var sft [read-sft]

    print-sft-entry-header

    [foreach entry $sft {
    	if [irq] break
    	#
	# Print out the file number, then the file name in its two
	# parts (name and extension with a . between them)
	#
    	echo -n [format {%2d: } $fnum]
    	    	
    	if {[length $entry] > 0} {
    	    print-sft-entry $entry
    	} else {
	    echo {*** empty ***}
    	}
	var fnum [expr $fnum+1]
    }]
}]

[defcommand geosfiles {} kernel
{Prints out all the files opened by GEOS}
{
    global PSPAddr segaddr

    var jft [value fetch $PSPAddr+34h $segaddr]
    var jftSize [value fetch $PSPAddr+32h [type word]]
    var handles [value fetch [field $jft segment]:[field $jft offset]
    	    	    	    [type make array $jftSize [type byte]]]
    
    var sft [read-sft]
    
    print-sft-entry-header

    var j 0
    foreach i $handles {
    	if [irq] break

    	echo -n [format {%2d: } $j]
    	if {$i == 255} {
	    echo {*** not open ***}
	} else {
	    print-sft-entry [index $sft $i]
	}
	var j [expr $j+1]
    }
}]

#
# dosStateStruct describes the state saved by DOS on entry to an INT 21
# dosSavedStack is address of DWORD giving SS:SP on entry
#
defvar dosStateStruct nil
if {[null $dosStateStruct]} {
    var dosStateStruct [type make pstruct
			dss_ax [type word]
			dss_bx [type word]
			dss_cx [type word]
			dss_dx [type word]
			dss_si [type word]
			dss_di [type word]
			dss_bp [type word]
			dss_ds [type word]
			dss_es [type word]
			dss_ip_swat [type word]
			dss_cs_swat [type word]
			dss_flags_swat [type word]
			dss_ip [type word]
			dss_cs [type word]
			dss_cc [type word]]
    gc register $dosStateStruct
}

defvar dosSavedStack 2bch:51eh
[defsubr pseg {name val}
{
    var handle [handle find [format 0x%04x:0 $val]]
    if {![null $handle]} {
	if {[handle state $handle] & 0x480} {
	    #
	    # Handle is a resource/kernel handle, so it's got a symbol in
	    # its otherInfo field. We want its name.
	    #
	    echo -n [format {%-4s%04xh   handle %04x (%s)}
			$name $val [handle id $handle]
			[symbol fullname [handle other $handle]]]
	} else {
	    echo -n [format {%-4s%04xh   handle %04x}
			$name $val [handle id $handle]]
	}
	if {[handle segment $handle] != $val} {
	    echo [format { [handle segment = %xh]}
			 [handle segment $handle]]
	} else {
	    echo
	}
    } else {
	echo [format {%-4s%04xh   no handle} $name $val]
    }
}]

[defcommand dosState {} dos
{Print out the state of the caller of the current DOS function}
{
    global dosStateStruct dosSavedStack flags

    if {[read-reg cs] >= [handle segment [handle lookup 1]]} {
    	error {Current thread not in DOS}
    }
    
    save-state
    protect {
    	#
	# Locate the saved state structure
	#
    	assign ss [value fetch PSP:30h [type word]] 
    	assign sp [value fetch PSP:2eh [type word]]

    	#
	# Fetch the state itself
	#
    	var state [value fetch ss:sp $dosStateStruct]

    	#
	# Change the thread's registers to match those saved in the
	# state structure
	#
    	foreach i {ax bx cx dx si di bp ds es ip cs cc} {
	    assign $i [field $state dss_$i]
    	}
	
	assign sp sp+[type size $dosStateStruct]
	
	echo {Now in state before DOS call. Type "break" to return to top level}
    	switch [patient name]:[index [patient data] 2]
	event dispatch STACK 0
	top-level
    } {restore-state}
}]

[defdsubr dosMem {} dos
{Travels along DOS's chain of memory blocks, providing info about each}
{
    global DOSTables

    var block [value fetch $DOSTables-2 [type word]]

    echo [format {%-8s %-8s %-8s} Block Owner Size]

    for {} {[value fetch $block:0 [type byte]] == 0x4d} {} {
	var size [value fetch $block:3 [type word]]
	echo [format {%-8.04x %-8.04x %-8.04x} $block
		[value fetch $block:1 [type word]]
		$size]
	var block [expr $block+$size+1]
    }
    echo [format {%-8.04x %-8.04x %-8.04x} $block
	    [value fetch $block:1 [type word]]
	    [value fetch $block:3 [type word]]]
}]

switch [index $p 0]:[index $p 2]

[defcommand sftwalk {} kernel
{Prints SFT info}
{
    var off [value fetch sftAddr word]
    var seg [value fetch sftAddr+2 word]
    while {($seg | $off) != 0} {
	var head [value fetch $seg:$off SFTBlockHeader]
	var count [field $head SFTBH_numEntries]
	echo [format {SFT block at %04x:%04x containing %d entries:}
							$seg $off $count]
	var ptr [expr $off+6]
	while {$count > 0} {
	    printSFT [value fetch $seg:$ptr SFTEntry]
	    var ptr [expr $ptr+[type size [sym find type SFTEntry]]]
	    var count [expr $count-1]
	}
        var i [value fetch $seg:$off+2 word]
        var off [value fetch $seg:$off word]
        var seg $i
    }
}]

defsubr printSFT {ent} {
    foreach j [field $ent SFTE_name] {echo -n $j}
    echo
}

[defcommand waitpostinfo {{count 10}} kernel
{Prints wait/info test info}
{
    if {[null [sym find var wpHistory]]} {
    	echo {The kernel must have TEST_WAIT_POST turned on for this}
    	return
    }
    echo [format {Last %d calls to BiosWaitOrPost (in reverse order) are:}
    	    	    	$count]
    var ptr [value fetch wpPtr]
    var arrayEnd [expr [sym get [sym find const WP_HISTORY_SIZE]]*[type
    	    	    	    	size [sym find type WaitPostCall]]]
    for {var i 0} {$i < $count} {var i [expr $i+1]} {
    	if {$ptr == 0} {
    	    var ptr $arrayEnd
    	}
    	var ptr [expr $ptr-[type size [sym find type WaitPostCall]]]
    	p WaitPostCall wpHistory+$ptr
    }
}]
