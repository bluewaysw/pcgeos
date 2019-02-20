##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	objwatch.tcl
# FILE: 	objwatch.tcl
# AUTHOR: 	Adam de Boor, Feb 28, 1990
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	objwatch    	    	trace all methods sent to a specific object
#   	mwatch	    	    	trace delivery of a method or methods to any
#   	    	    	    	object
#   	objmessagebrk	    	stop before a message for an object is enqueued
#   	procmessagebrk	    	stop before a message for a process is enqueued
#   	pod 	    	    	format an object's address in ^l format.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/28/90		Initial Revision
#
# DESCRIPTION:
#	Shows calls going to a specific object, or a specific method being sent
#
#	$Id: objwatch.tcl,v 3.5 90/04/27 00:16:31 adam Exp $
#
###############################################################################


##############################################################################
#				objwatch
##############################################################################
#
# SYNOPSIS:	Trace all method calls to an object.
# PASS:		objaddr	= address expression giving the base of the object
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	any previous objwatch is cancelled
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/28/90		Initial Revision
#
##############################################################################
[defcommand objwatch {{objaddr {}}} profile
{"objwatch" displays method calls that have reached a particular object.
At this point in time, only one object at a time can be watched this way.
Use:	objwatch <CR>		- clears current objwatch
	objwatch ADDR <CR>	- sets watch on object at ADDR
}
{
	global	ow_brkpt
	global  ow_object
	global  ow_interest

    remove-brk ow_brkpt
    # Nuke any previous interest record since we're no longer interested
    # in the handle, our breakpoint having gone away.
    if {![null $ow_interest]} {
	handle nointerest $ow_interest
	var ow_interest {}
    }
    if {![null $objaddr]} {
	#
	# Locate the chunk handle for the object in question.
	#
    	var ow_object [get-chunk-addr-from-obj-addr $objaddr]
	#
	# Keep swat's handle descriptor, whose token we've got, valid by
	# expressing interest in it. Data passed to the interest procedure
	# is the chunk handle of the object so it can manipulate the
	# breakpoint condition properly
	#
	var ow_interest [handle interest [index $ow_object 0]
				ow-interest-proc [index $ow_object 1]]
	#
	# Set a conditional breakpoint for the machine to stop any time
	# ObjCallMethodTable is called with this object in mind.
	#
    	var ow_brkpt [cbrk aset ObjCallMethodTable
			    si=[index $ow_object 1]
			    ds=[handle segment [index $ow_object 0]]]
	#
	# Alter the command to print something nice, since we can't give
	# both command and criteria to cbrk
	#
    	brk cmd $ow_brkpt print-ow
    }
}]
##############################################################################
#				ow-interest-proc
##############################################################################
#
# SYNOPSIS:	Track changes in the handle containing the object being watched
# PASS:		handle	= token for handle containing the object
#   	    	what	= change in handle that provoked this call
#   	    	chunk	= chunk handle of object being watched
# CALLED BY:	handle module
# RETURN:	nothing
# SIDE EFFECTS:	breakpoint can be deleted, enabled, disabled or have its
#   	    	condition changed.
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/28/90		Initial Revision
#
##############################################################################

[defsubr	ow-interest-proc {handle what chunk}
{
    [case $what in
	free {
	    #
	    # If block being freed, null out the ow_interest variable in the
	    # global scope so we don't try and delete the thing (which is about
	    # to be deleted by the handle module anyway).
	    #
	    uplevel 0 {
		var ow_interest {}
		# Biff the breakpoint now as well
		brk del $ow_brkpt
	    }
	}
	swapin|load|resize|move {
	    #
	    # Alter the conditions of the breakpoint to match the block's
	    # current location.
	    #
	    global ow_brkpt
	    brk cond $ow_brkpt ds=[handle segment $handle] si=$chunk
	    #
	    # Re-enable the breakpoint if it was disabled before.
	    #
	    brk enable $ow_brkpt
	}
	swapout|discard {
	    #
	    # Make sure we don't trigger falsely while the block is out.
	    #
	    global ow_brkpt
	    brk disable $ow_brkpt
	}
    ]
}]

