#
#	dcall is a command that displays calls to routines
#
#	$Id: dcall.tcl,v 3.7.6.1 97/03/29 11:28:12 canavese Exp $
#
defvar dc_list {}

[defcmd dcall {args} profile
{Usage:
    dcall [<args>]

Examples:
    "dcall Dispatch"	Display when the routine Dispatch is called
    "dcall none"    	stop displaying all routines

Synopsis:
    Display calls to a routine and the thread calling it.

Notes:
    * The args argument normally is the name of the routine to monitor.
      Whenever a call is made to the routine it's name is displayed.

      If 'none' or no argument is passed, then all the routines will
      stop displaying.

    * Dcall uses breakpoints to display routine names.  By looking at 
      the list of breakpoints you can see which routines display their
      names and you can stop them individually by disabling or deleting
      them.

See also:
    showcalls, mwatch.
}
{
	global	dc_list

    if {[string c $args none] == 0 || [null $args]} {
	foreach i $dc_list {
	    catch {brk delete $i}
	}
	var dc_list {}
    } else {
    	    	
# later -- handle other args here
	#
	# It prints out thread handle as well as function name
	#
	var tempb [brk aset $args print-dcall-info]
	var dc_list [concat $dc_list $tempb]
    }
}]

##############################################################################
#	print-dcall-info
##############################################################################
#
# SYNOPSIS:	Print out the information of dcall
# PASS:		nothing
# CALLED BY:	breakpoint module set by dcall
# RETURN:	TCL_OK (continue the machine)
# SIDE EFFECTS:	none
#
# STRATEGY:
#       Echo the thread and followed by the function of top frame.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       simon 	8/ 6/95   	Initial Revision
#
##############################################################################
[defsubr    print-dcall-info {} {
    echo -n {CALL: } 

    # Display the backtrace
    var cur_frame [frame cur]
    echo -n [frame function $cur_frame]
    
    # Display thread name
    echo [format { (%s)} [threadname [value fetch ss:TPD_threadHandle]]]
    
    #
    # In the future, it can be enhanced to print out backtrace
    # with a specified number of frames.
    #
    return TCL_OK
}]
