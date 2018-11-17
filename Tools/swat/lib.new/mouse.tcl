##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE: 	
# AUTHOR: 	jimmy lefkowitz
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jimmy	5/ 5/89		Initial Revision
#
# DESCRIPTION: 
#   	    	global variables:
#   	    	    	mousemode - state of mouse action
#   	    	    	    	{} - nothing
#   	    	    	    	_grab_text_mode - highlight text as mouse moves
#
#   	    	    	mouse_highlight - info on highlighted region
#   	    	    	    	{} - no highlighted text
#   	    	    	    	<x y> : x = start of region
#   	    	    	    	    	  y = end of region  
#
#	$Id: mouse.tcl,v 1.22 97/04/29 19:42:12 dbaumann Exp $
#
###############################################################################

require curses

defvar mouse_highlight {}

defvar hmmc 0

[defsubr hmm {}
{
	global last_left_button_click
	global global_mouse_event
	global hmmc
	global mouse_highlight mh

	var hmmc [expr $hmmc+1]
	var mh $mouse_highlight
	var last_left_button_click
	var global_mouse_event
}]

#############################################################################
#   main dispatch routine for all mouse events
#############################################################################
[defsubr debug-test {mouse_event}
{
    global  mousemode mouse_highlight global_mouse_event 
    global  last_left_button_click

    # put useful values into variables
    var	xpos [index $mouse_event 0]
    var	ypos [index $mouse_event 1]
    var	button [index $mouse_event 2]

    # THIS IS NECESSARY, because of the hack to overcome the mouse driver
    # no reporting mouse movements onto the space where a hide-cursor has
    # been called, I have to report fake events to see if we moved onto one
    # of these spaces.  in order to avoid responding to a cursor just sitting
    # there I just check to see if nothing has changed ...sigh
    if {[string c $mouse_event $global_mouse_event] == 0} {
    	return
    }
}]

[defsubr hi {}
{
	global last_left_button_click
	global global_mouse_event

	var last_left_button_click
	var global_mouse_event
}]
#############################################################################
#   main dispatch routine for all mouse events
#############################################################################
[defsubr mouse-do-event {mouse_event}
{
    global  mousemode mouse_highlight global_mouse_event 
    global  last_left_button_click
    global  mydisp mydisp_name doing_breakpoint

    #
    # put useful values into variables
    #
    var	xpos [index $mouse_event 0]
    var	ypos [index $mouse_event 1]
    var	button [index $mouse_event 2]

    #
    # THIS IS NECESSARY, because of the hack to overcome the mouse driver
    # no reporting mouse movements onto the space where a hide-cursor has
    # been called, I have to report fake events to see if we moved onto one
    # of these spaces.  in order to avoid responding to a cursor just sitting
    # there I just check to see if nothing has changed ...sigh
    #
    if {[string c $mouse_event $global_mouse_event] == 0} {
    	return
    }

    if {![null $global_mouse_event] && [index $global_mouse_event 2] & 002} {
    	var last_left_button_click $global_mouse_event
    } elif {$button & 001} {
    	if {$xpos != [index $global_mouse_event 0] || $ypos != [index $global_mouse_event 1]} { 
    	    var last_left_button_click {}
    	}
    }
    var global_mouse_event $mouse_event

#    event dispatch FULLSTOP _DONT_PRINT_THIS_
#    echo  [format {%03o %03o %03o} $xpos $ypos $button]
    #
    # figure out which display got the mouse click
    #
    var mydisp [find-display $ypos]
    #
    # get the display name, could be _main_display, _main_line or an
    # actual display list for any other displays
    #
    var	mydisp_name [index $mydisp 0]
    #
    # get the srcwin, might need it
    #
    var srcdisp [get-display-source-display]
    #
    # if we click on the _main_line and a srcwin is open then
    # scroll it up or down depending on the button
    #
    if {[string c $mydisp_name _main_line] == 0 && [expr $button&004] == 0 } {
    	if {![null $srcdisp]} {
	    #
    	    # see how large the srcwin is and scroll by half its height
	    #
    	    var lines [index $srcdisp 4]
            [case $button in 
    		002 {dss [expr $lines/2]}   # left button press, scroll down
    	    	010 {dss [expr -$lines/2]}  # right button press, scroll up
    	   ]
    	   return
    	}
    }
    #
    # we want to do the buttons first as they take precedence over
    # a drag...    	
    
    # bit 004 is a release of the left button, this takes us out of
    #   	    _grab_text_mode and leaves us in null mode
    # bit 002 is a press of the left button, this puts us into 
    #   	    _grab_text_mode
    # bit 001 is a mouse drag - see mouse drag routine for details
    # bit 010 is a right button press - this does a paste into the
    #   	    command line of the highlighted text
    # region if there is one
    #
    var btn [expr $button]
    if {[expr $btn&4]} {
        if {![null $mousemode]} {
    	    var mousemode {}
	    #
    	    # Press and release on the same spot undoes the current highlight.
	    #
    	    if {[index $mouse_highlight 0] == [index $mouse_highlight 1]} {
    	        invert-screen-region [index $mouse_highlight 0] [index $mouse_highlight 1]
    	        var mouse_highlight {}
    	    }
	    handle-scrolled-highlight
            mouse-show-cursor
	    #
    	    # allow mouse to go anywhere again
	    #
    	    mouse-set-y-range 0 49
        }
    } elif {[expr $btn&2]} {
	if {$mydisp_name == $srcdisp && $xpos < 5} {
	    mouse-do-breakpoint $ypos $mydisp left
	} else {
	    left-button-down $xpos $ypos 
	}
    } elif {[expr $btn&1]} {
        mouse-drag $xpos $ypos
    } elif {[expr $btn&8]} {
	if {$mydisp_name == $srcdisp && $xpos < 5} {
	    mouse-do-breakpoint $ypos $mydisp right
	} else {
            right-button-down
    	}
    }
}]


