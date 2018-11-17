##############################################################################
#
# 	Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	
# FILE: 	stream.tcl
# AUTHOR: 	Adam de Boor, Aug 25, 1993
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	8/25/93		Initial Revision
#
# DESCRIPTION:
#	Functions for printing out stuff about streams.
#
#	$Id: stream.tcl,v 1.2.13.1 97/03/29 11:28:04 canavese Exp $
#
###############################################################################

##############################################################################
#				str-last-write
##############################################################################
#
# SYNOPSIS:	print out the last n bytes put into a stream
# PASS:		addr	= address of stream, or SerialPortData or
#			  ParallelPortData structure
#   	    	[n] 	= number of bytes to print. Defaults to 64
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	8/25/93		Initial Revision
#
##############################################################################
[defcommand str-last-write {addr {n 64}} {stream}
{Usage:
    str-last-write <stream> [<num-to-print>]

Examples:
    "str-last-write ds:0"	Prints the last 64 bytes written to the
				stream whose StreamData structure resides at
				ds:0
    "str-last-write lpt3"   	Prints the last 64 bytes written to LPT3
    "str-last-write com3 20"	Prints the last 20 bytes written to COM3
    "str-last-write bx 20"  	Prints the last 20 bytes written to the stream
				whose token is in BX.

Synopsis:
    Allows you to see the most-recent bytes written to a stream, with hooks
    to easily examine streams created by the serial and parallel drivers.

Notes:
    * The <stream> argument may be a stream token, one of the serial or
      parallel driver's internal port variables (named after the various
      ports, but in lower-case, not upper-case), or the full address of
      a StreamData structure.

    * If you ask for more bytes than are actually in the stream, you
      will just get all the bytes that are in the stream, so giving a second
      argument like 1,000,000 (without commas, of course), will show you
      everything, should you want it.

See also:
    str-last-read, str-info
}
{
    var a [addr-parse $addr 0]

    # Cope with receiving a stream token.
    #
    if {[index $a 0] == value} {
    	if {([index $a 1]&0xf000) >= 0xf000} {
	    # movable stream
	    var addr ^h[expr ([index $a 1]&0xfff<<4)]:0
    	} else {
	    # fixed stream
	    var addr [expr [index $a 1]&0xffff]:0
    	}
    }
    var a [addr-preprocess $addr s o]
    if {![null [index $a 2]]} {
    	# See if it's a serial or parallel driver structure and change
	# $a, $s, and $o to be the base of the output stream for the port
	# if it is.
	var name [type name [index $a 2] {} 0]
	[case $name in
	 *SerialPortData* {
	    var a [addr-preprocess *($s:$o).serial::SPD_outStream s o]
    	 }
	 *ParallelPortData* {
	    var a [addr-preprocess *($s:$o).parallel::PPD_stream s o]
	 }
    	]
    }
    var base [type size [symbol find type stream::StreamData]]
    var max [value fetch $s:$o.stream::SD_max]
    var end [value fetch $s:$o.stream::SD_writer.stream::SSD_ptr]

    # handle icky case of end being the start of the buffer, which means it's
    # actually $max instead, courtesy of modulo arithmetic...
    if {$end == $base} {
    	var end $max
    }

    var avail [value fetch $s:$o.stream::SD_reader.stream::SSD_sem.geos::Sem_value]
    if {$avail > 0} {
    	echo $avail [pluralize byte $avail] still waiting to be read
    } else {
    	echo all bytes written have been read
    }
    echo

    # compute offset to first byte to fetch
    var start [expr $end-$n]
    
    # if that's before the start of the buffer, wrap back to the end
    if {$start < $base} {
    	var start [expr $max-($base-$start)]
	
	if {$start < $end} {
	    # not $n bytes in the buffer, so just print the whole thing
    	    var start $end
    	}
    }
    
    # if end is after the end of the buffer, wrap back to the front
    if {$end > $max} {
    	var end [expr $start+($end-$max)]
	if {$end > $start} {
	    var end $start
    	}
    }
    
    # now fetch the bytes
    if {$start >= $end} {
    	# must do it in two parts
	var t1 [type make array [expr $max-$start] [type byte]]
	var t2 [type make array [expr $end-$base] [type byte]]
	var b [concat [value fetch $s:$o+$start $t1]
		      [value fetch $s:$o+$base $t2]]
    	type delete $t1
	type delete $t2
    } else {
    	var t [type make array [expr $end-$start] [type byte]]
	var b [value fetch $s:$o+$start $t]
	type delete $t
    }
    
    require fmt-bytes memory
    
    fmt-bytes $b $start [length $b] 0
}]
    
