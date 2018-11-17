##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	dumptext.tcl
# FILE: 	dumptext.tcl
# AUTHOR: 	Adam de Boor, Apr  8, 1992
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/ 8/92		Initial Revision
#
# DESCRIPTION:
#	function to dump a text object's text, styles and rulers.
#
#	$Id: dumptext.tcl,v 1.6 92/04/15 17:07:19 adam Exp $
#
###############################################################################

##############################################################################
#				dt-fetch-runs
##############################################################################
#
# SYNOPSIS:	    Fetch the runs from a run array
# PASS:		    addr    = base of the RunArray
# CALLED BY:	    dumptext
# RETURN:	    2-list: {elements-addr runs}
#   	    	    where runs is a list of pairs: {offset token}
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/ 8/92		Initial Revision
#
##############################################################################
[defsubr dt-fetch-runs {addr}
{
    var rat [symbol find type ui::RunArray]
    var raet [symbol find type ui::RunArrayElement]
    var raetsize [type size $raet]

    var ra [value fetch $addr $rat]
    var ea [list [field $ra RA_elementArrayHandle] [field $ra RA_elementArrayChunk]]
    
    var runs {} off [type size $rat]
    [for {var rae [value fetch ($addr)+$off $raet]}
    	 {[field $rae RAE_position] != 0x8000}
	 {var rae [value fetch ($addr)+$off $raet]}
    {
    	var runs [concat $runs [list [list [field $rae RAE_position] [field $rae RAE_token]]]]
	var off [expr $off+$raetsize]
    }]
    
    return [list $ea $runs]
}]

##############################################################################
#				dt-print-text
##############################################################################
#
# SYNOPSIS:	Print out the text chunk for the object, inserting whatever
#   	    	labels have been deemed appropriate based on the style and
#   	    	ruler runs.
# PASS:		textaddr    = the base of the text chunk
#   	    	labels	    = list of pairs: {offset label} where offset
#			      is the offset into the text at which to
#			      put the given label.
#   	    	stream	    = stream to which to write the result
# CALLED BY:	dumptext
# RETURN:	nothing
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/15/92		Initial Revision
#
##############################################################################
[defsubr dt-print-text {textaddr labels stream}
{
    var tsize [expr [value fetch ($textaddr)-2 [type word]]-2]
    var ttype [type make array $tsize [type byte]]
    var text [value fetch $textaddr $ttype]
    type delete $ttype
    var ct [symbol find type Chars]
    
    var off 0 perline 60 prefix [format {\tchar}] thisline 0
    stream write [format {chunk TextChunk = data \{\ntext_base\tlabel\tchar\n}] $stream
    foreach c $text {
    	if {$off == [index [index $labels 0] 0]} {
    	    if {$thisline != 0} {
	    	stream write "\n $stream
    	    }
	    stream write [format {%s\tlabel\tchar\n}
	    	    	     [index [index $labels 0] 1]] $stream
	    var thisline 0
	    var labels [range $labels 1 end]
	    if {[null $labels]} {
	    	var labels [list [list -1 0]]
    	    }
    	}
	if {$thisline == $perline} {
	    stream write "\n $stream
	    var thisline 0
    	}
	if {$c >= 32 && $c < 0x7f} {
    	    if {$thisline == 0} {
	    	stream write $prefix\t" $stream
    	    }
	    stream write [format %c $c] $stream
	    var thisline [expr $thisline+1]
	} else {
    	    [case $c in
    	     13 {
	     	if {$thisline == 0} {
		    stream write $prefix\t"\\r"\n $stream
    	    	} else {
    	    	    stream write \\r"\n $stream
    	    	}
    	     }
	     * {
	     	var cname [type emap $c $ct]
	    	if {[null $cname]} {
	    	    var cname $c
    	    	}
		if {$thisline != 0} {
		    stream write "\n $stream
    	    	}
		stream write $prefix\t$cname\n $stream
    	    }]
    	    var thisline 0
    	}
	var off [expr $off+1]
    }
    if {$thisline != 0} {
    	stream write "\n $stream
    }
    stream write \}\n $stream
}]
	
##############################################################################
#				dt-print-run-array
##############################################################################
#
# SYNOPSIS:	    Print out a run array (really?)
# PASS:		    runlist 	= list of runs as pairs {offset token}
#   	    	    label   	= label for the run array chunk
#   	    	    eltlabel	= label for the already-printed element array
#				  chunk
#   	    	    labellist	= mapping from text offset -> label names. a
#				  list of pairs of the form {offset label}
#   	    	    tokennames	= mapping from run-array element tokens to
#   	    	    	    	  printable things the user might be able to
#				  find. {token name} pairs, as you'd expect
#   	    	    stream  	= stream to which to print the result
# CALLED BY:	    dumptext
# RETURN:	    nothing
# SIDE EFFECTS:	    none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/15/92		Initial Revision
#
##############################################################################

