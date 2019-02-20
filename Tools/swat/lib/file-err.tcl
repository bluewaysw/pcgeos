##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat System Library -- File module error handling
# FILE: 	file-err.tcl
# AUTHOR: 	Adam de Boor, Aug 14, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	file-err    	    	Locates a file
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	8/14/89		Initial Revision
#
# DESCRIPTION:
#	Routines for use by the File module when searching for a patient.
#
#	$Id: file-err.tcl,v 3.1 90/10/03 21:59:29 adam Exp $
#
###############################################################################

#
# Set up the initial load-path variable inside a subroutine to avoid leaving
# extra variables lying around. Makes sure the lib directory appears at the
# end of the path.
#
[defsubr setup-load-path {}
{
    global load-path devel-directory file-system-library file-root

    var lp [getenv SWATPATH] load-path {}

    for {} {![null $lp]} {} {
    	var colon [string first : $lp]
	if {$colon < 0} {
	    var load-path [concat ${load-path} [file $lp expand]]
	    break
	} else {
	    var load-path [concat ${load-path} 
				  [file [range $lp 0 [expr $colon-1] chars]
					expand]]
	    var lp [range $lp [expr $colon+1] end chars]
	}
    }
    if {[string match ${file-system-library} /*]} {
    	var load-path [concat ${load-path} ${file-system-library}
    } elif {[null ${devel-directory}]} {
	var load-path [concat ${load-path} ${file-root}/${file-system-library}]
    } else {
    	var load-path [concat ${load-path}
			      ${devel-directory}/${file-system-library}
			      ${file-root}/${file-system-library}]
    }
}]
setup-load-path

#
# Error-handling routine for File module when a patient's executable cannot
# be located. Prompts for the location, with file-name completion, and
# returns either the name of an existing file or the null string, if the
# user has requested we ignore the thing.
#
[defsubr file-err {patient maydetach mayignore}
{
    require top-level-read top-level
    global init-directory

    # Figure the name of the patient w/o the extension or trailing spaces
    var pname [index [range $patient 0 7 char] 0]

    # If the patient is listed in the "SWATIGNORE" envariable, ignore it,
    # since we can't seem to locate it.
    foreach i [getenv SWATIGNORE] {
	if {[string c $i $pname] == 0} {
	    return {}
	}
    }

    echo Can't find executable file for "$patient" (version mismatch?)
    echo Answer "quit" to exit to the shell
    if {$maydetach} {echo Answer "detach" to detach and return to top level}
    if {$mayignore} {echo Answer "ignore" to ignore this patient}
    
    for {} {1} {} {
    	var file [top-level-read {Where is it? } ${init-directory}/ 0]

    	#
	# Handle lazy initial-value override, looking for any double slash,
	# which indicates a switch to a different absolute path, or a /~,
    	# which indicates a switch to someone's home directory. $i is left
	# holding the index of the first character to use in $file, defaulting
	# to 0 if neither // nor /~ is present.
	#
    	var // [string last // $file] /~ [string last /~ $file] i 0
    	if {${//} >= 0} {
	    if {${//} > ${/~}} {
	    	var i ${//}
	    } else {
	    	var i ${/~}
	    }
	} elif {${/~} >= 0} {
	    var i ${/~}
	}
	
    	#
	# Deal with any home-directory specs in the file as well as trimming the
	# file as indicated by the above checks.
	#
    	var file [file [range $file $i end char] expand]

    	#
	# See if the line given is one of the special commands we accept
	#
    	var check {}
    	[case [index $file 0] in
    	 q* {var check quit}
	 d* {var check detach}
	 i* {var check ignore}]

	if {![null $check]} {
    	    #
	    # Restrict the special command to the length of the first element
	    # of the input line (which should be the command).
	    #
	    var check [range $check 0
	    	    	     [expr [length [index $file 0] char]-1] char]
    	    #
	    # Make sure the first element matches the command in all its
	    # particulars.
	    #
	    if {[string c $check [index $file 0]] == 0} {
    	    	#
		# Is a special command -- perform the appropriate action.
		#   quit    	just eval the command -- we'll exit stage left
		#   detach  	eval the command and return to top level
		#   ignore  	just return empty -- caller should expect
		#   	    	that as a signal to return empty.
    	    	#
    	    	[case $check in
		 q* {eval [concat quit [range $file 1 end]]}
		 d* {
		    if {$maydetach} {
    	    	    	eval [concat detach [range $file 1 end]]
			return {}
		    } else {
		    	echo Detaching not allowed.
			continue
	    	    }
    	    	 }
		 i* {
		    if {$mayignore} {
		    	return {}
		    } else {
		    	echo Ignoring this patient is not allowed.
			continue
		    }
		 }]
    	    }
	}	 
	#
	# Check for the existence of the file -- the caller will have to
	# figure out about serial numbers and whatnot.
	#
    	if {[string match $file /*]} {
	    if {[file $file readable]} {
	    	return $file
	    }
    	} elif {[file ${init-directory}/${file} readable]} {
	    #
	    # Given relative to initial directory
	    #
	    return ${init-directory}/${file}
	}
	echo $file not readable. Try again.
    }
}]