##############################################################################
#				str-last-read
##############################################################################
#
# SYNOPSIS:	print out the last n bytes read from a stream
# PASS:		addr	= address of stream, or SerialPortData or
#			  ParallelPortData structure
#   	    	[n] 	= number of bytes to print. Defaults to 64
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	8/25/93		Initial Revision
#
##############################################################################
[defcommand str-last-read {addr {n 64}} {stream}
{Usage:
    str-last-read <stream> [<num-to-print>]

Examples:
    "str-last-read ds:0"	Prints the last 64 bytes read to the
				stream whose StreamData structure resides at
				ds:0
    "str-last-read lpt3"   	Prints the last 64 bytes read to LPT3
    "str-last-read com3 20"	Prints the last 20 bytes read to COM3
    "str-last-read bx 20"  	Prints the last 20 bytes read to the stream
				whose token is in BX.

Synopsis:
    Allows you to see the most-recent bytes read to a stream, with hooks
    to easily examine streams created by the serial and parallel drivers.

Notes:
    * The <stream> argument may be a stream token, one of the serial or
      parallel driver's internal port variables (named after the various
      ports, but in lower-case, not upper-case), or the full address of
      a StreamData structure.

    * If you ask for more bytes than are actually in the stream, you
      will just get all the bytes that are in the stream, so giving a second
      argument like 1,000,000 (without commas, of course), will show you
      everything, should you want it.

See also:
    str-last-read, str-info
}
{
    var a [addr-parse $addr 0]

    # Cope with receiving a stream token.
    #
    if {[index $a 0] == value} {
    	if {([index $a 1]&0xf000) >= 0xf000} {
	    # movable stream
	    var addr ^h[expr ([index $a 1]&0xfff<<4)]:0
    	} else {
	    # fixed stream
	    var addr [expr [index $a 1]&0xffff]:0
    	}
    }
    var a [addr-preprocess $addr s o]
    if {![null [index $a 2]]} {
    	# See if it's a serial or parallel driver structure and change
	# $a, $s, and $o to be the base of the output stream for the port
	# if it is.
	var name [type name [index $a 2] {} 0]
	[case $name in
	 *SerialPortData* {
	    var a [addr-preprocess *($s:$o).serial::SPD_inStream s o]
    	 }
	 *ParallelPortData* {
	    error {parallel ports are not readable}
	 }
    	]
    }
    var base [type size [symbol find type stream::StreamData]]
    var max [value fetch $s:$o.stream::SD_max]
    var end [value fetch $s:$o.stream::SD_reader.stream::SSD_ptr]

    # handle icky case of end being the start of the buffer, which means it's
    # actually $max instead, courtesy of modulo arithmetic...
    if {$end == $base} {
    	var end $max
    }

    var avail [value fetch $s:$o.stream::SD_reader.stream::SSD_sem.geos::Sem_value]
    if {$avail > 0} {
    	echo $avail [pluralize byte $avail] still waiting to be read
    } else {
    	echo all bytes written have been read
    }
    echo

    # compute offset to first byte to fetch
    var start [expr $end-$n]
    
    # if that's before the start of the buffer, wrap back to the end
    if {$start < $base} {
    	var start [expr $max-($base-$start)]
	
	if {$start < $end} {
	    # not $n bytes in the buffer, so just print the whole thing
    	    var start $end
    	}
    }
    
    # if end is after the end of the buffer, wrap back to the front
    if {$end > $max} {
    	var end [expr $start+($end-$max)]
	if {$end > $start} {
	    var end $start
    	}
    }
    
    # now fetch the bytes
    if {$start >= $end} {
    	# must do it in two parts
	var t1 [type make array [expr $max-$start] [type byte]]
	var t2 [type make array [expr $end-$base] [type byte]]
	var b [concat [value fetch $s:$o+$start $t1]
		      [value fetch $s:$o+$base $t2]]
    	type delete $t1
	type delete $t2
    } else {
    	var t [type make array [expr $end-$start] [type byte]]
	var b [value fetch $s:$o+$start $t]
	type delete $t
    }
    
    require fmt-bytes memory
    
    fmt-bytes $b $start [length $b] 0
}]
    
