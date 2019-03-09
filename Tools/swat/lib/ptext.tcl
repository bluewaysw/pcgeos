#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library -- Text Object
# FILE:		ptext.tcl
# AUTHOR:	Tony Requist, November 15, 1989
#
# COMMANDS:
#	Name			Description
#	----			-----------
#   	ptext    	    	Print a text object
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	tony	11/15		Initial revision
#
# DESCRIPTION:
#	This file contains TCL routines to print out text objects
#
#	$Id: ptext.tcl,v 3.6 91/01/17 16:36:01 tony Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

[defdsubr ptext {args} output|ui
{ptext [-lsrt] ADDR - Prints out a text object
	-c: print out the characters (the default)
	-e: print out elements in addition to runs
	-l: print out line and field structures
	-s: print out style structures
	-r: print out ruler structures
	-g: print out graphics structures
	-t: print out type structures
}
{
    var default 1
    var chars 0
    var lines 0
    var elements 0
    var styles 0
    var rulers 0
    var graphics 0
    var types 0
    if {[string m [index $args 0] -*]} {
	#
	# Gave us some flags
	#
	foreach i [explode [index $args 0]] {
	    [case $i in
		c {var chars 1 default 0}
		e {var elements 1}
		l {var lines 1 default 0}
		s {var styles 1 default 0}
		r {var rulers 1 default 0}
		g {var graphics 1 default 0}
		t {var types 1 default 0}]
	}
	var args [cdr $args]
    }
    if {[length $args] == 0} {
	var address *ds:si
    } else {
	var address [index $args 0]
    }

    var addr [addr-parse $address]
    var seg [handle segment [index $addr 0]]
    var off [index $addr 1]
    echo [format {Text object: *%04xh:%04xh} $seg $off]

    var VTI [expr $off+[value fetch $seg:$off.ui::Vis_offset]]
    var instance [value fetch $seg:$VTI ui::VisTextInstance]

    if {$default || $chars} {
	echo -n [format {Text at %04x, } [field $instance VTI_text]]
	if {[printString $seg $instance 0 256]} {
	    echo {<etc>}
    	}
    }

    #
    # Print lines
    #
    if {$lines} {
	var lineChunk	  [field $instance VTI_lines]
	var lineChunkAddr [value fetch $seg:$lineChunk word]
	var lineChunkSize [expr [value fetch $seg:$lineChunkAddr-2 word]-2]
	var lineOffset	  0
	var lineInfoSize  [type size [sym find type LineInfo]]

	do {
	    [print-text-line $seg $instance $lineOffset]
	    var lineOffset [expr $lineOffset+$lineInfoSize]
	} while {$lineOffset<$lineChunkSize}
	echo
    }

    #
    # Print style runs
    #
    if {$styles} {
	if {[field [field $instance VTI_typeFlags] VTTF_MULTIPLE_STYLES]} {
	    echo [format {Multiple styles:}]
	    var soff [value fetch $seg:[field $instance VTI_styleRuns]
								[type word]]
	    var runa [value fetch $seg:$soff ui::RunArray]
	    var ptr [expr $soff+10]
	    echo [format {Runs at *%04x:} [field $instance VTI_styleRuns]]
	    do {
		var rae [value fetch $seg:$ptr ui::RunArrayElement]
		echo [format {\tPosition = %04x, token = %d}
			    [field $rae RAE_position] [field $rae RAE_token]]
		var ptr [expr $ptr+4]
	    } while {[field $rae RAE_position] != 0x8000}
	    if {$elements} {
		var ehan [field $runa RA_elementArrayHandle]
		if {$ehan == 0} {
		    var eseg $seg
		} else {
		    var eseg [handle segment [handle lookup $ehan]]
		}
		var chunk [field $runa RA_elementArrayChunk]
		var ptr [value fetch $eseg:$chunk [type word]]
		var base $ptr
		var ea [value fetch $eseg:$ptr ui::ElementArray]
		var csz [expr [value fetch $eseg:$ptr-2 [type word]]-2]
		echo [format {Elements at *%04x, chunk size %d, %d styles:}
		    $chunk $csz
		    [expr {($csz-[type size [symbol find
						type ui::ElementArray]])/
		    [type size [symbol find type ui::VisTextStyle]]} ]]
		echo {***** Element array header *****}
		print ui::ElementArray $eseg:$ptr
		var ptr [expr $ptr+[type size [symbol find
						type ui::ElementArray]]]
		for {var i 0} {$i != [field $ea EA_count]} {var i [expr $i+1]} {
		    echo [format {***** Element token %d *****}
							[expr $ptr-$base]]
		    print ui::VisTextStyle $eseg:$ptr
		    var ptr [expr $ptr+[type size
					[symbol find type ui::VisTextStyle]]]
		}
	    }
	} else {
	    if {[field [field $instance VTI_typeFlags] VTTF_DEFAULT_STYLE]} {
		echo [format {Single style (stored as default, %04x):}
				    [field $instance VTI_styleRuns]]
		precord ui::VisTextDefaultStyle [field $instance VTI_styleRuns]
	    } else {
		echo [format {Single style (stored in chunk, %04x):}
				    [field $instance VTI_styleRuns]]
		print ui::VisTextStyle *$seg:[field $instance VTI_styleRuns]
	    }
	}
	echo
    }
    #
    # Print ruler runs
    #
    if {$rulers} {
	if {[field [field $instance VTI_typeFlags] VTTF_MULTIPLE_RULERS]} {
	    echo [format {Multiple rulers:}]
	    var soff [value fetch $seg:[field $instance VTI_rulerRuns]
								[type word]]
	    var runa [value fetch $seg:$soff ui::RunArray]
	    var ptr [expr $soff+10]
	    echo [format {Runs at *%04x:} [field $instance VTI_rulerRuns]]
	    do {
		var rae [value fetch $seg:$ptr ui::RunArrayElement]
    	    	var taddr (*$seg:[field $instance VTI_text])+[field
    	    	    	    	    	    	    	    $rae RAE_position]
		echo -n [format
    	    	    {    Position = %04x, token = %3d, prev = %s, text = "}
			    [field $rae RAE_position] [field $rae RAE_token]
    	    	    	    [prenum Chars [value fetch $taddr-1 byte]]]
    	    	printchars $taddr 12
    	    	echo "
		var ptr [expr $ptr+4]
	    } while {[field $rae RAE_position] != 0x8000}
	    if {$elements} {
		var ehan [field $runa RA_elementArrayHandle]
		if {$ehan == 0} {
		    var eseg $seg
		} else {
		    var eseg [handle segment [handle lookup $ehan]]
		}
		var chunk [field $runa RA_elementArrayChunk]
		var ptr [value fetch $eseg:$chunk [type word]]
		var base $ptr
		var ea [value fetch $eseg:$ptr ui::ElementArray]
		var csz [expr [value fetch $eseg:$ptr-2 [type word]]-2]
		echo [format {Elements at *%04x, chunk size %d:} $chunk $csz]
		echo {***** Element array header *****}
		print ui::ElementArray $eseg:$ptr
		var ptr [expr $ptr+[type size [symbol find
						type ui::ElementArray]]]
		var csz [expr $csz-[type size [symbol find
						type ui::ElementArray]]]
		for {var i 0} {$i != [field $ea EA_count]} {var i [expr $i+1]} {
		    echo [format {***** Element at offset %d, token %d *****}
			[expr $ptr-$base]
			[value fetch $eseg:$ptr.ui::VTR_token]]
		    print ui::VisTextRuler $eseg:$ptr
		    var numTabs [value fetch $eseg:$ptr.ui::VTR_numberOfTabs]
		    if {$numTabs > 0} {
			var tptr [expr $ptr+[type size
					[symbol find type ui::VisTextRuler]]]
			for {var j 0} {$j != $numTabs} {var j [expr $j+1]} {
			    print ui::Tab $eseg:$tptr
			    var tptr [expr $tptr+[type size
					    [symbol find type ui::Tab]]]
			}
		    }
		    var rsz [expr {[type size [symbol find
						type ui::VisTextRuler]]+
			$numTabs*[type size [symbol find type ui::Tab]]}]
		    var ptr [expr $ptr+$rsz]
		    var csz [expr $csz-$rsz]
		}
		if {$csz != 0} {
		    echo [format {ERROR!  Bytes left = %d} $csz]
		}
	    }
	} else {
	    if {[field [field $instance VTI_typeFlags]
						VTTF_DEFAULT_RULER]} {
		echo [format {Single ruler (stored as default, %04x):}
				    [field $instance VTI_rulerRuns]]
		precord ui::VisTextDefaultRuler [field $instance VTI_rulerRuns]
	    } else {
		echo [format {Single ruler (stored in chunk, %04x):}
				    [field $instance VTI_rulerRuns]]
		print ui::VisTextRuler *$seg:[field $instance VTI_rulerRuns]
	    }
	} 
	echo
    }
    #
    # Print graphics runs
    #
    if {$graphics} {
	if {[field $instance VTI_gstringRuns] != 0} {
	    echo [format {graphics:}]
	    var soff [value fetch $seg:[field $instance VTI_gstringRuns]
								[type word]]
	    var runa [value fetch $seg:$soff ui::RunArray]
	    var ptr [expr $soff+10]
	    echo [format {Runs at *%04x:} [field $instance VTI_gstringRuns]]
	    do {
		var rae [value fetch $seg:$ptr ui::RunArrayElement]
		echo [format {\tPosition = %04x, token = %d}
			    [field $rae RAE_position] [field $rae RAE_token]]
		var ptr [expr $ptr+4]
	    } while {[field $rae RAE_position] != 0x8000}
	    if {$elements} {
		var ehan [field $runa RA_elementArrayHandle]
		if {$ehan == 0} {
		    var eseg $seg
		} else {
		    var eseg [handle segment [handle lookup $ehan]]
		}
		var chunk [field $runa RA_elementArrayChunk]
		var ptr [value fetch $eseg:$chunk [type word]]
		var base $ptr
		var ea [value fetch $eseg:$ptr ui::ElementArray]
		var csz [expr [value fetch $eseg:$ptr-2 [type word]]-2]
		echo [format {Elements at *%04x, chunk size %d, %d graphics:}
		    $chunk $csz
		    [expr {($csz-[type size [symbol find
						type ui::ElementArray]])/
		    [type size [symbol find type ui::VisTextGraphic]]} ]]
		echo {***** Element array header *****}
		print ui::ElementArray $eseg:$ptr
		var ptr [expr $ptr+[type size [symbol find
						type ui::ElementArray]]]
		for {var i 0} {$i != [field $ea EA_count]} {var i [expr $i+1]} {
		    echo [format {***** Element token %d *****}
							[expr $ptr-$base]]
		    print ui::VisTextGraphic $eseg:$ptr
		    var ptr [expr $ptr+[type size
					[symbol find type ui::VisTextGraphic]]]
		}
	    }
	} else {
	    echo No graphics
	}
    }
    #
    # Print type runs
    #
    if {$types} {
	if {[field [field $instance VTI_typeFlags] VTTF_MULTIPLE_TYPES]} {
	    echo [format {Multiple types:}]
	    var soff [value fetch $seg:[field $instance VTI_typeRuns]
								[type word]]
	    var runa [value fetch $seg:$soff ui::RunArray]
	    var ptr [expr $soff+10]
	    echo [format {Runs at *%04x:} [field $instance VTI_typeRuns]]
	    do {
		var rae [value fetch $seg:$ptr ui::RunArrayElement]
		echo [format {\tPosition = %04x, token = %d}
			    [field $rae RAE_position] [field $rae RAE_token]]
		var ptr [expr $ptr+4]
	    } while {[field $rae RAE_position] != 0x8000}
	} else {
	    echo [format {Single type = %04x} [field $instance VTI_typeRuns]]
	} 
	echo
    }
}]

[defsubr printchars {addr count} {
        for {var i 0} {$i < $count} {var i [expr $i+1]} {
    	var ch [value fetch ($addr)+$i byte]
        if {$ch >= 32 && $ch < 127} {
            echo -n [format %c $ch]
        } else {
    	    echo -n .
        }
    }
}]

[defdsubr pline {args} output|ui
{pline [LINE] [ADDR] - Prints out a line of a text object
    if there is a single argument it is assumed to be the line.
    Default for the line is the value in 'di'.
    Default for the address is '*ds:si'.
}
{
    if {[length $args] == 0} {
	var lineOffset [read-reg di]
	var address *ds:si
    } elif {[length $args] == 1} {
	var lineOffset [index $args 0]
	var address *ds:si
    } elif {[length $args] == 2} {
	var lineOffset [index $args 0]
	var address    [index $args 1]
    } else {
        echo {usage: pline [line] [addr]}
	return
    }

    var addr [addr-parse $address]
    var seg [handle segment [index $addr 0]]
    var off [index $addr 1]

    var VTI [expr $off+[value fetch $seg:$off.ui::Vis_offset]]
    var instance [value fetch $seg:$VTI ui::VisTextInstance]
    
    print-text-line $seg $instance $lineOffset
}]


[defdsubr pfield {args} output|ui
{pfield [FIELD] [ADDR] - Prints out a field of a text object
    if there is a single argument it is assumed to be the field.
    Default for the field is the value in 'bx'.
    Default for the address is '*ds:si'.
}
{
    if {[length $args] == 0} {
	var fieldOffset [read-reg bx]
	var address *ds:si
    } elif {[length $args] == 1} {
	var fieldOffset [index $args 0]
	var address *ds:si
    } elif {[length $args] == 2} {
	var fieldOffset [index $args 0]
	var address     [index $args 1]
    } else {
        echo {usage: pfield [field] [addr]}
	return
    }

    var addr [addr-parse $address]
    var seg [handle segment [index $addr 0]]
    var off [index $addr 1]

    var VTI [expr $off+[value fetch $seg:$off.ui::Vis_offset]]
    var instance [value fetch $seg:$VTI ui::VisTextInstance]
    
    #
    # Need to find the line which contains this field.
    #
    var lineChunkAddr  [value fetch $seg:[field $instance VTI_lines]  word]
    var lineChunkSize  [expr [value fetch $seg:$lineChunkAddr-2 word]-2]
    var fieldChunkAddr [value fetch $seg:[field $instance VTI_fields] word]
    var lineInfoSize   [type size [sym find type LineInfo]]

    var lineOffset 0
    var foundLine 0
    do {
        [var aFieldOffset
	    [value fetch $seg:$lineChunkAddr+$lineOffset.LI_fieldInfo word]]
    	do {
    	    if {$aFieldOffset == $fieldOffset} {
    	        var foundLine -1
	    } else {
	        [var aFieldOffset
		    [value fetch $seg:$fieldChunkAddr+$aFieldOffset.FI_next
		    word]]
	    }
	} while {!$foundLine && $aFieldOffset!=0xffff}
	var lineOffset [expr $lineOffset+$lineInfoSize]
    } while {!$foundLine && $lineOffset < $lineChunkSize}

    if {$lineOffset >= $lineChunkSize} {
    	echo {pfield: Can't find that field in any line.}
    } else {
        print-text-field $seg $instance $lineOffset $fieldOffset
    }
}]

#
# print-text-line
#   Print a line in a meaningful fashion.
# Line 0000:
#   height = 12345.67, baseline = 12345, adjustment = 12345
#   Flags = {LF_xxx, LF_xxx, etc}
#
[defsubr print-text-line {seg instance lineOffset}
{
    var lineChunkAddr  [value fetch $seg:[field $instance VTI_lines]  word]
    var fieldChunkAddr [value fetch $seg:[field $instance VTI_fields] word]
    
    var lineinfo [value fetch $seg:$lineChunkAddr+$lineOffset LineInfo]
    
    echo [format {Line 0x%04x: } $lineOffset]
    var adjustment [field [field $lineinfo LI_adjustment] LA_VALUE]
    var needsCalc  [field [field $lineinfo LI_adjustment] LA_NEEDS_CALC_BIT]
    echo [format {  height = %.3f, baseline = %5d, adjustment = %5d}
    	[convWBFixed [field $lineinfo LI_hgt]]
	[field $lineinfo LI_blo]
	$adjustment]
    echo -n {  Flags = }
    if {$needsCalc} {
        echo -n {NEEDSCALC, }
    }
    [precord LineFlags
    	    [value fetch $seg:$lineChunkAddr+$lineOffset.LI_flags byte] 1]

    var fieldOffset [field $lineinfo LI_fieldInfo]
    do {
        print-text-field $seg $instance $lineOffset $fieldOffset
	var fieldOffset [value fetch $seg:$fieldChunkAddr+$fieldOffset.FI_next [type word]]
    } while {$fieldOffset!=0xffff}
}]

#
# print-text-field seg instance lineOffset fieldOffset
#   Print information about a field in this format:
#
# Field XXXX: "This is the text on this field"
#   start = 1234, position = 12345, width = 12345, spacePad = 12345.67
#   Tab <12345, TT_ANCHORED, TL_LINE, 'a', lw=1, ls=1, al=12345, ar=12345>
#   Flags = {FF_xxx, FF_xxx, etc}
#
[defsubr print-text-field {seg instance lineOffset fieldOffset}
{
    var fieldChunk     [field $instance VTI_fields]
    var fieldChunkAddr [value fetch $seg:$fieldChunk word]
    var theField       [value fetch $seg:$fieldChunkAddr+$fieldOffset FieldInfo]

    echo -n [format { Field 0x%4x: } $fieldOffset]
    
    [printString $seg $instance [field $theField FI_start]
    	[charsInField $seg $instance $lineOffset $fieldOffset $theField]]

    echo [format {  start = %4x, position = %5d, width = %5d, spacePad = %.3f}
    	    	[field $theField FI_start]
		[field $theField FI_position]
		[field $theField FI_width]
		[convWBFixed [field $theField FI_spacePad]]]

    var theTab [field $theField FI_tab]
    var tabType [type emap [field $theTab TR_TYPE]
    	    	    	   [sym find type TabReferenceType]]
    var tabNum [field $theTab TR_REF_NUMBER]
    if {[string c $tabType TRT_RULER]} {
        # Not a ruler reference, must be TRT_OTHER
	var tabRef OTHER_INTRINSIC_TAB
    } else {
	# Is a ruler reference.
        var tabRef RULER_TAB_AT_LEFT_MARGIN
    }
    if {$tabNum != 0x7f} {
        var tabRef $tabNum
    }
    echo [format {  TabReference <%s, %s>} $tabType $tabRef]
    
    echo -n {  Flags = }
    [precord FieldFlags
    	   [value fetch $seg:$fieldChunkAddr+$fieldOffset.FI_flags byte] 1]
}]

#
# printString seg instance start nchars
#   Print the text in an instance but only so many characters.
#
[defsubr printString {seg instance start nchars}
{
    var ptr [value fetch $seg:[field $instance VTI_text] [type word]]
    var ptr [expr $ptr+$start]
    #
    # Print characters as we got them w/no intervening commas -- use
    # format to take care of \\, \{ and \} things. All other things are
    # printed as returned by value...
    #
    echo -n {"}
    do {
	var ch [value fetch $seg:$ptr [type char]]
	if {[string c $ch \\000]} {
	    if {[string m $ch {\\[\{\}\\]}]} {
		echo -n [format $ch]
	    } else {
		echo -n $ch
	    }
	}
	var ptr [expr $ptr+1]
	var nchars [expr $nchars-1]
    } while {[expr ($nchars!=0)&&[string c $ch \\000]]}
    echo {"}
    if {$nchars==0} {
        return -1
    } else {
    	return 0
    }
}]

#
# charsInField seg instance lineOffset fieldOffset theField
#   Get the number of characters in a field.
#
[defsubr charsInField {seg instance lineOffset fieldOffset theField}
{
    var nextField [field $theField FI_next]

    if {$nextField!=0xffff} {
    	#
	# There is a next field, get it's start.
	#
	var nextFieldStart [fieldStart $seg $instance $nextField]
    } else {
        #
	# There is no next field, try the next line.
	#
	var lineChunk	  [field $instance VTI_lines]
	var lineChunkAddr [value fetch $seg:$lineChunk word]
	var lineChunkSize [expr [value fetch $seg:$lineChunkAddr-2 word]-2]
	
	var lineOffset [expr $lineOffset+[type size [sym find type LineInfo]]]

	if {$lineOffset >= $lineChunkSize} {
	    #
	    # There is no next line, use the size of the text.
	    #
	    var textAddr [value fetch $seg:[field $instance VTI_text] word]
	    var nextFieldStart [expr [value fetch $seg:$textAddr-2 word]-2]
        } else {
	    #
	    # There is a next line.
	    #
	    var nextLine [value fetch $seg:$lineChunkAddr+$lineOffset LineInfo]
	    var nextField [field $nextLine LI_fieldInfo]
	    var nextFieldStart [fieldStart $seg $instance $nextField]
	}
    }
    return [expr $nextFieldStart-[field $theField FI_start]]
}]

#
# fieldStart
#   Return the start of a field.
#
[defsubr fieldStart {seg instance fieldOffset}
{
    var fieldChunkAddr [value fetch $seg:[field $instance VTI_fields] word]
    
    return [value fetch $seg:$fieldChunkAddr+$fieldOffset.FI_start]
}]

#
#	For VisTextPtr performance checking
#
[defsubr vtpstart {} {
    assign ui::ptrCount 0
    assign ui::selCount 0
    echo {Counts zeroed...}
}]

[defsubr vtpdisp {} {
    var ptrCount [value fetch ui::ptrCount [type word]]
    var selCount [value fetch ui::selCount [type word]]
    if {$ptrCount == 0} {
       var per 0
    } else {
       var per [expr (1-($selCount/$ptrCount))*100 float]]
    }
    echo -n [format {%d total calls to VisTextPtr, } $ptrCount]
    echo [format {%d calls to ExtendSelection, %.0f%% extra} $selCount $per]
}]

#
# Formatting.
#
[defsubr convBBFixed {param} {
    return [expr [field $param BBF_int]+[field $param BBF_frac]/256 f]
}]

[defsubr convWBFixed {param} {
    return [expr [field $param WBF_int]+[field $param WBF_frac]/256 f]
}]

