
##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
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
#	$Id: nimbus.tcl,v 3.3 90/10/15 23:23:15 gene Exp $
#
###############################################################################

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

[defcommand pnimbit {addr} output
{Prints out a Nimbus bitmap.  Takes one argument, the address of the bitmap.}
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

    pbitmap $bseg:0 $width $height
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

[defcommand tnimbus {} output
{Trace Nimbus character data commands while building character.}
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

[defcommand pnimchar {args} output
{Prints out the Nimbus data for a character in a given font. Takes three
arguments, the character to print, the GEOS font ID, and a list of styles.
 The arguments can either be a numeric constants or GEOS constants.}
{
    #
    # Parse the flags, if any.
    #
    var char [index $args 0]
    var font [index $args 1]
    #
    # Check out the chararcter -- see if it's a numeric constant
    # If it's a chararcter, convert it to a constant.
    #
    if {[catch {eval {expr $char+0}}] != 0} {
        if {[string m $char C_* ]} {
            var pchar [index [addr-parse $char] 1]
    	} else {
    	    [scan $char %c pchar]
    	}
    } else {
        var pchar $char
    }
    #
    # Check out the font -- see if it's a numeric constant
    #
    if {[catch {eval {expr $font+0}}] != 0} {
    	if {[string m $font FONT_* ]} {
    	    var pfont [index [addr-parse $font] 1]
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
    var styles [index $args 2]
    while {![null $styles]} {
    	var s [getbitvalue TextStyles [car $styles]]
    	if {$s != -1} {
    	    var style [expr {$style|$s}]
    	} else {
    	    var style [expr {$style+[index [addr-parse [car $styles]] 1]}]
    	}
    	var styles [cdr $styles]
    }
    var kstyles [expr ([getbitvalue TextStyles ST_UNDERLINE]|[getbitvalue TextStyles ST_STRIKE_THRU])]
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
    	echo {Warning: header block not available -- making some guesses}
    	var first 32
    	var last 255
    	var width {(unknown)}
    	var flags {(unknown)}
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
    precord TextStyles [value fetch $seg:$c_off.ODE_style byte]
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
    echo [format {using data handle = ^h%xh (at 0x%x)} $dhan $dseg]
    var dptr [expr {$dchar*2}]
    echo [format {width = %s (0x%x)} $width $width]
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

[defcommand pnimdata {addr} output
{Prints out the Nimbus data for a character. Takes one argument, the address
of the outline data.}
{
    var	seg	[handle segment [index [addr-parse $addr] 0]]
    var offset	[index [addr-parse $addr] 1]
    var command -1
    #
    # Print the header with the bounds of the data
    #
    print NimbusData $seg:$offset
    var offset [expr {$offset+[size NimbusData]}]
    #
    # Print the number of x-tuples, print them, and advance past them
    #
    var ntuples [value fetch $seg:$offset byte]
    echo [format {#x-tuples = %d} $ntuples]
    var offset [expr $offset+1]
    for {} {$ntuples > 0} {var ntuples [expr $ntuples-1] offset [expr $offset+[size NimbusTuple]]} {
    	print NimbusTuple $seg:$offset
    }
    #
    # Print the number of y-tuples, print them, and advance past them
    #
    var ntuples [value fetch $seg:$offset byte]
    echo [format {#y-tuples = %d} $ntuples]
    var offset [expr $offset+1]
    for {} {$ntuples > 0} {var ntuples [expr $ntuples-1] offset [expr $offset+[size NimbusTuple]]} {
    	print NimbusTuple $seg:$offset
    }
    #
    # Go through the commands and print them out
    #
    while {$command != [index [addr-parse NIMBUS_DONE] 1]} {
    	var command [value fetch $seg:$offset NimbusCommands]
    	var offset [pnimcommand $seg:$offset]
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

[defcommand pnimcommand {addr} output
{Prints out Nimbus data from memory, and advances a ptr appropriately.}
{
    var	seg	[handle segment [index [addr-parse $addr] 0]]
    var offset	[index [addr-parse $addr] 1]

    var command [value fetch $seg:$offset NimbusCommands]
    prenum NimbusCommands $command
    var offset [expr $offset+[size NimbusCommands]]
    [case $command in
	0 {print NimbusMoveData $seg:$offset
    	   var offset [expr $offset+[size NimbusMoveData]]}
	1 {print NimbusLineData $seg:$offset
    	   var offset [expr $offset+[size NimbusLineData]]}
	2 {print NimbusBezierData $seg:$offset
    	   var offset [expr $offset+[size NimbusBezierData]]}
	3 {echo {DONE}}
	5 {print NimbusAccentData $seg:$offset
    	   var offset [expr $offset+[size NimbusAccentData]]}
	6 {print NimbusVertData $seg:$offset
    	   var offset [expr $offset+[size NimbusVertData]]}
	7 {print NimbusHorizData $seg:$offset
    	   var offset [expr $offset+[size NimbusHorizData]]}
	8 {print NimbusRelLineData $seg:$offset
    	   var offset [expr $offset+[size NimbusRelLineData]]}
	9 {print NimbusRelBezierData $seg:$offset
    	   var offset [expr $offset+[size NimbusRelBezierData]]}
    	default {error [format {unknown Nimbus command %d at %xh:%xh} $command $seg $offset]}]
    return $offset
}]
