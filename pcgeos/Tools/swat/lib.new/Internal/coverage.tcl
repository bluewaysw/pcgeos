##############################################################################
#
# 	Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	
# FILE: 	coverage.tcl
# AUTHOR: 	Adam de Boor, Sep 17, 1993
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	9/17/93		Initial Revision
#
# DESCRIPTION:
#	Functions to analyze code-coverage for a geode.
#
#	$Id: coverage.tcl,v 1.5 95/05/17 13:58:22 john Exp $
#
###############################################################################

[defcommand coverage {args} profile
{Usage:
    coverage [-sp | -x] (<patient> | <resource> | <function>)

Examples:
    "coverage geos"	    	    	Prints out the ranges of source lines
					in all loaded resources of the patient
					"geos", saying whether they've been
					executed or not.
    
    "coverage dump::Resident"	    	Prints out the ranges of source lines
					for the Resident module of the "dump"
					application, saying whether they've 
					been executed.
    
    "coverage -s FileSetCurrentPath"	Prints out the source of the
					"FileSetCurrentPath" function, placing
					a > beside every line that has *not*
					been executed.
    
    "coverage -p geos"	    	    	Prints out the percentage of the "geos"
    	    	    	    	    	patient which has been executed. This
					is the percentage of bytes, not the
					percentage of lines.
    
    "coverage -x geos"	    	    	Prints out a reduced summary of
	    	    	    	    	the percentage coverage for a geode.
    	    	    	    	    	
					This option can't be used with -s or
					-p. It generates overall statistics
					along with statistics about which
					functions were hit/not-hit.

Synopsis:
    Prints out information on the basic block execution coverage of a
    test suite.

Notes:
    * The patient in question must have been assembled with Esp's -pb flag
      turned on to insert the requisite code to remember when a basic block
      of code (a sequence of instructions that are always executed together)
      has been executed.

    * This is functional only for assembly language, currently.

See also:
    restally.
}
{
    # default to printing out line numbers
    var mode numbers
    
    # default to not compute and print the percentage
    var percentage 0
    
    # default to not compute and print the summary
    var summary 0
    
    # amount of covered code and amount of uncovered code
    var coveredCode 0 uncoveredCode 0
    
    # parse arguments
    while {[string match [index $args 0] -*]} {
    	[case [index $args 0] in
	 -s  {var mode source}
	 -p  {var percentage 1}
	 -sp {var mode source percentage 1}
	 -x  {var summary 1}
	 *   {error [format {unknown flag (or combination) %s} [index $args 0]]}]
	var args [cdr $args]
    }
    
    if {$summary} {
	#
    	# Just clear the other flags for the user, rather than just
	# bitching.
	#
	if {$mode == source || $percentage == 1} {
	    echo {-x flag overrides both -s and -p flags}
	    echo {continuing ...}

	    var mode numbers
	    var percentage 0
	}
	
	#
	# Get the patient in question
	#
	var p [patient find [index $args 0]]
	
	if {[null $p]} {
	    error [format {-x flag requires a patient: %s} [index $args 0]]
	}
	
	#
	# The data we are generating is a big list with elements that look
	# like this:
	#   	{function_name {}}
	# Where each element represents a function that was actually hit.
	#

	#
	# Process each resource generating the data we need.
	#
	var summary-list {}

	echo -n {Processing}
	flush-output
	foreach r [range [patient resources $p] 2 end] {
	    #
	    # Enumerate over all the profile marks in the resource, but
	    # only if the resource is loaded (the 'if' condition).
	    #
    	    if {([handle state $r] & 1)} {
	    	[symbol foreach [handle other $r] profile
		    coverage-summary-callback]
    	    }
	}

	#
	# Spit out the data
	#
	var coveredFuncs 0 uncoveredFuncs 0

	echo
    	echo [format {%-50s %s} Function Status]
    	echo [format {%-50s %s} -------- ------]
	foreach r [range [patient resources $p] 2 end] {
	    #
	    # Enumerate over all the functions in the resource.
	    #
	    [symbol foreach [handle other $r] proc
		    coverage-summary-generate-report]
	}
	
	#
	# Spit out the percentages
	#
	echo
	echo {Summary:}
	echo [format {   Functions Hit:     %d} $coveredFuncs]
	echo [format {   Functions Not Hit: %d} $uncoveredFuncs]
	
	var total [expr $coveredFuncs+$uncoveredFuncs]
	echo [format {   Percent hit:       %3.2f}
    	    	    	    [expr 100*($coveredFuncs/$total) float]]
	echo [format {   Percent not hit:   %3.2f}
    	    	    	    [expr 100*($uncoveredFuncs/$total) float]]
	return 0
    }

    #
    # First see if the thing is a patient.
    #
    while {[length $args] > 0} {
	#
	# Initialize state variables used by coverage-process and
	# coverage-print-line
	#
    	var state {} lastfile {}
	var p [patient find [index $args 0]]
	
	if {![null $p]} {
	    #
	    # Print coverage for all resources of the patient
	    #
	    foreach r [range [patient resources $p] 2 end] {
	    	echo
		echo RESOURCE: [symbol name [handle other $r]]
		
		if {!([handle state $r] & 1)} {
		    echo Never brought into memory
		} else {
		    #
		    # Initialize state variables used by coverage-process and
		    # coverage-print-line
		    #
		    var state {} lastfile {}
		    #
		    # Enumerate over all the profile marks in the resource.
		    #
		    [symbol foreach [handle other $r] profile
			    coverage-callback
			    [list resource [list $r ^h[handle id $r]]]]
		    if {![null $state]} {
		    	coverage-print-line $state
    	    	    }
		}
	    }
	} else {
	    #
	    # See if the argument is a function or module.
	    #
	    var f [symbol find {proc module} [index $args 0]]
	    if {[null $f]} {
		error [format {%s unknown} [index $args 0]]
    	    }

	    if {$mode == numbers} {
		echo [format {%-20s State} {Line(s)}]
	    }

	    if {[symbol class $f] == module} {
    	    	#
		# For a resource, print out info for all the profile markers.
		#
		var h [index [addr-parse [symbol fullname $f]:0] 0]
		[symbol foreach $f profile
    	    	    	coverage-callback
			[list resource [list $h ^h[handle id $h]]]]
	    } else {
	    	#
		# For a procedure, only print out the markers that are within
		# the procedure.
		#
		[symbol foreach [symbol scope $f] profile 
		    coverage-callback 
		    [list function [list $f ^h[handle id [index [addr-parse [symbol fullname [symbol scope $f]]:0] 0]]]]]
	    }
	    #
	    # Finish up any pending state
	    #
	    if {![null $state]} {
		coverage-print-line $state
	    }
	}
	var args [cdr $args]
    }
    
    #
    # Print out the percentage if desired by the user
    #
    if {$percentage} {
    	var total [expr $coveredCode+$uncoveredCode]
	var percC [format %3.2f [expr 100*($coveredCode/$total) float]]
	var percU [format %3.2f [expr 100*($uncoveredCode/$total) float]]
	
	echo
	echo [format {Total bytes:        %6d} $total]
	echo [format {Total covered:      %6d} $coveredCode]
	echo [format {Total not covered:  %6d} $uncoveredCode]
	echo
	echo [format {Percent covered:     %5s%%} $percC]
	echo [format {Percent not covered: %5s%%} $percU]
    }
}]

