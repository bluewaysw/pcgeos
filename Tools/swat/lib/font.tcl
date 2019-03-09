##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	SWAT -- System library.
# FILE: 	font.tcl
# AUTHOR: 	Gene Anderson
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#	plist			print a list of structures in an lmem chunk
#	fonts			print different information about font usage
#	pchar			print a character as a bitmap 
#	pfont			do pchar on the whole font
#	pbitmap			print out a generic bitmap
#	pfontinfo		print font info for a font
#
# DESCRIPTION:
#	For printing lists of structures
#
#	$Id: font.tcl,v 3.12 90/10/22 22:55:20 gene Exp $
#
###############################################################################

##############################################################################
#				plist
##############################################################################
#
# SYNOPSIS:	print a list of structures in an lmem chunk.
# PASS:		$structure - structure in array
#   	    	$addr - address of lmem handle
#   	    	$field - field to check (optional)
#   	    	$value - value to match in field (optional)
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	9/14/90		Initial Revision
#
##############################################################################

[defcommand plist {args} output
{Prints out a list of structures stored in an lmem chunk.  It takes two
arguments, the structure type that makes up the list, and the lmem handle
of the chunk. eg. plist FontsInUseEntry ds:di}

{
    #
    # Usage: plist  	structure
    #			address of lmem handle
    #		opt:	field in structure to check
    #		opt:	value in field to match
    #
	
    #
    # Parse the arguments
    #
    var matchflag 0

    var structure [index $args 0]
    var args [cdr $args]
    var addr [index $args 0]
    var args [cdr $args]
    var matchflag 0
    if {![null $args]} {
	var entry [index $args 0]
	var args [cdr $args]
	var matchvalue [index [addr-parse [index $args 0]] 1]
    	var matchflag 1
    }
    #
    # Set various variables that will be needed.
    #
    var address     [addr-parse $addr]
    var	seg	    [handle segment [index $address 0]]
    var offset	    [index $address 1]
    var chunkAddr   [value fetch $seg:$offset word]
    var chunkSize   [expr [value fetch $seg:[expr $chunkAddr-2] word]-4]

    var strucPtr $chunkAddr
    for {} {$strucPtr < [expr $chunkAddr+$chunkSize]} {var strucPtr [expr $strucPtr+[size $structure]]} {
    	if {$matchflag} {
    	    var val	[value fetch $seg:$strucPtr.$entry]
    	    if {$val == $matchvalue} {
	    	print $structure $seg:$strucPtr
    	    }
    	} else {
    	    	print $structure $seg:$strucPtr
    	}
    }
}]

##############################################################################
#				fonts
##############################################################################
#
# SYNOPSIS:	print a variety of information about fonts in the system
# PASS:		flags:
#   	    	    -a	    - list of fonts
#   	    	    -d	    - list of font drivers available
#   	    	    -u (ID) - list of fonts currently in use. Optional font ID.
#   	    	    -s - print summary of above information
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	9/14/90		Initial Revision
#
##############################################################################

