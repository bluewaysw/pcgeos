##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	SWAT -- System library
# FILE: 	help.tcl
# AUTHOR: 	Adam de Boor, Mar 13, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	help	    	    	Provide help for a command or browse the tree
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/13/89		Initial Revision
#
# DESCRIPTION:
#	On-line help browsing facility.
#
#	$Id: help.tcl,v 3.0 90/02/04 23:46:47 adam Exp $
#
###############################################################################
defvar help-separator ==============================================================================
[defvar help-verbose 1 variable
{If non-zero, performs verbose prompting, which can be annoying after a while}]

[defvar help-minAspect 15 variable
{If non-zero, contains the minimum aspect ratio to be maintained when
displaying tables in the help browser. The ratio is expressed as the fraction
    entries_per_column*10/number_of_columns
E.g. a minimum ratio of 1.5 would be 15 (since we don't do floating-point)}]

#
# Select elements from list whose indexth character matches char. This is used
# to perform a sort of lexical radix sort for completion since list is sorted
# alphabetically. Returns the elements that match, or {} if (a) none matches or
# (b) one of those that made it so far has no indexth character. This
# indicates that we've gotten the common prefix from the elements and
# can go no further.
#
[defsubr help-pick {char list index}
{
    var start 0 end -1

    foreach i $list {
    	if {$index < [length $i chars]} {
	    [case [string c $char [index $i $index chars]] in
	      1 {var start [expr $start+1] end $start}
	      0 {var end [expr $end+1]}
	     -1 {break}
	    ]
    	} else {
	    var start [expr $start+1] end $start
	}
    }
    if {$start <= $end} {
    	return [range $list $start $end]
    } else {
    	return {}
    }
}]

#
# Format a sorted list of topics into a table of as many columns as possible,
# with the topics running down the columns.
#
[defsubr help-print-as-table {topics {ignoreAspect 0}}
{
    global help-minAspect

    #
    # Find the width of the longest one
    #
    var width 0
    foreach i $topics {
	var len [length $i chars]
	if {$len > $width} {
	    var width $len
	}
    }
    #
    # Up that by the inter-column spacing (2 -- magic)
    #
    var width [expr $width+2]
    #
    # Figure the number of columns we can put up (minimum of 1)
    #
    var nc [expr ([columns]-1)/$width]
    if {$nc == 0} {
	var nc 1
    }
    var tlen [length $topics]

    #
    # Figure out the distance between topics in a row. This is just
    # the number of topics divided by the number of columns, rounded up
    #
    var inc [expr ($tlen+$nc-1)/$nc]

    if {!$ignoreAspect && ${help-minAspect}} {
	while {($inc*10)/$nc < ${help-minAspect} && $nc != 1} {
	    var nc [expr $nc-1]
	    var inc [expr ($tlen+$nc-1)/$nc]
	}
    }    	

    #
    # Put up the table. Note that [index list n] when
    # n > [length list] returns empty, so there's no need to check
    # for overflow.
    #
    for {var i 0} {$i < $inc} {var i [expr $i+1]} {
	for {var j 0} {$j < $nc} {var j [expr $j+1]} {
	    echo -n [format {%-*s} $width
			    [index $topics [expr $i+$j*$inc]]]
	}
	echo
    }
}]

#
# Read in a command line for the help menu at the given level. topics is
# the sorted list of topics available at that level, for use in completion
#
[defsubr help-read {topics level}
{
    global help-verbose
    
    if {[var help-verbose]} {
    	echo {Type "help" for help, "menu" to redisplay the menu, "0" to exit.}
	echo {Type a topic (or its number) to display it.}
    }
    #
    # Print the prompt
    #
    prompt help:$level>
    
    #
    # Initialize variables
    #
    var line {}
    var mcidx -1
    
    for {} {1} {} {
    	#
	# Read a line, storing whatever we've already got in first
	#
    	var line [read-line 1 $line]
	
    	#
	# See if ends with a completion character
	#
	var ln [expr [length $line chars]-1]
	var ec [if {$ln >= 0} {index $line $ln chars} {}]
	if {[string m $ec \[\e\004\035\]]} {
    	    #
	    # Skip to first non-identifier character in the line
	    #
	    [for {var i [expr $ln-1]}
		 {$i>=0 && [string m [index $line $i chars] {[-A-Za-z0-9_]}]}
		 {var i [expr $i-1]}
		 {}]

    	    #
	    # Strip off the prefix while extracting it
	    #
    	    [var plen [expr $ln-($i+1)]
		 line [if {$i>=0} {range $line 0 $i chars} {}]
	     	 prefix [range $line [expr $i+1] [expr $ln-1] chars]]
	    
    	    #
	    # Use a radix-type sort to locate the range of topics that
	    # match, stopping when help-pick returns empty or we get a
	    # list of just one element. The range of possible topics is
	    # left in $possible
	    #
	    var possible $topics
	    var idx 0
	    foreach i [explode $prefix] {
	    	var next [help-pick $i $possible $idx]
		if {[string c $next _last_was_most_] == 0} {
		    break
		} elif {[length $next] == 1 && $idx == $plen-1} {
		    var possible $next
		    break
		}
		var possible $next
		var idx [expr $idx+1]
    	    }
	    
	    [case $ec in 
    	     \004 {
	     	#
		# Display all matching. Go to new line and print the list
		# in a table, then re-prompt with the line we had.
		#
    	    	var mcidx -1
    	    	echo
	     	help-print-as-table $possible 1
    	    	var line $line$prefix
    	    	prompt help:$level>
		echo -n $line
    	     }
	     \e {
	     	[case [length $possible] in
    	    	 1 {
		    #
		    # Unique completion -- find the rest of the word
		    # and add it to the end of line. Loop to fetch more
		    #
		    var suffix [range $possible $plen end chars]
		    echo -n $suffix
		    var line $line$prefix$suffix
    	    	 }
		 0 {
		    #
		    # No completions -- beep and put the prefix back on
		    #
		    beep
		    var line $line$prefix
    	    	 }
		 default {
		    #
		    # Too many completions -- use the completion function
		    # to fetch the common prefix, trim off whatever part
		    # is already showing, print that, adding it to the line,
		    # beep and continue.
		    #
		    var common [completion $possible]
		    var suffix [range $common $plen end chars]
    	    	    echo -n $suffix
		    var line $line$prefix$suffix
		    beep
    	    	 }]
    	     }
	     \035 {
	     	#
		# Cycle through possible completions
		#
	     	if {$mcidx == -1 || [string c $line$prefix $mcline]} {
    	    	    #
		    # New or line changed -- reset state variables
		    #
		    var mcidx 0 mcplen $plen last 0 mcnames $possible
    	    	}
		#
		# Fetch next name
		#
		var name [index $mcnames $mcidx]
    	    	#
		# Erase old tail of old one (stuff past common prefix)
		#
		for {var j $plen} {$j > $mcplen} {var j [expr $j-1]} {
		    echo -n \b\ \b
    	    	}
		#
		# Put out new tail
		#
		echo -n [range $name $mcplen end chars]
    	    	#
		# Tack the new name on, set state variables in case cycle
		# continued.
		#
    	    	var line $line$name
		var mcline $line
		var mcidx [expr ($mcidx+1)%[length $mcnames]]
	    }]
    	} else {
	    return $line
    	}
    }
}]
		    
#
# Locate all topics containing a given pattern and provide a menu of them,
# printing them out either by name or number upon request. Returns the name
# of the level to which the caller should go (if given "goto" command), or
# quit (if given "quit" command) to tell the caller to quit, or {} if things
# should stay as they were.
#
[defsubr help-find {pattern}
{
    global help-separator

    var topics [sort [help-scan $pattern]]
    var n 0
    var menu [concat {{ 0 FINISH}}
    	    	     [map t $topics {
			  var n [expr $n+1]
			  format {%2d %s} $n $t
		      }]]
    
    help-print-as-table $menu
    
    for {} {1} {} {
    	var line [help-read $topics $pattern]
	[case [index $line 0] in
    	 0 {
	    return {}
	 }
	 {[1-9]*} {
	    var t [index $topics [expr [index $line 0]-1]]
    	    if {[null $t]} {
	    	echo No such topic number
		continue
	    }
    	 }
	 find {
	    help-find [range $line 1 end]
	    return {}
    	 }
	 goto {
	    return [range $line 1 end]
	 }
	 |menu {
	    help-print-as-table $menu
    	    continue
    	 }
	 show {
    	    var t [range $line 1 end]
    	 }
	 default {
	    var t $line
	 }]
	 if {[catch {help-get $t} hl] != 0} {
	    echo $hl
	 } elif {[length $hl] == 1} {
	    echo \n[index $hl 0]\n${help-separator}
    	 } else {
	    foreach i $hl {
		echo \n$i\n${help-separator}
    	    }
    	 }
    }
}]	    
    
#
# Print out the menu of topics available at the given level, returning the
# list of topics sorted alphabetically.
#
[defsubr help-menu {level}
{
    if {[catch {help-fetch $level} desc] == 0} {
	echo $desc:\n
    }	
    #
    # Fetch the topics for this level
    #
    var topics [sort [help-fetch-level $level]]
    var num 0
    var menu [concat {{ 0 FINISH}}
    	    	    [map t $topics {
			    	var num [expr $num+1]
				if {[help-is-leaf $level.$t]} {
				    format {%2d %s} $num $t
				} else {
				    format {%2d %s...} $num $t
				}
			    }]]

    help-print-as-table $menu
    echo
    return $topics
}]

[defdsubr help-help {} obscure
{Available commands:
    show <topic>    Print the help for the given topic. If it has subtopics,
    	    	    provides a menu of those subtopics for you to examine.
    find <pattern>  Locate all help topics matching a pattern.
    up	    	    Go back up one level in the help tree.
    ..		    Same as "up"
    goto <level>    Go to a specific level in the help tree.
    menu    	    Show the menu for the current level.
    <topic> 	    Any topic that's not one of the above commands. Performs
    	    	    an implicit "show <topic>"
Just as symbols may be completed by typing escape, control-] or control-D,
topics may be completed in the same ways with the same characters (escape
finishes out the topic, if possible, or finishes as much as is common among
the possibilities and beeps when it becomes helpless; control-] cycles through
the possible choices; control-D prints out a table of the possibilities).

In this documentation and in usage messages, the following conventions have
been more-or-less followed:
    ()'s enclose a set of alternatives. The alternatives are separated by |'s
    []'s usually enclose optional elements, except in fairly obvious cases
	 where they imply a character class (e.g. for the "frame" command).
    <>'s enclose "non-terminals", i.e. a type of argument, rather than a
	 string that's to be typed as shown (e.g. "<addr>" means an address
	 expression, whereas "(addr|biff)" means either the string "addr" or
	 the string "biff").
'*' following one of these constructs means 0 or more of the thing, while '+'
means 1 or more.}
{
    # Print our own help message
    echo [index [help-get help-help] 0]
}]

