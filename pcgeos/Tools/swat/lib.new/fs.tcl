# test comment
##############################################################################
#
# 	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	fs.tcl
# FILE: 	fs.tcl
# AUTHOR: 	Adam de Boor, Oct 28, 1991
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	10/28/91	Initial Revision
#
# DESCRIPTION:
#	Functions for finding out about loaded filesystem drivers, disks,
#   	drives, etc.
#
#	$Id: fs.tcl,v 1.17 95/10/13 11:45:59 adam Exp $
#
###############################################################################

##############################################################################
#				fsdwalk
##############################################################################
#
# SYNOPSIS:	    Print out all the FSDs currently registered with the
#		    system.
# PASS:		    nothing
# CALLED BY:	    user
# RETURN:	    nothing
# SIDE EFFECTS:	    nothing
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	10/31/91	Initial Revision
#
##############################################################################
[defsubr fsdwalk {}
{
    var t [symbol find type geos::FSDriver]
    var prim [value fetch FSInfoResource:FIH_primaryFSD]
    [for {var d [value fetch FSInfoResource:FIH_fsdList]}
    	 {$d != 0}
	 {var d [field $fsd FSD_next]}
    {
    	var fsd [value fetch FSInfoResource:$d $t]
	var name [value fetch ^h[field $fsd FSD_handle].GH_geodeName]
	
	echo [format {@%04xh: "%s"%s} $d
	    	[mapconcat c $name {var c}]
		[if {$d == $prim} {format { (PRIMARY)}}]]
	require fmtval print
    	echo -n {    }
	fmtval $fsd $t 4
    }]
}]

##############################################################################
#				_drive_name
##############################################################################
#
# SYNOPSIS:	    Fetch the name of a drive from a DriveStatusEntry
# PASS:		    drive   = offset within FSIR of DriveStatusEntry
#   	    	    [t]	    = type token for DriveStatusEntry structure,
#			      if known.
# CALLED BY:	    drivewalk, fwalk
# RETURN:	    name of the drive, w/o colon
# SIDE EFFECTS:	    none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	11/ 3/91	Initial Revision
#
##############################################################################
[defsubr _drive_name {drive {t {}}}
{
    if {[null $t]} {
    	var t [symbol find type geos::DriveStatusEntry]
    }
    global dbcs
    if {[null $dbcs]} {
    	var namelen [expr {[value fetch FSInfoResource:$drive-2 [type word]] -
	    	    	   2 - [type size $t]}]
    	var nt [type make array [expr $namelen-1] [type char]]
    } else {
    	var namelen [expr {([value fetch FSInfoResource:$drive-2 [type word]] -
	    	    	   2 - [type size $t])/2}]
        var nt [type make array [expr $namelen-1] [type wchar]]
    }
    var name [mapconcat c [value fetch FSInfoResource:$drive.DSE_name $nt] {var c}]
    type delete $nt
    return $name
}]

##############################################################################
#				_disk_name
##############################################################################
#
# SYNOPSIS:	Fetch the name from a DiskDesc
# PASS:		disk	= offset of DiskDesc
# CALLED BY:	
# RETURN:	string
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/29/92		Initial Revision
#
##############################################################################
[defsubr _disk_name {disk}
{
    if {$disk & 1} {
    	# standard path
	return [penum geos::StandardPath $disk]
    } else {
        return [mapconcat c [value fetch FSInfoResource:$disk.DD_volumeLabel] 
        	    {var c}]
    }
}]

