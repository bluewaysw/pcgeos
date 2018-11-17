#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
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
#	$Id: ptext.tcl,v 1.32.11.1 97/03/29 11:27:02 canavese Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

require carray-enum chunkarr.tcl
require harray-enum hugearr.tcl
require fmtrecord   print.tcl
require map-file-to-vm-handle   vm.tcl
require fvardata pvardata.tcl
require pvmtext pvm.tcl
require map-db-item-to-addr db.tcl

[defsubr convDWFixed {param} {
    return [expr [field $param DWF_int]+[field $param DWF_frac]/65536 f]
}]

##############################################################################
#				pttrans
##############################################################################
#
# SYNOPSIS:	Print information about a text transfer object
# CALLED BY:	user
# PASS:		args	= List containing:
#   	    	    	    -c	: Print out the characters (default)
#
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 1/29/92	Initial Revision
#
##############################################################################
[defcommand pttrans {args} lib_app_driver.text
{pttrans [-args] FILE BLOCK - Prints out a text transfer item
}
{
    while {[string m [index $args 0] -*]} {
	#
	# Gave us some flags
	#
    	var arg [range [index $args 0] 1 end chars]
    	while {![null $arg]} {
	    [case [range $arg 0 0 chars] in
		e {var elements 1}
	    ]
    	    if {![null $arg]} {
    	    	var arg [range $arg 1 end chars]
    	    }
    	}
	var args [cdr $args]
    }
    if {[length $args] != 2} {
	var file [read-reg bx]
    	var block [read-reg ax]
    } else {
	var file [index $args 0]
    	var block [index $args 1]
    }
    echo [format {Information for text transfer item ^v%04xh:%04xh}
    	    	 $file $block]
    var header [value fetch ^v$file:$block TextTransferBlockHeader]
    #
    # Text info
    #
    var textArray [expr [field $header TTBH_text]>>16]
    echo [format {Text at ^v%04xh:%04xh:} $file $textArray]
    [harray-enum-raw $file $textArray pttrans-chars 0 {}]
}]

#
# subroutine to print the characters in the huge array

[defsubr pttrans-chars {elNum text count extra}
{
    echo [format {Block at %s, count is %d} $text $count]
    bytes $text $count
    # pstring $text $count
    return 0
}]

