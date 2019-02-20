##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
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
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/13/89		Initial Revision
#
# DESCRIPTION:
#	
#
#	$Id: unix.tcl,v 3.2 90/02/24 19:08:17 adam Exp $
#
###############################################################################
#
# edit the current file or the one given as the first argument.
#
[defcommand vi {args} top
{Invoke "vi" using the given arguments. If none given, and the source file
in which the patient is executing is known, edit that file. If the source file
isn't known, does a "vi -t <function-name>" where <function-name> is the name
of the function in the current frame.}
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

[defcommand ls {args} misc
{List the current directory. -C flag automatically passed (otherwise the output
wouldn't be in columns). Other flags you have to give yourself.}
{
    return [eval [concat {exec ls -C } $args]]
}]

[defcommand pmake {args} misc
{Recompile the current patient. Doesn't download the thing, though}
{
    return [system [concat cd [file [patient path] dirname]; pmake $args]]
}]

[defdsubr vif {{func nil}} misc
{VI the given function.}
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
