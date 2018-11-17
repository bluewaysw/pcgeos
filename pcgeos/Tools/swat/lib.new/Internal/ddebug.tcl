##############################################################################
#
# 	Copyright (c) GeoWorks 1994 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	
# FILE: 	ddebug.tcl
# AUTHOR: 	Adam de Boor, Dec 20, 1994
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/20/94		Initial Revision
#
# DESCRIPTION:
#	Function(s) for dumping the debugging output stored in the
#   	ring buffer in the stub.
#
#	$Id: ddebug.tcl,v 1.2 95/01/31 18:17:49 adam Exp $
#
###############################################################################
##############################################################################
#				ddebug
##############################################################################
#
# SYNOPSIS:	Dump out the debugging ring-buffer in the stub
# PASS:		doinv	= non-zero to have things the debugging output flagged
#			  as being inverse show up in inverse. 0 to have them
#			  flagged with >< around them (useful when mailing
#			  output around)
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	stuff be printed.
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/6/94		Initial Revision
#
##############################################################################
[defsubr ddebug	{{doinv 1}}
{
    # The stub stores the pointer to the pointer to the ring buffer four bytes
    # before the place to which DOS will return control when the kernel
    # exits. This provides a convenient spot we can find easily, you see.
    # So first get the pointer to the pointer.
    var o [value fetch PSP:PSP_saveQuit.offset]
    var o [value fetch SwatSeg:$o-4 word]

    # $o is the address of the buffer pointer. fetch the pointer itself
    # into $end
    var end [value fetch SwatSeg:$o word]
    # the size of the buffer follows the pointer. fetch that, too
    var size [value fetch SwatSeg:$o+2 word]
    
    #
    # Make sure the stub actually has a ring buffer by looking for the standard
    # magic number following the buffer size.
    #
    if {[value fetch SwatSeg:$o+4 word] != 0xadeb} {
    	error {the stub doesn't appear to have been compiled with the debugging ring buffer in it}
    }
    #
    # See if the buffer has ever wrapped by checking the byte at the buffer
    # pointer for 0 (meaning it's never been written to).
    #
    var beg [expr $o+6]
    if {[value fetch SwatSeg:$end byte] == 0} {
    	#
	# Never wrapped, so just get the bytes from the start
	#
	var b [value fetch SwatSeg:$o+6
		[type make array [expr $end-$beg] [type byte]]]
    } else {
	var b [concat [value fetch SwatSeg:$end
			[type make array [expr $size-($end-$beg)] [type byte]]]
		      [value fetch SwatSeg:$beg
			[type make array [expr $end-$beg] [type byte]]]]
    }
    var inv 0
    foreach i $b {
    	if {$i & 0x80} {
	    var ninv 1 i [expr $i&0x7f]
    	} else {
	    var ninv 0
    	}
	if {$ninv != $inv} {
    	    if {$doinv} {
		winverse $ninv
    	    } elif {$ninv} {
	    	echo -n >
    	    } else {
	    	echo -n <
    	    }
	    var inv $ninv
    	}
	echo -n [format %c $i]
    }
    if {$doinv} {
	winverse 0
    }
    echo
}]
