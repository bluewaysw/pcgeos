##############################################################################
#
# 	(c) Copyright Geoworks 1994.  All rights reserved.
#			GEOWORKS CONFIDENTIAL
#
# PROJECT:	
# MODULE:	swat
# FILE: 	bits.tcl
# AUTHOR: 	Steve Kertes, Aug  4, 1994
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	SK	8/ 4/94   	Initial Revision
#
# DESCRIPTION:
#
#	examine memory in binary (byte, word, dword chunks)
#
#	$Id: bits.tcl,v 1.7.6.1 97/03/29 11:27:15 canavese Exp $
#
###############################################################################
##############################################################################
#	bits
##############################################################################
#
# SYNOPSIS:	dump memory as bits, and hex
# PASS:		[addr]	= address from which to start dumping
#   	    	[num]	= number of units to dump
#		[type]	= bytes, words, dwords (b,w,d)
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	${lastAddr} is set to last address accessed
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       SK 	8/ 4/94   	Initial Revision
#
##############################################################################
[defcommand    bits {{addr nil} {num 16} {disp b}} top.memory
{Usage:
    bits [<address>] [<length>] [<type>]

Examples:
    "bits"              lists 16 bytes worth of bits at ds:si
    "bits ds:di 8"      lists 8 bytes worth of bits at ds:di
    "bits ds:di 24 w"   lists 24 words worth of bits at ds:di

Synopsis:
    Examine memory as a dump of bits in sets of 8, 16, or 32 (byte,word,dword)

Notes:
    * The address argument is the address to examine.  If not
      specified, the address after the last examined memory location
      is used.  If no address has been examined then ds:si is used for
      the address.

    * The length argument is the number of units to examine.  It 
      defaults to 16.

    * They type argument is bytes, words or dwords.  It defaults to bytes.

    * Pressing return after this command continues the list.

See also:
    bytes, words, dwords, imem, assign.

}
{
#
# get the address to start from
#
	addr-preprocess [get-address $addr ds:si] seg base
#
# find out what type of units we are going to use (byte, word, dword)
#
	[case [range $disp 0 0 chars] in
		b {
			var unit_type byte
		}
		w {
			var unit_type word
		}
		d {
			var unit_type dword
		}
	]
#
# fetch the data
#
#echo	getting data
var thedata [value fetch $seg:$base [type make array $num [type $unit_type]]]

#
# format and print the data
# 
#echo	printing data
	fmt-bits-$unit_type $thedata $base $num 0

#
# set stuff up for a repeated command (pressing return)
#
#echo	setting up for repeat
	var end $seg:$base+[expr $num*[size $unit_type]]
	set-address $end-[size $unit_type]
	set-repeat [format {$0 {%s} $2 $3} $end]
}]
##############################################################################
#	fmt-bits-byte
##############################################################################
#
# SYNOPSIS:	
# PASS:		
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       SK 	8/ 4/94   	Initial Revision
#
##############################################################################
[defsubr    fmt-bits-byte {bytes base num fmtoff} {
#	fmt-bytes $bytes $base $num $fmtoff
#
# put up the header line
#
    echo [format {%*sAddr:  +0          +1          +2          +3} $fmtoff {}]
#
# output rows of 4 bytes, in binary and hex
#
	[for {var start $base}
	     {$num > 0} {var start [expr $start+[size byte]*4]} {

		echo -n [format {%04xh: } $start]
#
# write the binary part
#
		var tnum $num
		for {var i 0} {$i < 4 && $tnum > 0} {var i [expr $i+1]} {
			echo -n [format {%s   } [hex-to-bin [format {%02x} [index $bytes [expr $i+($start-$base)/[size byte]]]]]]
			var tnum [expr $tnum-1]
		}
#
# add spaces if the full line was not filled
#
		for {var j $i} {$j < 4 } { var j [expr $j+1]} {
			echo -n [format {            }]
		}
#
# write the hex part
#
		echo -n [format {     }]
		var tnum $num
		for {var i 0} {$i < 4 && $tnum > 0} {var i [expr $i+1]} {
			echo -n [format {%02x } [index $bytes [expr $i+($start-$base)/[size byte]]]]
			var tnum [expr $tnum-1]
		}

		echo
		var num [expr $num-4]
	}]
}]