[defsubr dt-print-run-array {runlist label eltlabel labellist tokennames stream}
{
    #
    # Put out the chunk definition and the RunArray header
    #
    stream write [format {chunk %s = data \{
    RunArray <
	%s,	; RA_elementArrayChunk
	0,			; RA_elementArrayHandle (set later)
	0,			; RA_nameArrayChunk
	0,			; RA_nameArrayHandle (set later)
	0			; RA_last
    >
    RunArrayElement \\\n} $label $eltlabel] $stream

    #
    # For each run, put out the offset, by label, and the printable name for
    # the token.
    #
    foreach run [index $runlist 1] {
    	var l [assoc $labellist [index $run 0]]
	var t [assoc $tokennames [index $run 1]]
if {[null $t]} {debug}
    	stream write [format {\t<%s-text_base, %s>,\n} [index $l 1] 
	    	    	[index $t 1]] $stream
    }
    #
    # Terminate the array properly.
    #
    stream write [format {\t<TEXT_ADDRESS_PAST_END, 0>\n}] $stream
    stream write \}\n $stream
}]

##############################################################################
#				dt-print-data
##############################################################################
#
# SYNOPSIS:	    Create an Esp initializer from a value list for a structure
#		    field
# PASS:		    val	    = structure field's value list: {name type value}
#   	    	    offset  = indentation
#   	    	    tail    = thing to stick at the end of the structure
#			      initializer ("," or nothing)
#   	    	    stream  = stream to which to write
# CALLED BY:	    dt-print-styles, dt-print-rulers, self
# RETURN:	    nothing
# SIDE EFFECTS:	    not really
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/15/92		Initial Revision
#
##############################################################################

[defsubr dt-print-data {val offset tail stream}
{
    [case [type class [index $val 1]] in
    	struct {
    	    #
	    # Nested structure, so begin a structure initializer with the name
	    # of the field next to it.
	    #
	    stream write [format {%*s< ; %s\n} $offset {} [index $val 0]] $stream
    	    
    	    #
	    # Figure how many named fields there are (we don't print anything
	    # for nameless fields as Esp doesn't expect or want anything) so
	    # we know when to not pass ourselves a tail of {,}
	    #
	    var n 0
	    var fields [map f [index $val 2] {
	    	if {[null [index $f 0]]} {
		    format {}
		} else {
		    var n [expr $n+1]
		    var f
    	    	}
	    }]
	    #
	    # Now call ourselves for each field, using a further level of
	    # indentation
	    #
	    foreach f $fields {
    	    	if {![null $f]} {
	    	    var n [expr $n-1]
    	    	    if {$n == 0} {
	    	    	dt-print-data $f [expr $offset+4] {} $stream
    	    	    } else {
	    	    	dt-print-data $f [expr $offset+4] {,} $stream
    	    	    }
    	    	}
    	    }
	    #
	    # Finish off the initializer properly
	    #
	    stream write [format {%*s>%s\n} $offset {} $tail] $stream
    	}
	union {
    	    #
    	    # assume first field in union covers whole union...
    	    #
    	    var uname [index [index [index $val 2] 0] 0]
	    stream write [format {%*s<%s ; %s.%s\n} $offset {} $uname
	    	    	    [index $val 0] $uname] $stream
    	    #
	    # Call ourselves with the value of the first piece of the union.
	    #
	    dt-print-data [index [index $val 2] 0] [expr $offset+4] {} $stream
    	    #
	    # Finish off the union initializer
	    #
	    stream write [format {%*s>%s\n} $offset {} $tail] $stream
    	}
	enum {
    	    #
	    # Map the constant to its named version, if possible.
	    #
	    var name [type emap [index $val 2] [index $val 1]]
	    if {[null $name]} {
	    	var name [index $val 2]
    	    }
	    #
	    # Put out its initializer with the appropriate field-name comment.
	    #
	    stream write [format {%*s%s%s ; %s\n} $offset {} $name $tail
	    	    	     [index $val 0]] $stream
    	}
    	array {
    	    #
	    # An array. Wheee. Figure the element type and number
	    #
	    var n 0 base [type aget [index $val 1]]
	    var elttype [index $base 0] max [index $base 2]
	    #
	    # Write out the start of the initializer.
	    #
	    stream write [format {%*s< ; %s\n} $offset {} [index $val 0]] $stream
    	    #
	    # Call ourselves to put out each element.
	    #
	    foreach e [index $val 2] {
    	    	if {$n == $max} {
	    	    [dt-print-data [list [format {%s[%d]} [index $val 0] $n]
		    	    	    $elttype
				    $e]
			       	   [expr $offset+4]
				   {}
				   $stream]
    	    	} else {
	    	    [dt-print-data [list [format {%s[%d]} [index $val 0] $n]
		    	    	    $elttype
				    $e]
			       	   [expr $offset+4]
				   {,}
				   $stream]
    	    	}
    	    	var n [expr $n+1]
    	    }
    	    #
	    # Finish off the initializer
	    #
	    stream write [format {%*s>%s\n} $offset {} $tail] $stream
    	}
	char {
	    #
	    # Put the thing out in single-quotes...
	    #
	    stream write [format {%*s'%s'%s ; %s\n} $offset {} [index $val 2]
	    	    	     $tail [index $val 0]] $stream
    	}
	default {
    	    #
	    # Put the beast out in whatever format "value" gave it to us; it
	    # usually knows what it's doing...
	    #
	    stream write [format {%*s%s%s ; %s\n} $offset {} [index $val 2]
	    	    	    $tail [index $val 0]] $stream
    	}
    ]
}]