##############################################################################
#				ptext
##############################################################################
#
# SYNOPSIS:	Print information about a text object.
# CALLED BY:	user
# PASS:		args	= List containing:
#   	    	    	    -c	: Print out the characters (default)
#   	    	    	    -e	: Print elements in additions to runs
#   	    	    	    -l	: Print out line and field structures
#   	    	    	    -s	: Print out character-attribute structures
#   	    	    	    -r	: Print out paragraph-attribute structures
#   	    	    	    -g	: Print out graphic structures
#   	    	    	    -t	: Print out type structures
#   	    	    	    -R	: Print out region structures
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 1/29/92	Initial Revision
#
##############################################################################
[defcommand ptext {args} lib_app_driver.text
{Usage:
    ptext [<options>] [<addr>]

Examples:
    "ptext"	    	    	Prints the text in the object for the method
				being executed in the current stack frame

Synopsis:
    prints out the text and related structures for a text object.

Notes:
    * Possible options (more than one may be given):
	-e: print out elements in addition to runs
	-l: print out line and field structures
	-c: print out char attr structures
	-p: print out para attr structures
	-g: print out graphics structures
	-t: print out type structures
	-s: print out style structures
	-r: print out region structures
    	-N: print out associated names
    	-E: limit printout to just the elements of whatever arrays are
	    requested. Do not attempt to print out associated text.
    	-f<field> print out given field of each element (default is meta part)
    	-R: print full region descriptions

See also:
    plines, ptrange
}
{
    global geos-release

    if {${geos-release} < 2} {
        eval [concat oldptext $args]
    	return 0
    }

    var default 1
    var chars 0
    var lines 0
    var elements 0
    var charAttrs 0
    var paraAttrs 0
    var styles 0
    var graphics 0
    var types 0
    var regions 0
    var names 0
    var elementsOnly 0
    var fieldToPrint {}
    var startPos 0
    while {[string m [index $args 0] -*]} {
	#
	# Gave us some flags
	#
    	var arg [range [index $args 0] 1 end chars]
    	while {![null $arg]} {
	    [case [index $arg 0 char] in
		e {var elements 1}
		E {var elements 1 elementsOnly 1}
		l {var lines 1 default 0}
		c {var charAttrs 1 default 0}
		p {var paraAttrs 1 default 0}
		r {var regions 1 printFullRegions 0 default 0}
		R {var regions 1 printFullRegions 1 default 0}
    	    	s {var styles 1 default 0}
		g {var graphics 1 default 0}
		t {var types 1 default 0}
    	    	N {var names 1 default 0}
    	    	f {
    	    	    var fieldToPrint [range $arg 1 end chars]
    	    	    if {[null $fieldToPrint]} { var fieldToPrint VTCA_meta }
    	    	    var arg {}
    	    	  }
		S {
		    var startPos [getvalue [range $arg 1 end char]]
		    var arg {}
    	    	}
	    ]
    	    var arg [range $arg 1 end chars]
    	}
	var args [cdr $args]
    }
    if {[length $args] == 0} {
    	# use appropriate default, based on language of current function
	var address [addr-with-obj-flag {}]
    } else {
	var address [index $args 0]
    }

    var addr	[addr-preprocess $address seg off]
    echo [format {Text object: *%s:%04xh} $seg $off]

    var VTI 	 [expr $off+[value fetch $seg:$off.ui::Vis_offset]]
    var instance [value fetch $seg:$VTI text::VisTextInstance]

    #
    # If the object is a large object, figure the file-handle once
    # so we can reuse the value
    #
    var isLarge 0
    if {[field [field $instance VTI_storageFlags] VTSF_LARGE]} {
    	var file [text-object-get-file $seg $instance]
	var isLarge 1
    }

    if {$default || $chars} {
    	var textArray [field $instance VTI_text]

        if {$isLarge} {
	    #
	    # Large object
	    #
	    echo -n [format {Text in huge-array ^v%04xh:%04xh, }
    	    	    	    	$file $textArray]
	    echo -n {"}
	   [harray-enum-raw $file $textArray print-chars 0
		       [list 256 $seg $instance $startPos]]
	    echo {"}
	} else {
	    #
	    # Small object
	    #
	    echo -n [format {Text at %04xh, } $textArray]
	    if {[printString $seg $instance 0 256]} {
	    	echo {<etc>}
    	    }
	}
    }

#############################################################################
#			     Print lines
#############################################################################
    if {$lines} {
	print-lines $seg $instance $startPos
	echo
    }

#
# Runs are interesting... The runs themselves are easy enough to print. They
# are always contained in either a chunk-array or a huge-array.
#
# The problem is with the elements. They can be stored in either:
#   - ChunkArray in the same block as the object
#   - ChunkArray in vm-block where the vm-block handle is the VM user-id
#     of the block contaiing the runs.
#

    var storageFlags [field $instance VTI_storageFlags]

#############################################################################
#			 Print char attr runs
#############################################################################
    if {$charAttrs} {
	var charAttrRuns [field $instance VTI_charAttrRuns]

	if {[field $storageFlags VTSF_MULTIPLE_CHAR_ATTRS]} {
	    echo [format {Multiple char attrs:}]
    	    var elArr [print-run-array $seg $off $charAttrRuns $instance
    	    	    	    	    print-char-text-callback $elementsOnly
				    $startPos]

	    if {$elements} {
    	    	if {[null $fieldToPrint]} {
		    var args -ttext::VisTextCharAttr
		    [pcarray -E -htext::TextElementArrayHeader
				-ttext::VisTextCharAttr
    	    	    	    	$elArr]
    	    	} else {
		    [pcarray -E -htext::TextElementArrayHeader
		    	    	-f$fieldToPrint
				$elArr]
    	    	}
		
	    }
	} else {
	    if {[field $storageFlags VTSF_DEFAULT_CHAR_ATTR]} {
		echo [format {Single char attr (stored as default, %04xh):}
				    $charAttrRuns]
		precord text::VisTextDefaultCharAttr $charAttrRuns
	    } else {
		echo [format {Single char attr (stored in chunk, %04xh):}
				    $charAttrRuns]
		_print text::VisTextCharAttr *$seg:$charAttrRuns
	    }
	}
	echo
    }

#############################################################################
#			 Print para attr runs
#############################################################################
    if {$paraAttrs} {
	var paraAttrRuns [field $instance VTI_paraAttrRuns]

	if {[field $storageFlags VTSF_MULTIPLE_PARA_ATTRS]} {
	    echo [format {Multiple para attrs:}]
    	    var elArr [print-run-array $seg $off $paraAttrRuns
    	    	    	 $instance print-para-text-callback $elementsOnly
			 $startPos]
	    if {$elements} {
    	    	echo [format {Elements at %s} $elArr]
    	    	if {[null $fieldToPrint]} {
	    	    [pcarray -E -htext::TextElementArrayHeader
				-ttext::VisTextParaAttr -TTab
    	    	    	    	$elArr]
    	    	} else {
	    	    [pcarray -E -htext::TextElementArrayHeader 
    	    	    	    	-f$fieldToPrint
		    	    	$elArr]
    	    	}
	    }
	    
	} else {
	    if {[field $storageFlags VTSF_DEFAULT_PARA_ATTR]} {
		echo [format {Single para attr (stored as default, %04xh):}
				    $paraAttrRuns]
		precord text::VisTextDefaultParaAttr $paraAttrRuns
	    } else {
		echo [format {Single para attr (stored in chunk, %04xh):}
				    $paraAttrRuns]
		_print text::VisTextParaAttr *$seg:$paraAttrRuns
	    }
	} 
	echo
    }

#############################################################################
#			   Print styles
#############################################################################
    if {$styles} {
	if {![field $storageFlags VTSF_STYLES]} {
	    echo No style array
	} else {
    	    var styleArray [get-style-array $seg $off $instance]
    	    if {[null $styleArray]} {
    	    	echo {No Style var data ???}
    	    } else {
    	    	echo [format {Style array at %s} $styleArray]
    	    	carray-enum $styleArray print-one-style {}
    	    }
    	}
    }

#############################################################################
#			 Print graphics runs
#############################################################################
    if {$graphics} {
	if {![field $storageFlags VTSF_GRAPHICS]} {
	    echo No graphics array
	} else {
	    var rchunk [fvardata text::ATTR_VIS_TEXT_GRAPHIC_RUNS $seg:$off]
	    if {[null $rchunk]} {
	    	var rchunk [fvardata ui::ATTR_GEN_TEXT_GRAPHIC_RUNS $seg:$off]
    	    }
	    if {![null $rchunk]} {
		echo [format {graphics:}]
		var soff [index $rchunk 1]
		var elArr [print-run-array $seg $off $soff
    	    	    	    	    	    $instance {} $elementsOnly
					    $startPos]

		if {$elements} {
		    if {[null $fieldToPrint]} {
			[pcarray -E -htext::TextElementArrayHeader
				    -ttext::VisTextGraphic
				    $elArr]
		    } else {
			[pcarray -E -htext::TextElementArrayHeader 
				    -f$fieldToPrint
				    $elArr]
		    }
		}
    	    }
    	}
    }

#############################################################################
#			   Print type runs
#############################################################################
    if {$types} {
	if {![field $storageFlags VTSF_TYPES]} {
	    echo No type array
	} else {
	    var rchunk [fvardata text::ATTR_VIS_TEXT_TYPE_RUNS $seg:$off]
	    if {[null $rchunk]} {
	    	var rchunk [fvardata ui::ATTR_GEN_TEXT_TYPE_RUNS $seg:$off]
    	    }
	    if {![null $rchunk]} {
		echo [format {types:}]
		var soff [index $rchunk 1]
		var elArr [print-run-array $seg $off $soff
    	    	    	    	    	    $instance {} $elementsOnly
					    $startPos]

		if {$elements} {
		    if {[null $fieldToPrint]} {
			[pcarray -E -htext::TextElementArrayHeader
				    -ttext::VisTextType
				    $elArr]
		    } else {
			[pcarray -E -htext::TextElementArrayHeader 
				    -f$fieldToPrint
				    $elArr]
		    }
		}
    	    }
    	}
    }

#############################################################################
#			   Print regions
#############################################################################
    if {$regions} {
	var rchunk [value fetch $seg:$VTI.text::VLTI_regionArray [type word]]
	if {[null $rchunk]} {
	    echo No regions
	} else {
	    [carray-enum *$seg:$rchunk
    	    	print-one-region [list $seg $instance $file $printFullRegions]]
	}
    }
#############################################################################
#			   Print names
#############################################################################
    if {$names} {
	
	var rchunk [fvardata text::ATTR_VIS_TEXT_NAME_ARRAY $seg:$off]
	if {[null $rchunk]} {
	    echo No name array
	} else {
	    var rchunk [index $rchunk 1]
    	    if {[field [field $instance VTI_storageFlags] VTSF_LARGE]} {
    	    	echo {names in VM block}
    		var file [text-object-get-file $seg $instance]
    		ensure-vm-block-resident $file $rchunk
    	    	var chunk [type size [sym find type LMemBlockHeader]]
    	    	pcarray -tVisTextNameArrayElement -N *(^v$file:$rchunk):$chunk
    	    } else {
    	    	echo {names in chunk}
    	    	var count [value fetch *$seg:$rchunk.CAH_count word]
    	    	if {$count == 0} {
    	    	    echo No names in name array
    	    	} else {
    	    	    pcarray -tVisTextNameArrayElement -N *$seg:$rchunk
    	    	}
    	    }
	}
    }
}]

##############################################################################
#				plines
##############################################################################
#
# SYNOPSIS:	Print lines from a text object.
# CALLED BY:	user
# PASS:	    	start	- First line to print
#   	    	end 	- Last line to pring
#   optional	obj 	- Address expression of the object to print from
#   	    	    	  Defaults to *ds:si
#
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	12/ 9/92	Initial Revision
#
##############################################################################
[defcommand plines {start {obj *ds:si}} lib_app_driver.text
{Usage:
    plines start [obj]

Examples:
    "plines 12"	    	    Print lines starting at line 12
    "plines 12 ^lcx:dx"	    Print lines starting at line 12 of object ^lcx:dx

Synopsis:
    Print information about the lines in a text object.
    
Notes:
    WARNING: The line-starts printed are *not* correct.

See also:
    ptext
}
{
    #
    # Parse the address
    #
    var addr	[addr-parse $obj]
    var seg 	[handle segment [index $addr 0]]
    var off 	[index $addr 1]

    #
    # Fetch the instance 
    #
    var VTI 	 [expr $off+[value fetch $seg:$off.ui::Vis_offset]]
    var instance [value fetch $seg:$VTI text::VisTextInstance]

    var lineArray [field $instance VTI_lines]
	
    #
    # Using wonderful dynamic inheritance we can supply the offset to the
    # line start and get it updated as each line is drawn.
    #
    global pl_lineStart
    var pl_lineStart 0
    if {[field [field $instance VTI_storageFlags] VTSF_LARGE]} {
    	#
	# Large text object.
	#
	var file [text-object-get-file $seg $instance]
	[harray-enum-raw $file $lineArray print-one-line $start
    	    	    [list $seg $instance 0 [symbol find type geos::LineInfo]]]
    } else {
    	#
	# Small text object.
	#
	[carray-enum-internal $start *$seg:$lineArray print-one-line
    	    	    [list $seg $instance 0 [symbol find type geos::LineInfo]]]
    }
}]

##############################################################################
#				print-run-array
##############################################################################
#
# SYNOPSIS:	Print a run array
# CALLED BY:	ptext
# PASS:	    	seg 	 - object segment
#   	    	off 	 - object offset
#   	    	token	 - chunk array or VM block
#   	    	instance - VisTextInstance
#   	    	callback - passed {seg off pos instance elArr elNum addr}
#   	    	elementsOnly - 
#   	    	startPos - position after which run must fall to be printed
# RETURN:	elArr	 - Address expression for the elements
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 1/29/92	Initial Revision
#
##############################################################################
[defsubr print-run-array {seg off token instance callback elementsOnly startPos}
{
    if {[field [field $instance VTI_storageFlags] VTSF_LARGE]} {
	var file [text-object-get-file $seg $instance]
	#
	# The elements are contained in a vm-block whose handle is stored
	# in the TLRAH_elementVMBlock field.
	#
	ensure-vm-block-resident $file $token
	var ehan [value fetch (^v$file:$token):text::TLRAH_elementVMBlock]
	ensure-vm-block-resident $file $ehan
    	var chunk [value fetch (^v$file:$ehan):geos::LMBH_offset]
    	var elArr *(^v$file:$ehan):$chunk

	echo [format {Runs in huge array at ^v%04xh:%04xh} $file $token]
    	if {!$elementsOnly} {
	    [harray-enum $file $token print-run-array-element
	    	    	    [list $callback $seg $off $instance $elArr $startPos]]
    	}
	
    } else {
    	var soff [value fetch $seg:$token word]
	#
	# The elements are in one of two places:
	#   - Chunk in same block as object
	#   - VM-block somewhere
	#
	var runa [value fetch $seg:$soff text::TextRunArrayHeader]
	var ehan [field $runa TRAH_elementVMBlock]

	if {$ehan} {
	    #
	    # It's in a vm-block. Get the file and figure the address
	    # of the chunk-array
	    #
    	    var file [text-object-get-file $seg $instance]
	    var elArr *(^v$file:$ehan):[size LMemBlockHeader]
	} else {
	    #
	    # It's in a chunk in the same block as the object
	    #
    	    var chunk [field $runa TRAH_elementArray]
	    var elArr *$seg:$chunk
	}
	echo [format {Runs in chunk at *%s:%04xh} $seg $token]

    	if {!$elementsOnly} {
    	    [carray-enum $seg:$soff print-run-array-element 
	    	    	    [list $callback $seg $off $instance $elArr $startPos]]
    	}

    }
    return $elArr
}]

#
# Callback to print additional information for each character attribute
#

[defsubr print-char-text-callback {seg off pos instance elArr elNum addr} {
    var textArray [field $instance VTI_text]

    if {[field [field $instance VTI_storageFlags] VTSF_LARGE]} {
	var file [text-object-get-file $seg $instance]

	echo -n [format {, text = "} ]
    	[if {[catch {harray-enum-raw $file $textArray {print-chars} $pos [list [expr $pos+12] $seg $instance]}] != 0}
    	{
	    echo -n ==ERR==
    	}]
    } else {
	var taddr (*$seg:$textArray)+$pos
	
	echo -n [format {, text = "} $prev]
	printchars $taddr 12
    }
    #
    # Find the style
    #
    if {[field [field $instance VTI_storageFlags] VTSF_STYLES]} {
    	var styleArray [get-style-array $seg $off $instance]
    	if {[null $styleArray]} {
    	    echo "
    	} else {
    	    var elem [carray-get-element-addr $elArr
    	    	    	    [value fetch $addr.text::TRAE_token] text::VisTextCharAttr]
    	    var styleToken [value fetch $elem.styles::SSEH_style]

    	    var styleAddr [carray-get-element-addr $styleArray
    	    	    	    	    $styleToken text::TextStyleElementHeader]
    	    var nextStyleAddr [carray-get-element-addr $styleArray
    	    	    	    	    [expr $styleToken+1] text::TextStyleElementHeader]
    	    var s1 [index [addr-parse $styleAddr] 1]
    	    var s2 [index [addr-parse $nextStyleAddr] 1]
    	    var count [expr $s2-$s1-[size text::TextStyleElementHeader]]
    	    echo -n [format {", style = %d, "} $styleToken]
    	    for {var i 0} {$i < $count} {var i [expr $i+1]} {
    	    	echo -n [value fetch $styleAddr+[size text::TextStyleElementHeader]+$i char]
    	    }
    	    echo "
    	}
    } else {
    	echo "
    }
}]

#
# Callback to print additional information for each paragraph attribute
#

[defsubr print-para-text-callback {seg off pos instance elArr elNum addr} {
    var textArray [field $instance VTI_text]

    if {[field [field $instance VTI_storageFlags] VTSF_LARGE]} {
	var file [text-object-get-file $seg $instance]

	if {$pos} {
    	    var prev [harray-get-element $file $textArray [expr $pos-1] byte]
    	    if {[null $prev]} {
    	    	var prev {<INVALID>}
    	    } else {
    	    	var prev [penum geos::Chars $prev]
    	    }
    	} else {
	    var prev {<START>}
	}

	echo -n [format {, prev = %s, text = "} $prev]
    	[harray-enum-raw $file $textArray print-chars $pos
		       [list [expr $pos+12] $seg $instance]]
	echo "
    } else {
	var taddr (*$seg:$textArray)+$pos

	if {$pos} {
    	    var prev [penum geos::Chars [value fetch $taddr-1 byte]]
    	} else {
	    var prev {<START>}
	}

	echo -n [format {, prev = %s, text = "} $prev]
	printchars $taddr 12
	echo "
    }
}]

##############################################################################
#				get-style-array
##############################################################################
#
# SYNOPSIS:	Get the style array
# CALLED BY:	
# PASS:		seg 	- text object segment
#   	    	off 	- text object offset
#   	    	instance -
# RETURN:	address
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 4/13/92	Initial Revision
#
##############################################################################
[defsubr get-style-array {seg off instance}
{
    var rchunk [fvardata text::ATTR_VIS_TEXT_STYLE_ARRAY $seg:$off]
    if {[null $rchunk]} {
	var rchunk [fvardata ui::ATTR_GEN_TEXT_STYLE_ARRAY $seg:$off]
    }
    if {![null $rchunk]} {
	var rchunk [index $rchunk 1]
	if {[field [field $instance VTI_storageFlags] VTSF_LARGE]} {
	    var file [text-object-get-file $seg $instance]
	    #
	    # The elements are contained in a vm-block whose handle is
	    # stored in the TLRAH_elementVMBlock field.
	    #
	    ensure-vm-block-resident $file $rchunk
	    var chunk [value fetch (^v$file:$rchunk):geos::LMBH_offset]
	    return *(^v$file:$rchunk):$chunk
	} else {
	    var cruns [field $instance VTI_charAttrRuns]
	    var runa [value fetch *$seg:$cruns text::TextRunArrayHeader]
	    var ehan [field $runa TRAH_elementVMBlock]
	    #
	    # The elements are in one of two places:
	    #   - Chunk in same block as object
	    #   - VM-block somewhere
	    #
	    if {$ehan} {
		#
		# It's in a vm-block. Get the file and figure the address
		# of the chunk-array
		#
		var file [text-object-get-file $seg $instance]
	    	var chunk [value fetch (^v$file:$rchunk):geos::LMBH_offset]
		return *(^v$file:$rchunk):$chunk
	    } else {
		#
		# It's in a chunk in the same block as the object
		#
		return *$seg:$rchunk
	    }
	}
    } else {
    	return {}
    }
}]

##############################################################################
#				print-run-array-element
##############################################################################
#
# SYNOPSIS:	Print a single run-array element.
# CALLED BY:	print-run-array via carray-enum
# PASS:		elnum	- Element number
#   	    	addr	- Address expression of the element
#   	    	lsize	- Size of data
#   	    	extra	- List containing:
#   	    	    	    	callback - Callback function
#   	    	    	    	seg 	 - Segment of the instance
#   	    	    	    	instance - VisTextInstance structure
#    	    	    	    	elArr	 - element array
#   	    	    	    	startPos - position after which run must fall
#					   to be printed
# RETURN:	0 indicating "keep going"
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 4/13/92	Initial Revision
#
##############################################################################
[defsubr print-run-array-element {elnum addr lsize extra}
{
    var callback [index $extra 0]
    var seg 	 [index $extra 1]
    var off 	 [index $extra 2]
    var instance [index $extra 3]
    var elArr 	 [index $extra 4]

    var rae [value fetch $addr text::TextRunArrayElement]
    var pos [getwaah $rae TRAE_position]
    if {$pos == 0xffffff} {
    	echo [format {    Position = END}]
    } elif {$pos >= [index $extra 5]} {
    	echo -n [format {    Position = %04xh, token = %d, elnum = %d}
	    	    	$pos
    	    	    	[field $rae TRAE_token] $elnum]
    	if [null $callback] {
    	    echo
    	} else {
    	    $callback $seg $off $pos $instance $elArr $elnum $addr
    	}
    }
    
    return 0
}]

##############################################################################
#				print-lines
##############################################################################
#
# SYNOPSIS:	Print the lines in a text object.
# CALLED BY:	ptext
# PASS:		seg 	- Segment containing the instance
#   	    	instance- VisTextInstance structure
#   	    	startPos- text position after which a line must fall to be
#			  printed
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 1/29/92	Initial Revision
#
##############################################################################
[defsubr print-lines {seg instance startPos}
{
    var lineArray [field $instance VTI_lines]
	
    #
    # Using wonderful dynamic inheritance we can supply the offset to the
    # line start and get it updated as each line is drawn.
    #
    global pl_lineStart
    var pl_lineStart 0
    if {[field [field $instance VTI_storageFlags] VTSF_LARGE]} {
    	#
	# Large text object.
	#
	var file [text-object-get-file $seg $instance]
    	echo [format {Line array at ^v%04xh:%04xh} $file $lineArray]
	[harray-enum $file $lineArray print-one-line
	    [list $seg $instance $startPos [symbol find type geos::LineInfo]]]
    } else {
    	#
	# Small text object.
	#
    	echo [format {Line array at *%s:%04xh} $seg $lineArray]
	[carray-enum *$seg:$lineArray print-one-line
    	    [list $seg $instance $startPos [symbol find type geos::LineInfo]]]
    }
}]

##############################################################################
#				text-object-get-file
##############################################################################
#
# SYNOPSIS:	Get the file-handle of the file associated with an object.
# CALLED BY:	print-lines, print-run-array
# PASS:	    	seg 	 - Segment of block containing object
#   	    	instance - Text object instance
# RETURN:	file	 - File handle associated with the object
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 3/23/92	Initial Revision
#
##############################################################################
[defsubr text-object-get-file {seg instance}
{
    var file [field $instance VTI_vmFile]

    if {$file == 0} {
	var blockHan [value fetch $seg:LMBH_handle word]
	var blockOwn [value fetch kdata:$blockHan.HM_owner]
	var file     [value fetch kdata:$blockOwn.HVM_fileHandle]
    }

    return $file
}]


##############################################################################
#				print-one-line
##############################################################################
#
# SYNOPSIS:	Print a single line.
# CALLED BY:	print-lines via carray-enum
# PASS:	    	elnum	- Element number (line number)
#   	    	addr	- Address expression of the line
#   	    	lsize	- Size of the line/field data
#   	    	extra	- List containing:
#   	    	    	    seg	    - Segment of the instance
#   	    	    	    instance- VisTextInstance structure
#			    startPos
#   	    	    	    lit	    - type token for LineInfo type
# RETURN:	0 indicating "keep going"
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 1/29/92	Initial Revision
#
##############################################################################
[defsubr print-one-line {elnum line lsize extra}
{
    #
    # Extract the segment and instance from the extra stuff
    #
    var seg 	 [index $extra 0]
    var instance [index $extra 1]
    
    #
    # Get a pointer to the line
    #
    var addr [addr-preprocess $line s loff]

    #
    # Print the line
    #
    var l [value fetch $s:$loff [index $extra 3]]
    print-line-struct $elnum $s $l $instance $loff
    
    #
    # Print the fields
    #
    
    #
    # Compute the size of a FieldInfo structure since we use it in the loop
    # below.
    #
    var fsize  [type size [sym find type geos::FieldInfo]]
    
    #
    # Fetch the first field and establish the start of the field
    #
    var f      [field $l LI_firstField]
    
    global pl_lineStart
    var fstart $pl_lineStart

    #
    # Compute the offset of the *next* field (after the current one)
    #
    var foff   [expr $loff+[type size [sym find type geos::LineInfo]]]

    #
    # Now loop around printing the fields
    #
    var fnum 0
    do {
	#
	# Print the current field
	#
    	[print-field-struct $fnum $seg $f $fstart $instance $s
    	    	    	    [expr $foff-$fsize]]
	
	#
	# Compute the start of the next field
	#
        global dbcs
        if {[null $dbcs]} {
	    var fstart [expr $fstart+[field $f FI_nChars]]
    	} else  {
	    var fstart [expr $fstart+[field $f FI_nChars]*2]
    	}

	#
	# Fetch the next field and advance the field offset
	#
    	var f [value fetch $s:$foff [sym find type geos::FieldInfo]]

	var fnum [expr $fnum+1]
	var foff [expr $foff+$fsize]
    } while {$foff <= [expr $loff+$lsize]}
    
    var pl_lineStart $fstart

    echo
    return 0
}]

##############################################################################
#				print-line-struct
##############################################################################
#
# SYNOPSIS:	Print a single line structure
# CALLED BY:	print-one-line
# PASS:	    	linenum	- Line number
#   	    	seg 	- Segment containing VisTextInstance
#   	    	l   	- LineInfo structure
#   	    	instance- VisTextInstance
#   	    	line	- Address expression for the line
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 1/29/92	Initial Revision
#
##############################################################################
[defsubr print-line-struct {linenum seg l instance loff}
{
    #
    # Print height, baseline, adjustment, and start.
    #
    echo [format {Line %3d (%s:%04xh):}
    	    	    $linenum
		    $seg $loff
		    ]
    echo [format {    count = %-5d hgt = %3.3f blo = %3.3f adj = %-3d spcPd = %3.3f}
		    [getwaah $l LI_count]
		    [getwbf  $l LI_hgt]
		    [getwbf  $l LI_blo]
		    [field   $l LI_adjustment]
		    [getwbf  $l LI_spacePad]
    	    	    ]
    #
    # Now flags
    #
    echo -n {    }
    fmtrecord [sym find type geos::LineFlags] [field $l LI_flags] 4
    echo
}]


##############################################################################
#				print-field-struct
##############################################################################
#
# SYNOPSIS:	Print a single field structure
# CALLED BY:	print-one-line
# PASS:	    	fieldnum- Field number
#   	    	seg 	- Segment containing VisTextInstance
#   	    	f   	- FieldInfo structure
#   	    	fstart	- Offset to the start of this field
#   	    	instance- VisTextInstance
#   	    	fseg	- Segment of the block where the field is located
#   	    	foff	- Offset into the block where the field is located
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 1/29/92	Initial Revision
#
##############################################################################
[defsubr print-field-struct {fieldnum seg f fstart instance fseg foff}
{
    var tabType [field [field $f FI_tab] TR_TYPE]
    var tabType [type emap $tabType [sym find type geos::TabReferenceType]]

    if {[string c $tabType TRT_OTHER]==0} {
    	var tabType o
    } else {
    	var tabType r
    }

    echo -n {        }
    echo [format {Field %2d (%s:%04xh):}
		$fieldnum
		$fseg $foff
    	    	]
    echo -n {            }
    echo [format {nChars = %3d, pos = %3d, width = %3d, tab = %s, %2d}
		[field $f FI_nChars]
		[field $f FI_position]
		[field $f FI_width]
    	    	$tabType
		[field [field $f FI_tab] TR_REF_NUMBER]
    	    	]

    #
    # Print out the text of the field
    #
    echo -n {            "}
    if {[field [field $instance VTI_storageFlags] VTSF_LARGE]} {
	#
	# Large object
	#
	var file [text-object-get-file $seg $instance]
    	var textArray [field $instance VTI_text]
       [harray-enum-raw $file $textArray print-chars $fstart
		   [list [expr $fstart+[field $f FI_nChars]]
			 $seg
			 $instance]]
    } else {
	#
	# Small object
	#
	var tstart [field $instance VTI_text]
	var tstart [value fetch $seg:$tstart word]
	var fstart [expr $tstart+$fstart]

    	printchars $seg:$fstart [field $f FI_nChars]
    }
    echo {"}
}]

##############################################################################
#				ptrange
##############################################################################
#
# SYNOPSIS:	Print a range of text from a text object.
# CALLED BY:	user
# PASS:	    	start	- First character
#   	    	end 	- Last character
#   optional	obj 	- Address expression of the object to print from
#   	    	    	  Defaults to *ds:si
#
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	12/ 9/92	Initial Revision
#
##############################################################################
[defcommand ptrange {start end {obj *ds:si}} lib_app_driver.text
{Usage:
    ptrange start end [obj]

Examples:
    "ptrange 12 15"	    	    Print the character range 12-15 in *ds:si
    "ptrange 12 15 ^lcx:dx"	    Print the character range 12-15 in ^lcx:dx

Synopsis:
    Print a range of characters in a text object.
    
Notes:

See also:
    ptext
}
{
    #
    # Parse the address
    #
    var addr	[addr-parse $obj]
    var seg 	[handle segment [index $addr 0]]
    var off 	[index $addr 1]

    #
    # Fetch the instance 
    #
    var VTI 	 [expr $off+[value fetch $seg:$off.ui::Vis_offset]]
    var instance [value fetch $seg:$VTI text::VisTextInstance]

    echo -n {            "}
    if {[field [field $instance VTI_storageFlags] VTSF_LARGE]} {
	#
	# Large object
	#
	var file [text-object-get-file $seg $instance]
    	var textArray [field $instance VTI_text]
       [harray-enum-raw $file $textArray print-chars $start
		   [list $end
			 $seg
			 $instance]]
    } else {
	#
	# Small object
	#
	var tstart [field $instance VTI_text]
	var tstart [value fetch $seg:$tstart word]

    	printchars $seg:$tstart [expr $end-$start]
    }
    echo {"}
}]

##############################################################################
#				getwaah
##############################################################################
#
# SYNOPSIS:	Convert a WordAndAHalf structure to a number
# CALLED BY:	ptext
# PASS:		tvar	- Structure containing the WordAndAHalf
#   	    	tfield	- Field which is the WordAndAHalf
# RETURN:	num 	- The value of the WordAndAHalf
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 1/29/92	Initial Revision
#
##############################################################################
[defsubr getwaah {tvar tfield} {
    var a  [field $tvar $tfield]
    return [expr [field $a WAAH_low]+([field $a WAAH_high]<<16)]
}]

##############################################################################
#				getwbf
##############################################################################
#
# SYNOPSIS:	Convert a WBFixed structure to a number
# CALLED BY:	print-line-struct
# PASS:		tvar	- Structure containing the WBFixed
#   	    	tfield	- Field which is the WBFixed
# RETURN:	num 	- The value of the WBFixed
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 1/30/92	Initial Revision
#
##############################################################################
[defsubr getwbf {tvar tfield}
{
    var a  [field $tvar $tfield]
    var n  [field $a WBF_int]
    var n  [expr $n+([field $a WBF_frac]/256) float]
    return $n
}]


##############################################################################
#				printchars
##############################################################################
#
# SYNOPSIS:	Print the characters in a string.
# CALLED BY:	ptext
# PASS:		addr	- Address of the string
#   	    	count	- Number of characters to print
# RETURN:	# of chars actually printed
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 1/29/92	Initial Revision
#
##############################################################################
[defsubr printchars {addr count} {
    global dbcs
    if {[null $dbcs]} {
    	var wide 1
    } else {
    	var wide 2
    }
    if {$wide == 1} {
    	for {var i 0} {$i < $count} {var i [expr $i+1]} {
    	    var c [value fetch ($addr)+$i [type byte]]
	    # if we encounter CR, echo "\r"
            if {$c == 0dh} {
        	echo -n \\r
            } elif {$c < 32 || $c > 127} {
        	echo -n {.}
            } else {
        	echo -n [format %c $c]
    	    }
    	}
    	return $count
    } else {
    	var qp 1
    	for {var i 0} {$i < $count && $c != 0} {var i [expr $i+1]} {
	    # if we encounter CR, echo "\r"
    	    var c [value fetch ($addr)+[expr $i*2] [type word]]
            if {$c == 0dh} {
    	    	if {!$qp} {
    	    	    echo -n {"}
    	    	    var qp 1
    	    	}
        	echo -n \\r
            } elif {$c < 32 || $c > 127} {
    	    	if {$qp == 1} {
    	    	    var qp 0
    	    	    echo -n {",}
    	    	}
    	    	echo -n [format {%s,} [penum geos::Chars $c]]
            } else {
    	    	if {$qp == 0} {
    	    	    var qp 1
    	    	    echo -n {"}
    	    	}
        	echo -n [format %c $c]
    	    }
    	}
    	return $i
    }
}]


##############################################################################
#				printString
##############################################################################
#
# SYNOPSIS:	Print a string associated with a VisTextInstance
# CALLED BY:	ptext, oldptext
# PASS:		seg 	- Segment of VisTextInstance
#   	    	instance- VisTextInstance structure
#   	    	start	- Place to start at
#   	    	nChars	- Number of characters to print
# RETURN:	-1  If nChars were printed
#   	    	 0  Otherwise
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 1/29/92	Initial Revision
#
##############################################################################
[defsubr printString {seg instance start nchars}
{
    var ptr [value fetch $seg:[field $instance VTI_text] [type word]]
    var ptr [expr $ptr+$start]
    #
    # Print characters as we got them w/no intervening commas -- use
    # format to take care of \\, \{ and \} things. All other things are
    # printed as returned by value...
    #
    global dbcs
    echo -n {"}
    if {[null $dbcs]} {
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
    } else {
    	var nchars [printchars $seg:$ptr $nchars]
    	echo {}
    }
    if {$nchars==0} {
        return -1
    } else {
    	return 0
    }
}]

##############################################################################
#				vtpstart
##############################################################################
#
# SYNOPSIS:	Starts VisTextPtr performance checking
# CALLED BY:	user
# PASS:		nothing
# RETURN:	nothing
# SIDE EFFECTS:	Initializes the variables (on the target system) associated
#   	    	with the VisTextPtr performance checking.
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 1/29/92	Initial Revision
#
##############################################################################
[defsubr vtpstart {} {
    assign text::ptrCount 0
    assign text::selCount 0
    echo {Counts zeroed...}
}]

##############################################################################
#				vtpdisp
##############################################################################
#
# SYNOPSIS:	Print out VisTextPtr performance values
# CALLED BY:	user
# PASS:		nothing
# RETURN:	none
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 1/29/92	Initial Revision
#
##############################################################################
[defsubr vtpdisp {} {
    var ptrCount [value fetch text::ptrCount [type word]]
    var selCount [value fetch text::selCount [type word]]
    if {$ptrCount == 0} {
       var per 0
    } else {
       var per [expr (1-($selCount/$ptrCount))*100 float]]
    }
    echo -n [format {%d total calls to VisTextPtr, } $ptrCount]
    echo [format {%d calls to ExtendSelection, %.0f%% extra} $selCount $per]
}]

##############################################################################
#				convBBFixed, convWBFixed
##############################################################################
#
# SYNOPSIS:	Convert a BBFixed or WBFixed to a number
# CALLED BY:	nobody
# PASS:		param	- A BBFixed (WBFixed) structure
# RETURN:	num 	- The floating point number that is the BBFixed (WBFixed)
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 1/29/92	Initial Revision
#
##############################################################################
[defsubr convBBFixed {param} {
    return [expr [field $param BBF_int]+[field $param BBF_frac]/256 f]
}]

[defsubr convWBFixed {param} {
    return [expr [field $param WBF_int]+[field $param WBF_frac]/256 f]
}]

#========================================================================
#========================================================================
#========================================================================
#   	    	    1.X version

[defsubr oldptext {args}
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
    echo [format {Text object: *%s:%04xh} $seg $off]

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
	var lineInfoSize  [type size [sym find type geos::LineInfo]]

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
		_print ui::ElementArray $eseg:$ptr
		var ptr [expr $ptr+[type size [symbol find
						type ui::ElementArray]]]
		for {var i 0} {$i != [field $ea EA_count]} {var i [expr $i+1]} {
		    echo [format {***** Element token %d *****}
							[expr $ptr-$base]]
		    _print ui::VisTextStyle $eseg:$ptr
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
		_print ui::VisTextStyle *$seg:[field $instance VTI_styleRuns]
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
		_print ui::ElementArray $eseg:$ptr
		var ptr [expr $ptr+[type size [symbol find
						type ui::ElementArray]]]
		var csz [expr $csz-[type size [symbol find
						type ui::ElementArray]]]
		for {var i 0} {$i != [field $ea EA_count]} {var i [expr $i+1]} {
		    echo [format {***** Element at offset %d, token %d *****}
			[expr $ptr-$base]
			[value fetch $eseg:$ptr.ui::VTR_token]]
		    _print ui::VisTextRuler $eseg:$ptr
		    var numTabs [value fetch $eseg:$ptr.ui::VTR_numberOfTabs]
		    if {$numTabs > 0} {
			var tptr [expr $ptr+[type size
					[symbol find type ui::VisTextRuler]]]
			for {var j 0} {$j != $numTabs} {var j [expr $j+1]} {
			    _print ui::Tab $eseg:$tptr
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
		_print ui::VisTextRuler *$seg:[field $instance VTI_rulerRuns]
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
		_print ui::ElementArray $eseg:$ptr
		var ptr [expr $ptr+[type size [symbol find
						type ui::ElementArray]]]
		for {var i 0} {$i != [field $ea EA_count]} {var i [expr $i+1]} {
		    echo [format {***** Element token %d *****}
							[expr $ptr-$base]]
		    _print ui::VisTextGraphic $eseg:$ptr
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

##############################################################################
#				print-chars
##############################################################################
#
# SYNOPSIS:	Print some characters from a huge-array.
# CALLED BY:	harray-enum-raw
# PASS:		elNum	- Current character
#   	    	addr	- Address of character
#   	    	count   - Number of valid characters
#   	    	extra	- List containing:
#   	    	    	    end	    - Last element to print
#   	    	    	    seg	    - Segment of the instance
#   	    	    	    instance- VisTextInstance structure
# RETURN:	0 indicating "keep going"
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 3/23/92	Initial Revision
#
##############################################################################
[defsubr print-chars {elNum text count extra}
{
    var base 0

    while {$count} {
	#
	# Make sure the current element is in range
	#
	if {$elNum >= [index $extra 0]} {
	    #
	    # Abort
	    #
	    return 1
	}

    	global dbcs
    	if {[null $dbcs]} {
	    var ch [value fetch $text+$base [type char]]
    	} else {
	    var ch [value fetch $text+$base [type wchar]]
    	}
	if {[string c $ch \\000]} {
	    if {[string m $ch {\\[\{\}\\]}]} {
		echo -n [format $ch]
    	    } else {
		echo -n $ch
	    }
	}
        var count [expr $count-1]
	var elNum [expr $elNum+1]
	var base  [expr $base+1]
    }
    return 0
}]

##############################################################################
#				print-one-region
##############################################################################
#
# SYNOPSIS:	Print a single region.
# CALLED BY:	ptext via carray-enum
# PASS:		elnum	- Element number (region number)
#   	    	addr	- Address expression of region
#   	    	rsize	- Size of region
#   	    	extra	- List containing:
#   	    	    	    seg	    - Segment of the instance
#   	    	    	    instance- VisTextInstance structure
#   	    	    	    file    - file handle
#   	    	    	    verbose - True to print full regions
# RETURN:	0 indicating "keep going"
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 4/ 3/92	Initial Revision
#
##############################################################################
[defsubr print-one-region {elnum addr rsize extra}
{
    #
    # Fetch the region
    #
    var r [value fetch $addr [sym find type text::VisLargeTextRegionArrayElement]]
    
    var a   [addr-parse $addr]
    var seg [handle segment [index $a 0]]
    var off [index $a 1]
    
    #
    # Print out the pertinent information
    #
    echo [format {Region %3d:   (%s:%04xh)   @(%d,%d)}
	    $elnum
	    $seg $off
    	    [field [field $r VLTRAE_spatialPosition] PD_x]
    	    [field [field $r VLTRAE_spatialPosition] PD_y]
	    ]
    echo [format {    Width: %d   Height: %d   CalcHeight: %5.3f}
	    [field [field $r VLTRAE_size] XYS_width]
	    [field [field $r VLTRAE_size] XYS_height]
	    [convWBFixed [field $r VLTRAE_calcHeight]]
	    ]

    echo [format {    Section: %d    Char Count: %d   Line Count: %d}
    	    [field $r VLTRAE_section]
    	    [field $r VLTRAE_charCount]
    	    [field $r VLTRAE_lineCount]
	    ]

    echo -n {    Flags: }
    fmtrecord [sym find type text::VisLargeTextRegionFlags] [field $r VLTRAE_flags] 4
    echo

    var reg [field $r VLTRAE_region]
    if {$reg} {
        var raddrlist [map-db-item-to-addr [index $extra 2]
    	    	    	    	    	   [expr ($reg&0xffff0000)>>16]
    	    	    	    	    	   [expr ($reg&0x0000ffff)]]
    	var raddr [format {%d:%d} [index $raddrlist 2] [index $raddrlist 4]]
        echo [format {   Region exists, bounds are (%d, %d, %d, %d), region is:}
    	    	    [value fetch $raddr+0 word] [value fetch $raddr+2 word]
    	    	    [value fetch $raddr+4 word] [value fetch $raddr+6 word]]
    	if {[index $extra 3]} {
       	    preg -d $raddr
    	}
    }

    echo
    
    return 0
}]

##############################################################################
#				print-one-style
##############################################################################
#
# SYNOPSIS:	Print a single style.
# CALLED BY:	ptext via carray-enum
# PASS:		elnum	- Element number (region number)
#   	    	addr	- Address expression of region
#   	    	rsize	- Size of style
#   	    	extra	- List containing:
# RETURN:	0 indicating "keep going"
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 4/ 3/92	Initial Revision
#
##############################################################################
[defsubr print-one-style {elnum addr rsize extra}
{
    
    var a   [addr-parse $addr]
    var seg [handle segment [index $a 0]]
    var off [index $a 1]
    
    #
    # Print out the pertinent information
    #
    echo -n [format {Style %d: } $elnum]

    if {[value fetch $addr.REH_refCount.WAAH_high] == 255} {
    	echo {FREE}
    } else {
    	echo -n {"}
	var count [expr $rsize-[size text::TextStyleElementHeader]]
	for {var i 0} {$i < $count} {var i [expr $i+1]} {
	    echo -n [value fetch $addr+[size text::TextStyleElementHeader]+$i char]
	}
	var base [value fetch $addr.text::TSEH_baseStyle]
    	if {$base == 65535} {
	    echo -n [format {", no base style}]
    	} else {
	    echo -n [format {", based on %d} $base]
    	}
	echo -n [format {, char = %d, para = %d}
		    [value fetch $addr.text::TSEH_charAttrToken]
		    [value fetch $addr.text::TSEH_paraAttrToken]
	     ]
	var flags [value fetch $addr.text::TSEH_privateData.text::TSPD_flags]
	if {[field $flags TSF_APPLY_TO_SELECTION_ONLY]} {
	    echo -n {, charOnly}
	}
	if {[field $flags TSF_POINT_SIZE_RELATIVE]} {
	    echo -n {, psRel}
	}
	if {[field $flags TSF_MARGINS_RELATIVE]} {
	    echo -n {, marRel}
	}
	if {[field $flags TSF_LEADING_RELATIVE]} {
	    echo -n {, leadRel}
	}
    	echo
    }

    return 0
}]

##############################################################################
#				rwatch
##############################################################################
#
# SYNOPSIS:	Watch recalculation happen
# CALLED BY:	
# PASS:		on/off
# RETURN:	nothing
# SIDE EFFECTS:	sets or clears breakpoints
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 6/25/92	Initial Revision
#
##############################################################################
[defcommand rwatch {{onOff {}}} {lib_app_driver.text profile}
{Usage:
    rwatch [on|off]

Examples:
    "rwatch on"	  	Watch text-recalculation as it happens
    "rwatch off"  	Turn output off
    "rwatch"	    	See what the status is

Synopsis:
    Displays information about text recalculation. Specifically designed
    for tracking bugs in the rippling code.

Notes:

See also:
    ptext
}
{
    global  rw_brk_list
    
    if {[string compare $onOff on]==0} {
    	#
    	# Set the breakpoints (if there aren't any set already)
    	#
    	if {[null $rw_brk_list]} {
	    var	rw_brk_list [list
	[brk text::CalculateRegions 	    rw-start]
	[brk text::CR_quit  	    	    rw-end]
	[brk text::CR_lineLoop	    	    rw-line-loop]
	[brk text::CR_almostPerfect  	    rw-almost-perfect]
	[brk text::CR_calcLineInfo   	    rw-calc]
	[brk text::CR_afterCalc   	    rw-after-calc]
	[brk text::CR_rippleToNextRegion    rw-ripple-nr]
	[brk text::CR_calcFromNextColumn    rw-ripple-nc]
	[brk text::CR_calcFromNextSection   rw-ripple-ns]
	[brk text::CR_reachedLastLine	    rw-last-line]
	[brk text::UpdateRegionHeight       rw-update-region-height]
	[brk text::InsertOneLine    	    rw-insert-line]
	[brk text::IODL_afterDelete	    rw-after-delete]
	]
    	} else {
	    echo rwatch is already on
	}
    } elif {[string compare $onOff off]==0} {
    	if {[null $rw_brk_list]} {
	    echo rwatch is already off
	} else {
	    #
	    # Clear the breakpoints
	    #
	    if {![null $rw_brk_list]} {
		foreach i $rw_brk_list {
		    catch {brk clear $i}
		}
	    }
	    var rw_brk_list {}
	}
    } else {
	if {[null $rw_brk_list]} {
    	    echo rwatch is off
	} else {
	    echo rwatch is on
	}
    }
}]

##############################################################################
#				rw-start
##############################################################################
#
# SYNOPSIS:	Print information before computing an object
# CALLED BY:	
# PASS:		
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 6/25/92	Initial Revision
#
##############################################################################
[defsubr rw-start {}
{
    var addr [addr-parse *ds:si]
    var seg  [handle segment [index $addr 0]]
    var off  [index $addr 1]

    echo -n {------------}
    echo -n [format {Starting calculation for object: ^l%04xh:%04xh} 
    	    	    	[value fetch ds:LMBH_handle]
			[read-reg si]]
    echo {------------}
    echo [format {First line to compute is %d}
    	    	    	[expr ([read-reg bx]*65536)+[read-reg di]]]

    echo
    echo ================
    echo

    return 0
}]

##############################################################################
#				rw-end
##############################################################################
#
# SYNOPSIS:	Print information after computing an object
# CALLED BY:	
# PASS:		
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 6/25/92	Initial Revision
#
##############################################################################
[defsubr rw-end {}
{
    echo -n {------------}
    echo -n [format {Finished calculation for object: ^l%04xh:%04xh}
		    [value fetch ds:LMBH_handle]
		    [read-reg si]]
    echo {------------}

    return 0
}]

##############################################################################
#				rw-line-loop
##############################################################################
#
# SYNOPSIS:	Print information at the top of the line-calculation loop
# CALLED BY:	
# PASS:		
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 6/25/92	Initial Revision
#
##############################################################################
[defsubr rw-line-loop {}
{
    echo [format {Checking before calculating line %d in context of region %d}
    	    	    [read-reg di]
		    [value fetch ss:bp.text::LICL_region]]
    return 0
}]

##############################################################################
#				rw-almost-perfect
##############################################################################
#
# SYNOPSIS:	Print information at the point when we think an object
#   	    	may be up to date.
# CALLED BY:	
# PASS:		
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 6/25/92	Initial Revision
#
##############################################################################
[defsubr rw-almost-perfect {}
{
    echo
    echo {Object appears almost perfect}
    return 0
}]

##############################################################################
#				rw-calc
##############################################################################
#
# SYNOPSIS:	Print information at the moment we are to compute a line
# CALLED BY:	
# PASS:		
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 6/25/92	Initial Revision
#
##############################################################################
[defsubr rw-calc {}
{
    var l [value fetch ss:bp.text::LICL_line]
    var r [value fetch ss:bp.text::LICL_region]
    
    var ins [convDWFixed [value fetch ss:bp.text::LICL_insertedSpace]]

    echo
    echo [format {Calculating line: %d in region %s, insSpace %d} $l $r $ins]
#    precord LineFlags [read-reg cx] 1

    return 0
}]

##############################################################################
#				rw-after-calc
##############################################################################
#
# SYNOPSIS:	Print information after computing the line
# CALLED BY:	
# PASS:		
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 6/25/92	Initial Revision
#
##############################################################################
[defsubr rw-after-calc {}
{
    var ins [convDWFixed [value fetch ss:bp.text::LICL_insertedSpace]]
    var rh [convDWFixed [value fetch ss:bp.text::LICL_rippleHeight]]
    
    echo [format {After calc: inserted space: %s  (old hgt: %s, new hgt %s, rCount %d, rHgt %s)}
		    $ins
    	    	    [convWBFixed [value fetch ss:bp.text::LICL_oldLineHeight]]
		    [convWBFixed [value fetch ss:bp.text::LICL_lineHeight]]
		    [value fetch ss:bp.text::LICL_rippleCount]
		    $rh]

    echo
    return 0
}]

##############################################################################
#				rw-ripple-nr
##############################################################################
#
# SYNOPSIS:	Print information about rippling to the next segment
# CALLED BY:	
# PASS:		
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 6/25/92	Initial Revision
#
##############################################################################
[defsubr rw-ripple-nr {}
{
    var l [value fetch ss:bp.text::LICL_line]

    echo [format {Reached region end at line: %d} $l]

    return 0
}]

##############################################################################
#				rw-ripple-nc
##############################################################################
#
# SYNOPSIS:	Print information about rippling to the next column
# CALLED BY:	
# PASS:		
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 6/25/92	Initial Revision
#
##############################################################################
[defsubr rw-ripple-nc {}
{
    var l [value fetch ss:bp.text::LICL_line]

    echo [format {Reached column break at line: %d} $l]

    return 0
}]

##############################################################################
#				rw-ripple-ns
##############################################################################
#
# SYNOPSIS:	Print information about rippling to the next segment
# CALLED BY:	
# PASS:		
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 6/25/92	Initial Revision
#
##############################################################################
[defsubr rw-ripple-ns {}
{
    var l [value fetch ss:bp.text::LICL_line]

    echo [format {Reached section break at line: %d} $l]

    return 0
}]

##############################################################################
#				rw-last-line
##############################################################################
#
# SYNOPSIS:	Note that we've reached the last line
# CALLED BY:	
# PASS:		
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 6/25/92	Initial Revision
#
##############################################################################
[defsubr rw-last-line {}
{
    var l [value fetch ss:bp.text::LICL_line]

    echo [format {Reached last line: %d} $l]

    return 0
}]

##############################################################################
#				rw-remove-rippled-lines
##############################################################################
#
# SYNOPSIS:	Note that we are moving lines from one place to another
# CALLED BY:	
# PASS:		
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 6/25/92	Initial Revision
#
##############################################################################
[defsubr rw-remove-rippled-lines {}
{
    var al [expr [read-reg ax]&0xff]
    var dx [read-reg dx]

    var spc [expr $dx+($al/256) float]

    if {$spc < 0} {
        echo [format {Rippling space backwards: %d} $spc]
    } elif {$spc > 0} {
        echo [format {Rippling space forwards:  %d} $spc]
    } else {
    	echo {No space rippled}
    }

    return 0
}]

##############################################################################
#				rw-handle-rippled-lines
##############################################################################
#
# SYNOPSIS:	Note that we're handling rippling lines somewhere somehow
# CALLED BY:	
# PASS:		
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 6/25/92	Initial Revision
#
##############################################################################
[defsubr rw-handle-rippled-lines {}
{
    var l [expr ([read-reg bx]*65536)+[read-reg di]]
    var c [value fetch ss:bp.text::LICL_range.text::VTR_start]

    echo [format {Setting region boundary at: line %d   char %d} $l $c]

    return 0
}]

##############################################################################
#				rw-update-region-height
##############################################################################
#
# SYNOPSIS:	Help me help me. I can't remember what they all do.
# CALLED BY:	
# PASS:		
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 6/25/92	Initial Revision
#
##############################################################################
[defsubr rw-update-region-height {}
{
    var ins [convDWFixed [value fetch ss:bp.text::LICL_insertedSpace]]
    var del [convDWFixed [value fetch ss:bp.text::LICL_deletedSpace]]
    var rh  [convDWFixed [value fetch ss:bp.text::LICL_rippleHeight]]
    
    echo [format {Updating region height: inserted %s   deleted %s  rippled %s}
    	    	    $ins $del $rh]

    echo
    echo ================
    echo

    return 0
}]

##############################################################################
#				rw-insert-line
##############################################################################
#
# SYNOPSIS:	Ahahahahahaha
# CALLED BY:	
# PASS:		
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 6/25/92	Initial Revision
#
##############################################################################
[defsubr rw-insert-line {}
{
    var curLine [value fetch ss:bp.text::LICL_line]

    echo [format {Inserting 1 line before %d} $curLine]
    return 0
}]

##############################################################################
#				rw-after-delete
##############################################################################
#
# SYNOPSIS:	Waaaaaaaaaah
# CALLED BY:	
# PASS:		
# RETURN:	
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 6/25/92	Initial Revision
#
##############################################################################
[defsubr rw-after-delete {}
{
    var delCount [value fetch ss:bp.text::LICL_delCount]
    var curLine  [value fetch ss:bp.text::LICL_line]

    if {$delCount!=0} {
        echo [format {Deleting %d lines starting at %d} $delCount $curLine]
	echo [format {Deleted Space: %d,  Total Change in Segment: %s}
			[read-reg dx] 
			[convDWFixed [value fetch ss:bp.text::LICL_insertedSpace]]]
    }

    return 0
}]




#############################################################################
#		tundocalls
#############################################################################
#
# SYNOPSIS:	Prints out undo information.
#
# CALLED BY:	GLOBAL
# PASS:		nada
# RETURN:		nada
#
# KNOWN BUGS/SIDE EFFECTS/IDEAS:
# 
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	atw	7/27/92		Initial version
#
############################################################################
[defcmd tundocalls {{flags {}}} lib_app_driver.text
{Usage:
	tundocalls [-acPCrR]

Examples:
	"tundocalls -a" 	Print out all text undo calls
	"tundocalls -r"		Print run undo calls
	"tundocalls -R"		Print replace undo calls
	"tundocalls -c"	    	Print info when undo information is created
	"tundocalls -cP"	Print info about para attrs only
	"tundocalls -cC"	Print info about char attrs only   
	"tundocalls"		Stop printing out text undo stuff

Synopsis:
	This prints out information about each undo call made to the
	text object.

See also:
	ptext, showcalls
}
{
    	global 	tu_runs tu_replaces caOnly paOnly

    remove-brk tu_runs
    remove-brk tu_replaces
    remove-brk tu_creates
    var caOnly 0
    var paOnly 0
    if {![null $flags]} {
	foreach i [explode [range $flags 1 end chars]] {
	    [case $i in
	    	a {
		    set-replace-brks
		    set-run-brks
		    set-create-brks
		}

	     	c {
		    set-create-brks
		}    
		r {
		    set-run-brks
		}
	     
	     	R {
		    set-replace-brks
		    
		}
	     	C {
		    var caOnly 1
		}    
	     	P {
		    var paOnly 1
		}    
	    	default {
		    error {Unrecognized flag $i}
		}]
	}
    }
}]

#
# Subroutines to set break points for various options in tundocalls
#
[defsubr set-create-brks {}
{
    	global	tu_creates
	    var tu_creates [list   [brk text::TA_AppendRunsInRangeToHugeArray print-append-runs-start]
			    	   [brk	text::AddItemToHugeArray print-run]
		      	    	   [brk text::TA_ARIRTHA_done print-runs-end]
    			    	   [brk	text::TU_CreateUndoForRunModification print-create-delete-undo]
				   [brk ui::GPUSC_startNewChain print-new-chain]
    				   [brk ui::GenProcessUndoPlaybackChain print-playback-chain]
				   [brk ui::GPUEC_endCurrentChain print-end-chain]]
	
}]

[defsubr set-replace-brks {}
{
    	global	tu_replaces
	    var tu_replaces [list   [brk text::SRU_beforeReplaceText print-sru]
			      	    [brk text::LargeReplaceUndo print-lru]]
}]

[defsubr set-run-brks {}
{
    	global	tu_runs
	
	    var tu_runs [list   [brk text::TA_RRFHA_start print-restore-runs]
			    	[brk text::TA_RRFHA_beforeNext print-run]
			    	[brk text::TA_RRFHA_done print-runs-end]
			     	[brk text::TA_DRIR_deleting print-delete-runs-start]
			     	[brk text::TA_DRIR_doingDelete print-run]
	    	    	    	[brk text::TA_DRIR_done print-runs-end]]

}]


[defsubr print-sru {}
{
    echo -n Small Replace
    var charsToInsert [value fetch es:CRD_charsToInsert]
    if {$charsToInsert != 0} {
	echo -n { - }
    	pvmtext es:[getvalue CRD_chars] $charsToInsert
    } else {
	echo { with no text}
    }
    return 0
}]

[defsubr print-lru {}
{
    echo Large Replace
    return 0	
}]
[defsubr get-run-type {runOffset}
{
    global runType 
    #
    # Determine what kind of runs these are
    #
    [case $runOffset in
    	[getvalue text::OFFSET_FOR_TYPE_RUNS]
	{
	    var runType TYPE_RUN
	}
    
	[getvalue text::OFFSET_FOR_GRAPHIC_RUNS]
	{
	    var runType GRAPHIC_RUN
	}

	[expr {[index [symbol get [symbol find field text::VTI_charAttrRuns]] 0] >> 3}]
	{
	    var runType CHAR_RUN
	}
	
	[expr {[index [symbol get [symbol find field text::VTI_paraAttrRuns]] 0] >> 3}]
	{
	    var runType PARA_RUN
	}
	
	default
	{
	    error {Invalid run type $runoffset}
	}]
    return [check-if-printable-run]
}]	
[defsubr print-restore-runs {}
{
    if {[get-run-type [read-reg cx]] != 0} {	
	echo -n {Restoring }
	output-run-name 
	echo -n { }
	echo \{
    }
    return 0
}]

[defsubr print-runs-end {}
{
    if {[check-if-printable-run]} {
	echo \}
	echo
    }
    return 0
}]
[defsubr check-if-printable-run {}
{
    global caOnly paOnly runType
    if {$caOnly != 0 && [string compare $runType CHAR_RUN]} {
    	return 0
    } elif {$paOnly != 0 && [string compare $runType PARA_RUN]} {
    	return 0
    } else {
    	return 1
    }
}]


[defsubr output-run-name {}
{
    global runType
    #
    # Determine what kind of runs these are
    #
    [case $runType in
    	TYPE_RUN
	{
    	    echo -n type runs
	}
    
	GRAPHIC_RUN
	{
    	    echo -n graphic runs
	}

	CHAR_RUN
	{
    	    echo -n char attr runs
	}
	
	PARA_RUN
	{
    	    echo -n para attr runs
	}
	
	default
	{
	    error {Invalid run type $runType}
	}]        
}]
[defsubr print-delete-runs-start {}
{
      if {[get-run-type [read-reg cx]] != 0} {
	  echo -n {Deleting }
	  output-run-name
	  echo { in range} ([value fetch ss:bp.text::VTR_start], [value fetch ss:bp.text::VTR_end]) \{
      }
      return 0	
}]

[defsubr print-run {}
{
    if {[check-if-printable-run]} {
	echo {    } Pos: [expr {[read-reg dl] << 16 | [read-reg ax]}], Token: [read-reg bx]
    }
    return 0
}]

[defsubr print-append-runs-start {}
{
    if {[get-run-type [read-reg cx]] != 0} {
	echo -n {Appending }
	output-run-name
	echo { in range} ([value fetch ss:bp.text::VTR_start], [value fetch ss:bp.text::VTR_end])  to harray \{
    }
    return 0
}]

[defsubr print-new-chain {}
{
    echo
    echo ---------------- Starting new chain -----------------
    echo
    return 0
}]
[defsubr print-playback-chain {}
{
    echo
    echo ---------------- Starting playback chain -----------------
    echo
    return 0    
}]
[defsubr print-end-chain {}
{
    echo
    echo ---------------- Ending chain -----------------
    echo
    return 0
}]
[defsubr print-create-delete-undo {}
{
    if {[get-run-type [read-reg cx]] != 0} {
	echo -n {Creating delete undo item for }
	output-run-name
	echo { in range} ([value fetch ss:bp.text::VTR_start], [value fetch ss:bp.text::VTR_end])  to harray
	echo
    }
    return 0
}]    
[defsubr remove-brk {bname} {
	global	$bname

    if {![null $[var $bname]]} {
	foreach i [var $bname] {
	    catch {brk clear $i}
	}
	var $bname {}
    }
}]


##############################################################################
#				text-fixup
##############################################################################
#
# SYNOPSIS:	fixup a large text object.
# CALLED BY:	
# PASS:		nothing
# RETURN:	nothing
# SIDE EFFECTS:	fixes up text object data-structures
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 6/25/92	Initial Revision
#
##############################################################################
[defcommand text-fixup {} {lib_app_driver.text lib_app_driver.geowrite}
{Usage:
    Use it like this:
	
	- Run geos under swat, run swat on the development system
	
    	- Run GeoWrite
	
	- Open the GeoWrite file that needs fixing
	
    	- Set the breakpoint in swat:
    	    	patch text::CalculateRegions
	    	=> text-fixup
    	  This will set a breakpoint at the right spot
	
    	- Turn on the error-checking code in swat:
    	    	ec +text

    	- Enter a <space> into the document, this forces recalculation
	  which will cause CalculateRegions to be called which will cause
	  text-fixup to be called.

    	If the world is good, this code should patch together the file.
	If it's not, you'll get a FatalError right now.
	
	- Turn off the ec code and disable the fixup breakpoint.
	    	ec none
    	    	dis <breakpoint number>
		continue

    	- Delete the space and save the file.
	
	To do another file, you can just enable the breakpoint once the new
	file is open and turn on the ec code.

Synopsis:
    Help fix up trashed documents.

Notes:

See also:

}
{
    #
    # Fetch the text object (*ds:si) and make sure it's a large object.
    #
    var addr	 [addr-parse *ds:si]
    var seg 	 [handle segment [index $addr 0]]
    var off 	 [index $addr 1]
    var VTI 	 [expr $off+[value fetch $seg:$off.ui::Vis_offset]]
    var instance [value fetch $seg:$VTI text::VisTextInstance]
    
    if {[field [field $instance VTI_storageFlags] VTSF_LARGE]==0} {
    	error {text-fixup can only be run on a large model text object}
    }
    
    #
    # Let the user know what's going on.
    #
    echo [format {Fixing up object *%04xh:%04xh} [read-reg ds] [read-reg si]]
    
    #
    # For each region, fix it up.
    #
    global  tf_curLine
    global  tf_curOffset
    var tf_curLine   0
    var tf_curOffset 0

    var file [text-object-get-file $seg $instance]
    var rchunk [value fetch $seg:$VTI.text::VLTI_regionArray [type word]]
    carray-enum *$seg:$rchunk region-fixup [list $seg $instance $file]

    #
    # Let them know what to do...
    #
    echo {The error checking code in CalculateRegions should now verify that}
    echo {the new values are correct. If it dies with a fatal error then}
    echo {the file was not salvagable. If it does not die, save the file}
    echo {because it has been correctly salvaged.}
}]

##############################################################################
#				region-fixup
##############################################################################
#
# SYNOPSIS:	Fixup a single region.
# CALLED BY:	text-fixup via carray-enum
# PASS:		elnum	- Element number (region number)
#   	    	addr	- Address expression of region
#   	    	rsize	- Size of region
#   	    	extra	- List containing:
#   	    	    	    seg	    - Segment of the instance
#   	    	    	    instance- VisTextInstance structure
#   	    	    	    file    - File containing huge-arrays
# RETURN:	0 indicating "keep going"
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 4/ 3/92	Initial Revision
#
##############################################################################
[defsubr region-fixup {elnum addr rsize extra}
{
    #
    # Extract useful information
    #
    var seg 	  [index $extra 0]
    var instance  [index $extra 1]
    var file	  [index $extra 2]
    var lineArray [field $instance VTI_lines]

    #
    # These contain the starting line and offset for this region.
    #
    global  tf_curLine
    global  tf_curOffset
    
    echo [format {Fixing up region %d} $elnum]
    
    #
    # For each line in the region add the height.
    #
    global rf_lineSum
    global rf_lineCount
    var    rf_lineSum 0
    var	   rf_lineCount [value fetch $addr.text::VLTRAE_lineCount]
    
    echo [format {Summing %d line heights} $rf_lineCount]

    [harray-enum $file $lineArray line-add-height [list $seg $instance $file]]

    #
    # rf_lineSum contains the sum of the line-heights for this line.
    #
    # We want to convert it to the integer and fraction components
    # and then save them.
    #
    var lsInt  [expr $rf_lineSum/256]
    var lsFrac [expr $rf_lineSum%256]
    
    var olsInt  [value fetch $addr.text::VLTRAE_calcHeight.WBF_int]
    var olsFrac [value fetch $addr.text::VLTRAE_calcHeight.WBF_frac]
    
    #
    # Let them know if there was a difference...
    #
    echo
    echo [format {Old Height:  Integer: %d  Fraction: %d}
    	    	    $olsInt $olsFrac]
    echo [format {New Height:  Integer: %d  Fraction: %d}
    	    	    $lsInt $lsFrac]

    #
    # Save new value...
    #
    value store $addr.text::VLTRAE_calcHeight.WBF_int  $lsInt
    value store $addr.text::VLTRAE_calcHeight.WBF_frac $lsFrac
    
    echo [format {New value saved: %3.3f}
    	    	[convWBFixed [value fetch $addr.text::VLTRAE_calcHeight]]]

    #
    # Dirty the block.
    #
    echo {Dirtying the block.}

    var a    [addr-parse $addr]
    var bs   [handle segment [index $a 0]]
    var bhan [value fetch $bs:LMBH_handle]
    
    call-patient VMDirty bp $bhan
    
    #
    # Set up for next call.
    #
    var tf_curLine [expr $tf_curLine+[value fetch $addr.text::VLTRAE_lineCount]]
    
    #
    # Signal that we want to keep going.
    #
    echo
    return 0
}]

##############################################################################
#				line-add-height
##############################################################################
#
# SYNOPSIS:	Add the height of this line to the total
# CALLED BY:	region-fixup via harray-enum
# PASS:		elnum	- Element number (region number)
#   	    	addr	- Address expression of region
#   	    	rsize	- Size of region
#   	    	extra	- List containing:
#   	    	    	    seg	    - Segment of the instance
#   	    	    	    instance- VisTextInstance structure
#   	    	    	    file    - File containing huge-arrays
# RETURN:	0 indicating "keep going" if we haven't reached the end.
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 4/ 3/92	Initial Revision
#
##############################################################################
[defsubr line-add-height {elnum addr rsize extra}
{
    #
    # Give the user some feedback.
    #
    global  rf_lineSum
    global  rf_lineCount
    global  tf_curLine
    
    if {$elnum >= $tf_curLine} {
#        echo -n {.}
	if {$rf_lineCount==0} {
	    #
	    # Stop processing
	    #
	    return 1
	} else {
	    #
	    # Get the height.
	    #
	    var lhInt  [value fetch $addr.text::LI_hgt.WBF_int]
	    var lhFrac [value fetch $addr.text::LI_hgt.WBF_frac]

	    var lh [expr ($lhInt*256)+$lhFrac]

	    var rf_lineSum [expr $rf_lineSum+$lh]
	    
	    echo [format {Added %3d.%03d to get %3d.%03d} 
	    	    	$lhInt $lhFrac 
			[expr $rf_lineSum/256]
			[expr $rf_lineSum%256]]

	    #
	    # One less line to do...
	    #
	    var rf_lineCount [expr $rf_lineCount-1]
	}
    }
    #
    # Keep processing
    #
    return 0
}]


##############################################################################
#				ptreg
##############################################################################
#
# SYNOPSIS:	Print lines from a text region.
# CALLED BY:	user
# PASS:	    	reg	- Region to print lines for
#   optional	obj 	- Address expression of the object to print from
#   	    	    	  Defaults to *ds:si
#
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	12/ 9/92	Initial Revision
#
##############################################################################
[defcommand ptreg {reg {obj *ds:si}} lib_app_driver.text
{Usage:
    ptreg start [obj]

Examples:
    "ptreg 12"	    	    Print lines for region 12
    "ptreg 12 ^lcx:dx"	    Print lines for region 12 of object ^lcx:dx

Synopsis:
    Print information about the lines in a region.
    
Notes:

See also:
    ptext
}
{
    #
    # Fetch the text object (*ds:si) and make sure it's a large object.
    #
    var addr	 [addr-parse $obj]
    var seg 	 [handle segment [index $addr 0]]
    var off 	 [index $addr 1]
    var VTI 	 [expr $off+[value fetch $seg:$off.ui::Vis_offset]]
    var instance [value fetch $seg:$VTI text::VisTextInstance]
    
    if {[field [field $instance VTI_storageFlags] VTSF_LARGE]==0} {
    	error {ptreg can only be invoked for a large object}
    }

    #
    # Compute the starting line and offset for the region.
    #
    global  tf_curLine
    global  tf_curOffset
    global  tf_regLineCount
    var tf_curLine   0
    var tf_curOffset 0
    var tf_regLineCount 0

    var file [text-object-get-file $seg $instance]
    var rchunk [value fetch $seg:$VTI.text::VLTI_regionArray [type word]]
    carray-enum *$seg:$rchunk region-get-start [list $seg $instance $file $reg]
    
    #
    # Now that we have the starting line and offset for the region in question
    # we print the lines.
    #
    global pl_lineStart
    var	   pl_lineStart $tf_curOffset

    var lineArray [field $instance VTI_lines]

    [harray-enum $file $lineArray ptreg-print-line
    	[list $seg $instance $file [symbol find type geos::LineInfo]]]
}]

##############################################################################
#				region-get-start
##############################################################################
#
# SYNOPSIS:	Get the start line and offset for a region.
# CALLED BY:	ptreg via carray-enum
# PASS:		elnum	- Element number (region number)
#   	    	addr	- Address expression of region
#   	    	rsize	- Size of region
#   	    	extra	- List containing:
#   	    	    	    seg	    - Segment of the instance
#   	    	    	    instance- VisTextInstance structure
#   	    	    	    file    - File containing huge-arrays
#			    reg	    - The region we're really interested in
# RETURN:	0 indicating "keep going"
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 4/ 3/92	Initial Revision
#
##############################################################################
[defsubr region-get-start {elnum addr rsize extra}
{
    #
    # Extract useful information
    #
    var reg	  [index $extra 3]

    #
    # These contain the starting line and offset for this region.
    #
    if {$reg==$elnum} {
	#
	# Time to stop, we've reached the region.
	#
	global tf_regLineCount
	var tf_regLineCount [value fetch $addr.text::VLTRAE_lineCount]

    	return 1
    }
    
    #
    # We need to continue summing the counts and offsets
    #
    global  tf_curLine
    global  tf_curOffset
    
    var tf_curLine   [expr $tf_curLine+[value fetch $addr.text::VLTRAE_lineCount]]
    var tf_curOffset [expr $tf_curOffset+[value fetch $addr.text::VLTRAE_charCount]]
    
    return 0
}]

##############################################################################
#				ptreg-print-line
##############################################################################
#
# SYNOPSIS:	print a line, if it's in the current region.
# CALLED BY:	ptreg via carray-enum
# PASS:		elnum	- Element number (region number)
#   	    	addr	- Address expression of region
#   	    	rsize	- Size of region
#   	    	extra	- List containing:
#   	    	    	    seg	    - Segment of the instance
#   	    	    	    instance- VisTextInstance structure
#   	    	    	    file    - File containing huge-arrays
# RETURN:	0 indicating "keep going"
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	 4/ 3/92	Initial Revision
#
##############################################################################
[defsubr ptreg-print-line {elnum addr rsize extra}
{
    #
    # We'll need all of these...
    #
    global  tf_curLine
    global  tf_curOffset
    global  tf_regLineCount
    
    #
    # Check to see if we've reached the starting line
    #
    if {$elnum<$tf_curLine} {
	#
	# We haven't reached the first line of the region yet.
    	return 0
    }
    
    #
    # We have reached the starting line, see if we're past the end.
    #
    if {$elnum>=($tf_curLine+$tf_regLineCount)} {
	#
	# We're past the end...
	#
    	return 1
    }
    
    #
    # It's a line we want to print
    #
    print-one-line $elnum $addr $rsize $extra

    return 0
}]
