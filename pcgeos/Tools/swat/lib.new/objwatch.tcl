##############################################################################
#
# 	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	Swat
# MODULE:	System Library
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
#	$Id: objwatch.tcl,v 3.22.11.1 97/03/29 11:26:38 canavese Exp $
#
###############################################################################


##############################################################################
#				objwatch
##############################################################################
#
# SYNOPSIS:	Trace all message calls to an object.
# PASS:		objaddr	= address expression giving the base of the object
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	any previous objwatch is cancelled
#
# STRATEGY
#   	figure the chunk handle of the object being watched, as that's what
#   	we need for the breakpoint condition
#
#   	set a conditional breakpoint at ObjCallMethodTable for the object
#   	in question being in *ds:si (breakpoint module will deal with the
#   	block shifting around)
#
#   	bind print-ow to actually print out the message call and continue
#   	the machine when the breakpoint is hit.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/28/90		Initial Revision
#
##############################################################################
[defcmd objwatch {args} {object.message patient.message profile}
{Usage:
    objwatch <object> [<message>]
    objwatch <special object flags> [<message>]
    objwatch <object block> [<message>]
    objwatch <patient>

Examples:
    "objwatch ^l4c30h:002eh"watch messages that reach object at ^l4c30h:002eh
    "objwatch oself"	    watch messages reaching current object (C)
    "objwatch *ds:si"	    watch messages reaching current object (asm)
    "objwatch FooObject"    watch messages that reach FooObject
    "objwatch ^h4c30h"	    watch messages that reach objects in ^h4c30h
    "objwatch -f MSG_META_KBD_CHAR"    watch for kbd char reaching cur focus obj
    "objwatch FooResource"  watch messages that reach objects in FooResource
    "objwatch myapp"	    watch messages that reach patient myapp
    "brk list"		    see list of breakpoints, (includes these)
    "del 5"		    delete breakpoint 5 (useful on an objwatch as well
				as a plain breakpoint)

Synopsis:
    Display message calls to a particular object, or group of objects.  This
    command is analogous to "objbrk", but instead of stopping stop execution,
    just prints out the message occurrence. 

Notes:
    * The address argument is the address of the object to watch.

    * This returns the token of the breakpoint being used to watch message
      deliveries to the object. Use the "brk" command to enable, disable or
      delete the watching of the object.

    * Special object flags:  These may be used as a substitute for an
      actual object address:

    	Value	Returns in watch on:
	-----	-----------------------------------------------------------
    	-a  	the current patient's application object
	-p	the current patient's process
    	-i  	the current "implied grab": the windowed object over which
		the mouse is currently located.
    	-f  	the leaf of the keyboard-focus hierarchy
	-t  	the leaf of the target hierarchy
	-m  	the leaf of the model hierarchy
	-c  	the content for the view over which the mouse is currently
		located
    	-kg  	the leaf of the keyboard-grab hierarchy
	-mg 	the leaf of the mouse-grab hierarchy

See also:
    mwatch, objbrk, brk, objmessagebrk, procmessagebrk, gentree, vistree,
    classtree, methods, gup, vup, cup, pobject, pinst
}
{
    if {[length $args] > 1} {
    	var mcond ax=[getvalue [index $args 1]]
    } else {
    	var mcond ax!=MSG_META_MOUSE_PTR
    }
    
    var pat [patient find [index $args 0]]
    if {[null $pat]} {
    	var objaddr [addr-with-obj-flag [index $args 0]]
    	var ow_object [get-chunk-addr-from-obj-addr $objaddr]

    var h [index $ow_object 0]
    [if {[handle isthread $h]} {
    	#
	# Thread
	#
	# Set breakpoint at ObjCallMethodTable for ds being the patient's dgroup
	# and the thread being the indicated one.
	#
	var ow_brkpt [eval [concat cbrk aset ObjCallMethodTable
	    	    	ds=[patient name [handle patient $h]]::dgroup
			thread=[handle id $h]
			$mcond]]
    	brk cmd $ow_brkpt [list print-thread-ow $h 
	    	    	    [handle segment [index
			    	    	     [patient resources
					      [handle patient $h]]
					     1]]]
    } elif {([handle state $h]&0xf8000) == 0x40000} {
    	#
    	# event queue. Can only catch these at ObjMessage
	#
	var ow_brkpt [eval [conat cbrk aset ObjMessage bx=[handle id $h] $mcond]]
	brk cmd $ow_brkpt [list print-queue-ow $h]
    } else {
	#
	# Set a conditional breakpoint for the machine to stop any time
	# ObjCallMethodTable is called with this object in mind.
	#
	var ow_brkpt [eval [concat cbrk aset ObjCallMethodTable
			    [if {[index $ow_object 1]} {
				list si=[index $ow_object 1]
			    }]
			    ds=^h[handle id [index $ow_object 0]]
			    $mcond]]
	#
	# Alter the command to print something nice, since we can't give
	# both command and criteria to cbrk
	#
	brk cmd $ow_brkpt [list print-ow $ow_object]
    }]
    } else {
	swi [patient name $pat]
	var ow_brkpt [brk pset ObjCallMethodTable {print-ow {}}]

	# Can't set patient-specific conditional breakpoints now
	#brk cond $ow_brkpt $mcond

    }
    return $ow_brkpt
}]

