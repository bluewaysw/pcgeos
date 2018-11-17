##############################################################################
#
# 	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System library.
# FILE: 	ref.tcl
# AUTHOR: 	Roger
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	inst	    	    	give info on instructions
#   	ascii	    	    	show the file 'ascii'
#	gloss			give a glossary definition
#	ref			print the function's header
#	xref			print a cross reference for a kernel function
#
#	$Id: ref.tcl,v 1.9 97/04/29 20:13:33 dbaumann Exp $
#
###############################################################################


[defcommand inst {{name ref}} support.unix.reference
{Usage:
    inst [<arg>]

Examples:
    "inst"   	    	list all assembly instructions
    "inst lodsb"    	describe the lodsb instruction
    "inst ea"	    	describe effective address timings 
    "inst cond"	    	describe jumps on condition codes

Synopsis:
    Print information on an assembler instruction.

Notes:
    * This command is not supported for DOS.

    * The argument is optional and may either be an assembly
      instruction or one of the following:

	ea		display effective address (EA) timings for 8086/88
	ref	    	list all assembly instructions with a description
	cond	    	display table of conditional jump instructions

      If no argument is given inst lists all the instructions with a 
      short, one-line description.

    * Each instruction reference has three basic output fields: Flags,
      Description, Notes, and Timing.

    * The Flags field illustrates how the instruction affects
      processor's condition flags. Each of the nine flags is
      abbreviated by a single letter.

	Abbrv.	Flag
	------	---------------
	O	Overflow
	D	Direction
	I	Interrupt
	T	Trap
	S	Sign
	Z	Zero
	A	Auxiliary Carry
	P	Parity
	C	Carry

      The flags are displayed horizontally with a code below each.

	Flags:	O D I T S Z A P C
		1 - - ? ? x ? x 0

      The flag codes have the following meanings:

	Code	Meaning
	------	-----------------------------------------------------
	-	unchanged by instruction
	x	changed predictably by instruction
	1	forced to 1 by instruction
	0	forced to 0 by instruction	
 	?	undefined or unpredictably altered by instruction

    * The Description field follows the Flags field and describes the
      purpose and usage of the instruction. Sometimes optional
      fields, such as Notes and See also, provide additional
      information and cross references.

    * The Timing field provides processor clock cycle data for the
      instruction. The timings assume a full prefetch queue.

}
{
    global file-syslib-dir file-os
    var nl [length $name chars]

    if {[string c ${file-os} unix] != 0} {
    	error {The "inst" command is supported only for UNIX, not for DOS.}
    }

    #upcase the name
    for {var i 0} {$i < $nl} {var i [expr $i+1]} {
	scan [index $name $i chars] %c c

	#96 == 'a'-1, 123 == 'z'+1
	if {$c > 96 && $c < 123} {
	    var c [expr $c-32]
	}
	var inst [format {%s%c} $inst $c]
    }
       
    var string 0

    #convert all string forms to their root, noting we're dealing with
    #a string instruction.
    [case $inst in
    	CMPS* {var inst CMPS string 1 suff W}
	INS*  {var inst INS string 1 suff W}
	LODS* {var inst LODS string 1 suff W}
	MOVS* {var inst MOVS string 1 suff W}
	OUTS* {var inst OUTS string 1 suff W}
	SCAS* {var inst SCAS string 1 suff W}
	STOS* {var inst STOS string 1 suff W}
	XLAT* {var inst XLAT string 1 suff B}]

    var desc [exec sed -n -e
	      [format {
		/^[^ \t=]/,/^===/{
		    /^[^ \t=]/,/^[ \t]*$/{
			/^%s[ \t]/bgotit
			/^%s$/bgotit
			:loop
			N
			/\\n%s[ \t]/bgotit
			/\\n%s$/bgotit
			/\\n[ \t]*$/bnope
			bloop
		    }
		    :nope
		    n
		    /^===/!bnope
		    d
		    :gotit
		    p
		    n
		    /^===/!bgotit
		    d
		}} $inst $inst $inst $inst]
	    ${file-syslib-dir}/ref.80x8x]
		    
    if {[string c $desc {}] == 0} {
    	error [format {%s not listed} $name]
    } else {
    	echo -n $desc

    	#if string instruction, use word form to get all timing info
    	if {$string} {var inst ${inst}${suff}}

	if {[string c $inst [index $desc 0]] != 0} {
	    var fmt [format {
			/^\{%s[ \t]/,/^\{/{
			    /^\{%s/p
			    /^\{/!p
			}
			/^\{%s[ \t]/,/^\{/{
			    /^\{%s/p
			    /^\{/!p
			}} $inst $inst [index $desc 0] [index $desc 0]]
	} else {
	    var fmt [format {
			/^\{%s[ \t]/,/^\{/{
			    /^\{%s/p
			    /^\{/!p
			}} $inst $inst]
	}

    	var t [exec sed -n -e $fmt ${file-syslib-dir}/timing.80x8x]
	var l [index $t 0]
	if {[length $l] > 2} {
	    echo -n [format {%-16s} Timing:]
	    #if string instruction, don't use "implied"-type formatting -- need
	    #to distinguish between byte/word access
	    if {$string} {
		var itype string
	    } else {
		var itype [index $l 1]
	    }
	    [case $itype in
		repeat {}
		{implied control branch int prefix stack return muldiv} {
		    echo [format {%-16s%-10s%-10s%-10s%-10s}
				MODE 8088 8086 80286 V20]
		    foreach i [range $l 2 end] {
			echo [format {\t\t%-16s%-10s%-10s%-10s%-10s}
				[index $i 0] [index $i 2] [index $i 1]
				[index $i 3] [index $i 5]]
		    }
		}
		default {
		    echo [format {%-16s%-18s%-10s%-18s}
				MODE {8088 byte/word}
				80286 {V20 byte/word}]
		    foreach i [range $l 2 end] {
			[if {[string match [index $i 0] *mem*] &&
			     [string c [index $i 1] -] != 0 &&
			     ![string match [index $i 0] *ax*]}
    	    	    	{
			    var times [list [index $i 1]+EA/[index $i 2]+EA 
				    	[index $i 3]
					[index $i 4]/[index $i 5]]
    	    	    	} else {
			    var times [list [index $i 1]/[index $i 2]
				       [index $i 3]
				       [index $i 4]/[index $i 5]]
			}]
			echo [eval [concat
				    [list format {\t\t%-16s%-18s%-10s%-18s} 
					  [index $i 0]] 
			    	    $times]]
		    }
		}
	    ]
	}
    }
}]
	    	

[defcommand ascii {} support.unix.reference
{Usage:
    ascii

Example:
    "ascii"		show the ascii table

Synopsis:
    Display an ascii table in both decimal and hex.

Notes:
    * This command is only supported for UNIX.

See also:
    print.
}
{
    global file-syslib-dir file-os

    if {[string c ${file-os} unix] != 0} {
    	error {The "ascii" command is supported only for UNIX.}
    }

    exec cat ${file-syslib-dir}/ascii
}]

######################################################################
#
# glossSedScript is the script given to SED to locate all entries that
# match the given argument. The idea is to go forward in the file a section
# at a time (sections being delineated by blank lines) checking the line at
# the beginning of each section ONLY for the given term. %s is replaced by
# the term in the appropriate form (i.e. in {}s if the word contains spaces,
# else as given).
#
global glossSedScript
[var glossSedScript
{/^xxx START xxx$/,$\{
:foo2
/^$/\{
n
/\{%s/!bfoo1
i\\
\{

:foo3
p
n
/^$/!bfoo3
i\\
\}

bfoo2
:foo1
/^$/!\{
n
bfoo1
\}
bfoo2
\}
\}}]


[defcommand gloss {args} support.unix.reference
{
Usage:
    gloss <regexp>

Synopsis:
    Print out the glossary definition of 'regexp', which is a
    regular expression (or just a word) that is given to SED.

Notes:
    * This command is not supported for DOS.
}
{
    global glossSedScript file-os

    if {[string c ${file-os} unix] != 0} {
    	error {The "gloss" command is supported only for UNIX, not for DOS.}
    }

    if {[null $args]} {
	error {Usage: gloss <word>}
    } else {
	#
	# First find all the applicable definitions
	#
	var defs [exec sed -n -e [format $glossSedScript $args] /staff/pcgeos/Spec/glossary.doc]

	if {[null $defs]} {
	    error [format {"%s" not found} $args]
	} else {
	    #
	    # Loop through them all
	    #
	    foreach i $defs {
		#
		# Separate out the term and the aliases and see how many
		# aliases there actually are.
		#
		[var term [index [index $i 0] 0]
		     aliases [range [index $i 0] 1 end]]
		var alen [length $aliases]

		if {$alen > 0} {
		    #
		    # Actually has aliases -- print them out nicely, separated
		    # by commas, etc.
		    #
		    echo -n $term {(a.k.a. }
		    foreach j $aliases {
			if {$alen != 1} {
			    echo -n [format {%s, } $j]
			} else {
			    echo -n [format {%s)} $j]
			}
			var alen [expr $alen-1]
		    }
		} else {
		    #
		    # No aliases -- just print the term itself
		    #
		    echo -n $term
		}
		#
		# Print out the part-of-speech thing like a dictionary
		#
		echo [format {: %s.} [index $i 1]]

		#
		# If the source of the definition is given, tell the user,
		# giving the full path, just to be nice.
		#
		if {![null [index $i 2]]} {
		    echo Defined in: /staff/pcgeos/Spec/[index $i 2]
		}
		#
		# See if there are any cross-references and print them out
		# nicely (separated by commas) if there are.
		#
		var seeAlso [index $i 3]
		if {![null $seeAlso]} {
		    echo -n {See also: }
		    var alen [length $seeAlso]
		    foreach j $seeAlso {
			if {$alen != 1} {
			    echo -n [format {%s, } $j]
			} else {
			    echo $j
			}
			var alen [expr $alen-1]
		    }
		}
		#
		# Print out the actual definition, bracketed by blank lines
		#
		echo
		echo [index $i 5]
		echo
		#
		# If an example was given, print it out too
		#
		if {![null [index $i 4]]} {
		    echo Example: "[index $i 4]"
		}
		echo =============================================================================
	    }
	}
    }
}]
######################################################################
#
#	ref command
#
[defsubr extract-header {target file}
{
    #
    # Now for the fun part: look through the file with SED, dealing with the
    # two different types of procedure headers in the system. The result will
    # be the procedure header with the following things deleted:
    #	- blank lines
    #	- revision history
    #	- callers/function type (CALLED BY field)
    #	- pseudo code
    #
    var header [exec sed -n -e [format {
/^COMMENT/,/^[-%%][-%%]*[@\}]$/\{
    /^COMMENT.*%%%%/,/^[^ 	]/\{
	s/$/ /
    	/%s[ \t,]/bfound
    \}
    /^COMMENT.*-----/,/^FUNCTION:/\{
	/^FUNCTION/s/$/ /
    	/^FUNCTION.*%s[ \t,]/\{
	    s/FUNCTION:/	/
	    a\\
==============================================================================
	    bfound
	\}
    \}
    /^COMMENT.*-----/,/^METHOD:/\{
	/^METHOD/s/$/ /
    	/^METHOD.*%s[ \t,]/\{
	    s/METHOD:/	/
	    a\\
==============================================================================
	    bfound
	\}
    \}
    d
    :found
    p
    :ploop
    n
    /^%%%%*[^@\}]$/s/%%/=/g
    /^CALLED BY/,/^[A-Z]/\{
	/^CALLED/bploop
	/^[ 	]/bploop
	/^$/bploop
    \}
    /^PSEUDO/,/^[A-Z]/\{
	/^PSEUDO/bploop
	/^[ 	]/bploop
	/^$/bploop
    \}
    /^REVISION/,/^[-A-Z%%]/\{
	/^REVISION/bploop
	/^[ 	]/bploop
	/^$/bploop
    \}
    /^[-%%][-%%]*[@\}]$/!\{
    	/^[ 	]*$/bploop
	p
	bploop
    \}
    /^[-%%][-%%]*[@\}]$/q
\}} $target $target $target] $file]
    if {[null $header]} {
    	return nil
    } else {
    	return $header
    }
}]
    
[defcommand ref {{target nil}} support.unix.reference
{Usage:
    ref <routine name>

Examples:
    "ref GrCreateState"		display the header for GrCreateState

Synopsis:
    Print the header for a function.

Notes:
    * This command is not supported for DOS.

    * The routine name argument is the name of a function to print the
      header of.  If no function is given, the function active in the
      current stack frame is used.

    * This command locates the function using a tags file, so that
      tags file should be kept up-to-date

See also:
    emacs.
}
{
    global file-os

    if {[string c ${file-os} unix] != 0} {
    	error {The "ref" command is supported only for UNIX, not for DOS.}
    }
    #
    # Default to current function if none given
    #
    if {[null $target]} {
	var tsym [frame funcsym [frame cur]] target [func]
    } else {
    	var tsym [sym find func $target]
	if {[null $tsym]} {
	    error [format {"%s" not a defined function} $target]
	}
    }
    
    [if {[catch {src line [sym fullname $tsym]} fileLine] != 0 ||
    	 [null $fileLine]}
    {
    	error [format {cannot determine file for "%s"} $target]
    }]
    var header [extract-header [symbol name $tsym] [index $fileLine 0]]
    if {[null $header]} {
    	error [format {"%s" not in %s as expected} [symbol name $tsym] [index $fileLine 0]]
    } else {
    	return $header
    }
}]
######################################################################
#
#	xref command
#
[defcommand xref {{target nil}} support.unix.reference
{
Usage:
    xref <routineName>

Synopsis:
     Print out a cross reference for the given kernel function.

Notes:
    * This command is not supported for DOS.

    * If no function is given, the function active in the current frame is used.
}
{
    global file-os

    if {[string c ${file-os} unix] != 0} {
    	error {The "xref" command is supported only for UNIX, not for DOS.}
    }
    if {[null $target]} {
	var target [func]
    }
    catch {exec egrep ^$target /usr/pcgeos/Installed/Kernel/xref} foo
    if {[null  $foo]} {
	error [format {"%s" not found} $target]
    } else {
	return $foo
    }
}]
