##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	emacs.tcl
# FILE: 	emacs.tcl
# AUTHOR: 	Adam de Boor, Feb  2, 1990
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	2/ 2/90		Initial Revision
#
# DESCRIPTION:
#	Functions for talking to emacs in its server mode.
#
#	$Id: emacs.tcl,v 3.10 90/10/31 12:51:50 tony Exp $
#
###############################################################################
defvar emacs-event nil
defvar emacs-stream nil

[defvar emacsIgnore 1 variable.output
{If non-zero, ewatch ignores all routines in emacs-ignore-list}]

[var emacs-ignore-list {
    BootGeos FatalError ProcCallModuleRoutine ObjCallMethodTable SendMessage
    SendMessageAndEC ObjMessage Dispatch BlockOnLongQueue LibraryCallInt
    CallMethodCommon CallMethodCommonLoadESDI ObjCallInstanceNoLock
    SerialPrimaryInt ECCheckDirectionFlag WakeUpLongQueue BlockOnLongQueue
    EndGeos
}]

[defsubr emacs-show {args}
{
    global emacs-ignore-list emacsIgnore

    if {$emacsIgnore} {
	var ignore 0
	if {[catch {frame function} ff] == 0} {
	    # echo >>> $ff <<<
	    [foreach i ${emacs-ignore-list} {
		if {[string c $i $ff] == 0} {
		    var ignore 1
		    break
		}
	    }]
    	}
	if {$ignore == 0} {
	    emacs-real-show
	}
    } else {
	emacs-real-show
    }
    return EVENT_HANDLED
}]

[defsubr emacs-real-show {args}
{
    [if {[catch {src line [frame register pc]} fileLine] == 0 &&
	 ![null $fileLine]} 
    {
	global emacs-stream
	[if {![null ${emacs-stream}] &&
	     [string c [stream state ${emacs-stream}] error] == 0}
	{
	    stream close ${emacs-stream}
	    var emacs-stream nil
	}]
	if {[null ${emacs-stream}]} {
	    if {[file [getenv HOME]/.emacs_server exists]} {
		var emacs-stream [stream open [getenv HOME]/.emacs_server r+]
		if {[null ${emacs-stream}]} {
		    return EVENT_HANDLED
		}
	    } else {
		return EVENT_HANDLED
	    }
	}
	stream write [format {>%d %s \n} [index $fileLine 1]
			[index $fileLine 0]] ${emacs-stream}
	stream flush ${emacs-stream}
    }]
}]

[defcommand ewatch {args} top
{This command controls the monitoring of program execution by EMACS. To
operate, you must have executed "start-server" in your EMACS, either by
typing M-x start-server or by having the command (start-server nil) in your
.emacs file.

The command takes three possible subcommands:
    on	    every time the machine stops or you change stack frames, EMACS
    	    will display the file and line for the current cs:ip, placing 
	    a little "=>" at the start of the line so you know where it is.
    off	    disables the above.
    show    causes EMACS to display the current frame's cs:ip, but only does
    	    it once -- it won't follow the execution on the PC.

If you give no arguments, ewatch will just return the current state of the
watching mechanism.}
{
    global emacs-event
    if {[null $args]} {
    	return [if {[null ${emacs-event}]} {concat off} {concat on}]
    } else {
    	[case $args in
	    {[Oo][Nn]*} {
		if {[null ${emacs-event}]} {
		    var emacs-event [list
			[event handle FULLSTOP emacs-show]
			[event handle STACK emacs-show]
			[event handle CHANGE emacs-show]
		    ]
		}
    	    }
	    {[Oo][Ff]*} {
		if {![null ${emacs-event}]} {
		    global emacs-stream
		    if {![null ${emacs-stream}]} {
			stream close ${emacs-stream}
			var emacs-stream nil
		    }
		    foreach i ${emacs-event} {
			event delete $i
		    }
		    var emacs-event nil
		 }
    	    }
	    {[Ss]*} {
	    	emacs-show
	    }
    	    default {
        	error {Usage: ewatch [(on|off|show)]}
    	    }
    	]
    }
}]

[defsubr goto {file line}
{
    global emacs-stream
    [if {![null ${emacs-stream}] &&
	 [string c [stream state ${emacs-stream}] error] == 0}
    {
	stream close ${emacs-stream}
	var emacs-stream nil
    }]
    if {[null ${emacs-stream}]} {
	if {[file [getenv HOME]/.emacs_server exists]} {
	    var emacs-stream [stream open [getenv HOME]/.emacs_server r+]
	    if {[null ${emacs-stream}]} {
		return
	    }
	} else {
	    return
	}
    }
    stream write [format {>%d %s \n} $line $file] ${emacs-stream}
    stream flush ${emacs-stream}
}]



[defcommand emacs {{routine cs:ip}} top
{	Like vi, makes your emacs bring up the source line corresponding to
	the current address expression, or cs:ip if no argument is specified.  
	ewatch must be on.
}
{
    var srcline [src line $routine]
    goto [index $srcline 0] [index $srcline 1]
}]
