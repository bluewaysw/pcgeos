##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	history.tcl
# FILE: 	history.tcl
# AUTHOR: 	Adam de Boor, Jul  6, 1992
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	history
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/ 6/92		Initial Revision
#
# DESCRIPTION:
#	Tcl implementation of command-line history.
#
#   	Substitution is based loosely on this grammar:
#
# line		: REAL_CHAR
# 		| hist
# 		| line REAL_CHAR
# 		| line hist
# 		;
# hist		: '!' event_spec modifiers
# 		| '!' '!' modifiers
# 		| '!' special_word
# 		| '!' special_word ':' modifier
# 		;
# modifiers	: /* nothing */
# 		| ':' wordspec
# 		| ':' modifier
# 		| ':' wordspec ':' modifier
# 		;
# 
# special_word	: '*'
# 		| '^'
# 		| '$'
# 		;
# 
# event_spec	: number
# 		| '-' number
# 		| '?' string
# 		| '?' string '?'
# 		| non_ws_string
# 		;
# wordspec	: word
# 		| word '-' word
# 		| '-' word
# 		| word '-'
# 		| number '*'
# 		| '*'
# 		;
# word		: number
# 		| '^'
# 		| '$'
# 		;
# number		: digit
# 		| number digit
# 		;
# digit		: '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' ;
# string		: string_char
# 		| string string_char
# 		;
# string_char	: REAL_CHAR
# 		| ' '
# 		| '\t'
# 		;
# non_ws_string	: REAL_CHAR
# 		| non_ws_string REAL_CHAR
# 		;
# 
# modifier	: 'g' modifier
# 		| 's'
# 		| 'h'
# 		| 'r'
# 		| 'e'
# 		| 't'
# 		;
#
#
#	$Id: history.tcl,v 1.7 93/07/31 22:36:32 jenny Exp $
#
###############################################################################

#
# Define the history queue as a FIFO cache of at most 50 entries, by default.
#
defvar history-queue nil
if {[null ${history-queue}]} {
    var history-queue [cache create fifo 50]
}

#
# The number of the next entry to be added to the queue.
#
defvar history-next-number 1

##############################################################################
#				history-input
##############################################################################
#
# SYNOPSIS:	Fetch the next character from the command being substituted
# PASS:		nothing
# CALLED BY:	INTERNAL
# RETURN:	next character, or {} if none left
# SIDE EFFECTS:	curpos in history-subst incremented
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/ 6/92		Initial Revision
#
##############################################################################
[defsubr history-input {}
{
    return [uplevel history-subst
    	    if {$curpos < $endpos} {
    	    	var curpos [expr $curpos+1]
	    	index $line [expr $curpos-1] char
    	    }
    	]
}]

##############################################################################
#				history-unput
##############################################################################
#
# SYNOPSIS:	Put a character back into the line being parsed
# PASS:		c   = character fetched by history-input
# CALLED BY:	INTERNAL
# RETURN:	nothing
# SIDE EFFECTS:	so long as $c isn't {}, back up $curpos in history-subst
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/ 6/92		Initial Revision
#
##############################################################################
[defsubr history-unput {c}
{
    if {[string c $c {}]} {
    	uplevel history-subst {var curpos [expr $curpos-1]}
    }
}]

##############################################################################
#				history-output
##############################################################################
#
# SYNOPSIS:	Append the given string to the one being built
# PASS:		str 	= string to append
# CALLED BY:	INTERNAL
# RETURN:	nothing
# SIDE EFFECTS:	retval in history-subst has $str appended to it
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/ 6/92		Initial Revision
#
##############################################################################
[defsubr history-output {str}
{
    uplevel history-subst var str $str
    uplevel history-subst {var retval $retval$str}
}]

##############################################################################
#				history-parse-number
##############################################################################
#
# SYNOPSIS:	Parse a decimal number from the input stream
# PASS:		c   = initial character
# CALLED BY:	INTERNAL
# RETURN:	the number parsed
# SIDE EFFECTS:	input pointer points to first char not in the number
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/ 6/92		Initial Revision
#
##############################################################################
[defsubr history-parse-number {c}
{
    [for {
	    var n $c
	    var c [history-input]
	 }
	 {[string m $c {[0-9]}]}
	 {
	    var n $n$c
	    var c [history-input]
	 }
    {}]
    history-unput $c
    return [expr $n]
}]