[defcommand fonts {args} output|kernel
{Prints a variety of useful information about font usage.  Takes some
interesting looking flags...
	-a        list of fonts available
	-d        list of font drivers available
	-u (ID)   list of fonts currently in use. Optional font ID to match.
	-s        summary of above information

Defaults to showing the summary.}
{
    #
    # parse the flags
    #

    var drivers 0 usage 0 available 0 summary 0

    if {[length $args] > 0 && [string m [index $args 0] -*]} {
	#
	# Examine the flags word for things we know and set vars
	# accordingly.
	#
	foreach i [explode [range [index $args 0] 1 end chars]] {
	    [case $i in
		a {var available 1}
		d {var drivers 1}
		u {var usage 1}
		s {var summary 1}
		default {error [format {unknown option %s} $i]}
	    ]
	}
	#
	# Shift the first arg off the list
	#
	var args [range $args 1 end]
    	#
    	# If doing fonts in use, check for optional font ID to match.
    	#
    	if {$usage} {
    	    var matchID 0
    	    if {![null $args]} {
	    	var matchID [index [addr-parse [index $args 0]] 1]
    	    	var args [cdr $args]
    	    }
    	}
    } else {
	var summary 1
    }

    #
    # set up some initial conditions
    #
    var seg [fontinfoaddr]

    #
    # do the right thing(s)
    #

    if {$available} {
	echo {available fonts:}
	echo {----------------}
	var lhan 16
	plist FontsAvailEntry $seg:$lhan
    }
    if {$usage} {
	echo {fonts in use:}
	echo {-------------}
	var lhan 18
    	if {$matchID} {
	    plist FontsInUseEntry $seg:$lhan FIUE_fontID $matchID
    	} else {
    	    plist FontsInUseEntry $seg:$lhan
    	}
    }
    if {$drivers} {
	echo {available drivers:}
	echo {------------------}
	var lhan 20
	plist DriversAvailEntry $seg:$lhan
    }
    if {$summary} {
	echo {available fonts:}
	echo {----------------}
	var lhan 16

	var bitmaps [countlist $seg:$lhan  FontsAvailEntry]
	echo [format {%d %s available} $bitmaps [pluralize font $bitmaps]]

	echo {}
	echo {fonts in use:}
	echo {-------------}
	var lhan 18

	var used [countlist $seg:$lhan FontsInUseEntry]
    	var mt [countlist $seg:$lhan FontsInUseEntry FIUE_dataHandle 0]
    	var inuse [expr $used-$mt]
    	var del [countlist $seg:$lhan FontsInUseEntry FIUE_refCount 0]
	echo [format {%d %s in use} $inuse [pluralize face $inuse]]
    	echo [format {%d can be deleted} [expr $del-$mt]]
    	echo [format {%d %s in list} $used [pluralize entry $used]]

	var complex [countlist $seg:$lhan FontsInUseEntry FIUE_flags FBF_IS_COMPLEX ismask]
	echo [format {%d %s complex transformations} $complex [pluralize has $complex]]

	var lhan 20
	var drivers [countlist $seg:$lhan DriversAvailEntry]
	echo {}
	echo {available drivers:}
	echo {------------------}
	echo [format {%d %s %s loaded} $drivers [pluralize driver $drivers] [pluralize is $drivers]]

    }
}]

##############################################################################
#				isbitset
##############################################################################
#
# SYNOPSIS:	check to see if bit is set in record
# PASS:		$bit - name of bit field
#   	    	$record - actual value of record
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	9/14/90		Initial Revision
#
##############################################################################

[defsubr isbitset {bit record}
{
	while {![null $record]} {
		var field [index $record 0]
		var name [index $field 0]
		if {![string compare $bit $name]} {
		    if {[index [index $field 2] 0]} {
			return 1
		    }
		}
		var record [cdr $record]
	}
	return 0
}]

##############################################################################
#				countlist
##############################################################################
#
# SYNOPSIS:	count entries in a list, with optional filter
# PASS:		$addr - ptr to list
#   	    	$structure - structures in list
#   	    	$field - optional field in structure
#   	    	$value - value in field to match
#   	    	$ismask - non-NULL if value is a bit mask
# RETURN:	$count - # of matching entries in list
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	9/14/90		Initial Revision
#
##############################################################################

[defsubr countlist {args}
{
    #
    # Parse the arguments
    #
    var matchflag 0

    var addr [index $args 0]
    var args [cdr $args]
    var struct [index $args 0]
    var args [cdr $args]
    if {![null $args]} {
	var entry [index $args 0]
	var args [cdr $args]
	var matchvalue [index $args 0]
	var args [cdr $args]
	if {[null $args]} {
	    var matchflag 1
	    var matchval [index [addr-parse $matchvalue] 1]
	} else {
	    var matchflag 2
	}
    }
	
    #
    # Get the lmem handle, dereference it, and find out how big
    # the chunk is.
    #
    var address     [addr-parse $addr]
    var	seg	    [handle segment [index $address 0]]
    var offset	    [index $address 1]
    var chunkAddr   [value fetch $seg:$offset word]
    var chunkSize   [expr [value fetch $seg:[expr $chunkAddr-2] word]-4]
    #
    # Search the list for the value passed, in the field of the
    # structure specified.
    #
    var count 0
    var strucPtr $chunkAddr

    for {} {$strucPtr < [expr $chunkAddr+$chunkSize]} {var strucPtr [expr $strucPtr+[size $struct]]} {
	if {$matchflag != 0} {
	    var val	[value fetch $seg:$strucPtr.$entry]
	}

	[case $matchflag in
	    0 {var count [expr $count+1]}
	    1 {
		if {$val == $matchval} {
		    var count [expr $count+1]
		}
	      }
	    2 {
		var biton [isbitset $matchvalue $val]
		if {$biton} {
		    var count [expr $count+1]
		}
	      }
	]
    }
    return $count
}]