##############################################################################
#				pdrive-internal
##############################################################################
#
# SYNOPSIS:	Print a description of a drive
# PASS:		d   = offset of the DriveStatusEntry
#		dse = value list from fetching the DriveStatusEntry
#		t   = type token for DriveStatusEntry
#		mt  = type token for MediaType
#		dt  = type token for DriveType
# CALLED BY:	(INTERNAL) pdrive, drivewalk
# RETURN:	nothing
# SIDE EFFECTS:	output
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	10/18/93	Initial Revision
#
##############################################################################
[defsubr pdrive-internal {d dse t mt dt}
{
    var name [_drive_name $d $t]
    var num [field $dse DSE_number]
    var status [field $dse DSE_status]
    var extflags [field $status DES_EXTERNAL]
    var flags [mapconcat f {{DES_LOCAL_ONLY L}
			    {DES_READ_ONLY R}
			    {DES_FORMATTABLE F}
			    {DES_ALIAS A}
			    {DES_BUSY B}}
	{
	    if [field $status [index $f 0]] {
		index $f 1
	    }
	}][mapconcat f {{DS_MEDIA_REMOVABLE r}
			{DS_NETWORK n}}
	{
	    if [field $extflags [index $f 0]] {
		index $f 1
	    }
	}]
    var type [range [type emap [field $extflags DS_TYPE] $dt] 6 end char]
    var media [range [type emap [field $dse DSE_defaultMedia] $mt] 6 end c]

    if {[field [field $dse DSE_exclusive] Sem_value] > 0} {
	var locks none
    } elif {[field $dse DSE_shareCount] != 0} {
	var disk [field [field $dse DSE_diskLock] TL_owner]
	var locks [format {%04xh [%s]}
		    $disk [_disk_name $disk]]
    } else {
	var locks Excl
    }

    echo [format {%04xh %-12.12s%3d  %-7s %-5.5s %13.13s  %04xh %s}
		$d $name $num $flags $type $media [field $dse DSE_fsd]
		$locks]
}]

##############################################################################
#				pdrive
##############################################################################
#
# SYNOPSIS:	Print an individual drive given its drive handle
# PASS:		drive	= offset to the DriveStatusEntry
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	output
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	10/19/93	Initial Revision
#
##############################################################################
[defcommand pdrive {drive} {system.file_system lib_app_driver.file_system}
{Usage:
    pdrive <drive-handle>
    pdrive <drive-name>
    pdrive <drive-number>

Examples:
    "pdrive si"	    Print a description of the drive whose handle is in SI
    "pdrive al"	    Print a description of the drive whose number is in AL
    "pdrive C"	    Print a description of drive C

Synopsis:
    Provides the same information as "drivewalk," but for a single drive,
    given the offset to its DriveStatusEntry structure in the FSInfoResource. 

Notes:
    * This is intended for use by implementors of IFS drivers, as no one else is
      likely to ever see a drive handle.

See also:
    drivewalk.
}
{
    var t [symbol find type geos::DriveStatusEntry]

    if {[catch {getvalue $drive} d] == 0} {
    
	#
	# See if the thing is a valid drive. If not, we'll assume it's a name or
	# a number.
	#
	[for {var h [value fetch geos::FSInfoResource:geos::FIH_driveList]}
	     {$h != 0}
	     {var h [value fetch geos::FSInfoResource:$h.geos::DSE_next]}
	{
	    if {$d == $h} {
		break
	    }
	}]
	var checkNum 1
    } else {
    	var checkNum 0 h 0
    }
    
    if {$h == 0} {
    	#
	# Not a drive. If $drive is numeric, assume the thing is a drive number
	#
	[for {var h [value fetch geos::FSInfoResource:geos::FIH_driveList]}
	     {$h != 0}
	     {var h [value fetch geos::FSInfoResource:$h.geos::DSE_next]}
    	{
	    [if {$checkNum &&
	         [value fetch geos::FSInfoResource:$h.geos::DSE_number] == $d} 
    	    {
	    	break
	    } elif {$drive == [_drive_name $h $t]} {
	    	break
    	    }]
    	}]
	if {$h == 0} {
	    error [format {%s is not a known drive} $drive]
    	}
	var d $h
    }

    echo {Addr  Name        Num  Flags   Type  Default Media  FSD   Locks}

    var dt [symbol find type geos::DriveType]
    var mt [symbol find type geos::MediaType]

    pdrive-internal $d [value fetch FSInfoResource:$d $t] $t $mt $dt
}]

