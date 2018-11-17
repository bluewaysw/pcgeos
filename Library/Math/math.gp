##############################################################################
#
#       Copyright (c) Geoworks 1991 -- All Rights Reserved
#
# PROJECT:     PC GEOS
# MODULE:      
# FILE:        float.gp
#
# AUTHOR:      Cheng
#
#
# Geode parameters for Float -- the floating point library
#
#       $Id: math.gp,v 1.1 97/04/05 01:23:35 newdeal Exp $
#
##############################################################################
#
# Specify the geode's permanent name
#
name math.lib

#
# Specify the type of geode (this is both a library, so other geodes can
# use the functions, and a driver, so it is allowed to access I/O ports).
# It may only be loaded once.
#
type library, single

#
# Define the library entry point
#
entry MathLibraryEntry

#
# Import definitions from the kernel
#
library geos
library ui
#
# Desktop-related things
#
longname        "Math Library"
tokenchars      "MATH"
tokenid         0

#
# Specify alternate resource flags for anything non-standard
#
nosort
resource FloatFixedCode     	shared, code, read-only, fixed
resource MathFixedCode		shared, code, read-only, fixed
resource InitCode           	preload, shared, read-only, code, discard-only
resource CommonCode		shared, code, read-only
resource C_Float		shared, code, read-only
resource FloatFormatCode	shared, code, read-only
resource FloatDateTime		shared, code, read-only
resource Init			shared, code, read-only
resource ThreadListCode		shared, code, read-only
resource FloatFormatStrings	lmem data read-only shared
resource ControlStrings		lmem data read-only shared
resource FloatFormatUI		object
resource MathClassStructures	shared, read-only, fixed
ifdef GP_FULL_EXECUTE_IN_PLACE
resource MathControlInfoXIP	read-only shared
endif

#
# Define the interface for this library
#
# The list is organized thus:
#     Math and transcendental routines (please keep this list alphabetized)
#     Some stack routines
#     Date and time routines
#
# THE FOLLOWING ROUTINES MUST BE IN THIS ORDER AND MUST BE FIRST
export FloatInit
export FloatExit
export FloatSetStackSizeFar as FloatSetStackSize
export FLOATMINUS1
export FLOATMINUSPOINT5
export FLOAT0
export FLOATPOINT5
export FLOAT1
export FLOAT2
export FLOAT5
export FLOAT10
export FLOAT3600
export FLOAT16384
export FLOAT86400
export FLOATABS
export FLOATADD
export FLOATARCCOS
export FLOATARCCOSH
export FLOATARCSIN
export FLOATARCSINH
export FLOATARCTAN
export FLOATARCTAN2
export FLOATARCTANH
export FloatCompAndDropFar as FloatCompAndDrop
export FloatCompFar as FloatComp
export FloatCompESDIFar as FloatCompESDI
export FLOATCOS
export FLOATCOSH
export FLOATDEPTH
export FLOATDIV
export FLOATDIVIDE
export FLOATDIVIDE2
export FLOATDIVIDE10
export FLOATDROP
export FLOATDUP
export FloatDwordToFloatFar as FloatDwordToFloat
export FLOATEPSILON
export FloatEq0Far as FloatEq0
export FLOATEXP
export FLOATEXPONENTIAL
export FloatFloatToAscii
export FloatFloatToAscii_StdFormat
export FLOATFACTORIAL
export FLOATFRAC
export FLOATGETNUMDIGITSININTEGERPART
export FloatGt0Far as FloatGt0
export FLOATINT
export FLOATINTFRAC
export FLOATINVERSE
export FLOATLG
export FLOATLG10
export FLOATLN
export FLOATLN1PLUSX
export FLOATLN2
export FLOATLN10
export FLOATLOG
export FloatLt0Far as FloatLt0
export FLOATMAX
export FLOATMIN
export FLOATMOD
export FLOATMULTIPLY
export FLOATMULTIPLY2
export FLOATMULTIPLY10
export FLOATNEGATE
export FLOATOVER
export FLOATPI
export FLOATPIDIV2
export FloatPickFar as FloatPick
export FloatPopNumberFar as FloatPopNumber
export FloatPushNumberFar as FloatPushNumber
export FLOATRANDOM
export FloatRandomizeFar as FloatRandomize
export FLOATRANDOMN
export FloatRollFar as FloatRoll
export FloatRollDownFar as FloatRollDown
export FLOATROT
export FloatRoundFar as FloatRound
export FLOATSIN
export FLOATSINH
export FLOATSQR
export FLOATSQRT
export FLOATSQRT2
export FloatAsciiToFloat
export FLOATSUB
export FLOATSWAP
export FLOATTAN
export FLOATTANH
export FLOAT10TOTHEX
export FLOATTRUNC
export FLOATFLOATTODWORD
export FloatWordToFloatFar as FloatWordToFloat
export FLOATGETSTACKPOINTER
export FloatSetStackPointer
#
# Date and time routines
#
export FloatGetDateNumber
export FLOATDATENUMBERGETYEAR
export FloatDateNumberGetMonthAndDay
export FLOATDATENUMBERGETWEEKDAY
export FloatGetTimeNumber
export FloatStringGetDateNumber
export FloatStringGetTimeNumber
export FLOATTIMENUMBERGETHOUR
export FLOATTIMENUMBERGETMINUTES
export FLOATTIMENUMBERGETSECONDS
export FloatGetDaysInMonth
export FloatGeos80ToIEEE64Far as FloatGeos80ToIEEE64
export FloatIEEE64ToGeos80Far as FloatIEEE64ToGeos80
export FloatGeos80ToIEEE32
export FloatIEEE32ToGeos80

