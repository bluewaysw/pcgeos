##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	swat/lib
# FILE: 	ec.tcl
# AUTHOR: 	Doug Fults, May  5, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	doug	5/ 5/89		Initial Revision
#
# DESCRIPTION:
#	Error checking commands
#
#	$Id: ec.tcl,v 3.32.11.1 97/03/29 11:26:55 canavese Exp $
#
###############################################################################


defvar ec-flags {
    {free 	    ECF_FREE}
    {lmem   	    ECF_LMEM}
    {graphics 	    ECF_GRAPHICS}
    {segment 	    ECF_SEGMENT}
    {normal 	    ECF_NORMAL}
    {vm   	    ECF_VMEM}
    {lmemMove	    ECF_LMEM_MOVE}
    {unlockMove	    ECF_UNLOCK_MOVE}
    {vmemDiscard    ECF_VMEM_DISCARD}
    {app    	    ECF_APP}
    {text    	    ECF_TEXT}
    {high   	    ECF_HIGH}
    {analVM 	    ECF_ANAL_VMEM}
}


defvar old-ec-flags {
    {region 	    OECF_REGION}
    {heapFree 	    OECF_HEAP_FREE_BLOCKS}
    {lmemInternal   OECF_LMEM_INTERNAL}
    {lmemFree 	    OECF_LMEM_FREE_AREAS}
    {lmemObject     OECF_LMEM_OBJECT}
    {graphics 	    OECF_GRAPHICS}
    {segment 	    OECF_SEGMENT}
    {normal 	    OECF_NORMAL}
    {vm   	    OECF_VMEM}
    {lmemMove	    OECF_LMEM_MOVE}
    {unlockMove	    OECF_UNLOCK_MOVE}
    {vmemDiscard    OECF_VMEM_DISCARD}
    {analVM	    OECF_ANAL_VMEM}
    {app    	    OECF_APP}
    {text    	    OECF_TEXT}
}

[defcmd set-startup-ec {args} ec
{Usage:
    set-startup-ec [<args>]

Examples:
    set-startup-ec +vm		turn on VM error checking when starting up
    set-startup-ec none		turn off all ec code when starting up

Synopsis:
    Executes the "ec" command upon startup, to allow one to override the
    default error checking flags.

See also:
    ec
}
{
    global attached
    global savedBrkPoint delayed_startup_ec_event delayed_startup_ec_args

    if {![null $savedBrkPoint]} {
	brk delete $savedBrkPoint
	var savedBrkPoint {}
    }
    if {![null $args]} {
    	if {[null [patient find geos]]} {
    	    #
	    # If kernel not loaded yet, then we can't set a breakpoint in it.
	    # Record the args we want to use and register an event handler for
	    # the START event so we can watch for the kernel being loaded.
	    #
	    var delayed_startup_ec_args $args
	    if {[null ${delayed_startup_ec_event}]} {
	    	var delayed_startup_ec_event [event handle START delayed-startup-ec-install]
    	    }
    	} else {
    	    set-startup-ec-breakpoint $args
    	}
    }
}]

[defsubr set-startup-ec-breakpoint {a}
{
    if {[null [symbol find label geos::GetEC::done]]} {
    	echo Cannot set EC flags: not running error-checking kernel
    } else {
    	global savedBrkPoint
	var savedBrkPoint [brk geos::GetEC::done [concat \[ec $a\]\[expr 0\]]]
    }
}]

[defsubr delayed-startup-ec-install {p}
{
    # if the patient just started was the kernel, do our thing
    if {[patient name $p] == geos} {
    	global savedBrkPoint delayed_startup_ec_event delayed_startup_ec_args
    	#
	# First set the breakpoint appropriately.
	#
    	set-startup-ec-breakpoint $delayed_startup_ec_args
    	#
	# Nuke the event that called us, our task being accomplished
	#
    	event delete $delayed_startup_ec_event
	var delayed_startup_ec_event {}
    	return EVENT_HANDLED
    } else {
    	return EVENT_NOT_HANDLED
    }
}]

