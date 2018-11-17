##############################################################################
#
#	Copyright (c) Designs in Light 2000 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	
# FILE:		prefpm.gp
#
# Parameters file for:  prefpm.geo
#
#	$Id$
#
##############################################################################
#
# Permanent name
#
name prefpm.lib
#
# Long name
#
longname "Power Management Module"
usernotes "Copyright (c) Designs in Light - http://www.designsinlight.com"
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
#
# Define resources other than standard discardable code
#
nosort
resource PrefPowerCode		read-only code shared
resource AppLCMonikerResource	shared lmem read-only
resource AppLMMonikerResource	shared lmem read-only
resource PrefPowerUI		object
resource Strings		shared lmem

#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#
export PrefPowerGetPrefUITree
export PrefPowerGetModuleInfo

# exported classes
export PrefPowerDialogClass
export DriverStatusDialogClass
