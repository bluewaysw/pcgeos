##############################################################################
#
# 	Copyright (c) GeoWorks 1990 -- All Rights Reserved
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
#	$Id: emacs.tcl,v 3.46 97/04/29 17:28:21 dbaumann Exp $
#
###############################################################################
defvar emacs-event nil
defvar emacs-stream nil
defvar emacs-debug 0

[defvar emacsIgnore 1 swat_variable.output
{If non-zero, ewatch ignores all routines in emacs-ignore-list}]

defvar emacs-ignore-list {
    BootGeos FatalError ProcCallModuleRoutine ObjCallMethodTable SendMessage
    SendMessageAndEC ObjMessage Dispatch BlockOnLongQueue LibraryCallInt
    CallMethodCommon CallMethodCommonLoadESDI ObjCallInstanceNoLock
    SerialPrimaryInt ECCheckDirectionFlag WakeUpLongQueue BlockOnLongQueue
    EndGeos LoadGeos FarDebugProcess ResourceCallInt FSIdleIntercept Idle
    ThreadGetInfo LoaderError GeodeNotifyLibraries ObjCallMethodTableSaveBXSI
    DispatchEventLow DispatchFromQueueLow ThreadAttachToQueue
    ObjGotoSuperTailRecurse ProcCallFixedOrMovable DOSIdleHook
}

[defsubr emacs-show {args}
{
    global emacs-ignore-list emacsIgnore

    if {$emacsIgnore} {
	var ignore 0
	if {[catch {frame function} ff] == 0} {
	    # echo >>> $ff <<<
	    case $ff in ${emacs-ignore-list} {var ignore 1}
    	}
	if {$ignore == 0} {
	    emacs-real-show
	}
    } else {
	emacs-real-show
    }
    return EVENT_HANDLED
}]

##############################################################################
#				emacs-extract-subfile
##############################################################################
#
# SYNOPSIS:	Fetch the subfile below the PC/GEOS root of the passed file.
#   	    	handles things in the user's development tree and in the
#   	    	installed tree.
# PASS:		path	= the absolute file/directory name
# CALLED BY:	emacs-break
# RETURN:	the path below the PC/GEOS root, with leading /
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/21/91		Initial Revision
#
##############################################################################
[defsubr emacs-extract-subfile {path}
{
    global file-devel-dir file-branch

    if {[string first ${file-devel-dir} $path] == 0} {
    	#
	# File is in development tree..
	#
	return [range $path [length ${file-devel-dir} chars] end chars]
    } else {
        var pcgeos [string first pcgeos $path]
	var path [range $path [expr $pcgeos+6] end chars]
	if {[string first /${file-branch}/ $path] == 0} {
	    return [range $path [length /${file-branch} chars] end chars]
	} else {
            return $path
	}
    }
}]

#    } elif {[null $a]}  {
#	#
#	# That didn't work -- try the "pcgeos" path to the
#	# executable, too...
#	#
#	var a [src addr
#		   [range $path 0 
#		    [expr [string first pcgeos $path]+6]
#		    chars]${subfile} $line $p]
#
#	if {[null $a]} {
#	    #
#	    # Might be on a branch. Make sure to get the whole root
#	    # directory, up to the Installed directory and try
#	    # that.
#	    #
#	    var root [range $path 0
#			    [expr {[length $path char]-
#				   [length
#				    [emacs-extract-subfile $path]
#				    char]-
#				   1}]
#			    char]
#	    var a [src addr ${root}${subfile} $line $p]
#	    if {[null $a]} {
#		#
#		# XXX: Last-ditch hack. Use that, but with /staff
#		# instead of whatever local disk might be there...
#		#
#		var a [src addr /staff/[range $root [string first pcgeos $root] end chars]${subfile} $line $p]
#	    }
#	}
#    }

