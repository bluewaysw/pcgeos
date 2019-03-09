##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	stack.tcl
# AUTHOR: 	Adam de Boor, May  5, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	func	    	    	Returns name of current function or
#   	    	    	    	sets current frame to be first containing
#				given function.
#   	up  	    	    	Moves current frame up
#   	down	    	    	Moves current frame down
#   	backtrace   	    	Prints out stack frames in order
#	finishframe		Finish out a specific frame given its
#				frame token
#	finish			Finish a frame given its number (or current)
#	ret			Finish a frame given the name of the function
#				active in it.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/ 5/89		Initial Revision
#
# DESCRIPTION:
#	Commands to play with the stack
#
#	$Id: stack.tcl,v 3.6 90/11/06 19:12:36 doug Exp $
#
###############################################################################
#
# set or get the current function
#
[defcommand func {args} stack
{Sets or gets the current function. If no argument is given, returns the
function in the current stack frame. If an argument is given, sets the current
frame to be the first from the top that is for that function. If the patient
isn't active, or there's no frame for the function, this function returns an
error}
{
    if {[length $args]==0} {
        return [frame function]
    } else {
        var func [index $args 0]
	[for {var cur [frame top]}
    	     {![null $cur] && ![irq]}
    	     {var cur [frame next $cur]}
	 {
	     if {[string compare [frame function $cur] $func] == 0} break
	 }
     	]
	if {[null $cur]} {
	    error [format {%s not active} $func]
    	} elif {[string compare [frame function $cur] $func] == 0} {
	    frame set $cur
	}
    }
}]

#
# Shift the current frame up 1 or n frames.
#	Usage: up [<number-of-frames-to-go-up>]
#
[defcommand up {args} stack|top
{Given an argument n, shifts the current frame up n frames. If no argument is
given, makes the next frame up the stack (where "up" is away from the top) be
the current frame. Command may be repeated by typing just <return>.}
{
    global lastCommand repeatCommand

    var repeatCommand $lastCommand

    if {[length $args]==0} {
	frame +1
    } else {
	frame +[index $args 0]
    }
}]

#
# Shift the current frame down 1 or n frames.
# 	Usage: down [<number-of-frames-to-go-down>]
#
[defcommand down {args} stack|top
{Shifts the current frame down the given number of frames, or 1 if no number
given. "down" means towards the top of the stack. Command may be repeated by
typing just <return>.}
{
    global lastCommand repeatCommand

    var repeatCommand $lastCommand

    if {[length $args]==0} {
	frame -1
    } else {
	frame -[index $args 0]
    }
}]

#
# Backtrace prints out all the stack frames in the stack, or n stack frames, 
# where n is the first argument given to it. I.e.
# 	Usage: backtrace [<number-of-frames-to-print>]
#
[defcommand backtrace {args} stack|top
{Print all active stack frames for the patient. If an argument is given, it is
the number of frames to print.}
{
    #figure how many frames to print
    if {[length $args]!=0} {
	var maxFrame [expr [index $args 0]+1]

	# Don't print methods
	var methodtrace 0

    } else {
	# set the maximum frame to be some ridiculously large number
	var maxFrame 100000

	# Do method printing trace
	var methodtrace 1
    }
    var cur [frame top] realCur [frame cur] skipMethod 0

    [for {var framenum 1}
	 {([string compare $cur nil] != 0) && ($framenum < $maxFrame) &&
	  ![irq]}
	 {var framenum [expr $framenum+1]}
     {
    	#print * to left of frame if it's the current one
    	if {$cur == $realCur} {
	    var star *
	} else {
	    var star { }
    	}

    	#see if function in current frame known
	var fs [frame funcsym $cur]
	var next [frame next $cur]
    	if {![null $fs]} {

	    #Wild, glorious changes attempted by Doug begin here.

	    #First, cache some neat vars we would like to have around
	    var symname [symbol name $fs]

	    #Then, on any ObjCallMethodTable call, print out a line anouncing
    	    #the sending of a method in the system.  Yup, we look directly
	    #at the stack, so we can pull out everything we need.
	    [if {![string compare $symname ObjCallMethodTable] &&
	    	 $methodtrace &&
		 ([frame register sp $next]-[frame register sp $cur])>=16}
    	    {
		var stackptr [frame register ss $next]:[frame register sp $next]
		[print-obj-call [value fetch $stackptr-16 word]
			[value fetch $stackptr-8 word]
			[value fetch $stackptr-14 word]
			[value fetch $stackptr-10 word]
			[value fetch $stackptr-2 word]
			[value fetch $stackptr-4 word]
			[value fetch $stackptr-6 word]
			[value fetch $stackptr-12 word]]
    	    	var skipMethod 1
	    }]

	    if {($framenum == 1) || !($methodtrace)} {

		#Always print frame for top line
		print-frame $star $framenum $fs $cur $fileline $methodtrace

    	    } elif {$skipMethod} {
	    	[case $symname in
		    SendMessage|SendMessageAndEC|ObjCallMethodTable {}
		    default {
		    	print-frame $star $framenum $fs $cur $fileline $methodtrace
			var skipMethod 0
		    }
    	    	]
    	    } elif {![null $next]} {
    	    	#figure the name of the next function up the stack so we
		#can filter out things that are called from ObjCallMethodTable
    	    	var ns [frame funcsym $next]
		if {![null $ns]} {
		    var nextname [symbol name $ns]
		} else {
		    var nextname nil
		}

    	    	[if {[string c $nextname ObjCallMethodTable] != 0 ||
    	    	     [string c $symname ProcCallModuleRoutine] != 0}
		{
    	    	    var skipMethod 0
		    print-frame $star $framenum $fs $cur $fileline $methodtrace
		}]
	    } else {
	    	print-frame $star $framenum $fs $cur $fileline $methodtrace
	    }
    	} else {
	    #function unknown -- that's about it.
    	    echo [format {%s%2d: ?(), addr %s} $star $framenum 
    	    	    	[frame register pc $cur]]
    	}
	#Move to new frame
	var cur $next
     }
    ]
}]

