##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	debug.tcl
# AUTHOR: 	Adam de Boor, May  5, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	enter-debugger	    	Main entry point...
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/ 5/89		Initial Revision
#
# DESCRIPTION:
#	TCL debugger
#
#   	Constants for frame flags:
#   	    Name    	Value	    What
#   	    TD_STOP 	0x100 	    When set in a frame, causes debugger
#   	    	    	    	    to be called when return from that frame
#   	    TD_DEBUG	0x200 	    Set to indicate a frame that invoked
#   	    	    	    	    the debugger.
#   	    TD_NEXT 	0x400	    Stop on next call after frame returns
#
#	$Id: debug.tcl,v 3.0 90/02/04 23:46:08 adam Exp $
#
###############################################################################

[defsubr debug-print-frame {frame num iscur {abbrev 1}}
{
    if {[tcl-debug getf $frame] & 0x100} {
	echo -n b
    } else {
	echo -n { }
    }
    if {$iscur} {
	echo -n *
    } else {
	echo -n { }
    }
    echo -n [format {%2d: } $num]

    echo -n [map i [tcl-debug args $frame] {
	    	if {$abbrev && [length $i chars] > 13} {
    	    	    var a [range $i 0 9 chars]...
	    	} else {
		    var a $i
	    	}
		mapconcat c [explode $a] {
		    scan $c %c i
		    [case $i in
		     9 {format {\\t}}
		     10 {format {\\n}}
		     13 {format {\\r}}
		     12 {format {\\f}}
		     default {
			if {$i < 32 || $i > 126} {
			    format {\\%03o} $i
			} else {
			    var c
			}
		     }]
	      }}]

    if {[tcl-debug complete $frame]} {
    	echo
    } else {
    	echo ...evaluating args
    }
}]

defvar debug-ignore-error 0