##############################################################################
#				print-ow
##############################################################################
#
# SYNOPSIS:	Breakpoint routine to trace methods going to an object.
# PASS:		Nothing
# CALLED BY:	breakpoint module when conditions set by objwatch are set
# RETURN:	0 (we don't want the machine to stop)
# SIDE EFFECTS:	message is printed if this is indeed the object we're watching.
#
# STRATEGY
#   	    	Since we will be called whenever a breakpoint at
#   	    	ObjCallMethodTable fires, we must compare *ds:si against the
#   	    	object we're watching before printing anything.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/28/90		Initial Revision
#
##############################################################################
[defsubr	print-ow {} {

	global  ow_object

    [if {([index $ow_object 1] == [read-reg si]) &&
	 ([handle segment [index $ow_object 0]] == [read-reg ds])}
    {
	[print-obj-and-method [handle id [index $ow_object 0]] [read-reg si]
		[read-reg ax] [read-reg cx] [read-reg dx] [read-reg bp]]
    }]
    return 0
}]


##############################################################################
#				mwatch
##############################################################################
#
# SYNOPSIS:	Display all deliveries of a method or methods
# PASS:		args	= any number of methods to be watched
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	any previous method watches are deleted
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/28/90		Initial Revision
#
##############################################################################
[defcommand mwatch {args} profile
{"mwatch" displays all deliveries of a particular method. 

Use:	mwatch <CR>			- clears current mwatch
	mwatch METHOD1 METHOD2<CR>	- sets method watch on methods

You may specify up to 8 methods to be watched (less if you have other
conditional breakpoints active).
}
{
    global mw_brkpts

    remove-brk mw_brkpts
    var mw_brkpts [map i $args {
    	var b [cbrk aset ObjCallMethodTable ax=$i]
	brk cmd $b print-method
	var b
    }]
}]
# Routine to print out method going to object, where object is at *ds:si.
#
[defsubr	print-method {} {
    [print-obj-and-method [handle id [handle find ds:0]] [read-reg si]
		[read-reg ax] [read-reg cx] [read-reg dx] [read-reg bp]]
    return 0
}]


##############################################################################
#				objmessagebrk
##############################################################################
#
# SYNOPSIS:	Stop any method being sent to an object before it enters the
#   	    	queue for the thread that is running the object.
# PASS:		objaddr	= address of object to be watched
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	a conditional breakpoint is set at ObjMessage
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/28/90		Initial Revision
#
##############################################################################

[defcommand objmessagebrk {{objaddr {}}} profile
{"objmessagebrk" breaks anytime a method is being SENT to a particular
object via ObjMessage.  Thus, methods that will be sent via queue are caught
at ObjMessage, before the event is in the queue.
Use:	objmessagebrk <CR>		- clears current objmessagebrk
	objmessagebrk ADDR <CR>		- sets breakpoint for object at ADDR
}
{
	global	omb_brkpt
	global  omb_object

    remove-brk omb_brkpt
    if {![null $objaddr]} {
    	var omb_object [get-chunk-addr-from-obj-addr $objaddr]
    	var omb_brkpt [cbrk aset ObjMessage bx=[handle id [index $omb_object 0]]
	    	    	    	    	    si=[index $omb_object 1]]
	brk cmd $omb_brkpt print-omb
    }
}]
##############################################################################
#				print-omb
##############################################################################
#
# SYNOPSIS:	breakpoint handler for objmessagebrk. If called b/c message
#   	    	is being sent to watched object, leaves the machine stopped
# PASS:		nothing
# CALLED BY:	breakpoint module
# RETURN:	1 (stop machine) if message being sent to watched object.
#   	    	0 (continue machine) if message being sent elsewhere
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/28/90		Initial Revision
#
##############################################################################
#
# Routine to print out method going to object, given OD of object in 
# ^lbx:si, method in AX.
# Makes sure that ^lbx:si is the same as ow_object, only prints on match.
#
[defsubr	print-omb {} {

	global  omb_object

    [if {([index $omb_object 1] == [read-reg si]) &&
	 ([handle id [index $omb_object 0]] == [read-reg bx])}
    {
	[print-obj-and-method [read-reg bx] [read-reg si] [read-reg ax]
		[read-reg cx] [read-reg dx] [read-reg bp]
	]
	return 1
    } else {
    	return 0
    }]
}]