##############################################################################
#				drivewalk
##############################################################################
#
# SYNOPSIS:	    Print out all the drives currently registered with the
#		    system.
# PASS:		    nothing
# CALLED BY:	    user
# RETURN:	    nothing
# SIDE EFFECTS:	    nothing
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	10/28/91	Initial Revision
#
##############################################################################
[defcommand drivewalk {} {system.file_system lib_app_driver.file_system}
{Usage:
    drivewalk

Examples:
    "drivewalk"	    Prints the table of drives known to the system.

Synopsis:
    Prints out all disk drives known to the system, along with their current
    status.

Notes:
    * The Flags column is a string of single-character flags with the
      following meanings:
      	L   	The drive is accessible to the local machine only, i.e.
		it's not visible over a network.
    	R   	The drive is read-only.
	F   	Disks may be formatted in the drive.
	A   	The drive is actually an alias for a path on another drive.
	B   	The drive is busy, performing some extended operation, such
		as formatting or copying a disk.
    	r   	The drive uses disks that may be removed by the user.
    	n   	The drive is accessed over the network.

    * The Locks column can reflect one of three states:
    	none	The drive isn't being accessed by any thread.
	Excl	The drive is locked for exclusive access by a single thread.
	<num>	The drive is locked for shared access for a particular disk,
		whose handle is the number. This is followed by the volume
		name of the disk, in square brackets.

See also:
    diskwalk, fsdwalk.
}
{
    echo {Addr  Name        Num  Flags   Type  Default Media  FSD   Locks}

    var t [symbol find type geos::DriveStatusEntry]
    var dt [symbol find type geos::DriveType]
    var mt [symbol find type geos::MediaType]

    [for {var d [value fetch FSInfoResource:FIH_driveList]}
    	 {$d != 0}
	 {var d [field $dse DSE_next]}
    {
    	var dse [value fetch FSInfoResource:$d $t]
	
    	pdrive-internal $d $dse $t $mt $dt
    }]
}]

##############################################################################
#				pdisk-internal
##############################################################################
#
# SYNOPSIS:	print out a DiskDesc given its value list
# PASS:		d   = offset from whence it sprints
#   	    	dd  = value list
#   	    	mt  = type token for MediaType etype.
# CALLED BY:	diskwalk, pdisk
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	11/23/92	Initial Revision
#
##############################################################################
[defsubr pdisk-internal {d dd mt}
{	
    var media [range [type emap [field $dd DD_media] $mt] 6 end c]
    var name [mapconcat c [field $dd DD_volumeLabel] {var c}]
    if {[field $dd DD_drive] == 0} {
    	var drive -
    } else {
    	var drive [_drive_name [field $dd DD_drive]]
    }
    var status [field $dd DD_flags]
    var flags [mapconcat f {{DF_WRITABLE w}
			    {DF_ALWAYS_VALID V}
			    {DF_STALE S}
			    {DF_NAMELESS u}}
	{
	    if [field $status [index $f 0]] {
		index $f 1
	    }
	}] 

    echo [format {%04xh %-11s  %-12.12s %-5s  %08xh  %s}
	    $d $name $media $flags [field $dd DD_id] $drive]
}]

##############################################################################
#				pdisk
##############################################################################
#
# SYNOPSIS:	print an individual disk handle
# PASS:		disk	= disk handle number
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	11/24/92	Initial Revision
#
##############################################################################
[defcommand pdisk {disk} {system.file_system lib_app_driver.file_system}
{Usage:
    pdisk <disk-handle>

Examples:
    "pdisk bp"	    Prints information about the disk whose handle is in bp

Synopsis:
    Prints out information about a registered disk, given its handle.

Notes:
    * The Flags column is a string of single-character flags with the
      following meanings:
    	w   	The disk is writable.
	V   	The disk is always valid, i.e. it's not removable.
	S   	The disk is stale. This is set if the drive for the disk
		has been deleted.
    	u   	The disk is unnamed, so the system has made up a name for it.

See also:
    diskwalk
}
{
    echo {Addr  Name         Media        Flags  ID         Drive}
    [pdisk-internal [getvalue $disk]
    	    [value fetch FSInfoResource:$disk geos::DiskDesc]
    	    [symbol find type geos::MediaType]]
}]

