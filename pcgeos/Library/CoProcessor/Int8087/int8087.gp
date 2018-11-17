##############################################################################
#
#       Copyright (c) Geoworks 1991 -- All Rights Reserved
#
# PROJECT:     PC GEOS
# MODULE:      
# FILE:        int8087.gp
#
# AUTHOR:      jimmy
#
#
# Geode parameters for Float -- the floating point library
#
#       $Id: int8087.gp,v 1.1 97/04/04 17:48:43 newdeal Exp $
#
##############################################################################
#
# Specify the geode's permanent name
#
name int8087.lib

#
# Specify the type of geode
# It may only be loaded once.
#
type library, single

# entry point for library
entry Intel80X87LibraryEntry
#
# Import definitions from the kernel
#
library geos
library math
#
# Desktop-related things
#
longname        "Intel 8087 Library"
tokenchars      "IX87"
tokenid         0

#
# Specify alternate resource flags for anything non-standard
#
resource FixedCode     		shared, code, read-only, fixed
resource CommonCode    		shared, code, read-only
resource C_Float   		shared, code, read-only
resource DateAndTimeCode	shared, code, read-only
resource InitCode    		shared, code, read-only

#
# Define the interface for this library
#
# The list is organized thus:
#     Math and transcendental routines (please keep this list alphabetized)
#     Some stack routines
#     Date and time routines
#


# these routines are not copied over into the math library's relocation table
export Intel80X87Overflow
export Intel80X87Underflow
export Intel80X87SaveState
export Intel80X87RestoreState
export Intel80X87GetHardwareStackSize
export Intel80X87GetEnvSize
export Intel80X87DoHardwareInit


# THIS IS THE START OF THE ROUTINES THAT GET WRITTEN ONTO THE
# MATH LIBRARY'S RELOCATION TABLE, SO DON'T MESS WITH THESE...

export Intel80X87Init
export Intel80X87Exit
export Intel80X87SetStackSize

export Intel80X87Minus1
export Intel80X87MinusPoint5
export Intel80X87Zero
export Intel80X87Point5
export Intel80X87One
export Intel80X87Two
export Intel80X87Five
export Intel80X87Ten
export Intel80X87_3600
export Intel80X87_16384
export Intel80X87_86400

export Intel80X87Abs
export Intel80X87Add
export Intel80X87ArcCos
export Intel80X87ArcCosh
export Intel80X87ArcSin
export Intel80X87ArcSinh
export Intel80X87ArcTan
export Intel80X87ArcTan2
export Intel80X87ArcTanh
export Intel80X87CompAndDrop

export Intel80X87Comp
export Intel80X87CompESDI
export Intel80X87Cos
export Intel80X87Cosh
export Intel80X87Depth
export Intel80X87DIV
export Intel80X87Divide
export Intel80X87Divide2
export Intel80X87Divide10
export Intel80X87Drop

export Intel80X87Dup
export Intel80X87DwordToFloat
export Intel80X87Epsilon
export Intel80X87Eq0
export Intel80X87Exp
export Intel80X87Exponential
export Intel80X87FloatToAscii
export Intel80X87FloatToAscii_StdFormat
export Intel80X87Factorial
export Intel80X87Frac
export Intel80X87GetNumDigitsInIntegerPart

export Intel80X87Gt0
export Intel80X87Int
export Intel80X87IntFrac
export Intel80X87Inverse
export Intel80X87Lg
export Intel80X87Lg10
export Intel80X87Ln
export Intel80X87Ln1plusX
export Intel80X87Ln2
export Intel80X87Ln10

export Intel80X87Log
export Intel80X87Lt0
export Intel80X87Max
export Intel80X87Min
export Intel80X87Mod
export Intel80X87Multiply
export Intel80X87Multiply2
export Intel80X87Multiply10
export Intel80X87Negate
export Intel80X87Over

export Intel80X87Pi
export Intel80X87PiDiv2
export Intel80X87Pick
export Intel80X87PopNumber
export Intel80X87PushNumber
export Intel80X87Random
export Intel80X87Randomize
export Intel80X87RandomN
export Intel80X87Roll
export Intel80X87RollDown

export Intel80X87Rot
export Intel80X87Round
export Intel80X87Sin
export Intel80X87Sinh
export Intel80X87Sqr
export Intel80X87Sqrt
export Intel80X87Sqrt2
export Intel80X87AsciiToFloat
export Intel80X87Sub
export Intel80X87Swap

export Intel80X87Tan
export Intel80X87Tanh
export Intel80X8710ToTheX
export Intel80X87Trunc
export Intel80X87FloatToDword
export Intel80X87WordToFloat

export Intel80X87GetStackPointer
export Intel80X87SetStackPointer

#
# Date and time routines
#
export Intel80X87GetDateNumber
export Intel80X87DateNumberGetYear
export Intel80X87DateNumberGetMonthAndDay
export Intel80X87DateNumberGetWeekday
export Intel80X87GetTimeNumber
export Intel80X87StringGetDateNumber
export Intel80X87StringGetTimeNumber
export Intel80X87TimeNumberGetHour
export Intel80X87TimeNumberGetMinutes
export Intel80X87TimeNumberGetSeconds
export Intel80X87GetDaysInMonth
export Intel80X87Geos80ToIEEE64
export Intel80X87IEEE64ToGeos80
export Intel80X87Geos80ToIEEE32
export Intel80X87IEEE32ToGeos80
#
# C routines
#
export INTEL80X87ASCIITOFLOAT
export INTEL80X87FLOATTOASCII
export INTEL80X87FLOATTOASCII_STDFORMAT
export INTEL80X87FLOATIEEE64TOASCII_STDFORMAT
export INTEL80X87COMP
export INTEL80X87COMPANDDROP
export INTEL80X87COMPESDI
export INTEL80X87EQ0
export INTEL80X87LT0
export INTEL80X87GT0
export INTEL80X87PUSHNUMBER
export INTEL80X87POPNUMBER
export INTEL80X87ROUND
export INTEL80X87STRINGGETDATENUMBER
export INTEL80X87STRINGGETTIMENUMBER
export INTEL80X87INIT
export INTEL80X87EXIT
export INTEL80X87SETSTACKSIZE
export INTEL80X87GEOS80TOIEEE64
export INTEL80X87GEOS80TOIEEE32
export INTEL80X87IEEE64TOGEOS80
export INTEL80X87IEEE32TOGEOS80
export INTEL80X87WORDTOFLOAT
export INTEL80X87DWORDTOFLOAT
export INTEL80X87GETDAYSINMONTH
export INTEL80X87GETDATENUMBER
export INTEL80X87GETTIMENUMBER
export INTEL80X87DATENUMBERGETMONTHANDDAY
export INTEL80X87SETSTACKPOINTER
export INTEL80X87ROLL
export INTEL80X87ROLLDOWN
export INTEL80X87PICK
export INTEL80X87FSTSW
export INTEL80X87RANDOMIZE

