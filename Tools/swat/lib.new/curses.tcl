##############################################################################
#
# 	Copyright (c) GeoWorks 1990 -- All Rights Reserved
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
#	$Id: curses.tcl,v 3.48 97/04/29 18:43:40 dbaumann Exp $
#
###############################################################################
#
# Table of displays. Each display is a five-list:
#	{number window-token command event-token number-of-lines}
#
# window-token is the token for the window created for the display
# command is the command to execute to refresh the display
# event-token is the token for catching the FULLSTOP event
#
# Table is keyed off display number, not token.
#

defvar curses_displays nil
require bpt-init bptutils
defvar curses_disp_token [bpt-init curses_displays disp]

[defsubr _display_catch {why val}
{
    #XXX: still window of vulnerability between protect and wpush...
    global repeatCommand
    var oldrepeat $repeatCommand
    protect {
	wpush [index $val 1]
	wclear
	var code [catch {eval [index $val 2]} result]
	#
	# Echo any result (makes life easier).
	#
	if {$code == 0 && ![null $result]} {
	    echo $result
	} elif {$code != 0} {
	    wclear
	    echo error: $result
    	}
    } {
    	wrefresh
    	wpop
    }
    #
    # Clear out the repeatCommand just in case...
    #
    var repeatCommand $oldrepeat
    if {$code} {
    	return EVENT_NOT_HANDLED
    } else {
    	return EVENT_HANDLED
    }
}]

##############################################################################
#				display-get
##############################################################################
#
# SYNOPSIS:	Fetch the description of a display, given its number or token
# PASS:		n   = the number or display token about which info is desired
# CALLED BY:	INTERNAL, mouse.tcl
# RETURN:	list of info about the display:
#	    	    {number window-token command event-token number-of-lines}
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	9/ 1/93		Initial Revision
#
##############################################################################
[defsubr display-get {n}
{
    global curses_displays curses_disp_token
    
    var n [bpt-parse-arg $n $curses_disp_token]
    if {[null $n]} {
    	error [format {%s: no such display active} $n]
    } else {
    	return [table lookup $curses_displays $n]
    }    
}]

