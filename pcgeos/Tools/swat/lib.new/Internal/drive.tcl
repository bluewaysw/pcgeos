##############################################################################
#
# 	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	drive.tcl
# FILE: 	drive.tcl
# AUTHOR: 	Adam de Boor, Jul 21, 1990
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/21/90		Initial Revision
#
# DESCRIPTION:
#	Functions to track device driver requests for a particular drive
#
#	$Id: drive.tcl,v 1.9.11.1 97/03/29 11:25:04 canavese Exp $
#
###############################################################################


[defsubr _drive_letter {drive}
{
    return [format {%c} [expr 65+$drive]]
}]

defvar bios-cmds {{0 reset} {1 status} {2 read} {3 write} {4 verify} {5 format} {8 {read params}} {21 {read type}} {22 {change line status}}}

[defsubr pbios {drive}
{
    if {[read-reg dl] == $drive} {
    	var cmd [index [assoc [uplevel 0 {var bios-cmds}] [read-reg ah]] 1]
	echo {bios cmd = } $cmd
	[case $cmd in
	    {read write} {
	    	echo [format {\thead %d, track %d, sector %d, count %d}
		    	[read-reg dh] [read-reg ch] [read-reg cl] [read-reg al]]
    	    }
    	]
    }
    return 0
}]

