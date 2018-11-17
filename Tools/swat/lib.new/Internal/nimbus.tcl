
##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	SWAT -- System library.
# FILE: 	nimbus.tcl
# AUTHOR: 	Gene Anderson
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	tnimbus    	    	trace Nimbus commands during rasterization
#	pnimbit			print a Nimbus bitmap
#   	pnimdata    	    	print Nimbus outline data
#   	pnimchar    	    	print Nimbus outline data for a character
#   	pnimcommand 	    	print a Nimbus outline command
#
#	$Id: nimbus.tcl,v 3.19.12.1 97/03/29 11:25:11 canavese Exp $
#
###############################################################################

require pncbitmap putils

##############################################################################
#				pnimbit
##############################################################################
#
# SYNOPSIS:	print a Nimbus bitmap
# PASS:		$addr - ptr to Nimbus bitmap
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	6/13/89		Initial Revision
#
##############################################################################

[defcmd pnimbit {addr} lib_app_driver.font.nimbus
{Usage:
    pnimbit <address>

Synopsis:
    Print a Nimbus bitmap.

Notes:
    * This is an internal command.

    * The address argument is the address of the bitmap in a nimbus font.

See also:
    pnimdata, pnimcommand, tnimbus
}
{
    #
    # Set various variables that will be needed.
    #
    var address     [addr-parse $addr]
    var	seg	    [handle segment [index $address 0]]
    var offset	    [index $address 1]
    var width	    [value fetch $seg:$offset.NB_width]
    var height	    [value fetch $seg:$offset.NB_height]
    var bseg 	    [value fetch $seg:$offset.NB_segment]
    var lox	    [value fetch $seg:$offset.NB_lox]
    var hiy	    [value fetch $seg:$offset.NB_hiy]

    echo [format %s%d {width = } $width]
    echo [format %s%d {height = } $height]
    echo [format %s%d {low x = } $lox]
    echo [format %s%d {high y = } $hiy]

    pncbitmap $bseg:0 $width $height
}]

##############################################################################
#				tnimbus
##############################################################################
#
# SYNOPSIS:	toggle tracing of Nimbus rasterization on and off.
# PASS:		none
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	9/14/90		Initial Revision
#
##############################################################################

[defcmd tnimbus {} lib_app_driver.font.nimbus
{Usage:
    tnimbus

Synopsis:
    Trace Nimbus character data commands while building characters.

Notes:
    * This is an internal command.

See also:
    pnimbit, pnimcommand, pnimdata.
}
{
    global  tn_state
    global  tn_cmdtrace

    #
    # If we've never been called before, create the appropriate
    # breakpoint commands. Otherwise, just toggle the breakpoints.
    #
    if {[null $tn_state]} {
    	#
    	# (1) Print the current pen position (transformed)
    	# (2) Print the data command
    	#
    	var tn_cmdtrace [brk Segments {
echo [format {pen=(%d,%d)} [value fetch ds:x0] [value fetch ds:y0]]
echo [type emap [value fetch es:di byte] [sym find type NimbusCommands]]
expr 0}]
    	var tn_state 2
    	echo {Nimbus tracing started}
    } elif {$tn_state == 1} {
    	brk enable $tn_cmdtrace
    	var tn_state 2
    	echo {Nimbus tracing ON}
    } else {
    	brk disable $tn_cmdtrace
    	var tn_state 1
    	echo {Nimbus tracing OFF}
    }
}]

##############################################################################
#				pnimchar
##############################################################################
#
# SYNOPSIS:	print the Nimbus outline data for a character.
# PASS:		$char - character to print
#   	    	$font - font ID
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	9/14/90		Initial Revision
#
##############################################################################

