##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	Swat System Library
# MODULE:	Break On Resource Load
# FILE: 	brkload.tcl
# AUTHOR: 	Adam de Boor, Aug 21, 1992
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	brkload	    	    	stop when a particular resource is loaded
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	8/21/92		Initial Revision
#
# DESCRIPTION:
#	
#
#   	$Id: brkload.tcl,v 1.9.12.1 97/03/29 11:26:28 canavese Exp $
#
###############################################################################
[defcommand brkload {{handle {}}} breakpoint
{Usage:
    brkload [<handle>]

Examples:
    "brkload Interface"	    Stop the machine when the Interface resource is
			    loaded or swapped in.
    "brkload bx"    	    Stop the machine when the resource whose handle ID
			    is in BX is loaded or swapped in.
    "brkload"	    	    Stop watching for the previously-specified resource
			    to be loaded.

Synopsis:
    Stop the machine when a particular resource is loaded into memory.

Notes:
    * Only one brkload may be active at a time; registering a second one
      automatically unregisters the first.

    * If you give no <handle> argument, the previously-set brkload will be
      unregistered.

See also:
    handle.
}
{
    #
    # Unregister any previous brkload
    #
    global brkload_interest
    if {![null $brkload_interest]} {
    	handle nointerest $brkload_interest
	var brkload_interest {}
    }
    #
    # Now figure out the handle token.
    #
    if {![null $handle]} {
    	#
	# Parse it once, allowing values.
	#
    	var a [addr-parse $handle 0]
	if {![null [index $a 0]] && [string c [index $a 0] value]} {
    	    # expression involved a handle of some sort, so just use that
	    var h [index $a 0]
    	} else {
	    # expression is just an integer of some sort, so look it up
    	    var h [handle lookup [index $a 1]]
    	}
	#
	# Register interest in the handle, so we know when it comes in or
	# gets freed.
	#
    	var brkload_interest [handle interest $h brkload-interest-proc]
    }
}]

##############################################################################
#				brkload-finish-frame
##############################################################################
#
# SYNOPSIS:	Set a thread-specific breakpoint at the return address of the
#		given frame
# PASS:		f   = frame the finish of which is eagerly awaited.
#   	    	msg = message to print when frame is finished
# CALLED BY:	brkload-interest-proc
# RETURN:	nothing
# SIDE EFFECTS:	breakpoint is set.
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	8/21/92		Initial Revision
#
##############################################################################
[defsubr brkload-finish-frame {f msg}
{
    var f [frame next $f]
    var b [cbrk [frame register pc $f] thread=[frame register curThread $f]]
    brk cmd $b [list brkload-finish-complete $b $msg]
}]

##############################################################################
#				brkload-finish-complete
##############################################################################
#
# SYNOPSIS:	Give the user the message that was delayed by the need to
#   	    	wait for the handle to have meaningful data.
# PASS:		b   	= breakpoint token (for nuking breakpoint)
#   	    	msg 	= message to give the user
# CALLED BY:	breakpoint module
# RETURN:	1 (stop the machine)
# SIDE EFFECTS:	breakpoint is removed, machine is stopped.
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	8/21/92		Initial Revision
#
##############################################################################
[defsubr brkload-finish-complete {b msg}
{
    echo $msg
    brk clear $b
    return 1
}]

##############################################################################
#				brkload-interest-proc
##############################################################################
#
# SYNOPSIS:	handle-interest procedure for brkload to note when the
#		handle being watched changes state
# PASS:		h   	= token for handle being watched
#   	    	change	= string indicating what type of change the handle
#			  is undergoing
# CALLED BY:	handle module
# RETURN:	nothing
# SIDE EFFECTS:	patient may be stopped, brkload cancelled, or a breakpoint
#		set to stop when the handle's in a condition to be looked at.
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	8/21/92		Initial Revision
#
##############################################################################
[defsubr brkload-interest-proc {h change}
{
    [case $change in
     {load} {
     	var f [frame next [frame top]]
	[case [symbol name [frame funcsym $f]] in
	 PreLoadResources {
    	    #
	    # Resource has its memory and its contents, so stop now.
	    #
	    echo [format {%s pre-loaded} [symbol name [handle other $h]]]
	    stop-patient
    	 }
	 GeodeDuplicateResource {
    	    #
	    # Finish out of GeodeDuplicateResource so bx holds handle of
	    # duplicate.
	    #
    	    brkload-finish-frame $f [format {%s duplicated}
	    	    	    	     [symbol name [handle other $h]]]
    	 }
	 LockDiscardedResource_callback {
    	    #
	    # Get to a point where the handle actually has the data (back
	    # in LockDiscardedResource)
	    #
	    [while {[string c [symbol name [frame funcsym $f]]
			      LockDiscardedResource]}
    	    {
	    	var f [frame next $f]
    	    }]
	    brkload-finish-frame [frame prev $f] [format {%s loaded}
						  [symbol name
						   [handle other $h]]]
    	 }]
     }
     {swapin} {
    	#
	# Block has its contents at this point, so stop now.
	#
	echo [format {Handle %04xh swapped in} [handle id $h]]
     	stop-patient
     }
     {free} {
    	#
	# Handle is being freed, so tell the user the brkload has been cancelled
	# and record its absence in our global variable.
	#
     	echo [format {brkload %04xh canceled: block has been freed} 
		     [handle id $h]]
     	global brkload_interest
	var brkload_interest {}
    }]
}]
