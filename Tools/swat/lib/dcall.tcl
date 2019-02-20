#
#	dcall is a command that displays calls to routines
#
#	$Id: dcall.tcl,v 3.0 90/02/04 23:46:04 adam Exp $
#
defvar dc_list {}

[defcommand dcall {args} profile
{dcall displays calls to a given routine.  Invoking dcall with no arguments
causes dcall to be disabled.
	Usage: dcall <routineName>
}
{
	global	dc_list

    if {[null $args]} {
	foreach i $dc_list {
	    brk del $i
	}
	var dc_list {}
    } else {
# later -- handle other args here
	var tempb [brk aset $name [format {[echo %s] [expr 0]}
					   [index $args 0]]]
	var dc_list [concat $dc_list $tempb]
    }
}]
