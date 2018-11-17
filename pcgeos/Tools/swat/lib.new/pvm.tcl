#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
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
#	$Id: pvm.tcl,v 3.73.6.1 97/03/29 11:27:44 canavese Exp $
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

##############################################################################
#				pstring
##############################################################################
#
# SYNOPSIS:	print a null-terminated string from memory at the given addr
# PASS:		addr	= address of start of the string
# CALLED BY:	GLOBAL
# RETURN:	nothing
# SIDE EFFECTS:	The string is enclosed in double-quotes,
#               unless a second argument is defined.
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	?	10/2/91		Initial Revision
#       martin  11/10/92        added ability to "silence" pstring
#	dloft	11/10/92	Changed how carriage returns get printed
#
##############################################################################
[defsubr pstring {args} {
    var silent 0
    global dbcs
    if {[null $dbcs]} {
    	var wide 1
    } else {
    	var wide 2
    }
    while {[string m [index $args 0] -*]} {
	#
	# Gave us some flags
	#
    	var arg [range [index $args 0] 1 end chars]
    	while {![null $arg]} {
	    [case [range $arg 0 0 chars] in
		s {var silent 1}
		w {var wide 2}
    	    	n {var wide 1}
    	    	l { 
    	    	    var maxlength [index $args 1]
    	    	    var args [range $args 1 end] 
    	    	}
		default {error [format {unknown option %s} $i]}
	    ]
    	    if {![null $arg]} {
    	    	var arg [range $arg 1 end chars]
    	    }
    	}
	var args [cdr $args]
    }

    var a [addr-parse $args]
    var s ^h[handle id [index $a 0]]
    var o [index $a 1]

    if {$wide == 1} {
    	if {!$silent} {
       	    echo -n "
    	}
    	[for {var c [value fetch $s:$o [type byte]]}
    	 {$c != 0}
    	 {var c [value fetch $s:$o [type byte]]}
    	{
	    # if we encounter CR, echo "\r"
            if {$c == 0dh} {
        	echo -n \\r
            } elif {$c < 32 || $c > 127} {
        	echo -n {.}
            } else {
        	echo -n [format %c $c]
    	    }
            var o [expr $o+$wide]
    	    if {![null $maxlength]} {
    	    	var maxlength [expr $maxlength-1]
    	    	if {$maxlength == 0} break
    	    }
    	}]
    	if {!$silent} {
       	    echo "
    	}
    } else {
    	var qp 0
    	[for {var c [value fetch $s:$o [type word]]}
    	 {$c != 0}
    	 {var c [value fetch $s:$o [type word]]}
    	{
	    # if we encounter CR, echo "\r"
            if {$c == 0dh} {
    	    	if {!$silent && !$qp} {
    	    	    echo -n "
    	    	    var qp 1
    	    	}
        	echo -n \\r
            } elif {$c < 32 || $c > 127} {
    	    	if {!$silent && $qp} {
    	    	    echo -n {",}
    	    	    var qp 0
    	    	}
    	    	echo -n [format {%s,} [penum geos::Chars $c]]
            } else {
    	    	if {!$silent && !$qp} {
    	    	    echo -n "
    	    	    var qp 1
    	    	}
        	echo -n [format %c $c]
    	    }
            var o [expr $o+$wide]
    	    if {![null $maxlength]} {
    	    	var maxlength [expr $maxlength-1]
    	    	if {$maxlength == 0} break
    	    }
    	}]
    	if {!$silent && $qp} {
    	    echo -n "
    	}
    	echo {}
    }
}]

##############################################################################
#				pmnemonic
##############################################################################
#
# SYNOPSIS:	print the data at the passed address as a moniker mnemonic
# PASS:		addr	= address of the mnemonic
# CALLED BY:	pvismon
# RETURN:	nothing
# SIDE EFFECTS:	if it has no mnemonic, this is printed
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	?	10/2/91		Initial Revision
#
##############################################################################
defsubr pmnemonic addr {
    var c [value fetch $addr.ui::VMT_mnemonicOffset [type byte]]
    global geos-release
    if {${geos-release} >= 2} {
        [case $c in
            255 {echo no mnemonic}
            254 {
		echo -n {not in text}
		addr-preprocess $addr.ui::VMT_text s o
                [for {var tc [value fetch $s:$o byte]}
	            {$tc != 0}
	            {var tc [value fetch $s:$o byte]}
                {
                    var o [expr $o+1]
                }]
                var o [expr $o+1]
		echo [format { - '%c'} [value fetch $s:$o byte]]
	    }
	    253 {echo cancel}
	    default {echo $c}
        ]
    } else {
	[case $c in
	    255 {echo no mnemonic}
	    254 {echo cancel}
	    default {echo $c}
        ]
    }
}

##############################################################################
#				pvmtext
##############################################################################
#
# SYNOPSIS:	Print the text for a VisMoniker.
# PASS:		addr	= start of the text for the moniker
#   	    	count   = number of chars in the text
# CALLED BY:	pvismon
# RETURN:	nothing
# SIDE EFFECTS:	...
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	?	10/2/91		Initial Revision
#
##############################################################################
defsubr pvmtext {addr count} {
    addr-preprocess $addr s o

    echo -n "
    if {$count!=0} then {
	    [for {var c [value fetch $s:$o [type char]]}
		 {$count != 0}
		 {var c [value fetch $s:$o [type char]]}
	    {
	    	if {[string c $c \\000]} {
	    	    if {[string m $c {\\[\{\}\\]}]} {
		    	echo -n [format $c]
	    	    } else {
		    	echo -n $c
	    	    }
	    	}

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
##############################################################################
#				ppdiff
##############################################################################
#
# SYNOPSIS:	Print out delta's between points
# PASS:		address - pointer to array of Point structures
# CALLED BY:	GLOBAL
# RETURN:	nothing
# SIDE EFFECTS:	nothing
#
# STRATEGY
#   	    	loop through all the points and calculate differences
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jim	3/18/93		Initial Revision
#
##############################################################################

[defcommand ppdiff {args} lib_app_driver.graphics
{Usage:
    ppdiff <address>

Examples:
    "ppdiff"	    	List the point deltas at ds:si
    "ppdiff ^hdi"    	List the point deltas at the start of the block whose
    	    	    	handle is in di
    "ppdiff -p"	        List the point deltas along with the points at ds:si
    "ppdiff -c10"       List 10 deltas at ds:si

Synopsis:
    Calculate the distance between successive points

}
{
    var pointsToo 0
    var pCount 2

    while {[string m [index $args 0] -*]} {
	#
	# Gave us some flags
	#
    	var arg [range [index $args 0] 1 end chars]
    	while {![null $arg]} {
	    [case [range $arg 0 0 chars] in
		p {
    	    	    var pointsToo 1
		}
    	    	c {
    	    	    if {[length $arg chars] > 1} {
			var pCount [expr [range $arg 1 end chars]]
    	    	    	var arg {}
		    }
		}
	    ]
    	    if {![null $arg]} {
    	    	var arg [range $arg 1 end chars]
    	    }
    	}
	var args [cdr $args]
    }

    # write a header out to make it pretty
    #
    if {$pointsToo == 1} {
        echo [format {Point\t\tDelta}]
        echo [format {-----\t\t-----}]
    } else {
    	echo [format {DeltaX\tDeltaY}]
    	echo [format {------\t------}]
    }

    # parse the address, so we know where it is.  If no address, use ds:si
    #
    if {[null $args]} {
    	var args {ds:si}
    }
    var addr [addr-parse $args]
    var seg ^h[format %04xh [handle id [index $addr 0]]]
    var off [index $addr 1]

    [for {var loopCount 0} 
    	 {$loopCount < $pCount} 
    	 {var loopCount [expr $loopCount+1]}
     {
    	var diffX [expr $oldX-[value fetch $seg:$off.P_x]]
    	var diffY [expr $oldY-[value fetch $seg:$off.P_y]]
    	if {$pointsToo == 1} {
    	    pcoord $seg:$off.P_x 1
    	    pcoord $seg:$off.P_y 2
        }
        if {$loopCount != 0} {
    	    echo -n [format {\t%4d\t%4d\t} $diffX $diffY]
    	    if {$diffX == 0} {
    	       echo -n vertical
    	    }
    	    if {$diffY == 0} {
    	       echo -n horizontal
    	    }
    	    if {$diffX == $diffY} {
    	    	echo -n diagonal
    	    }
    	    if {$diffX == [expr -$diffY]} {
    	    	echo -n back-diagonal
    	    }
    	    echo 
        } else {
    	    echo
    	}
    	var oldX [value fetch $seg:$off.P_x]
    	var oldY [value fetch $seg:$off.P_y]
    	var off [expr $off+[size Point]]
     }]
}]
##############################################################################
#				pgs
##############################################################################
#
# SYNOPSIS:	User command/subroutine to print out an in-memory graphics
#		string, giving all its opcodes and the operands for those
#		opcodes. If the graphics string is in a VM file at the start of
#   	    	a block, it is assumed to be chained through the first word
#   	    	of each block to the next in the series. All opcodes from
#   	    	those blocks that are resident are printed.
#
# PASS:		address	= start of the gstring.
# CALLED BY:	User, pvismon
# RETURN:	nothing
# SIDE EFFECTS:	_pgs_size_list will be initialized if it is null on entry
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	?	10/2/91		Initial Revision
#
##############################################################################
[defcommand pgs {args} lib_app_driver.graphics
{Usage:
    pgs <address>

Examples:
    "pgs"	    	List the graphics string at ds:si
    "pgs ^hdi"	    	List the graphics string whose handle is in di,
    	    	    	starting at the current position.
    "pgs -s ^hdi"	List the graphics string whose handle is in di, 
    	    	        starting at the beginning of the graphics string
    "pgs -l3 ^hdi"  	List three elements of the graphics string whose handle
    	    	    	is in di, starting at the current position.
    "pgs -c"	        List the graphics string at ds:si, including all the
    	    	        coordinate values for objects with lists.

Synopsis:
    List the contents of a graphics string.

Notes:
    * The address argument is the address of a graphics string.  If
      none is specified then ds:si is used as a pointer to a graphics
      string.

    * The passed address may also be the base of a gstate (e.g. "^hdi").
      In this case, the gstring that is associated with the gstate will
      be printed.

    * The -s option can be used to specify that the gstring should be listed
      from the beginning of the string.  By default, gstrings will be listed
      starting at the current position.

    * The -g option can be used to specify that the passed addres is the
      address of a GrObj (GStringClass) object -- the gstring for that object
      will be listed.

    * The -c option is used to expand out coordinate lists for those objects
      that have them (Polylines, Polygons, etc).  The default behaviour is 
      to simply list the number of points in the object.

See also:
    pbitmap, pvismon, pobjmon
}
{
    var startCP 1
    var isvm 0 
    var	slen 65536
    var elRange 65536
    var isGrObj 0
    var asMacros 0
    var pCrdLists 0

    while {[string m [index $args 0] -*]} {
	#
	# Gave us some flags
	#
    	var arg [range [index $args 0] 1 end chars]
    	while {![null $arg]} {
	    [case [index $arg 0 chars] in
		s {
    	    	    var startCP 0
		}
		a {var asMacros 1}
		c {
    	    	    var pCrdLists 1
		}
    	    	l {
    	    	    if {[length $arg chars] > 1} {
			var elRange [expr [range $arg 1 end chars]]
    	    	    	var arg {}
		    }
		}
		g {
    	    	    var isGrObj 1
    	    	}
	    ]
    	    if {![null $arg]} {
    	    	var arg [range $arg 1 end chars]
    	    }
    	}
	var args [cdr $args]
    }

    echo Graphics String:
    echo {OFFSET   OPCODE}
    echo {------   ------}
    if {[null $args]} {
    	var args {ds:si}
    }
    var addr [addr-parse $args]
    var seg ^h[format %04xh [handle id [index $addr 0]]]
    var off [index $addr 1]
    var base $off

    #
    # If base is zero, if could be that we were passed some type of handle.
    # See if it's a gstring thing and do the right thing.  It's got to be
    # an LMem block, and of the right type.
    #

    var hid [handle id [index $addr 0]]

    if {$base == 0} {
	if {[handle state [index $addr 0]] & 0x800} {
	    #
    	    # It's an LMem block.  If it's a gstate, get the corresponding
    	    # GString handle
    	    #
	    if {[value fetch ^h$hid:LMBH_lmemType] == 
    	    	[getvalue LMEM_TYPE_GSTATE] } {
		var hid [value fetch ^h$hid.GS_gstring]
		if {$hid == 0} {
		    error {GState not associated with a GString}
    	    	}
    	    }
    	    #
    	    # Finally, we're at the GString structure.  See what the type is.
    	    #
	    if {[value fetch ^h$hid:LMBH_lmemType] ==
		[getvalue LMEM_TYPE_GSTRING]} {
    	    	#
    	    	# Get at the start of the string, based on the type
    	    	#
    	    	var gstype [penum geos:GStringType 
    	    	    	    	  [field [value fetch ^h$hid:GSS_flags] 
    	    	    	    	         GSF_HANDLE_TYPE]]
    	    	var cp 0
    	    	if {$startCP == 1} {
    	    	    var cp [value fetch ^h$hid:GSS_curPos [type dword]]
    	    	}
    	    	[case $gstype in
    	    	    GST_VMEM {
    	    	    	var isvm 1
    	    	    	var vmfile [value fetch ^h$hid:GSS_hString]
    	    	    	var dirblk [value fetch ^h$hid:GSS_firstBlock]
    	    	    	var address [format {^v%d:%d} $vmfile $dirblk]
    	    	    }
		    GST_STREAM {
    	    	    	# starting position recorded in GSS_curPos?
    	    	    	[pgsstream [value fetch ^h$hid:GSS_hString] 
			    	[if {$startCP}
			    	    {value fetch ^h$hid:GSS_filePos}
				    {value fetch ^h$hid:GSS_curPos}]
			    	$elRange]
			return
		    }
		    GST_CHUNK {
		    	if {$startCP == 1} {
    	    	    	    var chunk [value fetch ^h$hid:GSS_firstBlock]
			    var hid [value fetch ^h$hid:GSS_hString]
    	    	    	    var start [value fetch ^h$hid:$chunk word]
    	    	    	    var address [format {^h%d:%d+%d} $hid $start $cp]
    	    	    	} else {
    	    	    	    var address [format {^l%d:%d}
					 [value fetch ^h$hid.GSS_hString]
			    	    	 [value fetch ^h$hid:GSS_firstBlock]]
    	    	    	}
    	       	    }
		    GST_PTR {
		    	if {$startCP == 1} {
    	    	    	    var address [format {%d:%d+%d} 
    	    	    	    	    	 [value fetch ^h$hid:GSS_hString]
			    	    	 [value fetch ^h$hid:GSS_firstBlock]
    	    	    	    	    	 $cp]
    	    	    	} else {
    	    	    	    var address [format {%d:%d} 
    	    	    	    	    	 [value fetch ^h$hid:GSS_hString]
			    	    	 [value fetch ^h$hid:GSS_firstBlock]]
    	    	    	}
    	    	    }
    	    	]
	    	var addr [addr-parse $address]
		var seg ^h[format %04xh [handle id [index $addr 0]]]
		var off [index $addr 1]
		var base $off
		var hid [handle id [index $addr 0]]

   	    	} else {
		    error {There can't be a gstring at offset 0 of a non-gstring lmem block}
    	    	}
    	    } elif {[handle isvm 
	    	     [handle lookup [value fetch kdata:$hid.HM_owner]]]} {
    	    	#
		# Get a file handle for the owning VM file.
		#
    	    	var vmh [value fetch kdata:$hid.HM_owner]
		var vmfile [value fetch kdata:$vmh.HVM_fileHandle]
    	    	#
		# Map the memory handle for the hugearray directory block
		# to its corresponding VM block handle.
		#
		var hdr ^h[value fetch kdata:$vmh.HVM_headerHandle]
		var lasth [value fetch $hdr.VMH_lastHandle]
		var bs [type size [symbol find type VMBlockHandle]]

		[for {var dirblk [getvalue VMH_blockTable]}
		     {$dirblk < $lasth}
		     {var dirblk [expr $dirblk+$bs]}
    	    	{
		    [if {([value fetch $hdr:$dirblk.VMBH_sig] & 1) &&
		    	 [value fetch $hdr:$dirblk.VMBH_memHandle] == $hid}
    	    	    {
		    	break
    	    	    }]
    	    	}]
		
		if {$dirblk == $lasth} {
		    error [format {Cannot find VM block handle for %04xh} $hid]
    	    	}
    	    	#
		# Signal the thing is a VM-based gstring and $vmfile and $dirblk
		# contain the directory block for the huge array.
		#
    	    	var isvm 1
    	    }
    	} elif { $isGrObj } {
	    var isvm 1
	    var dirblk [value fetch ($args).GSI_vmemBlockHandle]
    	    var vmh [value fetch kdata:$hid.HM_owner]
	    var vmfile [value fetch kdata:$vmh.HVM_fileHandle]
	}

#
# print out the graphics string
#
    if {$isvm} {
    	pharray -tgstring -e$cp -l$elRange $vmfile $dirblk
    } else {
    	var cursize 1
    	[for {} {$cursize!=0 && $elRange!=0} 
    	    	{var off [expr $off+$cursize] elRange [expr $elRange-1]} {
    	    var cursize [pgselem $seg:$off -1]
    	}]
    }

}]
##############################################################################
#				pgsstream
##############################################################################
#
# SYNOPSIS:	Complex function to print out a stream GString
# PASS:		fh  	= file handle
#   	    	startpos= position of start of gstring within file
#   	    	elRange = number of elements to print
# CALLED BY:	pgs
# RETURN:	nothing
# SIDE EFFECTS:	memory allocated & freed, etc.
#
# STRATEGY  	currently ignores startpos & always prints the gstring from
#   	    	the very start.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	10/20/93	Initial Revision
#
##############################################################################
[defsubr pgsstream {fh startpos elRange}
{
    var pd [patient data]
    protect {
    	switch

	if {![call-patient FilePosFar bx $fh al geos::FILE_POS_RELATIVE cx 0 dx 0]} {
	    restore-state
	    error {can't get initial position}
	}
	var initPos [list [read-reg dx] [read-reg ax]]
	restore-state
	
	if {![call-patient FilePosFar bx $fh al geos::FILE_POS_START cx [expr $startpos>>16] dx [expr $startpos&0xffff]]} {
	    restore-state
	    error {can't set initial position}
    	}
	restore-state
	
    	if {![call-patient geos::GrLoadGString bx $fh cl geos::GST_STREAM ch 0]} {
	    restore-state
	    error {unable to allocate secondary gstring}
    	}
	var gstate [read-reg si] gstring [value fetch ^hsi.GS_gstring]
	restore-state
	
	if {![call-patient geos::GrSetGStringPos si $gstate al geos::GSSPT_BEGINNING]} {
	    restore-state
	    error {unable to reposition file}
	}
	restore-state

	if {![call-patient MemLock bx $gstring]} {
	    restore-state
	    error {unable to lock secondary gstring}
    	}
	assign es ax
	
    	
    	[for {}
	     {$cursize!=0 && $elRange!=0} 
    	     {var elRange [expr $elRange-1]} 
    	{
    	    if {![call-patient geos::ReadElement]} {
	    	restore-state
		restore-state
		error {unable to call ReadElement}
    	    }
	    discard-state
	    if {[getcc C]} {
	    	restore-state
		error {error returned by ReadElement}
    	    }

    	    var cursize [pgselem ds:si [value fetch es:GSS_lastSize]]
	    assign es:GSS_flags.GSF_ELEMENT_READY 0
    	}]
	restore-state
	if {![call-patient MemUnlock bx $gstring]} {
	    echo {error unlocking gstring}
    	}
	restore-state
    } {
    	if {![null $gstring]} {
	    call-patient MemFree bx $gstring
	    restore-state
	    call-patient GrDestroyState di $gstate
	    restore-state
    	}
	
    	if {![null $initPos]} {
	    call-patient FilePosFar bx $fh al geos::FILE_POS_START cx [index $initPos 0] dx [index $initPos 1]
	    restore-state
    	}
	
    	switch [index $pd 0]:[index $pd 2]
    }
}]
    
##############################################################################
#				pgselem
##############################################################################
#
# SYNOPSIS:	Print a single graphics string element, and return info about
#   	    	the size of the element
# PASS:		address	- address of element
#   	    	size - size of element, total
# CALLED BY:	pgs, (via pharray or pcarray sometimes)
# RETURN:	size	- size of element
# SIDE EFFECTS:	nothing
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jim	5/ 1/92		Initial Revision
#
##############################################################################
[defsubr pgselem {address size}
{
    var	addr	[addr-preprocess $address seg off]
    var element [value fetch $seg:$off [type byte]]
    var esize   [value fetch {geos::GraphicsCommon::GSElemInfoTab[$element].GSEI_size}]
    var	varSize	[expr $esize>>8]
    var voff	[expr $varSize&0x3f]
    var	fsize	[expr $esize&255]
    var eltype	[penum geos::GStringElement $element]
    var tfsize  0
    
    #
    # Fetch state of -c option if called from pgs, else don't print coords.
    #
    if {[catch {uplevel pgs var pCrdLists} coordOption] != 0} {
    	var coordOption 0
    }

    #
    # Fetch state of -a option if called from pgs, else don't print db
    # statements
    #
    if {[catch {uplevel pgs var asMacros} asmMode] != 0} {
    	var asmMode 0
    }


    #
    # Signal the stopping condition, if we're at the end of the string
    #
    if {([string c $eltype GR_END_GSTRING]==0) || [null $eltype]} {
    	var fsize 0
    }
    if {$asmMode} {
    	echo -n [format {;\n;}]
    }
    echo -n [format {0x%04x} $off]
    [case $eltype in
    	GR_*_BITMAP_OPTR {
	    echo -n \t $eltype -- (
	    pcoord $seg:$off.ODBOP_x 1
	    pcoord $seg:$off.ODBOP_y 2
	    var chunk [value fetch $seg:$off.ODBOP_optr.chunk]
	    var han [value fetch $seg:$off.ODBOP_optr.handle]
	    echo [format {^l%04xh:%04xh} $han $chunk]
	}
    	GR_*_BITMAP_PTR  {
	    echo -n \t $eltype -- (
	    pcoord $seg:$off.ODBP_x 1
	    pcoord $seg:$off.ODBP_y 2
    	    var bptr [value fetch $seg:$off.ODBP_ptr]
	    var width [value fetch $seg:$bptr.B_width]
	    var height [value fetch $seg:$bptr.B_height]
	    var compact [value fetch $seg:$bptr.B_compact]
	    var btype [value fetch $seg:$bptr+4 [type byte]]
	    echo -n [format {width=%d,height=%d,} $width $height]
	    var fmt [expr $btype&7]
	    echo [format {%s, %s} [penum geos::BMFormat $fmt] [penum geos::BMCompact $compact]]
	}
	GR_COMMENT {
	    echo \t $eltype
	}
	GR_LABEL {
	    echo -n \t [format {%s -- %d} $eltype 
    	    	    	    	    	  [value fetch $seg:$off.OL_value]]
	}
	GR_ESCAPE {
	    var escsize [value fetch $seg:$off.OE_escSize]
	    var ecode [value fetch $seg:$off.OE_escCode]
    	    echo -n \t $eltype {-- }
	    echo [format {ESC CODE:%xh (%d),size=%d} $ecode $ecode $escsize]
	}
	GR_DRAW_TEXT_CP {
	    var tsize [value fetch $seg:$off.ODTCP_len]
	    echo -n \t $eltype {-- }
	    pvmtext $seg:$off+3 $tsize
	}
	GR_DRAW_TEXT_PTR {
	    echo -n \t $eltype {-- }
	    pcoord $seg:$off.ODTP_x1 1
	    pcoord $seg:$off.ODTP_y1 2
    	    var toff [value fetch $seg:$off.ODTP_ptr]
	    pstring $seg:$toff
	}
	GR_DRAW_TEXT_OPTR {
	    echo -n \t $eltype -- (
	    pcoord $seg:$off.ODBOP_x 1
	    pcoord $seg:$off.ODBOP_y 2
	    var chunk [value fetch $seg:$off.ODTOP_ptr.chunk]
	    var han [value fetch $seg:$off.ODTOP_ptr.handle]
	    echo [format {^l%04xh:%04xh} $han $chunk]
	    pstring ^l$han:$chunk
	}
	GR_DRAW_TEXT {
   	    var tsize [value fetch $seg:$off.ODT_len]
	    echo -n \t $eltype {-- (}
	    pcoord $seg:$off.ODT_x1 1
	    pcoord $seg:$off.ODT_y1 2
	    pvmtext $seg:$off+7 $tsize
	}
	GR_DRAW_CHAR_CP {
	    echo -n \t $eltype {-- }
	    echo [format {"%c"} [value fetch $seg:$off+1 [type byte]]]
	}
	GR_DRAW_CHAR {
	    echo -n \t $eltype {-- (}
	    pcoord $seg:$off.ODC_x1 1
	    pcoord $seg:$off.ODC_y1 2
	    echo [format { - "%c"} [value fetch $seg:$off+1 [type byte]]]
	}
	GR*ROUND_RECT {
	    echo -n \t $eltype {-- radius=}
	    pcoord $seg:$off.ODRR_radius 1
    	    echo -n {  (}
	    pcoord $seg:$off.ODRR_x1 1
	    pcoord $seg:$off.ODRR_y1 4
	    pcoord $seg:$off.ODRR_x2 1
	    pcoord $seg:$off.ODRR_y2 0
	}
	GR*ROUND_RECT_TO {
	    echo -n \t $eltype {-- radius=}
	    pcoord $seg:$off.ODRRT_radius 1
    	    echo -n {  (}
	    pcoord $seg:$off.ODRRT_x2 1
	    pcoord $seg:$off.ODRRT_y2 3
	}
	{GR*ARC} {
	    echo -n \t $eltype {-- (}
	    pcoord $seg:$off.ODATP_x1 1
	    pcoord $seg:$off.ODATP_y1 4
	    pcoord $seg:$off.ODATP_x2 1
	    pcoord $seg:$off.ODATP_y2 4
	    pcoord $seg:$off.ODATP_x3 1
	    pcoord $seg:$off.ODATP_y3 4
	    echo [penum geos::ArcCloseType [value fetch $seg:$off.ODATP_close]])
    	}
	{GR*ARC_3POINT} {
	    echo -n \t $eltype {-- (}
	    pfixed $seg:$off.ODATP_x1 1
	    pfixed $seg:$off.ODATP_y1 4
	    pfixed $seg:$off.ODATP_x2 1
	    pfixed $seg:$off.ODATP_y2 4
	    pfixed $seg:$off.ODATP_x3 1
	    pfixed $seg:$off.ODATP_y3 4
	    echo [penum geos::ArcCloseType [value fetch $seg:$off.ODATP_close]])
    	}
    	GR_DRAW_REL_ARC_3POINT_TO) {
	    echo -n \t $eltype {-- (}
	    pfixed $seg:$off.ODRATPT_x2 1
	    pfixed $seg:$off.ODRATPT_y2 4
	    pfixed $seg:$off.ODRATPT_x3 1
	    pfixed $seg:$off.ODRATPT_y3 4
	    echo [penum geos::ArcCloseType [value fetch $seg:$off.ODRATPT_close]])
    	}
	{GR_DRAW_ARC_3POINT_TO GR_FILL_ARC_3POINT_TO} {
	    echo -n \t $eltype {-- (}
	    pfixed $seg:$off.ODATPT_x2 1
	    pfixed $seg:$off.ODATPT_y2 4
	    pfixed $seg:$off.ODATPT_x3 1
	    pfixed $seg:$off.ODATPT_y3 4
	    echo [penum geos::ArcCloseType [value fetch $seg:$off.ODATPT_close]])
    	}
	GR*CLIP_RECT {
	    echo -n \t $eltype {-- (}
    	    if {[value fetch $seg:$off.OSCR_flags] == 0} then {
	    	echo {NULL)}
    	    } else {
	    	pcoord $seg:$off.OSCR_rect.R_left 1
	    	pcoord $seg:$off.OSCR_rect.R_top 4
		pcoord $seg:$off.OSCR_rect.R_right 1
		pcoord $seg:$off.OSCR_rect.R_bottom 0
	    }
    	}
    	{GR*RECT GR_DRAW_LINE GR*ELLIPSE GR*BOUNDS} {
	    echo -n \t $eltype {-- (}
	    pcoord $seg:$off.ODR_x1 1
	    pcoord $seg:$off.ODR_y1 4
	    pcoord $seg:$off.ODR_x2 1
	    pcoord $seg:$off.ODR_y2 0
	}
	{GR_MOVE_TO GR*RECT_TO GR_DRAW_LINE_TO GR_DRAW_POINT} {
	    echo -n \t $eltype {-- (}
	    pcoord $seg:$off.ODRT_x2 1
	    pcoord $seg:$off.ODRT_y2 0
	}
	{GR_REL_MOVE_TO GR_DRAW_REL_LINE_TO} {
	    echo -n \t $eltype {-- (}
	    pfixed $seg:$off.ORMT_x1 1
	    pfixed $seg:$off.ORMT_y1 0
	}
	{GR*HLINE GR*VLINE} {
	    echo -n \t $eltype {-- (}
	    pcoord $seg:$off.ODHL_x1 1
	    pcoord $seg:$off.ODHL_y1 4
	    pcoord $seg:$off.ODHL_x2 0
	}
	GR_SET_FONT {
	    echo -n \t $eltype {-- }
	    var fontid [value fetch $seg:$off.OSF_id]
	    echo -n [format {%s, } [penum geos::FontID $fontid]]
    	    pfixed $seg:$off.OSF_size 3 byte
    	}
	{GR*HLINE_TO GR*VLINE_TO} {
	    echo -n \t $eltype {-- }
	    pcoord $seg:$off.ODHLT_x2 3
	}
	GR_*_BITMAP {
	    echo -n \t $eltype {--(}
	    var width [value fetch $seg:$off+7 [type word]]
	    var height [value fetch $seg:$off+9 [type word]]
	    var compact [value fetch $seg:$off+11 [type byte]]
	    var btype [value fetch $seg:$off+12 [type byte]]
	    var fmt [expr $btype&7]
	    pcoord $seg:$off.ODB_x 1
	    pcoord $seg:$off.ODB_y 2
	    echo -n [format {%s:%04xh, } $seg [expr $off+7]]
	    echo -n [format {width=%d,height=%d,} $width $height]
	    echo [format {%s, %s} [penum geos::BMFormat $fmt] [penum geos::BMCompact $compact]]
	}
	GR_*_BITMAP_CP {
	    echo -n \t $eltype {-- }
	    var width [value fetch $seg:$off+3 [type word]]
	    var height [value fetch $seg:$off+5 [type word]]
	    var compact [value fetch $seg:$off+7 [type byte]]
	    var type [value fetch $seg:$off+8 [type byte]]
	    var fmt [expr $type&7]
	    echo -n [format {%s:%04xh, } $seg [expr $off+3]]
	    echo -n [format {width=%d, height=%d, } $width $height]
	    echo [penum geos::BMFormat $fmt], [penum geos::BMCompact $compact]
	}
	GR_SET_MIX_MODE {
	    echo -n \t $eltype {-- }
	    echo [penum geos::MixMode [value fetch $seg:$off.OSMM_mode]]
	}
	GR_SET*COLOR_INDEX {
	    echo -n \t $eltype {-- }
	    echo [penum geos::Color [value fetch $seg:$off.OSACI_color]]
	}
	GR_FILL_POLYGON {
	    echo -n \t $eltype {-- }
	    echo -n [penum geos::RegionFillRule [value fetch $seg:$off.OFP_rule]]
    	    var cc [value fetch $seg:$off.OFP_count]
	    echo [format { rule, %d coord pairs} $cc]
    	    if {$coordOption==1} then {
    	    	[for {var pc 0} {$pc<$cc} {var pc [expr $pc+1]} {
    	    	    echo -n \t\t {(}
    	    	    pcoord $seg:$off+[size OpFillPolygon]+[expr $pc*4] 1
    	    	    pcoord $seg:$off+[size OpFillPolygon]+[expr $pc*4]+2 0
    	    	}]
    	    }
	}
	{GR_DRAW_SPLINE GR_DRAW_SPLINE_TO GR_DRAW_POLY*} {
	    echo -n \t $eltype {-- }
    	    var cc [value fetch $seg:$off.ODS_count]
	    echo [format {%d coord pairs} $cc]
    	    if {$coordOption==1} then {
    	    	[for {var pc 0} {$pc<$cc} {var pc [expr $pc+1]} {
    	    	    echo -n \t\t {(}
    	    	    pcoord $seg:$off+[size OpDrawPolygon]+[expr $pc*4] 1
    	    	    pcoord $seg:$off+[size OpDrawPolygon]+[expr $pc*4]+2 0
    	    	}]
    	    }
	}
    	{GR_DRAW*CURVE_TO} {
	    echo -n \t $eltype {-- (}
	    pcoord $seg:$off.ODCVT_x2 1
	    pcoord $seg:$off.ODCVT_y2 5
	    pcoord $seg:$off.ODCVT_x3 1
	    pcoord $seg:$off.ODCVT_y3 5
	    pcoord $seg:$off.ODCVT_x4 1
	    pcoord $seg:$off.ODCVT_y4 0
    	}
    	{GR_DRAW*CURVE} {
	    echo -n \t $eltype {-- (}
	    pcoord $seg:$off.ODCV_x1 1
	    pcoord $seg:$off.ODCV_y1 5
	    pcoord $seg:$off.ODCV_x2 1
	    pcoord $seg:$off.ODCV_y2 5
	    pcoord $seg:$off.ODCV_x3 1
	    pcoord $seg:$off.ODCV_y3 5
	    pcoord $seg:$off.ODCV_x4 1
	    pcoord $seg:$off.ODCV_y4 0
    	}
	{GR_BRUSH_POLYLINE} {
	    echo -n \t $eltype {-- }
    	    var cc [value fetch $seg:$off.OBPL_count]
	    echo [format {%d coord pairs} $cc]
    	    echo [format {\t brush size: %d wide by %d high} 
    	    	    	 [value fetch $seg:$off.OBPL_width]
    	    	    	 [value fetch $seg:$off.OBPL_height]]
    	    if {$coordOption==1} then {
    	    	[for {var pc 0} {$pc<$cc} {var pc [expr $pc+1]} {
    	    	    echo -n \t\t {(}
    	    	    pcoord $seg:$off+[size OpBrushPolyline]+[expr $pc*4] 1
    	    	    pcoord $seg:$off+[size OpBrushPolyline]+[expr $pc*4]+2 0
    	    	}]
    	    }
	}
	GR_SET*COLOR {
	    echo -n \t $eltype {-- }
	    echo -n RGB: 
	    var r [value fetch $seg:$off.OSAC_color.RGB_red]
	    var g [value fetch $seg:$off.OSAC_color.RGB_green]
	    var b [value fetch $seg:$off.OSAC_color.RGB_blue]
	    echo [format {(%d,%d,%d)} $r $g $b]
	}
	GR_SET*JOIN {
	    echo -n \t $eltype {-- }
	    echo [penum geos::LineJoin [value fetch $seg:$off.OSLJ_mode]]
	}
	{GR_SET_MITER_LIMIT GR_SET_LINE_WIDTH} {
	    echo -n \t $eltype {-- }
	    pfixed $seg:$off.OSML_mode 3
	    }
	GR_SET*MAP {
	    echo -n \t $eltype {-- }
	    var mmode [field [value fetch $seg:$off.OSLCM_mode] CMM_MAP_TYPE]
	    echo [penum geos::ColorMapType $mmode]
	}
	GR_SET_CUSTOM*MASK {
	    echo -n \t $eltype {-- }
    	    for {var boff 1} {$boff <= 8} {var boff [expr $boff+1]} {
    	    	var bval [value fetch $seg:$off+$boff [type byte]]
    	    	echo -n [format {%02x } $bval]
    	    } 
    	    echo 
	}
	GR_SET_CUSTOM*STYLE {
	    echo -n \t $eltype {-- }
	    echo [format {%d on/off pairs} [value fetch $seg:$off.OSCLS_count]]
	}
	GR_SET*MASK {
	    echo -n \t $eltype {-- }
            var dmask [field [value fetch $seg:$off.OSLM_mask] SDM_MASK]
	    echo [penum geos::SystemDrawMask $dmask]
	}
	GR_SET_LINE_END {
	    echo -n \t $eltype {-- }
	    echo [penum geos::LineEnd [value fetch $seg:$off.OSLE_mode]]
	}
	GR_SET_LINE_STYLE {
	    echo -n \t $eltype {-- }
	    echo -n [penum geos::LineStyle [value fetch $seg:$off.OSLS_style]]
	    echo [format {, index = %d} [value fetch $seg:$off.OSLS_index]]
	}
	GR_APPLY_ROTATION {
	    echo -n \t $eltype {-- }
	    echo -n {angle=}
	    pfixed $seg:$off.OAR_angle 3
	}
	GR_APPLY_SCALE {
	    echo -n \t $eltype {-- }
	    echo -n {xscale=}
	    pfixed $seg:$off.OAS_xScale 1
	    echo -n {yscale=}
	    pfixed $seg:$off.OAS_yScale 3
	}
	GR_APPLY_TRANSLATION {
	    echo -n \t $eltype {-- }
	    echo -n {xoffset=}
	    pfixed $seg:$off.OAT_x 1
	    echo -n {yoffset=}
	    pfixed $seg:$off.OAT_y 3
	}
	GR_APPLY_TRANSLATION_DWORD {
	    echo -n \t $eltype {-- }
	    echo -n {xoffset=}
	    pcoord $seg:$off.OADT_x 1 dword
	    echo -n {yoffset=}
	    pcoord $seg:$off.OADT_y 3 dword
	}
	{GR_SET_TRANSFORM GR_APPLY_TRANSFORM} {
	    echo -n \t $eltype {-- }
	    pfixed $seg:$off.OST_elem11 1
	    pfixed $seg:$off.OST_elem12 1
	    pfixed $seg:$off.OST_elem21 1
	    pfixed $seg:$off.OST_elem22 1
	    pdfixed $seg:$off.OST_elem31 1
	    pdfixed $seg:$off.OST_elem32 0
	}
	GR_SET_LINE_ATTR {
	    echo -n \t $eltype {-- }
	    var cflag [penum geos::ColorFlag [value fetch $seg:$off.OSLA_attr.LA_colorFlag]]
	    var r [value fetch $seg:$off.OSLA_attr.LA_color.RGB_red]
	    var g [value fetch $seg:$off.OSLA_attr.LA_color.RGB_green]
	    var b [value fetch $seg:$off.OSLA_attr.LA_color.RGB_blue]
	    var cmode [penum geos::ColorMapType [field [value fetch $seg:$off.OSLA_attr.LA_mapMode] CMM_MAP_TYPE]]
	    var dmask [penum geos::SystemDrawMask [value fetch $seg:$off.OSLA_attr.LA_mask]]
    	    if {[null $dmask]} {
	    	var dmask [value fetch $seg:$off.OSLA_attr.LA_mask]
    	    }
	    var le [penum geos::LineEnd [value fetch $seg:$off.OSLA_attr.LA_end]]
	    var lj [penum geos::LineJoin [value fetch $seg:$off.OSLA_attr.LA_join]]
	    var ls [penum geos::LineStyle [value fetch $seg:$off.OSLA_attr.LA_style]]
	    echo -n $cflag:
    	    [case $cflag in
    	    	CF_RGB {
	    	    echo -n [format {(%d,%d,%d),} $r $g $b]
    	     	}
    	    	CF_INDEX {
	    	    echo -n [format {%s,} [penum geos::Color $r]]
    	    	}
    	    	CF_GRAY {
    	    	    echo -n [format {%d,} $r]
    	    	}]
    	    echo -n ${cmode},${dmask},
	    echo -n {width=}
    	    pfixed $seg:$off.OSLA_attr.LA_width 1
    	    echo ${le},${lj},${ls}
	}
	GR_SET_AREA_ATTR {
	    echo -n \t $eltype {-- }
	    var cflag [penum geos::ColorFlag [value fetch $seg:$off.OSAA_attr.AA_colorFlag]]
	    var r [value fetch $seg:$off.OSAA_attr.AA_color.RGB_red]
	    var g [value fetch $seg:$off.OSAA_attr.AA_color.RGB_green]
	    var b [value fetch $seg:$off.OSAA_attr.AA_color.RGB_blue]
	    var cmode [penum geos::ColorMapType [field [value fetch $seg:$off.OSAA_attr.AA_mapMode] CMM_MAP_TYPE]]
	    var dmask [penum geos::SystemDrawMask [value fetch $seg:$off.OSAA_attr.AA_mask]]
	    if {[null $dmask]} {
	    	var dmask [value fetch $seg:$off.OSAA_attr.AA_mask]
    	    }
	    echo -n $cflag:
    	    [case $cflag in
    	    	CF_RGB {
	    	    echo -n [format {(%d,%d,%d),} $r $g $b]
    	     	}
    	    	CF_INDEX {
	    	    echo -n [format {%s,} [penum geos::Color $r]]
    	    	}
    	    	CF_GRAY {
    	    	    echo -n [format {%d,} $r]
    	    	}]
	    echo [format {%s, %s} $cmode $dmask]
	}
	GR_SET_TEXT_ATTR {
	    echo -n \t $eltype {-- (}
	    ptextattr $seg:$off.OSTA_attr $asmMode
	}
    	GR_DRAW_TEXT_FIELD {
    	    echo -n \t $eltype {-- }
    	    var tlen [value fetch $seg:$off.ODTF_saved.GDFS_nChars]
    	    echo -n [format {%d chars drawn at (} $tlen]
    	    pfixed $seg:$off.ODTF_saved.GDFS_drawPos.PWBF_x 1 byte
    	    pfixed $seg:$off.ODTF_saved.GDFS_drawPos.PWBF_y 0 byte
    	    var styleoff [expr $off+[size OpDrawTextField]]
    	    var slen 0
    	    var	runnum 1
    	    [for {} {$tlen > 0} 
    	    	    {var styleoff [expr $styleoff+[size TFStyleRun]+$slen]
    	    	     var runnum [expr $runnum+1]
		     var tlen [expr $tlen-$slen]}
	    {
    	    	#
    	    	# for each style run, print the text and the style info
    	    	# we're also keeping track of the total size of the style
    	    	# runs, so we can return the right element size at the end
    	    	#
    	    	var slen [value fetch $seg:$styleoff.TFSR_count]
    	    	var tfsize [expr $tfsize+$slen+[size TFStyleRun]]
    	    	if {$asmMode} {echo -n ;}
    	    	echo \t [format {--- Style Run #%d ---} $runnum]
    	    	var toff [expr $styleoff+[size TFStyleRun]]
    	    	if {$asmMode} {echo -n ;}
		echo -n \t
    	    	pvmtext $seg:$toff $slen
    	    	if {$asmMode} {echo -n ;}
		echo -n \t { }
    	    	ptextattr $seg:$styleoff.TFSR_attr $asmMode
    	     }]
    	}
    	GR_SET_TEXT_MODE {
	    echo -n \t $eltype -- 
    	    psetclear $seg:$off.OSTMo_set geos::TextMode
	    echo
    	}
    	GR_SET_TEXT_STYLE {
	    echo -n \t $eltype -- 
    	    psetclear $seg:$off.OSTS_set geos::TextStyle
	    echo
    	}
    	GR_SET_PALETTE_ENTRY {
    	    echo -n \t $eltype -- 
    	    var entry [value fetch $seg:$off.OSPE_entry]
    	    var r [value fetch $seg:$off.OSPE_color.RGB_red]
    	    var g [value fetch $seg:$off.OSPE_color.RGB_green]
    	    var b [value fetch $seg:$off.OSPE_color.RGB_blue]
    	    echo -n [format {entry: %d = (%d,%d,%d)} $entry $r $g $b]
    	}
    	GR_SET_PALETTE {
    	    echo -n \t $eltype -- 
    	    var entry [value fetch $seg:$off.OSP_num]
    	    echo -n [format {#entries set: %d} $entry]
    	}
	GR_SET_TEXT_SPACE_PAD {
	    echo -n \t $eltype {-- }
	    pfixed $seg:$off.OSTSP_pad 3 byte
    	}
	GR_BEGIN_PATH {
	    echo -n \t $eltype {-- }
	    var pct [symbol find type geos::PathCombineType]
	    var lend [type emap [value fetch $seg:$off.OBP_combine] $pct]
	    var flags [value fetch $seg:$off.OBP_flags [symbol find type geos::BeginPathFlags]]
	    echo [format {PathCombineType: %s (%d)} $lend [value fetch $seg:$off.OBP_combine]]
	    if {$asmMode} {
	    	echo -n [format {;\t }]
    	    } else {
	    	echo -n [format {\t }]
    	    }
	    if {[field $flags BPF_FILL_RULE_VALID]} {
	    	echo -n [format {RegionFillRule: %s (%d), }
		    	    [type emap [field $flags BPF_FILL_RULE]
				      [symbol find type geos::RegionFillRule]]
		    	    [field $flags BPF_FILL_RULE]]
    	    }
	    echo -n [format {PathCoordSource: %s (%d), }
	    	    	[type emap [field $flags BPF_COORD_TYPE]
	    	    	    	    [symbol find type geos::PathCoordSource]]
			[field $flags BPF_COORD_TYPE]]
	    echo -n [format {Bounds %sknown, }
		  [if {![field $flags BPF_BOUNDS_KNOWN]} {format {not }}]]
    	    echo [format {Sub combine type: %s (%d)}
		    	    [type emap [field $flags BPF_COMBINE] $pct]
			    [field $flags BPF_COMBINE]]
	}
    	{GR_SET_CLIP_PATH GR_SET_WIN_CLIP_PATH} {
	    echo -n \t $eltype {-- }
	    var pct 
	    var lend [type emap [value fetch $seg:$off.OSCP_flags] 
			   [symbol find type geos::PathCombineType]]
	    var fill [type emap [value fetch $seg:$off.OSCP_rule]
	    	    	   [symbol find type geos::RegionFillRule]]
	    
	    echo [format {PathCombineType: %s (%d), RegionFillRule: %s (%d)}
	    	    $lend [value fetch $seg:$off.OSCP_flags]
		    $fill [value fetch $seg:$off.OSCP_rule]]
    	}
    	GR_SET_FONT_WEIGHT {
    	    echo -n \t $eltype {-- }
    	    echo [penum geos::FontWeight [value fetch $seg:$off.OSFW_weight]]
    	}
    	GR_SET_FONT_WIDTH {
    	    echo -n \t $eltype {-- }
    	    echo [penum geos::FontWidth [value fetch $seg:$off.OSFWI_width]]
    	}
    	GR_SET_SUPERSCRIPT_ATTR {
    	    echo -n \t $eltype {-- }
    	    echo -n [format {pos = %d%%} [value fetch $seg:$off.OSSA_pos]]
    	    echo [format {size = %d%%} [value fetch $seg:$off.OSSA_size]]
    	}
    	GR_SET_SUBSCRIPT_ATTR {
    	    echo -n \t $eltype {-- }
    	    echo -n {pos = }
    	    echo -n [format {pos = %d%%} [value fetch $seg:$off.OSSBA_pos]]
    	    echo [format {size = %d%%} [value fetch $seg:$off.OSSBA_size]]
    	}
        GR_FILL_PATH {
	    echo -n \t $eltype {-- }
    	    var lend [value fetch $seg:$off+1 [type byte]]
	    echo -n RegionFillRule:
	    echo [penum geos::RegionFillRule $lend]
    	}
    	GR_SET_CUSTOM_*_PATTERN {
    	    echo -n \t $eltype
        }
        GR_SET_*_PATTERN {
	    echo -n \t $eltype {-- }
	    var type [penum geos::PatternType 
	    	    	[value fetch $seg:$off.OSAP_pattern.GP_type]]
	    var data [value fetch $seg:$off.OSAP_pattern.GP_data]
	    
	    [case $type in
	    	PT_SOLID {
		    echo PT_SOLID
		}
		PT_SYSTEM_HATCH {
		    echo PT_SYSTEM_HATCH, [penum geos::SystemHatch $data]
    	    	}
		PT_SYSTEM_BITMAP {
		    echo PT_SYSTEM_BITMAP, [penum geos::SystemBitmap $data]
		}
		default {
		    echo $type, $data
		}
    	    ]
        }
    	GSE_BITMAP_SLICE {
    	    echo -n \t $eltype {-- }
    	    var bsize [value fetch $seg:$off.OBS_size word]
    	    var bmoff [expr $off+[size OpBitmapSlice]]
    	    var nscans [value fetch $seg:$bmoff.CB_numScans word]
    	    echo [format {numBytes=%d, numscans=%d} $bsize $nscans]
    	}
	nil {
	    echo [format {Bad gstring opcode: %d } $element]
    	    var varSize 0 fsize 0
	}
	default {
	    echo \t $eltype
	}]
    #
    # OK, we've printed out all the interesting info, now return the size
    #
    if {$size == -1} {
	var vcount 0
	if {($varSize & 0xc0) == 0x40} {
	    var vcount [value fetch $seg:$off+$voff [type word]]
	} elif {($varSize & 0xc0) == 0x80} {
	    var vcount [expr [value fetch $seg:$off+$voff [type word]]*2]
	} elif {($varSize & 0xc0) == 0xc0} {
	    var vcount [expr [value fetch $seg:$off+$voff [type word]]*4]
	} elif {$tfsize != 0} {
	    var vcount $tfsize
	}
	var size [expr $fsize+$vcount]
    }
    if {$asmMode} {
    	#
	# Now print out all the bytes for Esp to use.
	#
	[for {var i 0 j 8 n $size}
	     {$n > 0}
	     {var n [expr $n-1] i [expr $i+1] j [expr $j-1]}
    	{
	    if {$j == 8} {
	    	echo -n \tdb\t
    	    }
	    echo -n [format {0x%02x} [value fetch $seg:$off+$i byte]]
	    if {$j == 1 || $n == 1} {
	    	var j 9
		echo
    	    } else {
	    	echo -n {, }
    	    }
    	}]
    }
    return $size
}]

[defsubr ptextattr {addr asmMode}
{
    var cflag [penum geos::ColorFlag [value fetch ($addr).TA_color.CQ_info]]
    var r [value fetch ($addr).TA_color.CQ_redOrIndex]
    var g [value fetch ($addr).TA_color.CQ_green]
    var b [value fetch ($addr).TA_color.CQ_blue]
    var dmask [penum geos::SystemDrawMask [value fetch ($addr).TA_mask]]
    if {[null $dmask]} {
	var dmask [value fetch ($addr).TA_mask]
    }
    echo -n $cflag:
    [case $cflag in
	CF_RGB {
	    echo -n [format {(%d,%d,%d),} $r $g $b]
	}
	CF_INDEX {
	    echo -n [format {%s,} [penum geos::Color $r]]
	}
	CF_GRAY {
	    echo -n [format {%d,} $r]
	}]
    echo [format {%s} $dmask]

    if {$asmMode} {echo -n ;}
    echo -n \t [format { font: %s, } [penum geos::FontID 
		     [value fetch ($addr).TA_font]]]
    echo -n {pointsize: }
    pfixed ($addr).TA_size 1 byte
    echo { weight:} [value fetch ($addr).TA_fontWeight]%

    if {$asmMode} {echo -n ;}
    echo -n \t { space padding: }
    pfixed ($addr).TA_spacePad 1 byte
    echo { width:} [value fetch ($addr).TA_fontWidth]%
    
    if {$asmMode} {echo -n ;}
    echo -n \t { text modes: }
    psetclear ($addr).TA_modeSet geos::TextMode
    echo

    if {$asmMode} {echo -n ;}
    echo -n \t { styles: }
    psetclear ($addr).TA_styleSet geos::TextStyle
    echo

    if {$asmMode} {echo -n ;}
    echo [format {\t  track kerning: %g%%} [expr [value fetch ($addr).TA_trackKern]/256*100 f]]
    
}]

##############################################################################
#				psetclear
##############################################################################
#
# SYNOPSIS:	Given two same-sized records, one after another, take the
#   	    	first record to be bits to set, and the second to be bits
#   	    	to clear and print them accordingly.
# PASS:		base	= address at which the "set" record is located. the
#			  "reset" record is at $base+[size $type]
#   	    	type	= name of the record in question
# CALLED BY:	pgs
# RETURN:	nothing
# SIDE EFFECTS:	...
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	10/2/91		Initial Revision
#
##############################################################################
[defsubr psetclear {base type}
{
    # convert type name to type token so we can play with it
	var tm [sym find type $type]
    # fetch bits to be set
	var set [value fetch $base $tm]
    # we need to do something different now to do address arithmetic
    	var baseaddr {((byte *)&$base)}
    # fetch bits to be cleared
	var reset [value fetch $baseaddr+[type size $tm] $tm]

    # print the bits to be set, if any
	var pref {set:}
	foreach i $set {
	    if {![null [index $i 0]] && [index $i 2]} {
		echo -n $pref [index $i 0]
		var pref {,}
	    }
	}

    # print the bits to be reset, if any
	var pref { reset:}
	foreach i $reset {
	    if {![null [index $i 0]] && [index $i 2]} {
		echo -n $pref [index $i 0]
		var pref {,}
	    }
	}
}]

##############################################################################
#				pfixed
##############################################################################
#
# SYNOPSIS:	Print a fixed-point number stored at a given address
# PASS:		addr	= where the number is stored
#   	    	comma	= flag indicating what to print after the number:
#   	    	    	    0	")\n"
#   	    	    	    1	","
#   	    	    	    2	") "
#   	    	    	    3	"\n"
#   	    	    	other	""
#   	    	fractype= the type of data that makes up the fraction. This is
#   	    	    	  normally a word, but may also be "byte". The integer
#			  is always a word.
# CALLED BY:	pgs
# RETURN:	nothing
# SIDE EFFECTS:	...
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jim	10/2/91		Initial Revision
#
##############################################################################
[defsubr pfixed {addr comma {fractype word}}
{
    addr-preprocess $addr s o
    var frac [value fetch $s:$o [type $fractype]]
    [case $fractype in
    	byte {var fdiv 256 ioff 1}
	word {var fdiv 65536 ioff 2}]
    var intgr [value fetch $s:$o+$ioff [type short]]
    if {$intgr < 0} then {
	var normfrac [expr $intgr-$frac/$fdiv float]
    } else {
        var normfrac [expr $intgr+$frac/$fdiv float]
    }
    echo -n [format {%.4f} $normfrac]
    [case $comma in
     0 {echo {)}}
     1 {echo -n {,}}
     2 {echo -n {) }}
     3 {echo {}}
     default {}]
}]

##############################################################################
#				pdfixed
##############################################################################
#
# SYNOPSIS:	Print a dwfixed-point number stored at a given address
# PASS:		addr	= where the number is stored
#   	    	comma	= flag indicating what to print after the number:
#   	    	    	    0	")\n"
#   	    	    	    1	","
#   	    	    	    2	") "
#   	    	    	    3	"\n"
#   	    	    	other	""
#   	    	fractype= the type of data that makes up the fraction. This is
#   	    	    	  normally a word, but may also be "dword". The integer
#			  is always a dword.
# CALLED BY:	pgs
# RETURN:	nothing
# SIDE EFFECTS:	...
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jim	10/2/91		Initial Revision
#
##############################################################################
[defsubr pdfixed {addr comma {fractype word}}
{
    addr-preprocess $addr s o
    var frac [value fetch $s:$o [type $fractype]]
    [case $fractype in
    	dword {var fdiv 4294967296.0 ioff 4}
	word {var fdiv 65536 ioff 2}]
    var intgr [value fetch $s:$o+$ioff [type long]]

    if {$intgr < 0} then {
	var normfrac [expr $intgr-$frac/$fdiv float]
    } else {
        var normfrac [expr $intgr+$frac/$fdiv float]
    }
    echo -n [format {%.6f} $normfrac]
    [case $comma in
     0 {echo {)}}
     1 {echo -n {,}}
     2 {echo -n {) }}
     3 {echo {}}
     default {}]
}]

##############################################################################
#				pcoord
##############################################################################
#
# SYNOPSIS:	print a single coordinate stored at the passed address, 
# PASS:		addr	= where the coordinate is located
#   	    	comma	= what to print after the coordinate:
#   	    	    	    0	")\n"
#   	    	    	    1	","
#   	    	    	    2	") "
#   	    	    	    3	"\n"
#   	    	    	    4	", "
#   	    	    	    5	"), ("
#   	    	    	other	""
#   	    	dtype	= coordinate type.  defaults to short
# CALLED BY:	pgs
# RETURN:	nothing
# SIDE EFFECTS:	
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	?	10/2/91		Initial Revision
#
##############################################################################
[defsubr pcoord {addr comma {dtype short}}
{
    echo -n [format {%d} [value fetch $addr [type $dtype]]]

    [case $comma in
     0 {echo {)}}
     1 {echo -n {,}}
     2 {echo -n {) }}
     3 {echo {}}
     4 {echo -n {, }}
     5 {echo -n {), (}}
     default {}]
}]

##############################################################################
#				pmonlist
##############################################################################
#
# SYNOPSIS:	Print out the contents of a moniker list.
# PASS:		seg 	= segment in which the moniker list is located
#		off 	= offset of the start of the list
# CALLED BY:	pvismon
# RETURN:	nothing
# SIDE EFFECTS:	all monikers in the list are printed.
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	?	10/3/91		Initial Revision
#
##############################################################################
[defsubr pmonlist {seg off}
{
	var sz [value fetch $seg:$off-2 word]
	global geos-release
	if {${geos-release} >= 2} {
	    var vmpref VisMoniker
    	} else {
    	    var vmpref VisualMoniker
    	}
	var listentrysize [type size [symbol find type ui::${vmpref}ListEntry]]
	[for {var sz [value fetch $seg:$off-2 word]}
		{$sz !=2}
		{var sz [expr $sz-$listentrysize]}
	{
		_print ui::${vmpref}ListEntry $seg:$off
		var off [expr $off+$listentrysize]
	}]
}]


[defcommand pvismon {{address {}} {textonly 0}} {object.vis}
{Usage:
    pvismon [<address>] [<textonly>]

Examples:
    "pvismon"	    	print the moniker at *ds:si
    "pvismon -i 1"	print a short description of the implied grab object.

Synopsis:
    Print a visual moniker structure at an absolute address.

Notes:
    * The address argument is the address to an object in the visual
      tree.  This defaults to *ds:si.

    * The textonly argument returns a shortened description of the
      structure.  To set it use something other than '0' for the
      second argument.

    * The special object flags may be used to specify <object>.  For a
      list of these flags, see pobj.

See also:
    pobjmon, pobject, vistree, gup, gentree, impliedgrab, systemobj.
}
{
    require addr-with-obj-flag user

    var address [addr-with-obj-flag $address]

    addr-preprocess $address seg off

    #
    # Print associated graphics string
    #
    var vmpref VisMoniker
    var type [value fetch $seg:$off.ui::VM_type ui::VisMonikerType]

    if {[field $type VMT_MONIKER_LIST] == 1} then {
	if {$textonly == 0} then {
	    echo {Moniker List:}
	    pmonlist $seg $off
	} else {
	    echo {*** Is Moniker List ***}
	}
    } elif {[field $type VMT_GSTRING] == 0} then {
	if {$textonly == 0} then {
	    _print ui::${vmpref} $seg:$off
	    echo -n {TEXT -- }
	    pstring &$seg:$off.ui::VM_data.ui::VMT_text
	    echo -n {MNEMONIC OFFSET -- }
	    pmnemonic $seg:$off.ui::VM_data
	} else {
	    pstring &$seg:$off.ui::VM_data.ui::VMT_text
	}
    } else {
	if {$textonly == 0} then {
	    _print ui::${vmpref} $seg:$off
	    _print ui::VisMonikerGString $seg:$off.ui::VM_data
	    pgs $seg:$off.ui::VM_data.ui::VMGS_gstring
	} else {
	    echo {*** Is GString ***}
	}
    }
}]

[defcommand pobjmon {{object {}} {textonly 0}} {object.gen}
{Usage:
    pobjmon [<object>] [<textonly>]

Examples:
    "pobjmon"	print the VisMoniker from the gentree object at *ds:si

Notes:
    * The <object> argument is the address of an object with a
      VisMoniker.  If none is specified then *ds:si is used.

    * The textonly argument returns a shortened description of the
      structure.  To set it use something other than '0' for the
      second argument.

    * The special object flags may be used to specify <object>.  For a
      list of these flags, see pobj.

See also:
    pvismon, pobject, vistree, gup, gentree, impliedgrab, systemobj.
}
{
    require addr-with-obj-flag user

    var object [addr-with-obj-flag $object]
    addr-preprocess $object seg off
    var gboffset [value fetch $seg:$off.ui::Gen_offset]
    var off [expr $off+$gboffset]

    #
    # Print VisMoniker
    #
    var off [value fetch $seg:$off.ui::GI_visMoniker word]
    if {$off == 0} then {
	echo *** No VisMoniker ***
    } else {
	pvismon *$seg:$off $textonly
    }
}]


##############################################################################
#				ppath
##############################################################################
#
# SYNOPSIS:	Print out the contents of a path.
# PASS:		address	= address of the Path structure
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	Don	9/25/92		Initial Revision
#
##############################################################################
[defcommand ppath {{path current} {gstate ^hdi}} lib_app_driver.graphics
{Usage:
    ppath [<current, docClip, winClip>] [<gstate>] 

Examples:
    "ppath"			print the current path of the GState in ^hdi
    "ppath docClip ^hdi"	print the doc clip path of the GState in ^hdi
    "ppath winClip ds"		print the window clip path of the GState in ds

Synopsis:
    Print the structure of a path.

Notes:
    * Unique abbreviations for the path to be printed are allowed.

See also:
}
{
	#
	# Parse the path to be printed
	#
	if {![string first $path current]} {
		var off GS_currentPath
	} elif {![string first $path docClip]} {
		var off GS_clipPath
	} elif {![string first $path winClip]} {
		var off GS_winClipPath
	} else {
		echo Possible paths are: current, docClip, winClip
		return
	}
	#
	# Simply print out the Path structure & the GString that follows it
	#
    	addr-preprocess $gstate:$off seg off
	var chunk [value fetch $seg:$off word]
	if {$chunk == 0} {
		echo *** No Path ***
	} else {
		var off [value fetch $seg:$chunk word]
		prpath $seg:$off
	}
}]

##############################################################################
#				prpath
##############################################################################
#
# SYNOPSIS:	Low-level routine to print out the contents of a path.
# PASS:		address	= address of the Path structure
# CALLED BY:	ppath, user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	Don	9/25/92		Initial Revision
#
##############################################################################
[defsubr prpath {address}
{
    	addr-preprocess $address seg off
	echo Path Header:
	_print Path $seg:$off
	pgs $seg:$off+[size Path]
}]