#
# Routine to print out message being sent, given method in AX, object 
# in ^lbx:si
#
[defsubr	print-message {} {

    [print-obj-and-method [read-reg bx] [read-reg si] [read-reg ax]
		[read-reg cx] [read-reg dx] [read-reg bp] ]
    return 0
}]



[defcommand procmessagebrk {{prochandle {}}} profile
{"procmessagebrk" breaks anytime a method is being SENT to a given process
via ObjMessage.  Thus, methods which will be sent via queue are caught
at ObjMessage, before the event is in the queue.
Use:	procmessagebrk <CR>		- clears current procmessage
	procmessagebrk HANDLE <CR>	- sets breakpoint for process
}
{
	global	opm_brkpt
	global  opm_object

    remove-brk opm_brkpt
    if {![null $prochandle]} {
    	var opm_object $prochandle
    	var opm_brkpt [cbrk aset ObjMessage bx=$opm_object]
    	brk cmd $opm_brkpt print-opm
    }
}]
#
# Routine to print out method going to a process
# Makes sure that bx is the same as opm_object, only prints on match.
#
[defsubr	print-opm {} {

	global  opm_object

    if {([eval $opm_object] == [read-reg bx])} {
	return 1
    } else return 0
}]


[defcommand	pod {{objaddr}} print
{"pod" prints out the address passed in output descriptor format:
^l<handle>:<chunk>
}
{
    var chunkaddr [get-chunk-addr-from-obj-addr $objaddr]
    var blockhandle [handle id [index $chunkaddr 0]]
    var chunkoffset [index $chunkaddr 1]
    echo [format {^l%04x:%04x} $blockhandle $chunkoffset]
}]


##############################################################################
#				remove-brk
##############################################################################
#
# SYNOPSIS:	Delete a list of breakpoints
# PASS:		bname	= name of a global variable containing the list of
#   	    	    	  breakpoints
# CALLED BY:	procmessagebrk, objwatch, mwatch, objmessagebrk
# RETURN:	nothing
# SIDE EFFECTS:	the global variable is set to {}
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/28/90		Initial Revision
#
##############################################################################
[defsubr remove-brk {bname} {
	global	$bname

    if {![null $[var $bname]]} {
	foreach i [var $bname] {
	    catch {brk clear $i}
	}
	var $bname {}
    }
}]

##############################################################################
#				objbrk
##############################################################################
#
# SYNOPSIS:	Stop when a particular message is about to be delivered
#   	    	to an object.
# PASS:		obj 	= address of object to watch
#   	    	method	= method on which to stop
# CALLED BY:	user
# RETURN:	breakpoint number
# SIDE EFFECTS:	maybe
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/26/90		Initial Revision
#
##############################################################################
[defcommand objbrk {{obj {}} {method {}}} breakpoint
{Allows you to stop execution when a particular message is delivered to an
object. First argument is the object to watch. Second is the method number for
which to watch.

Any previous breakpoint set by this command is cleared. If no arguments are
given, no new breakpoint is set.}
{
    global  ob_brkpt ob_object ob_interest

    remove-brk ob_brkpt
    
    # nuke any previous interest record since we're no longer interested
    # in the handle, our breakpoint has gone away.
    if {![null $ob_interest]} {
	handle nointerest $ob_interest
	var ob_interest {}
    }
    if {![null $obj]} {
    	if {[null $method]} {
	    var mcond {}
	} else {
	    var mcond ax=$method
    	}
	#
	# Locate the chunk handle for the object in question.
	#
    	var ob_object [get-chunk-addr-from-obj-addr $obj]
	#
	# Keep swat's handle descriptor, whose token we've got, valid by
	# expressing interest in it. Data passed to the interest procedure
	# is the chunk handle of the object so it can manipulate the
	# breakpoint condition properly
	#
    	var handle [index $ob_object 0] chunk [index $ob_object 1]
	var ob_interest [handle interest $handle
				ob-interest-proc 
				[concat si=$chunk $mcond]]
	#
	# Set a conditional breakpoint for the machine to stop any time
	# ObjCallMethodTable is called with this object in mind.
	#
    	var ob_brkpt [eval [concat
	    	    	    cbrk aset ObjCallMethodTable
			    	si=[index $ob_object 1]
			    	ds=[handle segment $handle]
				$mcond]]
    	#
	# If object handle not resident, disable the breakpoint until it
	# comes in.
	#
    	if {([handle state $handle] & 1) == 0} {
	    brk disable $ob_brkpt
    	}
	#
	# Alter the command to get to the method handler...
	#
    	brk cmd $ob_brkpt [concat ob-trigger $handle $chunk
	    	    	    [if {![null $method]}
			    	{index [addr-parse $method] 1}]]
    }
}]

