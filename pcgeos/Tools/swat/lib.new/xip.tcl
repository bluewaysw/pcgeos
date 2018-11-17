
##############################################################################
#
# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE: 	
# AUTHOR: 	jimmy lefkowitz
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jimmy	5/ 5/89		Initial Revision
#
# DESCRIPTION:	xip related stuff
#	
#   	Routines:
#   	    	    	xipwalk:       print out info on XIP handles
#
#	$Id: xip.tcl,v 1.5.6.1 97/03/29 11:27:25 canavese Exp $
#
###############################################################################

require print-handle-info heap

[defcmd xipwalk {args} {}
{Usage:
    xipwalk	    	print out info on all XIP resources
    xipwalk -p <num>  	print out info on all XIP resource in XIP page <num>
}
{
    var	xipPage -1

    # find the kernels table of XIP resources if its available
    if {[null [sym find any loaderVars]] || [null [sym find type FullXIPHeader]]} {
    	error {unable to locate XIP handle table}
    }
    var	xipHeader [value fetch loaderVars.KLV_xipHeader [type word]]
    var fxiph [value fetch $xipHeader:0 [sym find type FullXIPHeader]]
    var	xiptable [field $fxiph FXIPH_handleAddresses]
    var	lastXIPResource [field $fxiph FXIPH_lastXIPResource]
    var	cur [field $fxiph FXIPH_handleTableStart]
    var	pagesize 0

    if {[length $args] > 0 && [string m [index $args 0] -*]} {
	#
	# Examine the flags word for things we know and set vars
	# accordingly.
	#
        foreach i [explode [range [index $args 0] 1 end chars]] {
    	    [case $i in
    	    	p { 
    	    	    var xipPage [index $args 1]
    	    	    var args [range $args 1 end] 
    	    	}
    	    	
            ]
    	}
    }

    if {![null $args]} {
    	var xipPage $args
    }

    echo    [format {HANDLE PAGE SEGMENT  SIZE  OWNER     IDLE   OINFO TYPE}]
    echo    ---------------------------------------------------------
    
    #the format of the table is an array of dwords, one per XIP handle
    #the least significant word of the dword is the offset into the page
    #of the handle's segment address, and the most significant word is the
    #page number, the first dword corresponds to the first handle at the
    #start of the handle table, and they just go in order, on entry per entry
    #in the handle table up to the lastXIPResource handle found in the
    #FullXIPHeader
    while {$cur < $lastXIPResource} {
#    	var offset [value fetch $xipHeader:$xiptable [type word]]
    	var page [value fetch $xipHeader:$xiptable+2 [type word]]
    	var han [handle lookup $cur]

    	# some of the handles in this range have their own XIP windows as
    	# they contain FIXED memory, and so they don't show up as XIP resources
    	# because they don't behave like "normal" XIP resources as they
    	# never get mapped out by  ResourceCallInt
    	if {([null $args] || $xipPage == $page) && ([null $han] || [handle isxip $han])} {
    	    var	hm [value fetch kdata:$cur [sym find type HandleMem]]
	    if {[null $han]} {
		echo -n [format {%04x    %02d                 } $cur  $page]
		echo [field $hm HM_owner]
	    } else {
	        var segment [handle segment $han]
    	        var mysize [handle size $han]
    	        echo -n [format {%04x    %02d   %04x   %05d  } $cur  $page 
    	    	    	    	    	    	$segment  $mysize]

    	    # use stuff from heap.tcl to print out useful info on the handle
    	        print-handle-info $hm
    	        var	own [field $hm  HM_owner]
    	        var	ownHandle [handle lookup $own]
    	        var	other [field $hm HM_other]
    	        var	flags [field $hm HM_flags]
    	        heap-print-type $flags $cur $own $ownHandle $segment $other
    	    
    	    # keep track of the pagesize in case we need it
    	        var pagesize [expr $pagesize+$mysize]
	    }
    	}
    	var xiptable [expr $xiptable+[size dword]]
    	var cur [expr $cur+[size HandleMem]]
    }
    if {$xipPage != -1} {
    	echo	Total size for page $xipPage is $pagesize
    }
}]