[defsubr tdrive {drive}
{
    if {[not-1x-branch]} {
    	[for {var d [value fetch FSInfoResource:FIH_driveList]}
	     {$d != 0}
	     {var d [value fetch FSInfoResource:$d.DSE_next]}
    	{
	    if {[value fetch FSInfoResource:$d.DSE_number] == $drive} {
	    	break
    	    }
    	}]
	if {$d == 0 || [value fetch FSInfoResource:$d.DSE_fsd.FSD_flags.FSDF_PRIMARY] == 0} {
	    global DOSTables
	    var dcb [value fetch $DOSTables.DLOL_DCB]
	    while {($dcb & 0xffff) != 0xffff} {
	    	var dcbseg [expr ($dcb>>16)&0xffff] dcboff [expr $dcb&0xffff]
	    	if {[value fetch $dcbseg:$dcboff.DCB_drive] == $drive} {
		    var dseg [value fetch $dcbseg:$dcboff.DCB_deviceHeader.segment]
		    var doff [value fetch $dcbseg:$dcboff.DCB_deviceHeader.offset]
		    var unit [value fetch $dcbseg:$dcboff.DCB_unit]
    	    	    break
    	    	} else {
	    	    var dcb [value fetch $dcbseg:$dcboff.DCB_nextDCB]
    	    	}
    	    }
	    if {($dcb & 0xffff) == 0xffff} {
	    	error [format {drive %d not found} $drive]
    	    }
    	} else {
	    var priv [value fetch FSInfoResource:$d.DSE_private]
	    var dseg [value fetch FSInfoResource:$priv.DDPD_device.segment]
	    var doff [value fetch FSInfoResource:$priv.DDPD_device.offset]
	    var unit [value fetch FSInfoResource:$priv.DDPD_unit]
	    brk DOSDiskReadBootSector [concat drive-get-boot $drive]
    	}
    } else {
    	var dset [sym find type DriveStatusEntry]
	[for {var d [value fetch FSInfoResource:FIH_driveList]}
	     {$d != 0}
	     {var d [field $dse DSE_next]}
    	{
	    var dse [value fetch FSInfoResource:$d $dset]
	    if {[field $dse DSE_number] == $drive} {
	    	break
    	    }
    	}]
	if {$d == 0} {
	    error [format {drive %d not registered} $drive]
    	}
	[if {![value fetch FSInfoResource:[field $dse DSE_fsd].FSD_flags.FSDF_PRIMARY]}
	{
	    error [format {drive %d not run by primary IFS driver, so it can't be traced} $drive]
    	}]
	var pd [value fetch FSInfoResource:[field $dse DSE_private] DOSDrivePrivateData]
	var dseg [expr ([field $pd DDPD_device]>>16)&0xffff]
	var doff [expr [field $pd DDPD_device]&0xffff]
	var unit [field $pd DDPD_unit]
    	brk DOSDiskReadBootSector [concat drive-get-boot $drive]
    }

    var strat [value fetch $dseg:$doff.DH_strat]
    var intr [value fetch $dseg:$doff.DH_intr]

    brk $dseg:$strat [concat drive-strat $unit]
    brk $dseg:$intr [concat drive-intr $unit]
}]

[defsubr drive-strat {unit}
{
    if {[value fetch es:bx.RH_unit] == $unit} {
    	var cmd [type emap [value fetch es:bx.RH_command]
	    	    [sym find type DosDriverFunction]]
    	echo Command = $cmd
    	global lastRequest lastRequestCmd
	var lastRequest [read-reg es]:[read-reg bx]
	var lastRequestCmd $cmd

	[case $cmd in
    	    {DDF_READ DDF_WRITE} {
    	    	var media [type emap [value fetch es:bx.RR_media]
		    	    [sym find type DosMediaType]]
    	    	var count [value fetch es:bx.RR_count]
	    	var sect [value fetch es:bx.RR_startSector]
		if {$sect == 0xffff} {
		    var sect [value fetch es:bx+26 [type dword]]
    	    	}
		echo [format {\t%d sectors from %d, media = %s} $count $sect
		    	    	$media]
    	    }  
	    DDF_MEDIA_CHECK {
    	    	var media [type emap [value fetch es:bx.MCR_media]
		    	    [sym find type DosMediaType]]
		echo \tlast media = $media
    	    	_print MediaCheckRequest es:bx
    	    }
	    DDF_BUILD_BPB {
	    	_print BuildBPBRequest es:bx
		var buf [value fetch es:bx.BBPBR_buffer+2 word]:[value fetch es:bx.BBPBR_buffer word]
		words $buf
		#return 1
    	    }
	    DDF_IOCTL {
	    	_print GenIoctlRequest es:bx
    	    }
    	]
    }
    return 0
}]

[defsubr drive-intr {unit}
{
    global lastRequest
    
    if {![null $lastRequest] && [value fetch $lastRequest.RH_unit] == $unit} {
    	brk tset [value fetch ss:sp+2 word]:[value fetch ss:sp word] drive-intr-complete
    }
    return 0
}]

[defsubr drive-intr-complete {}
{
    global lastRequest lastRequestCmd breakpoint

    var retval 0

    if {[field [value fetch $lastRequest.RH_status] DDS_ERROR]} {
    	echo [format {\terror = %s}
	    	[type emap
		 [field [value fetch $lastRequest.RH_status] DDS_ERROR_CODE]
		 [sym find type DosDriverError]]]
    } else {
    	[case $lastRequestCmd in
    	    DDF_MEDIA_CHECK {
	    	[case [value fetch $lastRequest.MCR_change] in
		    1 {echo \tmedia not changed}
		    0 {echo \tmedia may have changed}
		    255 {echo \tmedia definitely changed}
		    default {echo \tMCR_change = [value fetch $lastRequest.MCR_change]}
    	    	]
    	    }
	    DDF_BUILD_BPB {
	    	_print *$lastRequest.BBPBR_bpb
    	    }
	    DDF_READ {
	    	bytes *$lastRequest.RR_buffer 64
		if {[value fetch $lastRequest.RR_startSector] == 28} {
		    var retval 1
    	    	}
    	    }
    	]
    }
    
    brk clear $breakpoint
    var lastRequest {}
    return $retval
}]
    

[defsubr drive-get-boot {drive}
{
    if {[not-1x-branch]} {
    	if {[value fetch es:si.DSE_number] == $drive} {
	    echo DOSReadBootSector($drive)
    	}
    } elif {[read-reg al] == $drive} {
    	echo GetBootSector($drive)
    }
    return 0
}]
