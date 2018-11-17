##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
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
#	$Id: toplevel.tcl,v 3.22.9.1 97/03/29 11:26:47 canavese Exp $
#
###############################################################################

#
# Load in history support
#
load history

[defvar lastCommand nil {swat_prog.input swat_variable.input}
{Usage:
    none

Examples:
    "var repeatCommand $lastCommand"	Set the current command as the one
					to execute next time.

Synopsis:
    $lastCommand stores the text of the command currently being executed.

Notes:
    * This variable is set by top-level-read. Setting it yourself will
      have no effect, unless you call set-address or some similar routine
      that looks at it.

See also:
    repeatCommand, top-level-read
}]

[defvar repeatCommand nil {swat_prog.input swat_variable.input}
{Usage:
    var repeatCommand <string>

Examples:
    "var repeatCommand [list foo nil]"	    Execute the command "foo nil" if
					    the user just hits <Enter> at the
					    next command prompt.

Synopsis:
    This variable holds the command Swat should execute if the user enters
    an empty command. It is used by all the memory-referencing commands to
    display the next chunk of memory, and can be used for other purposes as
    well.

Notes:
    * repeatCommand is emptied just before top-level-read returns the command
      the interpreter should execute and must be reset by the repeated command
      if it wishes to continue to be executed when the user just hits <Enter>.

    * The text of the current command is stored in lastCommand, should you
      wish to use it when setting up repeatCommand.

See also:
    lastCommand, top-level-read.
}]

[defvar symbolCompletion 0 swat_variable.input
{Usage:
    var symbolCompletion (0|1)
    syntax diagram

Examples:
    "var symbolCompletion 1"	Enable symbol completion in the top-level
				command reader.

Synopsis:
    This variable controls whether you can ask Swat to complete a symbol
    for you while you're typing a command. Completion is currently very
    slow and resource-intensive, so you probably don't want to enable it.

Notes:
    * Even when symbolCompletion is 0, file-name, variable-name, and command-
      name completion are always enabled, using the keys described below.

    * When completion is enabled, three keys cause the interpreter to take
      the text immediately before the cursor and look for all symbols that begin
      with those characters. The keys are:
      	Ctrl+D	Produces a list of all possible matches to the prefix.
	Escape	Takes the list of all matches and inserts the remaining 
	    	characters of their common prefix, effectively typing as
		many characters as Swat can unambiguously determine are part
		of any symbol that begins with the characters already typed.
    	Ctrl+]	Cycles through the list of possible symbols, in alphabetical
		order.

See also:
    top-level-read.
}]

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
		if {[catch {thread handle $rt} rp] == 0} {
		    var rp [patient name [handle patient $rp]]
		    var rtn [thread number $rt]
		} else {
		    var rp unknown rtn 0
		}
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
    } foo] != 0} {echo prompt is hosed: $foo => }

    flush-output
}]