[defcmd display {maxLines args} window
{Usage:
    display <lines> <command>
    display list
    display del <num>

Examples:
    "display list"  	list all the commands displayed
    "display 1 {pobj VCNI_viewHeight}"     always display the view height
    "display del 2" 	delete the second display command

Synopsis:
    Manipulate the display at the bottom of Swat's screen.

Notes:
    * If you give a numeric <lines> argument, the next argument, <command>, is
      a standard TCL command you would like to have executed each time the
      machine halts. The output of the command goes into a window <lines> lines
      high, usually located at the bottom of the screen.
    
    * You can list all the active displays by giving "list" instead of a number
      as the first argument.
    
    * If the first argument is "del", you can give the number of a display to
      delete as the <num> argument. <num> comes either from the value this
      command returned when the display was created, or from the list of
      active displays shown by typing "display list".

See also:
    wtop, wcreate
}
{
    global curses_displays curses_disp_token
  
    if {[string m $maxLines {l*}]} {
    	[for {var i 0}
	     {$i < [bpt-extract-max $curses_disp_token]}
	     {var i [expr $i+1]}
	{
	    var el [table lookup $curses_displays $i]
	    if {![null $el]} {
    	    	echo [format {%2d: %s} $i [index $el 2]]
    	    }
    	}]
    } elif {[string m $maxLines {d*}]} {
	global regwindisp localwindisp varwindisp varsymlist
	global srcwindisp srcwinevents

    	foreach which $args {
	    var nums [bpt-parse-arg $which $curses_disp_token]
	    if {[null $nums]} {
		error [format {%s: no such display active} $which]
    	    }
	    foreach n $nums {	    	
	    	var dlist [table lookup $curses_displays $n]
	    
	    	var dname [index $dlist 2]
	    	[case [index $dname 0] in
		 _display_regs {
		    var regwindisp {}
		 }
		 _display_regs_32 {
		    var regwindisp {}
		 }
		 locals {
		    var localwindisp {}
		 }
		 curses-show-frame {
		    framewincleanup
		 }
		 _display_source {
		    foreach e $srcwinevents {
			event delete $e
		    }
		    var srcwindisp {} srcwinevents {}
		 }
    	    	 {_display_var} {
    	    	    var varwindisp {}
		    var varsymlist {}
    	    	 }    	    	 
		]
		event delete [index $dlist 3]
		wdelete [index $dlist 1]

		table remove $curses_displays $n
		bpt-free-number $n $curses_disp_token
    	    }
    	}
    } else {
    	# Open the window
    	var win [wcreate $maxLines]
    	#
    	# Form the display record from the _next_display number, the window
	# and the first argument (the command to execute)
    	#
	var n [bpt-alloc-number $curses_disp_token]
	var dis [list $n $win [index $args 0]]
    	#
	# Register interest in FULLSTOP events to call _display_catch with
	# the above list as its argument
	#
	var ev [event handle FULLSTOP _display_catch $dis]
    	#
	# Tack it onto the end, placing the event handle on the end so we
	# can nuke it when the display goes away.
	#
    	# also add the number of lines onto the list so that things like
    	# mouse support for the PC have a hope in hell of figuring out
    	# which display was clicked in
	#
	table enter $curses_displays $n [list $n 
					      $win
					      [index $args 0]
					      $ev
					      $maxLines]
    	#
	# Take care of initial display...
	#
    	catch {_display_catch {Because} $dis} foo
    	#
	# Return the token to the user
	#
    	return disp$n
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
    global  file-os

    var	    regs [current-registers]

    if {[null $_lastRegs]} {
    	var _lastRegs $regs
    }
    foreach i {{CS 9} {AX 0} {BX 3} {CX 1} {DX 2} {SP 4} {SS 10} {DS 11} {ES 8}} {
	var idx [index $i 1]
	var r1 [index $regs $idx] r2 [index $_lastRegs $idx]

	if {$r1 != $r2} {
	    winverse 1
	    echo -n [format {%-3s%04xh} [index $i 0] $r1]
	    winverse 0
	} else {
	    echo -n [format {%-3s%04xh} [index $i 0] $r1]
	}
	echo -n { }
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
    	echo -n [format {IP %04xh <%s} $ip [range $sa [expr $sl-43] end char]]
    } else {
    	echo -n [format {IP %04xh %-44s} $ip $sa]
    }
    foreach i {{BP 5} {SI 6} {DI 7}} {
	var idx [index $i 1]
	var r1 [index $regs $idx] r2 [index $_lastRegs $idx]

	echo -n { }

	if {$r1 != $r2} {
	    winverse 1
	    echo -n [format {%-3s%04xh} [index $i 0] $r1]
	    winverse 0
	} else {
	    echo -n [format {%-3s%04xh} [index $i 0] $r1]
	}
    }
    #
    # Spew an extra newline to deal with xterm that will swallow the character
    # following the 'h' that comes after DI's value, expecting it to be a
    # newline...but only for unix, not DOS
    #
    if {[string c ${file-os} unix] == 0} {
    	echo
    }
    var _lastRegs $regs
}]
    	    
[defsubr _display_regs_32 {}
{
    global  _lastRegs regnums
    global  file-os

    var	    regs [current-registers]

    if {[null $_lastRegs]} {
    	var _lastRegs $regs
    }
    foreach i {{DS 11} {ES 8}} {
	var idx [index $i 1]
	var r1 [index $regs $idx] r2 [index $_lastRegs $idx]

	if {$r1 != $r2} {
	    winverse 1
	    echo -n [format {%-2s:%04xh} [index $i 0] $r1]
	    winverse 0
	} else {
	    echo -n [format {%-2s:%04xh} [index $i 0] $r1]
	}

	echo -n { }
    }
    echo -n {| }
    foreach i {{EAX 15} {EBX 18} {ECX 16} {EDX 17}}  {
	var idx [index $i 1]
	var r1 [index $regs $idx] r2 [index $_lastRegs $idx]

	if {$r1 != $r2} {
	    winverse 1
	    echo -n [format {%-3s:%08x} [index $i 0] $r1]
	    winverse 0
	} else {
	    echo -n [format {%-3s:%08x} [index $i 0] $r1]
	}

        echo -n { }
    }
    echo
    foreach i {{FS 23} {GS 24}} {
	var idx [index $i 1]
	var r1 [index $regs $idx] r2 [index $_lastRegs $idx]

	if {$r1 != $r2} {
	    winverse 1
	    echo -n [format {%-2s:%04xh} [index $i 0] $r1]
	    winverse 0
	} else {
	    echo -n [format {%-2s:%04xh} [index $i 0] $r1]
	}

	echo -n { }
    }
    echo -n {| }
    foreach i {{ESI 21} {EDI 22} {EBP 20} {ESP 19}}  {
	var idx [index $i 1]
	var r1 [index $regs $idx] r2 [index $_lastRegs $idx]

	if {$r1 != $r2} {
	    winverse 1
	    echo -n [format {%-3s:%08x} [index $i 0] $r1]
	    winverse 0
	} else {
	    echo -n [format {%-3s:%08x} [index $i 0] $r1]
	}

        echo -n { }
    }
    wmove 0 2
    foreach i {{SS 10} {CS 9}} {
	var idx [index $i 1]
	var r1 [index $regs $idx] r2 [index $_lastRegs $idx]

	if {$r1 != $r2} {
	    winverse 1
	    echo -n [format {%-2s:%04xh} [index $i 0] $r1]
	    winverse 0
	} else {
	    echo -n [format {%-2s:%04xh} [index $i 0] $r1]
	}
        echo -n { }
    }
    echo -n {| }
#    wmove 0 2
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
    if {$sl >= 43} {
    	echo -n [format {IP:%04xh -> <%s} $ip [range $sa [expr $sl-41] end char]]
    } else {
    	echo -n [format {IP:%04xh -> %-42s} $ip $sa]
    }
    #
    # Spew an extra newline to deal with xterm that will swallow the character
    # following the 'h' that comes after DI's value, expecting it to be a
    # newline...but only for unix, not DOS
    #
    if {[string c ${file-os} unix] == 0} {
    	echo
    }
    var _lastRegs $regs
}]

[defcommand regwin {args} top.window
{Usage:
    regwin [off]

Examples:
    "regwin"
    "regwin off"

Synopsis:
    Turn on or off the continuous display of registers.

Notes:
    * If you give the optional argument "off", you will turn off any
      active register display.

    * If you give no argument, the display will be turned on.

    * Only one register display may be active at a time.

See also:
    display, localwin, srcwin.

}
{
    global regwindisp
    global stub-regs-are-32

    if {![null $regwindisp]} {
    	display del $regwindisp
    }
    if {[string c $args off] != 0} {
        if {${stub-regs-are-32}} {
    	    var regwindisp [display 3 _display_regs_32]
        } else {
    	    var regwindisp [display 2 _display_regs]
        }
    }
    return $regwindisp
}]

[defcommand localwin {{arg {}}} top.window
{Usage:
    localwin [<number>]

Examples:
    "localwin"	    	    Display local variables in a 10-line window
    "localwin 15"   	    Display local variables in a 15-line window
    "localwin off"  	    Turn off the local variable display

Synopsis:
    Turn on or off the continuous display of local variables.

Notes:
    * Passing an optional numerical argument turns on display of that
      size. The default size is 10 lines.

    * Only one local variable display may be active at a time.

See also:
    display, regwin, srcwin.

}
{
    global localwindisp

    if {![null $localwindisp]} {
    	display del $localwindisp
    }
    if {[string c $arg off] != 0} {
    	if {[null $arg]} {
            var localwindisp [display 10 locals]
    	} else {
            var localwindisp [display $arg locals]
    	}
    }
    return $localwindisp
}]

##############################################################################
#   	    	    	    	    	    	    	    	    	     #
#			    SOURCE DISPLAY  	    	    	    	     #
#   	    	    	    	    	    	    	    	    	     #
##############################################################################
#
# $srcwinmode can be either _srcwin, _viewwin, or _docwin (see srclist.tcl)
#
defvar srcwinmode _srcwin
defvar atBreakpoint {}

#
# _display_source is the FULLSTOP event handler for the source window.
#
[defsubr _display_source {lines}
{
    global  srcwincurpos srcwinmode atBreakpoint

    #
    # Did we get here by hitting a breakpoint?
    #
    if {[brk isset cs:ip] && [null $atBreakpoint]} {
	#
	# Yes. We'll want to display the code at the current point of
	# execution, so we set srcwinmode appropriately.
	#
	var srcwinmode _srcwin
	#
	# Note: atBreakpoint is set to TRUE both here and by the view
	# command when appropriate. It gets reset to NULL in
	# continue-patient, called from cont, go, spawn...
	#
	var atBreakpoint TRUE
    }
    #
    # If srcwinmode = _srcwin, we want to use the current cs:ip to get the
    # src line info, otherwise we'll keep displaying whatever is currently up.
    #
    if {[string c $srcwinmode _srcwin] == 0} {
        var fileLine [src-line-catch cs:ip]

        if {![null $fileLine]} {
    	    var srcwincurpos [list [index $fileLine 0] [index $fileLine 1] 0]
    	} else {
    	    var srcwincurpos {}
    	}
    }
    dss
}]

#############################################################################
#   get-display-source-display returns the source display from the _displays
#   global variable if a source window is currently open    	    	    
#############################################################################
[defsubr get-display-source-display {} 
{
    global curses_displays curses_disp_token srcwindisp

    if {[null $srcwindisp]} {
    	return {}
    }
    return [display-get $srcwindisp]
}]

#############################################################################
#   dslr - display scroll left/right	    	    	    	    	    
#   scrolls the source window left and right by scroll_columns 	    	    
#   negative values mean scroll left, positive is scroll right	    	    
############################################################################# 
[defsubr dslr {scroll_columns}
{
    global  	srcwincurpos srcwindisp

    # first update the proper global variable

    var newcol [expr [index $srcwincurpos 2]+$scroll_columns]
    if {$newcol<0} {
        var newcol 0
    }
    if {$newcol>[columns]} {
    	var newcol [columns]
    }

    var srcwincurpos [list [index $srcwincurpos 0] [index $srcwincurpos 1] $newcol]
    # now force a redisplay
    dss
}]

[defsubr src-addr-find-file {file line}
{
    var	addr [src addr $file $line]
    if {![null $addr]} {
    	return $file
    }
    var file [range $file [expr [string last / $file]+1] end chars]
    var addr [src addr $file $line]
    return $file
}]

#############################################################################
#   dss - display source scroll	    	    	    	    	    	    #
#   scroll the source window up or down by scroll_lines	    	    	    #
#   positive values of scroll_line scroll down, negative values scroll up   #
#############################################################################
    
[defsubr dss {{scroll_lines 0} {absolute 0}}
{
    global  	global_mouse_event attached
    global  	srcwincurpos srcwindisp srcwinmode file-os
    global  	mouse_highlight doc_linenum found_line

    #
    # We proceed only if we have a source window.
    #
    if {![null $srcwindisp]} {
    	if {$attached == 0} {
    	    var fileLine {}
   	} elif {[catch {src line cs:ip} fileLine] != 0} {
    	    var fileLine {}
    	} else {
            var truecur [index $fileLine 1]
    	}
    	if {[null $srcwincurpos]} {
	    #
    	    # src line sometimes errors, sometimes just returns nil
	    #
    	    if {[null $fileLine]} {
    	    	return
    	    }
    	    var srcwincurpos [concat $fileLine {0}]
    	}
    	#
    	# Give up if we don't have the source file.
	# (src size is a friendly way to check if the file
	# exists because it converts unix paths to dos format)
    	#
	if {[catch {[src size [index $srcwincurpos 0]]}] != 0} {
	    return
	}

    	# if we are in a different file from the current source file the
    	# don't try to hightlight the current line
    	if {[string c [index $srcwincurpos 0] [index $fileLine 0] NO_CASE] != 0} {
    	    var truecur {}
    	}

    	# in a doc file set truecur to the doc line number so that the tagged
    	# item gets highlighted, quite slick
	if {[string c $srcwinmode _docwin] == 0} {
    	    var truecur ${doc_linenum}
    	}

	#
    	# now get the size of the active source win
    	# first get the display element 
	#
    	var disp [display-get $srcwindisp]
    	if {[string c ${file-os} dos] == 0} {
       	    mouse-hide-cursor
    	}
	#
	# If there's a highlight in the source window, get rid of it.
	#
	var lineLength [expr {2 * [columns]}]
	if {![null $mouse_highlight]} {
	    scan [index $mouse_highlight 0] %d place
	    var highlightYPos [expr {$place / $lineLength}]
	    var highlightDisp [index [find-display $highlightYPos] 0]
	    if {$highlightDisp == $disp} {
	    	unhighlight-mouse
	    	var mouse_highlight {}
	    }
	}
	#
    	# the fourth element in a display is always the height
    	# subtract one line for the file name
	#
    	var lines [expr [index $disp 4]-1]
	#
    	# the file names are the same so we do this...
    	# this only real difference here is that we inverse the current
    	# line for the active file while if we are displaying a different
    	# file, we don't
	#
        var curfile [index $srcwincurpos 0]
    	var cursize [index $srcwincurpos 1]
    	var curcol  [index $srcwincurpos 2]
    	if {[string compare $srcwinmode _docwin] != 0} {
    	    var	 isdocwin 0
    	} else {
    	    var isdocwin 1
    	    var lines [expr $lines+1]
    	}
    	var half_lines [expr [expr $lines+1]/2]
    	var srcsize [src size $curfile]
    	if {$absolute == 0} {
    	    if {[expr $cursize+2*$scroll_lines]<$half_lines} {
                var srcwincurpos [list $curfile $half_lines $curcol]
    	    } elif {[expr $cursize+$scroll_lines+$half_lines>$srcsize]} {
                var srcwincurpos [list $curfile [expr $srcsize-$half_lines] $curcol]
    	    } else {
                var srcwincurpos [list $curfile [expr $cursize+$scroll_lines] $curcol]
    	    }
    	} else {
	    #
    	    # do an absolute line number
	    #
    	    var	newline [expr $absolute+$half_lines-1]
    	    if {$newline+$half_lines > $srcsize} {
    	    	var newline [expr $newline-$half_lines]
    	    }
    	    var srcwincurpos [list $curfile $newline $curcol]
    	}
        var cur [index $srcwincurpos 1]
    	var start [expr $cur-$half_lines+1]

    	# enter the srcwin for output
    	wpush   [index $disp 1]
    	wmove 0 0
	#
    	# put out the file name
	#
    	if {$isdocwin == 0} {
    	    var filename [string subst $curfile \\ / global]
	    echo [format {View file %s} $filename]
    	}
    	if {$start < 1} {
	    var start 1
    	} 

    	# dss_low is the real guts of the routine to display stuff
    	catch {dss_low $lines $start $curfile $curcol $srcwinmode $truecur $found_line}

    	# check for breakpoints that need to be highlighted if not a docwin
    	# there are many checks to be done, we need to go through all the
    	# breakpoints checking to see if:
    	#   a) its enabled
    	#   b) its in the currently displayed file
    	#   c) its at a line number currently being displayed
	if {[string c $srcwinmode _docwin] != 0} {
    	    # see how many breakpoints to look at
    	    var max [get-max-bpt-number]
    	    for {var i 0} {$i <= $max} {var i [expr $i+1]} {
    	    	if {[catch {brk addr $i} addr] == 0} {
    	    	    # see if the breakpoint is enabled
    	    	    if {[brk isenabled $i]} {
   	    	    	if {[catch {src line $addr} sl] == 0} {
    	    	    	    # src line might return nil
    	    	    	    if {[null $sl]} {
    	    	    	    	continue
    	    	    	    }
    	    	    	    # now check the file and line number
    	    	    	    if {[index $sl 1] >= $start && [index $sl 1] < [expr $start+$lines]} {
    	    	    	    	if {[string c [index $sl 0] $curfile NO_CASE] == 0} {
    	    	    	    	    wmove 0 [expr [index $sl 1]-$start+1]
    	    	    	    	    winverse 1
    	    	    	    	    echo -n [format {%4d} [index $sl 1]]
    	    	    	    	    winverse 0
      	    	    	    	}
    	    	    	    }
    	    	    	}
    	    	    }
    	    	}
    	    }
    	}

    	wrefresh
    	wpop
	#
    	# this refresh solves a strange problem that sometimes when we
    	# return to the command window we get a line of inverse text that
    	# I can't explain, but calling wrefresh solves the problem
	#
    	wrefresh
    	if {[string c ${file-os} dos] == 0} {
       	    mouse-show-cursor
    	}
    }
}]

#############################################################################
#   src-line-catch
#############################################################################
[defsubr src-line-catch {args}
{
    if {[catch {src line $args} f] != 0} {
    	var f {}
    }
    return $f
}]

#############################################################################
#   srcwin display source code in a display 	    	    	    	    
#############################################################################
[defcommand srcwin {{numLines 25} {view 0} {resizing {}}} top.window
{Usage:
    srcwin [<numLines>] [view]

Examples:
    "srcwin"	    	Bring up a 25-line display of the source
    	    	    	    code around cs:ip
    "srcwin 6"	    	Bring up a 6-line display of the source
    	    	    	    code around cs:ip
    "resize s 15"	Resize the source window to 15 lines.
    "srcwin off"	Turn the display off
    "srcwin 0"	    	Turn the display off

Synopsis:
     Turn on or off the continuous display of source code.

Notes:
    * The optional <numLines> argument specifies the size of the
      display. The default is 25 lines.

    * The optional <view> argument suppresses the error message which
      is otherwise printed if the source code is not available.

    * There can be no more than one source window. Entering a second
      srcwin command when a source window or a window created by the
      view command is already up will replace that window with a new
      one.

See also:
    sym-default, view-default, view, resize, find, tag, line, doc

}
{
    global srcwindisp srcwinevents _view_filename
    global srcwincurpos srcwinmode file-os

    if {![null $srcwindisp]} {

	if {[null $resizing]} {
	    var srcwinmode _srcwin
	}
    	display del $srcwindisp
	foreach e $srcwinevents {
	    event delete $e
	}
	var srcwindisp {} srcwinevents {}
    	if {[string c ${file-os} unix] != 0} {
    	    # these are all the page up/down/left/right keys
            unbind-key \321
    	    unbind-key \320
    	    unbind-key \311
    	    unbind-key \310
    	    unbind-key \313
    	    unbind-key \315
    	    unbind-key \307
    	    unbind-key \317
        }
    	
    }
    #
    # Done if we're turning the display off
    #
    if {[string m $numLines {o*}]} {
    	return
    }
    if {$numLines > 0} {
        var srcwindisp [display $numLines [concat _display_source $numLines]]
    	var srcline [src-line-catch cs:ip]
    	var _view_filename  1

    	var dis [display-get $srcwindisp]
        var srcwinevents [map e {STACK CHANGE} {
    	    event handle $e _display_catch $dis
    	}]
	if {[null $resizing]} {
	    if {[null $srcline]} {
		if {$view == 0} {
		    echo {Source file for the current point of execution is not available}
		    var srcwincurpos {}
		}
	    } else {
		var srcwincurpos [list [index $srcline 0] [index $srcline 1] 0]
		dss
	    } 
	} else {
	    dss
	}
    	if {[string c ${file-os} unix] != 0} {
    	    # page down
            bind-key \321 [format {dss %d} [expr $numLines/2]]
       	    # arrow down
	    bind-key \320 {dss 1}
    	    # page up
    	    bind-key \311 [format {dss %d} [expr -$numLines/2]]
    	    # arrow up
	    bind-key \310 {dss -1}
    	    # scroll left
    	    bind-key \313 {dslr -5}
    	    # scroll right
    	    bind-key \315 {dslr 5}
    	    # home (go to top of file)
    	    bind-key \307 {dss 1 1}
    	    # end (end of file)
    	    bind-key \317 {dss 1000000}
    	}
    	return $srcwindisp
    }
}]
    
##############################################################################
#   show all active key bindings    	    	    	    	    	     #
##############################################################################
[defcommand bindings {} support.binding
{Usage:
    bindings

Synopsis:
    Shows all current key bindings

See also:
    bind-key, unbind-key, get-key-bindings
}
{
    var	i 0
    for {} {$i<256} {var i [expr $i+1]} {
    	var stuff [get-key-binding [format {%c} $i]]
    	if {![null $stuff]} {
    	    if {$i>127} {
        	    echo [format {\\%03o:  : %s} $i $stuff]
    	    } else {
        	    echo [format {\\%03o: %c: %s} $i $i $stuff]
    	    }
    	}
    }
}]

##############################################################################
#				resize
##############################################################################
#
# SYNOPSIS:	Resize the source window or a varwin or localwin.
# PASS:		window   = the name of the window to be resized
#               numLines = the desired size
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jenny	11/ 9/93	Initial version
#
##############################################################################
[defcommand resize {window numLines} {top.window top.source}
{Usage:
    resize <window> <numLines>

Example:
    "resize varwin 5"	Resizes the varwin to 5 lines.
    "resize va 5"       Ditto.

Synopsis:
    Resizes the source window or a varwin or localwin.

Notes:
    * The <window> argument is the name of the window to be resized, or
      a unique abbreviation of that name. Possible names are: "varwin",
      "localwin", "view", "doc", and "srcwin"; the last three all refer
      to the source window.

    * The <numLines> argument is the desired window size.

    * This command will not resize a flagwin, regwin, or framewin,
      as the optimal size of those windows does not vary.

See also:
    varwin, localwin, view, view-default, sym-default, doc, srcwin, tag, find.
}
{
    global srcwindisp varwindisp localwindisp

    [case $window in
        {s* vi* d*} {
	    if {![null $srcwindisp]} {
		srcwin $numLines view resizing
		dss
	    } else {
		error {No view/doc/srcwin exists.}
	    }
	}
	va* {
	    if {![null $varwindisp]} {
		varwin -s $numLines
	    } else {
		error {No varwin exists.}
	    }
	}
	l* {
	    if {![null $localwindisp]} {
		localwin $numLines
	    } else {
		error {No localwin exists.}
	    }
	}
	v* {
	    echo Use "resize va <size>" for the varwin, or "resize vi <size>" for the view.
	}
	default {
	    error {Invalid window name.}
	}
    ]
}]


##############################################################################
#   	    	    	    	    	    	    	    	    	     #
#			    VARIABLE DISPLAY  	    	    	    	     #
#   	    	    	    	    	    	    	    	    	     #
##############################################################################

##############################################################################
#				varwin
##############################################################################
#
# SYNOPSIS:	Turn on a continuous display of the specified variables.
# PASS:		(optional) flags = specify display size 
#                                   or whether variable is global
#               variables        = variables to watch
# CALLED BY:	user
# RETURN:	display token
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jenny	11/10/93	Initial version
#
##############################################################################
[defsubr _display_var {}
{
    global varsymlist

    require locals-callback stack
    foreach vsym $varsymlist {
	locals-callback $vsym 1
    }
}]

[defcommand varwin {args} top.window
{Usage:
    varwin [<flags>] <variables>

Examples:
    "varwin bing ping"	Turns on a 2-line display showing the values of
    	    	    	    the local or global variables, bing and ping,
                            or adds them to an existing varwin display
    "varwin -gs 5 hi" 	Turns on a 5-line display showing the value of a
                            global variable, hi (rather than of any local
                            variable by the same name).
    "varwin -s 7"    	Resizes an existing varwin to 7 lines.
    "resize va 7"       Also resizes an existing varwin to 7 lines.
    "varwin off"    	Turns off the varwin.

Synopsis:
    Turn on a continuous display of the specified variables.

Notes:
    * The optional <flags> arguments are:
      -g    Specifies that the variable is global. This flag need not be
            used unless a local variable by the same name exists.
      -s    Must be followed by a number. Specifies the size of the varwin.

    * The <variables> argument specifies the variables to examine.

    * If no size is specified, the display contains one line per variable.

See also:
    display, localwin, resize.
}
{
    global varwindisp varsymlist

    #
    # Initialize stuff.
    #
    var size 0
    var addLines 0
    #
    # Turn off any current varwin.
    #
    if {![null $varwindisp]} {
	var size [index [display-get $varwindisp] 4]
    	var vsl $varsymlist
        display del $varwindisp
    }
    #
    # Unless all we want to do is turn off the varwin...
    #
    if {[string c $args off] != 0} {
	#
	# Set $size and $globalVar according to the passed flags, if any.
	#
	if {[string m [index $args 0] -*]} {
	    foreach i [explode [index $args 0]] {
		[case $i in
		 g {
		     var globalVar TRUE args [range $args 1 end]
		 }
		 s {
		     var setSize TRUE
		     var size [index $args 1] args [range $args 2 end]
		 }]
	    }
	}
	#
	# Add the symbols for the variables to be watched to $varsymlist.
	#
	var varsymlist $vsl
        if {[null $args]} {
	    if {[null $varsymlist]} {
    	    	error {Variables to watch not specified.}
    	    }
    	} else {
	    foreach v $args {
		#
		# By default, we add one line per variable to the display
		# size.
		#
		if {[null $setSize]} {
		    var addLines [expr $addLines+1]
		}
		#
		# If there are a local variable and a global variable
		# with the same name, we will display the local unless
		# the user has specified that s/he wants to see the global.
		#
		var vsym [symbol find locvar $v [frame funcsym]]
		if {![null $globalVar] || [null $vsym]} {
		    var vsym [symbol find var $v]
		    if {[null $vsym]} {
			echo [format {Cannot find variable: %s} $v]
		    }
		}
		if {![null $vsym]} {
		    var varsymlist [concat [list $vsym] $varsymlist]
		}
	    }
	}
	#
	# Yip! Yip! Yip!
	#
	if {![null $varsymlist]} {
	    var varwindisp [display [expr $size+$addLines] _display_var]
	}
    }
    return $varwindisp
}]

##############################################################################
#   	    	    	    	    	    	    	    	    	     #
#			    FRAME DISPLAY  	    	    	    	     #
#   	    	    	    	    	    	    	    	    	     #
##############################################################################
[defsubr curses-show-frame {}
{
    if {[catch {frame cur} cur] != 0} {
	echo Current patient has no threads
    } else {
    	var fs [frame funcsym $cur]
	if {![null $fs]} {
	    echo -n [format {frame = %4s %s(), } [index [symbol get $fs] 1]
			[symbol fullname $fs]]
	    #if know source info for frame, use that, else use cs:ip
	    [if {[catch {src line [frame register pc $cur]} fileLine] == 0 &&
		 ![null $fileLine]}
	    {
		echo [file tail [index $fileLine 0]]:[index $fileLine 1]
	    } else {
		echo addr [frame register pc $cur]
	    }]
	}
    }
}]

[defcommand framewin {{nukeit {}}} top.window
{Usage:
    framewin [off]

Examples:
    "framewin"	    	Creates a single-line window to display info about the
			current stack frame.
    "framewin off"  	Deletes the window created by a previous "framewin"

Synopsis:
    Creates a window in which the current stack frame is always displayed.

Notes:
    * Only one frame window can be active at a time.

See also:
    display, regwin, srcwin

}
{
    global  _fw_data framewindisp
    
    if {[string c $nukeit off] == 0} {
	if {![null $framewindisp]} {
	    display del $framewindisp
	}
	return
    } elif {![null $_fw_data]} {
	return
    } else {
    	var framewindisp [display 1 {curses-show-frame}]
	var _fw_data [event handle STACK _display_catch [display-get $framewindisp]]
    }
}]

[defsubr framewincleanup {}
{
    global  _fw_data framewindisp

    if {[null $_fw_data]} {
	return
    }
    event delete $_fw_data
    var _fw_data {}
    var framewindisp {}
}]


[defcommand find {noeval} top.source
{Usage:
    find <string> [<file>]

Examples:
    "find FileRead"  	    find next occurrence of string "FileRead"
    	    	    	    	in currently viewed file

    "find FI_foo poof.goc"
    	    	    	    find first occurrence of string "FI_foo"
    	    	    	    	in file poof.goc

    "find -ir myobject"     case-insensitive reverse search for most
    	    	    	    	recent occurrence of string "myobject"
    	    	    	    	in currently viewed file
Synopsis:
    Finds a string in a file. 

Notes:
    * If no file is specified, find will find the next instance of the string
      in the already viewed file starting from the current file position

    * There must already be a source window displayed for find to work.

    * Possible options to find are:
      -------------------------------
      -r    reverse search
      -i    case insensitive search

See also:
    srcwin, view, doc. tag. resize, line, sym-default, view-default
}
{
    global srcwincurpos

    var case {} direction 1
    if {[string m [index $noeval 0] -*]} {
        #
	# Gave us some flags
	#
	foreach i [explode [index $noeval 0]] {
	    [case $i in
		i {var case no_case}
    	    	r {var direction -1}
    	    ]
    	}
    	var string [index $noeval 1]
    	var filename [index $noeval 2]
    } else {
    	var string [index $noeval 0]
    	var filename [index $noeval 1]
    }

    var found [search_internal $string $direction $filename $case]

    # if don't find it the wrap around
    if {[null $found]} {
    	# save the original value in case we don't find it
    	var swcp $srcwincurpos
    	if {$direction == 1} {
    	    var srcwincurpos [list [index $srcwincurpos 0] 0 [index $srcwincurpos 2]]
    	} else {
    	    var srcwincurpos [list [index $srcwincurpos 0] [src size [index $srcwincurpos 0]] [index $srcwincurpos 2]]
    	}    	
        var found [search_internal $string $direction $filename $case]
    	if {[null $found]} {
    	    echo [format {string "%s" not found in file} $string]
    	    var srcwincurpos $swcp
    	}
    }    
}]


[defsubr search_internal {string direction {file {}} {mode {}}}
{
    global  srcwincurpos srcwinmode found_line

    #
    # if file not specified, get currently displayed file
    #
    var	start 1
    if {[null $file]} {
    	var usingDefault TRUE
    	if {[null $srcwincurpos]} {
    	    error {No file currently open or specified.}    	    
    	    return 1
    	} else {
    	    var start [expr [index $srcwincurpos 1]+$direction]
    	    var	file [index $srcwincurpos 0]
    	}
    } elif {$direction < 0} {
    	#
    	# if we are going backwards and we are given a file, then start
    	# from the end of the file, not the beginning
    	#
    	var start [src size $file]
    }

    var seen_lines 0
    var num_lines [src size $file]

    for {} {1} {} {
    	if {[catch {src read $file $start} line] == 0} {
    	    #
    	    # Search the current line.
    	    #
    	    if {[null $mode]} {
        	var begin [string first $string $line]
    	    } else {
        	var begin [string first $string $line no_case]
    	    }
            if {$begin != -1} {
    	        break
    	    }
    	} else {
    	    #
    	    # We've looked at every line of the file, or the file was not found.
	    # Unfortunately, there's no really good way of telling which is which,
	    # so we just check the returned error string.
    	    #
	    if [string m $line File*] {
		echo [format {File "%s" not found in current directory.} $file]
	    } else {
		#echo [format {"%s" not found.} $string]
	    }
    	    return {}
    	}
    	#
    	# Make $start indicate the next line of the file to examine, and
    	# check it since src read returns no error for negative line numbers
    	#
    	var start [expr $start+$direction]
    	if {$start < 0} {
#    	    echo [format {"%s" not found.} $string]
    	    return {}
    	}
    	var seen_lines [expr $seen_lines+1]
    	if {$seen_lines > $num_lines} {
    	    return {}
    	}
    }

    #
    # We found the string, so bring it up and highlight it.
    # If the file was originally brought up by the "doc" command,
    # don't show the line numbers; otherwise, do.
    #
    var found_line $start
    var srcwincurpos [list $file $start [index $srcwincurpos 2]]
    var swcp $srcwincurpos
    if {(![null $usingDefault]) && ([string c $srcwinmode _docwin] == 0)} {
    	catch {dss}
#    	view $file $found_line 0
    } else {
    	catch {dss}
#    	view $file $found_line
    }
    var srcwincurpos $swcp
    global repeatCommand lastCommand
    var repeatCommand $lastCommand
    return $found_line
}]