##############################################################################
#				coverage-summary-callback
##############################################################################
#
# SYNOPSIS:	Callback function to generate summary information
# PASS:	    	sym 	= token for profile mark symbol
# CALLED BY:	coverage via symbol foreach
# RETURN:	0 => keep enumerating
# SIDE EFFECTS:	$state in coverage will be altered
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	5/17/95		Initial Revision
#
##############################################################################
[defsubr coverage-summary-callback {sym}
{
    #
    # Skip this work if the thing isn't a basic-block profiling symbol.
    #
    if {[index [symbol get $sym] 1] != 1} {
    	return 0
    }
    
    var sl  [uplevel coverage var summary-list]
    var sc  [symbol fullname [symbol scope $sym]]
    var ap  [addr-parse $sc]
    var seg [handle segment [index $ap 0]]
    var off [symbol addr $sym]

    #
    # If the state of the profiling marker is "hit", then add this
    # function to the head of the list (if it's not there already).
    #
    var paddr [symbol addr $sym]

    if {[value fetch $seg:$paddr byte] != 0xc0} {
	#
	# The marker was hit.
	#
	var fn  [symbol fullname [symbol faddr proc $seg:$off]]

	#
	# Check to see if the list is null, or if the function is already
	# there.
	#
        if {[null $sl] || [index [index $sl 0] 0] != $fn} {
	    #
	    # Empty list, or function not in the list, add the new state.
	    # I use an assoc list because I am too lazy to write a 'member'
	    # function later ...
	    #
	    uplevel coverage var summary-list [cons [list $fn {}] $sl]
	    echo -n {.}
    	    flush-output
    	}
    }

    #
    # Keep processing
    #
    return 0
}]    