##############################################################################
#				history-fetch
##############################################################################
#
# SYNOPSIS:	Retrieve the command stored in the history queue under
#   	    	the given number
# PASS:	    	num	= number to fetch
# CALLED BY:	history-hist, history
# RETURN:	the command string.
# SIDE EFFECTS:	generates an error if that number's not in the queue
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/ 6/92		Initial Revision
#
##############################################################################
[defsubr history-fetch {num}
{
    global history-queue

    var e [cache lookup ${history-queue} $num]
    if {[null $e]} {
	error [format {entry %s not in command history} $num]
    } else {
	return [cache getval ${history-queue} $e]
    }
}]

##############################################################################
#				history-fetch-relative
##############################################################################
#
# SYNOPSIS:	Fetch the text of the nth previous command
# PASS:		n   = number of commands to go back (1 = the previous command)
# CALLED BY:	history-hist
# RETURN:	the text of the previous command
# SIDE EFFECTS:	generates an error if there aren't that many commands in the
#   	    	queue
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/ 6/92		Initial Revision
#
##############################################################################
[defsubr history-fetch-relative {n}
{
    global history-next-number
    
    return [history-fetch [expr ${history-next-number}-$n]]
}]

##############################################################################
#				history-search
##############################################################################
#
# SYNOPSIS:	Search for a command in the history queue with the
#   	    	indicated string and return it.
# PASS:		str 	= string for which to search
#   	    	anchor	= non-zero if must be at start of command
# CALLED BY:	history-hist
# RETURN:	command string
# SIDE EFFECTS:	generates an error if no match found
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/ 6/92		Initial Revision
#
##############################################################################
[defsubr history-search {str anchor}
{
    global history-queue history-next-number
    
    [for {
    	    var i [expr ${history-next-number}-1]
	    var e [cache lookup ${history-queue} $i]
    	 }
	 {![null $e]}
	 {
	    var i [expr $i-1]
	    var e [cache lookup ${history-queue} $i]
    	 }
    {
    	var cmd [cache getval ${history-queue} $e]
	var ind [string first $str $cmd]
	if {$ind >= 0 && (!$anchor || $ind == 0)} {
	    return $cmd
    	}
    }]
    if {$anchor} {
    	error [format {no command begins with "%s"} $str]
    } else {
    	error [format {no command contains "%s"} $str]
    }
}]

##############################################################################
#				history-parse-range-end
##############################################################################
#
# SYNOPSIS:	Parse off the end of a word range. '-' has already been seen
# PASS:		in history-hist scope:
#   	    	    cmd	= command selected by !
# CALLED BY:	history-word-or-mod
# RETURN:	the number to use (may be "end")
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
[defsubr history-parse-range-end {}
{
    #
    # Range specified; parse ending number
    #
    var c [history-input]
    if {[string m $c {[0-9]}]} {
	var end [history-parse-number $c]
    } elif {![string c $c {$}]} {
	var end end
    } else {
	# all but final word...
	var end [expr [uplevel history-hist {length $cmd}]-2]
	if {$end < 0} {
	    var end 0
	}
	history-unput $c
    }
    return $end
}]