##############################################################################
#				diskwalk
##############################################################################
#
# SYNOPSIS:	    Print all the disks registered with the system,
#		    optionally restricting the printout to those
#		    for a particular drive.
# PASS:		    [drive] = a drive name whose disks are to be printed.
# CALLED BY:	    user
# RETURN:	    nothing
# SIDE EFFECTS:	    none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	10/28/91	Initial Revision
#
##############################################################################
[defcommand diskwalk {{drive {}}} {system.file_system lib_app_driver.file_system}
{Usage:
    diskwalk <drive>

Examples:
    "diskwalk F"	    Prints the disks registered in drive F.
    "diskwalk"	    	    Prints all the disks registered with the system.

Synopsis:
    Prints out information on registered disks.

Notes:
    * The Flags column is a string of single-character flags with the
      following meanings:
    	w   	The disk is writable.
	V   	The disk is always valid, i.e. it's not removable.
	S   	The disk is stale. This is set if the drive for the disk
		has been deleted.
    	u   	The disk is unnamed, so the system has made up a name for it.

See also:
    drivewalk, fsdwalk.
}
{
    global dbcs
    if {[null $dbcs]} {
        var edrive [explode $drive] dlen [length $drive char]
        if {$dlen} {
    	    var dnamet [type make array $dlen [type char]]
        }
    } else {
        var edrive [explode $drive] dlen [length $drive wchar]
        if {$dlen} {
    	    var dnamet [type make array $dlen [type wchar]]
        }
    }

    var t [symbol find type geos::DiskDesc]
    var mt [symbol find type geos::MediaType]

    echo {Addr  Name         Media        Flags  ID         Drive}

    [for {var d [value fetch FSInfoResource:FIH_diskList]}
    	 {$d != 0}
	 {var d [field $dd DD_next]}
    {
    	var dd [value fetch FSInfoResource:$d $t]

    	if {$dlen} {
    	    [map {c1 c2}
	    	$edrive
		[value fetch FSInfoResource:[field $dd DD_drive].DSE_name
		    	$dnamet]
    	    {
	    	if {[string c $c1 $c2] != 0} {
		    continue
    	    	}
    	    }]
	    [if {[value fetch
	    	    FSInfoResource:[field $dd DD_drive].DSE_name+$dlen
		    [type byte]] != 0}
    	    {
	    	continue
    	    }]
    	} 
    	pdisk-internal $d $dd $mt
    }]
    if {$dlen} {
    	type delete $dnamet
    }
}]

[defsubr _drive_letter {drive}
{
    return [format {%c} [expr 65+$drive]]
}]