##############################################################################
#	fmt-bits-word
##############################################################################
#
# SYNOPSIS:	
# PASS:		
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       SK 	8/ 4/94   	Initial Revision
#
##############################################################################
[defsubr    fmt-bits-word {words base num fmtoff} {
#fmt-words $words $base $num $fmtoff
#
# put up the header line
#
    echo [format {%*sAddr:  +0                    +2          } $fmtoff {}]
#
# output rows of 2 words, in binary and hex
#
	[for {var start $base}
	     {$num > 0} {var start [expr $start+[size word]*2]} {

		echo -n [format {%04xh: } $start]
#
# write the binary part
#
		var tnum $num
		for {var i 0} {$i < 2 && $tnum > 0} {var i [expr $i+1]} {
			echo -n [format {%s   } [hex-to-bin [format {%04x} [index $words [expr $i+($start-$base)/[size word]]]]]]
			var tnum [expr $tnum-1]
		}
#
# add spaces if the full line was not filled
#
		for {var j $i} {$j < 2 } { var j [expr $j+1]} {
			echo -n [format {                      }]
		}
#
# write the hex part
#
		echo -n [format {         }]
		var tnum $num
		for {var i 0} {$i < 2 && $tnum > 0} {var i [expr $i+1]} {
			echo -n [format {%04x } [index $words [expr $i+($start-$base)/[size word]]]]
			var tnum [expr $tnum-1]
		}

		echo
		var num [expr $num-2]
	}]
}]


##############################################################################
#	fmt-bits-dword
##############################################################################
#
# SYNOPSIS:	
# PASS:		
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       SK 	8/ 4/94   	Initial Revision
#
##############################################################################
[defsubr    fmt-bits-dword {dwords base num fmtoff} {
#fmt-dwords $dwords $base $num $fmtoff
#
# put up the header line
#
    echo [format {%*sAddr:} $fmtoff {}]
#
# output rows of 1 dword, in binary and hex
#
	[for {var start $base}
	     {$num > 0} {var start [expr $start+[size dword]*1]} {

		echo -n [format {%04xh: } $start]
#
# write the binary part
#
		var tnum $num
		for {var i 0} {$i < 1 && $tnum > 0} {var i [expr $i+1]} {
			echo -n [format {%s   } [hex-to-bin [format {%08x} [index $dwords [expr $i+($start-$base)/[size dword]]]]]]
			var tnum [expr $tnum-1]
		}
#
# add spaces if the full line was not filled
#
		for {var j $i} {$j < 1 } { var j [expr $j+1]} {
			echo -n [format {                      }]
		}
#
# write the hex part
#
		echo -n [format {           }]
		var tnum $num
		for {var i 0} {$i < 1 && $tnum > 0} {var i [expr $i+1]} {
			echo -n [format {%08x } [index $dwords [expr $i+($start-$base)/[size dword]]]]
			var tnum [expr $tnum-1]
		}

		echo
		var num [expr $num-1]
	}]
}]