##############################################################################
#				ob-interest-proc
##############################################################################
#
# SYNOPSIS:	Track changes in the handle containing the object for which
#   	    	a message breakpoint has been set
# PASS:		handle	= token for handle containing the object
#   	    	what	= change in handle that provoked this call
#   	    	criteria= additional criteria for the conditional breakpoint
#   	    	    	  (chunk handle and method number)
# CALLED BY:	handle module
# RETURN:	nothing
# SIDE EFFECTS:	breakpoint can be deleted, enabled, disabled or have its
#   	    	condition changed.
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/28/90		Initial Revision
#
##############################################################################

[defsubr	ob-interest-proc {handle what criteria}
{
    [case $what in
	free {
	    #
	    # If block being freed, null out the ob_interest variable in the
	    # global scope so we don't try and delete the thing (which is about
	    # to be deleted by the handle module anyway).
	    #
	    uplevel 0 {
		var ob_interest {}
		# Biff the breakpoint now as well
		brk del $ob_brkpt
		echo [format {handle %04xh freed, so object breakpoint deleted}
		    	[handle id $handle]]
	    }
	}
	swapin|load|resize|move {
	    #
	    # Alter the conditions of the breakpoint to match the block's
	    # current location.
	    #
	    global ob_brkpt
	    eval [concat brk cond $ob_brkpt ds=[handle segment $handle]
	    	    	    $criteria]
	    #
	    # Re-enable the breakpoint if it was disabled before.
	    #
	    brk enable $ob_brkpt
	}
	swapout|discard {
	    #
	    # Make sure we don't trigger falsely while the block is out.
	    #
	    global ob_brkpt
	    brk disable $ob_brkpt
	}
    ]
}]

##############################################################################
#				ob-trigger
##############################################################################
#
# SYNOPSIS:	Trigger an object breakpoint
# PASS:		handle	= token of the handle containing the object
#   	    	chunk	= chunk of the object
#   	    	method	= method being watched for, if any
# CALLED BY:	breakpoint
# RETURN:	0 (continue the machine) or 1 (stop the machine)
# SIDE EFFECTS:	breakpoints appropriate to getting to the actual method
#   	    	handler will have been set as for istep's M command
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/26/90		Initial Revision
#
##############################################################################
[defsubr ob-trigger {handle chunk {method -1}}
{
    [if {[read-reg ds] == [handle segment $handle] &&
         [read-reg si] == $chunk &&
	 ($method == -1 || [read-reg ax] == $method)}
    {
    	stop-catch {go ObjCallModuleMethod CallFixed OCMT_none}
	stop-catch {
    	    [case [index [unassemble cs:ip] 0] in
	    	ObjCallModuleMethod {go ^hbx:ax}
		CallFixed {go {*(dword es:bx)}}
		OCMT_none {}]
    	}
    	# Keep machine stopped now we're where we want to be.
	return 1
    } else {
    	return 0
    }]
}]