# C routines
#
#
#
export FLOATASCIITOFLOAT
export FLOATFLOATTOASCII_OLD
export FLOATFLOATTOASCII_STDFORMAT
export FLOATFLOATIEEE64TOASCII_STDFORMAT
export FLOATCOMP
export FLOATCOMPANDDROP
export FLOATCOMPESDI
export FLOATEQ0
export FLOATLT0
export FLOATGT0
export FLOATPUSHNUMBER
export FLOATPOPNUMBER
export FLOATROUND
export FLOATSTRINGGETDATENUMBER
export FLOATSTRINGGETTIMENUMBER
export FLOATINIT
export FLOATEXIT
export FLOATSETSTACKSIZE
export FLOATGEOS80TOIEEE64
export FLOATGEOS80TOIEEE32
export FLOATIEEE64TOGEOS80
export FLOATIEEE32TOGEOS80
export FLOATWORDTOFLOAT
export FLOATDWORDTOFLOAT
export FLOATGETDAYSINMONTH
export FLOATGETDATENUMBER
export FLOATGETTIMENUMBER
export FLOATDATENUMBERGETMONTHANDDAY
export FLOATSETSTACKPOINTER
export FLOATROLL
export FLOATROLLDOWN
export FLOATPICK
export FloatFSTSW
export FLOATRANDOMIZE
#THIS IS THE END OF THE LIST OF ROUTINES THAT MUST BE IN THE GIVEN ORDER

export FloatGenerateFormatStr
export FloatFormatNumber
export FLOATFORMATNUMBER
#export FormatDisplayNumber

export FloatFormatInit
export FloatFormatGetFormatParamsWithListEntry
export FloatFormatInitFormatList
export FloatFormatProcessFormatSelected
export FloatFormatInvokeUserDefDB
export FloatFormatUserDefOK
export FloatFormatGetFormatTokenWithName
export FloatFormatGetFormatParamsWithToken
export FloatFormatDelete
export FloatFormatIsFormatTheSame?
export FloatFormatAddFormat
export FLOATFORMATINIT
export FLOATFORMATGETFORMATPARAMSWITHLISTENTRY
export FLOATFORMATINITFORMATLIST
export FLOATFORMATPROCESSFORMATSELECTED
export FLOATFORMATINVOKEUSERDEFDB
export FLOATFORMATUSERDEFOK
export FLOATFORMATGETFORMATTOKENWITHNAME
export FLOATFORMATGETFORMATPARAMSWITHTOKEN
export FLOATFORMATDELETE
export FLOATFORMATISFORMATTHESAME?
export FLOATFORMATADDFORMAT

#SPECIAL ROUTINES NEEDED BY THE HARDWARE LIBRARIES
export FloatPushNumber as FloatPushNumberInternal
export FloatPopNumber as FloatPopNumberInternal
export FloatSetStackSizeInternal
export FloatPick as FloatPickInternal
export FloatRandomInternal
export FloatRandomizeInternal
export FloatRandomNInternal
export FloatRollInternal
export FloatRollDownInternal
export FloatFloatToAscii as FloatFloatToAsciiInternal
export FloatFloatToAscii_StdFormatInternal
export FloatAsciiToFloatInternal
export FloatGetNumDigitsInIntegerPart as FloatGetNumDigitsInIntegerPartInternal
export FloatCompPtr
export FloatGetStackDepth
export FloatSetStackDepth
export FloatGetSoftwareStackHandle
export FloatHardwareExit
export FloatHardwareEnter
export FloatHardwareInit
export FloatHardwareLeave
export GetDateNumber
export DateNumberGetYear
export DateNumberGetMonthAndDay
export DateNumberGetWeekday
export GetTimeNumber
export TimeNumberGetHour
export TimeNumberGetMinutes
export TimeNumberGetSeconds
export StringGetDateNumber
export StringGetTimeNumber
export GetDaysInMonth

export FloatFormatClass

incminor
export FloatLocalizeFormats

incminor
publish FLOATFLOATTOASCII

#
# XIP-enabled
#

incminor GetModifiedFormat
export FloatFormatGetModifiedFormat
export FLOATFORMATGETMODIFIEDFORMAT