##############################################################################
#	hex-to-bin
##############################################################################
#
# SYNOPSIS:	convert hex to binary
# PASS:		hex string
# CALLED BY:	
# RETURN:	binary string, nibbles spaced
# SIDE EFFECTS:	none
# NOTES:	illegal digits are replaced with ****
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       SK 	8/ 4/94   	Initial Revision
#
##############################################################################
[defcommand    hex-to-bin {hex_number} top.print
{Usage:
    hex-to-bin <hex-digits>

Examples:
    "hex-to-bin 45"  returns "0100 0101"
    "hex-to-bin 45X" returns "0100 0101 ****"

Synopsis:
    Converts hex digits to binary.

See also:
    hex-to-bin-reverse
}
{		var binary_number {}
	for {var i 0} {$i < [length $hex_number chars]} {var i [expr $i+1]} {
		var nibble ****
		[case [range $hex_number $i $i chars] in
			0 { var nibble 0000 }
			1 { var nibble 0001 }
			2 { var nibble 0010 }
			3 { var nibble 0011 }
			4 { var nibble 0100 }
			5 { var nibble 0101 }
			6 { var nibble 0110 }
			7 { var nibble 0111 }
			8 { var nibble 1000 }
			9 { var nibble 1001 }
			A { var nibble 1010 }
			B { var nibble 1011 }
			C { var nibble 1100 }
			D { var nibble 1101 }
			E { var nibble 1110 }
			F { var nibble 1111 }
			a { var nibble 1010 }
			b { var nibble 1011 }
			c { var nibble 1100 }
			d { var nibble 1101 }
			e { var nibble 1110 }
			f { var nibble 1111 }
		]
		var binary_number [concat $binary_number $nibble]
	}
		
	return $binary_number
}]
##############################################################################
#	hex-to-bin-reverse
##############################################################################
#
# SYNOPSIS:	convert hex to binary, but reverse bits in each byte
# PASS:		hex string
# CALLED BY:	
# RETURN:	binary string, nibbles spaced, bits in each byte reversed
# SIDE EFFECTS:	none
# NOTES:	illegal digits are replaced with ****
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       SK 	8/ 4/94   	Initial Revision
#
##############################################################################
[defcommand    hex-to-bin-reverse {hex_number} top.print
{Usage:
    hex-to-bin-reverse <hex-digits>

Examples:
    "hex-to-bin-reverse 45"   returns "1010 0010"
    "hex-to-bin-reverse 456F" returns "1010 0010 1111 0110"
    "hex-to-bin-reverse 456"  returns "1010 0010 **** 0110"
Synopsis:
    Converts hex digits to binary, and reverses the bits in each byte worth.

See also:
    hex-to-bin
}
{
		var binary_number {}
	for {var i 0} {$i < [length $hex_number chars]} {var i [expr $i+2]} {
		var reversed_bits {}
	   for {var j 0} {$j < 2} {var j [expr $j+1]} {
		var nibble ****
		[case [range $hex_number [expr $i+$j] [expr $i+$j] chars] in
			0 { var nibble 0000 }
			1 { var nibble 1000 }
			2 { var nibble 0100 }
			3 { var nibble 1100 }
			4 { var nibble 0010 }
			5 { var nibble 1010 }
			6 { var nibble 0110 }
			7 { var nibble 1110 }
			8 { var nibble 0001 }
			9 { var nibble 1001 }
			A { var nibble 0101 }
			B { var nibble 1101 }
			C { var nibble 0011 }
			D { var nibble 1011 }
			E { var nibble 0111 }
			F { var nibble 1111 }
			a { var nibble 0101 }
			b { var nibble 1101 }
			c { var nibble 0011 }
			d { var nibble 1011 }
			e { var nibble 0111 }
			f { var nibble 1111 }
		]
		var reversed_bits [concat $nibble $reversed_bits]
	   }
	   var binary_number [concat $binary_number $reversed_bits]
	}
		
	return $binary_number
}]
##############################################################################
#	bin
##############################################################################
#
# SYNOPSIS:	prints stuff in binary
# PASS:		[number]	= number to print
#		[nibbles]	= field width to print
# CALLED BY:	
# RETURN:	binary string
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       SK 	8/ 5/94   	Initial Revision
#
##############################################################################
[defcommand  bin {expr {width {}}} top.print
{Usage:
    bin <expression> [<field width>]

Examples:
    "bin 5"	returns "0101"
    "bin 10h"	returns "0001 0000"
    "bin 10h 3" returns "0000 0001 0000"
    "bin ax"	returns ax in binary

Synopsis:
    Prints expressions in binary.

Notes:
    * The field width is in nibbles.

    * The default field width is the minium number of nibbles to
      display the number.

See also:
    bits.

}
{
    var number [index [addr-parse $expr 0] 1]
    var field_stuff %0${width}x
    return	[hex-to-bin [format $field_stuff $number]]
}]