##############################################################################
#				history-modifiers
##############################################################################
#
# SYNOPSIS:	Search for and process all modifiers we can find
# PASS:		in history-hist scope:
#   	    	    cmd	    = range of words on which to operate
# CALLED BY:	history-word-or-mod, history-hist
# RETURN:	nothing
# SIDE EFFECTS:	$cmd is modified according to the modifiers, if any
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/ 6/92		Initial Revision
#
##############################################################################
[defsubr history-modifiers {}
{
    [for {var c [history-input]}
    	 {![string c $c :]}
	 {var c [history-input]}
    {
    	var isglobal 0
	[for {
	    	var c [history-input]
    	     }
	     {1}
	     {
	     	var c [history-input]
	     }
    	{
	    [case $c in
	     g	{
	     	var isglobal 1
    	     }
	     s	{
	     	var delim [history-input]
		if {[null $delim]} {
		    error {:s missing search string}
    	    	}
		[for {var search {} c [history-input]}
		     {[string c $c $delim] && [string c $c {}]}
		     {
		     	var search $search$c 
			var c [history-input]
    	    	     }
    	    	{}]
		if {![string c $c $delim]} {
		    [for {var replace {} c [history-input]}
			 {[string c $c $delim] && [string c $c {}]}
			 {
			    var replace $replace$c
			    var c [history-input]
			 }
		    {}]
    	    	} else {
		    var replace {}
    	    	}
		if {$isglobal} {
		    uplevel history-hist [format {var cmd [string subst $cmd %s %s global]}
		    	    [list $search]
			    [list $replace]]
    	    	} else {
		    uplevel history-hist [format {var cmd [string subst $cmd %s %s]}
		    	    [list $search]
			    [list $replace]]
    	    	}		
		break
    	     }
	     h	{
	     	uplevel history-hist {
		    var cmd [map i $cmd {
		    	file dirname $i
    	    	    }]}
    	    	break
    	     }
	     r	{
	     	uplevel history-hist {
		    var cmd [map i $cmd {
		    	file rootname $i
    	    	    }]}
    	    	break
	     }
	     e	{
	     	uplevel history-hist {
		    var cmd [map i $cmd {
		    	file extension $i
    	    	    }]}
    	    	break
    	     }
	     t	{
	     	uplevel history-hist {
		    var cmd [map i $cmd {
		    	file tail $i
    	    	    }]}
    	    	break
    	     }
	     default {
	     	error [format {unknown history modifier %s} $c]
    	     }]
    	}]
    }]
    history-unput $c
}]

##############################################################################
#				history-word-or-mod
##############################################################################
#
# SYNOPSIS:	Parse off an optional word specifier, then an optional
#   	    	modifier
# PASS:		in history-hist scope:
#   	    	    cmd	= string on which to operate
# CALLED BY:	history-hist
# RETURN:	nothing
# SIDE EFFECTS:	cmd altered as appropriate
#
# STRATEGY
#   	for both a modifier and a word-specifier, the next character must be
#   	a colon
#
#   	Once the colon's been ascertained, we look at the next char to decide
#   	whether it's a word-spec (0-9, -, ^, $, *) or a modifier (anything
#	else)
#
#   	If it's a modifier, push the : and the second char back into the
#   	input and call history-modifiers
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/ 6/92		Initial Revision
#
##############################################################################
[defsubr history-word-or-mod {}
{
    var c [history-input]
    #
    # If next char is one of the specials ($, ^, or *), just push it back
    # into the input stream and pretend we got a :
    #
    if {[string m $c {[$^*]}]} {
    	history-unput $c
    } elif {[string c $c :]} {
    	#
	# Not a colon either, so not a word specification. Stop right here.
	#
    	history-unput $c
	return
    }
    #
    # Figure the start and end of the subrange to be used from $cmd
    #
    var start 1
    var end end
    var c [history-input]
    [case $c in
     {[0-9]} {
    	#
	# Parse start of range
	#
    	var start [history-parse-number $c]
	var c [history-input]
	[case $c in
	 {-} {
    	    #
	    # Range specified -- parse the end
	    #
	    var end [history-parse-range-end]
    	 }
	 {\*} {
	    # from $start to end, but $end == end, so do nothing
    	 }
	 default {
	    #
	    # Anything else means number is by itself and want only that
	    # arg.
	    #
	    history-unput $c
	    var end $start
    	 }
    	]
     }
     {-} {
     	#
	# Range starting with word 0
	#
     	var start 0
	var end [history-parse-range-end]
     }
     {\*} {
     	# do nothing. $start == 1, $end == end
     }
     {^} {
    	# $start == 1, so just see if there's a range, and set $end to 1 if
	# not.
	var c [history-input]
	if {[string c $c -]} {
    	    var end 1
	    history-unput $c
    	} else {
	    var end [history-parse-range-end]
    	}
     }
     {$} {
     	var end [expr [uplevel history-hist {length $cmd}]-1]
	var start $end
     }
     default {
     	history-unput $c
	history-unput -
	var start 0
     }
    ]
    #
    # Now set $cmd in history-hist to the specified range
    #
    uplevel history-hist [format {var cmd [range $cmd %s %s]} $start $end]
    #
    # Look for modifier list
    #
    history-modifiers
}]
     
    

