#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:  	PC GEOS
# MODULE:   	Swat System Library -- 
# FILE:		replace.tcl
# AUTHOR:	John Wedgwood, Nov 20, 1991
#
# COMMANDS:
#	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	john	11/20/91	Initial revision
#
# DESCRIPTION:
#	Code for debugging replace operations
#
#	$Id: replace.tcl,v 1.1 97/04/07 11:22:34 newdeal Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

##############################################################################
#				pvtrp
##############################################################################
#
# SYNOPSIS:	Print a VisTextReplaceParameters structure
# PASS:		address	- Address of the structure
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/24/91	Initial Revision
#
##############################################################################
[defcommand pvtrp {{address ss:bp}} text
{Usage:
    pvtrp [<address ss:bp>]

Examples:
    "pvtrp"	    	print the VisTextReplaceParameters at ss:bp
    "pvtrp es:0"    	print the VisTextReplaceParameters at es:0

Synopsis:
    Print a VisTextReplaceParameters structure

Notes:

See also:
    ptref
}
{
    var addr [addr-parse $address]
    var han  [handle id [index $addr 0]]
    var seg  [handle segment [index $addr 0]]
    var off  [index $addr 1]
    
    var p [value fetch $seg:$off [sym find type text::VisTextReplaceParameters]]

    echo [format {Parameters at %04xh:%04xh:} $seg $off]

    var start [field [field $p VTRP_range] VTR_start]
    var end   [field [field $p VTRP_range] VTR_end]
    
    #
    # Map the start/end based on special values
    #
    var info  [make-real $start $end]
    var start [index $info 0]
    var end   [index $info 1]

    var insCnt [field $p VTRP_insCount]
    var ic $insCnt

    if {($insCnt&0xffff0000)==0x01ff0000} {
    	var insCnt <null-terminated>
	var ic 255
    }

    echo [format {\tStart:  %s} $start]
    echo [format {\tEnd:    %s} $end]
    echo [format {\tInsert: %s} $insCnt]
    
    var t [field [field $p VTRP_textReference] TR_type]
    var t [type emap $t [sym find type TextReferenceType]]
    var t [range $t 4 end chars]
    var a [get-ref-address [field $p VTRP_textReference]]

    if {$ic} {
    	echo  [format {\tType: %-15s %s   "%s"}
    	    	    $t
		    $a
		    [get-string $t $a $ic]]
    }
}]

##############################################################################
#				make-real
##############################################################################
#
# SYNOPSIS:	Make a range into something "real"
# CALLED BY:	pvtrp
# PASS:		start	- start of range
#   	    	end 	- end of range
# RETURN:	info	- list containing "real" start and end
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	11/25/91	Initial Revision
#
##############################################################################
[defsubr make-real {start end}
{
    if {($start & 0xffff0000) == 0xffff0000} {
    	#
	# Use selection of text object
	#
	var start {SelectStart}
	var end   {SelectEnd}
    } else {
	if {($start & 0xffff0000) == 0x00ff0000} {
	    #
	    # Map to end of text
	    #
	    var start {EndOfText}
	}
	if {($end & 0xffff0000) == 0x00ff0000} {
	    #
	    # Map to end of text
	    #
	    var end {EndOfText}
	}
    }    
    return [list $start $end]
}]


##############################################################################
#				ptref
##############################################################################
#
# SYNOPSIS:	Print a text reference
# PASS:		address	- Address of a TextReference structure
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	10/24/91	Initial Revision
#
##############################################################################
[defcommand ptref {{address ss:bp}} text
{Usage:
    ptref [<address ss:bp>]

Examples:
    "ptref"	    	print the TextReference at ss:bp
    "ptref es:0"    	print the TextReference at es:0

Synopsis:
    Print a TextReference in a human readable form

Notes:

See also:
    pvtrp
}
{
    var addr [addr-parse $address]
    var han  [handle id [index $addr 0]]
    var seg  [handle segment [index $addr 0]]
    var off  [index $addr 1]
    
    var p [value fetch $seg:$off [sym find type text::TextReference]]

    var t [field $p TR_type]
    var t [type emap $t [sym find type TextReferenceType]]
    var t [range $t 4 end chars]

    var a [get-ref-address $p]

    echo  [format {\tType: %-15s %s   "%s"}
    	    	    $t
		    $a
		    [get-string $t $a 255]]
}]

##############################################################################
#				get-ref-address
##############################################################################
#
# SYNOPSIS:	Get an address expression for a reference.
# CALLED BY:	pvtrp
# PASS:		ref 	- TextReference structure
# RETURN:	str 	- Address expression for a reference
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	11/20/91	Initial Revision
#
##############################################################################
[var ref-type-handlers {
    {TRT_POINTER    	format-pointer-ref  	    TRU_pointer}
    {TRT_SEGMENT_CHUNK	format-segment-chunk-ref    TRU_segChunk}
    {TRT_BLOCK_CHUNK	format-block-chunk-ref	    TRU_blockChunk}
    {TRT_BLOCK		format-block-ref    	    TRU_block}
    {TRT_VM_BLOCK   	format-vm-block-ref 	    TRU_vmBlock}
    {TRT_DB_ITEM   	format-db-item-ref  	    TRU_dbItem}
    {TRT_HUGE_ARRAY   	format-huge-array-ref	    TRU_hugeArray}
}]