[defsubr enter-debugger {why result}
{
    var	frame	[tcl-debug top] fnum 1
    var func 	[index [tcl-debug args $frame] 0]

    [case $why in
     enter {
     	echo calling $func
     }
     exit {
     	echo $func returning "$result"
	if {[tcl-debug getf $frame] & 0x400} {
    	    #did a next in the frame -- set stopOnNextCall and return
	    #result we were passed.
	    tcl-debug next-call
	    return $result
	}
     }
     error {
    	global debug-ignore-error
	
	if {${debug-ignore-error}} {
	    return $result
	}
    	if {[string c $func error] == 0} {
	    var frame [tcl-debug next $frame] fnum 2
	}
     	echo error in $func: $result
     }
     quit {
     	echo quit in $func
     }
     reset {
    	global debug-ignore-error debugOnReset
	
	var debug-ignore-error 0

    	if {$debugOnReset == 0} {
     	    return $result
	}
     }
     toplevel {
     	global debug-ignore-error
	
	var debug-ignore-error 0
	return $result
     }
     other {
     	echo stopped in $func
     }]
    debug-print-frame $frame $fnum 1
    
    for {} {1} {} {
    	var l [top-level-read [format {debug [%s] ! : } $func]]
	
	[case [index $l 0] in
	 up|u {
    	    if {[length $l] > 1} {
    	    	var n [index $l 1]
    	    } else {
	    	var n 1
	    }
    	    var num $n
	    [for {var f $frame}
	     	 {![null $f] && $n > 0}
		 {var f [tcl-debug next $f]}
    	     {
	     	var n [expr $n-1]
	     }]
	    if {[null $f]} {
	    	echo Error: not that many frames to go up
	    } else {
	    	var frame $f fnum [expr $fnum+$num]
    	    	debug-print-frame $f $fnum 1
	    }
	 }
	 down|d {
    	    if {[length $l] > 1} {
    	    	var n [index $l 1]
    	    } else {
	    	var n 1
	    }

    	    var num $n
	    [for {var f $frame}
	     	 {![null $f] && $n > 0}
		 {var f [tcl-debug prev $f]}
    	     {
	     	var n [expr $n-1]
	     }]
	    if {[null $f]} {
	    	echo Error: not that many frames to go down
	    } else {
	    	var frame $f fnum [expr $fnum-$num]
    	    	debug-print-frame $f $fnum 1
	    }
	 }
	 where|bt|w {
    	    var n [index $l 1]
	    if {[null $n]} {
	    	var n 10000
	    }
	    [for {var f [tcl-debug top] num 1}
	    	 {![null $f] && $n > 0}
		 {var f [tcl-debug next $f] num [expr $num+1]}
    	     {
		debug-print-frame $f $num [expr $f==$frame]
	     }]
    	 }
	 eval|e {
	    [case [catch {tcl-debug eval $frame [range $l 1 end]} res] in
	     0 {
    	    	#successful return
	     	if {[length $res chars] > 0} {
		    echo $res
		}
	     }
	     1 {
    	    	#real error code
	     	echo error: $res
	     }
	     default {
	     	#weirdness
    	     	echo bogus return value (result = "$res")
    	     }]
    	 }
    	 E {
	    [case [catch [range $l 1 end] res] in
	     0 {
    	    	#successful return
	     	if {[length $res chars] > 0} {
		    echo $res
		}
	     }
	     1 {
    	    	#real error code
	     	echo error: $res
	     }
	     default {
	     	#weirdness
    	     	echo bogus return value (result = "$res")
    	     }]
    	 }
	 default {
	    [case [catch {tcl-debug eval $frame $l} res] in
	     0 {
    	    	#successful return
	     	if {[length $res chars] > 0} {
		    echo $res
		}
	     }
	     1 {
    	    	#real error code
	     	echo error: $res
	     }
	     default {
	     	#weirdness
    	     	echo bogus return value (result = "$res")
    	     }]
	 }
	 step|s {
    	    #set to stop on next call and to stop when top-most frame returns
	    tcl-debug next-call
    	    var frame [tcl-debug top]
	    tcl-debug setf $frame [expr [tcl-debug getf $frame]|0x500]
	    return $result
	 }
	 next|n {
    	    #set to stop when top-most frame returns, but set TD_NEXT so we
    	    #just print the result, we don't actually stop there
	    var frame [tcl-debug top]
	    tcl-debug setf $frame [expr [tcl-debug getf $frame]|0x500]
	    return $result
	 }
	 finish|fi {
	    #set to stop when top-most frame returns, but let interpreter
	    #run freely until then, clearing the stop bit from all lower frames
	    [for {var f [tcl-debug top]}
		 {$f != $frame}
		 {var f [tcl-debug next $f]}
	     {
		tcl-debug setf $f [expr [tcl-debug getf $f]&0xff]
	     }]
	    tcl-debug setf $frame [expr [tcl-debug getf $frame]|0x100]
	    return $result
	 }
	 abort|a|quit|q {
	    return-to-top-level
	 }
	 go|g {
	    return $result
	 }
	 cont|c {
    	    #clear the stop flag from all frames
	    [for {var f [tcl-debug top]}
	    	 {![null $f]}
		 {var f [tcl-debug next $f]}
    	     {
	     	tcl-debug setf $f [expr [tcl-debug getf $f]&0xff]
	     }]
    	    global debug-ignore-error
	    
	    var debug-ignore-error 1

	    return $result
	 }
	 frame|fr {
	    if {[length $l] > 1} {
		var num [index $l 1]
		if {$num < 1} {
		    echo $num: frame # less than 1? You're weird...
		} elif {$num < $fnum} {
		    [for {var i $fnum f $frame}
			 {$i != $num && ![null $f]}
			 {var i [expr $i-1] f [tcl-debug prev $f]} {}]
		} else {
		    [for {var i $fnum f $frame}
			 {$i != $num && ![null $f]}
			 {var i [expr $i+1] f [tcl-debug next $f]} {}]
		}
		if {[null $f]} {
		    echo $num: no such frame active
		} else {
		    var frame $f fnum $num
		}
	    } else {
		debug-print-frame $frame $fnum 1 0
	    }
	 }
	 h|help|\? {
	    echo {
The commands available are:
    u or up [<num>]	Move up <num> frames in call stack (defaults to 1)
    d or down [<num>]	Move down <num> frames in call stack (defaults to 1)
    fr or frame [<num>]	Move to frame <num> or print current frame in
			unabbreviated form if <num> not given
    fi or finish	Allows interpreter to run freely until the current
			frame returns, at which point control returns to the
			debugger
    q or quit		Returns to normal command level, throwing away all
			in-progress calls.
    c or cont		Removes stop flags from all active frames (e.g. as
			set by the s or n commands) and allows the interpreter
			to run freely.
    g or go		Allows the interpreter to run freely. It will stop
			again when it returns from a frame whose stop flag
			is set (see "w", below). Note the difference between
			this and the "c" command.
    s or step		Continue execution, stopping on the next call
    n or next		Continue execution, stopping on the next call at
			the same level (i.e. calls made on behalf of the
			current frame's function will not cause a stop)
    e or eval <command>	Executes the <command> using the variables from the
			current frame.
    w or bt		Prints all active frames in an abbreviated form.
			A "b" to the left of the frame indicates a frame whose
			return will cause the debugger to activate if the
			interpreter is continued with the "go" command.
Any unrecognized command will be executed as for the "eval" command.
}
	 }]
    }
}]
	    
    	    	    
