##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
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
#	$Id: drive.tcl,v 1.2 90/10/03 21:59:05 adam Exp $
#
###############################################################################

defvar bios-cmds {{0 reset} {1 status} {2 read} {3 write} {4 verify} {5 format} {8 {read params}} {21 {read type}} {22 {change line status}}}

[defsubr pbios {drive}
{
    if {[read-reg dl] == $drive} {
    	var cmd [index [assoc [uplevel 0 {var bios-cmds}] [read-reg ah]] 1]
	echo {bios cmd = } $cmd
	[case $cmd in
	    read|write {
	    	echo [format {\thead %d, track %d, sector %d, count %d}
		    	[read-reg dh] [read-reg ch] [read-reg cl] [read-reg al]]
    	    }
    	]
    }
    return 0
}]

[defsubr tdrive {drive}
{
    var dse [sym find type DriveStatusEntry]
    var dseg [value fetch
    	driveStatusTable+[expr $drive*[type size $dse]].DSE_dosDriver+2
    	[type word]]
    var doff [value fetch
    	driveStatusTable+[expr $drive*[type size $dse]].DSE_dosDriver
    	[type word]]
    var strat [value fetch $dseg:$doff.DH_strat]
    var intr [value fetch $dseg:$doff.DH_intr]
    var unit [value fetch 
    	driveStatusTable+[expr $drive*[type size $dse]].DSE_dosUnit byte]

    brk $dseg:$strat [concat drive-strat $unit]
    brk $dseg:$intr [concat drive-intr $unit]
    brk GetBootSector [concat drive-get-boot $drive]
}]

[defsubr drive-strat {unit}
{
    if {[value fetch es:bx.RH_unit] == $unit} {
    	var cmd [type emap [value fetch es:bx.RH_command]
	    	    [sym find type DosDriverFunctions]]
    	echo Command = $cmd
    	global lastRequest lastRequestCmd
	var lastRequest [read-reg es]:[read-reg bx]
	var lastRequestCmd $cmd

	[case $cmd in
    	    DDF_READ|DDF_WRITE {
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
    	    	print MediaCheckRequest es:bx
    	    }
	    DDF_BUILD_BPB {
	    	print BuildBPBRequest es:bx
		var buf [value fetch es:bx.BBPBR_buffer+2 word]:[value fetch es:bx.BBPBR_buffer word]
		words $buf
		return 1
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

    if {[field [value fetch $lastRequest.RH_status] DDS_ERROR]} {
    	echo [format {\terror = %s}
	    	[type emap
		 [field [value fetch $lastRequest.RH_status] DDS_ERROR_CODE]
		 [sym find type DosDriverErrors]]]
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
	    	print *$lastRequest.BBPBR_bpb
    	    }
    	]
    }
    
    brk clear $breakpoint
    var lastRequest {}
    return 0
}]
    

[defsubr drive-get-boot {drive}
{
    if {[read-reg al] == $drive} {
    	echo GetBootSector($drive)
    }
    return 0
}]
