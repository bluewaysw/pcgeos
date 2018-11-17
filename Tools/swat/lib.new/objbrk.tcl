##############################################################################
#
# 	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	Swat
# MODULE:	System Library
# FILE: 	objbrk.tcl
# AUTHOR: 	Adam de Boor, Oct  8, 1991
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	objbrk
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	10/8/91		Initial Revision
#
# DESCRIPTION:
#	Breakpoints for particular messages being delivered to one or more
#   	objects
#
#	$Id: objbrk.tcl,v 1.11.12.1 97/03/29 11:26:27 canavese Exp $
#
###############################################################################

defvar objbrks	nil

require bpt-init bptutils

defvar objbrk-token [bpt-init objbrks objbrk maxobjbrk
       	    	    	objbrk-set-callback objbrk-unset-callback]
defsubr isqueue {h} {return [expr ([handle state $h]&0xf8000)==0x40000]}

##############################################################################
#				objbrk-unset-callback
##############################################################################
#
# SYNOPSIS:	    Tell the stub to get rid of an objbrk
# PASS:		    bnum    = number of the objbrk being nuked
#   	    	    brknum  = number from cbrk's perspective
#   	    	    data    = data list for the objbrk
#   	    	    alist   = address list where the breakpoint is set
#   	    	    why	    = "exit" if we should really remove the thing,
#			      or "out" if the block just got discarded or
#			      swapped out
# CALLED BY:	    bpt utils
# RETURN:	    non-zero if breakpoint actually removed
# SIDE EFFECTS:	    stub may be called to remove the thing
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/10/91	Initial Revision
#
##############################################################################
[defsubr objbrk-unset-callback {bnum brknum data alist why}
{
    if {$why == exit} {
    	# we're doing the clearing, so don't tell us about it
    	cbrk delcmd $brknum
    	# now clear it
    	cbrk clear $brknum

	return 1
    } else {
    	return 0
    }
}]

##############################################################################
#				objbrk-set-callback
##############################################################################
#
# SYNOPSIS:	    Set the object breakpoint in the stub.
# PASS:		    bnum    = number of breakpoint to set
#   	    	    brknum  = value returned from previous call
#   	    	    data    = two-list containing address list of object for
#			      which breakpoint is being set and the condition
#			      for the message on which we should break.
#   	    	    alist   = address list where bpt is set (the object)
#   	    	    why	    = "start" if patient just starting or bpt
#			      never been set before. "in" if block
#			      just came in from executable or swap.
# CALLED BY:	    bpt utils
# RETURN:	    value to pass to unset callback (the stub's number
#		    for the bpt)
# SIDE EFFECTS:	    the stub is called if "start", else nothing
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/16/92		Initial Revision
#
##############################################################################
[defsubr objbrk-set-callback {bnum brknum data alist why}
{
    if {$why == start} {
    	#
	# Call the stub, passing it the offset and segment (in that order)
	# at which the objbrk should be set, expecting to get a word back
	# (the stub's breakpoint number)
	#
    	var h [index $alist 0]
	if {[handle isthread $h]} {
	    var objbrk [eval [concat cbrk aset ObjCallMethodTable
				ds=[patient name [handle patient $h]]::dgroup
				thread=[handle id $h]
				[index $data 0]]]
    	} elif {[isqueue $h]} {
	    #
	    # event queue. Can only catch these at ObjMessage
	    #
	    var objbrk [cbrk aset ObjMessage bx=[handle id $h]]
    	} else {
	    #
	    # if pass "chunk" handle is 0, then match any objects in block --
	    # don't put any criteria on si
	    #
	    var objbrk [eval [concat cbrk aset ObjCallMethodTable
			    [if {[index $alist 1]} {
				list si=[index $alist 1]
			    }]
			    ds=^h[handle id [index $alist 0]]
			    [index $data 0]]]
    	}
	brk cmd $objbrk [concat ob-trigger $bnum]
	brk delcmd $objbrk [concat objbrk-delete $bnum]

    	return $objbrk
    } else {
    	return $brknum
    }
}]