##############################################################################
#				print-ow
##############################################################################
#
# SYNOPSIS:	Breakpoint routine to trace methods going to an object.
# PASS:		ow_object   = address list for the object being watched
#   	    	    	      (for the chunk handle, not the instance data)
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
[defsubr	print-ow {ow_object}
{
  require test-msg-cond objbrk
  if {[null $ow_object]} {
    if {[test-msg-cond [read-reg ax] {}]} {
	[print-obj-and-method [value fetch ds:0 [type word]] [read-reg si]
		{} [read-reg ax] [read-reg cx] [read-reg dx] [read-reg bp]]
    }
  } else {
    [if {[test-si-cond [read-reg si] [index $ow_object 1]] &&
	 ([handle segment [index $ow_object 0]]==[read-reg ds]) &&
	 [test-msg-cond [read-reg ax] {}]} {
	[print-obj-and-method [handle id [index $ow_object 0]] [read-reg si]
		{} [read-reg ax] [read-reg cx] [read-reg dx] [read-reg bp]]
    }]
  }
  return 0
}]

##############################################################################
#				print-thread-ow
##############################################################################
#
# SYNOPSIS:	Breakpoint routine to trace methods going to a thread
# PASS:		h   	= handle token for the thread.
#   	    	dgroup	= segment of dgroup  
# CALLED BY:	breakpoint module when conditions set by objwatch are met
# RETURN:	0 (we don't want the machine to stop)
# SIDE EFFECTS:	message is printed if this is indeed the object we're watching.
#
# STRATEGY
#   	    	Since we will be called whenever a breakpoint at
#   	    	ObjCallMethodTable fires, we must compare ds against the
#   	    	patient's dgroup and ensure the proper thread is running.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/28/90		Initial Revision
#
##############################################################################
[defsubr	print-thread-ow {h dgroup}
{
    if {[read-reg ds] == $dgroup && [read-reg curThread] == [handle id $h]} {
	[print-obj-and-method [handle id $h] [read-reg si]
		{} [read-reg ax] [read-reg cx] [read-reg dx] [read-reg bp]]
    }
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
# SIDE EFFECTS:	uses conditional breakpoints
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/28/90		Initial Revision
#
##############################################################################
[defcmd mwatch {{command clear} args} {object.message profile}
{Usage:
    mwatch <msg>+
    mwatch add <msg>+
    mwatch list
    mwatch clear

Examples:
    "mwatch MSG_FOO_ZIP MSG_FOO_ZAP"	watch only these messages
    "mwatch add MSG_VIS_DRAW"		watch this message also
    "mwatch"	        	    	clear all message watches

Synopsis:
    Display all deliveries of a particular message.

Notes:
    * The <msg>+ argument is which messages to watch; those specified will
      replace any messages watched before.  If none are specified then
      any messages watched will be cleared, to conserve conditional
      breakpoints.

    * You may specify up to eight messages to be watched (less if you
      have other conditional breakpoints active).  See cbrk.

    * "mwatch clear" will clear all message watches.

    * "mwatch add" will add the specified messages to the watch list.

    * "mwatch list" will return a list of breakpoints that have been set
      by previous calls to mwatch.

See also:
    objwatch, objbrk, objmessagebrk, procmessagebrk
}
{
    global mw_brkpts

    [case $command in
     clear {
	 remove-brk mw_brkpts
     }
     list {
	 echo $mw_brkpts
     }
     {add default} {
	 #
	 # if <command> isn't "add", then it must be a message.
	 #
	 if {[string c $command add] != 0} then {
	     remove-brk mw_brkpts
	     var args [concat $command $args]
	 }
	 map i $args {
	     if {[catch
		  {
		      var b [cbrk aset ObjCallMethodTable ax=$i]
		      brk cmd $b print-method
		      var mw_brkpts [concat $mw_brkpts $b]
		  } result] == 1
	      } then {
		  echo [format {Error: %s} $result]
	      }
         }
     }]
}]


# Routine to print out method going to object, where object is at *ds:si.
#
[defsubr	print-method {} {
    [print-obj-and-method [handle id [handle find ds:0]] [read-reg si]
		{} [read-reg ax] [read-reg cx] [read-reg dx] [read-reg bp]]
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

[defcmd objmessagebrk {{objaddr {}}} {object.message profile}
{Usage:
    objmessagebrk [<address>]

Examples:
    "objmessagebrk MyObj"   break whenever a method is sent to MyObj
    "objmessagebrk" 	    stop intercepting methods

Synopsis:
    Break whenever a method is SENT to a particular object via ObjMessage.

Notes:
    * The address argument is the address to an object to watch for
      methods being sent to it.  If no argument is specified then the
      watching is stopped.

    * This breaks whenever a method is sent (before they get on the method
      queue.  This enables one to track identical methods to an object
      which can be removed.

See also:
    objwatch, mwatch, procmessagebrk, pobject.
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
	[print-obj-and-method [read-reg bx] [read-reg si] {} [read-reg ax]
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

    [print-obj-and-method [read-reg bx] [read-reg si] {} [read-reg ax]
		[read-reg cx] [read-reg dx] [read-reg bp] ]
    return 0
}]



[defcmd procmessagebrk {{prochandle {}}} profile
{Usage:
    procmessagebrk [<handle>]

Examples:
    "procmessagebrk 3160h"   break whenever a message is sent to the process
			     whose handle is 3160h
    "procmessagebrk" 	     stop intercepting messages

Synopsis:
    Break whenever a method is SENT to a particular process via ObjMessage.

Notes:
    * The handle argument is the handle of the process to watch.
      If no argument is specified then the watching is stopped.  The process's
      handle may be found by typing 'ps -p'.  The process's handle is the
      number before the process's name.

    * This breaks whenever a method is sent (before they get on the method
      queue.  This enables one to track identical methods to a process
      which can be removed.

See also:
    objwatch, mwatch, objmessagebrk, pobject.
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

    return [expr {$opm_object == [read-reg bx]}]
}]


[defcmd	pod {{objaddr}} print
{Usage:
    pod	<address>

Examples:
    "pod ds:si"

Synopsis:
    Print in output descriptor format (^l<handle>:<chunk>) the address passed.

Notes:
    * The address argument is the address of an object.

}
{
    var chunkaddr [get-chunk-addr-from-obj-addr $objaddr]
    var blockhandle [handle id [index $chunkaddr 0]]
    var chunkoffset [index $chunkaddr 1]
    echo [format {^l%04xh:%04xh} $blockhandle $chunkoffset]
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
#				geowatch
##############################################################################
#
# SYNOPSIS:	Trace all geometry calls on an object
# PASS:		obj	= address expression giving the base of the object
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	any previous geowatch is cancelled
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/28/90		Initial Revision
#
##############################################################################
[defcmd geowatch {{obj {}}} profile
{Usage:
    geowatch [<object>]

Examples:
    "geowatch *MyObj"		display geometry calls that have reached
				    the object MyObj
    "geowatch"			display geometry calls that have reached
				    *ds:si (asm) or oself (goc)

Synopsis:
    Display geometry calls that have reached a particular object.

Notes:
    * Two conditional breakpoints are used by this function (see cbrk).
      The tokens for these breakpoints are returned.

    * The special object flags may be used to specify <object>.  For a
      list of these flags, see pobj.

See also:
    objwatch, mwatch, cbrk.
}
{
    require addr-with-obj-flag user

    var obj [addr-with-obj-flag $obj]
    
    #
    # Locate the chunk handle for the object in question.
    #
    var gw_object [get-chunk-addr-from-obj-addr $obj]
    var gw_objhan [handle id [index $gw_object 0]]
    var gw_chunkhan [index $gw_object 1]

    #
    # Set a conditional breakpoint for the machine to stop any time
    # ObjCallMethodTable is called with this object in mind.
    #
    var gw_brkpt [cbrk aset ui::StartRecalcSize
			si=[index $gw_object 1] 
			ds=^h[handle id [index $gw_object 0]]]
    var gw_brkpt2 [cbrk aset ui::EndRecalcSize
			si=[index $gw_object 1] 
			ds=^h[handle id [index $gw_object 0]]]
    #
    # Alter the command to print something nice, since we can't give
    # both command and criteria to cbrk
    #
    brk cmd $gw_brkpt [list start-calc-new-size $gw_object]
    brk cmd $gw_brkpt2 [list end-calc-new-size $gw_object]
    
    return [list $gw_brkpt $gw_brkpt2]
}]

##############################################################################
#				print-gw
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
[defsubr	start-calc-new-size {gw_object} {

     # print the arguments

    var csym [symbol faddr var *(*ds:si).MB_class]
    if {[null $csym]} {
      echo -n [format {%s(*%04xh:%04xh[?],%04xh,%04xh)}
	    	 CALC_NEW_SIZE [read-reg ds] [read-reg si] [read-reg cx]
		 [read-reg dx]]
    } else {
      echo -n [format {%s(*%04xh:%04xh) (%04xh,%04xh)}
	    	 [symbol name $csym] [read-reg ds] [read-reg si] 
		 [read-reg cx] [read-reg dx]]
    }

    echo
    return 0
}]

[defsubr	end-calc-new-size {gw_object} {
    echo -n [format {-> (%04xh,%04xh)} [read-reg cx]
		[read-reg dx]]

    echo
    return 0
}]