##############################################################################
#				dt-print-styles
##############################################################################
#
# SYNOPSIS:	    Put out the VisTextStyle structures for the object,
#   	    	    returning a list of names for each style, by token number
# PASS:		    sea	    = address of base of element array
#   	    	    stream  = stream to which to write it
# CALLED BY:	    dumptext
# RETURN:	    list of token -> name mapping pairs: {token name}
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/ 9/92		Initial Revision
#
##############################################################################
[defsubr dt-print-styles {sea stream}
{
    #
    # Find the dimensions of the element array
    #
    var header [value fetch $sea ui::ElementArray]
    #
    # Find the VisTextStyle type, as we'll be needing it a lot
    #
    var vts [symbol find type ui::VisTextStyle]
    var vtssize [type size $vts]
    
    #
    # Write out the start of the chunk and the array header.
    #
    stream write [format {chunk TextStyleElements = data \{\n}] $stream
    stream write [format {TSE_base ElementArray <%d,%d,%d>\n}
		    [field $header EA_count]
		    [field $header EA_freePtrOrCounter]
		    [field $header EA_insertionToken]] $stream
    #
    # Now print out each element
    #
    var off [type size [symbol find type ui::ElementArray]]
    var names {}
    for {var n 1} {$n <= [field $header EA_count]} {var n [expr $n+1]} {
    	#
	# Add this new offset -> name mapping to the list of known ones.
	#
    	var names [concat $names [list [list $off TSE_Style$n-TSE_base]]]
    	#
	# Fetch the element from memory
	#
    	var elt [value fetch ($sea)+$off $vts]
    	#
	# If the reference count is non-zero, spew the style to the output
	# stream.
	#
	if {[field [field $elt VTS_meta] E_refCount]} {
	    stream write [format {TSE_Style%d VisTextStyle } $n] $stream
    	    dt-print-data [list VisTextStyle $vts $elt] 0 {} $stream
    	}
	#
	# Advance to the next element
	#
    	var off [expr $off+$vtssize]
    }
    stream write \}\n $stream
    return $names
}]

##############################################################################
#				dt-print-rulers
##############################################################################
#
# SYNOPSIS:	    Print out the elements of the ruler array
# PASS:		    rea	    = base of the ElementArray
#   	    	    stream  = stream to which to print everything
# CALLED BY:	    dumptext
# RETURN:	    list of token -> name mappings for the ruler runs
# SIDE EFFECTS:	    output, you know?
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/ 9/92		Initial Revision
#
##############################################################################
[defsubr dt-print-rulers {rea stream}
{
    #
    # Fetch the element array header and find the types we'll be using a good
    # deal.
    #
    var header [value fetch $rea ui::ElementArray]
    var vtr [symbol find type ui::VisTextRuler]
    var vtrsize [type size $vtr]
    var tab [symbol find type ui::Tab]
    var tabsize [type size $tab]
    
    #
    # Write out the chunk definition and the array header.
    #
    stream write [format {chunk TextRulerElements = data \{\n}] $stream
    stream write [format {TRE_base ElementArray <%d,%d,%d>\n}
    	    	    [field $header EA_count]
	    	    [field $header EA_freePtrOrCounter]
	    	    [field $header EA_insertionToken]] $stream
    #
    # Now spew the elements one by one.
    #
    var off [type size [symbol find type ui::ElementArray]]
    var names {}
    for {var n 1} {$n <= [field $header EA_count]} {var n [expr $n+1]} {
    	#
	# Fetch the next element and put out the human-readable constant for
	# the ruler.
	#
    	var elt [value fetch ($rea)+$off $vtr]
    	var names [concat $names [list [list [field $elt VTR_token] 
					     TEXT_RULER_$n]]]
    	#
	# If the reference count is non-zero, spew the ruler to the output
	# stream.
	#
	var refCount [field [field $elt VTR_meta] E_refCount]
	if {$refCount} {
            stream write [format {TEXT_RULER_%d equ %d\n} $n
			      	[field $elt VTR_token]] $stream
	    stream write VisTextRuler $stream
    	    dt-print-data [list VisTextRuler $vtr $elt] 0 {} $stream
    	}
    	var off [expr $off+$vtrsize]
	var ntabs [field $elt VTR_numberOfTabs]
    	#
	# Now print out any accompanying tabs
	#
	for {var t 0} {$t < $ntabs} {var t [expr $t+1]} {
	    if {$refCount} {
		stream write Tab $stream
		dt-print-data [list Tab $tab
		    	    	[value fetch ($rea)+$off $tab]] 0 {} $stream
    	    }
	    var off [expr $off+$tabsize]
    	}
    }
    stream write \}\n $stream
    return $names
}]

