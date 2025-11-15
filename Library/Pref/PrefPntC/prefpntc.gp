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
name prefpntc.lib
#
# Long name
#
longname "KidGuard Module"
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
library parentc

#
# Define resources other than standard discardable code
#
nosort
resource PrefPntCtrlCode	     read-only code shared
resource AppLHCMonikerResource   shared lmem read-only
resource AppLCMonikerResource    shared lmem read-only
resource AppLMMonikerResource    shared lmem read-only
resource AppLCGAMonikerResource  shared lmem read-only
resource MonikerResource	     shared lmem read-only
resource ParentalControlUI       ui-object
resource Strings		         shared lmem read-only

#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#

export PrefCompGetPrefUITree
#List
export PrefCompGetModuleInfo

# new classes
export PrefPntCDialogClass
export PntCtrlItemGroupClass
export PCPrefInteractionClass
export PCSettingPrefInteractionClass