##############################################################################
#				top-level-read
##############################################################################
#
# SYNOPSIS:	Read a line of input from the user dealing with completion
#		of various sorts and command-line history too
# PASS:		[prompt]= prompt string to issue. It may contain a single
#			  exclamation point to substitute the current
#			  history number. Defaults to system prompt
#   	    	[line]	= initial input provided for user. Defaults to
#			  none.
#   	    	[history]= non-zero to perform command-history substitution
#			   on the final string.
# CALLED BY:	top-level, others
# RETURN:	the line read
# SIDE EFFECTS:	the line is stored in the global variable lastCommand
#   	    	the global variable repeatCommand is emptied
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/24/91		Initial Revision
#
##############################################################################
[defsubr top-level-read {{prompt nil} {line {}} {history 1}}
{
    global lastCommand repeatCommand symbolCompletion
    global file-os

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
    var lasthist [history cur]
    var lastLine {}
    global historySearching
    if {[null $historySearching]} {
	var completionLength -1
    } else {
	var completionLength 0
    }
    for {} {1} {} {
    	#
    	# Read command into line
    	#
	global wordDelineatingChars
	global cleChars
	if {[null $wordDelineatingChars]} {
	    if {[null $cleChars]} {
		var line [read-line 1 $line {\e\004\035\020\016}]
	    } else {
		var line [read-line 1 $line {\e\004\035\020\016} {\040\t} $cleChars]
	    }
	} else {
	    if {[null $cleChars]} {
		var line [read-line 1 $line {\e\004\035\020\016} $wordDelineatingChars]
	    } else {
		var line [read-line 1 $line {\e\004\035\020\016} $wordDelineatingChars $cleChars]
	    }
	}
	
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
		 fstart [string last / $line]
		 sstart [string last :: $line]]
		 #] -- another fix for parser confusion
	    
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
	    if {$sstart > $start} {
    	    	[for {var i [expr $sstart-1]}
		     {$i >= $start}
		     {var i [expr $i-1]}
    	    	{
		    if {[string match [index $line $i char] \[\ \t\n\]]} {
			break
    	    	    }
    	    	}]
    	    	# set it to $i so assignment to $start+1 will position to
		# proper place, in the next conditional.
		var start $i
		var vcomp 0 fcomp 0
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
		# Start is at bracket, dollar, or forward-slash.  Skip it.
	    	var start [expr $start+1]
	    }
	    #assume symbol completion
	    #
	    # Form the list of possible symbols. Sort them numerically
	    # and blow away duplicates (which can arise due to
	    # libraries).
	    #
    	    if {$symbolCompletion} {
	    	var cmd {[sort -u [map j [symbol match any ${pref}*]
			    {symbol name $j}]]}
    	    } else {
    	    	# if symbol completion disabled, search only for local
		# vars or labels within the current scope.
	    	var cmd {[sort -u [map j [symbol match {locvar label} ${pref}* 
		    	    	    	    [frame funcsym]]
    	    	    	    	    	  {symbol name $j}]]}
    	    }
	    var chars {[A-Za-z0-9@_?-]}
    	    var noloop 0
    	    if {![string match [range $line $start end chars] {*[ 	]*}]} {
    	    	# No whitespace after special char
    	    	if {$fcomp} {
		    #filename completion -- locate start of filename (beginning
		    #of line or just after preceding whitespace char)
		    var cmd {file match ${pref}*}
    	    	    [for {var i [expr $start-1]}
		    	 {$i>=0 && ![string m [index $line $i char] {[ 	]}]}
			 {var i [expr $i-1]}
			 {}]
	    	    var start [expr $i+1] noloop 1
		} elif {$vcomp} {
		    #variable completion
		    [if {[string c [index $line $start char] \{] == 0} {
			# $ followed by curly --  skip over curly
			var start [expr $start+1]
		    	var cmd {info globals ${pref}*}
    	    	    	var noloop 1
		    } elif {![string m
		    	    	[range $line $start [expr $ln-1] char]
				{*[^A-Za-z0-9_-]*}]}
    	    	    {
			# not followed by curly or non-identifier char --
			# do variable completion ($start in proper place)
		    	var cmd {info globals ${pref}*}
			var noloop 1
		    }]
		} elif {$sstart > $start} {
    	    	    var cmd [format {[sort -u
				      [map j
				       [symbol match {locvar label} ${pref}*
				        [symbol find scope %s]]
				       {
				           symbol name $j
				       }]]}
		    	    	[range $line $start [expr $sstart-1] char]]
		    var start [expr $sstart+2]
		    var noloop 1
		} else {
		    #command completion
		    var cmd {info commands ${pref}*}
		    var noloop 1
		}
	    }
	    
    	    if {!$noloop} {
    	    	# skip backwards over chars in $chars (a regexp) to find the
		# start of the thing to be completed
		[for {var i [expr $ln-1]}
		     {$i>=$start && [string m [index $line $i chars] $chars]}
		     {var i [expr $i-1]}
		     {}]
    	    } else {
    	    	# If doing file, command or variable completion, already
		# know where the thing starts...
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
		if {$ln != 0} {
		    var line [range $line 0 [expr $ln-1] chars]
		} else {
		    # The only character in the line is the completion char
		    var line {}
		}
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
		# if line == mcline, user just hit C-bracket again
	    	if {$mcidx == -1 || [string c $line $mcline]} {
		    #
		    # First time through -- record the list of symbols for
		    # later iterations and up the index to 0
		    #
		    var mcidx 0 mcplen $plen
		    var mcnames [sort $syms]
    	    	    #
		    # If no possibilities, beep at the user, reset our private
		    # counter and continue where we left off.  Don't forget
		    # to take off the trailing C-bracket
		    #
		    if {[length $mcnames] == 0} {
		    	beep
			var line [range $line 0 [expr $ln-1] chars]
    	    	    	var mcidx -1
			continue
		    }
		}
		var name [index $mcnames $mcidx]
    	    	if {[file isdir $name]} {
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
	    	    } elif {$fcomp && [file isdir $new]} {
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
        } elif {![string c $ec \020]} {
	    #
	    # If $line doesn't match $lastLine, then reset all history params
	    #
	  if {$ln != 0} {
#echo checking $ln line is "$line"
	    if {[string c $lastLine [range $line 0 [expr $ln-1] chars]] != 0 } {
#echo no match		
		var lastLine {}
		#var lasthist [history cur]
		if {[null $historySearching]} {
		    var completionLength -1
#echo no match -1
		} else {
		    var completionLength $ln
#echo checking $ln line is "$line"
		}
	    } else {
#echo match $completionLength		
	    }
	  }

	    var lasthist [expr $lasthist-1]

	    #
	    # If there's nothing to search for, or if we've already engaged
	    # in a sequential history recall, keep goin' sequentially.
	    #
	    if {$ln == 0 || $completionLength == -1} {

		#
		# Indicate that we're just walking backwards through history
		#
		var completionLength -1

		if {[catch {history fetch $lasthist} n] == 0} {
		    #
		    # Erase current command (tabs always expanded to spaces
		    # by read-line, so we're ok to do this...
		    #
		    for {var i $ln} {$i > 0} {var i [expr $i-1]} {
		        echo -n \b \b
		    }
		    var line $n
		    echo -n $n
		} else {
	    	    var lasthist [expr $lasthist+1]
		    if {$ln == 0} {
			var line {}
    	    	    } else {
			var line [range $line 0 [expr $ln-1] chars]
    	    	    }
    		}
	    } else {
		#
		# There's something ahead of the ctrl-p, so let's loop
		# back through history to find a match for it.
		#
		while {1} {
		  if {[catch {history fetch $lasthist} n] == 0} {
			#
			# See if the thing matches our search pattern.
			# Just for kicks, let's throw out all redundancies,
			# as well. It be nice to make this a little smarter
			# by throwing out *all* redundancies, not just
			# consecutive ones, but hey, it's Sunday.
			#
		    if {[string c [range $n 0 [expr $completionLength-1] chars]
			          [range $line 0 [expr $completionLength-1] chars]] == 0 &&
			[string c $lastLine $n] != 0} {

			#
			# It's a match!
			#
			for {var i [expr $ln-$completionLength]} {$i > 0} {var i [expr $i-1]} {
		            echo -n \b \b
		        }
			var line $n
		        echo -n [range $line $completionLength end chars]
			break
    	    	    } else {
		    	var lasthist [expr $lasthist-1]
		    }
		  } else {
		    	var lasthist [expr $lasthist+1]
			var line [range $line 0 [expr $ln-1] chars]
			#beep
			break
		  }
		}
    	    }
    	    #
    	    # Don't prompt again
	    #
	    var lastLine $line
	    continue
        } elif {![string c $ec \016]} {
	  #
	  # If $line doesn't match $lastLine, then reset all history params
	  #
	  if {$ln != 0} {
	    if {[string c $lastLine [range $line 0 [expr $ln-1] chars]] != 0 } {
		var lastLine {}
		#var lasthist [history cur]
		if {[null $historySearching]} {
		    var completionLength -1
		} else {
		    var completionLength $ln
		}
	    }
	  }

	    var lasthist [expr $lasthist+1]

	    if {$ln == 0 || $completionLength == -1} {
		#
		# Put out next command
		#
		if {[catch {history fetch $lasthist} n] != 0} {
    	  	    var lasthist [history cur]
	    	    var n {}
    	        }
		#
		# Erase current command (tabs always expanded to spaces
		# by read-line, so we're ok to do this...
		#
		for {var i $ln} {$i > 0} {var i [expr $i-1]} {
		echo -n \b \b
	        }
		var line $n
		echo -n $n
	    } else {
		#
		# We completed last time, so we need to backtrack here
		#
		while {1} {
		  if {[catch {history fetch $lasthist} n] == 0} {
		    if {[string c [range $n 0 [expr $completionLength-1] chars]
			          [range $line 0 [expr $completionLength-1] chars]] == 0 &&
			[string c $lastLine $n] != 0} {
			#
			# It's a match!
			#
			for {var i [expr $ln-$completionLength]} {$i > 0} {var i [expr $i-1]} {
		            echo -n \b \b
		        }
			var line $n
		        echo -n [range $line $completionLength end chars]
			break
    	    	    } else {
		    	var lasthist [expr $lasthist+1]
		    }
		  } else {
		    	var lasthist [expr $lasthist-1]
			var line [range $line 0 [expr $ln-1] chars]
			#beep
			break
		  }
		}
	    }
    	    #
    	    # Don't prompt again
	    #
	    var lastLine $line
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

	#
	# Reset the history counter
	#
	    var lasthist [history cur]
    }

    var lastCommand $line repeatCommand nil
    return $line
}]

[defcommand set-repeat {template} swat_prog.input
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

##############################################################################
#				tcsh
##############################################################################
#
# SYNOPSIS:  	Sets up various switches to enable tcsh-like command
#		line editing and history searching.
# CALLED BY:	
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/ 6/92		Initial Revision
#
##############################################################################
[defcommand tcsh {{option {}} args} {swat_navigation}
{Usage:
    tcsh [<command line editing specification>]
    tcsh off
    tcsh cle [<command line editing specification>]
    tcsh cle off
    tcsh hist [on]
    tcsh hist off

Examples:
    "tcsh"		Enables tcsh-style history searching and
			command line editing, using the default bindings.

    "tcsh aebfrvdtkyu"	Turns on tcsh-style history searching and
			command line editing, using the following bindings:

			ctrl-a: beginning of line
			ctrl-e: end of line
			ctrl-b: backward character
			ctrl-f: forward character
			ctrl-r: backward word
			ctrl-v: forward word
			ctrl-d: delete char
			ctrl-t: forward delete word
			ctrl-k: kill region
			ctrl-y: yank
			ctrl-u: kill line

    "tcsh off"		Disables tcsh-style history searching and
			command line editing.

    "tcsh cle"		Enables tcsh-style command line editing, leaving
			history searching unchanged.

    "tcsh cle off"	Disables tcsh-style command line editing, leaving
			history searching unchanged.

    "tcsh hist"		Enables tcsh-style history searching. leaving
			command line editing  unchanged.

    "tcsh hist off"	Disables tcsh-style history searching. leaving
			command line editing  unchanged.

Synopsis:
    This command implements enhanced command line editing, similar to that
    found in the tcsh shell. It also enables an enhancement to the history
    mechanism that searches the command history for elements whose beginnings
    match the current command line (similar to history-search-forward and
    -backward from tcsh).

Notes:

    * The default bindings are "aebfrvdtkyu", as above.

    * The variable wordDelineatingChars can be used to define characters
      that mark the beginning and end of words, according to the word
      related function. For example, typing:

var wordDelineatingChars {\040\t._\\/@}

      ... would designate spaces, tabs, periods, underscores, both kinds of
      slashes, and the "at" sign as places to "stop" during word-type
      operations such as "delete word" (which is always bound to ctrl-w,
      by the way).

    * With the exception of the "yank" command, other command line
      editing keystrokes are *not* intercepted if the command line is
      currently empty (since they'd have no effect anyways). This is
      to allow secondary uses of those keystrokes to take effect
      (eg., ctrl-b = backward page if blank line, backward char otherwise)

    * ctrl-d is still a completion character when the cursor is at the
      end of the current command line, so you probably don't want to
      map ctrl-d to one of the "backward" commands.
      
    * ctrl-space sets the mark, for use with the kill region command.
      *This isn't working for the DOS version.*

See Also:
    top-level-read, history
}
{
    global cleChars
    global defaultCleChars
    global historySearching

    if {[null $option]} {
	var cleChars $defaultCleChars
	var historySearching 1
	echo tcsh-style command line editing and history searching enabled
    } else {
	[case $option in
	    off {
	    	var cleChars {}
		var historySearching {}
		echo tcsh-style command line editing and history searching disabled
	    }
	    cle {
		var cles [index $args 0]
		if {[null $cles]} {
		    var cleChars $defaultCleChars
		    echo tcsh-style command line editing enabled
		} elif {[string c $cles off] == 0} {
		    var cleChars {}
		    echo tcsh-style command line editing disabled
		} elif {[length $cles char] != [length $defaultCleChars char]} {
		    echo tcsh-style command line editing specification must be [length $defaultCleChars char] characters long
		} else {
		    var cleChars $cles
		    echo tcsh-style command line editing enabled
		}
	    }
	    hist {
		if {[null [index $args 0]]} {
		    var historySearching 1
		    echo tcsh-style history searching enabled
		} elif {[string c [index $args 0] off] == 0} {
		    var historySearching {}
		    echo tcsh-style history searching disabled
		} else {
		    var historySearching 1
		    echo tcsh-style history searching enabled
		}
	    }
	    default {
		if {[length $option char] != [length $defaultCleChars char]} {
		    echo tcsh-style command line editing specification must be [length $defaultCleChars char] characters long
		} else {
		    var cleChars $option
		    var historySearching 1
		    echo tcsh-style command line editing and history searching enabled
		}
	    }
	]
    }
}]

var defaultCleChars {aebfrvdtkyu}