##############################################################################
#				dumptext
##############################################################################
#
# SYNOPSIS:	    Write a UIC-able definition of the given text object to
#   	    	    a file.
# PASS:		    obj	    = address of a text object
#   	    	    file    = name of the file to which to write it
# CALLED BY:	    user, dump-write-page
# RETURN:	    nothing
# SIDE EFFECTS:	    ?
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/15/92		Initial Revision
#
##############################################################################

[defsubr dumptext {obj file}
{
    protect {
    	var stream [stream open $file w]

	var a [addr-parse $obj]

	var h [handle id [index $a 0]]

	var vti [value fetch ($obj)+[value fetch ($obj).ui::Vis_offset] ui::VisTextInstance]
	var textChunk [field $vti VTI_text]
	var styles [field $vti VTI_styleRuns]
	var rulers [field $vti VTI_rulerRuns]

	#
	# Fetch the style and ruler runs for the beast.
	#
	var styleRuns [dt-fetch-runs ^l$h:$styles]
	var rulerRuns [dt-fetch-runs ^l$h:$rulers]

	#
	# For each one of those run elements, we'll need a label in the text, so
	# take the offset portion of each run-array element from both run arrays
	# and use sort -nu to get a list of unique offsets.
	#
	# $labels ends up being a list of pairs {offset name} where name is the
	# name of the label put into the text for that offset.
	#
	var n 0
	var runoffsets [map q [concat
				     [index $styleRuns 1]
				     [index $rulerRuns 1]]
			     {index $q 0}]
	var labels [map i [sort -nu $runoffsets]
	{
	    var n [expr $n+1]
	    list [index $i 0] L$n
	}]

    	echo **** STYLE ELEMENTS ****
	var sea ^l[index [index $styleRuns 0] 0]:[index [index $styleRuns 0] 1]
	var styleNames [dt-print-styles $sea $stream]

    	echo **** RULER ELEMENTS ****
	var rea ^l[index [index $rulerRuns 0] 0]:[index [index $rulerRuns 0] 1]
	var rulerNames [dt-print-rulers $rea $stream]    

	echo **** TEXT ****
	dt-print-text ^l$h:$textChunk $labels $stream

	echo **** STYLE RUNS ****
	[dt-print-run-array $styleRuns TextStyleRuns TextStyleElements
	     $labels $styleNames $stream]

	echo **** RULER RUNS ****
	[dt-print-run-array $rulerRuns TextRulerRuns TextRulerElements
	     $labels $rulerNames $stream]
    } {
    	if {![null $stream]} {
	    stream close $stream
    	}
    }
}]

##############################################################################
#				dump-write-page
##############################################################################
#
# SYNOPSIS:	Dump the GeoWrite page under the pointer to the given file
# PASS:		file	= name of file into which to dump the text object
# RETURN:	nothing
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/15/92		Initial Revision
#
##############################################################################
[defsubr dump-write-page {file}
{
    #
    # Fetch the OLPortWindow under the mouse
    #
    var ig [impliedgrab]
    #
    # Fetch its OLPWI_OD, which points to a WriteTextPageClass object
    #
    var page [value fetch (($ig)+[value fetch ($ig).ui::Vis_offset]).motif::OLPWI_OD]
    var page ^l[expr ($page>>16)&0xffff]:[expr $page&0xffff]
    #
    # Find the last child of the beast; that's the WriteTextRegionClass object
    # that holds the Good Stuff.
    #
    [for {var c [value fetch (($page)+[value fetch ($page).ui::Vis_offset]).ui::VCI_comp.geos::CP_firstChild]}
    	{($c & 1) == 0}
    	{var c [value fetch (($lc)+[value fetch ($lc).ui::Vis_offset]).ui::VI_link.geos::LP_next]}
    {
        var lc ^l[expr ($c>>16)&0xffff]:[expr $c&0xffff]
    }]
    #
    # Dump that.
    #
    echo Dumping text object at $lc...
    dumptext $lc $file
}]
    	
