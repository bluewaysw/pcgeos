##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	filehan.tcl
# AUTHOR: 	Cheng, Apr 25 89
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	fwalk	    	    	display file handles
#   	fhandle	    	    	print out an OS/90 file handle
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	Cheng	4/25/89		Initial version
#
# DESCRIPTION:
#	Functions for examining file structures
#
#	$Id: filehandle.tcl,v 3.3 90/05/01 20:44:15 brianc Exp Locker: steve $
#
###############################################################################

[defcommand fwalk {args} kernel|file
{Print out the status of all blocks on the heap.
The letters in the 'Flags' column mean the following:
    RW		deny RW
    R		deny R
    W		deny W
    N		deny none
    rw		access RW
    r		access R
    w		access RW}

{
    var owner nil fast 0 ptrs 0 echeck 0 totsz 0

    require read-sft dos

    if {[length $args] > 0} {
	#
	# Gave an owner whose handles are to be printed. Figure out if it's
	# a handle ID or a patient name and set owner to the decimal equiv
	# of the handle ID.
	#
	var h [handle lookup [index $args 0]]
	if {![null $h] && $h != 0} {
	    var owner [handle id $h]
	} else {
	    var owner [handle id
			[index [patient resources
					[patient find [index $args 0]]] 0]]
	}
    }

    #
    # Read in the SFT so we can find the files to which the things belong
    #
    var sft [read-sft]

    #
    # Print out the banner
    #
    echo {Handle  SFN  Drive  Name           Owner    Other   Flags     Sem}
    echo {-----------------------------------------------------------------}

    #
    # Set up initial conditions.
    #
    var start [value fetch fileList]
    var nextStruc [value fetch kdata:$start HandleFile]

    for {var cur $start} {$cur != 0} {var cur $next} {

    	var val $nextStruc
	var next [field $val HF_next]
	[var nextStruc [value fetch kdata:$next HandleFile]
	     own [field $val HF_owner]]

	if {[null $owner] || $own == $owner} {
	    [var sfn [field $val HF_sfn]
	     drive [field $val HF_drive]
	     flags [field $val HF_accessFlags]
	     sem [field $val HF_semaphore]
	     oi [field $val HF_otherInfo]]

    	    var sftent [index $sft $sfn]
	    echo -n [format {%-8.04x%-4.02x  %2d    %-15s}
		$cur $sfn $drive 
		[mapconcat c [range [field $sftent SFTE_name] 0 7] {var c}].[mapconcat c [range [field $sftent SFTE_name] 8 end] {var c}]]
		    	    	     

	    echo -n [format {%-9s}
		      [patient name [handle patient [handle lookup $own]]]]
    	    if {$oi != 0 && [value fetch kdata:$oi.HG_type] == 0xfc} {
	    	echo -n {V}
	    } else {
	    	echo -n { }
	    }
    	    if {$oi != 0} {
    	    	echo -n [format {%04x   } $oi]
    	    } else {
	    	echo -n { --    }
    	    }

	    var excludes [field $flags FFAF_EXCLUDE]
	    var access [field $flags FFAF_MODE]
	    if {$excludes == 1} {echo -n {RW}}
	    if {$excludes == 2} {echo -n { W}}
	    if {$excludes == 3} {echo -n { R}}
	    if {$excludes == 4} {echo -n { N}}
	    echo -n /
	    if {[field $flags FFAF_EXCLUSIVE]} {
		echo -n {E}
	    } else {
		echo -n { }
	    }
	    if {[field $flags FFAF_OVERRIDE]} {
		echo -n {O}
	    } else {
		echo -n { }
	    }
	    echo -n /
	    if {$access == 0} {echo -n {r }}
	    if {$access == 1} {echo -n {w }}
	    if {$access == 2} {echo -n {rw}}

	    echo [format {  %1d} $sem]
	}
    }
}]

[defcommand fhandle {num} kernel|output|file
{Print out a handle. Single argument NUM is the handle's ID number (if you
want it in hex, you'll have to indicate that with the usual radix specifiers
at your disposal)}
{
    var	val [value fetch kdata:$num HandleFile]

    echo [format {SFN: %#x  signature: %#x  drive: %#x  unit: ?  cluster: ?}
          [field $val HF_sfn] [field $val HF_handleSig]
	  [field $val HF_drive]]
    var owner [field $val HF_owner]
    var owneraddr [value fetch kdata:$owner.HM_addr]
    echo -n [format {owner: %#x (} $owner]
    if {$owner != 0} {
    	if {$owner == 0x10} {
    	    echo -n kernel
	} else {
        var ownername [value fetch $owneraddr:0.GH_geodeName]
    	    foreach i $ownername {
    	 	echo -n [format %s $i]
    	    }
	}
    } else {
	echo -n FREE
    }
    echo -n {)  }
    var next [field $val HF_next]
    echo -n [format {next: %#x  } $next]

    echo -n {open for: }
    var flags [field $val HF_accessFlags]
    var access [field $flags FFAF_MODE]
    if {$access == 0} {echo -n {Access_R, }}
    if {$access == 1} {echo -n {Access_W, }}
    if {$access == 2} {echo -n {Access_RW, }}
    var excludes [field $flags FFAF_EXCLUDE]
    if {$excludes == 1} {echo -n {Deny_RW, }}
    if {$excludes == 2} {echo -n {Deny_W, }}
    if {$excludes == 3} {echo -n {Deny_R, }}
    if {$excludes == 4} {echo -n {Deny_none, }}
    if {[field $flags FFAF_EXCLUSIVE]} {
	echo -n {Exclusive, }
    }
    if {[field $flags FFAF_OVERRIDE]} {
	echo {Override}
    } else {
	echo
    }
}]
