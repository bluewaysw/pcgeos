##############################################################################
#
# 	Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	
# FILE: 	clipbrd.tcl
# AUTHOR: 	Adam de Boor, Apr  8, 1993
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/ 8/93		Initial Revision
#
# DESCRIPTION:
#	Functions for looking at stuff on the clipboard.
#
#	$Id: clipbrd.tcl,v 1.4.9.1 97/03/29 11:26:33 canavese Exp $
#
###############################################################################

[defcommand pnormal {args} lib_app_driver.clipboard
{Usage:
    pnormal [-v]

Examples:
    "pnormal -v"    Print out verbose info about the current normal transfer 
		    item.

Synopsis:
    Prints out information about the current "normal" transfer item on the
    clipboard.

Notes:
    * If you give the "-v" flag, this will print out the contents of the
      different transfer formats, rather than just an indication of their
      types.

See also:
    pquick, print-clipboard-item
}
{
    eval [concat print-clipboard-item [concat $args 
    	    	    	    [list
			     [value fetch ui::normalTransferItem.TII_vmFile]
			     [value fetch ui::normalTransferItem.TII_vmBlock]]]]
}]

[defcommand pquick {args} lib_app_driver.clipboard
{Usage:
    pquick [-v]

Examples:
    "pquick -v"     Print out verbose info about the current quick transfer 
		    item.

Synopsis:
    Prints out information about the current "quick" transfer item on the
    clipboard.

Notes:
    * If you give the "-v" flag, this will print out the contents of the
      different transfer formats, rather than just an indication of their
      types.

See also:
    pnormal, print-clipboard-item
}
{
    eval [concat print-clipboard-item [concat $args 
    	    	    	    [list
			     [value fetch ui::quickTransferItem.TII_vmFile]
			     [value fetch ui::quickTransferItem.TII_vmBlock]]]]
}]

