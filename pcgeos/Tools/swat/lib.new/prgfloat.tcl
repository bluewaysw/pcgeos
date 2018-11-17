######################################################################
#
#	Copyright (c) GeoWorks 1994 -- All Rights Reserved
# 
# PROJECT:	PC GEOS
# MODULE:	RegFloat, Swat library
# FILE:		prgfloat.tcl
#
# AUTHOR:	David Litwin
#
# COMMANDS:
#
# Scope	Name			Description
# -----	----			-----------
#   	prgfloat    	    	Print a RegFloat
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	dlitwin	12/14/94	Initial version.
#
# DESCRIPTION:
#	Misc stuff for debugging RegFloat library.
#
#	$Id: prgfloat.tcl,v 1.4.10.1 97/03/29 11:27:48 canavese Exp $
#
######################################################################


##############################################################################
#				format-rgfloat
##############################################################################
#
# SYNOPSIS:	Format a RegFloat number
# PASS:		highWord - high word of RegFloat
#               lowWord  -  low word of RegFloat
# CALLED BY:	utility
# RETURN:	str 	- String representing formatted number
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	dlitwin	12/14/94	Initial Revision
#
##############################################################################
[defsubr format-rgfloat {highWord lowWord}
{

    #
    # grab the relevant fields from the high word
    #
    var sgn [field $highWord RFE_SIGN_BIT]
    var exp [field $highWord RFE_EXPONENT]
    var highByte [field $highWord RFE_MANTISSA]

    #
    # add implied one to the mantissa.  Since the mantissa of the 
    # high byte is only 7 bits we can just add 80h to set the "1" bit.
    #
    var highByte [expr $highByte+80h]

    #
    # make the sign bit 1 or -1 according to its Boolean value
    # so we can later multiply by it
    #
    if {$sgn == 0} {
	var sgn 1
    } else {
	var sgn -1
    }

    #
    # Check for a zero exponent and return 0 as a special case
    # unbias the exponent if not zero.
    #
    if {$exp == 0} {
    	return {0}
    }
    var exp [expr $exp-[getvalue REG_FLOAT_EXP_BIAS]]

    #
    # add up the mantissa, multiply by 2^exp and multiply by the sign
    # for our result.
    #
    return [expr ((($lowWord/65536)+$highByte)/128)*2**$exp*$sgn float]
}]




######################################################################
#		format-rgfloat-mem
######################################################################
#
# SYNOPSIS:	Format a RegFloat that is in memory
# PASS:		address - address where RegFloat resides
# RETURN:	str 	- String representing formatted number
# SIDE EFFECTS: none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	dlitwin	12/16/94	Initial version.
#
######################################################################
[defsubr format-rgfloat-mem {flt}
{
    #
    # grab the high and low words to pass to format-rgfloat
    #
    var highWord  [field $flt RF_high]
    var lowWord   [field $flt RF_low]

    #
    # echo the formated result
    #
    return [format-rgfloat $highWord $lowWord]
}]



######################################################################
#		format-rgfloat-regs
######################################################################
#
# SYNOPSIS:	Format a RegFloat that is in a register pair
# PASS:		regpair - register pair where RegFloat resides
# RETURN:	str 	- String representing formatted number
# SIDE EFFECTS: none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	dlitwin	12/16/94	Initial version.
#
######################################################################
[defsubr format-rgfloat-regs {regpair}
{
    #
    # break up the string into the first two chars (first reg)
    # and rest of the string (second reg, should only be two chars)
    #
    var highReg [range $regpair 0 1 char]
    var lowReg [range $regpair 2 end char]

    #
    # cast the high register's value to the RegFloatExp 
    # type so format-rgfloat can use it
    #
    var expType [sym find type rgfloat::RegFloatExp]
    var highWord [cvtrecord $expType [read-reg $highReg]]

    #
    # the low register is simply numeric (no type info needed)
    #
    var lowWord [read-reg $lowReg]

    #
    # echo the formated result
    #
    return [format-rgfloat $highWord $lowWord]
}]