##############################################################################
#				pchar
##############################################################################
#
# SYNOPSIS:	print bitmap of a character
# PASS:		$char - character to print (eg. C_TRADEMARK)
#   	    	$addr - address of font (eg. ^h1bf0h)
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	9/14/90		Initial Revision
#
##############################################################################

[defcommand pchar {args} output
{Prints out the bitmap of a character.  Takes two arguments, the character to
print, and the address of the font.  If none is given, ^hbx is used.
The character can either be a numeric constant or a character.}
{
    #
    # Parse the flags, if any.
    #
    var compact 0
    var opts [index $args 0]
    if {[string m $opts -*]} {
	#
	# Gave us some flags
	#
	foreach i [explode [range $opts 1 end chars]] {
	    [case $i in
		c {var compact 1}
		default {error [format {unknown option %s} $i]}]
	}
        var args [cdr $args]
    }
    var char [index $args 0]
    if [null [index $args 1]] {
	var addr {^hbx}
    } else {
        var addr [index $args 1]
    }

    #
    # Check out the chararcter -- see if it's a numeric constant
    # If it's a chararcter, convert it to a constant.
    #
    if {[catch {eval {expr $char+0}}] != 0} {
        if {[string m [index $args 0] C_* ]} {
            var pchar [index [addr-parse $char] 1]
    	} else {
    	    [scan $char %c pchar]
    	}
    } else {
        var pchar $char
    }
    #
    # Set various variables that will be needed.
    #
    var address     [addr-parse $addr]
    var	seg	    [handle segment [index $address 0]]

    var first [field [value fetch $seg:0 FontBuf] FB_firstChar]
    var last [field [value fetch $seg:0 FontBuf] FB_lastChar]
    var ptrs [size FontBuf]
    var cte_size [size CharTableEntry]

    if {$pchar < $first} {
	echo {no such chararcter}
    } elif {$pchar > $last} {
	echo {no such chararcter}
    } else {
	var entry [expr $ptrs+($pchar-$first-1)*$cte_size]
	var data [field [value fetch $seg:$entry CharTableEntry] CTE_dataOffset]
	if {$data <=3} {
	    if {$compact == 0} {
    	    	echo {}
	    	echo -n [format %s%d%s%x {CHARACTER: } $pchar { / 0x} $pchar ]
    	    	echo [format %s%s { / } [prenum Chars $pchar]]
		print CharTableEntry $seg:$entry
 	        [case $data in
		    0 {echo {NO CHARACTER}}
		    1 {echo {NOT LOADED}}
		    2 {echo {NOT BUILT}}
		    3 {echo {ERROR -- UNKNOWN FLAG}} ]
	    }
	} else {
	    echo {}
	    echo -n [format %s%d%s%x {CHARACTER: } $pchar { / 0x} $pchar ]
    	    echo [format %s%s { / } [prenum Chars $pchar]]
	    print CharTableEntry $seg:$entry
    	    var flags [value fetch $seg:FB_flags]
    	    if {[field $flags FBF_IS_REGION]} {
    	    	print RegionCharData $seg:$data
    	    	var ptr [expr [index [addr-parse RCD_data] 1]+$data]
    	    	var height [field [value fetch $seg:0 FontBuf] FB_height]
    	    	if {[index [index $height 1] 2] <= 80} {
    	            preg -g $seg:$ptr
    	    	}
    	    	preg $seg:$ptr
    	    } else {
	    	var width [field [value fetch $seg:$data CharData] CD_pictureWidth]
	    	var height [field [value fetch $seg:$data CharData] CD_numRows]
	    	var first [field [value fetch $seg:$data CharData] CD_yoff]
	    	var left [field [value fetch $seg:$data CharData] CD_xoff]
	    	var bwidth [expr ($width+7)/8]
	    	echo [format %s%d {pixel width = } $width]
	    	echo [format %s%d {height = } $height]
	    	echo [format %s%d {first row = } $first]
	    	echo [format %s%d {first col = } $left]
	    	echo [format %s%d {byte width = } $bwidth]
	    	echo {}
	    	var ptr [expr [index [addr-parse CD_data] 1]+$data]
	    	pbitmap $seg:$ptr $width $height
    	    }
	}
    }
}]

