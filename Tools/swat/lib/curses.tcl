##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	curses.tcl
# FILE: 	curses.tcl
# AUTHOR: 	Adam de Boor, Jan 11, 1990
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	display	    	    	Open another window on the screen to execute
#   	    	    	    	a command every time the machine stops
#   	regwin	    	    	Front-end for display to show the current
#   	    	    	    	registers.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	1/11/90		Initial Revision
#
# DESCRIPTION:
#	Window-system specific functions for operating under Curses.
#
#	$Id: curses.tcl,v 3.0 90/02/04 23:35:40 adam Exp $
#
###############################################################################
defvar _displays {}
defvar _next_display 1

[defsubr _display_catch {why val}
{
    #XXX: still window of vulnerability between protect and wpush...
    protect {
	wpush [index $val 1]
	wclear
	var code [catch {eval [index $val 2]} result]
	#
	# Echo any result (makes life easier).
	#
	if {$code == 0 && ![null $result]} {
	    echo $result
	}
    } {
    	wrefresh
    	wpop
    }
    #
    # Clear out the repeatCommand just in case...
    #
    global repeatCommand
    var repeatCommand {}
    if {$code} {
    	error $result
    } else {
    	return EVENT_HANDLED
    }
}]

[defcommand display {maxLines args} window
{Creates a window MAXLINES high for executing the given command each time
the machine halts. First arg may also be "list", in which case all active
displays are listed, or "del", in which case the given display is deleted (the
display may be given by number or by the token returned when the display was
created). The command to execute for the display must be given as a single
argument.}
{
    global _displays _next_display

    if {[string m $maxLines {l*}]} {
    	foreach i $_displays {
    	    echo [format {%2d: %s} [index $i 0] [index $i 2]]
    	}
    } elif {[string m $maxLines {d*}]} {
    	foreach which $args {
	    if {[scan $which {disp%d} dnum] != 1}  {
		var dnum $which
	    }
	    var i 0 nd [length $_displays]
	    foreach el $_displays {
		if {$dnum == [index $el 0]} {
		    var dlist $el
		    break
		}
		var i [expr $i+1]
	    }
	    if {$i == $nd} {
		error [format {%s: no such display active} $which]
	    }
	    event delete [index $dlist 3]
	    wdelete [index $dlist 1]
	    if {$i == 0} {
		var _displays [range $_displays 1 end]
	    } elif {$i == $nd-1} {
		var _displays [range $_displays 0 [expr $i-1]]
	    } else {
		var _displays [concat [range $_displays 0 [expr $i-1]]
				      [range $_displays [expr $i+1] end]]
	    }
    	}
    } else {
    	# Open the window
    	var win [wcreate $maxLines]
    	#
    	# Form the display record from the _next_display number, the window
	# and the first argument (the command to execute)
    	#
	var dis [list $_next_display $win [index $args 0]]
    	#
	# Register interest in FULLSTOP events to call _display_catch with
	# the above list as its argument
	#
	var ev [event handle FULLSTOP _display_catch $dis]
    	#
	# Tack it onto the end, placing the event handle on the end so we
	# can nuke it when the display goes away.
	#
	var _displays [concat $_displays [list [concat $dis $ev]]]
    	#
	# Up the display counter
	#
	var _next_display [expr $_next_display+1]
    	#
	# Take care of initial display...
	#
    	catch {_display_catch {Because} $dis} foo
    	#
	# Clear out the repeatCommand just in case...
	#
	global repeatCommand
	var repeatCommand {}
    	#
	# Return the token to the user
	#
    	return [format {disp%d} [expr $_next_display-1]]
    }
}]
    	
##############################################################################
#                                                                            #
#   	    	    	    REGISTER DISPLAY	    	    	    	     #
#									     #
##############################################################################
defvar _lastRegs nil
[defsubr _display_regs {}
{
    global  _lastRegs regnums
    var	    regs [current-registers]

    if {[null $_lastRegs]} {
    	var _lastRegs $regs
    }
    foreach i {{CS 9} {AX 0} {BX 3} {CX 1} {DX 2} {SP 4} {SS 10} {DS 11} {ES 8}} {
	var idx [index $i 1]
	var r1 [index $regs $idx] r2 [index $_lastRegs $idx]

	if {$r1 != $r2} {
	    winverse 1
	    echo -n [format {%-3s%04x} [index $i 0] $r1]
	    winverse 0
	} else {
	    echo -n [format {%-3s%04x} [index $i 0] $r1]
	}
	echo -n {  }
    }
    wmove 0 1
    var ip [index $regs 12] fs [frame funcsym [frame top]]
    if {![null $fs]} {
    	var fa [symbol addr $fs]
    	if {$fa == $ip} {
	    var sa [symbol fullname $fs]
	} else {
	    var sa [format {%s+%d} [symbol fullname $fs] [expr $ip-$fa]]
    	}
    } else {
    	var sa {}
    }
    var sl [length $sa chars]
    if {$sl >= 45} {
    	echo -n [format {IP %04x  <%s } $ip [range $sa [expr $sl-43] end char]]
    } else {
    	echo -n [format {IP %04x  %-45s} $ip $sa]
    }
    foreach i {{BP 5} {SI 6} {DI 7}} {
	var idx [index $i 1]
	var r1 [index $regs $idx] r2 [index $_lastRegs $idx]

	if {$r1 != $r2} {
	    winverse 1
	    echo -n [format {%-3s%04x} [index $i 0] $r1]
	    winverse 0
	} else {
	    echo -n [format {%-3s%04x} [index $i 0] $r1]
	}
	echo -n {  }
    }
    var _lastRegs $regs
}]
    	    
[defdsubr regwin {} window
{Turns on continuous display of registers}
{
    global regwindisp
    var regwindisp [display 2 _display_regs]
    return $regwindisp
}]