#############################################################################
#   deal with a left button mouse click in the source window, set or unset
#   breakpoints if appropriate
#############################################################################
[defsubr handle-scrolled-highlight {}
{
	global mydisp_name

	#
	# If we're in the command window, we update the scrolled
	# highlight info; else, we clear it.
	#
	if {[string c $mydisp_name _main_display] == 0} {
    	    update-scrolled-highlight
	} else {
	    clear-highlightinfo
	}
}]

#############################################################################
#   deal with a left button mouse click in the source window, set or unset
#   breakpoints if appropriate
#############################################################################
[defsubr mouse-do-breakpoint {ypos mydisp which}
{
    global  srcwincurpos file-os
    global  doing_breakpoint

    var ypos [expr $ypos]

    if {![null $doing_breakpoint]} {
    	var  doing_breakpoint {}
    	return
    }

    var disp_start [index $mydisp 1]
    # the top line is the file name
    if {$ypos == $disp_start} {
    	return
    }
    var doing_breakpoint TRUE
    var	srcdisp [index $mydisp 0]
    var delta_y [expr $ypos-$disp_start-[expr [index $srcdisp 4]+1]/2]
    # deal with odd numbers from the /2 in the above line
    if {[expr [expr [index $srcdisp 4]/2]*2] != [expr [index $srcdisp 4]]} {
    	var delta_y [expr $delta_y+1]
    }
    var filename [index $srcwincurpos 0]
    var lineno [expr [index $srcwincurpos 1]+$delta_y]

    # methods are kind of weird in C so this allows us to click on the
    # @method line and actually set a breakpoint somewhere useful
    if {[string match [src read $filename $lineno] @*method*]} {
    	var lineno [expr $lineno+1]
    }

    var bpt_list [get-active-bpt-line-numbers $filename]
    if {[string c ${file-os} unix] == 0} {
    	var filename [src-addr-find-file $filename $lineno]
    }
    var addr [src addr $filename $lineno]
    var already_bpt {}
    # find the lowest numbered line with the same src addr mapping as that
    # is the line that will get highlighted as where the breakpoint really
    # is
    var	real_line [expr $lineno-1]
    for {} {$real_line > 0} {} {
        if {[src addr $filename $real_line] != $addr} {
    	    break
       	}
        var real_line [expr $real_line-1]
    }
    var real_line [expr $real_line+1]
    # if the click corresponds to code off the screen then do nothing
   if {[expr $lineno-$real_line] >= [expr $ypos-$disp_start]} {
        var doing_breakpoint {}
    	if {[string compare $which left] == 0} {
    #	    echo {There is no executable code at that line, no breakpoint set.}
    	    return
    	} else {
    #       echo {There is no breakpoint set at that line.}
    	    return
    	}
    	prompt
        return
    }
    if {![null $bpt_list]} {
        var already_bpt [assoc $bpt_list $real_line]
    }
    if {[null $already_bpt]} {
    	if {[string compare $which left] == 0} {
      	    stop at $filename $real_line
    	} else {
	    echo {There is no breakpoint set at that line.}
    	}
    } else {
    	# if the breakpoint is enabled, just delete it
    	# if its disabled, they probably want to turn it on, so enabled it
    	if {[brk isenabled [index $already_bpt 1]]} {
    	    # if it was a right mouse click then just disable the bpt
    	    # if it was a left mouse click, then delete it
    	    if {[string compare $which left] == 0} {
    	    	delete [index $already_bpt 1]
    	    } else {
    	    	disable [index $already_bpt 1]
    	    }
    	} else {
    	    enable [index $already_bpt 1]
    	}
    }
    # now force a screen update of the source window
#    dss
    var doing_breakpoint {}
    return
}]

