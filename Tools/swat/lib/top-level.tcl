##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	top-level.tcl
# AUTHOR: 	Adam de Boor, May  5, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	prompt	    	    	Prompt format string
#   	prompt	    	    	Issue prompt based on $prompt
#   	lastCommand 	    	Command being executed (as returned
#				by top-level-read)
#   	repeatCommand	    	Command to execute if just <return> given
#   	symbolCompletion    	Non-zero => perform symbol/command completion
#   	top-level-read	    	Read a line with completion, prompting, etc.
#   	set-repeat  	    	Set the command to be repeated based on the
#   	    	    	    	passed template and $lastCommand
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	5/ 5/89		Initial Revision
#
# DESCRIPTION:
#	
#
#                            TOP LEVEL LOOP
#
# top-level-read is responsible for prompting for input, formatting input
# into whatever format (this version does symbol completion and history
# substitution and command repetition) is desired and returning the line to
# be executed by the C top-level loop.
#
#	$Id: top-level.tcl,v 3.2 90/10/03 22:00:53 adam Exp $
#
###############################################################################

[defvar prompt {swat (%s) ! => } variable.input
{Contains a format string for the command prompt. A single %s is replaced by
the name of the current patient. A single ! is replaced by the number of the
current command in the command history. These escapes may only be used once.
Note that to get a % in the prompt, you must use %% or you will get an error}]

[defvar lastCommand nil prog.input|variable.input
{The command currently being executed. Set by top-level-read}]

[defvar repeatCommand nil prog.input|variable.input
{The command to execute should the user type only a newline. Set to nil by
top-level-read. A command that wishes to be repeated should set this to the
appropriate value (usually based on the value of lastCommand)}]

[defvar symbolCompletion 1 variable.input
{If non-zero, enables symbol completion in the command reader. An escape causes
the reader to supply the longest common prefix of all symbols that begin with
what you've typed so far. If the prefix begins more than one symbol, it will
beep to tell you this. If you type control-D, the reader will print out all the
possible completions. Typing control-] causes it to cycle through the possible
symbols, in alphabetical order}]

#
# Prompt command only defined if not running under X (it has its own prompt
# command so it can record the start of the input line).
#
if {[string c ${window-system} x11] != 0} {
    [defsubr prompt {args}
    {
	if {[catch {
	    if {[length $args] > 0} {
		    var pvar [index $args 0]
		    #
		    # Indicate nesting, if any.
		    #
		    if {[current-level] > 1} {
			echo -n [current-level]:
		    }
		    var hn [string first ! $pvar]
		    #
		    # Protect against errors in the prompt format string --
		    # don't want to abort out of the top-level-read, but we do
		    # want the user to know s/he screwed up.
		    #
		    [if {[catch {
			    catch {patient name} pname
			    if {$hn >= 0} {
				#
				# Deal with including the history number
				#
				echo -n [format [range $pvar 0 [expr $hn-1] chars]
					    $pname]
				echo -n [history cur]
				echo -n [format [range $pvar [expr $hn+1] end chars]
					    $pname]
			    } elif {[string first %s $pvar]>=0}  {
				echo -n [format $pvar $pname]
			    } else {
				echo -n $pvar
			    }
			} foo]}
		    {
			echo -n ($foo)
		    }]
	    } else {
		if {[current-level] > 1} {
		    echo -n [current-level]:
		}

		global attached

		[if {$attached && 
		     [catch {handle other [handle lookup [read-reg curThread]]} rt]==0}
		{
		    var rp [patient name [handle patient [thread handle $rt]]]
		    var rtn [thread number $rt]
		} else {
		    var rp [patient name] rtn [index [patient data] 2]

		}]
		echo -n [format
			    [if {[null [patient threads]]} {
				concat {[%s%s] %d => }
			     } elif {[string c $rp [patient name]] ||
				     [index [patient data] 2] != $rtn} {
				concat {[%s:%d] %d => }
			     } else {
				concat {(%s:%d) %d => }
			     }]
			    [patient name]
			    [index [patient data] 2]
			    [history cur]]
	    }
	} foo] != 0} {echo prompt is hosed: $foo}

	flush-output
    }]
}

