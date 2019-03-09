######################################################################
#
#	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# This file contains commands to access the on-line PC GEOS glossary,
# look up the procedure header of a function and examine the cross-
# reference listing produced by...someone.
#
#	$Id: gloss.tcl,v 3.1 90/04/28 21:35:35 adam Exp $
#
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


[defcommand gloss {args} reference
{'gloss regexp' prints out the glossary definition of 'regexp', which is a
regular expression (or just a word) that is given to SED.}
{
    global glossSedScript
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
    	/%s/bfound
    \}
    /^COMMENT.*-----/,/^FUNCTION:/\{
    	/^FUNCTION.*%s[ \t]*$/\{
	    s/FUNCTION:/	/
	    a\\
==============================================================================
	    bfound
	\}
    \}
    /^COMMENT.*-----/,/^METHOD:/\{
    	/^METHOD.*%s[ \t]*$/\{
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
    
[defcommand ref {{target nil}} reference
{'ref routineName' prints out the routine header for a function. If no function
is given, the function active in the current stack frame is used. This command
locates the function using a tags file, so that tags file should be kept
up-to-date}
{
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
[defcommand xref {{target nil}} reference
{'xref routineName' prints out a cross reference for the given kernel function.
If no function is given, the function active in the current frame is used.}
{
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
