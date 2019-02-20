##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
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
#	$Id: dos.tcl,v 3.35 97/07/30 18:33:43 dave Exp $
#
###############################################################################
#
# Enter these field symbols in the kernel's global scope
#
var p [patient data]
global geos-release
if {[null [info global geos-release]]} {
    switch kernel
} elif {${geos-release} < 2} {
    switch geos
} else {
    switch loader
}
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
if {[string c $_nuke_SFT_handler {}] == 0} {
    var _nuke_SFT_handler [event handle CONTINUE _nuke_SFT]
}
[defsubr _nuke_SFT {args} {
    global _cachedSFT
    
    if {![null $_cachedSFT]} {
    	table destroy $_cachedSFT
    	var _cachedSFT nil
    }
    return EVENT_HANDLED
}]

##############################################################################
#				read-sft-entry
##############################################################################
#
# SYNOPSIS:	    Fetch a single entry from the DOS SFT.
# PASS:		    sfn	= the System File Number (aka index) whose entry
#			  is to be fetched.
# CALLED BY:	    ?
# RETURN:	    a value list containing the following fields, at least:
#   	    	    	SFTE_refCount	    number of times it's referenced
#			SFTE_mode   	    FileAccessFlags for the handle
#   	    	    	SFTE_position	    Current seek position for the
#					    file
#   	    	    	SFTE_size   	    Current size of the open file
#   	    	    	SFTE_name   	    Array of chars giving the name
#					    of the open file.
#   	    	    nil if $sfn is beyond the bounds of the SFT.
#
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	11/ 3/91	Initial Revision
#
##############################################################################
[defsubr read-sft-entry {sfn {hnumvar {}}}
{
    global DOSTables segaddr _cachedSFT

    #
    # Can't do anything if it's OS/2 (which we check for by seeing if the
    # DOS major version is 20 or the os2 patient is loaded (for WinNT))
    #
    if {[value fetch dosVersion.low] == 20 || ![null [patient find os2]]} {
	return {}
    }

    if {![null [patient find ms3]] && [value fetch ms3::isPC3_0]} {
    	var ispc30 1
	var sftEntry [sym find type SFT30Entry]
    } else {
    	var ispc30 0
    	var sftEntry [sym find type SFTEntry]
    }
    var sftHeader [sym find type SFTBlockHeader]
    var sftEntrySize [type size $sftEntry]
    
    if {[null $_cachedSFT]} {
    	var _cachedSFT [table create]
    }
    
    # convert from hex, if necessary
    var sfn [expr $sfn]

    var elist [table lookup $_cachedSFT $sfn]
    if {[null $elist]} {
    	var dosVersion [value fetch dosVersion]
	var isDRDOS [value fetch isDRDOS]
	
    	#
	# Locate the SFT entry in the linked-list
    	#

    	# if we are using a gym file for the IFS driver we won't be able
    	# to get at this info...
    	if {[null [sym find var sftStart]]} {
    	    return {}
    	}
	[for {var n $sfn base [value fetch sftStart]}
	     {($base & 0xffff) != 65535}
	     {var base [field $sftBlock SFTBH_next]}
    	{
    	    #
	    # Figure how many entries are in the block and set addr to be the
	    # address of the first of them (just after the sftHeader)
	    #
    	    var addr [expr ($base>>16)&0xffff]:[expr $base&0xffff]
    	    var sftBlock [value fetch $addr $sftHeader]
    	    var limit [field $sftBlock SFTBH_numEntries]
	    
    	    if {$n >= $limit} {
	    	var n [expr $n-$limit]
	    } else {
    	    	var addr $addr+[expr 6+$n*$sftEntrySize]
		var entry [value fetch $addr $sftEntry]
		break
    	    }
    	}]
	
	#XXX: massage various fields as appropriate to the DOS version:
	#   * DOS 2: SFTE_position doesn't exist, but SFTE_relativeRec does
	#   * DR DOS: SFTE_position isn't kept up-to-date, so need to go
    	#     into their internal table. Ditto for SFTE_size, and maybe
	#     for SFTE_refCount
	#   * PC DOS 3.0: convert SFT30E_ to SFTE_
    	if {![null $entry]} {
	    if {$isDRDOS} {
		var hts [value fetch dri::handleTable.segment]
		var fh $hts:[value fetch $hts:[value fetch dri::handleTable.offset]+[expr 2*$sfn] [type word]]
		var realPos [value fetch $fh.FH_filePos]
		if {[field [value fetch $fh.FH_mode] FHAM_DEVICE]} {
		    var realSize 0
		} else {
		    var realSize [value fetch $hts:[value fetch $fh.FH_desc].FD_size]
		}

		var entry [map e $entry {
		    [case [index $e 0]
		     SFTE_position {
			concat [range $e 0 1] $realPos
		     }
		     SFTE_size {
			concat [range $e 0 1] $realSize
		     }
		     * {
			var e
		     }
		    ]
		}]
	    } elif {$ispc30} {
		var entry [map e $entry {
		    concat SFTE_[range [index $e 0] 7 end char] [range $e 1 end]
		}]
	    }
    	}
	var elist [list $entry [concat [range [addr-parse $addr] 0 1]
				       [list $sftEntry]]]
	table enter $_cachedSFT $sfn $elist
    }
    
    if {![null $hnumvar]} {
    	uplevel 1 var $hnumvar [value hstore [index $elist 1]]
    }

    return [index $elist 0]
}]
    