[defcommand fwalk {args} {top.file system.file_system lib_app_driver.file_system patient.handle}
{Usage:
    fwalk [<patient>]

Examples:
    "fwalk"	    	list all open files.
    "fwalk geos"	list all open files owned by the geos patient.

Synopsis:
    Print the list of files open anywhere in the system.

Notes:
    * The patient argument may be used to restrict the list to a
      particular patient.  The patient may be specified either as the
      patient name or as the patient's handle.

    * fwalk differs from sysfiles and geosfiles in that it deals primarily
      with GEOS data structures.

    * The 'Other' column shows if there is a VM handle bound to the file.

    * The letters in the 'Flags' column mean the following:
        RW		deny RW
        R		deny R
        W		deny W
        N		deny none
        rw		access RW
        r		access R
        w		access RW
        O	    	override, used to override normal exclusion
    	        	normally used by FileEnum to check out file headers.
        E	    	exclusive, used to prevent override.  
    	    		this is used by disk.geo

See also:
    fhandle, geosfiles, sysfiles.
}
{
    global geos-release
    require read-sft-entry dos

    var owner nil fast 0 ptrs 0 echeck 0 totsz 0


    if {[length $args] > 0} {
	#
	# Gave an owner whose handles are to be printed. Figure out if it's
	# a handle ID or a patient name and set owner to the decimal equiv
	# of the handle ID.
	#
	var h [handle lookup [index $args 0]]
	if {![null $h] && $h != 0} {
	    var owner [handle id $h]
	} else {
	    var owner [handle id
			[index [patient resources
					[patient find [index $args 0]]] 0]]
	}
    }

    #
    # Print out the banner
    #
    echo {Handle  SFN  Drive  Name            Owner    Other   Flags     Sem}
    echo {------------------------------------------------------------------}

    #
    # Set up initial conditions.
    #
    var start [value fetch fileList]
    var nextStruct [value fetch kdata:$start HandleFile]

    for {var cur $start} {$cur != 0} {var cur $next} {

    	var val $nextStruct
	var next [field $val HF_next]
	[var nextStruct [value fetch kdata:$next HandleFile]
	     own [field $val HF_owner]]

	if {[null $owner] || $own == $owner} {
	    [var sfn [field $val HF_sfn]
	     flags [field $val HF_accessFlags]
	     sem [field $val HF_semaphore]
	     oi [field $val HF_otherInfo]]
    	    if {${geos-release} >= 2} {
	    	var disk [field $val HF_disk]
		if {$disk != 0} {
	    	    var drive [_drive_name [value fetch FSInfoResource:$disk.DD_drive]]
    	    	    if {[value fetch FSInfoResource:$disk.DD_drive.DSE_fsd.FSD_flags.FSDF_PRIMARY]} {
		    	var sftent [read-sft-entry $sfn]
			var name "[mapconcat c [range [field $sftent SFTE_name] 0 7] {var c}].[mapconcat c [range [field $sftent SFTE_name] 8 end] {var c}]"
    	    	    } else {
		    	var name n/a
    	    	    }
		} else {
		    var drive n/a
		    var sftent [read-sft-entry $sfn]
		    var name "[mapconcat c [range [field $sftent SFTE_name] 0 7] {var c}].[mapconcat c [range [field $sftent SFTE_name] 8 end] {var c}]"
    	    	}
    	    } else {
    	    	var drive [_drive_letter [field $val HF_drive]]
		var sftent [read-sft-entry $sfn]
		var name "[mapconcat c [range [field $sftent SFTE_name] 0 7] {var c}].[mapconcat c [range [field $sftent SFTE_name] 8 end] {var c}]"
    	    }

    	    var sftent [read-sft-entry $sfn]
	    echo -n [format {%5.04xh%4.02xh  %-5.5s  %-14s  }
		$cur $sfn $drive $name]
		    	    	     

	    var h [handle lookup $own]
	    if {[null $h]} {
		echo -n [format {%04xh    } $own]
	    } else {
		echo -n [format {%-9s}
			  [patient name [handle patient [handle lookup $own]]]]
	    }
    	    if {$oi != 0 && [value fetch kdata:$oi.HG_type] == 0xfc} {
	    	echo -n {V}
	    } else {
	    	echo -n { }
	    }
    	    if {$oi != 0} {
    	    	echo -n [format {%04xh  } $oi]
    	    } else {
	    	echo -n { --    }
    	    }

	    var excludes [field $flags FFAF_EXCLUDE]
	    var access [field $flags FFAF_MODE]
	    if {$excludes == 1} {echo -n {RW}}
	    if {$excludes == 2} {echo -n { W}}
	    if {$excludes == 3} {echo -n { R}}
	    if {$excludes == 4} {echo -n { N}}
	    if {$excludes == 0} {echo -n { C}}
	    echo -n /
	    if {[field $flags FFAF_EXCLUSIVE]} {
		echo -n {E}
	    } else {
		echo -n { }
	    }
	    if {[field $flags FFAF_OVERRIDE]} {
		echo -n {O}
	    } else {
		echo -n { }
	    }
	    echo -n /
	    if {$access == 0} {echo -n {r }}
	    if {$access == 1} {echo -n {w }}
	    if {$access == 2} {echo -n {rw}}

	    echo [format {    %d} $sem]
	}
    }
}]

##############################################################################
#				fsir-stat
##############################################################################
#
# SYNOPSIS:	Print out the status of the FSIR.
# PASS:	    	nothing
# CALLED BY:	sophisticated user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	1/21/92		Initial Revision
#
##############################################################################
[defcommand fsir-stat {} {system.ifs lib_app_driver.ifs}
{Usage:
    fsir-stat
}
{
    var fsir [symbol find module geos::FSInfoResource]

    foreach r [patient resources [patient find geos]] {
    	if {[string c $fsir [handle other $r]] == 0} {
	    break
    	}
    }
    var locks [value fetch kdata:[handle id $r].HM_lockCount]
    echo [format {FSInfoResource = %04xh, locked %d %s (%s)} [handle id $r]
    	    $locks [pluralize time $locks]
	    [if {[value fetch kdata:[handle id $r].HM_usageValue] == 0} 
		{format shared}
		{format exclusive}]]

    echo [format {%-18s shared excl} thread]
    foreach t [thread all] {
	if {[value fetch geos::biosLock.TL_owner] == [thread id $t]} {
	    var ss [value fetch geos::biosStack]
	} else {
	    var ss [thread register $t ss]
	}
    	echo [format {%-18s  %3d    %3d} 
	    	[format {%04xh (%s)} [thread id $t] [threadname [thread id $t]]]
		[value fetch $ss:TPD_sharedFSIRLocks]
		[value fetch $ss:TPD_exclFSIRLocks]]
    }
}]
    	    