[defcommand xipwatch {patient {turnoff all}} profile
{Usage:
    xipwatch <patient>
    xipwatch none [<patient>]

Examples:
    "xipwatch geos"	    Sets breakpoints to watch for code resources in the
			    kernel being read into RAM
    "xipwatch none" 	    Turn off all xipwatch breakpoints.
    "xipwatch none geos"    Turn off xipwatch breakpoints for just the kernel.

Synopsis:
    This command allows you to discover whether any of your code resources
    are being inadvertently brought into memory from the XIP image.

Notes:
    * The patient must be loaded for you to be able to set the breakpoint.

    * To catch all cases of a code resource being loaded, you will want to
      spawn the patient in question, run xipwatch for the patient, then
      continue the machine.

See also:
    spawn.
}
{
    global xipwatch_bpts

    if {$patient == none} {
    	if {$xipwatch_bpts != {}} {
	    var list [map bpt $xipwatch_bpts {
		if {$turnoff == all || [patient name [index $bpt 0]] == $turnoff} {
		    cbrk clear [index $bpt 1]
		} else {
		    list $bpt
		}
	    }]
	    var xipwatch_bpts [eval [concat concat $list]]
    	}
    } else {
    	var p [patient find $patient]
	if {[null $p]} {
	    error [format {xipwatch: %s: not a patient} $patient]
    	}
    	var b [cbrk geos::CopyDataFromXIPImage ds=^h[handle id [index [patient resources $p] 0]]]
	brk cmd $b [list xipwatch-check-handle $p]

	var xipwatch_bpts [concat [list [list $p $b]] $xipwatch_bpts]
    }
}]

[defsubr xipwatch-check-handle {p}
{
    var h [handle lookup [read-reg bx]]
    if {![null $h] && [handle patient $h] == $p && ([handle state $h] & 0x80)} {
    	#
    	# it's a known handle, owned by the patient we're worried about, and
	# it's a resource handle, which means it might hold a function. Look
	# for a procedure at the last possible address in the block. This
	# will find the last procedure, it's true, but will always find one
	# if the resource contains one.
	#
    	if {![null [symbol faddr proc ^hbx:0xffff]]} {
    	    # there's a procedure in the resource, so we want to warn the
	    # user. First find the caller that's locking the thing down
	    # by searching for a frame that's not in the kernel
    	    var kernel [patient find geos]
    	    [for {var f [frame top]}
		 {![null $f] && [frame patient $f] == $kernel}
		 {var f [frame next $f]}
    	    {}]
	    # figure the name of the function
	    if {[null $f]} {
	    	var caller ???
    	    } else {
	    	var caller [frame function $f]
    	    }
    	    echo Loading [symbol fullname [handle other $h]] from $caller
    	}
    }
    # don't stop, please
    return 0
}]

[defcmd print-xip-geodes {args} {}
{Usage:
	print-xip-geodes - prints the names of all geodes in the XIP image
}
{

#	Get a pointer to the array of GeodeNameTableEntry structs, and
#	the # entry structs there are.

	var xipHeader [value fetch loaderVars.KLV_xipHeader [type word]]
	var fxiph [value fetch $xipHeader:0 [sym find type FullXIPHeader]]
	var numGeodes [field $fxiph FXIPH_numGeodeNames]
	var arrayEntry [field $fxiph FXIPH_geodeNames]

	echo [format {OFFSET   COREBLOCK   FILENAME       FULLNAME}]
	echo ---------------------------------------------------------
	while {$numGeodes != 0} {
	    var cblock [value fetch $xipHeader:$arrayEntry.GNTE_coreblock [type word]]
	    var fname [get-tcl-string-from-memory $xipHeader $arrayEntry]
	    var fullname [get-tcl-string-from-memory $xipHeader [expr $arrayEntry+13]]
	    echo [format {%04xh    %04xh       %-14s %s} $arrayEntry $cblock $fname $fullname]
	    var arrayEntry [expr $arrayEntry+[size GeodeNameTableEntry]]
	    var numGeodes [expr $numGeodes-1]
	}
	echo [field $fxiph FXIPH_numGeodeNames] geodes in the image
}]

[defsubr get-tcl-string-from-memory {seg off} {
    global dbcs
    var type byte
    var	index 0
    catch {if $dbcs {
	var type word
     }}
    var c1 [value fetch $seg:$off+$index $type]
    while {$c1 != 0} {

    	var res [format {%s%c} $res $c1]
    	var index [expr $index+1]
        var c1 [value fetch $seg:$off+$index $type]
    }
    return $res
}]


