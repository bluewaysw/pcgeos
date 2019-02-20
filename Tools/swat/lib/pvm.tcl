#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library -- Vis Moniker Printout
# FILE:		pvm.tcl
# AUTHOR:	Andrew Wilson, June 27, 1989
#
# COMMANDS:
#	Name			Description
#	----			-----------
#   	pgs 	    	    	Print a graphics string
#   	pvm 	    	    	Print a vis moniker
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	atw	6/27/89		Initial revision
#	jad	11/4/89		Changed for new graphics string types
#
# DESCRIPTION:
#	This file contains TCL routines to print out VisMonikers and GStrings.
#
#	$Id: pvm.tcl,v 3.11 90/06/12 17:29:50 andrew Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

defsubr pstring addr {
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]

    echo -n "
    [for {var c [value fetch $s:$o [type byte]]}
	 {$c != 0}
	 {var c [value fetch $s:$o [type byte]]}
    {
        echo -n [format %c $c]
        var o [expr $o+1]
    }]
    echo "
}

defsubr pmnemonic addr {
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]

    var c [value fetch $s:$o [type byte]]
    var c [format %d $c]
    if {[string compare $c 255]} then {
       		[echo $c]
       } else {
		[echo no mnemonic]
       }
}

defsubr pvmtext {addr count} {
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]

    echo -n "
    if {$count!=0} then {
	    [for {var c [value fetch $s:$o [type byte]]}
		 {$c != 0 && $count != 0}
		 {var c [value fetch $s:$o [type byte]]}
	    {
		echo -n [format %c $c]
		var o [expr $o+1]
		var count [expr $count-1]
	    }]
    }
    echo "
}

defvar _pgs_size_list nil

#
# Set up to force a fetch of the size list the first time pgs is used after
# a detach.
#
[defsubr pgs-biff-size-list {args}
{
    global _pgs_size_list
    
    var _pgs_size_list nil
}]
defvar _pgs_biff_event nil

# Be sure to evaluate this in the global scope....
uplevel 0 {
    if {[null $_pgs_biff_event]} {
        var _pgs_biff_event [event handle DETACH pgs-biff-size-list]
    }
}