##############################################################################
#				objbrk-delete
##############################################################################
#
# SYNOPSIS:	Remove the object breakpoint with the given number from the
#   	    	list of all object breakpoints.
# PASS:		bnum	= number of the object breakpoint to remove
#   	    	free	= if non-zero, nukes the associated conditional
#   	    	    	  breakpoint and interest record
# CALLED BY:	brk when objbrk token is being nuked.
# RETURN:	nothing
# SIDE EFFECTS:	entry removed from the table of objbrks
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	10/8/91		Initial Revision
#
##############################################################################
[defsubr objbrk-delete {bnum}
{
    global  objbrk-token
    
    bpt-unset ${objbrk-token} $bnum 1
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
[defcommand objbrk {args} {top.breakpoint object.message patient.message}
{Usage:
    objbrk <object> [<message>]
    objbrk <special object flags> [<message>]
    objbrk <object block> [<message>]
    objbrk <patient> [<message>]
    objbrk list
    objbrk del <objbrk>

Examples:
    "oj ^l4c30h:001eh	    	break whenever object at ^l4c30h:001eh is called
    "objbrk ^l4c30h:001eh	break whenever object at ^l4c30h:001eh is called
    "objbrk oself MSG_FOO"	break when MSG_FOO arrives at cur object (C)
    "objbrk *ds:si MSG_FOO"	break when MSG_FOO arrives at cur object (asm)
    "objbrk FooObject"		break whenever a message arrives at object
    "objbrk FooResource"	break on any message arriving at resource
    "objbrk ^h4c30h	"	break on any messages arriving in block ^h4c30h
    "objbrk -p"			break on any message arriving at current process
    "objbrk -f" MSG_META_KBD_CHAR	
    	    	    	    	break on kbd char arriving at cur focus
    "objbrk myapp"		break on any message going to patient myapp
    "objbrk list"   	    	lists all active object breakpoints
    "objbrk del 4"   	    	deletes object breakpoint 4

Synopsis:
    Break when a particular object, or group of objects, gets messaged.  You
    can break on a certain message, or leave the message unspecified.  This
    command is good for discriminating between messages sent to one object of
    many in its class, or where you aren't sure what the incoming message
    will be.

Notes:
    * If you do not give a <message> argument after the <obj> argument, the
      machine will stop when any message is delivered to the object.

    * <obj> is the address of the object to watch. 
    
    * The <objbrk> argument to "objbrk del" is the token/number returned when
      you set the breakpoint.

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
    objwatch, mwatch, brk, objmessagebrk, procmessagebrk, gentree, vistree,
    classtree, methods, gup, vup, cup, pobject
}
{
    global  objbrk-token maxobjbrk
    
    [case [index $args 0] in
    	list {
    	    echo [format {%-3s %-30s  %-20s  %-20s} Num Object Class Message]
    	    for {var b 0} {$b < $maxobjbrk} {var b [expr $b+1]} {
    	    	var addr [bpt-addr ${objbrk-token} $b]
    	    	var obj [index $addr 0]
		if {[null $obj]} {
		    continue
    	    	}

	    	var data [index [bpt-get ${objbrk-token} $b] 0]
		var h [index $obj 0]
		var hid [handle id $h] chunk [index $obj 1]
		if {$hid == 0} {
		    [var objname {patient gone} classname {class unknown}
		    	methname [index $data 1]]
    	    	} else {
		    if {[handle isthread $h]} {
		    	var objname [threadname $hid]
			var objclass [symbol faddr var
				      *[thread register 
				        [handle other $h] ss]:TPD_classPointer]
    	    	    	var objaddr {}
    	    	    } elif {[isqueue [index $obj 0]]} {
		    	var objname [format {queue %04xh} [handle id $h]]
    	    	    	var objclass {} objaddr {}
    	    	    } else {
			var objsym [symbol faddr var ^h$hid:$chunk]
			if {![null $objsym]} {
			    var objname [format {^l%04xh:%04xh (%s)} $hid $chunk
					    [symbol name $objsym]]
			} else {
			    var objname [format {^l%04xh:%04xh} $hid $chunk]
			}
			var objclass [obj-class ^l$hid:$chunk]
			var objaddr ^l$hid:$chunk
    	    	    }
		    if {![null $objclass]} {
			var classname [symbol fullname $objclass]
    	    	    	if {[null [index $data 1]]} {
			    var methname any
    	    	    	} else {
			    var methname [map-method [index $data 1]
						     $classname
						     $objaddr]
    	    	    	}
			var classname [symbol name $objclass]
			var l [length $classname chars]
			[if {[string c [range $classname [expr $l-5] end chars]
				Class] == 0}
			{
			    var classname [range $classname 0 [expr $l-6] chars]
			}]
		    } else {
			var classname {class unknown}
			var methname [index $data 1]
			if {[null $methname]} {
			    var methname any
    	    	    	}
		    }
    	    	}
		
		echo [format {%3d %-30s  %-20s  %-20s}
		    	    $b
			    [bpt-trim-name $objname 30]
			    [bpt-trim-name $classname 20]
			    $methname]
    	    }
	    return
    	}
	{del clear delete} {
	    foreach barg [range $args 1 end] {
	    	var nums [bpt-parse-arg $barg ${objbrk-token}]
    	    	if {[null $nums]} {
		    echo objbrk: ${barg}: no such breakpoint defined
    	    	} else {
		    foreach b $nums {
		    	bpt-unset ${objbrk-token} $b
    	    	    }
    	    	}
    	    }
	    return
	}
    ]
    
    var obj [index $args 0] message [index $args 1]
    if {![null $obj]} {

    	if {[length $args] > 1} {
    		var mcond ax=[getvalue [index $args 1]]
    	} else {
    		var mcond ax!=MSG_META_MOUSE_PTR
    	}

        #
        # Figure what number to assign this breakpoint.
        #
        var bnum [bpt-alloc-number ${objbrk-token}]
	
        #
        # Locate the chunk handle for the object in question.
        #
        var obj [get-chunk-addr-from-obj-addr [addr-with-obj-flag $obj]]
    
        if {[bpt-set ${objbrk-token} $bnum [list $mcond $message] $obj]} {
	        return objbrk$bnum
        }
    } else {
    	error {Usage: objbrk (del|delete|clear|list|<obj> [<message>])}
    }
}]


##############################################################################
#				ob-trigger
##############################################################################
#
# SYNOPSIS:	Trigger an object breakpoint
# PASS:		bnum	= object-breakpoint number to check
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
[defsubr ob-trigger {bnum}
{
    global	objbrk-token

    var obj [index [bpt-addr ${objbrk-token} $bnum] 0]
    var message [index [index [bpt-get ${objbrk-token} $bnum] 0] 1]
    var h [index $obj 0]

    #
    # Check condition and come up with name to give user for the target
    # of the call.
    #
    [if {[handle isthread $h]} {
    	[if {[read-reg ds] == 
	     [handle segment
	      [handle find [patient name [handle patient $h]]::dgroup:0]]}
    	{
	    var target [threadname [read-reg curThread]]
	    var objorclass [symbol fullname
			    [symbol faddr var *ss:TPD_classPointer]]
    	} else {
	    return 0
    	}]
    } elif {[isqueue $h]} {
    	# event queue -- no address to check
    	var target [format {queue %04xh} [handle id $h]]
    } elif {[read-reg ds] == [handle segment $h] &&
	    [test-si-cond [read-reg si] [index $obj 1]]}
    {
    	var target [format {^l%04xh:%04xh} [handle id $h] [read-reg si]]
	var label [format {@%d, } [value hstore [addr-parse $target]]]
	var objorclass *ds:si
    } else {
    	return 0
    }]
    
    if {[test-msg-cond [read-reg ax] $message]} {
    	if {![isqueue $h]} {
    	    #
	    # Not watching a queue, so go to the start of the method
	    #
	    require istep-go-to-next-method istep
	    istep-go-to-next-method
    	}
	require class-addr-with-obj-flag class
	echo [format {%s being delivered to %s (%s%s)}
	        [if {[null $message]} {
			[if {[null $objorclass]} {
				format %d [read-reg ax]}
		   		{map-method [read-reg ax] $objorclass
			}]
		}
		{var message}]
		[symbol name [symbol faddr var
				[class-addr-with-obj-flag $target]]]
		$label
		$target]

    	# Keep machine stopped now we're where we want to be.
	return 1
    } else {
    	return 0
    }
}]

[defsubr test-msg-cond {ax msg}
{
	if {[null $msg]} {

# Discard of "Internal" messages removed here until we can make sure this
# is only done for generic objects.  - Doug 7/6/93

		# Skip Vis, Spui for generic objects=16384-24575
#		if {[expr ($ax>=4000h)&&($ax<6000h)]} {return 0}

		# Skip normal button messages
#		if {[expr ($ax>=265)&&($ax<=276)]} {return 0}

		# Skip pre, post passive button message
#		if {[expr ($ax>=277)&&($ax<=294)]} {return 0}

		# Skip mouse/kbd gain/loss
#		if {[expr ($ax>=224)&&($ax<=227)]} {return 0}

		# Skip MSG_META_MOUSE_PTR=118
		# Skip MSG_META_TEST_WIN_INTERACTIBILITY=322
		# Skip MSG_META_IMPLIED_WIN_CHANGE=74
		# Skip MSG_META_RAW_UNIV_LEAVE=76
		# Skip MSG_META_RAW_UNIV_ENTER=75
		# Skip MSG_META_ENSURE_NO_MENUS_IN_STAY_UP_MODE=309
		# Skip MSG_META_MUP_ALTER_FTVMC_EXCL=242
		# Skip MSG_META_EXPOSED=69
		# Skip MSG_META_WIN_UPDATE_COMPLETE=71
		# Skip MSG_META_QUERY_IF_PRESS_IS_INK=263
		# Skip MSG_META_WIN_DEC_REF_COUNT=50
		# Skip MSG_META_RELEASE_FT_EXCL=241
		# Skip MSG_META_CONTENT_ENTER=189
		# Skip MSG_META_CONTENT_LEAVE=190
		# Skip MSG_META_IS_OBJECT_IN_CLASS=14
		# Skip MSG_META_OBJ_FLUSH_INPUT_QUEUE=49
		# Skip MSG_META_RESOLVE_VARIANT_SUPERCLASS=19
		#
#		[case $ax in
#			{16384-24575} {return 0}
#			{118 278 277 322 74 76 75 309 242 69 71 263 50 241 189 190 14 49 19} {
#				return 0
#			}
#			default {return 1}
#		]
		return 1
	} else {
		return [expr $ax==[getvalue $msg]]
	}
}]

[defsubr test-si-cond {si ch}
{
	if {$ch} {
		return [expr $si==$ch]
	} else {
		return 1
	}
}]

alias oj {objbrk list}