##############################################################################
#				coverage-summary-generate-report
##############################################################################
#
# SYNOPSIS:	Generate a report for the summary coverage
# PASS:	    	sym = symbol of the function to check
# CALLED BY:	coverage
# RETURN:	none
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	5/17/95		Initial Revision
#
##############################################################################
[defsubr coverage-summary-generate-report {sym}
{
    #
    # Get the summary list
    #
    var sl [uplevel coverage var summary-list]
    
    #
    # Get the function name.
    #
    var fn [symbol fullname $sym]
    
    #
    # If the function is in the summary list, then we say that it's hit, 
    # otherwise it's not.
    #
    var q [assoc $sl $fn]

    if {![null $q]} {
    	var status hit
    	var cf [uplevel coverage var coveredFuncs]
    	uplevel coverage var coveredFuncs [expr $cf+1]
    } else {    	
	var status {NOT HIT}
    	var ucf [uplevel coverage var uncoveredFuncs]
    	uplevel coverage var uncoveredFuncs [expr $ucf+1]
    }
    echo [format {%-50s %-10s} $fn $status]
}]    

##############################################################################
#				coverage-callback
##############################################################################
#
# SYNOPSIS:	Callback function to print out the coverage of whatever...
# PASS:	    	sym 	= token for profile mark symbol
#		data	= {<type> <handle> <segment>}
#   	    	    	where type = Type of callback {function, resource}
# CALLED BY:	coverage via symbol foreach
# RETURN:	0 => keep enumerating
# SIDE EFFECTS:	$state and $lastfile in coverage will be altered
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	9/17/93		Initial Revision
#
##############################################################################
[defsubr coverage-callback {sym data}
{
    var type [index $data 0]
    var d    [index $data 1]

    if {$type == function} {
    	return [coverage-func-callback $sym $d]
    } elif {$type == resource} {
    	return [coverage-res-callback $sym $d]
    } else {
	error [format {Unexpected callback type %s} $type]
    }
}]    

##############################################################################
#				coverage-res-callback
##############################################################################
#
# SYNOPSIS:	Callback function to print out the coverage of a resource
# PASS:		sym 	= token for profile mark symbol
#		data	= {<handle> <segment>}
# CALLED BY:	coverage via symbol foreach
# RETURN:	0 => keep enumerating
# SIDE EFFECTS:	$state and $lastfile in coverage will be altered
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	9/17/93		Initial Revision
#
##############################################################################
[defsubr coverage-res-callback {sym data}
{
    #
    # Make sure marker is for basic-block analysis
    #
    if {[index [symbol get $sym] 1] != 1} {
    	return 0
    }
    coverage-process $sym [index $data 1]
    return 0
}]    

##############################################################################
#				coverage-func-callback
##############################################################################
#
# SYNOPSIS:	Callback function to print out the coverage of a function.
# PASS:		sym 	= token for profile mark symbol
#		data	= {<funcsym> <segment>}
# CALLED BY:	coverage via symbol foreach
# RETURN:	0 to keep enumerating, 1 to stop
# SIDE EFFECTS:	$state and $lastfile in coverage will be altered
#
# STRATEGY  	Slightly different from coverage-res-callback, this one
#		ignores profile markers that come before the indicated function
#		and stops once it sees a marker that is after the function
#		but falls within another function.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	9/17/93		Initial Revision
#
##############################################################################
[defsubr coverage-func-callback {sym data}
{
    #
    # Make sure marker is for basic-block analysis
    #
    if {[index [symbol get $sym] 1] != 1} {
    	return 0
    }
    var fsym [index $data 0] seg [index $data 1] paddr [symbol addr $sym]
    if {$paddr >= [symbol addr $fsym]} {
    	#
	# Might be inside the desired function. See in what function it actually
	# falls.
	#
    	var nfsym [symbol faddr proc $seg:$paddr]
    	if {$nfsym != $fsym} {
	    #
	    # Different from desired, so we must be done. Close off the final
	    # range, though.
	    #
    	    coverage-process-low $sym $seg [symbol addr $nfsym] {NOT HIT}   	    
	    return 1
    	}
    	coverage-process $sym $seg
    }
    return 0
}]