#############################################################################
# turn off currently highlighted region. only inverts screen, no variables
# updated
#############################################################################
[defsubr unhighlight-mouse {}
{
    global  mouse_highlight

    if {![null $mouse_highlight]} {
    	mouse-hide-cursor
    	var pin [index $mouse_highlight 0]
    	var end [index $mouse_highlight 1]
    	if {$pin < $end} {
    	    invert-screen-region $pin $end
    	} else {
            invert-screen-region $end $pin
    	}
    	mouse-show-cursor
    }
}]

#############################################################################
# code to handle a mouse drag with left button down
#############################################################################
[defsubr mouse-drag {xpos ypos}
{
    global  mousemode mouse_highlight

    if {[string c $mousemode _grab_text_mode] == 0} {

    	var pin [index $mouse_highlight 0]
    	var x [expr $xpos]
    	var y [expr $ypos]
    	var new_end [expr [expr $x+$y*[columns]]*2]
    	var old_end   [index $mouse_highlight 1]

    	# see if we are moving around below (in screen memory)
    	# the pinned point
    	var mouse_highlight [list $pin $new_end]
    	if {$new_end < $pin} {
    	    # we are below the pin
    	    if {$old_end <= $pin} {
    	    	# we are moving around below the pin
    	    	if {$old_end <= $new_end} {
    	    	    #contracting
        	    invert-screen-region $old_end [expr $new_end-2]
    	    	} else {
    	    	    invert-screen-region $new_end [expr $old_end-2]
    	    	}
    	    } else {
    	    	# we were above the pin so we flipped up
    	    	invert-screen-region $new_end [expr $pin-2]
    	    	invert-screen-region [expr $pin+2] $old_end
    	    }
    	} else {
    	    # ok, we are moving around above the pinned point
            if {$old_end < $pin} {
    	    	# ok, we have flipped from below to above the point so
    	    	# get rid of the below region and start up an above region
    	    	invert-screen-region $old_end $pin
    	    	invert-screen-region $pin $new_end
            } else {
    	    	# ok, we are not flipping, so just expand or contract
    	    	# high-lighted region
    	    	if {$old_end < $new_end} {
    	    	    # ok, we are expanding
      	            invert-screen-region [expr $old_end+2] $new_end
    	    	} else {
    	    	    # contracting
       	    	    invert-screen-region [expr $new_end+2] $old_end
    	    	}
    	    }
    	} 
    }

}]

#############################################################################
# code to handle a right mouse button click
#############################################################################
[defsubr right-button-down {}
{
    global  mouse_highlight

    insert-highlighted-text
}]

#############################################################################
# code to handle a left mouse button click in the command window
#############################################################################
[defsubr left-button-down {xpos ypos}
{
    global  mousemode mouse_highlight last_left_button_click
    global  mydisp mydisp_name curses_disp_token

    var x [expr $xpos]
    var y [expr $ypos]
    var start [expr [expr $x+$y*[columns]]*2]
    #
    # If this is the second click in the same spot, we want to highlight
    # the word clicked on.
    #
    if {[index $last_left_button_click 0] == $xpos &&
	[index $last_left_button_click 1] == $ypos} {
        unhighlight-mouse
    	mouse-hide-cursor
    	mouse-word-select $start
    	mouse-show-cursor
	handle-scrolled-highlight
    	return
    }

    var base 0
    if {[string c $mydisp_name _main_display] == 0} {
    	var height [expr [command-window-height]-1]
    } else {
	var base [index $mydisp 1]
	var height [expr {$base - 1 + [index [index $mydisp 0] 4]}]
    }

    mouse-set-y-range $base $height

    mouse-hide-cursor
    unhighlight-mouse
    clear-highlightinfo
    #
    # As long as the left mouse button is down we will be in _grab_text_mode
    #
    var mousemode _grab_text_mode
    #
    # we start with the current mouse position as the highlighted region
    #
    invert-screen-region $start $start
    var mouse_highlight [list $start $start]

}]