[defsubr get-ref-address {ref}
{
    global ref-type-handlers
    
    var t [type emap [field $ref TR_type] [sym find type TextReferenceType]]
    var info [assoc [var ref-type-handlers] $t]
    
    var r [index $info 1]
    var t [index $info 2]
    
    return [$r [field [field $ref TR_ref] $t]]
}]

##############################################################################
#				format-pointer-ref
##############################################################################
#
# SYNOPSIS:	Format a pointer reference
# CALLED BY:	get-ref-address
# PASS:		ref 	- TextReferencePointer
# RETURN:	str 	- Formatted address expression
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	11/20/91	Initial Revision
#
##############################################################################
[defsubr format-pointer-ref {ref}
{
    var addr [field $ref TRP_pointer]
    
    var seg [expr ($addr>>16)&0xffff]
    var off [expr ($addr&0xffff)]
    
    return [format {%04xh:%04xh} $seg $off]
}]

##############################################################################
#				format-segment-chunk-ref
##############################################################################
#
# SYNOPSIS:	Format a segment/chunk reference
# CALLED BY:	get-ref-address
# PASS:		ref 	- TextReferenceSegmentChunk
# RETURN:	str 	- Formatted address expression
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	11/20/91	Initial Revision
#
##############################################################################
[defsubr format-segment-chunk-ref {ref}
{
    var seg [field $ref TRSC_segment]
    var off [field $ref TRSC_chunk]
    
    return [format {*%04xh:%04xh} $seg $off]
}]

##############################################################################
#				format-block-chunk-ref
##############################################################################
#
# SYNOPSIS:	Format a block/chunk reference
# CALLED BY:	get-ref-address
# PASS:		ref 	- TextReferenceBlockChunk
# RETURN:	str 	- Formatted address expression
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	11/20/91	Initial Revision
#
##############################################################################
[defsubr format-block-chunk-ref {ref}
{
    var addr [field $ref TRBC_ref]
    
    var han [expr ($addr>>16)&0xffff]
    var chk [expr ($addr&0xffff)]
    
    return [format {^l%04xh:%04xh} $han $chk]
}]

##############################################################################
#				format-block-ref
##############################################################################
#
# SYNOPSIS:	Format a block reference
# CALLED BY:	get-ref-address
# PASS:		ref 	- TextReferenceBlock
# RETURN:	str 	- Formatted address expression
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	11/20/91	Initial Revision
#
##############################################################################
[defsubr format-block-ref {ref}
{
    var han [field $ref TRB_handle]
    
    return [format {^h%04xh} $han]
}]

##############################################################################
#				format-vm-block-ref
##############################################################################
#
# SYNOPSIS:	Format a vm-block reference
# CALLED BY:	get-ref-address
# PASS:		ref 	- TextReferenceVMBlock
# RETURN:	str 	- Formatted address expression
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	11/20/91	Initial Revision
#
##############################################################################
[defsubr format-vm-block-ref {ref}
{
    var f [field $ref TRVMB_file]
    var b [field $ref TRVMB_block]
    
    return [format {^v%04xh:%04xh} $f $b]
}]

##############################################################################
#				format-db-item-ref
##############################################################################
#
# SYNOPSIS:	Format a db-item reference
# CALLED BY:	get-ref-address
# PASS:		ref 	- TextReferenceDBItem
# RETURN:	str 	- Formatted address expression
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	11/20/91	Initial Revision
#
##############################################################################
[defsubr format-db-item-ref {ref}
{
}]

##############################################################################
#				format-huge-array-ref
##############################################################################
#
# SYNOPSIS:	Format a huge-array reference
# CALLED BY:	get-ref-address
# PASS:		ref 	- TextReferenceHugeArray
# RETURN:	str 	- Formatted address expression
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	11/20/91	Initial Revision
#
##############################################################################
[defsubr format-huge-array-ref {ref}
{
}]

##############################################################################
#				get-string
##############################################################################
#
# SYNOPSIS:	Get a string from an address
# CALLED BY:	pvtrp
# PASS:		t	- Type of the text reference
#   	    	address	- Address expression of the text
#   	    	count	- Number of characters to get
# RETURN:	str	- A text string
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jcw	11/25/91	Initial Revision
#
##############################################################################
[defsubr get-string {t address count}
{
    if {[string compare $t HUGE_ARRAY]==0} {
    	return {}
    }

    if {[string compare $t DB_ITEM]==0} {
    	return {}
    }

    var addr [addr-parse $address]
    var han  [handle id [index $addr 0]]
    var seg  [handle segment [index $addr 0]]
    var off  [index $addr 1]
    
    var str {}
    for {var i $count} {$i} {var i [expr $i-1]} {
	var c [value fetch $seg:$off [type byte]]
	if {$c==0} {
	    break
	}
	if {($c < 0x20) || ($c > 128)} {
    	    var str [format {%s\\%0o} $str $c]
	} else {
    	    var str [format {%s%c} $str $c]
	}
	
	var off [expr $off+1]
    }
    
    return $str
}]