[defsubr top-level-read {{prompt nil} {line {}} {history 1}}
{
    global lastCommand repeatCommand

    #
    # Issue first command prompt.
    #
    if {[string c $prompt nil]} {
    	var promptcmd [list prompt $prompt]
    } else {
    	var promptcmd prompt
    }
    eval $promptcmd
    #
    # Follow with any initial input
    #
    if {![null $line]} {
	echo -n $line
    }
    var mcidx -1
    for {} {1} {} {
    	#
    	# Read command into line
    	#
    	var line [read-line 1 $line]

    	var ln [expr [length $line chars]-1]
    	var ec [if {$ln >= 0} {index $line $ln chars} {}]
    	if {[string m $ec \[\e\004\035\]]} {
    	    #
	    # Complete as far as possible
    	    #
	    # Skip to first non-identifier character in line. There be four
	    # types of completion here: symbol, variable, command and filename.
    	    #
	    # To determine the beginning of the string that wants completion,
	    # we work back through the string matching each character in turn
	    # against a character class stored in $chars. The first non-
	    # matching character terminates the search, providing the non-
	    # inclusive limit for the prefix to be completed.
    	    #
	    # The command to locate the possible completions is stored in $cmd.
	    # It returns a list of strings.
	    #
    	    # To determine what sort of completion to perform, we want to
	    # see if there are any spaces after the last $ or open bracket or /
	    # (whichever comes last). If so, we default to symbol-completion.
	    # Otherwise, it means we've got something like
	    #	... [prefix
	    # or
	    # 	... ${prefix
	    # or
	    #	... /prefix
	    # and need to perform the proper type of completion, depending on
	    # which type of character ($ or bracket or /) was right-most in
	    # the line
    	    #
	    # }]  these are to avoid confusing the tcl interpreter with the
	    # bracket and brace above...
    	    #
    	    [var vstart [string last {$} $line]
	    	 start [string last {[} $line]
		 lstart [string last \n $line]
		 fstart [string last / $line]]
	    # default use $start and no var or file completion
	    var vcomp 0 fcomp 0
    	    if {$lstart > $start} {
	    	var start $lstart
	    }
	    if {$fstart > $start} {
	    	var start $fstart fcomp 1
	    }
	    if {$vstart > $start} {
	    	# $ right-most -- record that as start and note var completion
	    	var start $vstart vcomp 1 fcomp 0
	    }

	    if {$start < 0} {
    	    	# Nothing special -- terminate at line start
    	    	var start 0
    	    } elif {$start == $lstart} {
		# Skip leading line indentation
		[for {var start [expr $start+1]}
		     {$start <= $ln}
		     {var start [expr $start+1]}
		 {
		    if {![string m [index $line $start char] {[ 	]}]} {
			break
		    }
		 }]
	    } else {
	    	var start [expr $start+1]
	    }
	    #assume symbol completion
	    #
	    # Form the list of possible symbols. Sort them numerically
	    # and blow away duplicates (which can arise due to
	    # libraries).
	    #
	    var cmd {[sort -u [map j [symbol match any ${pref}*]
			    {symbol name $j}]]}
	    var chars {[A-Za-z0-9@_?]}
    	    var noloop 0

    	    if {![string match [range $line $start end chars] {*[ 	]*}]} {
    	    	# No whitespace after special char
    	    	if {$fcomp} {
		    #filename completion -- locate start of filename (beginning
		    #of line or just after preceding whitespace char)
		    var cmd {file ${pref}* match}
    	    	    [for {var i [expr $start-1]}
		    	 {$i>=0 && ![string m [index $line $i char] {[ 	]}]}
			 {var i [expr $i-1]}
			 {}]
	    	    var start [expr $i+1] noloop 1
		} elif {$vcomp} {
		    #variable completion
		    if {[string c [index $line $start char] \{] == 0} {
			# $ followed by curly --  skip over curly
			var start [expr $start+1]
		    	var cmd {info globals ${pref}*}
    	    	    	var noloop 1
		    } elif {![string m
		    	    	[range $line $start [expr $ln-1] char]
				{*[^A-Za-z0-9_]*}]} {
			# not followed by curly or non-identifier char --
			# do variable completion ($start in proper place)
		    	var cmd {info globals ${pref}*}
			var noloop 1
		    }
		} else {
		    #command completion
		    var cmd {info commands ${pref}*}
		    var noloop 1
		}
	    }
	    
    	    if {!$noloop} {
		[for {var i [expr $ln-1]}
		     {$i>=$start && [string m [index $line $i chars] $chars]}
		     {var i [expr $i-1]}
		     {}]
    	    } else {
    	    	# If doing command or variable completion, already know where
		# the thing starts...
	    	var i [expr $start-1]
	    }
    	    #
	    # Figure the length of the prefix. It's ok that ln is 1- the length
	    # since we want to nuke the final character anyway...
	    #
	    var plen [expr $ln-($i+1)]
	    #
	    # DO NOT COMPLETE NULL-LENGTH PREFIXES
	    #
	    if {$plen == 0} {
	    	#
		# Strip off completion character first...
		#
	    	var line [range $line 0 [expr $ln-1] chars]
		continue
	    }
    	    #
	    # Extract prefix and line w/o prefix
	    #
    	    var pref [range $line [expr $i+1] [expr $ln-1] chars]
    	    var tline [if {$i < 0} {format {}} {range $line 0 $i chars}]

    	    #
	    # Carefully evaluate the command (this avoids premature return if
	    # a directory through which we're doing filename completion doesn't
    	    # exist). If there be an error, tell the user about it and go back
	    # to the top with the line, minus its completion character.
	    #
    	    if {[catch $cmd syms] != 0} {
	    	echo [format {\nUnable to complete: %s} $syms]
		var line [range $line 0 [expr $ln-1] chars]
    	    	echo -n $line
		continue
    	    }

    	    [case $ec in
	     \004 {
	    	#
		# Just print the matching strings
		#
    	    	var mcidx -1
		echo
		var names [sort $syms]
    	    	var lengths [map j $names {length $j chars}]
		var ml 0
    	    	map j $lengths {if {$j > $ml} {var ml $j}}

    	    	#
		# Now we've got the max length, figure the number of columns,
		# generating a format string that can be used to print
		# the names left-justified in the proper-sized field
		#
    	    	var ncols [expr [columns]/($ml+2)] fmt [format {%%-%ds}
							       [expr $ml+2]]
		if {$ncols == 0} {
		    var ncols 1
		}
    	    	var j $ncols
    	    	foreach name $names {
		    if {$j == 0} {
    	    	    	var j $ncols
		    	echo
		    }
		    echo -n [format $fmt $name]
		    var j [expr $j-1]
		}
		echo
    	    	#
		# Remove control-D from the end
		#
    	    	var line [range $line 0 [expr $ln-1] chars]
    	    	#
		# Re-prompt for input
		#
    	    	eval $promptcmd
		echo -n $line
    	    }
	    \035 {
	    	if {$mcidx == -1 || [string c $line $mcline]} {
		    #
		    # First time through -- record the list of symbols for
		    # later iterations and up the index to 0
		    #
		    var mcidx 0 mcplen $plen
		    var mcnames [sort $syms]
    	    	    #
		    # If no possibilities, beep at the user, reset our private
		    # counter and continue where we left off.
		    #
		    if {[length $mcnames] == 0} {
		    	beep
    	    	    	var mcidx -1
			continue
		    }
		}
		var name [index $mcnames $mcidx]
    	    	if {[file $name isdir]} {
		    var name ${name}/
		}
    	    	#
		# Erase back to original prefix. Want to make a string of
		# $plen-$mcplen {\b \b} strings...
		#
    	    	echo -n [mapconcat j
		    	    [explode [format %[expr $plen-$mcplen]s {}]]
		    	    {format {\b \b}}]
    	    	#
		# Echo new suffix
		#
		echo -n [range $name $mcplen end chars]
    	    	#
		# Easiest just to strip off entire symbol and tack on new one
		#
		var line $tline$name
		var mcline ${line}\035
    	    	#
		# Cycle through the list
		#
		var mcidx [expr ($mcidx+1)%[length $mcnames]]
    	    }
	    default {
	      	if {![null $syms]} {
    	    	    var mcidx -1
    	    	    #
		    # Figure the common prefix and print any new characters
		    # discovered.
		    #
    	    	    var new [completion $syms]
   	    	    echo -n [range $new $plen end chars]
    	    	    #
		    # If more (or less) than one possible, honk at the user
		    #
    	    	    if {[length $syms] != 1} {
		    	beep
	    	    } elif {$fcomp && [file $new isdir]} {
		    	var new ${new}/
			echo -n /
    		    }
		    var line $tline$new
	    	} else {
    	    	    #
		    # Completed to nothing -- honk at the user
		    #
    	    	    beep
	    	    var line [range $line 0 [expr $ln-1] chars]
	    	}
	    }]
    	    #
	    # Don't prompt again
	    #
    	    continue
    	} elif {[string c $line {}] == 0} {
    	    #
	    # If empty input line and a command has been saved, use it.
	    #
	    if {![null $repeatCommand]} {
	    	var line $repeatCommand
		break
    	    }
    	} else {
    	    #
    	    # Now for regular history substitution. If we get an error back,
    	    # print it out and loop again. Commands that extend over multiple
	    # lines are unmolested by (and absent from) history since the
	    # history library will compress out newlines...
    	    #
	    if {[string m $line *\n*] || !$history} {
	    	break
	    } elif {[catch {history subst $line} result] != 0} {
    	    	echo Error: $result
    	    	var line {}
    	    } else {
		#
		# Echo the new line if it's different.
		#
		if {[string c $line $result]} {
		    echo $result
		    var line $result
		}
    	    	break
    	    }
    	}
    	#
    	# Issue new prompt -- if we completed something, we didn't get here.
	#
    	eval $promptcmd
    }

    var lastCommand $line repeatCommand nil
    return $line
}]

[defdsubr set-repeat {template} prog.input
{Sets the command to be repeated using a template string and the lastCommand
variable. The variables $0...$n substitute the fields 0...n from the
lastCommand variable, with the final result being placed in repeatCommand
to be executed should the user type just return}
{
    global lastCommand repeatCommand
    
    var j 0
    foreach i $lastCommand {
    	var $j $i j [expr $j+1]
    }
    
    var repeatCommand [mapconcat i $template {
    	eval [concat format {{%s }} $i]
    }]
    
    return $repeatCommand
}]

