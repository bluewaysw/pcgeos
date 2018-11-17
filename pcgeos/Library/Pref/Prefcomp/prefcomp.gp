##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	Preferences
# MODULE:	
# FILE:		prefcomp.gp
#
# AUTHOR:	Adam de Boor
#
# Parameters file for:  prefcomp.geo
#
#	$Id: prefcomp.gp,v 1.1 97/04/05 01:33:05 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name prefcomp.lib
#
# Long name
#
longname "Computer Module"
#
# Desktop-related definitions
#
tokenchars "PREF"
tokenid 0
#
# Specify geode type
#
type	library, single
#

# Import library routine definitions
#
library	geos
library	ui
library config
driver	serial
driver	parallel
#
# Define resources other than standard discardable code
#
nosort
resource PrefCompCode		read-only code shared
resource AppLCMonikerResource	shared lmem read-only
resource AppLMMonikerResource	shared lmem read-only
resource AppLCGAMonikerResource	shared lmem read-only
resource ComputerUI ui-object
resource Strings		shared lmem read-only

#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#

export PrefCompGetPrefUITree
#List
export PrefCompGetModuleInfo

# new classes

export PrefCompMemItemClass
export PrefCompMemItemGroupClass
export PrefCompSerialValueClass
export PrefCompParallelItemGroupClass
