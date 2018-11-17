##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
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
#	where			Do backtrace+elist
#	finishframe		Finish out a specific frame given its
#				frame token
#	finish			Finish a frame given its number (or current)
#	ret			Finish a frame given the name of the function
#				active in it.
#   	dumpstack   	    	dump the stack and list possiblities of 
#   	    	    	    	the words
#   	locals	    	    	Print the values of all local variables in
#				the current scope.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/ 5/89		Initial Revision
#
# DESCRIPTION:
#	Commands to play with the stack
#
#	$Id: stack.tcl,v 3.61 97/04/29 20:25:02 dbaumann Exp $
#
###############################################################################
#
# set or get the current function
#
[defcmd func {args} stack
{Usage:
    func [<func name>]

Examples:
    "func"  	    	return the current function
    "func ObjMessage"	set the frame to the first frame for ObjMessage

Synopsis:
    Get the current function or set the frame to the given function.

Notes:
    * The func name argument is the name of a function in the stack
      frame of the current patient.  The frame is set to the first 
      occurence of the function from the top of the stack.

      If no func name argument is given then 'func' returns the 
      current function.

See also:
    where, up, down, finish.    
}
{
    ensure-swat-attached

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
	    error [format {The function '%s' is not active in the stack.} $func]
    	} elif {[string compare [frame function $cur] $func] == 0} {
	    frame set $cur
	}
    }
}]

#
# Shift the current frame up 1 or n frames.
#	Usage: up [<number-of-frames-to-go-up>]
#
[defcmd up {args} top.stack
{Usage:
    up [<frame offset>]

Examples:
    "up"    	    move the frame one frame up the stack
    "up 4"  	    move the frame four frames up the stack

Synopsis:
    Move the frame up the stack.

Notes:
    * The frame offset argument is the number of frame to move up the
      stack.  If none is specified then the current frame is moved up
      one frame.

    * This command may be repeated by pressing <return>.

See also: 
    where, down.
}
{
    ensure-swat-attached

    global lastCommand repeatCommand stepSoftInts

    var repeatCommand $lastCommand

    if {[length $args]==0} {
    	var n 1
    } else {
    	var n [index $args 0]
    }
    for {var f [frame cur]} {![null $f] && $n > 0} {var f $nf} {
    	var nf [frame next $f]
    	[if {![null $nf] &&
	     ([frame function $nf] != ResourceCallInt || $stepSoftInts)}
    	{
	    var n [expr $n-1]
    	}]
    }
    frame set $f
}]

#
# Shift the current frame down 1 or n frames.
# 	Usage: down [<number-of-frames-to-go-down>]
#
[defcmd down {args} top.stack
{Usage:
    down [<frame offset>]

Examples:
    "down"    	    move the frame one frame down the stack
    "down 4"  	    move the frame four frames down the stack

Synopsis:
    Move the frame down the stack.

Notes:
    * The frame offset argument is the number of frame to move down the
      stack.  If none is specified then the current frame is moved down
      one frame.

    * This command may be repeated by pressing <return>.

See also: 
    where, down.
}
{
    ensure-swat-attached

    global lastCommand repeatCommand stepSoftInts

    var repeatCommand $lastCommand

    if {[length $args]==0} {
    	var n 1
    } else {
    	var n [index $args 0]
    }
    for {var f [frame cur]} {![null $f] && $n > 0} {var f $nf} {
    	var nf [frame prev $f]
    	[if {![null $nf] &&
	     ([frame function $nf] != ResourceCallInt || $stepSoftInts)}
    	{
	    var n [expr $n-1]
    	}]
    }
    frame set $f
}]


#########################################################################
#   set-stack-frame-for-gym-files
#########################################################################
[defsubr set-stack-frame-for-gym-files {{echo_error {}}} 
{
    global cachedStackFrame
    #determine if we are using the kernels gym file or sym file
    if {![null [patient find geos]]} {
    	if {[string last geos.gym [patient path [patient find geos]] NO_CASE] != -1} {
    	    # if its the gym file, try to walk up the stack until we
    	    # find something that looks reasonable

    	    # first determine the current thread name
    	    var pname [patient name [handle patient [handle lookup 
    	        	    	[value fetch ss:TPD_threadHandle]]]]
            var ds_val [stack-find-frame {} {} $pname]
    	    if {![null $ds_val]} {
                var myss [index [current-registers] 10]
                var mysp [expr [index [current-registers] 4]+[index $ds_val 2]]
                var mycs [index $ds_val 0]
                var myip [index $ds_val 1]
    	   	# now get the frame at that cs:ip ss:sp and establish it
                # as the top frame
                frame get $myss $mysp $mycs $myip

    	 	if {![null $echo_error] && ![null [index $cachedStackFrame 3]]} {
            	    echo [format {died in FatalError because of %s} 
    	   	    	    	    [index $cachedStackFrame 3]]
                }

       	    }
    	}
    }
}]