##############################################################################
#				coverage-process
##############################################################################
#
# SYNOPSIS:	Common code to remember the file and line number of this
#		profile marker, and possibly print out the current range if
#		its state (executed/not executed) is different from that of
#		this marker.
# PASS:		sym 	= token for profile mark symbol
#		seg 	= segment in which the mark lies
# CALLED BY:	coverage-res-callback, coverage-func-callback
# RETURN:	nothing
# SIDE EFFECTS:	$state and $lastfile in coverage will be altered
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	9/17/93		Initial Revision
#
##############################################################################
[defsubr coverage-process {sym seg}
{
    #
    # Fetch the byte from the marker. This is the ModRM byte for either a
    # mov ax, ax or mov cx, cx instruction. In the latter case, the code
    # has been executed.
    #
    var paddr [symbol addr $sym]
    if {[value fetch $seg:$paddr byte] == 0xc0} {
	var pstate {NOT HIT}
    } else {
	var pstate hit
    }

    coverage-process-low $sym $seg $paddr $pstate
}]

##############################################################################
#				coverage-process-low
##############################################################################
#
# SYNOPSIS:	Do the grunt-work of keeping track of a range that's been
#		covered, printing things out when the state changes.
# PASS:		sym 	= token for profile mark symbol
#		seg 	= segment in which the mark lies
#		paddr	= address of profile mark (used to get file & line
#			  number of the mark)
#   	    	pstate	= "hit" or "NOT HIT"
# CALLED BY:	coverage-process, coverage-func-callback
# RETURN:	nothing
# SIDE EFFECTS:	$state and $lastfile in coverage will be altered
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	9/17/93		Initial Revision
#
##############################################################################
[defsubr coverage-process-low {sym seg paddr pstate}
{
    #
    # Get the file & line of the marker.
    #
    var fl [src line $seg:$paddr]
    var file [index $fl 0] line [index $fl 1]
    #
    # Fetch $state from coverage
    #
    var state [uplevel coverage var state]

    if {[null $state]} {
    	#
	# This is the first time through, so create the 5-list we like
	# to manipulate
	#
	uplevel coverage var state [list $pstate $file $line $line $seg]
    } elif {[index $state 0] == $pstate && [index $state 1] == $file} {
    	#
	# Same state and file as the last marker, so just adjust the ending line
	# in the 5-list
	#
	uplevel coverage aset state 3 $line
    } else {
    	#
	# Print out the previous range, ending it with the line before this 
	# marker, if appropriate.
	#
	if {$paddr != 0 && [catch {src line $seg:$paddr-1} fl] == 0} {
	    aset state 3 [index $fl 1]
    	}
	coverage-print-line $state
	#
	# Set the new single-line state for this marker.
	#
	uplevel coverage var state [list $pstate $file $line $line $seg]
    }
}]

##############################################################################
#				coverage-print-line
##############################################################################
#
# SYNOPSIS:	Spew a line range according to the current mode and the range's
#   	    	state
# PASS:		state	= {(hit|NOT HIT) <file> <start> <end>}
# CALLED BY:	coverage-process-low, coverage
# RETURN:	nothing
# SIDE EFFECTS:	$lastfile in coverage may be altered
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	9/17/93		Initial Revision
#
##############################################################################
[defsubr coverage-print-line {state}
{
    #
    # Update the covered/uncovered code
    #
    if {[uplevel coverage var percentage]} {

    	#
	# Compute the size of this hunk
	#
	var file  [index $state 1]
	var s     [index $state 2]
	var e     [index $state 3]

	var start [index [src addr $file $s] 1]
	var end   [index [src addr $file $e] 1]

	if {![null $start] && ![null $end]} {
	    if {[index $state 0] == hit} {
		#
		# Update the covered code total.
		#
		var cc    [uplevel coverage var coveredCode]
		uplevel coverage var coveredCode [expr $cc+$end-$start]
	    } else {
		#
		# Update the uncovered code total.
		#
		var uc [uplevel coverage var uncoveredCode]
		uplevel coverage var uncoveredCode [expr $uc+$end-$start]
	    }
    	} else {
	    echo {*** Warning: profiling information appears corrupted for:}
	    echo [format {  %s: %d-%d} $file $s $e]
	}
    }

    #
    # Generate appropriate output
    #
    if {[uplevel coverage var mode] == source} {
    	#
	# Spew forth source lines. Lines that haven't been executed are
	# preceded by a >
	#
	if {[index $state 0] == hit} {
	    var prefix {  }
	} else {
	    var prefix {> }
	}
	#
    	# Read all the lines of the range and print them out, preceded by
	# the appropriate character.
	#
	[for {var i [index $state 2]}
	     {$i <= [index $state 3]}
	     {var i [expr $i+1]}
	{
	    var l [src read [index $state 1] $i]
	    echo [format {%s%.77s} $prefix $l]
	}]
    } else {
    	#
	# If different file from previous range, put out the filename too
	#
    	if {[index $state 1] != [uplevel coverage var lastfile]} {
	    echo File [index $state 1]:
	    echo [format {%-20s State} {Line(s)}]
	    echo [format {%-20s -----} {-------}]
	    uplevel coverage var lastfile [index $state 1]
    	}

    	#
	# Print out the range of lines. If the start & end are the same, print
	# just the line number...
	#
	if {[index $state 2] == [index $state 3]} {
	    echo [format {%-20s %s} [index $state 2] [index $state 0]]
	} else {
	    echo [format {%-20s %s} 
		  [format {%d - %d} [index $state 2] [index $state 3]]
		  [index $state 0]]
	}
    }
}]