#############################################################################
#   	return the height of the command window
#############################################################################
[defsubr command-window-height {}
{
    return [index [wdim [cmdwin]] 1]
}]

    
#############################################################################
#   given a y value return the display that contains that row of the screen
#   also returns the xtarting Y value of that display for convenience
#############################################################################
[defsubr find-display {ypos}
{
    global  curses_displays curses_disp_token
    
    # locate the window itself
    var win [wfind 0 $ypos]
    if {[null $win]} {
    	return {}
    }
    
    # see if it belongs to any of the active displays
    [for {var i 0}
	 {$i < [bpt-extract-max $curses_disp_token]}
	 {var i [expr $i+1]}
    {
    	var el [table lookup $curses_displays $i]
    	if {$win == [index $el 1]} {
	    return [list $el [index [wdim $win] 3]]
    	}
    }]
    
    if {$win == [cmdwin]} {
    	return _main_display
    } else {
    	return _main_line
    }
}]

#############################################################################
#   	    decrease the mouse visible count 
#   	    used with mouse-show-curosr
#   	    so that nested calls should be done in pairs
#############################################################################
[defsubr mouse-hide-cursor {}
{
#    mouse-call-driver 10 0 65535 0
    mouse-call-driver 2
}]


#############################################################################
#   	    increase the mouse visible count once the cursor becomes
#   	    visible this does nothing, use with mouse-hide-cursor
#   	    so that nested calls should be done in pairs
#############################################################################
[defsubr mouse-show-cursor {}
{
    mouse-call-driver 1
#    mouse-call-driver 10 0 65535 32512
}]


#############################################################################
#   	    set the min and max values for the cursor to move in
#############################################################################
[defsubr mouse-set-y-range {ymin ymax}
{
    mouse-call-driver 8 0 [expr $ymin*8] [expr $ymax*8]
}]


#############################################################################
#   get-active-bpt-line-numbers	    	    	    	    	    	    #
#   makes a list of all active breakpoints for the file	    	    	    #
#   the list is just a list of line numbers for those breakpoints   	    #
#############################################################################
[defsubr get-active-bpt-line-numbers {file}
{
    global  file-os

    var	bpt_list {{}}

    var max_bpt [get-max-bpt-number]
    for {var bpt 1} {$bpt<=$max_bpt} {var bpt [expr $bpt+1]} {
 	if {[catch {brk addr $bpt} bpt_addr] == 0} {
    	    var	srcinfo [src-line-catch $bpt_addr]
    	    var	file2 [index $srcinfo 0]
    	    if {[string c ${file-os} unix] == 0} {
            	var file2 [src-addr-find-file $file2 [index $srcinfo 1]]
    	    	var file [range $file [expr [string last / $file]+1] end chars]
    	    }
    	    var ad [src addr $file2 [index $srcinfo 1]]
    	    var	fc [range $file 0 0 chars]
    	    var	fc2 [range $file 1 1 chars]
    	    if {$fc != [format {%s} /] && $fc != [format {%s} \\] && $fc2 != :} {
    	    	var file2 [range $file2 [expr [string last / $file2]+1] end chars]
    	    }
    	    if {[string compare $file $file2 no_case] == 0} {
    		if {[brk isset ^h[handle id [index $ad 0]]:[index $ad 1]]} {
    	    	    var	lineno [expr [index $srcinfo 1]-1]
    	    	    var ad2 [src addr $file2 $lineno]
    	    	    for {} {$ad == $ad2} {} {
    	    	    	var lineno [expr $lineno-1]
    	    	    	var ad2 [src addr $file2 $lineno]
    	    	    }
    	    	    var	bpt_el [list [expr $lineno+1] $bpt]
    	    	    var bpt_list [concat [list $bpt_el] $bpt_list]
    	    	}
    	    }
    	}
    }
    return $bpt_list
}]

#############################################################################
#		win32 function to support mouse clicks for breakpoint setting
#		called from CursesReadInput() in curses.c 
#
#		which parameter is either "left" or "right"
#############################################################################
[defsubr win32-button-press {ypos xpos which_btn}
{
    #
    # figure out which display got the mouse click
    #
    var mydisp [find-display $ypos]
    #
    # get the display name, could be _main_display, _main_line or an
    # actual display list for any other displays
    #
    var	mydisp_name [index $mydisp 0]
    #
    # get the srcwin, might need it
    #
    var srcdisp [get-display-source-display]

    # decided to always send the left button since it toggles and 
    # the right mouse button sometimes toggles, but with no error
    # messages going back to the user they won't know why (that the
    # right mouse button is mainly to turn off breakpoints

    if {$mydisp_name == $srcdisp && $xpos < 5} {
	mouse-do-breakpoint $ypos $mydisp left
    }
}]