##############################################################################
#				history-hist
##############################################################################
#
# SYNOPSIS:	    "hist" rule for parsing a history specification
# PASS:		    !	character seen
# CALLED BY:	    history-subst
# RETURN:	    nothing
# SIDE EFFECTS:	    characters are consumed and output
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/ 6/92		Initial Revision
#
##############################################################################
[defsubr history-hist {}
{
    var c [history-input]
    [case $c in
     {[0-9]} {
    	# parse command number, then apply wordspec/modifiers
	var n [history-parse-number $c]
    	var cmd [history-fetch [expr $n]]	
	history-word-or-mod
     }
     {#} {
     	var cmd [uplevel history-subst var retval]
	history-word-or-mod
     }
     {:} {
    	# start of wordspec or modifier: put it back and fetch prev command,
	# then apply wordspec/modifiers
     	history-unput $c
	var cmd [history-fetch-relative 1]
	history-word-or-mod
     }
     {!} {
    	# fetch prev command and apply wordspec/modifiers
	var cmd [history-fetch-relative 1]
	history-word-or-mod
     }
     {\*} {
     	# fetch 1-$ of prev command and apply modifiers
	var cmd [range [history-fetch-relative 1] 1 end]
	history-modifiers
     }
     {^} {
     	# fetch 1 of prev command and apply modifiers
	var cmd [index [history-fetch-relative 1] 1]
    	#
    	# deal with range
	#
	var c [history-input]
	if {[string c $c -]} {
	    history-unput $c
    	} else {
	    var end [history-parse-range-end]
	    var cmd [range $cmd 1 $end]
    	}
	history-modifiers
     }
     {$} {
     	# fetch $ of prev command and apply modifiers
	var cmd [history-fetch-relative 1]
	var end [expr [length $cmd]-1]
	var cmd [range $cmd $end $end]
	history-modifiers
     }
     {\?} {
     	# read all remaining text or until next question mark and search for
	# cmd with that string in it, then apply wordspec/modifiers
    	var str {}
	[for {var c [history-input]}
	     {[string c $c {}] && [string c $c ?]}
	     {var c [history-input]}
    	{
	    var str $str$c
    	}]
	var cmd [history-search $str 0]
	history-modifiers
     }
     {-} {
     	# parse number and fetch cur_num-number, then apply wordspec/modifiers
    	var c [history-input]
	if {[string m $c {[0-9]}]} {
    	    var n [history-parse-number $c]
    	} else {
	    var n 1
    	}
    	var cmd [history-fetch-relative $n]	
	history-word-or-mod
     }
     {{ } \t =} {
     	# output ! followed by $c
	history-output !$c
	return
     }
     default {
    	# read chars up to next whitespace/colon and search for cmd with that
	# string at its start, then apply wordspec/modifiers
    	var str {}
	[for {}
	     {[string c $c {}] && ![string m $c \[\ \t:\]]}
	     {var c [history-input]}
    	{
	    var str $str$c
    	}]
	history-unput $c
	var cmd [history-search $str 1]
	history-word-or-mod
     }]
    history-output $cmd
}]
    
##############################################################################
#				history-subst
##############################################################################
#
# SYNOPSIS:	    Perform history substitution on the given string.
# PASS:		    line    = string on which to perform substitution
# CALLED BY:	    history
# RETURN:	    line with substitution performed
# SIDE EFFECTS:	    generates an error if a substitution request is malformed
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/ 6/92		Initial Revision
#
##############################################################################
[defsubr history-subst {line}
{
    #
    # If line begins with caret, it means to perform substitution on the
    # previous command. The easiest way for us to do this is to mangle the
    # command to be !!:s^search^replace^ from the ^search^replace^ that it
    # was before.
    #
    if {![string c [index $line 0 char] ^]} {
    	var line !!:s$line
    }
    #
    # Trivial reject
    #
    if {[string first {!} $line] < 0} {
    	return $line
    }
    
    #
    # Set up variables that history-input and history-output will use.
    #
    var curpos 0 endpos [length $line chars]
    var retval {}

    for {} {1} {} {
    	var c [history-input]
	if {[string c $c !]} {
    	    if {![string c $c {}]} {
	    	break
    	    } elif {![string c $c {\\}]} {
		var c [history-input]
		if {[string c $c {!}]} {
	    	    history-output {\\}
    	    	}
    	    }
	    history-output $c
    	} else {
	    history-hist
    	}
    }
    
    return $retval
}]    
    