[defcommand tcov {cmd args} profile
{Usage:
    tcov set <proc>
    tcov reset <proc>
    tcov print [-s] <proc>
    tcov clear <proc>

Examples:
    "tcov set AllocateHandleAndBytes"	Begin coverage analysis of
					AllocateHandleAndBytes
    "tcov reset InnerLoop"  	    	Reset the coverage counters for
					InnerLoop
    "tcov print -s InnerLoop"	    	Print the coverage counts for
					all the source lines of InnerLoop

Synopsis:
    Uses the "tbrk" command to perform basic-block profiling of one or
    more procedures.

Notes:
    * The "-s" flag to "tcov print" says to print out the source code of the
      function. Each line will be hold the number of times the source line was
      executed, followed by as much of the source line as will fit.

    * You can use the "reset" subcommand to reset the counts for the various
      breakpoints, allowing you to determine coverage for various sets
      of operations.

See also:
    coverage, tbrk.
}
{
    global tcov_procs
    if {[null $tcov_procs]} {
        var tcov_procs [table create]
    }
    
    [case $cmd in
     {init set} {
     	var s [symbol find proc [index $args 0]]
     	var e [table lookup $tcov_procs [symbol fullname $s 1]]
	if {![null $e]} {
	    eval [concat {tbrk clear} [index $e 0]]
	    table remove $tcov_procs [symbol fullname $s 1]
    	}
     	var e [tcov-init [index $args 0]]
	table enter $tcov_procs [symbol fullname $s 1] $e
     }
     reset {
     	var s [symbol find proc [index $args 0]]
     	var e [table lookup $tcov_procs [symbol fullname $s 1]]
	if {[null $e]} {
	    error [format {%s not being checked for coverage} [index $args 0]]
    	}
	eval [concat {tbrk reset} [index $e 0]]
     }
     {clear del} {
     	var s [symbol find proc [index $args 0]]
     	var e [table lookup $tcov_procs [symbol fullname $s 1]]
	if {[null $e]} {
	    error [format {%s not being checked for coverage} [index $args 0]]
    	}
	eval [concat {tbrk clear} [index $e 0]]
	table remove $tcov_procs [symbol fullname $s 1]
     }
     {print list} {
     	var mode lines
     	while {[string match [index $args 0] -*]} {
	    [case [index $args 0] in
	    	-s {var mode source}
		default {error [format {tcov print: %s: unknown flag} 
				       [index $args 0]]}
    	    ]
	    var args [cdr $args]
    	}
	var s [symbol find proc [index $args 0]]
	var e [table lookup $tcov_procs [symbol fullname $s 1]]
	foreach b [index $e 0] {
	    var addr [tbrk address $b]
	    var sl [src line $addr]

	    if {[null $start]} {
		var file [index $sl 0]
		if {$mode == lines} {
		    echo File ${file}:
    	    	}
		var start [index $sl 1]
		var count [tbrk count $b]
    	    } else {
	    	var end [expr [index $sl 1]-1]
		tcov-print-range $start $end $mode $count $file
		var count [tbrk count $b]
		var start [expr $end+1]
    	    }
    	}
	var sl [src line [symbol fullname [symbol scope $s]]:[index $e 1]]
	if {[index $sl 0] == $file} {
	    var end [expr [index $sl 1]-1]
    	} else {
	    var end [src size $file]
    	}
	tcov-print-range $start $end $mode $count $file
		    
     }
     default {
     	error [format {tcov: %s: unknown subcommand} $cmd]
     }
    ]
	
}]