[defdsubr pgs {{address ds:si}} output|ui
{pgs ADDR - Prints out a graphics string.  Assumes ds:si if no address 
 specified.}
{
	echo Graphics String:
	var addr [addr-parse $address]
	var seg [handle segment [index $addr 0]]
	var off [index $addr 1]
	var base $off

# Build an array of the lengths of each gstring element. They are taken straight
# from klib, which says that if the byte has 0x80 or'ed into it, the low 7 bits
# are the offset of the word in the element that contains the size of the data
# for the element (still need to add in 3 for the opcode and the size...)
    	global _pgs_size_list
	if {[null $_pgs_size_list]} {
	    var _pgs_size_list [value fetch klib::PE_SizeTable
	    	   [type make array 
		    [index [addr-parse klib::PE_KernTable-klib::PE_SizeTable] 1]
		    [type byte]]]
    	}

# If at end of gstring, exit
	[for {var element [value fetch $seg:$off [type byte]]
	      var esize  [index $_pgs_size_list $element] } 
	    {($element != 0) && ($esize != 0)}
	    {var element [value fetch $seg:$off [type byte]]
	      var esize  [if {$element > [length $_pgs_size_list]} {expr 0}
	       {index $_pgs_size_list $element}] } 
	{	
		var eltype [prenum GStringElements $element]
		echo -n [format {%04x: } [expr $off-$base]]
# Print out special info for each type
		[case $eltype in
		 GR_DRAW_BITMAP_LPTR {
			echo -n \t $eltype -- (
			pcoord $seg:$off+1 1
			pcoord $seg:$off+3 2
			var chunk [value fetch $seg:$off+5 [type word]]
			var han [value fetch $seg:$off+7 [type word]]
			echo [format {^l%xh:%xh} $han $chunk]
		 }
		 GR_COMMENT {
			echo \t $eltype
		 }
		 GR_ESCAPE {
			var escsize [value fetch $seg:$off+3 [type word]]
			var ecode [value fetch $seg:$off+1 [type word]]
			echo -n \t $eltype {-- }
			echo [format {ESC CODE:0x%x (%d),size=%d} $ecode $ecode $escsize]
		 }
		 GR_DRAW_TEXT_CP {
			var tsize [value fetch $seg:$off+1 [type word]]
			echo -n \t $eltype {-- }
			pvmtext $seg:$off+3 $tsize
		 }
		 GR_DRAW_TEXT {
			var tsize [value fetch $seg:$off+5 [type word]]
			echo -n \t $eltype {-- (}
			pcoord $seg:$off+1 1
			pcoord $seg:$off+3 2
			pvmtext $seg:$off+7 $tsize
		 }
		 GR*ARC|GR*ROUND_RECT {
			echo -n \t $eltype {-- (}
			pcoord $seg:$off+1 1
			pcoord $seg:$off+3 4
			pcoord $seg:$off+5 1
			pcoord $seg:$off+7 4
			pcoord $seg:$off+9 1
			pcoord $seg:$off+11 0
		 }
		 GR*RECT|GR_DRAW_LINE|GR*ELLIPSE|GR*ROUND_RECT_TO|GR*BOUNDS {
			echo -n \t $eltype {-- (}
			pcoord $seg:$off+1 1
			pcoord $seg:$off+3 4
			pcoord $seg:$off+5 1
			pcoord $seg:$off+7 0
		 }
		 GR*MOVE_TO|GR*RECT_TO|GR_DRAW_LINE_TO {
			echo -n \t $eltype {-- (}
			pcoord $seg:$off+1 1
			pcoord $seg:$off+3 0
		 }
		 GR*HLINE|GR*VLINE {
			echo -n \t $eltype {-- (}
			pcoord $seg:$off+1 1
			pcoord $seg:$off+3 4
			pcoord $seg:$off+5 0
		 }
		 GR_SET_FONT {
			echo -n \t $eltype {-- }
			var pfrac [value fetch $seg:$off+1 [type byte]]
			var psize [value fetch $seg:$off+2 [type word]]
			var fontid [value fetch $seg:$off+4 [type word]]
			echo -n [prenum FontIDs $fontid]
			echo [format {, point size = %d, frac = %d} $psize $pfrac]
		 }
		 GR*HLINE*|GR*VLINE*|GR_SET*WIDTH {
			echo -n \t $eltype {-- }
			pcoord $seg:$off+1 3
		 }
		 GR_DRAW_BITMAP {
			echo -n \t $eltype {--(}
			var width [value fetch $seg:$off+7 [type word]]
			var height [value fetch $seg:$off+9 [type word]]
			var compact [value fetch $seg:$off+11 [type byte]]
			var type [value fetch $seg:$off+12 [type byte]]
			var fmt [expr $type&7]
			pcoord $seg:$off+1 1
			pcoord $seg:$off+3 2
			echo -n [format {width=%d,height=%d,} $width $height]
			echo [prenum BMFormat $fmt], [prenum BMCompact $compact]
		 }
		 GR_DRAW_BITMAP_CP {
			echo -n \t $eltype {-- }
			var width [value fetch $seg:$off+3 [type word]]
			var height [value fetch $seg:$off+5 [type word]]
			var compact [value fetch $seg:$off+7 [type byte]]
			var type [value fetch $seg:$off+8 [type byte]]
			var fmt [expr $type&7]
			echo -n [format {width=%d, height=%d, } $width $height]
			echo [prenum BMFormat $fmt], [prenum BMCompact $compact]
		 }
		 GR_SET_DRAW_MODE {
			echo -n \t $eltype {-- }
			var drawmode [value fetch $seg:$off+1 [type byte]]
			echo [prenum DrawModes $drawmode]
		 }
		 GR_SET*COLOR_INDEX {
			echo -n \t $eltype {-- }
			var color [value fetch $seg:$off+1 [type byte]]
			echo [prenum Colors $color]
		 }
		 GR_DRAW_POLY* {
			echo -n \t $eltype {-- }
			var ncoord [value fetch $seg:$off+1 [type word]]
			echo [format {%d coord pairs} $ncoord]
		 }
		 GR_FILL_POLYGON {
			echo -n \t $eltype {-- }
			var frule [value fetch $seg:$off+1 [type byte]]
			var ncoord [value fetch $seg:$off+2 [type word]]
			echo -n [prenum RF_rule $frule]
			echo [format { rule, %d coord pairs} $ncoord]
		 }
		 GR_DRAW_SPLINE {
			echo -n \t $eltype {-- }
			var ncoord [value fetch $seg:$off+2 [type word]]
			echo [format {%d coord pairs} $ncoord]
		 }
		 GR_SET*COLOR {
			echo -n \t $eltype {-- }
			echo -n RGB: 
			var r [value fetch $seg:$off+1 [type byte]]
			var g [value fetch $seg:$off+2 [type byte]]
			var b [value fetch $seg:$off+3 [type byte]]
			echo [format {(%d,%d,%d)} $r $g $b]
		 }
		 GR_SET*JOIN {
			echo -n \t $eltype {-- }
			var ljoin [value fetch $seg:$off+1 [type byte]]
			echo [prenum LineJoins $ljoin]
		 }
		 GR_SET_MITER_LIMIT {
			echo -n \t $eltype {-- }
			pfixed $seg:$off+1 3
		 }
		 GR_SET*MAP {
			echo -n \t $eltype {-- }
			var mmode [value fetch $seg:$off+1 [type byte]]
			echo [prenum MapColorToMono $mmode]
		 }
		 GR_SET_CUSTOM*MASK {
			echo \t $eltype {-- }
		 }
		 GR_SET_CUSTOM*STYLE {
			echo -n \t $eltype {-- }
			var ssize [value fetch $seg:$off+2 [type word]]
			echo [format {%d on/off pairs} $ssize]
		 }
		 GR_SET*MASK {
			echo -n \t $eltype {-- }
			var dmask [value fetch $seg:$off+1 [type byte]]
			echo [prenum DrawMasks $dmask]
		 }
		 GR_SET_LINE_END {
			echo -n \t $eltype {-- }
			var lend [value fetch $seg:$off+1 [type byte]]
			echo [prenum LineEnds $lend]
		 }
		 GR_SET_LINE_STYLE {
			echo -n \t $eltype {-- }
			var lstyle [value fetch $seg:$off+1 [type byte]]
			var sindex [value fetch $seg:$off+2 [type byte]]
			echo -n [prenum LineStyles $lstyle]
			echo [format {, index = %d} $sindex]
		 }
		 GR_APPLY_ROTATION {
			echo -n \t $eltype {-- }
			echo -n {angle=}
			pfixed $seg:$off+1 3
		 }
		 GR_APPLY_SCALE {
			echo -n \t $eltype {-- }
			echo -n {xscale=}
			pfixed $seg:$off+1 1
			echo -n {yscale=}
			pfixed $seg:$off+5 3
		 }
		 GR_APPLY_TRANSLATION {
			echo -n \t $eltype {-- }
			echo -n {xoffset=}
			pfixed $seg:$off+1 1
			echo -n {yoffset=}
			pfixed $seg:$off+5 3
		 }
		 GR_SET_TRANSFORM|GR_APPLY_TRANSFORM {
			echo -n \t $eltype {-- }
			pfixed $seg:$off+1 1
			pfixed $seg:$off+5 1
			pfixed $seg:$off+9 1
			pfixed $seg:$off+13 1
			pfixed $seg:$off+17 1
			pfixed $seg:$off+21 0
		 }
		 GR_SET_LINE_ATTR {
			echo -n \t $eltype {-- }
			var cflag [value fetch $seg:$off+1 [type byte]]
			var r [value fetch $seg:$off+2 [type byte]]
			var g [value fetch $seg:$off+3 [type byte]]
			var b [value fetch $seg:$off+4 [type byte]]
			var cmode [value fetch $seg:$off+5 [type byte]]
			var dmask [value fetch $seg:$off+6 [type byte]]
			var lwidth [value fetch $seg:$off+7 [type word]]
			var lend [value fetch $seg:$off+9 [type byte]]
			var ljoin [value fetch $seg:$off+10 [type byte]]
			if { $cflag == 0x80 } {
			    echo -n RGB: 
			    echo -n [format {(%d,%d,%d),} $r $g $b]
			} else {
			    echo -n COLOR:
			    echo -n [format {%s,} [prenum Colors $r]]
			}
			echo -n [format {%s,} [prenum LineEnds $lend]]
			echo -n [format {%s,} [prenum LineJoins $ljoin]]
			echo -n [format {%s,} [prenum DrawModes $cmode]]
			echo -n [format {%s,} [prenum DrawMasks $dmask]]
			echo [format {width=%d} $lwidth]
		 }
		 GR_SET_AREA_ATTR {
			echo -n \t $eltype {-- (}
			var cflag [value fetch $seg:$off+1 [type byte]]
			var r [value fetch $seg:$off+2 [type byte]]
			var g [value fetch $seg:$off+3 [type byte]]
			var b [value fetch $seg:$off+4 [type byte]]
			var cmode [value fetch $seg:$off+5 [type byte]]
			var dmask [value fetch $seg:$off+6 [type byte]]
			if { $cflag == 0x80 } {
			    echo -n RGB: 
			    echo -n [format {(%d,%d,%d),} $r $g $b]
			} else {
			    echo -n COLOR:
			    echo -n [format {%s,} [prenum Colors $r]]
			}
			echo -n [format {%s,} [prenum DrawModes $cmode]]
			echo [prenum DrawMasks $dmask]
		 }
		 nil {
			echo [format {Bad gstring opcode: %d } $element]
		 }
		 default {
			echo \t $eltype
		}]
		if {$esize >= 0x80} {
		    # Assume count is # bytes
		    var headersize [expr $esize&0x7f]
		    var count [value fetch $seg:$off+$headersize [type word]]
		    # if opcode was POLYLINE, POLYGON or SPLINE, count si #coord
		    [case $eltype in
		    *POLY*|*SPLINE {
			var esize [expr $count*4+$headersize+2 ]
		    }
		    default {
		        var esize [expr $count+$headersize+2]
		    }]
 	    	}
		var off [expr $off+$esize]
		var nextEl [value fetch $seg:$off [type byte]]
		if {$nextEl == 0} {echo \t GR_END_STRING}
	}]
	if {$esize == 0} {echo [format {Bad gstring opcode: %d } $element]}
}]
[defsubr pfixed {addr comma}
{
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]
    var frac [value fetch $s:$o [type word]]
    var intgr [value fetch $s:$o+2 [type short]]
    if {$intgr < 0} then {
	var normfrac [expr $intgr-$frac/65536 float]
    } else {
        var normfrac [expr $intgr+$frac/65536 float]
    }
    echo -n [format {%.4f} $normfrac]
    [case $comma in
     0 {echo {)}}
     1 {echo -n {,}}
     2 {echo -n {) }}
     3 {echo {}}
     default {}]
}]
[defsubr pcoord {addr comma}
{
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]

    var raw [value fetch $s:$o [type short]]

    if {($raw > -16384) && ($raw < 16384)} then {
	var param NONE
    }
    if {($raw >= 16384) && ($raw < 24576)} then {
	var raw [expr $raw-20480]
	var param PARAM_0
    }
    if {($raw >= 24576) && ($raw < 32768)} then {
	var raw [expr $raw-28672]
	var param PARAM_1
    }
    if {($raw >= -32768) && ($raw < -24576)} then {
	var raw [expr $raw+28672]
	var param PARAM_2
    }
    if {($raw >= -24576) && ($raw <= -16384)} then {
	var raw [expr $raw+20480]
	var param PARAM_3
    }

    if {$raw < 0} then {
        echo -n [format {%s%d} $param $raw]
    } else {
	if {[length $param chars]==4} then {
	    echo -n [format {%d} $raw]
	} else {
            echo -n [format {%s+%d} $param $raw]
	}
    }
    [case $comma in
     0 {echo {)}}
     1 {echo -n {,}}
     2 {echo -n {) }}
     3 {echo {}}
     4 {echo -n {, }}
     default {}]
}]
[defsubr pmonlist {seg off}
{
	var sz [value fetch $seg:$off-2 word]
	var listentrysize [type size [symbol find type VisualMonikerListEntry]]
	[for {var sz [value fetch $seg:$off-2 word]}
		{$sz !=2}
		{var sz [expr $sz-$listentrysize]}
	{
		print VisualMonikerListEntry $seg:$off
		var off [expr $off+$listentrysize]
	}]
}]

[defdsubr pvismon {{address *ds:si} {textonly 0}} output|ui
{pvismon [ADDR] - Displays passed VisualMoniker structure}
{

	var addr [addr-parse $address]
# Get segment and offset into separate vars
	var seg [handle segment [index $addr 0]]
	var off [index $addr 1]
# Print associated graphics string
	var type [value fetch $seg:$off.VM_type VisualMonikerTypeByte]

	if {[field $type VMTB_MONIKER_LIST] == 1} then {
		if {$textonly == 0} then {
			echo {Moniker List:}
			pmonlist $seg $off
		} else {
			echo {*** Is Moniker List ***}
		}
	} elif {[field $type VMTB_GSTRING] == 0} then {
		if {$textonly == 0} then {
			print VisualMoniker $seg:$off
			echo -n {TEXT -- }
			pstring $seg:$off.VM_data.VMT_text
			echo -n {MNEMONIC OFFSET -- }
			pmnemonic $seg:$off.VM_data.VMT_mnemonicOffset
		} else {
			pstring $seg:$off.VM_data.VMT_text
		}
	} else {
		if {$textonly == 0} then {
			print VisualMoniker $seg:$off
			pgs $seg:$off.VM_data
		} else {
			echo {*** Is GString ***}
		}
	}
}]

[defdsubr pvm {{address *ds:si} {textonly 0}} output|ui
{pvm [ADDR] - Displays VisualMoniker for the passed object}
{
	var addr [addr-parse $address]
# Get segment and offset into separate vars
	var seg [handle segment [index $addr 0]]
	var off [index $addr 1]
	var gboffset [value fetch $seg:$off.Gen_offset]
	var off [expr $off+$gboffset]
# Print VisMoniker
	var off [value fetch $seg:$off.GI_visMoniker word]
	if {$off == 0} then {
		echo *** No VisMoniker ***
	} else {
		pvismon *$seg:$off $textonly
	}
}]
