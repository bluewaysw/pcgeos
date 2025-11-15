##############################################################################
#
#       Copyright (c) Geoworks 1991 -- All Rights Reserved
#
# PROJECT:     PC GEOS
# MODULE:      
# FILE:        watcomc.gp
#
# AUTHOR:      jimmy
#
#
# Geode parameters for borlandc the interrupt driven floating point support
# as implemented by borlandc and micrsooftc
#
#       $Id: watcomc.gp,v 1.1 97/04/05 01:22:48 newdeal Exp $ 
#
##############################################################################

#
# Specify the geode's permanent name
#
name watcomc.lib

#
# Specify the type of geode (this is both a library, so other geodes can
# use the functions, and a driver, so it is allowed to access I/O ports).
# It may only be loaded once.
#
type library, single

#
# Define the library entry point
#
#entry BorlandcLibraryEntry

#
# Import definitions from the kernel
#
library geos
library ui
library math
#
# Desktop-related things
#
longname        "Watcom Float Library"
tokenchars      "WFL0"
tokenid         0

#
# Specify alternate resource flags for anything non-standard
#
nosort
resource WatcomMath	code read-only shared

#
#

export __FDFS
export __FDU4
export __EDM
export __EDA
export __EDS
export __EDC
export __FDM
export __FDA
export __FDS
export __FDC
export __EDD
export __FDD
export __FDN
export __I4FD
export __U4FD
export __FDI4
export __FSU4
export __FSI4
export __FSM
export __FSA
export __FSS
export __FSD
export __U4FS
export __I4FS
export __FSN
export __FSFD
export __FSC


#
# XIP enabled
#
