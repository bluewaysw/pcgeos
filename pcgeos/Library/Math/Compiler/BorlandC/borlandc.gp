##############################################################################
#
#       Copyright (c) Geoworks 1991 -- All Rights Reserved
#
# PROJECT:     PC GEOS
# MODULE:      
# FILE:        borlandc.gp
#
# AUTHOR:      jimmy
#
#
# Geode parameters for borlandc the interrupt driven floating point support
# as implemented by borlandc and micrsooftc
#
#       $Id: borlandc.gp,v 1.1 97/04/05 01:22:48 newdeal Exp $ 
#
##############################################################################

#
# Specify the geode's permanent name
#
name borlandc.lib

#
# Specify the type of geode (this is both a library, so other geodes can
# use the functions, and a driver, so it is allowed to access I/O ports).
# It may only be loaded once.
#
type library, single

#
# Define the library entry point
#
entry BorlandcLibraryEntry

#
# Import definitions from the kernel
#
library geos
library ui
library math
#
# Desktop-related things
#
longname        "Interrupt Float Library"
tokenchars      "IFL0"
tokenid         0

#
# Specify alternate resource flags for anything non-standard
#
nosort
resource FloatInterruptCode	shared, code, read-only, fixed
resource InterruptInitCode	preload, shared, code, read-only, discard-only
resource FloatMovableCode	code read-only shared
#
#

export SIN
export COS
export TAN
export COSH
export SINH
export TANH
export ATAN
export ACOS
export ASIN
export ATANH
export ASINH
export ACOSH
export LOG
export LN
export SQRT
export F_FTOL@

incminor NDO2000BorlandCMath
export POW

# New as of 3/3/99
incminor JavaScriptBorlandCMath
export	FLOOR
export	FABS_C as FABS
export	EXP
export	FRAND
export	FMOD
export	ATAN2
export  LOG10

#
# XIP enabled
#