##############################################################################
#				pfont
##############################################################################
#
# SYNOPSIS:	print all characters in a font
# PASS:     	$addr - address of font (eg. ^h1bf0h)
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	9/14/90		Initial Revision
#
##############################################################################

[defcommand pfont {{addr ^hbx}} output
{Prints out bitmaps of a font.  Takes one argument, the address of the
font. If none is given, ^hbx is used.}
{
    #
    # Set various variables that will be needed.
    #
    var address     [addr-parse $addr]
    var	seg	    [handle segment [index $address 0]]

    var first [field [value fetch $seg:0 FontBuf] FB_firstChar]
    var last [field [value fetch $seg:0 FontBuf] FB_lastChar]

    print FontBuf $seg:0
    echo {------------------------------------------}
    for {var i $first} {$i <= $last} {var i [expr $i+1]} {
	pchar -c $i $addr
    }
}]

##############################################################################
#				pusage
##############################################################################
#
# SYNOPSIS:	print LRU values for characters in a font
# PASS:     	$addr - address of font (eg. ^h1bf0h)
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	9/14/90		Initial Revision
#
##############################################################################

[defcommand pusage {{addr ^hbx}} output
{Prints out usage of characters in a font. Takes one argument, the address
of the font. If none is given, ^bx is used.}
{
    #
    # Set various variables that will be needed.
    #
    var address     [addr-parse $addr]
    var	seg	    [handle segment [index $address 0]]

    var first [field [value fetch $seg:0 FontBuf] FB_firstChar]
    var last [field [value fetch $seg:0 FontBuf] FB_lastChar]

    var cte_size [size CharTableEntry]
    var flags [field [value fetch $seg:0 FontBuf] FB_flags]
    var isreg [isbitset FBF_IS_REGION $flags]
    var cdh_size [expr [size CharData]-1]

    var	size [field [value fetch $seg:0 FontBuf] FB_dataSize]
    var hcount [field [value fetch $seg:0 FontBuf] FB_heapCount]
    var ptr [expr [size FontBuf]-$cte_size]
    var lruScore 0 lruChar 0 lruPtr 0xffff
    var fsize $ptr
    var maker [field [value fetch $seg:0 FontBuf] FB_maker]
    var bitmap [index [addr-parse MAKER_BITMAP] 1]
    if {$maker != $bitmap} {
    	var fsize [expr $fsize+[size CharGenData]]
    }
    #
    # Print an informative header...
    #
    echo [format %s%d%s%x%s {size = } $size { / 0x} $size { bytes}]
    echo [format %s%d {heap count = } $hcount]
    echo {data	size	usage 	char}
    echo {----------------------------}
    #
    # Cycle through all the characters in the font.
    #
    for {var i $first} {$i <= $last} {var i [expr $i+1]} {
	var data [field [value fetch $seg:$ptr CharTableEntry] CTE_dataOffset]
	var usage [field [value fetch $seg:$ptr CharTableEntry] CTE_usage]
    	var score [expr $hcount-$usage]
    	if {$data > 3} {
    	    #
    	    # If the characters are stored as regions, then the size
    	    # is stored with the data. If they are stored as bitmaps,
    	    # then the size is (pixelwidth/8)*height+header.
    	    #
    	    if {$isreg} {
    	    	var sze [field [value fetch $seg:$data RegionCharData] RCD_size]
    	    } else {
    	    	var w [field [value fetch $seg:$data CharData] CD_pictureWidth]
    	    	var w [expr ($w+7)/8]
    	    	var h [field [value fetch $seg:$data CharData] CD_numRows]
    	    	var sze [expr $w*$h+$cdh_size]
    	    }
    	    #
    	    # If the score is higher, the we have a new LRU char.
    	    # If the score is the same, then the char is a new LRU
    	    # only if it is older than the previous LRU.
    	    #
            if {$score > $lruScore} {
    	    	var lruChar $i
    	    	var lruScore $score
    	    	var lruPtr $data
    	    } elif {$score == $lruScore} {
    	    	if {$data < $lruPtr} {
    	    	    var lruChar $i
    	    	    var lruScore $score
    	    	    var lruPtr $data
    	    	}
    	    }
    	    echo -n [format %s%x {0x} $data]
    	    echo -n [format %s%s%x {	} {0x} $sze]
    	    echo -n [format %s%d%s {	} $usage { 	}]
    	    echo [prenum Chars $i]
    	    var fsize [expr $fsize+$sze]
    	}
    	var fsize [expr $fsize+$cte_size]
    	var ptr [expr $ptr+$cte_size]
    }
    echo [format %s%s {LRU = } [prenum Chars $lruChar]]
    echo [format %s%d%s%x%s {actual size = } $fsize { / 0x} $fsize { bytes}]
}]