[defcmd pnimchar {char font {styles {}}} lib_app_driver.font.nimbus
{Usage:
    pnimchar <character> <font> [<styles>]

Synopsis:
    Print the Nimbus data for a character in a given font.

Notes:
    * This is an internal command.

    * The character argument may either be a character or the ASCII
      code for a character.

    * The font argument requires a PC/GEOS font ID.

    * The styles argument requires a list of styles.  If not specified 
      plain text is assumed.

See also:
    pnimdata, pnimbit, pnimcommand, tnimbus.
}
{
    #
    # Check out the chararcter -- see if it's a numeric constant
    # If it's a chararcter, convert it to a constant.
    #
    if {[catch {eval {expr $char+0}}] != 0} {
        if {[string m $char C_* ]} {
            var pchar [getvalue $char]
    	} else {
    	    scan $char %c pchar
    	}
    } else {
        var pchar $char
    }
    #
    # Check out the font -- see if it's a numeric constant
    #
    if {[catch {eval {expr $font+0}}] != 0} {
    	if {[string m $font FID_* ]} {
    	    var pfont [getvalue $font]
    	} else {
    	    error [format {unknown font ID %s} $font]
    	}
    } else {
    	var pfont $font
    }
    #
    # Check out the styles -- see if they're numeric constants
    #
    var style 0
    while {![null $styles]} {
    	var s [getbitvalue TextStyle [car $styles]]
    	if {$s != -1} {
    	    var style [expr {$style|$s}]
    	} else {
    	    var style [expr {$style+[getvalue [car $styles]]}]
    	}
    	var styles [cdr $styles]
    }
    if {[not-1x-branch]} {
        var kstyles [expr ([getbitvalue TextStyle TS_UNDERLINE]|[getbitvalue TextStyle TS_STRIKE_THRU])]
    } else {
        var kstyles [expr ([getbitvalue TextStyles ST_UNDERLINE]|[getbitvalue TextStyles ST_STRIKE_THRU])]
    }
    var style [expr {~$kstyles&$style}]
    #
    # Find the FontsAvailEntry for the font, if any, and get the
    # associated FontInfo chunk.
    #
    var availPtr  [isfontavail $pfont]
    var seg 	  [fontinfoaddr]
    var lhan 	  [value fetch $seg:$availPtr.FAE_infoHandle]
    var chunkAddr [value fetch $seg:$lhan word]
    var outPtr	[expr $chunkAddr+[value fetch $seg:$chunkAddr.FI_outlineTab]]
    var outEnd	[expr $chunkAddr+[value fetch $seg:$chunkAddr.FI_outlineEnd]]
    #
    # Find the outline data for the font. As in the font driver,
    # we want to find the largest subset of the styles requested.
    #
    var c_diff 9999 c_off 0
    while {$outPtr < $outEnd} {
    	var val [value fetch $seg:$outPtr.ODE_style byte]
    	if {[issubset $style $val]} {
    	    if {[expr {$style-$val&$style}]<$c_diff} {
    	    	var c_diff [expr {$style-$val&$style}]
    	    	var c_off $outPtr
    	    }
    	}
    	var outPtr [expr $outPtr+[size OutlineDataEntry]]
    }
    #
    # We know which data to use. We need some info from the
    # header block about first and last character, etc.
    # If it's not there, we'll just make some guesses.
    #
    var dhan [value fetch $seg:$c_off.ODE_header.OE_handle]
    if {$dhan != 0} {
    	var dseg [field [value fetch kdata:$dhan HandleMem] HM_addr]
    }
    if {$dhan == 0 || $dseg == 0} {
    	error [format {header block discarded}]
    } else {
    	var first [value fetch $dseg:NFH_firstChar byte]
    	var last [value fetch $dseg:NFH_lastChar byte]
    	var dptr [expr {[size NewFontHeader]+($pchar-$first)*[size NewWidth]}]
    	var width [format {%d} [value fetch $dseg:$dptr.NW_width]]
    	var flags [precord CharTableFlags [value fetch $dseg:$dptr.NW_flags byte] 1]
    }
    #
    # See if there is a handle for the data, and if so, see
    # if the block in question is loaded. If not, complain.
    #
    echo -n {using }
    if {[not-1x-branch]} {
        precord TextStyle [value fetch $seg:$c_off.ODE_style byte]
    } else {
        precord TextStyles [value fetch $seg:$c_off.ODE_style byte]
    }
    if {$pchar < 0x80} {
        var dhan [value fetch $seg:$c_off.ODE_first.OE_handle]
    	var dchar [expr {$pchar-$first}]
    } else {
    	var dhan [value fetch $seg:$c_off.ODE_second.OE_handle]
    	var dchar [expr {$pchar-0x80}]
    }
    if {$dhan == 0} {
    	error [format {data not loaded}]
    } else {
    	var dseg [field [value fetch kdata:$dhan HandleMem] HM_addr]
    	if {$dseg == 0} {
    	    error [format {data for handle ^h%xh discarded} $dhan]
    	}
    }
    echo [format {using data handle = ^h%xh (at %xh)} $dhan $dseg]
    var dptr [expr {$dchar*2}]
    echo [format {width = %s (%xh)} $width $width]
    echo [format {flags = %s} $flags]
    pnimdata $dseg:[value fetch $dseg:$dptr word]
}]