[defcommand help {{command nil}} reference
{This is the user-level access to the on-line help facilities for SWAT. If
given a topic (e.g. "brk") as its argument, it will print all help strings
defined for the given topic (there could be more than one if the same name is
used for both a variable and a procedure, for instance). If invoked without
arguments, it will enter a browsing mode, allowing the user to work his/her
way up and down the documentation tree}
{
    global help-separator

    if {![null $command]} {
    	echo Help for $command:
	foreach i [help-get $command] {
	    echo $i\n${help-separator}
    	}
    	return
    }
    
    var level top

    global symbolCompletion
    var oldSC $symbolCompletion symbolCompletion 1
    protect {
    	var topics [help-menu $level]

	for {} {1} {} {
	    var line [help-read $topics $level]
	    [case [index $line 0] in
	     \\?|help {
	     	help-help
    	    	continue
    	     }
    	     0 {
	     	break
	     }
    	     {[1-9]*} {
	     	var t [index $topics [expr [index $line 0]-1]]
		if {[null $t]} {
		    echo No such topic number
		    continue
		}
    	     }
    	     show {
    	    	var t [range $line 1 end]
    	     }
    	     default {
    	    	var t [index $line 0]
    	     }
	     up|.. {
	     	if {[string c $level top] == 0} {
		    echo Can't go up -- already at top level
    	    	} else {
    	    	    var ldot [string last . $level]
		    if {$ldot < 0} {
		    	var level top
		    } else {
		    	var level [range $level 0 [expr $ldot-1] chars]
		    }
    	    	    var topics [help-menu $level]
    	    	}
		continue
    	     }
	     goto {
    	    	var t [range $line 1 end]
	     	if {[help-is-leaf $t] == 0} {
		    var level $t
		    var topics [help-menu $level]
    	    	} else {
		    echo $t: not a help level
    	    	}
		continue
    	     }
	     |menu {
	     	help-menu $level
    	    	continue
	     }
    	     find {
	     	var newLevel [help-find [range $line 1 end]]
		if {![null $newLevel] && ![help-is-leaf $newLevel]} {
		    var level $newLevel
    	    	    var topics [help-menu $level]
		} elif {[string c $newLevel quit] == 0} {
		    break
		}
		continue
    	     }
    	    ]
	    #
	    # Print the help for the selected thing
	    #
    	    if {[catch {help-is-leaf $level.$t} isLeaf] != 0} {
	    	echo $isLeaf
    	    } elif {!$isLeaf} {
		var level $level.$t
		var topics [help-menu $level]
	    } else {
		if {[catch {help-fetch $level.$t} str] == 0} {
		    echo Help for $t:\n$str\n${help-separator}
		}
	    }
	}
    } {
	var symbolCompletion $oldSC
    }
}]