[defcmd fhandle {num} {top.file system.file_system lib_app_driver.file_system patient.handle}
{Usage:
    fhandle <handle id>

Examples:
    "fhandle 3290h" 	    Prints info about the file whose handle is 3290h

Synopsis:
    Print out a file handle.

Notes:
    * The handle id argument is the handle number.  File handles are
      listed in the first column of the 'fwalk' command.

See also:
    fwalk.
}
{

    var	val [value fetch kdata:$num HandleFile]

    [var sfn [field $val HF_sfn]
     flags [field $val HF_accessFlags]
     sem [field $val HF_semaphore]
     oi [field $val HF_otherInfo]]
    if {[not-1x-branch]} {
	var disk [field $val HF_disk]
	if {$disk != 0} {
	    var drive [_drive_name [value fetch FSInfoResource:$disk.DD_drive]]
	} else {
	    var drive n/a
	}
    } else {
	var drive [_drive_letter [field $val HF_drive]]
    }

    require read-sft-entry dos

    var sftent [read-sft-entry $sfn]
    
    echo [format {Drive: %s SFN: %d (%xh)} $drive $sfn $sfn]
    if {[null $sftent]} {
    	echo Name: -- not available --
    } else {
    	echo Name: [mapconcat c [range [field $sftent SFTE_name] 0 7] {var c}].[mapconcat c [range [field $sftent SFTE_name] 8 end] {var c}]
    }
    echo [format {Owner: %04xh (%s)} [field $val HF_owner]
	      [patient name
	       [handle patient
	        [handle lookup
		 [field $val HF_owner]]]]]

    echo -n Access:
    var excludes [field $flags FFAF_EXCLUDE]
    var access [field $flags FFAF_MODE]
    if {$excludes == 1} {echo -n {RW}}
    if {$excludes == 2} {echo -n { W}}
    if {$excludes == 3} {echo -n { R}}
    if {$excludes == 4} {echo -n { N}}
    if {$excludes == 0} {echo -n { C}}
    echo -n /
    if {[field $flags FFAF_EXCLUSIVE]} {
	echo -n {E}
    } else {
	echo -n { }
    }
    if {[field $flags FFAF_OVERRIDE]} {
	echo -n {O}
    } else {
	echo -n { }
    }
    echo -n /
    if {$access == 0} {echo -n {r }}
    if {$access == 1} {echo -n {w }}
    if {$access == 2} {echo -n {rw}}

    if {$oi != 0 && [value fetch kdata:$oi.HG_type] == 0xfc} {
	echo -n [format {V(%04xh)} $oi]
    }

    if {$sem != 1} {
    	require print-queue thread

    	if {$sem != 0 && [value fetch kdata:$sem.HG_type] == 0xfb} {
	    # must be a geode file with a thread lock in the semaphore
	    var sv [value fetch kdata:$sem.HS_moduleLock.TL_sem.Sem_value]

	    if {$sv < 1} {
		var lown [value fetch kdata:$sem.HS_moduleLock.TL_owner]
		if {$lown != 0xffff} {
		    var nest [value fetch kdata:$sem.HS_moduleLock.TL_nesting]
		    echo [format {Grabbed %d %s by %04xh (%s)} $nest
			    [pluralize time $nest] $lown
			    [threadname $lown]]
		}
	    }
	    if {$sv <= 0} {
		echo value = $sv, blocked:
		print-queue [value fetch kdata:$sem.HS_moduleLock.TL_sem.Sem_queue]
    	    } else {
	    	echo { semaphore value =} $sv
    	    }
    	} else {
	    echo { P'ed; Waiting for access:} 
    	    print-queue $sem
   	}	    
    } else {
    	echo
    }
}]