#
# Prints out object address, class, method token & registers passed
#
[defsubr	print-obj-call {od_handle od_chunk class_seg class_offset
				method cx_value dx_value bp_value}
{
	require name-root showcalls

    #
    # Make sure the handle in question is an lmem block. If not,
    # the method must have been sent to a process. Set $obj to be
    # "invalid" if not an object block -- map-method shouldn't need to
    # make any reference to the object if the method was sent to a process.
    # Else set it to the address of the object, using the ^lhandle:chunk
    # syntax.
    #
    var hl [handle lookup $od_handle]
    if {[null $hl]} {
    	echo TRASH
    	return
    }
    if {[handle state $hl]&0x800} {
    	var obj ^l$od_handle:$od_chunk
    } else {
    	var obj {}
    }
    #
    # Find the symbol for the class using the class segment and offset
    # we've got
    #
    var s [sym faddr var $class_seg:$class_offset]
    if {[null $s]} {
	# If the class can't be determined, then we've probably fatal-errored
	# due to bad parameters to an object messaging routine.  Do the
	# best that we can.

	# Since we don't know the class, we can't really map the method
	# correctly.  However, since everything is subclassed from Meta,
	# we can at Least do that much.
        var en [map-method $method MetaClass]
	if {[string c $en nil] == 0} {
		# if method isn't defined in MetaClass, then just print #
		echo -n [format {method %04x} $method ]
	} else {
		# if it IS, however, print it.
		echo -n method $en
	}
	echo [format
		{ (%04x %04x %04x) sent to ^l%04x:%04x (? class unknown)}
		$cx_value $dx_value $bp_value $od_handle $od_chunk
	     ]
    } else {
    	#
	# Map the method to a meaningful name
	#
        var sn [sym fullname $s]
        var en [map-method $method $sn $obj]

	if {[null $en]} {
	    echo -n $method
	} else {
	    echo -n $en
	}
	echo -n [format { (%04x %04x %04x) sent to }
			$cx_value $dx_value $bp_value
		]
	if {[string c $obj invalid] == 0} {
	    #
	    # Sent to a process class -- find the name of the beast
	    #
	    var p [handle patient [handle lookup $od_handle]]
	    if {![null $p]} {
	    	echo [name-root $sn] ([patient name $p])
	    } else {
	    	echo [name-root $sn] (patient unknown)
	    }
    	} else {
    	    echo [format {%s (^l%0xh:%0xh)}
			[name-root $sn]
		        $od_handle $od_chunk
		]
	}
    }
#var s [sym faddr var $class_seg:$class_offset]
#if {[null $s]} {
#    echo {handling class unknown}
#} else {
#    var sn [sym fullname $s]
#	echo [format {Processed by %s} [name-root $sn]]
#}

}]


#
# Prints out a line representing a frame.  Pulled out because we
# need to call it from a couple of different places
#
[defsubr	print-frame {star framenum fs cur fileline methodtrace} {

    #print frame number, type of function and function name
    if {$methodtrace} {
    	echo -n [format {%s%2d: %4s %s() } $star $framenum
    	    	    		[index [symbol get $fs] 1]
				[symbol fullname $fs]]
    } else {
    	echo -n [format {%s%2d: %4s %s(), } $star $framenum
    	    	    		[index [symbol get $fs] 1]
				[symbol fullname $fs]]
    }

    #if know source info for frame, use that, else use cs:ip
    if {[catch {frame line $cur} fileLine] == 0} {
    	echo line [index $fileLine 1], file "[index $fileLine 0]"
    } else {
	if {$methodtrace} {
	    echo
	} else {
	    echo addr [frame register pc $cur]
	}
    }
}]