##############################################################################
#				pfontinfo
##############################################################################
#
# SYNOPSIS:	print font info for a font.
# PASS:     	$font - fond ID (eg. FONT_URW_ROMAN)
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	9/14/90		Initial Revision
#
##############################################################################

[defcommand pfontinfo {font} output|kernel
{Prints font header information for a font. Takes one argument, the
font ID.}

{
    #
    # Get the FontsAvailEntry of the font, and the lmem handle of
    # the FontInfo chunk.
    #
    var availPtr [isfontavail $font]
    var seg [fontinfoaddr]
    var lhan [value fetch $seg:$availPtr.FAE_infoHandle]
    var chunkAddr   [value fetch $seg:$lhan word]
    var chunkSize   [expr [value fetch $seg:[expr $chunkAddr-2] word]-4]
    print FontInfo $seg:$chunkAddr
    #
    # From the FontInfo chunk, get the start and size of the outline
    # entires and print them.
    #
    var outPtr	[expr $chunkAddr+[value fetch $seg:$chunkAddr.FI_outlineTab]]
    var outEnd	[expr $chunkAddr+[value fetch $seg:$chunkAddr.FI_outlineEnd]]
    echo {outlines}
    echo {--------}
    for {} {$outPtr < $outEnd} {var outPtr [expr $outPtr+[size OutlineDataEntry]]} {
        print OutlineDataEntry $seg:$outPtr
    }
    #
    # From the FontInfo chunk, get the start and size of the
    # bitmap entries and print them.
    #
    var outPtr	[expr $chunkAddr+[value fetch $seg:$chunkAddr.FI_pointSizeTab]]
    var outEnd	[expr $chunkAddr+[value fetch $seg:$chunkAddr.FI_pointSizeEnd]]
    echo {bitmaps}
    echo {-------}
    for {} {$outPtr < $outEnd} {var outPtr [expr $outPtr+[size PointSizeEntry]]} {
	print PointSizeEntry $seg:$outPtr
    }
}]

##############################################################################
#				isfontavail
##############################################################################
#
# SYNOPSIS:	Find the FontsAvailEntry for a font.
# PASS:		$fontid - FontID of font to fine
# RETURN:	$off - offset of FontsAvailEntry for font
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	10/10/90		Initial Revision
#
##############################################################################

[defsubr isfontavail {fontid}
{
    #
    # set the FontID to find
    #
    var font [index [addr-parse $fontid] 1]

    #
    # Get the lmem handle, dereference it, and find out how big the chunk is.
    #
    var seg 	    [fontinfoaddr]
    var lhan 16
    var chunkAddr   [value fetch $seg:$lhan word]
    var chunkSize   [expr [value fetch $seg:[expr $chunkAddr-2] word]-4]

    #
    # Search the list for the font ID that was passed.
    #
    var strucPtr $chunkAddr
    var found 0

    for {} {$found == 0 && ($strucPtr < [expr $chunkAddr+$chunkSize])} {var strucPtr [expr $strucPtr+[size FontsAvailEntry]]} {
	var fid	[value fetch $seg:$strucPtr.FAE_fontID]
	if {$fid == $font} {
		var availPtr $strucPtr
		var found 1
        }
    }
    if {$found == 0} {
	error [format {font %s not available} $fontid]
    } else {
    	return $availPtr
    }
}]

##############################################################################
#				fontinfoaddr
##############################################################################
#
# SYNOPSIS:	Return the address of the font info block.
# PASS:		none
# RETURN:	$seg - segment of font info block
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	10/10/90		Initial Revision
#
##############################################################################

[defsubr fontinfoaddr {}
{
    var han [value fetch kdata:[value fetch fontBlkHandle] HandleMem]
    return [field $han HM_addr]
}]
