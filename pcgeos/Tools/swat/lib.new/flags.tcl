#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library -- 
# FILE:		flags.tcl
# AUTHOR:	Eric Weber, Apr 15, 1993
#
# COMMANDS:
#	Name			Description
#	----			-----------
#   	pflags	    	    	print out the current flags
#   	flagwin	    	    	create a flag status window
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	weber	4/15/93	    	Initial revision
#
# DESCRIPTION:
#	useful routines for dealing with flags
#
#	$Id: flags.tcl,v 1.4.12.1 97/03/29 11:27:39 canavese Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


[defcommand pflags {args} {flag print}
{Usage:
   pflags

Synopsis:
   Prints the current flags.

See Also:
    setcc, getcc.
}
{
    ensure-swat-attached
    global flags
    echo -n {Flags: }
    var flagval [frame register CC [frame cur]]
    foreach i $flags {
        var bit [index $i 1]
	echo -n [format {%s=%d } [index $i 0] [expr ($flagval&$bit)/$bit]]
    }
    echo
    echo
}
]


##############################################################################
#                                                                            #
#   	    	    	    FLAGS DISPLAY	    	    	    	     #
#									     #
##############################################################################


defvar _lastFlags nil
defvar flagwindisp nil

[defsubr _display_flags {}
{
    global  flags
    global  _lastFlags 
    
    var	    flagval [frame register CC [frame cur]]

    if {[null $_lastFlags]} {
	var _lastFlags $flagval
    }

    foreach i $flags {
	var bit	[index $i 1]
	var f1	[expr ($flagval&$bit)/$bit]
	var f2	[expr ($_lastFlags&$bit)/$bit]
	if {$f1 != $f2} {
	    winverse 1
	    echo -n [format {%s=%d} [index $i 0] $f1]
	    winverse 0
	} else {
	    echo -n [format {%s=%d} [index $i 0] $f1]
	}
	echo -n { }
    }
    echo
    var _lastFlags $flagval
}
]

[defcommand flagwin {args} {top.window flag}
{Usage:
    flagwin
    flagwin off

Synopsis:
    Turns on or off the continuous display of flags.

See Also:
    pflags.
}
{
    global flagwindisp

    if {![null $flagwindisp]} {
    	display del $flagwindisp
    	var flagwindisp {}
    }
    if {[string c $args off] != 0} {
    	var flagwindisp [display 1 _display_flags]
    }

    return $flagwindisp
}
]
