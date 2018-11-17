##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	ddetach.tcl
# FILE: 	ddetach.tcl
# AUTHOR: 	Adam de Boor, Mar 24, 1992
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	ddetach	    	    	sets breakpoints at relevant routines, each
#				of which prints out the progress of the detach.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/24/92		Initial Revision
#
# DESCRIPTION:
#	Things for debugging detach problems.
#
#	$Id: ddetach.tcl,v 1.2 92/04/13 00:30:37 adam Exp $
#
###############################################################################
[defsubr ddetach {}
{
    global	detach_brkpts
    if {![null $detach_brkpts]} {
	eval [concat brk clear $detach_brkpts]
    }
    
    if {[not-1x-branch]} {
	var detach_brkpts [list
		[brk ObjInitDetach print-init-detach]
		[brk ObjIncDetach print-inc-detach]
		[brk ObjEnableDetach print-enable-detach]]
    } else {
	var detach_brkpts [list
		[brk ObjInitDetach print-init-detach]
		[brk ObjIncDetach print-inc-detach]
		[brk ObjEnableDetach print-enable-detach]
		[brk ObjAckDetach print-ack-detach]]
    }
    foreach i $detach_brkpts {
    	brk delcmd $i detach-brk-deleted
    }
}]

[defsubr detach-brk-deleted {}
{
    global  breakpoint detach_brkpts
    
    var detach_brkpts [mapconcat b $detach_brkpts {
    	if {[string c $b $breakpoint] == 0} {
	    format {}
    	} else {
    	    format {%s } $b
    	}
    }]
}]

[defsubr print-detach-data {}
{
    if {[not-1x-branch]} {
    	require vardaddr pvardata
	
    	var s ^h[handle id [handle find ds:si]]
	var o [vardaddr *ds:si]
	
	var end [expr [value fetch (*ds:si)-2 word]-2+[value fetch ds:si word]]
	
    	var dd [index [symbol get [symbol find enum geos::DETACH_DATA]] 0]
	while {$o != $end} {
	    var t [value fetch $s:$o.VDE_dataType]
    	    if {($t & ~3) == $dd} {
	    	var ackCount [value fetch $s:$o.VDE_extraData.DDE_ackCount]
		var ackOD [value fetch $s:$o.VDE_extraData.DDE_ackOD]
		var ackID [value fetch $s:$o.VDE_extraData.DDE_callerID]
		break
    	    } elif {$t & 2} {
	    	var o [expr $o+[value fetch $s:$o.VDE_entrySize]]
    	    } else {
	    	var o [expr $o+2]
    	    }
    	}
    } else {
	var si [read-reg si]
	[for {var chunk [value fetch ds:TLMBH_tempList]}
	     {$chunk != 0}
	     {var chunk [value fetch (*ds:$chunk).DD_reserved+2 word]}
	{
	    if {[value fetch (*ds:$chunk).DD_reserved word] == $si} {
	    	var ackCount [value fetch (*ds:$chunk).DD_ackCount]
		var ackOD [value fetch (*ds:$chunk).DD_ackOD]
		var ackID [value fetch (*ds:$chunk).DD_callerID]
    	    	break
    	    }
	}]
    }
    
    if {[null $ackCount]} {
	echo [format {\tdetach data not allocated yet}]
    } else {
	echo [format {\tackCount = %d, ackOD = ^l%04xh:%04xh, ackID = %04xh}
    	    	$ackCount
		[expr ($ackOD>>16)&0xffff]
		[expr $ackOD&0xffff]
		$ackID]
    }
}]
	
[defsubr print-detach-obj {preface}
{
    require fmtoptr print

    echo -n ${preface}
    fmtoptr [value fetch ds:LMBH_handle] [read-reg si]	
    echo
}]

[defsubr print-init-detach {}
{
    print-detach-obj {init detach }
    echo [format {\tcx = %04xh, dx:bp = ^l%04xh:%04xh}
		[read-reg cx]
		[read-reg dx]
		[read-reg bp]]
    print-detach-data
    return 0
}]

[defsubr print-inc-detach {}
{
    print-detach-obj {inc detach }
    print-detach-data
    return 0
}]

[defsubr print-enable-detach {}
{
    [if {[string c [frame function
		    [frame next [frame top]]]
		   ProcCallModuleRoutine] == 0}
    {
    	print-detach-obj {ack detach }
    } else {
    	print-detach-obj {enable detach }
    }]
    print-detach-data
    return 0
}]

[defsubr print-ack-detach {}
{
    print-detach-obj {ack detach }
    print-detach-data
    return 0
}]