############################################################
#
#	    FUNCTIONS TO FINISH OUT STACK FRAMES
#
############################################################

[defdsubr finishframe {frame} prog.stack
{Finishes out the frame given as an argument. For this to work, SWAT must be
able to decode the next frame down the stack (the given frame's caller), as
it simply fetches that frame and the address in it and sets a breakpoint
at that address. Caller should dispatch the FULLSTOP event... Returns
non-zero if interrupted.}
{
    var next [frame next $frame]
    var brkpt [brk tset [frame register pc $next]
    	    	 [format {[expr {[read-reg sp] > %s &&
		    	    	 [index [patient data] 2] == %d}]}
		    [frame register sp $frame]
		    [index [patient data] 2]]]
    stop-catch {
	continue-patient
	if {[wait]} {
	    return 1
    	}
    }
    return 0
}]

#
# finish out the current stack frame or frame n (1-origin)
#
[defcommand finish {{frameNum {}}} stack
{Finish the current frame, or frame n (number given by "backtrace"), if given.
Simply allows the machine to run until it exits the selected frame.}
{
    if {[null $frameNum]} {
    	var cur [frame cur]
    } else {
	var cur [frame top]
	[for {var frameNum [expr $frameNum-1]}
	     {$frameNum > 0}
	     {var frameNum [expr $frameNum-1]}
	{
	    var cur [frame next $cur]
	}]
    }
    finishframe $cur
    event dispatch FULLSTOP _DONT_PRINT_THIS_
    event dispatch STACK 0
}]

#
# return from the function given as an argument, or if no argument given,
# the function at the top of the stack
#
[defcommand ret {args} stack
{Return from the function given as an argument. If no argument given, return
from the one at the top of the stack. Note this doesn't forcibly return from
the function, it merely lets the patient run until the function is done. q.v.
"finish"}
{
    if {[length $args]} {
        var func [index $args 0]
	[for {var cur [frame top]} {![null $cur]} {var cur [frame next $cur]}
	 {
	     if {[string compare [frame function $cur] $func] == 0} break
	 }]
	if {[null $cur]} {
	    error [format {%s not active} $func]
	}
    } else {
	var cur [frame cur]
    }
    finishframe $cur
    event dispatch FULLSTOP _DONT_PRINT_THIS_
    event dispatch STACK 0
}]



[defcommand dumpstack {{ptr {}} {depth 50}} stack
{Dumps a list of words, attempting to make symbolic sense of the values,
in terms of handles, segments, & routines.  The default starting address
is ss:sp, but may be passed, as in "wordinfo ds:si".  A second argument
may be passed which is the # of words to print out. (default is 50}
{
    var last_last_segment 0
    var last_segment cs

    if {[null $ptr]} {
	var reg_ss ss
	var reg_sp sp
	var ptr $reg_ss:$reg_sp
    }
    echo
    echo [format {Stack at %s:} $ptr]
    echo

    [for {var i 0} {$i < $depth*2} {var i [expr $i+2]}
      {
	var w [value fetch $ptr+$i word]
    	echo -n [format {+%02d: %04xh  } $i $w]

	var ideas 0

	# DETERMINE the nature of this word...
	#
	var is_segment 0
	var is_code_segment 0
	var is_handle 0
	var w_handle 0
	var w_segment 0

	if {$w && !($w & 0xf)} {
	    var h [handle lookup $w]
    	    if {![null $h]} {
	        var is_handle 1
		var w_handle $h
		var w_segment [handle segment $h]
	    }
	}
    	var h [handle find [format 0x%04x:0 $w]]
    	if {(![null $h]) && ([handle segment $h] == $w)} {
	    var is_handle 0
	    var is_segment 1
	    var w_handle $h
	    var w_segment $w
	    var w_hs [handle state $w_handle]
	    if {(($w_hs & 0x400) || (($w_hs & 0x080) && ($w_hs & 0x00c)))} {
	    	var is_code_segment 1
	    }
	}

	# AND DETERMINE if next word is a segment...
	#
	var n [value fetch $ptr+$i+2 word]
	var n_is_segment 0
	var n_is_code_segment 0
	var n_handle 0
	var n_segment 0

    	var h [handle find [format 0x%04x:0 $n]]
    	if {(![null $h]) && ([handle segment $h] == $n)} {
	    var n_is_segment 1
	    var n_handle $h
	    var n_segment $n
	    var n_hs [handle state $n_handle]
	    if {(($n_hs & 0x400) || (($n_hs & 0x080) && ($n_hs & 0x00c)))} {
	    	var n_is_code_segment 1
	    }
	}

	# Snippet intended to tell if there is any procedures in a segment.
	# does not appear to be working...
	# ![null [symbol faddr proc $n_segment:0xffff]]

	# PRINT OUT any interesting results
	#

	# Print if any particular segment or handle
	if {$is_segment || $is_handle} {
	    if {$ideas} {
		echo
		echo -n [format {         OR }]
	    }
	    var ideas [expr $ideas+1]
	    if {$is_segment} { echo -n [format {segment }] }
	    if {$is_handle} { echo -n [format {handle }] }
    	    if {$w_handle} {
	      if {[handle state $w_handle] & 0x480} {
    	        echo -n [format {(%s) } [sym fullname [handle other $w_handle]]]
	      } else {
    	    	echo -n [format {(%04xh) } [handle id $w_handle]]
	      }
	    }
	}

	# Print if return address of far call
	if {($n_is_code_segment)} {
	    var s [sym faddr func {$n:$w}]
	    if {![null $s]} {
	      var o [expr $w-[sym addr $s]]
	      if {$o < 2000} {
	        if {$ideas} {
		    echo
		    echo -n [format {         OR }]
		}
	        var ideas [expr $ideas+1]
		var ending {}

		# Print out where call is to, if we can find the call
		if {[value fetch $n_segment:$w-5 byte] == 154} {
	      	    var callw [value fetch $n_segment:$w-4 word]
	      	    var call_segment [value fetch $n_segment:$w-2 word]
	            var calls [sym faddr func {$call_segment:$callw}]
	            if {![null $calls]} {
	      		var callo [expr $callw-[sym addr $calls]]
	      		echo [format {FAR CALL to (%s+%1d)}
				[sym fullname $calls] $callo]

		        echo -n [format {            AT }]
			var ending -5
	      	    }
	        }

		echo -n [format {far offset  (%s+%1d%s)}
			[sym fullname $s] $o $ending]
	      }
	    }
	}

	# Print if return address of near call, based on last seg we saw
	if {(!$is_code_segment)} {
	    var s [sym faddr func {$last_segment:$w}]
	    if {![null $s]} {
	      var o [expr $w-[sym addr $s]]
	      if {$o < 2000} {
	        if {$ideas} {
		    echo
		    echo -n [format {         OR }]
		}
	        var ideas [expr $ideas+1]
		var ending {}

		# Print out where call is to, if we can find the call
		if {[value fetch $last_segment:$w-3 byte] == 232} {
	      	    var callw [expr
			([value fetch $last_segment:$w-2 word]+$w)&0xffff]
	            var calls [sym faddr func {$last_segment:$callw}]
	            if {![null $calls]} {
	      		var callo [expr $callw-[sym addr $calls]]
	      		echo [format {NEAR CALL to (%s+%1d)}
				[sym fullname $calls] $callo]

		        echo -n [format {            AT }]
			var ending -3
	      	    }
	        }

		echo -n [format {near offset (%s+%1d%s)}
			[sym fullname $s] $o $ending]

	      }
	    }
	}

	# Print if return address of near call, based on two segs ago...
	# (Just in case last segment wasn't really a near/far call)
	# NOTE:  if the last two segs encountered were the same, will not
	# print anything extra.
	if {(!$n_is_code_segment) && (!$is_code_segment) } {
	  if {[string compare
		[sym faddr func {$last_segment:$w}]
		[sym faddr func {$last_last_segment:$w}]]
	  	!= 0} {
	    var s [sym faddr func {$last_last_segment:$w}]
	    if {![null $s]} {
	      var o [expr $w-[sym addr $s]]
	      if {$o < 2000} {
	        if {$ideas} {
		    echo
		    echo -n [format {         OR }]
		}
	        var ideas [expr $ideas+1]
		var ending {}

		# Print out where call is to, if we can find the call
		if {[value fetch $last_last_segment:$w-3 byte] == 232} {
	      	    var callw [expr
			([value fetch $last_last_segment:$w-2 word]+$w)&0xffff]
	            var calls [sym faddr func {$last_last_segment:$callw}]
	            if {![null $calls]} {
	      		var callo [expr $callw-[sym addr $calls]]
	      		echo [format {near offset past NEAR CALL to (%s+%1d)}
				[sym fullname $calls] $callo]

		        echo -n [format {            AT }]
			var ending -3
	      	    }
	        }

		echo -n [format {near offset (%s+%1d%s)}
			[sym fullname $s] $o $ending]
	      }
	    }
	  }
	}


	echo

	# If this word was a code segment, then copy over for use in "near"
	# lookup attempts until the next segment
	#
	if {$is_code_segment} {
	    var last_last_segment $last_segment
	    var last_segment $w_segment
	}

      }
    ]
    set-repeat [format {$0 {%s} $2} $ptr+$i]
}]