##############################################################################
#   	    	    	    	    	    	    	    	    	     #
#		       HELP CLASS DOCUMENTATION				     #
#									     #
##############################################################################
[defhelp breakpoint top
{Commands relating to the setting of breakpoints}]

[defhelp kernel top
{Commands used to print/decode kernel data structures}]

[defhelp memory top
{Commands used to access memory in various ways}]

[defhelp misc top
{Commands that fit in no other category}]

[defhelp obscure top
{Commands that you probably don't want to know about}]

[defhelp output top
{Commands relating to output}]

[defhelp patient top
{Commands for accessing and altering the state of the patient}]

[defhelp profile top
{Commands for tracing/profiling the execution of a patient}]

[defhelp prog top
{Commands for programming swat}]

[defhelp reference top
{Commands for accessing reference material}]

[defhelp stack top
{Commands for examining and manipulating the stack of a thread}]

[defhelp thread top
{Commands for accessing/altering the state of a thread}]

[defhelp variable top
{Variables for altering swat's behaviour}]

[defhelp window top
{Commands to alter how swat's windowing works}]

[defhelp breakpoint prog
{Functions to set breakpoints from TCL}]

[defhelp def prog
{Functions for defining various things}]

[defhelp external prog
{Functions to execute things in the UNIX world (i.e. not in swat)}]

[defhelp file prog
{Functions for accessing files}]

[defhelp help prog
{Functions for manipulating/accessing the help tree}]

[defhelp input prog
{Functions for fetching input from the user}]

[defhelp list prog
{Functions for manipulating lists}]

[defhelp load prog
{Functions for loading TCL code}]

[defhelp memory prog
{Functions for accessing memory from TCL}]

[defhelp obscure prog
{Really obscure functions that I don't want to know about}]

[defhelp output prog
{Functions for producing output}]

[defhelp patient prog
{Functions for accessing/altering the state of a patient}]

[defhelp stack prog
{Functions for manipulating/accessing a stack}]

[defhelp string prog
{Functions for manipulating strings}]

[defhelp tcl prog
{General category for tcl-internal (as opposed to swat-internal) functions}]

[defhelp window prog
{Functions for manipulating windows}]

[defhelp conditional prog.tcl
{Functions for conditional execution/control decisions}]

[defhelp error prog.tcl
{Functions relating to error processing}]

[defhelp list prog.tcl
{Functions for manipulating lists}]

[defhelp loop prog.tcl
{Looping constructs}]
