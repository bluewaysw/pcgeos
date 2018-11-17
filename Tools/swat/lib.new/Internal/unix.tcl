##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	SWAT -- System library
# FILE: 	unix.tcl
# AUTHOR: 	Adam de Boor, Mar 13, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	vi  	    	    	Edit source files
#   	pmake	    	    	Recreate the current patient
#   	ls  	    	    	List the current directory
#   	vif 	    	    	VI a particular function
#   	which	    	    	Display version of an exectuable in UNIX
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/13/89		Initial Revision
#
# DESCRIPTION:
#	
#
#	$Id: unix.tcl,v 3.11.12.1 97/03/29 11:25:14 canavese Exp $
#
###############################################################################
#
# edit the current file or the one given as the first argument.
#
[defcmd vi {args} support.unix.editor
{Usage:
    vi [<args>]

Examples:
    "vi"    	    	start vi with the source file the patient is using
    "vi -t MyFunc"  	start vi at the function MyFunc

Synopsis:
    Invoke "vi" with the specified arguments.

Notes:
    * The args arguments are all passed to vi.  If none are given then
      vi starts with the source file that the patient is executing.
      If the source file is unknown, then a tags is tried on the
      function currently executing.

See also:
    vif.
}
{
    if {[length $args] != 0} {
	return [system [concat vi $args]]
    } else {
	[if {[catch {src line [frame register pc]} fileLine]==0 &&
	    ![null $fileLine]}
    	{
	    return [system [concat vi +[index $fileLine 1] [index $fileLine 0]]]
	} else {
    	    var fs [frame funcsym [frame cur]]
    	    if {![null $fs]} {
    	    	var fd [symbol get $fs]
	    	if {[length $fd] == 3} {
    	    	    #
		    # We know what file the thing is in, so vi it directly
		    #
	    	    return [system [concat vi "+/^[symbol name $fs]"
		    	    	     [index $fd 2]]]
    		} else {
    	    	    return [system [concat vi -t [symbol name $fs]]]
		}
    	    } else {
	    	error {No source information for current frame}
    	    }
	}]
    }
}]

[defcmd ls {args} support.unix
{Usage:
    ls [<args>]

Examples:
    "ls"    	    list the current directory.
    "ls -l" 	    list the current directory in the long format.

Synopsis:
    List the current Unix directory.

Notes:
    * The args arguments are all passed as is to the 'ls' command.

    * The '-C' flag is automatically passed (otherwise the output
      wouldn't be in columns).
}
{
    return [eval [concat {exec ls -C } $args]]
}]

[defcmd pmake {args} support.unix
{Usage:
    pmake [<args>]

Examples:
    "pmake" 	    recompile the current patient.

Synopsis:
    Recompile the current patient.

Notes:
    * The args arguments are all passed to pmake as is.

    * This works by changing the directory to where the patient's file
      is kept.

    * This doesn't download the recompiled patient.
}
{
    var path [file dirname [patient path]]
    if {[string first Installed $path] != -1} {
    	echo {Cannot remake patients in the Installed tree}
    } else {
    	return [system [concat cd $path; pmake $args]]
    }
}]

[defcommand vif {{func nil}} support.unix.editor
{Usage:
    vif [<function name>]

Examples:
    vif"    	    start vi with the current function.
    "vif MyFunc"    start vi with the function 'MyFunc'.

Synopsis:
    Start vi with a function loaded.

Notes:
    * The function name argument is the name of a function which is 
      kept in a tags file.  If none is specified then the current
      function is used.

See also:
    vi.
}
{
    if {[null $func]} {
	var func [func]
    }
    var fs [sym find func $func]
    if {[null $fs]} {
	error [concat Function $func undefined]
    }
    [if {[catch {src line [sym fullname $fs]} fileLine] == 0 &&
    	 ![null $fileLine]}
    {
    	return [system [format {vi +%d %s} [index $fileLine 1]
	    	    	    [index $fileLine 0]]]
    } else {
    	return [system [format {vi -t %s} [sym name $fs]]]
    }]
}]

##############################################################################
#				which
##############################################################################
#
# SYNOPSIS:	Display which version of a geode is in use
# PASS:		gname	= (optional) permanent name of geode
#   	    	-d	= (optional) display date/time stamp
# CALLED BY:	user
# RETURN:	none
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	2/24/91		Initial Revision
#
##############################################################################
[defcommand which {args} support.unix
{Usage:
    which [-d] [<gname>]

Examples:
    "which" 	    	    display version of current geode
    "which geocalc" 	    display version of geocalc
    "which -d geos" 	    display version and date/time of kernel

Synopsis:
    Display which version of a geode is in use.

Notes:
    * If no geode name is specified, the current geode is used.

    * The '-d' flag displays the UNIX date/time stampe of the geode in
    addition to the path of the geode.
}
{
    #
    # Parse the flags
    #
    var date 0

    if {[length $args] > 0 && [string m [index $args 0] -*]} {
	#
	# Examine the flags word for things we know and set vars
	# accordingly.
	#
	foreach i [explode [range [index $args 0] 1 end chars]] {
	    [case $i in
		d {var date 1}
		l {var date 1}
		default {error [format {unknown option %s} $i]}
	    ]
	}
	#
	# Shift the first arg off the list
	#
	var args [range $args 1 end]
    }
    #
    # If there are no args left, get the current geode name
    #
    if {[length $args] > 0} {
    	var gname $args
    } else {
    	var gname [patient name]
    }
    #
    # Do the right thing
    #
    if {$date == 0} {
    	echo [patient path [patient find $gname]]
    } else {
    	echo [ls -l [patient path [patient find $gname]]]
    }
}]