[defcommand print-clipboard-item {args} lib_app_driver.clipboard
{Usage:
    print-clipboard-item [-v] <vmfile> <vmblock>
    print-clipboard-item [-v] <memhandle>
    print-clipboard-item [-v] <addr>

Examples:
    "print-clipboard-item bx"	Print out info about the transfer item whose
    	    	    	    	memory handle is in BX.

Synopsis:
    Prints out information about a transfer item.

Notes:
    * If you give the "-v" flag, this will print out the contents of the
      different transfer formats, rather than just an indication of their
      types.

    * The -v flag will not work unless the transfer item is in a VM file.

See also:
    pnormal, pquick.
}
{
    var verbose 0

    #
    # parse the various arguments we allow.
    #
    while {[string match [index $args 0] -*]} {
    	foreach i [range [explode [index $args 0]] 1 end] {
	    [case $i in
	     v {var verbose 1}
    	    ]
    	}
	var args [cdr $args]
    }
    
    if {[null $args]} {
    	error {Usage: print-clipboard-item [-v] (<vmfile> <vmblock> | <memblock>)}
    }
    #
    # First remaining argument can be either the address of a 
    # ClipboardItemHeader, the handle of a memory block holding such a beast,
    # or the handle of a VM file (HandleFile or HandleVM), which must be
    # followed by a vm block handle.
    #
    var a [addr-parse [index $args 0] 0]
    if {[index $a 0] == value} {
    	# must be either a VM or File or memory handle
    	var hid [index $a 1]

	var h [handle lookup $hid]
	if {[handle isvm $h] || [handle isfile $h]} {
	    if {[length $args] != 2} {
		error {Usage: print-clipboard-item [-v] <vmfile> <vmblock>}
	    }
	    var addr ^v$hid:[index $args 1]
	    var args [range $args 2 end]
	} else {
	    # must be memory handle, with ClipboardItemHeader lying at its
	    # start
	    var addr ^h$hid:0
	    var args [cdr $args]
	}

	var a [addr-preprocess $addr seg off]
    } else {
    	# given full address. parse it down to segment & offset
    	var addr [index $args 0]
	addr-preprocess [index $args 0] seg off
	var args [cdr $args]
    }

    var vmhan [value fetch kdata:[handle id [index $a 0]].geos::HM_owner]
    if {![handle isvm [handle lookup $vmhan]]} {
	# can't print out contents of scrap if not in VM file yet
	var verbose 0 vmhan 0
    } else {
    	var vmhan [value fetch kdata:$vmhan.geos::HVM_fileHandle]
    }

    if {![null $args]} {
    	echo Warning: extra arguments $args ignored
    }
    
    #
    # Now put out basic information about the thing.
    #
    var nformats [value fetch $seg:$off.ui::CIH_formatCount]
    echo -n [format {%d %s in "%s" scrap (%s) created by\n\t}
    	    	$nformats [pluralize format $nformats]
		[clipbrd-fetch-string $seg:$off.ui::CIH_name]
		$addr]
    require fmtoptr print
    [fmtoptr [value fetch $seg:$off.ui::CIH_sourceID.handle]
	     [value fetch $seg:$off.ui::CIH_sourceID.chunk]]
    echo
    #
    # Now print out the individual formats.
    #
    var cifType [symbol find type ui::ClipboardItemFormat]
    for {var i 0} {$i < $nformats} {var i [expr $i+1]} {
    	var h [value hstore [addr-parse {$seg:$off.ui::CIH_formats[$i]}]]
    	echo *** FORMAT $i (@$h)
	var format [value fetch {$seg:$off.ui::CIH_formats[$i]}]
    	if {[field [field $format CIFI_format] CIFID_manufacturer] == 0} {
	    var fmtname [type emap [field [field $format CIFI_format]
					  CIFID_type] $cifType]
    	} else {
	    var fmtname [field [field $format CIFI_format] CIFID_type]
    	}
	var e1 [field $format CIFI_extra1] e2 [field $format CIFI_extra2]
	[case $fmtname in
	    CIF_TEXT {
	    	echo [format {    text (%d wide by %d high)} $e1 $e2]

	    	if {$verbose} {
		    require harray-enum-raw hugearr.tcl
		    [harray-enum-raw $vmhan
		    	    	     [value fetch (^v$vmhan:(([field $format CIFI_vmChain]>>16)&0xffff)).text::TTBH_text.high]
				     clipbrd-print-chars
				     0
				     {}]
    	    	}
    	    }
	    CIF_GRAPHICS_STRING {
	    	echo [format {    gstring (%d wide by %d high)} $e1 $e2]
	    	if {$verbose} {
		    pgs ^v$vmhan:(([field $format CIFI_vmChain]>>16)&0xffff)
    	    	}
    	    }
	    CIF_FILES {
	    	echo [format {    files (on %xh [%s], %s remote)}
		    	$e1 [clipbrd-disk-name $e1]
			[if {$e2} {format {at least one}} {format none}]]
    	    	if {$verbose} {
		    var entSize [type size [symbol find type FileOperationInfoEntry]]
		    [for {var blk [expr ([field $format CIFI_vmChain]>>16)&0xffff]}
		         {$blk != 0}
			 {var blk [value fetch (^v$vmhan:$blk).FQTH_nextBlock]}
    	    	    {
		    	var nfiles [value fetch (^v$vmhan:$blk).FQTH_numFiles]
			var disk [value fetch (^v$vmhan:$blk).FQTH_diskHandle]
			echo [format {%d %s in %xh [%s] %s} $nfiles 
			      [pluralize file $nfiles] $disk 
			      [clipbrd-disk-name $disk]
			      [clipbrd-fetch-string (^v$vmhan:$blk).FQTH_pathname]]
    	    	    	[for {var i 0 ent [getvalue FQTH_files]}
			     {$i < $nfiles}
			     {var i [expr $i+1] ent [expr $ent+$entSize]}
    	    	    	{
			    var hn [value hstore [addr-parse {FileOperationInfoEntry (^v$vmhan:$blk):$ent}]]
			    echo @$hn [clipbrd-fetch-string (^v$vmhan:$blk):$ent.FOIE_name]
    	    	    	}]
    	    	    }]
		}
    	    }
	    default {
	    	echo [format {    %s, extra1 = %d (%04xh), extra2 = %d (%04xh)}
		    	$fmtname $e1 $e1 $e2 $e2]
    	    }
    	]
    }
}]

		
##############################################################################
#				clipbrd-print-chars
##############################################################################
#
# SYNOPSIS:	Print some characters from a huge-array.
# CALLED BY:	print-clipboard-item via harray-enum-raw
# PASS:		elNum	- Current character
#   	    	addr	- Address of character
#   	    	count   - Number of valid characters
#   	    	extra	- junk
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
[defsubr clipbrd-print-chars {elNum text count extra}
{
    var base 0

    echo -n {    }
    while {$count} {
	var ch [value fetch $text+$base [type char]]
	if {[string c $ch \\000]} {
	    if {[string m $ch {\\[\{\}\\]}]} {
		echo -n [format $ch]
	    } else {
		echo -n $ch
	    }
	}
        var count [expr $count-1]
	#var elNum [expr $elNum+1]
	var base  [expr $base+1]
    }
    echo
    return 0
}]



##############################################################################
#				clipbrd-fetch-string
##############################################################################
#
# SYNOPSIS:	Fetch a null-terminated string out of a character array.
# PASS:		addr	= address of the array
# CALLED BY:	print-clipboard-item
# RETURN:	the string
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/ 8/93		Initial Revision
#
##############################################################################
    	
[defsubr clipbrd-fetch-string {addr}
{
	
    return [mapconcat c [value fetch $addr] {
    	if {[string c $c \\000] == 0} {
	    break
	} else {
	    var c
    	}
    }]
}]

##############################################################################
#				clipbrd-disk-name
##############################################################################
#
# SYNOPSIS:	Fetch the name for a disk handle
# PASS:		disk	= disk handle or StandardPath constant
# CALLED BY:	print-clipboard-item
# RETURN:	the name, as a string
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	4/ 8/93		Initial Revision
#
##############################################################################
[defsubr clipbrd-disk-name {disk}
{
    if {$disk & 1} {
    	# standard path
	return [range [type emap $disk [symbol find type geos::StandardPath]]
	    	      3 end chars]
    } else {
    	require _disk_name fs
	return [_disk_name $disk]
    }
}]