##############################################################################
#				emacs-try-break
##############################################################################
#
# SYNOPSIS:	See if we can find an address for a source file in a
#		likely-looking patient
# PASS:		file	= file name, from the patient's perspective
#   	    	line	= line number within the file at which to set bp
#   	    	p   	= likely-looking patient
# CALLED BY:	emacs-break
# RETURN:	breakpoint token, or null
# SIDE EFFECTS:	if address for file found, then breakpoint is set
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	10/ 7/92	Initial Revision
#
##############################################################################
[defsubr emacs-try-break {file line p subdir {tbrk 0}}
{
    global file-root-dir

    var a [src addr $file $line $p]
    if {[null $a]} {
    	#
	# Not in there from the patient's perspective, so try installed
	# form.
	#
    	var path ${file-root-dir}${subdir}/${file}
	var a [src addr $path $line $p]
	if {[null $a] && [string m $file ../*]} {
	    #
	    # Ok, not in installed, but path begins with .., so try stripping
	    # back pieces of subdir as appropriate
	    #
	    var path [explode ${file-root-dir}$subdir /]
	    var i 0
	    foreach c [explode $file /] {
	    	if {[string c $c ..] == 0} {
		    var i [expr $i+1]
    	    	} else {
    	    	    break
    	    	}
    	    }
	    var path [mapconcat c
	    	    	    [range [concat
			            [range $path 0 [expr [length $path]-$i-1]]
				    [range [explode $file /] $i end]]
				   1 end]
    	    {
	    	format /%s $c
    	    }]
	    
	    var a [src addr $path $line $p]
        }
	if {[null $a]} {
	    #
	    # Try replacing whatever comes before "pcgeos" with /staff, as
	    # a hack that works here, but not elsewhere.
	    #
	    var path /staff/[range $path [string first pcgeos $path] end char]
	    var a [src addr $path $line $p]
    	}
    }
    
    if {![null $a]} {
	if {$tbrk} {
	    return [brk tset ^h[handle id [index $a 0]]:[index $a 1]]
	} else {
	    return [brk ^h[handle id [index $a 0]]:[index $a 1]]
	}
    }
}]

##############################################################################
#				emacs-break
##############################################################################
#
# SYNOPSIS:	Set a breakpoint using information from emacs.
# PASS:		file	= absolute name of file in which to set the breakpoint
#   	    	line	= line number at which to set it.
# CALLED BY:	emacs-stream-watcher via "eval"
# RETURN:	nothing
# SIDE EFFECTS:	?
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/21/91		Initial Revision
#
##############################################################################
[defsubr emacs-break {file line {tbrk 0}}
{
    global file-devel-dir emacs-stream file-root-dir file-branch

    var subfile [emacs-extract-subfile $file]
    var sfcomps [explode $subfile /]
    var sfclen [length $sfcomps]

    foreach p [patient all] {
    	var path [patient path $p]
	var subdir [file dirname [emacs-extract-subfile $path]]
	if {[string match $subdir /Installed/*]} {
    	    var subdir [range $subdir 10 end chars]
    	}
	[if {[file exists ${file-root-dir}${subdir}/IS_A_PRODUCT] ||
	     (![null ${file-branch}] &&
	     [file exists ${file-root-dir}/${file-branch}${subdir}/IS_A_PRODUCT])}
    	{
	    var subdir [file dirname $subdir]
    	}]
#    	if {[string match $subfile /Library/CommonUI/*]} {
#    	    [case $subdir in
#	    	{/Library/Motif|/Library/CUA|/Library/Mac} {
#    	    	    debug
#		    var l [string first /Library/ $path]
#		    var s [string first / [range $path [expr $l+9] end char]]
#		    var l2 [string first /Library/ $file]
#		    var s2 [string first / [range $file [expr $l+9] end char]]
#		    var subfile ../CommonUI/[range $file [expr $l2+9+$s2+1] end char]
#		    var file [range $path 0 [expr $l+9+$s-1] char]/$subfile
#    	    	}
#    	    ]
#    	}
	
	if {[string first $subdir $subfile] == 0} {
    	    #
	    # file is under same tree as executable -- this is probably
	    # it...see if the full name is known.
	    #
    	    var retval [emacs-try-break [range $subfile
					 [expr [length $subdir char]+1] end char]
					$line $p $subdir $tbrk]
    	} else {
	    var sdcomps [explode $subdir /]
	    if {[string c [index $sfcomps 1] [index $sdcomps 1]]} {
    	    	# Not even in the same tree below PCGEOS, so don't consider it
    	    	continue
    	    }
	    
    	    #
	    # For each component that doesn't match, between $file and the
	    # directory that contains $p, up to the length of $subdir, we'll
	    # need to go up a level to get to the directory that holds $file.
	    # This conglomeration of ..'s (XXX: should there ever be more than
	    # one?) goes in $up
	    #
	    var sdclen [length $sdcomps] up {} over {}
	    for {var i 0} {$i < $sdclen} {var i [expr $i+1]} {
	    	if {[string c [index $sfcomps $i] [index $sdcomps $i]]} {
		    var up ${up}../
		    var over ${over}[index $sfcomps $i]/
    	    	}
    	    }
	    #
	    # Now append the remaining components from $subfile to that
	    #
	    while {$i < $sfclen} {
	    	var over ${over}[index $sfcomps $i]/
		var i [expr $i+1]
    	    }
    	    # strip final backslash
	    var over [range $over 0 [expr [length $over char]-2] char]
    	    # try that on for size
	    var retval [emacs-try-break ${up}${over} $line $p $subdir $tbrk]
    	}
	if {![null $retval]} {
	    break
	}
    }
    if {[null $retval]} {
    	# Tell emacs to report an error
    	stream write [format {"(error "can't find address for %s:%d")\n}
	    	    	$file $line] ${emacs-stream}
    } else {
    	var addr [brk addr $retval]
	var a [addr-parse $addr] s [symbol faddr label $addr]
	if {[null $s]} {
	    var desc [format {%s at %s} $retval $addr]
    	} else {
	    var off [index [symbol get $s] 0]
	    var diff [expr [index $a 1]-$off]
	    if {$diff} {
	    	var desc [format {%s at %s+%d} $retval [symbol fullname $s 1]
		    	  $diff]
    	    } else {
	    	var desc [format {%s at %s} $retval [symbol fullname $s 1]]
    	    }
    	}
        if {$tbrk} {
	    stream write [format {"(message "%s (temporary)")\n} $desc] ${emacs-stream}
    	} else {
    	    # Tell emacs to put up a message with the breakpoint token
	    stream write [format {"(message "%s")\n} $desc] ${emacs-stream}
    	}
    }
}]
	
    
##############################################################################
#				emacs-stream-watcher
##############################################################################
#
# SYNOPSIS:	Watch for and execute commands coming from emacs.
# PASS:		stream	= stream token for our connection
#   	    	what	= for what the stream is ready
# CALLED BY:	Rpc system
# RETURN:	nothing
# SIDE EFFECTS:	?
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/21/91		Initial Revision
#
##############################################################################
[defsubr emacs-stream-watcher {stream what}
{
    var line [stream read line $stream]
    var nl [string first \\n $line]

    if {$nl >= 0} {
    	var line [range $line 0 [expr $nl-1] chars]
    }
    if {[null $line]} {
    	# If we were called for an empty line, the server's probably
	# gone away, so close the stream down.
    	stream close $stream
	global emacs-stream
	var emacs-stream nil
    } else {
    	if {[string c [index $line 0 char] >] != 0} {
	    global emacs-debug
	    if ${emacs-debug} {
		echo emacs-stream-watcher: line = "${line}"
	    }
    	    eval $line
    	}
    }
}]

##############################################################################
#				emacs-fetch-stream
##############################################################################
#
# SYNOPSIS:	Return a stream open to the emacs server socket for the user
# PASS:		nothing
# CALLED BY:	emacs-real-show
# RETURN:	a stream token, or nil if stream couldn't be opened
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/21/91		Initial Revision
#
##############################################################################
[defsubr emacs-fetch-stream {}
{
    global emacs-stream
    [if {![null ${emacs-stream}] &&
	 [string c [stream state ${emacs-stream}] error] == 0}
    {
    	stream ignore ${emacs-stream}
	stream close ${emacs-stream}
	var emacs-stream nil
    }]
    
    global emacs-debug

    if {[null ${emacs-stream}]} {
	if {[file exists [getenv HOME]/.emacs_server]} {
	    var emacs-stream [stream open [getenv HOME]/.emacs_server r+]
	    if {[null ${emacs-stream}]} {
		if ${emacs-debug} {
		    echo emacs-fetch-stream: could not connect to [getenv HOME]/.emacs_server
		}
		return nil
	    }
	    stream watch ${emacs-stream} read emacs-stream-watcher
	} else {
	    if ${emacs-debug} {
		echo emacs-fetch-stream: server isn't running
	    }
	    return nil
	}
    }
    return ${emacs-stream}
}]


[defsubr emacs-real-show {args}
{
    [if {[catch {src line [frame register pc]} fileLine] == 0 &&
	 ![null $fileLine]} 
    {
    	emacs-goto [index $fileLine 0] [index $fileLine 1]
    }]
    return EVENT_HANDLED
}]

[defcmd ewatch {args} support.unix.editor
{Usage:
    ewatch [<args>]

Examples:
    "ewatch"        report on ewatch's status
    "ewatch on"     turn on ewatch

Synopsis:
    Allow automatic emacs updating of the point of execution.

Notes:
    * The argument can be one of the following:
    	on 	every time the machine stops or you change stack
    	    	frames, EMACS will display the file and line for the
    	    	current cs:ip, placing a little "=>" at the start of
    	    	the line so you know where it is.
    	off	disables the above.
    	show	causes EMACS to display the current frame's cs:ip, but
    	    	only does it once -- it won't follow the execution on
    	    	the PC.

    * If no argument is passed, ewatch returns its current state.

    * For emacs to be updated, ewatch must be turned on in swat, and
      the server must be started in emacs ('M-x start-server' or have
      the command (start-server nil) in you .emacs file).

    * Emacs may also be updated by typing 'emacs'.

    * The variable emacs-ignore-list contains a list of the functions that
      are not displayed when swat is stopped in them. This means that you
      can't use istep/ewatch to step through these routines. It also means
      that you won't be annoyed by having some routine you're not interested
      in displayed when you hit ctrl-C in swat.

      You can add your own routines to this list by putting the command:
		var emacs-ignore-list [concat [var emacs-ignore-list] {
				<routine1>
				<routine2>
				}]
      in your .swat file or in some other file which you can load.

    * The variable emacsIgnore is non-zero if emacs should not display
      the routines in the emacs-ignore-list. If you wish to debug a routine
      in this list, set this variable to zero with:
    	    	var emacsIgnore 0
      The default value for emacsIgnore is 1.

See also:
    emacs, frame, istep.
}
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

var emacsRemapSrcPath /staff
var emacsRemapDstPath s:

[defsubr emacs-goto {file line}
{
    global emacsRemapSrcPath
    global emacsRemapDstPath
    global file-os
    
    #
    # Use a custom command to talk to emacs in NT.
    if {[string c ${file-os} win32] == 0} {
	if {[string match $file $emacsRemapSrcPath*]} {
	    var file [string subst $file $emacsRemapSrcPath $emacsRemapDstPath]
	}
	var cmd [format {(find-file "%s") (goto-line %d)} $file $line]
	elispSend $cmd
	return
    }
    if {[file readable $file]} {
	var stream [emacs-fetch-stream]
	if {![null $stream]} {
	    stream write [format {>%d %s \n} $line $file] ${stream}
	    stream flush ${stream}
	} else {
	    error {Could not contact emacs server}
	}
    } else {
    	#
	# If haven't warned the user about this file being awol recently,
	# do so now.
	#
    	global emacs-last-unreadable
	if {[string c $file ${emacs-last-unreadable}]} {
    	    var emacs-last-unreadable $file
 	    error [concat {Could not read file} $file]
    	}
    }
}]


# set the current emacs buffer to read only mode so the user can't
# mess with it.
[defsubr emacs-buffer-read-only {}
{
    var stream [emacs-fetch-stream]
    if {![null $stream]} {
    	stream write [format {"(setq buffer-read-only t)\n}] ${stream}
    	stream write [format {"(set-buffer-modified-p (buffer-modified-p))\n}] ${stream}
    	stream flush ${stream}
    }
}]

# read a file in read only mode and without an error marker. 
# Good for displaying files for reference only.
[defsubr emacs-reference-file {file}
{
    var stream [emacs-fetch-stream]
    if {![null $stream]} {
    	stream write [format {>%d %s \n} 1 $file] ${stream}
    	stream write [format {"(setq buffer-read-only t)\n}] ${stream}
    	stream write [format {"(set-buffer-modified-p (buffer-modified-p))\n}] ${stream}
    	stream write [format {"(setq overlay-arrow-position nil)\n}] ${stream}
    	stream flush ${stream}
    }
}]


[defcmd emacs {{routine cs:ip}} support.unix.editor
{Usage:
    emacs [<address>]

Examples:
    "emacs"	        show the point of execution (cs:ip)
    "emacs Dispatch"    show the routine 'Dispatch' in emacs

Synopsis:
    Display the source code for an address.

Notes:
    * The address argument specifies what code to show in emacs.

    * For emacs to be updated the server must be started in emacs
      ('M-x start-server' or have the command (start-server nil) in
      you .emacs file).

See also:
    ewatch, frame, istep.
}
{
    var srcline [src line $routine]

    if {[null $srcline]} {
    	var s [symbol faddr {label proc} $routine]
	if {![null $s]} {
	    addr-preprocess $routine seg off
	    var a [index [symbol get $s] 0]
	    if {$a == $off} {
	    	var routine [symbol fullname $s]
    	    } else {
	    	var routine [symbol fullname $s]+[expr $off-$a]
    	    }
    	}
    	error [format {no source line information available for %s} $routine]
    }
	    
    emacs-goto [index $srcline 0] [index $srcline 1]
}]