#
# Print out the banner for what print-sft-entry produces
#
[defsubr print-sft-entry-header {}
{
    echo { @  #   Name    .Ext  Sharing  Access  Ref'd  Position    Size}
    echo {--------------------------------------------------------------}
}]

#
# Format and print the info from a single SFT entry. Assumes the number
# has already been printed (i.e. it starts with the Name in the banner above)
#
[defsubr print-sft-entry {entry}
{
    var i 0
    if {[null $entry]} {
    	echo NOT OPENED BY DOS
	return
    }
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

[defcmd sysfiles {args} {system.file_system lib_app_driver.file_system}
{Usage:
    sysfiles [all]

Examples:
    "sysfiles"

Synopsis:
    Print out all open files from dos's system file table.

Notes:
    * Normally SFT entries that aren't in-use aren't printed. If you give the
      optional argument "all", however, all SFT entries, including those that
      aren't in-use, will be printed.

See also:
    geosfiles, sftwalk, fwalk.
}
{
    var doAll [expr {[string c $args all] == 0}]

    print-sft-entry-header

    for {var fnum 0} {1} {var fnum [expr $fnum+1]} {
    	var entry [read-sft-entry $fnum hnum]
	if {[null $entry]} {
	    break
	} elif {[field $entry SFTE_refCount]} {
	    #
	    # Print out the file number, then the file name in its two
	    # parts (name and extension with a . between them)
	    #
	    echo -n [format {%3d %3d: } $hnum $fnum]
	    print-sft-entry $entry
	} elif {$doAll} {
	    echo [format {%3d: *** not open ***} $fnum]
    	}
    }
}]

[defcommand geosfiles {} {system.file_system lib_app_driver.file_system}
{Usage:
    geosfiles

Examples:
    "geosfiles"

Synopsis:
    Print out all the files for which I/O is currently pending in GEOS.

Notes:
    * This looks at the same dos structure as sysfiles but this prints
      only those files also listed in geos's job file table.

See also:
    sysfiles, sftwalk, fwalk.
}
{
    global PSPAddr segaddr

    var jft [value fetch $PSPAddr.PSP_jftAddr $segaddr]
    var jftSize [value fetch $PSPAddr.PSP_numHandles [type word]]
    if {$jftSize > 20} {
    	if {[not-1x-branch]} {
	    var jftSize [value fetch dri::realJFTSize]
    	} else {
	    var jftSize [value fetch drdos::realJFTSize]
    	}
    }
    var ht [type make array $jftSize [type byte]]
    var handles [value fetch [field $jft segment]:[field $jft offset] $ht]
    type delete $ht    	
    
    print-sft-entry-header

    var j 0
    foreach i $handles {
    	if {$i == 255} {
    	    echo [format {%3s %2d: *** not open ***} {} $j]
	} else {
	    var entry [read-sft-entry $i hnum]
    	    echo -n [format {%3d %2d: } $hnum $j]
	    print-sft-entry $entry
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
    var handle [handle find [format %04xh:0 $val]]
    if {![null $handle]} {
	if {[handle state $handle] & 0x480} {
	    #
	    # Handle is a resource/kernel handle, so it's got a symbol in
	    # its otherInfo field. We want its name.
	    #
	    echo -n [format {%-4s%04xh   handle %04xh (%s)}
			$name $val [handle id $handle]
			[symbol fullname [handle other $handle]]]
	} else {
	    echo -n [format {%-4s%04xh   handle %04xh}
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

[defcmd dosState {} system.dos
{Usage:
    dosState

Examples:
    "dosState"

Synopsis:
    Print out the state of the caller of the current DOS function.

Notes:
    * This must be called during the time when dos is called.  This is
      used to determine what called dos.  This can be trickly since dos
      switches stacks.  This command is probably quite dos 3.3 specific.  If
      the machine is stopped in a BIOS routine, use dumpstack to find the
      caller.
}
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

[defsubr dos-foreach-device {cmd}
{
    global DOSTables
    
    scan $DOSTables {%xh:%xh} ds do
    var do [expr $do+[getvalue DLOL_null]]
    
    while {$do != 0xffff} {
    	uplevel 1 var ds $ds do $do
    	[case [catch {uplevel 1 $cmd} res] in
	    2 {
	    	return $res
    	    }
	    default {
		[var ds [value fetch $ds:$do.DH_next.segment] 
		     do [value fetch $ds:$do.DH_next.offset]]
    	    }
	    1 {
	    	error $res
    	    }
	    3 {
	    	break
    	    }]
    }
    uplevel 1 var ds $ds do $do
}]	    	

[defsubr dos-foreach-dcb {cmd}
{
    global DOSTables
    
    [for {var dcb [value fetch $DOSTables.DLOL_DCB]} 
	 {($dcb&0xffff) != 0xffff}
	 {var dcb [value fetch $dcs:$dco.DCB_nextDCB]}
    {
	var dcs [expr ($dcb>>16)&0xffff] dco [expr $dcb&0xffff]
    	uplevel 1 var dcs $dcs dco $dco
    	[case [catch {uplevel 1 $cmd} res] in
	    2 {
	    	return $res
    	    }
	    default {
    	    }
	    1 {
	    	error $res
    	    }
	    3 {
	    	break
    	    }]
    }]
    uplevel 1 var dcs $dcs dco $dco
}]	    	

[defcommand dosMem {{flags {}}} system.dos
{Usage:
    dosMem

Examples:
    "dosMem"

Synopsis:
    Traverse DOS's chain of memory blocks, providing info about each.

}
{
    global DOSTables

    var doirqs 0
    foreach f [explode [range $flags 1 end char]] {
    	[case $f in
	 i {var doirqs 1 it [value fetch 0:0 [type make array 512 [type word]]]}]
    }
    var block [value fetch $DOSTables-2 [type word]]
    var namet [type make array 8 [type char]]

    echo [format { %8s %8s %8s %8s} Block Owner Name Size]
    echo [format { %8s %8s %8s %8s} ----- ----- ---- ----]

    for {} {1} {} {
	var size [value fetch $block:3 [type word]]
	var owner [value fetch $block:1 [type word]]
	var dosubs 0 maybeirq 1
	if {$owner == 0} {
	    var name free maybeirq 0
	} elif {$owner == 8} {
	    var name system
	    if {[value fetch $block:8 word] != 0x4353} {
	    	# data segment w/subsegments
	    	var dosubs 1
    	    }
	    var maybeirq 0
    	} elif {$owner == 7} {
	    var name excluded maybeirq 0
    	} elif {$owner == 6} {
	    var name umb maybeirq 0
    	} elif {$owner == 0xfffa} {
    	    # 386MAX UMB Control Block
	    var name {3M umbctl} maybeirq 0
	} elif {$owner == 0xfffd} {
    	    # excluded area for 386MAX
	    var name {3MAX excl} maybeirq 0
    	} elif {$owner == 0xfffe} {
    	    # umb created by 386MAX maybeirq 0
	    var name {3MAX umb}
    	} elif {$owner == 0xffff} {
    	    # driver loaded by 386MAX
	    var name {3M drvr}
	} else {
    	    # looks to be something real. first see if the name of the program
	    # is in the MCB itself. The name is the 8 bytes at offset 8 in the
	    # MCB
	    var name {}
	    var valid 1
	    var n [value fetch ($owner-1):8 $namet]
	    foreach c $n {
		if {[string m $c {\\*}]} {
		    if {$c == \000} {
			break
		    } else {
			var valid 0
			break
		    }
		}
	    }

    	    # If first byte of the name is 0, see if the thing can be identified
	    # as a device
	    if {[value fetch ($owner-1):8 byte] == 0} {
	    	# maybe a device driver
		dos-foreach-device {
		    if {$ds == $block+1} {
		    	break
    	    	    }
    	    	}

		if {$do != 0xffff} {
		    if {[value fetch $ds:$do.DH_attr.DA_CHAR_DEV]} {
		    	var n [value fetch $ds:$do.DH_name]
    	    	    } else {
		    	var first -1
			dos-foreach-dcb {
			    if {[value fetch $dcs:$dco.DCB_deviceHeader.segment] == $ds} {
			        if {$first == -1} {
				    var first [value fetch $dcs:$dco.DCB_drive]
    	    	    	    	}
				var last [value fetch $dcs:$dco.DCB_drive]
    	    	    	    }
    	    	    	}
		    	var n [explode [format {%c: - %c:} [expr $first+65]
			    	    [expr $last+65]]]
    	    	    }
		    var valid 1
    	    	}
    	    }

		
	    if {!$valid} {
    	    	# couldn't find a valid name. if its parent is itself, it's the
		# primary command interpreter
    	    	if {[value fetch $owner:PSP_parentId] == $owner} {
		    var n {c o m m a n d}
    	    	} else {
    	    	    # look in the extra strings that follow the environment
		    # for the filename
		    var env [value fetch $owner:PSP_envBlk]
		    if {[value fetch ($env-1):1 [type word]] == $owner} {
			var emax [expr [value fetch ($env-1):3 word]<<4]
			for {var i 0} {$i < $emax} {var i [expr $i+1]} {
			    if {[value fetch $env:$i byte] == 0} {
				if {[value fetch $env:$i+1 byte] == 0} {
				    var i [expr $i+2]
				    break
				}
			    }
			}
			# skip # of strings
			var i [expr $i+2]
			var ens 0
			for {var ns $i} {$i < $emax} {var i [expr $i+1]} {
			    [case [value fetch $env:$i byte] in
			      0 {
				  break
			      }
			      92 {
				  # backslash
				  var ns [expr $i+1]
			      }
			      46 {
				  # period
				  var ens $i
			      }
			    ]
			}
			if {$ens < $ns} {
			    var ens $i
			}
			var t [type make array [expr $ens-$ns] [type char]]
			var n [value fetch $env:$ns $t]
			type delete $t
		    } else {
			var n {u n k n o w n}
    	    	    }
    	    	}
    	    }
		    
	    foreach c $n {
		if {[string match $c {\\*}]} {
		    break
		} else {
		    var name ${name}${c}
		}
	    }
	}
	
	echo [format {%8.04xh%8.04xh %8s %8.04xh} $block $owner $name
		$size]
	if {$doirqs && $maybeirq} {
	    dos-find-irqs [expr $block+1] $size 3 $it
    	}
    	if {$dosubs} {
	    # block is divided into subsegments by DOS. print out info on those,
	    # too
	    [for {var ss 16}
		 {$ss < ($size<<4)}
		 {var ss [expr $ss+(($ssize+1)<<4)]}
    	    {
		var ssize [value fetch $block:$ss+3 word]
		var sname [mapconcat c [value fetch $block:$ss+8 $namet] {
		    if {[string match $c {\\*}]} {
		    	break
    	    	    } else {
		    	var c
    	    	    }
    	    	}]
		[case [value fetch $block:$ss char] in
		 D {var sdesc [format {Device driver: %s} $sname]}
		 E {var sdesc [format {Device driver appendage: %s} $sname]}
		 I {var sdesc [format {IFS driver: %s} $sname]}
		 F {var sdesc {System file tables}}
		 X {var sdesc {FCBs}}
		 C {var sdesc {Buffer workspace}}
		 B {var sdesc {Buffers}}
		 L {var sdesc {Current Directory Table}}
		 S {var sdesc {Stacks}}
		 T {var sdesc {Transient code}}
		 default {var sdesc [format {Unknown (%s): %s} 
				    [value fetch $block:$ss char]
				    $sname]}]
    	    	echo [format {%16s%04xh (%04xh) %s} {} [expr $block+($ss>>4)] $ssize $sdesc]
		if {$doirqs} {
		    dos-find-irqs [expr $block+($ss>>4)+1] $ssize 24 $it
    	    	}
    	    }]
    	}
	if {[value fetch $block:0 [type byte]] != 0x4d} {
    	    if {$block < 0xa000} {
	    	echo {    --- End of Conventional RAM ---}
		# see if there's a control block after the current block
		if {[value fetch ($block+$size+1):0 byte] == 0x4d} {
		    var block [expr $block+$size+1]
    	    	} else {
		    break
    	    	}
    	    } else {
	    	break
    	    }
	} else {
	    var block [expr $block+$size+1]
	}
    }
}]

[defsubr dos-find-irqs {seg size poff it}
{
    var n 0 end [expr $seg+$size]
    foreach i $it {
    	if {$n & 2} {
	    if {$i >= $seg && $i < $end} {
		echo [format {%*sINT %3d (%02xh): %04xh:%04xh} [expr $poff+4] {}
			[expr $n/4] [expr $n/4] $i $o]
    	    }
    	} else {
	    var o $i
    	}
	var n [expr $n+2]
    }

#    for {var i 0} {$i < 1024} {var i [expr $i+4]} {
#    	var s [value fetch 0:$i+2 word]
#	if {$s > $seg && $s < $seg+$size} {
#	    echo [format {%*sINT %3d (%02xh): %04xh:%04xh} [expr $poff+4] {}
#	    	    [expr $i/4] [expr $i/4] $s [value fetch 0:$i word]]
#    	}
#    }
}]

switch [index $p 0]:[index $p 2]

[defcmd sftwalk {} {system.file_system lib_app_driver.file_system}
{Usage:
    sftwalk

Examples:
    "sftwalk"

Synopsis:
    Print the SFT out by blocks.

Notes:
    * This is different than sysfiles in that it shows less details of
      the files and instead shows where the SFT blocks are and what
      files are in them.

See also:
    sysfiles, geosfiles, fwalk.
}
{
    [for {var base [value fetch sftStart]}
         {($base & 0xffff) != 65535}
         {var base [value fetch $seg:$off dword]} {

	var seg [expr $base>>16]
	var off [expr $base&0xffff]

	var head [value fetch $seg:$off SFTBlockHeader]
	var count [field $head SFTBH_numEntries]
	echo [format {SFT block at %04xh:%04xh containing %d entries:}
	      $seg $off $count]

	var ptr [expr $off+6]
	while {$count > 0} {
	    printSFT [value fetch $seg:$ptr SFTEntry]
	    var ptr [expr $ptr+[size SFTEntry]]
	    var count [expr $count-1]
	}
    }]
}]

defsubr printSFT {ent} {
    foreach j [field $ent SFTE_name] {echo -n $j}
    echo
}

[defcmd waitpostinfo {{count 10}} system.misc.obscure
{Usage:
    waitpostinfo

Examples:
    "waitpostinfo"

Synopsis:
    Print wait/info test info.  This is an internal command.

Notes:
    * This is turned on in Library/Kernel/kernelConstant.def.
}
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






[defsubr strings {seg length}
{
    var str {}
    for {var i 0} {$i < $length} {var i [expr $i+1]} {
    	var b [value fetch $seg:$i byte]
	if {$b >= 0x20 && $b < 0x7f} {
	    var str [format {%s%c} $str $b]
    	} else {
    	    if {[length $str char] > 3} {
	    	echo [format {%04xh:%04xh: "%s"} $seg
		    	     [expr $i-[length $str char]]
			     $str]
    	    }
    	    var str {}
    	}
    }
}]
