##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
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
#	pfontinfo		print font info for a font
#   	showfonts   	    	show loading, building of fonts
#
# DESCRIPTION:
#	For printing lists of structures
#
#	$Id: font.tcl,v 3.32.11.1 97/03/29 11:28:06 canavese Exp $
#
###############################################################################

require	pncbitmap   putils

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

[defcmd plist {args} print
{Usage:
    plist <structure> <address of lmem handle> [<field>] [<value>]

Synopsis:
Prints out a list of structures stored in an lmem chunk.  It takes two
arguments, the structure type that makes up the list, and the lmem handle
of the chunk. eg. plist FontsInUseEntry ds:di
}
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
	var matchvalue [getvalue [index $args 0]]
    	var matchflag 1
    }
    #
    # Set various variables that will be needed.
    #
    var address     [addr-parse $addr]
    var	seg	    [handle segment [index $address 0]]
    var offset	    [index $address 1]
    var chunkAddr   [value fetch $seg:$offset word]
    var chunkSize   [expr [value fetch $seg:[expr $chunkAddr-2] word]-2]

    var strucPtr $chunkAddr
    for {} {$strucPtr < [expr $chunkAddr+$chunkSize]} {var strucPtr [expr $strucPtr+[size $structure]]} {
    	if {$matchflag} {
    	    var val	[value fetch $seg:$strucPtr.$entry]
    	    if {$val == $matchvalue} {
	    	_print $structure $seg:$strucPtr
    	    }
    	} else {
    	    	_print $structure $seg:$strucPtr
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

[defcmd fonts {args} {system.font lib_app_driver.font}
{Usage:
    fonts [<args>]

Examples:
    "fonts"	    summarize general font usage
    "fonts -u" 	    list fonts currently in use

Synopsis:
    Print various font info.

Notes:
    * The args argument may be chosen from the following:

	-a         list of fonts available
	-d         list of font drivers available
	-u [<ID>]  list of fonts currently in use. Optional font ID to match.
    	-c  	   list of font files currently cached
	-s         summary of above information
    	-f  	   list of available fonts, giving the face name & the file name

      If no argument is specified the default is to show the summary.

    * When using other commands you probably need to pass them the 
      handle in FIUE_dataHandle.  When you don't have the font's handle
      ready, the best way is to use "fonts -u" to find the font at the
      right point size and then grab the handle from there.

See also:
    pfont, pfontinfo, pusage, pchar, pfontinfo.
}
{
    #
    # parse the flags
    #

    var drivers 0 usage 0 available 0 summary 0 fontcache 0 files 0

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
    	    	c {var fontcache 1}
		f {var files 1}
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
	    	var matchID [getvalue [index $args 0]]
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
    if {$files} {
    	echo {available fonts & their files:}
	echo {------------------------------}
    	pfontfiles $seg 16
    }
    if {$usage} {
	echo {fonts in use:}
	echo {-------------}
	var lhan 18
    	if {$matchID} {
	    plist FontsInUseEntry $seg:$lhan FIUE_attrs.FCA_fontID $matchID
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
    if {$fontcache} {
    	echo {font files open:}
    	echo {----------------}
    	var lhan 22
    	plist FontID $seg:$lhan
    }
    if {$summary} {
    	var lhan 22
    	var mfo [countlist $seg:$lhan FontID]
    	echo {}
    	echo {font file cache:}
    	echo {----------------}
    	echo [format {maximum files open = %d} $mfo]
    	var fo [countlist $seg:$lhan FontID {} 0]
    	echo [format {currently open = %d} [expr $mfo-$fo]]

    	echo {}
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
#				pfontfiles
##############################################################################
#
# SYNOPSIS:	Print out all the available fonts, giving their face name
#		and their filename. Useful mostly for copying fonts around
#   	    	for a document. Use "fonts -f" to get it.
# PASS:		seg 	= FontInfoBlock segment
#		lhan	= chunk handle of the list of available fonts
# CALLED BY:	fonts
# RETURN:	nothing
# SIDE EFFECTS:	output (one font per line: face name in a 20-char field, 2
#		spaces, filename)
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/26/94		Initial Revision
#
##############################################################################
[defsubr pfontfiles {seg lhan}
{
    var fae [symbol find type geos::FontsAvailEntry]
    var faesz [type size $fae]
    
    var off [value fetch $seg:$lhan word]
    var csize [expr [value fetch $seg:$off-2 word]-2]
    
    
    [for {var n [expr $csize/$faesz]}
    	 {$n > 0}
	 {var n [expr $n-1] off [expr $off+$faesz]}
    {
    	var file [mapconcat c [value fetch $seg:$off.geos::FAE_fileName] {
	    if {[string c $c \\000] == 0} {
		break
	    } else {
		var c
	    }
	}]
    	var fi [value fetch $seg:$off.geos::FAE_infoHandle]
	var face [mapconcat c [value fetch (*$seg:$fi).geos::FI_faceName] {
	    if {[string c $c \\000] == 0} {
		break
	    } else {
		var c
	    }
	}]
	echo [format {%-20s  %s} $face $file]
    }]
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
	    var matchval [getvalue $matchvalue]
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
    if {$chunkAddr == 0xffff} {
    	return 0
    }
    var chunkSize   [expr [value fetch $seg:[expr $chunkAddr-2] word]-2]
    #
    # Search the list for the value passed, in the field of the
    # structure specified.
    #
    var count 0
    var strucPtr $chunkAddr

    for {} {$strucPtr < [expr $chunkAddr+$chunkSize]} {var strucPtr [expr $strucPtr+[size $struct]]} {
	if {$matchflag != 0} {
    	    if {![null $entry]} {
	    	var val	[value fetch $seg:$strucPtr.$entry]
    	    } else {
    	    	var val [value fetch $seg:$strucPtr $struct]
    	    }
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

[defcmd pchar {args} lib_app_driver.font
{Usage:
    pchar [<compact flag>] [<character>] [<font address>]

Examples:
    "pchar" 	    	    
    "pchar A ^h20c0h"	    print the bitmap of the character 'A'
    "pchar 65 ^h20c0h"	    print the bitmap of ascii characer 65
    "pchar -C *"    	    print bare info on what the character is and it's
    	    	    	    status

Synopsis:
    Print the bitmap of a character in a font.

Notes:
    * The compact flag '-c' indicates to not print the structure info of 
      the character.  The super compact flag '-C' indicates just to
      print the character number, what it is (C_ASTERISK), and mentions
      anything special (NOT BUILT).

    * The character argument specifies which character to print.  The 
      argument may either be an actual character or the ascii value.

    * The font address argument is the address of the font which has
      the character you want to print out.  This defaults to ^hbx.

See also:
    fonts, pfont, pusage, pfontinfo.
}
{
    #
    # Parse the flags, if any.
    #
    var compact 0
    var superCompact 0
    var opts [index $args 0]
    if {[string m $opts -*]} {
	#
	# Gave us some flags
	#
	foreach i [explode [range $opts 1 end chars]] {
	    [case $i in
		c {var compact 1}
		C {var superCompact 1}
		default {error [format {unknown option %s} $i]}]
	}
        var args [cdr $args]
    }
    if [null [index $args 0]] {
	var char A
    } else {
        var char [index $args 0]
    }
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
            var pchar [getvalue $char]
    	} else {
    	    scan $char %c pchar
    	}
    } else {
        var pchar $char
    }
    var pchar [getvalue $pchar]

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
	    echo -n [format %s%d%s%x {CHARACTER: } $pchar { / 0x} $pchar ]
    	    echo [format %s%s { / } [penum Chars $pchar]]
    	    if {!$superCompact} {
	        if {!$compact} {
	    	    _print CharTableEntry $seg:$entry
    	    	}
 	    	[case $data in
		    0 {echo {NO CHARACTER}}
		    1 {echo {NOT LOADED}}
		    2 {echo {NOT BUILT}}
		    3 {echo {ERROR -- UNKNOWN FLAG}} ]
    	    }
	} else {
	    echo -n [format %s%d%s%x {CHARACTER: } $pchar { / 0x} $pchar ]
    	    echo [format %s%s { / } [penum Chars $pchar]]
    	    if {!$superCompact} {
	    	if {!$compact} {
	            _print CharTableEntry $seg:$entry
    	    	}
    	    	var flags [value fetch $seg:FB_flags]
    	    	if {[field $flags FBF_IS_REGION]} {
    	    	    _print RegionCharData $seg:$data
    	    	    var ptr [expr [getvalue RCD_data]+$data]
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
	    	    var ptr [expr [getvalue CD_data]+$data]
	    	    pncbitmap $seg:$ptr $width $height
    	    	}
    	    }
	}
        if {!$superCompact} {echo {}}
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

[defcmd pfont {args} lib_app_driver.font
{Usage:
    pfont [<compact flag>] [<address>]

Examples:
    "pfont" 	    	print bitmaps and widths of characters in font at ^hbx
    "pfont -b ^h1fd0h"	print bitmaps only of characters in font at ^h1fd0h
    "pfont -c ^h1fd0h"	list the characters in the font at ^h1fd0h

Synopsis:
    Print all the bitmaps of the characters in a font.

Notes:
    * The compact flag argument '-c' causes just pfont to list which 
      characters are in the font and any special status (NOT BUILT)..

    * The address argument is the address of the font.  If none is 
      specified then ^hbx is used.

See also:
    fonts, pusage, pchar, pfontinfo.
}
{
    #
    # Parse the flags, if any.
    #
    var compact {}
    var opts [index $args 0]
    if {[string m $opts -*]} {
	#
	# Gave us some flags
	#
	foreach i [explode [range $opts 1 end chars]] {
	    [case $i in
		b {var compact -c}
		c {var compact -C}
		default {error [format {unknown option %s} $i]}]
	}
        var args [cdr $args]
    }
    if [null [index $args 0]] {
	var addr {^hbx}
    } else {
        var addr [index $args 0]
    }

    #
    # Check    #
    # Set various variables that will be needed.
    #
    var address     [addr-parse $addr]
    var	seg	    [handle segment [index $address 0]]

    var first [field [value fetch $seg:0 FontBuf] FB_firstChar]
    var last [field [value fetch $seg:0 FontBuf] FB_lastChar]

    if {[null $compact]} {
        _print FontBuf $seg:0
        echo {------------------------------------------}
    	var kcount	[field [value fetch $seg:0 FontBuf] FB_kernCount]
    	if {$kcount != 0} {
            var kpairs [field [value fetch $seg:0 FontBuf] FB_kernPairPtr]
            var kvals [field [value fetch $seg:0 FontBuf] FB_kernValuePtr]
    	    echo {kern pairs}
    	    echo {----------}
    	    for {var i 0} {$i < $kcount} {var i [expr $i+1]} {
    	    	var left [value fetch $seg:$kpairs+1 byte]
    	    	var right [value fetch $seg:$kpairs byte]
    	    	echo [format {%s %s} [penum Chars $left] [penum Chars $right]]
    	    	var kpairs [expr $kpairs+[size KernPair]]
    	    }
    	    echo {kern values}
    	    echo {-----------}
    	    for {var i 0} {$i < $kcount} {var i [expr $i+1]} {
    	    	_print BBFixed $seg:$kvals+[expr $i*[size BBFixed]]
    	    }
            echo {------------------------------------------}
    	}
    }
    for {var i $first} {$i <= $last} {var i [expr $i+1]} {
    	if {![null $compact]} {
	    pchar $compact $i $addr
    	} else {
    	    pchar $i $addr
    	}
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

[defcmd pusage {{addr ^hbx}} lib_app_driver.font
{Usage:
    pusage [<address>]

Examples:
    "pusage"	    print the usage of characters in the font

Synopsis:
    List the characters in a font and when they were last used.

Notes:
    * The address argument is the address of a font.  If none is given
      then ^hbx is used.

See also:
    fonts, pfong, pfontinfo, pchar, plist.
}
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
    if {$maker == [getvalue FM_NIMBUSQ]} {
    	var fsize [expr $fsize+[size CharGenData]]
    }
    if {$maker == [getvalue FM_BITSTREAM]} {
    	var fsize [expr $fsize+[size BitstreamCharGenData]]
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
    	global dbcs
    	if {[null $dbcs]} {
	    var usage [field [value fetch $seg:$ptr CharTableEntry] CTE_usage]
    	} else {
    	    if {$isreg} {
    	    	var usage [field [value fetch $seg:$data RegionCharData] RCD_usage]
    	    } else {
    	    	var usage 0
    	    }
    	}
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
    	    echo [format {%s (0x%x)} [penum Chars $i] $i]
    	    var fsize [expr $fsize+$sze]
    	}
    	var fsize [expr $fsize+$cte_size]
    	var ptr [expr $ptr+$cte_size]
    }
    echo [format {LRU = %s (0x%x)} [penum Chars $lruChar] $lruChar]
    echo [format %s%d%s%x%s {actual size = } $fsize { / 0x} $fsize { bytes}]
}]

##############################################################################
#				pfontinfo
##############################################################################
#
# SYNOPSIS:	print font info for a font.
# PASS:     	$font - fond ID (eg. FID_DTC_URW_ROMAN)
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	9/14/90		Initial Revision
#
##############################################################################

#the list you get back from addr-parse has the type as its 3 element. The 3d
#element will be nil if the address has no type. you might be able to get away
#with a string comparison of the 3d element with the 3d element of an expression
#like {<struct_you're_looking_for> 0}. It won't work for pointers or arrays,
#but for structures it should work. I don't remember if the "type" command
#has an "equal" subcommand. There's a Type_Equal subroutine, so it wouldn't be
#too hard to add such a subcommand.


[defcmd pfontinfo {args} {system.font lib_app_driver.font}
{Usage:
    pfontinfo <font ID>

Examples:
    "pfontinfo FID_BERKELEY"

Synopsis:
    Prints font header information for a font.  Also lists all sizes built.

Notes:
    * The font ID argument must be supplied.  If not known, use 
      'fonts -u' to list all the fonts with their IDs.

See also:
    fonts, pfont.
}
{
    #
    # parse the flags
    #
    var sizes 0

    if {[length $args] > 0 && [string m [index $args 0] -*]} {
	#
	# Examine the flags word for things we know and set vars
	# accordingly.
	#
	foreach i [explode [range [index $args 0] 1 end chars]] {
	    [case $i in
		s {var sizes 1}
		default {error [format {unknown option %s} $i]}
	    ]
	}
	#
	# Shift the first arg off the list
	#
	var args [range $args 1 end]
    }
    #
    # Get the FontsAvailEntry of the font, and the lmem handle of
    # the FontInfo chunk.
    #
    var availPtr [isfontavail $args]
    var seg [fontinfoaddr]
    var lhan [value fetch $seg:$availPtr.FAE_infoHandle]
    var chunkAddr   [value fetch $seg:$lhan word]
    var chunkSize   [expr [value fetch $seg:[expr $chunkAddr-2] word]-2]
    if {!$sizes} {
    	_print FontInfo $seg:$chunkAddr
    } else {
    	echo [penum FontID [value fetch $seg:$chunkAddr.FI_fontID]]
    	echo
    }
    #
    # From the FontInfo chunk, get the start and size of the outline
    # entires and print them.
    #
    var outPtr	[expr $chunkAddr+[value fetch $seg:$chunkAddr.FI_outlineTab]]
    var outEnd	[expr $chunkAddr+[value fetch $seg:$chunkAddr.FI_outlineEnd]]
    echo {outlines}
    echo {--------}
    for {} {$outPtr < $outEnd} {var outPtr [expr $outPtr+[size OutlineDataEntry]]} {
    	if {!$sizes} {
            _print OutlineDataEntry $seg:$outPtr
    	} else {
    	    var val [value fetch $seg:$outPtr OutlineDataEntry]
    	    var styles [expr 2*[field [field $val ODE_style] TS_BOLD]|[field [field $val ODE_style] TS_ITALIC]]
    	    [case $styles in
    	    	0 {echo -n {plain   }}
    	    	1 {echo -n {italic  }}
    	    	2 {echo -n {bold    }}
    	    	3 {echo -n {bold-italic}}
    	    ]
    	    echo [format {\t= %s bytes} [expr [field [field $val ODE_header] OE_size]+[field [field $val ODE_first] OE_size]+[field [field $val ODE_second] OE_size]]]
    	}
    }
    #
    # From the FontInfo chunk, get the start and size of the
    # bitmap entries and print them.
    #
    var outPtr	[expr $chunkAddr+[value fetch $seg:$chunkAddr.FI_pointSizeTab]]
    var outEnd	[expr $chunkAddr+[value fetch $seg:$chunkAddr.FI_pointSizeEnd]]
    echo
    echo {bitmaps}
    echo {-------}
    for {} {$outPtr < $outEnd} {var outPtr [expr $outPtr+[size PointSizeEntry]]} {
    	if {!$sizes} {
	    _print PointSizeEntry $seg:$outPtr
    	} else {
    	    var val [value fetch $seg:$outPtr PointSizeEntry]
    	    echo -n [format {%d pt } [field [field $val PSE_pointSize] WBF_int]]
    	    var styles [expr 2*[field [field $val PSE_style] TS_BOLD]|[field [field $val PSE_style] TS_ITALIC]]
    	    [case $styles in
    	    	0 {echo -n {plain   	}}
    	    	1 {echo -n {italic  	}}
    	    	2 {echo -n {bold    	}}
    	    	3 {echo -n {bold-italic}}
    	    ]
    	    echo [format {\t= %s bytes} [field $val PSE_dataSize]]
    	}
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
    var font [getvalue $fontid]

    #
    # Get the lmem handle, dereference it, and find out how big the chunk is.
    #
    var seg 	    [fontinfoaddr]
    var lhan 16
    var chunkAddr   [value fetch $seg:$lhan word]
    var chunkSize   [expr [value fetch $seg:[expr $chunkAddr-2] word]-2]

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

##############################################################################
#				showfonts
##############################################################################
#
# SYNOPSIS:	Show loading and/or building of fonts
# PASS:		none
# CALLED BY:	user
# RETURN:	none
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	8/31/92		Initial Revision
#
##############################################################################

[defcmd showfonts {args} {system.font lib_app_driver.font}
{Usage:
    showfonts [<args>]

Examples:
    "showfonts -b"	    show bitmap font loading
    "showfonts -o"  	    show outline font building
    "showfonts"	    	    stop showing font 

Synopsis:
    Show when fonts are loaded and/or built.

Notes:
    * The args argument may be chosen from the following:

    	-b  	   Show loading of bitmap fonts
    	-o  	   Show building of outline fonts
    	-c  	   Show building of outline characters

See also:
    pfont
}
{
    global  sf_bitmap sf_outline sf_char
    remove-brk sf_bitmap
    remove-brk sf_outline
    remove-brk sf_char

    #
    # parse the flags
    #
    var ps {aset}
    if {[length $args] > 0 && [string m [index $args 0] -*]} {
	#
	# Examine the flags word for things we know and set vars
	# accordingly.
	#
	foreach i [explode [range [index $args 0] 1 end chars]] {
	    [case $i in
		b {
    	    	    var sf_bitmap [list [brk $ps ReloadFont print-lbf]]
    	    	}
		o {
    	    	    var sf_outline [list [brk $ps CheckCallDriver print-bof]]
    	    	}
		c {
    	    	    var sf_char [list [brk $ps GrCallFontDriverID print-boc]]
    	    	}
		default {error [format {unknown option %s} $i]}
	    ]
	}
    }
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

[defsubr print-lbf {} {
    echo Loading bitmap font:
    echo [penum FontID [read-reg cx]]
    print ds:di.PSE_pointSize
    print ds:di.PSE_style
    echo {}
    return 0
}]

[defsubr print-bof {} {
    echo Building outline font:
    print TMatrix bp:si
    print es:GS_fontAttr.FCA_fontID
    print es:GS_fontAttr.FCA_pointsize
    print es:GS_fontAttr.FCA_textStyle
    echo {}
    return 0
}]

[defsubr print-boc {} {
    if {[read-reg di]==[getvalue DR_FONT_GEN_CHAR]} {
    	echo Building outline character:
    	print bp:GS_fontAttr.FCA_fontID
    	print bp:GS_fontAttr.FCA_pointsize
    	print bp:GS_fontAttr.FCA_textStyle
    	echo [penum Chars [read-reg dl]]
    	echo {}
    }
    return 0
}]