##############################################################################
#				tcov-print-range
##############################################################################
#
# SYNOPSIS:	Display a range of lines covered by a single tbrk
# PASS:		start	= starting line number
#		end 	= ending line number (inclusive)
#		mode	= "lines" if display numbers, "source" if displaying
#			  source code
#   	    	count	= number of times the block was hit
#   	    	file	= source file from which they came
# CALLED BY:	tcov
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	10/ 5/93	Initial Revision
#
##############################################################################
[defsubr tcov-print-range {start end mode count file}
{
    if {$mode == lines} {
	if {$start == $end} {
	    echo [format {%-20s %s} $start $count]
	} else {
	    echo [format {%-20s %s}
		  [format {%d - %d} $start $end] $count]
	}
    } else {
    	for {var l $start} {$l <= $end} {var l [expr $l+1]} {
	    var line [src read $file $l]
	    echo [format {%5d %.73s} $count $line]
    	}
    }
}]

##############################################################################
#				tcov-init
##############################################################################
#
# SYNOPSIS:	Set tbrks at the start of every basic block within the given
#   	    	procedure
# PASS:		proc	= name of the procedure
# CALLED BY:	tcov
# RETURN:	{<list-of-tbrks> <end-proc-offset>}
# SIDE EFFECTS:	just the setting of the breakpoints
#
# STRATEGY
#   	Start from the beginning and fetch 16 bytes (the longest a 486
#	instruction can be, I believe) at a time, passing them to the marvelous
#	find-opcode instruction. It will return us the instruction decoded from
#	those bytes, along with lots of info about the instruction, to wit:
#        {name length branch-type args modrm bRead bWritten inst}
#       branch-type is one of:
#       
#              1       none (flow passes to next instruction)
#              j       absolute jump
#              b       pc-relative jump (branch)
#              r       near return              
#              R       far return 
#              i       interrupt return
#              I       interrupt instruction
#   	A basic block begins following any instruction that might send control
#	someplace else, so we're looking for instructions whose branch-type
#	isn't 1. We set a tbrk at the next instruction.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	10/ 5/93	Initial Revision
#
##############################################################################
[defsubr tcov-init {proc}
{
    protect {
    	#
	# Create a type to allow us to fetch 16 bytes at once.
	#
    	var t [type make array 16 [type byte]]
    	#
	# Initialize the list of tbrks for this function.
	#
	var tbrks {}
    	#
	# Always want a breakpoint at the start of the function...
	#
	var start 1
    	#
	# Locate the function's symbol, both for return and for easy comparison
	# within the loop.
	#
	var s [symbol find proc $proc]
	if {[null $s]} {
	    error [format {%s is not a defined procedure} $proc]
    	}
    	#
	# Determine a reasonable segment and offset to use in the loop, 
	# employing ^h<hid> for the segment, for maximum efficiency.
	#
	var h [handle find [symbol fullname [symbol scope $s]]:0]
	var seg ^h[handle id $h]
	var off [index [symbol get $s] 0]
	#
	# Loop through all the instructions in the function, stopping when
	# the current address maps to some other function...
	#
	while {[symbol faddr proc $seg:$off] == $s} {
    	    #
	    # If previous instruction was a break in control flow, set
	    # a tbrk at this one.
	    #
	    if {$start} {
	    	var tbrks [concat $tbrks [list [tbrk $seg:$off]]]
		var start 0
    	    }
	    #
	    # Fetch the next 16 bytes and decode them.
	    #
	    var b [value fetch $seg:$off $t]
	    var op [eval [concat [list find-opcode $seg:$off] $b]]
    	    #
	    # If this instruction doesn't just advance to the next one,
	    # set the flag to set a breakpoint at the next one.
	    #
	    if {[index $op 2] != 1} {
	    	var start 1
    	    }
	    #
	    # Advance to the next instruction.
	    #
	    var off [expr $off+[index $op 1]]
    	}
    } {
    	#
	# Nuke the type description we created.
	#
    	if {![null $t]} {
	    type delete $t
    	}
    }
    return [list $tbrks $off]
}]