##############################################################################
#				pnimdata
##############################################################################
#
# SYNOPSIS:	Given a ptr, print the Nimbus commands for a character.
# PASS:		$addr - ptr to the NimbusData for a character
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	10/11/90	Initial Revision
#
##############################################################################

[defcmd pnimdata {addr} lib_app_driver.font.nimbus
{Usage:
    pnimdata <address>

Synopsis:
    Print the Nimbus data for a character.

Notes:
    * This is an internal command.

    * The address argument is the address of an outline font.

See also:
    pnimbit, pnimchar, pnimcommand, tnimbus.
}
{
    var	seg	^h[handle id [index [addr-parse $addr] 0]]
    var offset	[index [addr-parse $addr] 1]
    var command -1
    #
    # Print the header with the bounds of the data
    #
    _print NimbusData $seg:$offset
    var offset [expr {$offset+[size NimbusData]}]
    #
    # Print the number of x-tuples, print them, and advance past them
    #
    var ntuples [value fetch $seg:$offset byte]
    echo [format {#x-tuples = %d} $ntuples]
    var offset [expr $offset+1]
    for {} {$ntuples > 0} {var ntuples [expr $ntuples-1] offset [expr $offset+[size NimbusTuple]]} {
    	_print NimbusTuple $seg:$offset
    }
    #
    # Print the number of y-tuples, print them, and advance past them
    #
    var ntuples [value fetch $seg:$offset byte]
    echo [format {#y-tuples = %d} $ntuples]
    var offset [expr $offset+1]
    for {} {$ntuples > 0} {var ntuples [expr $ntuples-1] offset [expr $offset+[size NimbusTuple]]} {
    	_print NimbusTuple $seg:$offset
    }
    #
    # Go through the commands and print them out
    #
    while {$command != [getvalue NIMBUS_DONE]} {
    	var command [value fetch $seg:$offset NimbusCommands]
    	var offset [pnimcommand $seg:$offset]
    	if {$command == [getvalue NIMBUS_ACCENT]} {
    	    var	command	[getvalue NIMBUS_DONE]
    	}
    }
}]

##############################################################################
#				pnimcommand
##############################################################################
#
# SYNOPSIS:	print a Nimbus data command and associated data
# PASS:		$addr - ptr to Nimbus command
# RETURN:	$offset - offset of next Nimbus command
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	10/11/90	Initial Revision
#
##############################################################################

[defcmd pnimcommand {addr} lib_app_driver.font.nimbus
{Usage:
    pnimcommand <address>

Synopsis:
    Print Nimbus data from memory, and advance a ptr appropriately.

Notes:
    * This is in internal command.

    * The address argument is the address to a Nimbus command.

See also:
    tnimbus, pnimdata, pnimbit.
}
{
    var	seg	^h[handle id [index [addr-parse $addr] 0]]
    var offset	[index [addr-parse $addr] 1]

    var command [value fetch $seg:$offset NimbusCommands]
    penum NimbusCommands $command
    var offset [expr $offset+[size NimbusCommands]]
    [case $command in
	0 {_print NimbusMoveData $seg:$offset
    	   var offset [expr $offset+[size NimbusMoveData]]}
	1 {_print NimbusLineData $seg:$offset
    	   var offset [expr $offset+[size NimbusLineData]]}
	2 {_print NimbusBezierData $seg:$offset
    	   var offset [expr $offset+[size NimbusBezierData]]}
	3 {echo {DONE}}
	5 {_print NimbusAccentData $seg:$offset
    	   var offset [expr $offset+[size NimbusAccentData]]}
	6 {_print NimbusVertData $seg:$offset
    	   var offset [expr $offset+[size NimbusVertData]]}
	7 {_print NimbusHorizData $seg:$offset
    	   var offset [expr $offset+[size NimbusHorizData]]}
	8 {_print NimbusRelLineData $seg:$offset
    	   var offset [expr $offset+[size NimbusRelLineData]]}
	9 {_print NimbusRelBezierData $seg:$offset
    	   var offset [expr $offset+[size NimbusRelBezierData]]}
    	default {error [format {unknown Nimbus command %d at %04xh:%04xh} $command $seg $offset]}]
    return $offset
}]