#########################################################################
#   backtrace
#########################################################################
[defcmd backtrace {args} top.stack
{Usage:
    backtrace -r<reg>* [-sp] [<frames to list>]

Examples:
    "backtrace"	    	print all the frames in the patient
    "backtrace -rax"	print all the frames and the contents of AX in
			each one.
    "backtrace 5"    	print the last five frames
    "bt 5"	    	same as "backtrace 5"

Synopsis:
    Print all the active stack frames for the patient.

Notes:
    * The <frames to list> argument is the number of frames to print. If not
      specified, then all are printed.

    * If a numeric argument is not passed to backtrace then it attempts to
      display method calls in the form:
    	MSG_NAME(cx, dx, bp) => className (^l####h:####h)
      Here <cx>, <dx>, and <bp> are the values passed in these registers.
      <className> is the name of the class which handled the message.
      ^l####h:####h is the address of the object (block, chunk handle)

    * If a numeric argument is passed to backtrace then the attempt to
      decode the message is not done and the single line above expands
      into:
            far ProcCallModuleRoutine(), geodesResource.asm:476
           near ObjCallMethodTable(), objectClass.asm:1224
      This is generally less useful, but sometimes it's what you need.
    
    * The -sp flag will cause Swat to print the number of bytes used by
      each stack frame.

See also:
    up, down, func, where
}
{
    ensure-swat-attached
    global cachedStackFrame curXIPPage stepSoftInts

    require print-obj-and-method object
    
    
    var show_regs {} stack_space 0
    [set-stack-frame-for-gym-files TRUE]

    while {[string match [car $args] -*]} {
    	[case [car $args] in
	    -r* {
	    	var show_regs [concat $show_regs [range [car $args] 2 end char]]
    	    }
	    -a	{
	    	if {[length $args] < 5} {
		    error {usage: backtrace -a <ss> <sp> <cs> <ip>}
    	    	}
		var cur [frame get [index $args 1] [index $args 2] [index $args 3] [index $args 4]]
		# trim first 4 args, cdr will get the last one
		var args [range $args 4 end]
    	    }
    	    -sp {
	    	var stack_space 1
    	    }
	    -* {
	    	error [format {backtrace: unknown flag %s} [car $args]]
    	    }
    	]
	var args [cdr $args]
    }

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
    if {[null $cur]} {
    	var cur [frame top] realCur [frame cur]
    } else {
    	var realCur $cur
    }
    var skipMethod 0

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
		if {![null [sym find proc RecordMessageStart]]} {
		    var stackptr [frame register ss $next]:[expr [frame register sp $next]-6]
		}
		#Get symbol token for Class to print
		var class_seg [value fetch $stackptr-14 [type word]]
		var class_off [value fetch $stackptr-10 [type word]]
    		var s [sym faddr var $class_seg:$class_off]
  
		var tf $next
		var insuper 0
		var inclass 0
		for {var i 1} {$i<4} {var i [expr $i+1]} {
		     var ts [symbol name [frame funcsym $tf]]
		     if {[string match $ts ObjCallSuperNoLock] ||
		     	 [string match $ts COBJCALLSUPER]} {
		     	var insuper 1
		     } 
		     if {[string match $ts ObjCallClassNoLock]} {
		     	var inclass 1
		     } 
		     var tf [frame next $tf]
		}
		if {$insuper} {
			var prefix {cspr}
		} elif {$inclass} {
			var prefix {ccls}
		} else {
			var prefix {call}
		}
    		echo -n [format {%s%2d: %s } $star $framenum $prefix]
    		[print-obj-and-method
			[value fetch $stackptr-16 [type word]]
			[value fetch $stackptr-8 [type word]]
			{}
			[value fetch $stackptr-2 [type word]]
			[value fetch $stackptr-4 [type word]]
			[value fetch $stackptr-6 [type word]]
			[value fetch $stackptr-12 [type word]]
			$s]
    	    	var skipMethod 1
	    }]
    	    #print out context info if any
    	    #look for a jmp $+5 and the first byte of a mov ax, CONTEXT_VALUE
    	    # we look for this 8 or 9 bytes before a call depending on if its
    	    # a far call or near call
#    	    if {[string c [index [sym get $fs] 1] near] == 0} {
#    	    	var off 8
#    	    } else {
#    	    	var off 9
#    	    }
#    	    var ra [frame retaddr $cur]
#    	    var	ra_seg [index $ra 0] ra_off [expr [index $ra 1]-$off]
#    	    var context [value fetch $ra_seg:$ra_off [type dword]]
#    	    var	con_sig [expr $context&0ffffffh]
#    	    var	con_val [expr $context>>24]
#    	    if {$con_sig == 0b803ebh} {
#    	    	echo [penum geos::ContextValues $con_val]
#    	    }
	    if {($framenum == 1) || !($methodtrace)} {

		#Always print frame for top line
		print-frame $star $framenum $fs $cur $fileline $methodtrace $show_regs $stack_space

    	    } elif {$skipMethod == 1} {
		#If in any one of the number of things that call 
		#ObjCallMethodTable, that we'd just as soon not print out, to
		#avoid cluttering the display, just don't print it -- and 
		#don't stop this method routine skipping activity just yet,
		#either.
	    	[case $symname in
		    {SendMessage SendMessageAndEC ObjCallMethodTable
		    	ObjCallMethodTableSaveBXSI CallMethodCommon
			CallMethodCommonLoadESDI CallFixed
		     	MessageDispatchDefaultCallBack MessageProcess
		     	OCCC_callInstanceCommon OCCC_no_save_no_test
			OCCC_save_no_test MessageDispatch ThreadAttachToQueue
		     	*ObjCallInstanceNoLock* *ObjCallSuperNoLock*
			*ObjMessage* ObjCallClassNoLock ObjInitializeMaster
			ObjGotoSuperTailRecurse ObjGotoInstanceTailRecurse
			ObjLinkCallParent COBJMESSAGE COBJCALLSUPER} {}
		    default {
		    	if {[isglobal $fs]} {
			    print-frame $star $framenum $fs $cur $fileline $methodtrace $show_regs $stack_space
			}
			var skipMethod 0
		    }
    	    	]
    	    } elif {![null $next]} {
    	    	var ns [frame funcsym $next]
		if {![null $ns]} {
		    var nextname [symbol name $ns]
		} else {
		    var nextname nil
		}
    	    	#Filter out internal stuff called from ObjCallMethodTable
		if {[string match $nextname ObjCallMethodTable]} {
	    	    [case $symname in
			{ProcCallModuleRoutine ResourceCallInt} {}
		    	default {
		    	    if {[isglobal $fs]} {
				print-frame $star $framenum $fs $cur $fileline $methodtrace $show_regs $stack_space
			    }
			    var skipMethod 0
		    	}
    	    	    ]
		#Skip non-context related internal stuff
    	    	} else {
	    	    [case $symname in
			{ResourceCallInt} {
			    # Print only if global var indicates user is
			    # interested in knowing about ResourceCallInt shme
			    if {$stepSoftInts && [isglobal $fs]} {
			    	print-frame $star $framenum $fs $cur $fileline $methodtrace $show_regs $stack_space
    	    	    	    }
			}
		    	default {
		    	    if {[isglobal $fs]} {
				print-frame $star $framenum $fs $cur $fileline $methodtrace $show_regs $stack_space
			    }
		    	}
		    ]
		    var skipMethod 0
		}
	    } else {
		#Skip ThreadAttachToQueue if last frame (we don't need to see
		#this...)
	    	[case $symname in
		    {ThreadAttachToQueue} {
		    # Print nothing for these internal routines
		    }
		    default {
		    	if {[isglobal $fs]} {
			    print-frame $star $framenum $fs $cur $fileline $methodtrace $show_regs $stack_space
			}
		    }
		]
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


[defcmd where {args} top.stack
{Usage:
    where

Examples:
    "where"	    	prints out current thread's stack & messages pending
			in the queue that it is attached to, if any
    "w"		    	same as "where"

Synopsis:
    Prints out the state of the current thread by printing out all active stack
    frames & a list of any messages pending in its queue.

Notes:
    * This is typically the first command typed after a crash, or to get a
      better feel for "where" a thread is in the code.

    * This command is the equivalent of "backtrace" followed by "elist", with
      no arguments.

See also:
    up, down, func, backtrace, elist
}
{
    eval [concat backtrace $args]
    echo ------------------------------------------------------------------------------
    elist
    echo ==============================================================================
}]


##############################################################################
#				isglobal
##############################################################################
#
# SYNOPSIS:	Subroutine to determine if function symbol is "global" or not.
#		if not global, then it is internal, & we may skip printing
#		it out.  To be used later as part of effort to make the 
#		debugger able to behave more like an application debugger
# PASS:		sym 	= symbol token to test
# CALLED BY:	where
# RETURN:	non-zero if function is global
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	doug	7/11/93		Initial Revision
#
##############################################################################
[defsubr isglobal {sym}
{
# For now, everything's global.

#	# near symbols of system code aren't internal
#        if [string match [index [symbol get $sym] 1] near] {
#		echo Internal -- near
#		return 0
#	}

	return 1

}]


##############################################################################
#				print-frame-callback
##############################################################################
#
# SYNOPSIS:	Callback function to print the value of any argument
#   	    	for the function in the current frame.
# PASS:		sym 	= symbol token for the current local variable
#   	    	data	= {bp ss} for the stack frame
# CALLED BY:	print-frame via symbol foreach
# RETURN:	non-zero to stop enumerating
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/ 5/92		Initial Revision
#
##############################################################################
[defsubr print-frame-callback {sym data}
{
    var sdata [symbol get $sym]
    #
    # DEFEAT the printing of oself, pself & message.  Why?  Because all this
    # is already displayed in the "@call" line following, & it clutters up the
    # display.	-- Doug 7/8/93.  if there's some other reason it's needed,
    # we can stick it back.
    #
    [case [symbol name $sym] in 
	{message oself pself} {}
	default {

    if {[string c [index $sdata 1] param] == 0} {
    	#
	# Fetch the value of the parameter.
	#
    	var val [value fetch [index $data 1]:[index $data 0]+[index $sdata 0] 
	    	 [index $sdata 2]]
    	#
	# Put out the name
	#
	echo -n [uplevel print-frame {var prefix}][symbol name $sym] {= }
    	#
	# Format the value, keeping it all on one line, if possible.
	#
	fmtval $val [index $sdata 2] 0 {} 1
	
	uplevel print-frame {var prefix {, }}
    }

	}]
}]

#
# Prints out a line representing a frame.  Pulled out because we
# need to call it from a couple of different places
#
[defsubr print-frame {star framenum fs cur fileline methodtrace show_regs stack_space}
{
    require fmtval print

    #print frame number, type of function and function name
    #echo -n [format {%s%2d: %4s %s(} $star $framenum
    #	    	    		[index [symbol get $fs] 1]
    #				[symbol fullname $fs]]

    if {$stack_space} {
    	var sp [frame register sp $cur] ss [frame register ss $cur]
	var sh [handle find ss:0]
	if {$ss == [frame register ss [frame top]]} {
	    var end [thread endstack [patient thread]]
    	} else {
	    var end [handle size $sh]
    	}
    	var n [frame next $cur]
	if {[null $n] || [frame register ss $n] != $ss} {
	    var size [expr $end-$sp]
    	} else {
	    var size [expr [frame register sp $n]-$sp]
    	}
	var size [format {(%3d) } $size]
    }

    echo -n [format {%s%2d: %s%4s %s(} $star $framenum $size
    	    	    		[index [symbol get $fs] 1]
    				[symbol name $fs]]

    var prefix {}
    [symbol foreach $fs locvar print-frame-callback 
    	[list [frame register fp $cur] [frame register ss $cur]]]
    

    echo -n {), }

   #if know source info for frame, use that, else use cs:ip
    [if {([catch {src line [frame register pc $cur] $cur} fileLine] == 0) &&
    	 ![null $fileLine]}
    {
    	echo [file tail [index $fileLine 0]]:[index $fileLine 1]
    } else {
    	echo [frame register pc $cur]
    }]
    foreach r $show_regs {
	echo [format {\t%s = %d, %04xh} $r [frame register $r $cur]
			[frame register $r $cur]]
    }
}]


############################################################
#
#	    FUNCTIONS TO FINISH OUT STACK FRAMES
#
############################################################

[defcommand finishframe {frame} swat_prog.stack
{Usage:
    finishframe <frame-token>

Examples:
    "finishframe $cur"	Run the machine until it returns from the frame whose
			token is in $cur

Synopsis:
    Allows the machine to continue until it has returned from a particular
    stack frame.

Notes:
    * No FULLSTOP event is dispatched when the machine actually finishes 
      executing in the given frame. The caller must dispatch it itself,
      using the "event" command.
      
    * The command returns zero if the machine finished executing in the
      given frame; non-zero if it was interrupted before that could happen.
      
    * The argument is a frame token, as returned by the "frame" command.

See also:
    event, frame, finish
}
{
    var next [frame next $frame]
    #
    # If frame above the one to be finished is for ResourceCallInt, set the
    # breakpoint at the return from that frame, unless stepSoftInts is
    # non-zero.
    #
    global stepSoftInts
    if {!$stepSoftInts && ![string c [frame function $next] ResourceCallInt]} {
    	var next [frame next $next]
    }
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
[defcmd finish {{frameNum {}}} top.stack
{Usage:
    finish [<frame num>]

Examples:
    "finish"	    	finish executing the current frame
    "finish 3"	    	finish executing up to the third frame

Synopsis:
    Finish the execution of a frame.

Notes:
    * The frame num argument is the number of the frame to finish.  If
      none is specified then the current frame is finished up.  The
      number to use is the number which appears in a where.

    * The machine contiues to run until the frame above is reached.

See also:
    where.
}
{
    ensure-swat-attached

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
[defcmd ret {args} stack
{Usage:
    ret [<function name>]

Examples:
    "ret"
    "ret ObjMessage"

Synopsis:
    Return from a function and stop.

Notes:
    * The function name argument is the name of a function in the
      patient's stack after which we should stop. If none is specified 
      then Swat returns from the current function.

      The function returned from is the first frame from the top of
      the stack which calls the function (like the "finish" command).

    * This command does not force a return.  The machine continues
      until it reaches the frame above the function.

See also:
    finish, where.
}
{
    ensure-swat-attached

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


############################################################
#
#	    FUNCTIONS to abort stack frames
#
############################################################

[defcommand abortframe {frame} swat_prog.stack
{Usage:
    abortframe <frame-token>

Examples:
    "abortframe $cur"	Abort all code execection through the frame whose 
			token is in $cur

Synopsis:
    Aborts code execution up through a particular stack frame.  As no code is
    executed, the registers may be in a garbaged state.

Notes:
    * No FULLSTOP event is dispatched when the machine actually aborts
      executing in the given frame. The caller must dispatch it itself,
      using the "event" command.
      
    * The command returns zero if the machine aborted executing in the
      given frame; non-zero if it was interrupted before that could happen.
      
    * The argument is a frame token, as returned by the "frame" command.

See also:
    abort, event, frame, finishframe
}
{
    var next [frame next $frame]
    #
    # If frame above the one to be aborted is for ResourceCallInt, set the
    # breakpoint at the return from that frame, unless stepSoftInts is
    # non-zero.
    #
    global stepSoftInts
    if {!$stepSoftInts && ![string c [frame function $next] ResourceCallInt]} {
	var frame $next
    	var next [frame next $frame]
    }

    # First, set the breakpoint were we want to stop.  This is the same as
    # that used for "finish".
    var brkpt [brk tset [frame register pc $next]
    	    	 [format {[expr {[read-reg sp] > %s &&
		    	    	 [index [patient data] 2] == %d}]}
		    [frame register sp $frame]
		    [index [patient data] 2]]]

    # Before continuing, though, let's move the instruction pointer to a ret
    # instruction of the type required to finish out the last frame.  We'll
    # additionally move the sp to that at the desired finish frame (which for
    # reasons unkown contain the return address for that location still on
    # the stack, so we don't have to adjust the sp down)

    var framesymget [sym get [frame funcsym $frame]]
    [case [index $framesymget 1] in 
	near {var retopcode RETN}
	far {var retopcode RETF}
	default {error {Sorry, don't know how to abort this}}
    ]
    var retaddr [find-no-param-opcode
	[frame register cs $frame]:[frame register ip $frame] $retopcode]
    var retaddr [addr-parse $retaddr]

    # Get all the data for where we'd like to restore the CPU to
    var cc [frame register cc $next]
    var ax [frame register ax $next]
    var bx [frame register bx $next]
    var cx [frame register cx $next]
    var dx [frame register dx $next]
    var bp [frame register bp $next]
    var si [frame register si $next]
    var di [frame register di $next]
    var ds [frame register ds $next]
    var es [frame register es $next]
    var cs [handle segment [index $retaddr 0]]
    var ip [index $retaddr 1]
    var sp [frame register sp $next]

    # Get back to first frame if not there, so we can muck w/current state
    if {![string match [frame cur] [frame top]]} {
	frame 1
    }

    # Restore registers, with sp last
    assign cc $cc
    assign ax $ax
    assign bx $bx
    assign cx $cx
    assign dx $dx
    assign bp $bp
    assign si $si
    assign di $di
    assign ds $ds
    assign es $es
    assign cs $cs
    assign ip $ip
    assign sp $sp

    # ss:sp points to the desired adddres,
    # cs:ip to a RET instruction that will pop it off the stack & take us 
    # there.  All the registers will be preserved in the return as we've set
    # them up.

    stop-catch {
	continue-patient
	if {[wait]} {
	    return 1
    	}
    }

    return 0
}]


[defsubr find-no-param-opcode {addr opcode}
{
# In the segment passed, find an offset at which resides the desired opcode,
# having no argument.  Used to find RETN & RETF instructions.
	var addr [addr-parse $addr]
	var seg [handle segment [index $addr 0]]
	var off [index $addr 1]
	for {
		var un [mangle-softint [unassemble $seg:$off] $seg:$off]
	} {
		!([string match [index [index $un 1] 0] $opcode] &&
			[null [index [index $un 1] 1]])
	} {
	} {
		var off [expr $off+[index $un 2]]
		var un [unassemble $seg:$off]
	}
	return $seg:$off
}]

#
# abort out the current stack frame or frame n (1-origin)
#
[defcmd abort {{arg0 {}}} stack
{Usage:
    abort [<frame num>]
    abort [<function>]

Examples:
    "abort"	    	abort executing the current frame
    "abort 3"	    	abort executing up through the third frame
    "abort ObjMessage"	abort executing up through first ObjMessage

Synopsis:
    Abort code execution up through a given frame or routine.  By "abort",
    we me "do not execute".  This can be quite dangerous, as semaphores may
    not be ungrabbed, blocks not unlocked, flags not cleared, etc., leaving
    the state of objects, & if executing system code, possibly the system
    itself screwed up.  This command should only be used when the only
    alternative is to to detach (i.e. in a fatalerror) as a way to possibly
    prolong the usefullness of the debugging session.

Notes:
    * If no argument is given, code through the current frame is aborted.

    * <frame num> are the numbers that appear at the left of the backtrace.

See also:
    finish, backtrace, zap
}
{
    ensure-swat-attached

    if {[null $arg0]} {
    	var cur [frame cur]
    } else {
	[case [index [explode $arg0] 0] in 
	    {[0-9]} {
		var cur [frame top]
		[for {var arg0 [expr $arg0-1]}
	     		{$arg0 > 0}
	     		{var arg0 [expr $arg0-1]}
			{var cur [frame next $cur]}
		]
	    }
	    default {
        	if {[null [sym find proc $arg0]]} {
	    		error [format {%s unknown} $arg0]
		}
		[for {var cur [frame top]}
			{![null $cur]}
			{var cur [frame next $cur]}
	 		{
	     	    	    if {[string compare
				[frame function $cur] $arg0] == 0} {break}
	 		}
		]
		if {[null $cur]} {error [format {%s not active} $arg0]}
	    }
	]
    }
    abortframe $cur
    event dispatch FULLSTOP _DONT_PRINT_THIS_
    event dispatch STACK 0
}]

############################################################
#
#	    dumpstack
#
############################################################

[defcmd dumpstack {{ptr {}} {depth {}} {prevstate {}}} stack
{Usage:
    dumpstack [<address>] [<length>]

Examples:
    "dumpstack"	    	dump the stack at ss:sp
    "ds ds:si 10"   	dump ten words starting at ds:si
    "ds -r"		dump from the top down (in reverse order)
    "ds ss:sp+500 -50"	dump 50 works in reverse order, starting at ss:sp+500

Synopsis:
    Dump the stack and try to make some sense of it.

Notes:
    * The address argument is the address of the list of words to
      dump.  This defaults to ss:sp.

    * The length argument argument is the number of words to dump.
      This defaults to 50.

    * This dumps the stack and tries to make symbolic sense of the
      values, in terms of handles, segments, and routines.

See also:
    where.
}
{
    ensure-swat-attached

    if {[null $prevstate]} {
	var last_last_segment 0
	var last_segment [read-reg cs]
    } else {
    	var last_last_segment [index $prevstate 0]
	var last_segment [index $prevstate 1]
    }

    if {[string match $ptr -r]} {
	var stackhan [value fetch ss:0 [type word]]
	var ptr ^h$stackhan+[handle size [handle lookup $stackhan]]
	if {[null $depth]} {var depth -50}
    } else {
	if {[null $depth]} {var depth 50}
    }
    if {[null $ptr]} {
	var reg_ss ss
	var reg_sp sp
	var ptr $reg_ss:$reg_sp
    }
    if {$depth>0} {
	var next 2
    } else {
	var next -2
    }
    echo
    echo [format {Stack at %s:} $ptr]
    echo

    var n [value fetch $ptr word]
    var nh [handle find $n:0]
    if {(![null $nh]) && ([handle segment $nh] == $n)} {
	var n_is_segment 1
	var n_handle $nh
	var n_segment $n
	var n_hs [handle state $n_handle]
	# 0x400 => kernel/loader
	# 0x080 => resource
	# 0x008 => fixed
	# 0x004 => discardable
	[if {(($n_hs & 0x400) || (($n_hs & 0x080) && ($n_hs & 0x00c))) &&
	     ($h != $kdata)}
	{
	    var n_is_code_segment 1
	} else {
	    var n_is_code_segment 0
	}]
    } else {
	var n_is_segment 0
	var n_is_code_segment 0
	var n_handle 0
	var n_segment 0
    }

    [for {var i 0} {[abs $i] < [abs $depth*2]} {var i [expr $i+$next]}
    {
	var w [value fetch $ptr+$i word]
    	echo -n [format {+%02d: %04xh  } $i $w]

	var ideas 0

	# DETERMINE the nature of this word...
	#
	var is_segment $n_is_segment
	var is_code_segment $n_is_code_segment
	var w_handle $n_handle
	var w_segment $n_segment

	if {$w && !($w & 0xf)} {
	    var h [handle lookup $w]
    	    if {![null $h]} {
	        var is_handle 1
		var w_handle $h
		var w_segment [handle segment $h]
	    } else {
	    	var is_handle 0
    	    }
	} else {
	    var is_handle 0
    	}
	

	# AND DETERMINE if next word is a segment...
	#
	var n [value fetch $ptr+$i+2 word]
    	var nh [handle find $n:0]
    	if {(![null $nh]) && ([handle segment $nh] == $n)} {
	    var n_is_segment 1
	    var n_handle $nh
	    var n_segment $n
	    var n_hs [handle state $n_handle]
    	    # 0x400 => kernel/loader
	    # 0x080 => resource
	    # 0x008 => fixed
	    # 0x004 => discardable
	    [if {(($n_hs & 0x400) || (($n_hs & 0x080) && ($n_hs & 0x00c))) &&
		 ($nh != $kdata)}
    	    {
	    	var n_is_code_segment 1
	    } else {
	    	var n_is_code_segment 0
    	    }]
	} else {
	    var n_is_segment 0
	    var n_is_code_segment 0
	    var n_handle 0
	    var n_segment 0
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
		echo -n {         OR }
	    }
	    var ideas [expr $ideas+1]
	    if {$is_segment} { echo -n {segment } }
	    if {$is_handle} { echo -n {handle } }
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
		    echo -n {         OR }
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

#		        echo -n [format {            AT }]
			var ending -5
	      	    }
	        } elif {[value fetch $n_segment:$w-4 byte] == 255} {
#			echo INDIRECT FAR CALL
#		        echo -n [format {            AT }]
			var ending -4
		}

		echo -n [format {far offset (%s+%1d%s)}
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
		    echo -n {         OR }
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

		        echo -n {            AT }
			var ending -3
	      	    }
	        }
    	    	var expr_string [format {%s%s} ${o} ${ending}]
		echo -n [format {near offset (%s+%1d)}
			[sym fullname $s] [expr $expr_string]]

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
		    echo -n {         OR }
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

		        echo -n {            AT }
			var ending -3
	      	    }
	        }

    	    	var expr_string [format {%s%s} ${o} ${ending}]
		echo -n [format {near offset (%s+%1d)}
			[sym fullname $s] [expr $expr_string]]
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
    set-repeat [format {$0 {%s} %s {%d %d}} $ptr+$i $depth
    	    $last_last_segment $last_segment]
}]




############################################################################
# ds_common is a helper routine stack-find-frame
############################################################################
[defsubr ds_common {callw calls pat last_proc myframe w near_call onscreen} {
    var callo [expr $callw-[sym addr $calls]]
    var call_pat 0
    var got_proc 0
    var fn [sym fullname $calls]
    [if {![null $pat]} {
	if {[string c $pat [patient name [sym patient 
	    [sym find proc $fn]]]] == 0} {
		var call_pat 1
	}
    }]
    if {$callo == 0 || $call_pat == 1} {
	var tail [expr [string last : $fn]+1]
	var got_proc [range $fn $tail end char]
			    
	var g_pat [patient name [sym patient [sym find proc $got_proc]]]
	var l_proc_sym [sym find proc $last_proc]

        if {![null $l_proc_sym] && near_call == 1} {
	    var	l_pat [patient name [sym patient $l_proc_sym]]
	} else {
	    var l_pat $g_pat
	}
	if {[string c $got_proc $last_proc] != 0 &&
	    [string c $g_pat $l_pat] == 0} {
	    #output the proc
	    var last_proc $got_proc
	    var result [check_for_top_function $myframe $last_proc $pat $onscreen]
	    if {![null [index $result 1]] && [null $onscreen]} {
		return [list 1 $last_proc $got_proc [index $result 1]]
	    }
	    if {[null $onscreen]} {
		return [list 0 $last_proc $got_proc $got_proc]
	    }
	    var myframe [index $result 0]
	    echo [format {%d: %s()} $myframe $got_proc]
   	    var myframe [expr $myframe+1]
	    return [list $myframe $last_proc $got_proc $got_proc]
	}
#	if {[string c $g_pat $pat] == 0} {
#	    var got_proc 0
#	}
   } else {
       var myframe [check_for_fatal_error $calls $callo $fn $w $myframe $onscreen $pat]
   }

   return [list $myframe $last_proc $got_proc {}]
}]


############################################################################
# ds_return_value forms a list of segment, offset and sp offset for
# stack-find-frame to return
############################################################################
[defsubr ds_return_value {proc_name sp_off} {
    #convert the proc name into a segment and address
    
    global  cachedStackFrame

    var addr [addr-parse $proc_name]
    var seg [handle segment [index $addr 0]]
    var off [index $addr 1]
    var cachedStackFrame [list [index [current-registers] 10] 
    	    	    	       [index [current-registers] 4]
    	    	    	       [list $seg $off $sp_off]
    	    	    	       [index $cachedStackFrame 3]]
    return [list $seg $off $sp_off]
}]

############################################################################
# check_for_fatal_error sees if there is a call to fatal error on the
# stack
############################################################################
[defsubr check_for_fatal_error 
    	    {calls callo fn caller_offset myframe onscreen pat}
{
    global cachedStackFrame

    # see if the call matches a call to FatalError
    if {[null [info command address-kernel-internal]]} {
        var addrp [addr-parse &FatalError]
    	var kcode  [handle segment [index $addrp 0]]
    	var fe_off [index $addrp 1]
    } else {
        var fe_addr [address-kernel-internal FatalError]
        var kcode [range $fe_addr 0 5 char]
        var fe_off [range $fe_addr [expr [string last : $fe_addr]+1] end char]
    }
    var cur_off [sym addr $calls]
    # since FatalError is a near routine, it must be a call from kcode
    var cur_seg [string match  $fn geos::kcode::*]
    var curss [index [current-registers] 8]
    var cursp [index [current-registers] 4]
    if {$cur_seg == 1 && [expr $fe_off] == [expr $cur_off+$callo]} {
        var cfataloff [expr [sym addr [sym find proc CFATALERROR]]]
        var appfataloff [expr [sym addr [sym find proc AppFatalError]]]

    	if {[expr $caller_offset] == [expr $cfataloff+3]} {
    	    # we are called by CFATALERROR, so get error value off the stack
    	    # look for the offset of CFATALERR and then add 6 to it
    	    var myoff 0
    	    var myval [value fetch $curss:$cursp word]
    	    while {[expr $myval-3] != $cfataloff} {
    	    	var myoff [expr $myoff+2]
    	    	var myval [value fetch $curss:$cursp+$myoff word]
    	    }
    	    
    	    var	err_val [value fetch $curss:$cursp+$myoff+6 word]
    	    var err [penum $pat::FatalErrors $err_val]
    	    if {[null $err]} {
    	    	var err UNKNOWN_ERROR
    	    }
    	    var cachedStackFrame [list 0 0 {} $err]
#      	    echo [format {died in FatalError because of %s} $err]
	    var myframe [expr $myframe+1]
    	} elif {[expr $caller_offset] == [expr $appfataloff+3]} {
    	    # so its a call to AppFatalError, so go up to get error value
    	    # at one byte past the return value of the call to AppFatalError
    	    var myoff 0
    	    var myval [value fetch $curss:$cursp word]
    	    while {[expr $myval-3] != $appfataloff} {
    	    	var myoff [expr $myoff+2]
    	    	var myval [value fetch $curss:$cursp+$myoff word]
    	    }
    	    var	upss [value fetch $curss:$cursp+$myoff+4 word]
    	    var	upsp [value fetch $curss:$cursp+$myoff+2 word]
    	    var err_val [value fetch $upss:$upsp+1 word]
    	    var err [penum $pat::FatalErrors $err_val]
    	    if {[null $err]} {
    	    	var err UNKNOWN_ERROR
    	    }
    	    var cachedStackFrame [list 0 0 {} $err]
#      	    echo [format {died in FatalError because of %s} $err]
	    var myframe [expr $myframe+1]
    	} else {
    	    var co [expr $caller_offset+1]
	    var err [penum geos::FatalErrors [value fetch $kcode:$co word]]
    	    if {[null $err]} {
    	    	var err UNKNOWN_ERROR
    	    }
    	    var cachedStackFrame [list 0 0 {} $err]
#            echo [format {died in FatalError because of %s} $err]
	    var myframe [expr $myframe+1]
    	}
   }
   return $myframe
}]

############################################################################
# check_for_top_function sees if we are in the middle of a routine that was
# called from the top of the stack
############################################################################
[defsubr check_for_top_function {myframe got_proc pat onscreen} {
    var result {}
    if {$myframe == 1} {
	var top_proc [frame function [frame top]]
	if {[string last : $top_proc] != -1} {
	    return [list $myframe {}]
	}
	var proc_pat [patient name [sym patient [sym find proc $top_proc]]]
	if {[string c $got_proc $top_proc] != 0 &&
	    [string c $pat $proc_pat] == 0} {
    	    if {![null $onscreen]} {
	    	echo [format {%d: %s()} $myframe $top_proc]
    	    }
	    var result $top_proc
	    var myframe [expr $myframe+1]
	}
    }
    return [list $myframe $result]
}]

###########################################################################
# stack-find-frame is used by backtrace when using the kernel's gym file
# to try to find a place on the stack that it understands so that it can
# create usable and meaningful stack frames
# it is kind of a haphazard function that seems to do pretty well...
# it returns a cs:ip and an offset from the current ss:sp to create the
# new frames from
###########################################################################
[defsubr stack-find-frame {{ptr {}} {depth {}} {pat {}} {onscreen {}}} {
    ensure-swat-attached
    global  cachedStackFrame

    # see if we have a cached answer, if not construct one
    if {[null $onscreen] &&
    	[index $cachedStackFrame 0] == [index [current-registers] 10] && 
    	[index $cachedStackFrame 1] == [index [current-registers] 4]} {

#    	if {![null [index $cachedStackFrame 3]]} {
#            echo [format {died in FatalError because of %s} 
#    	    	    	    [index $cachedStackFrame 3]]
#    	}
    	return [index $cachedStackFrame 2]
    }
    
    var cachedStackFrame {0 0 {} {}}
    var last_last_segment 0
    var last_segment cs

    if {[null $pat]} {
	var def_pat [sym-default]
	if {[string c $def_pat none] != 0} {
	    var pat $def_pat
	}
    }
    if {[string match $ptr -r]} {
	var stackhan [value fetch ss:0 [type word]]
	var ptr ^h$stackhan+[handle size [handle lookup $stackhan]]
	if {[null $depth]} {var depth -50}
    } else {
	if {[null $depth]} {var depth 50}
    }
    if {[null $ptr]} {
	var reg_ss ss
	var reg_sp sp
	var ptr $reg_ss:$reg_sp
    }
    if {$depth>0} {
	var next 2
    } else {
	var next -2
    }

    var	myframe 1
    var last_proc {}

    [for {var i 0} {[abs $i] < [abs $depth*2]} {var i [expr $i+$next]}
      {
	var w [value fetch $ptr+$i word]
    	#echo -n [format {+%02d: %04xh  } $i $w]

	# DETERMINE the nature of this word...
	#
	var is_segment 0
	var is_code_segment 0
	var is_handle 0
	var w_handle 0
	var w_segment 0
        var got_something 0

	if {$w && !($w & 0xf)} {
	    var h [handle lookup $w]
    	    if {![null $h]} {
	        var is_handle 1
		var w_handle $h
		var w_segment [handle segment $h]
	    }
	}
    	var h [handle find [format %04xh:0 $w]]
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

    	var h [handle find [format %04xh:0 $n]]
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
	if {($n_is_code_segment)} {
	    var s [sym faddr func {$n:$w}]
	    if {![null $s]} {
		var symname [sym name $s]
	    } else {
		var symname hi
	    }
	    [case $symname in
		    {SendMessage SendMessageAndEC ObjCallMethodTable
		    	ObjCallMethodTableSaveBXSI CallMethodCommon
			CallMethodCommonLoadESDI CallFixed
		     	MessageDispatchDefaultCallBack MessageProcess
		     	OCCC_callInstanceCommon OCCC_no_save_no_test
			OCCC_save_no_test MessageDispatch ThreadAttachToQueue
		     	*ObjCallInstanceNoLock* *ObjCallSuperNoLock*
			*ObjMessage* ObjCallClassNoLock ObjInitializeMaster
			ObjGotoSuperTailRecurse ObjGotoInstanceTailRecurse
			COBJMESSAGE COBJCALLSUPER ProcCallModuleRoutine} {

			    continue
		    }
		    default {
		    }
	    ]
	      
	    if {![null $s]} {
	      var o [expr $w-[sym addr $s]]
	      if {$o < 2000} {
		var ending {}
		var got_proc 0
		# Print out where call is to, if we can find the call
		if {[value fetch $n_segment:$w-5 byte] == 154} {
	      	    var callw [value fetch $n_segment:$w-4 word]
	      	    var call_segment [value fetch $n_segment:$w-2 word]
	            var calls [sym faddr func {$call_segment:$callw}]
	            if {![null $calls]} {
			var stuff [ds_common $callw $calls $pat 
				    $last_proc $myframe $w 0 $onscreen]
			var result [index $stuff 3]
			if {![null $result] && [null $onscreen]} {
			    if {[index $stuff 0] == 0} {
				return [ds_return_value $result $i]
			    } else {
				return [ds_return_value $result 0]
		    	    }
			}
			var myframe [index $stuff 0]
			var last_proc [index $stuff 1]
			var got_proc [index $stuff 2]
			var ending -5
	      	    }
	        } else {
		    [if {[value fetch $n_segment:$w-4 byte] == 255} {
			var ending -4
		    }]
		}

		[if {![null $pat] && $got_proc != 0} {
		    var mypat [patient name [sym patient $s]]
		    [if {[string c $pat $mypat] == 0} {
			var last_proc [sym name $s]
			var result [check_for_top_function $myframe 
				     	    	$last_proc $pat $onscreen]
			var myframe [index $result 0]
			var res [index $result 1]
			if {![null $res] && [null $onscreen]} {
			    return [ds_return_value $res 0]
			}
			echo [format {%d: %s()} $myframe $last_proc]
			if {![null $onscreen]} {
			    return [ds_return_value $last_proc $i]
			}
			var myframe [expr $myframe+1]
		    }]
		}]
	     }
	  }
	}

	# Print if return address of near call, based on last seg we saw
	if {(!$is_code_segment)} {
	    var s [sym faddr func {$last_segment:$w}]
	    if {![null $s]} {
	      var o [expr $w-[sym addr $s]]
	      if {$o < 2000} {
		var ending {}
		var got_proc 0

		# Print out where call is to, if we can find the call
		if {[value fetch $last_segment:$w-3 byte] == 232} {
	      	    var callw [expr
			([value fetch $last_segment:$w-2 word]+$w)&0xffff]
	            var calls [sym faddr func {$last_segment:$callw}]
	            if {![null $calls]} {
			var stuff [ds_common $callw $calls $pat 
				    $last_proc $myframe $w 1 $onscreen]
			var result [index $stuff 3]
			if {![null $result] && [null $onscreen]} {
			    if {[index $stuff 0] == 0} {
				return [ds_return_value $result $i]
			    } else {
				return [ds_return_value $result 0]
		    	    }
			}
			var myframe [index $stuff 0]
			var last_proc [index $stuff 1]
			var got_proc [index $stuff 2]
		        var ending -3
		    }
	        } 

		[if {![null $pat] && $got_proc != 0} {
    	    	    var mypat [patient name [sym patient $s]]
		    [if {[string c $pat $mypat] == 0  && 
			 [string c [sym name $s] $got_proc] != 0} {
			var last_proc [sym name $s]
			var result [check_for_top_function $myframe 
				     	    	$last_proc $pat $onscreen]
			var myframe [index $result 0]
			var res [index $result 1]
			if {![null $res] && [null $osncreen]} {
			    return [ds_return_value $res 0]
			}
			echo [index $result 1]
    	    	    	echo [format {%d: %s()} $myframe $last_proc]
			if {[null $onscreen]} {
			    return [ds_return_value $last_proc $i]
			}
			var myframe [expr $myframe+1]
		    }]
		}]
		 
	    }
	  }
	}
	if {(!$n_is_code_segment) && (!$is_code_segment) } {
	  if {[string compare
		[sym faddr func {$last_segment:$w}]
		[sym faddr func {$last_last_segment:$w}]]
	  	!= 0} {
	    var s [sym faddr func {$last_last_segment:$w}]
	    if {![null $s]} {
	      var o [expr $w-[sym addr $s]]
	      if {$o < 2000} {
		var ending {}
		var got_proc 0

		# Print out where call is to, if we can find the call
		if {[value fetch $last_last_segment:$w-3 byte] == 232} {
	      	    var callw [expr
			([value fetch $last_last_segment:$w-2 word]+$w)&0xffff]
	            var calls [sym faddr func {$last_last_segment:$callw}]
	            if {![null $calls]} {
			var stuff [ds_common $callw $calls $pat 
				    $last_proc $myframe $w 1 $onscreen]
			var result [index $stuff 3]
			if {![null $result] && [null $onscreen]} {
			    if {[index $stuff 0] == 0} {
				return [ds_return_value $result $i]
			    } else {
				return [ds_return_value $result 0]
		    	    }
			}
			var myframe [index $stuff 0]
			var last_proc [index $stuff 1]
			var got_proc [index $stuff 2]
		        var ending -3
	      	    }
	        }
		
		[if {![null $pat] && $got_proc != 0} {
    	    	    var mypat [patient name [sym patient $s]]
		    [if {[string c $pat $mypat] == 0  && 
			 [string c [sym name $s] $got_proc] != 0} {
			var last_proc [sym name $s]
			var result [check_for_top_function $myframe 
				     	    	$last_proc $pat $onscreen]
			var myframe [index $result 0]
			var res [index $result 1]
			if {![null $res] && [null $onscreen]} {
			    return [ds_return_value $res 0]
			}
			echo [index $result 1]
    	    	    	echo [format {%d: %s()} $myframe $last_proc]
			if {[null $onscreen]} {
			    return [ds_return_value $last_proc $i]
			}
			var myframe [expr $myframe+1]
		    }]
		}]

	      }
	    }
	  }
	}

	if {$is_code_segment} {
	    var last_last_segment $last_segment
	    var last_segment $w_segment
	}
      }
    ]

    set-repeat [format {$0 {%s} %s} $ptr+$i $depth]
}]



[defsubr abs {value}
{
    var v [expr $value]
	if {$v>=0} {
		return $v
	} else {
		return [expr -$v]
	}
}]

##############################################################################
#				locals
##############################################################################
#
# SYNOPSIS:	Print the values of all local variables in the current frame
# PASS:		[func]	= name of function whose list of local variables
#			  is desired.
# CALLED BY:	user
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	8/ 9/91		Initial Revision
#   	jenny	9/29/93	    	Broke out reg-name, now in swat.tcl
#
##############################################################################
[defsubr locals-callback {sym pval}
{
    if {$pval} {
    	var eq { = }
    } else {
    	var eq \n
    }
    var data [symbol get $sym]
    var sname [type name [index $data 2] [symbol name $sym] 0]
    [case [index $data 1] in
	static {
	    echo -n [format {static %s in segment %s%s}
		$sname
		[symbol name [symbol scope $sym 0]] $eq]
	}
	local {
	    echo -n [format {local %s at [bp%d]%s}
		$sname [index $data 0] $eq]
	}
	param {
	    echo -n [format {parameter %s at [bp+%d]%s}
		$sname [index $data 0] $eq]
	}
	reg {
    	    var rname [reg-name [index $data 0]]
	    echo -n [format {regvar %s in register %s%s}
		$sname $rname $eq]
	}
    ]
    if {$pval} {
	require fmtval print
    	if {[index $data 1] != reg} {
    	    var val [value fetch [symbol fullname $sym]]
    	} else {
	    var val [getvalue [format {(%s)%s} [type name [index $data 2] {} 0] $rname]]
    	}
	fmtval $val [index $data 2] 4
    }
    return 0
}]

[defcommand locals {{func {}}} {top.print top.stack}
{Usage:
    locals [<func>]

Examples:
    "locals"	    	Print the values of all local variables and
			arguments for the current frame.
    "locals WinOpen"	Print the names of all local variables for the
			given function. No values are printed.

Synopsis:
    Allows you to quickly find the values or names of all the local
    variables of a function or stack frame.

See also:
    print, frame info
}
{
    ensure-swat-attached

    if {[null $func]} {
    	var func [frame funcsym] pvals 1
    } else {
    	var func [symbol find func $func] pvals 0
    }

    if {![null $func]} {
    	symbol foreach $func locvar locals-callback $pvals
    }
}]
    

[defsubr count-locals-callback {sym}
{
    uplevel 1 {var count [expr $count+1]}
}]

[defsubr count-locals {}
{
    ensure-swat-attached

    var count 0
    var func [frame funcsym]
    if {![null $func]} {
    	symbol foreach $func locvar count-locals-callback
    }
    return $count
}]

##############################################################################
#				btall
##############################################################################
#
# SYNOPSIS:	Backtrace all active threads but the loader and scheduler
# PASS:		nothing
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	lots o' output
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/19/93		Initial Revision
#
##############################################################################

[defcommand btall {args} top.stack
{Usage:
    btall

Examples:
    "btall"	Runs the backtrace command for all threads

Synopsis:
    Produces a backtrace for all existing threads, one after the other.

Notes:
    * Any argument valid for the backtrace command may be passed to btall; it
      will be passed to each invocation of "backtrace"

See also:
    backtrace
}
{
    var curp [patient data]

    protect {
	foreach t [thread all] {
	    var tn [threadname [thread id $t]]
	    if {$tn != loader:0 && $tn != geos:0} {
		echo ==============================================================================
		echo [format {%*s%s} [expr (78-[length $tn char])/2] {} $tn]
		echo ==============================================================================
		switch [thread id $t]
		eval [concat backtrace $args]
    	    }
	}
    } {
    	switch [index $curp 0]:[index $curp 2]
    }
}]