[defcmd ec {args} {top.running ec}
{Usage:
    ec [<args>]

Examples:
    "ec"	    	list the error checking turned on
    "ec +vm"    	add vmem file structure checking
    "ec all"  	 	turn on all error checking (slow)
    "ec save none"	save the current error checking and then use none
    "ec restore"	use the saved error checking flags

Synopsis:
    Get or set the error checking level active in the kernel.

Notes:
    * The following arguments may occur in any combination:

	<flag>		turn on <flag>
	+<flag>	    	turn on <flag>
	-<flag>	    	turn off <flag>
	all		turn on all error checking flags
    	ALL	    	turn on *ALL* error checking flags
	none		turn off all error checking flags
	sum <handle>	turn on checksum checking for the memory block with the
			the given handle ("ec sum bx"). The current contents
			of the block will be summed and that sum regenerated
			and checked for changes at strategic points in the
			system (e.g. when a call between modules occurs).
    	    	    	NOTE: when checksum checking is turned on for a
    	    	    	resource, breakpoints in that resource may not be
    	    	    	set or unset, as that will cause the checksum to fail
    	    	    	To get around this, turn off checksum checking, set
    	    	    	or unset any breakpoints you want in that resource
    	    	    	and then re-set/unset checksum checking
	-sum		turn off checksum checking
    	save	    	save the current error checking
    	restore  	restore the saved error checking flags 

      where <flag> may be one of the following:

    COMMON FLAGS
	analVM		perform anal-retentive checking of vmem files
	graphics    	graphics checking
	normal	    	normal error checking
	segment	    	extensive segment register checking
    	lmemMove    	force lmem blocks to move whenever possible
    	unlockMove  	force unlocked blocks to move whenever possible
    	vm  	    	vmem file structure checking
    	vmemDiscard 	force vmem blocks to be discarded if possible
    	app 	    	perform application-specific error-checking
    	text	    	preform intensive text object error-checking

    NEW FLAGS
    	free    	heap free and lmem free block checking
	lmem	    	lmem error checking
    	high	    	various more-intesive error checking

    OLD FLAGS: (only available on Upgrade, Zoomer and Wizard)
	region	    	region checking
	lmemFree    	lmem free area checking
	lmemInternal	internal lmem error checking
	lmemObject  	lmem object checking

    * If there isn't an argument, 'ec' reports the current error
      checking flags.

    * Each time GEOS is run the ec flags are cleared.  The saved flags
      are preserved between sessions.  The ec flags may be saved and
      then restored after restarting GEOS so that the flag settings are not
      lost when restarting GEOS.

See also:
    why.
}
{	
    global ec-flags old-ec-flags
    global savedECFlags
    global attached geos-release

    var oecf [symbol find type geos::OldErrorCheckingFlags]
    if {![null [patient find geos]] && ([null $oecf] || ![kernel-has-table])} {
    	# kernel before ECF re-org.

	if {[null $oecf]} {
	    # using old .sym/.gym file too use the old-ec-flags, but we have to
	    # strip the leading O from the record field component to match
	    # the symbols in this kernel, where what we now think of as old
	    # was actually avant-garde.

	    var ecflags [map f ${old-ec-flags} {
		list [index $f 0] [range [index $f 1] 1 end chars]
	    }]
    	} else {
    	    # old kernel (no internal-symbol table) but new .gym file (has
	    # both ECF and OECF flags), so use the old-ec-flags list straight
	    
	    var ecflags ${old-ec-flags}
    	}
    	var doall {+region +heapFree +lmemInternal +lmemFree
		   +lmemObject +graphics +segment +normal +vm}
    	var doALL {+region +heapFree +lmemInternal +lmemFree
		   +lmemObject +graphics +segment +normal +vm
		   +app +lmemMove +unlockMove +vmemDiscard
		   +analVM +text}
    } else {
    	# kernel after ECF re-org using up-to-date .sym/.gym file
    	var ecflags ${ec-flags}
	var doall {+normal +segment +graphics +lmem +high +free}
	var doALL {+normal +segment +graphics +lmem +high +free
	    	   +vm +app +lmemMove +unlockMove +vmemDiscard +text}
    }

    protect {
	#
	# Turn off the data cache to avoid problems with changing the EC
	# level and having an event get generated while the machine is
	# stopped (sysECLevel and freeHandlePtr are usually in the same
	# data-cache block, so the old value of freeHandlePtr gets flushed
	# back when the machine restarts, generating instant EC death)
	#
	dcache off

    	if {[string last gym [patient path [patient find geos]] NO_CASE] != -1} {
    	    if {[kernel-has-table]} {
    	    	var ecLevelAddr [address-kernel-internal sysECLevel]
    	    } else {
    	    	error {Unable to access kernel's EC flags}
    	    }
       	} else {
    	    var ecLevelAddr sysECLevel
    	}

	if {[null $args]} {
	    if {!$attached} {
		error {The error-checking flags for the kernel cannot be read if you're not attached}
	    } elif {${geos-release} >= 2 && [null [patient find geos]]} {
		error {The error-checking flags for the kernel cannot be read until the kernel has been loaded}
	    }

	    var cur [value fetch $ecLevelAddr [type word]]

	    echo -n {Current error checking flags: }
	    precord geos::ErrorCheckingFlags $cur 1
	    if {$cur&[fieldmask ECF_BLOCK_CHECKSUM]} {
		echo [format
			{Checksum checking on block: %04xh (checksum is %04xh)}
			[value fetch sysECBlock] [value fetch sysECChecksum]]
	    }
	} else {
	    if {!$attached} {
		error {The error-checking flags for the kernel cannot be altered if you're not attached}
	    } elif {${geos-release} >= 2 && [null [patient find geos]]} {
    	    	var delayed_ec 1
		global ec_block ec_set_flags ec_reset_flags
    	    	require delassoc lisp
	    } else {
	    	var cur [value fetch $ecLevelAddr [type word]]
	    	var delayed_ec 0
    	    }

	    while {![null $args]} {
		var i [car $args]
		var args [cdr $args]
		[case $i in
		    sum {
		    	var b [addr-parse [car $args] 0]
			[if {![null [index $b 0]] && 
			     [string c [index $b 0] value]}
    	    	    	{
    	    	    	    var b [handle id [index $b 0]]
    	    	    	} else {
			    var b [index $b 1]
    	    	    	}]
			if $delayed_ec {
			    var ec_block $b
			    var ec_set_flags [concat $ec_set_flags
			    	    	    	ECF_BLOCK_CHECKSUM]
		    	    var ec_reset_flags [delassoc $ec_reset_flags
			    	    	    	ECF_BLOCK_CHECKSUM]
    	    	    	} else {
    	    	    	    assign [address-kernel-internal sysECBlock] $b
			    assign {word [address-kernel-internal sysECChecksum]} 0
			    var cur [expr $cur|[fieldmask ECF_BLOCK_CHECKSUM]]
    	    	    	}
			var args [cdr $args]
		    }
		    -sum {
    	    	    	if $delayed_ec {
			    var ec_block 0
			    
			    var ec_reset_flags [concat $ec_reset_flags
			    	    	    	ECF_BLOCK_CHECKSUM]
		    	    var ec_set_flags [delassoc $ec_set_flags
			    	    	    	ECF_BLOCK_CHECKSUM]
    	    	    	} else {
		    	    var cur [expr $cur&~[fieldmask ECF_BLOCK_CHECKSUM]]
			    assign [address-kernel-internal sysECBlock] 0
    	    	    	}
		    }

		    all {
    	    	    	var args [concat $doall $args]
    	    	    }
    	    	    ALL {
    	    	    	var args [concat $doALL $args]
    	    	    }
		    none {
		    	var args [concat [map f ${ecflags} {
    	    	    	    format {-%s} [index $f 0]
    	    	    	}] $args]
    	    	    }

		    save {
    	    	    	if $delayed_ec {
			    error {cannot save error-checking state if kernel not loaded}
    	    	    	}
		    	var savedECFlags $cur
    	    	    }
		    restore {
		    	if $delayed_ec {
			    error {cannot restore error-checking state if kernel not loaded}
    	    	    	}
			[if {![null $savedECFlags]} {
			    var cur $savedECFlags
			}]
		    }
		    +* {
			var field [assoc ${ecflags} [range $i 1 end chars]]
			if {[null $field]} {
			    echo Invalid option: $i
			} else {
			    if $delayed_ec {
			    	var ec_set_flags [concat $ec_set_flags
				    	    	    [index $field 1]]
				var ec_reset_flags [delassoc $ec_reset_flags
				    	    	    [index $field 1]]
    	    	    	    } else {
			    	var cur [expr $cur|[fieldmask [index $field 1]]]
    	    	    	    }
			}
		    }
		    -* {
			var field [assoc ${ecflags} [range $i 1 end chars]]
			if {[null $field]} {
			    echo Invalid option: $i
			} else {
			    if $delayed_ec {
			    	var ec_reset_flags [concat $ec_reset_flags
						    [index $field 1]]
				var ec_set_flags [delassoc $ec_set_flags
						  [index $field 1]]
    	    	    	    } else {
			    	var cur [expr $cur&~[fieldmask [index $field 1]]]
    	    	    	    }
			}
		    }
		    default {
			var field [assoc ${ecflags} $i]
			if {[null $field]} {
			    echo Invalid option: $i
			} else {
			    if $delayed_ec {
			    	var ec_set_flags [concat $ec_set_flags
						  [index $field 1]]
				var ec_reset_flags [delassoc $ec_reset_flags
						    [index $field 1]]
    	    	    	    } else {
			    	var cur [expr $cur|[fieldmask [index $field 1]]]
    	    	    	    }
			}
		    }
		]
	    }

	    if {$delayed_ec} {
	    	global ec_start_event
		
		if {[null $ec_start_event]} {
		    var ec_start_event [event handle START ec_delayed_check_bpt]
    	    	}
	    } else {
	    	assign {word $ecLevelAddr} $cur
    	    }
	}
    } {
	#
	# Re-enable the data cache...
	#
	dcache on
    }
}]

[defsubr ec_delayed_check_bpt {args}
{
    if {[string c [patient name [index $args 0]] geos] == 0} {
    	if {![brk isset geos::ec_set]} {
	    brk aset geos::ec_set {ec_delayed_install}
    	}
	ec_delayed_install
    }
    return EVENT_HANDLED
}]

[defsubr ec_delayed_install {args}
{
    global ec_block ec_set_flags ec_reset_flags
    
    protect {
    	dcache off
	
    	if {![null $ec_block]} {
	    assign [address-kernel-internal sysECBlock] $ec_block
	    assign [address-kernel-internal sysECChecksum] 0
    	}
	var cur [value fetch [address-kernel-internal sysECLevel] word]
	if {![null $ec_set_flags]} {
	    foreach f $ec_set_flags {
	    	var cur [expr $cur|[fieldmask geos::$f]]
    	    }
    	}
	
	if {![null $ec_reset_flags]} {
	    foreach f $ec_reset_flags {
	    	var cur [expr $cur&~[fieldmask geos::$f]]
    	    }
    	}
	
	value store [address-kernel-internal sysECLevel] $cur word
    } {
    	dcache on
    }
    return 0
}]