##############################################################################
#				prgfloat
##############################################################################
#
# SYNOPSIS:	Print a RegFloat number
# CALLED BY:	user
# PASS:		address	- Address or reg pair of a RegFloat
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	dlitwin	12/14/94	Initial Revision
#
##############################################################################
[defcommand prgfloat {{string {dxcx}}} lib_app_driver.rgfloat
{Usage:
    prgfloat [<reg-pair dxcx>]
            or
    prgfloat [<address ds:si>]

Examples:
    "prgfloat"	       print the RegFloat number dxcx
    "prgfloat axbp"    print the RegFloat number axbp
    "prgfloat ds:si"   print the RegFloat number at address ds:si

Synopsis:
    Print a RegFloat number

Notes:

See also:

}
{
    #
    # make sure RegFloat is loaded for the symbols we need.
    #
    if {[patient find rgfloat] == nil} {
	error {Unable to find rgfloat patient.}
    }

    #
    # get the symbol info for a RegFloat for the value fetch
    #
    var floatType [sym find type rgfloat::RegFloat]

    #
    # Catch an attempt to fetch the address.  If we fail, we are probably
    # dealing with the register pair version, so proceed accordingly. 
    #
    if {[catch {value fetch $string $floatType} flt] == 0} {
	echo [format-rgfloat-mem $flt]
    } else {
	echo [format-rgfloat-regs $string]
    }
}]










######################################################################
#		format-argfl-mem
######################################################################
#
# SYNOPSIS:	Format an AdjustedRegFloat that is in memory
# PASS:		address - address where the AdjustedRegFloat resides
# RETURN:	str 	- String representing formatted number
# SIDE EFFECTS: none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	dlitwin	12/16/94	Initial version.
#
######################################################################
[defsubr format-argfl-mem {flt}
{
    #
    # grab the high and low parts of the mantissa and the exponent
    #
    var exp [field $flt ARF_exponent]
    var highByte [field $flt ARF_mantissaH]
    var lowWord [field $flt ARF_mantissaL]

    #
    # add up the mantissa, multiply by 2^exp for our result.
    #
    return [expr ((($lowWord/65536)+$highByte)/128)*2**$exp float]
}]





######################################################################
#		format-argfl-regs
######################################################################
#
# SYNOPSIS:	Format an AdjustedRegFloat that is in a register pair
# PASS:		regpair - register pair where the AdjustedRegFloat resides
# RETURN:	str 	- String representing formatted number
# SIDE EFFECTS: none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	dlitwin	12/16/94	Initial version.
#
######################################################################
[defsubr format-argfl-regs {regpair}
{
    #
    # break up the string into the first two chars (first reg)
    # and rest of the string (second reg, should only be two chars)
    #
    var highReg [range $regpair 0 1 char]
    var lowReg [range $regpair 2 end char]

    #
    # grab exponent and high mantissa byte
    # using divides instead of caring about the symbols
    #
    var highWord [read-reg $highReg]
    var exp [expr [expr $highWord&0xFF00]/256]
    var highByte [expr $highWord&0x00FF]

    #
    # the low register is simply numeric (no type info needed)
    #
    var lowWord [read-reg $lowReg]

    #
    # add up the mantissa, multiply by 2^exp for our result.
    #
    return [expr (($lowWord/65536)+$highByte/128)*2**$exp float]
}]


##############################################################################
#				pargfl
##############################################################################
#
# SYNOPSIS:	Print an AdjustedRegFloat number
# CALLED BY:	user
# PASS:		address	- Address or reg pair of an AdjustedRegFloat
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	dlitwin	12/14/94	Initial Revision
#
##############################################################################
[defcommand pargfl {{string {dxcx}}} lib_app_driver.pargfl
{Usage:
    pargfl [<reg-pair dxcx>]
            or
    pargfl [<address ds:si>]

Examples:
    "pargfl"         print the AdjustedRegFloat number dxcx
    "pargfl axbp"    print the AdjustedRegFloat number axbp
    "pargfl ds:si"   print the AdjustedRegFloat number at address ds:si

Synopsis:
    Print an AdjustedRegFloat number

Notes:

See also:

}
{
    #
    # make sure rgfloat is loaded for the symbols we need.
    #
    if {[patient find rgfloat] == nil} {
	error {Unable to find rgfloat patient.}
    }

    #
    # get the symbol info for a RegFloat for the value fetch
    #
    var floatType [sym find type rgfloat::AdjustedRegFloat]

    #
    # Catch an attempt to fetch the address.  If we fail, we are probably
    # dealing with the register pair version, so proceed accordingly. 
    #
    if {[catch {value fetch $string $floatType} flt] == 0} {
	echo [format-argfl-mem $flt]
    } else {
	echo [format-argfl-regs $string]
    }
}]