##############################################################################
#				history
##############################################################################
#
# SYNOPSIS:	    Implementation of command-line history queue
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
[defcommand history {{option {}} args} support
{Usage:
    history <n>
    history set <queue-size>
    history subst <string>
    history cur
    history fetch <n>
    history save <file>
    history load <file>

Examples:
    "history 10"    	    	Prints the last 10 commands entered via the
				"history subst" command.
    "history subst $line"	Performs history substitution on
				the string in $line, enters the result 
				in the history queue and returns the
				result.
    "var n [history cur]"   	Stores the number of the next string to be
				entered via "history subst" in the variable n.
    "history set 50"	    	Limit the number of entries in the queue to
				50.
    "history fetch 36"	    	Returns the string entered as command number
				36 in the history queue.

Synopsis:
    This command implements command-history, with its attendant substitution.
    The history is a queue of a fixed size, with each entry in the queue
    having a unique number by which it is referenced.

Notes:

See Also:
    top-level-read
}
{
    global history-queue history-next-number

    if {[null $option]} {
    	var option [cache maxsize ${history-queue}]
    }

    [case $option in
     {[0-9]*} {
     	[for {var i [expr ${history-next-number}-$option]}
	     {$i < ${history-next-number}}
	     {var i [expr $i+1]}
    	{
	    var e [cache lookup ${history-queue} $i]
	    if {![null $e]} {
	    	echo [format {%4d  %s} $i [cache getval ${history-queue} $e]]
    	    }
    	}]
     }     
     cur {
     	return ${history-next-number}
     }
     set {
    	#
	# Set the maximum size of the queue...
	#
    	var n [index $args 0]
	if {$n < 1} {
	    var n 1
    	}
     	cache setmaxsize ${history-queue} $n
     }
     fetch {
    	#
	# Fetch the text of a particular entry in the queue.
	#
    	return [history-fetch [index $args 0]]
     }
     subst {
    	#
	# Perform the substitution itself.
	#
    	var retval [history-subst [index $args 0]]
    	#
	# Enter the result in the queue.
	#
	var e [cache enter ${history-queue} ${history-next-number}]
	cache setval ${history-queue} $e $retval
    	#
	# Advance the next-number counter.
	#
	var history-next-number [expr ${history-next-number}+1]
    	#
	# And return the result.
	#
	return $retval
     }
     save {
     	protect {
	    var s [stream open [index $args 0] wt]
	    if {![null $s]} {
	    	[for {var i 1}
		     {$i < ${history-next-number}}
		     {var i [expr $i+1]}
		{
		    var e [cache lookup ${history-queue} $i]
		    if {![null $e]} {
		    	stream write [cache getval ${history-queue} $e] $s
			stream write \n $s
    	    	    }
    	    	}]
    	    }
    	} {
	    if {![null $s]} {stream close $s}
    	}
     }
     load {
     	protect {
	    var s [stream open [index $args 0] rt]
	    if {![null $s]} {
	    	while {![stream eof $s]} {
		    var l [stream read line $s]
		    if {![null $l]} {
		    	var e [cache enter ${history-queue} ${history-next-number}]
			cache setval ${history-queue} $e $l
			var history-next-number [expr ${history-next-number}+1]
    	    	    }
    	    	}
    	    }
    	} {
	    if {![null $s]} {stream close $s}
    	}
     }
     default {
    	error {Usage: history (<n>|set|subst|cur|fetch|save|load)}
     }
    ]
}]
