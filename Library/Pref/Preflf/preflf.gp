##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		preflf.gp
#
# AUTHOR:	Gene Anderson, Aug 25, 1992
#
# Parameters file for: preflf.geo
#
#	$Id: preflf.gp,v 1.1 97/04/05 01:29:23 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name preflf.lib
#
# Long name
#
longname "Look & Feel Module"
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
resource PrefLFCode		read-only code shared
ifndef GPC_VERSION
resource AppLCMonikerResource	shared lmem read-only
resource AppLMMonikerResource	shared lmem read-only
resource AppLCGAMonikerResource	shared lmem read-only
else
resource AppMonikerResource	shared lmem read-only
endif
resource PrefLFUI 		object
resource Strings		shared lmem read-only

#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#
export PrefLFGetPrefUITree
#List
export PrefLFGetModuleInfo

# exported classes

export	PrefFontItemGroupClass
export	PrefLFDialogClass
export	PrefMinuteValueClass
export	PrefLFSameBooleanGroupClass
export	PrefWidthValueClass
