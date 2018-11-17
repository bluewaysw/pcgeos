##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	Preferences
# MODULE:	
# FILE:		preflo.gp
#
# AUTHOR:	Adam de Boor
#
# Parameters file for:  preflo.geo
#
#	$Id: preflo.gp,v 1.1 97/04/05 01:32:06 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name preflo.lib
#
# Long name
#
longname "Lights Out Module"
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
library saver
library net noload
#
# Define resources other than standard discardable code
#
nosort
resource PrefLOCode		read-only code shared
ifndef GPC_VERSION
resource AppLCMonikerResource	shared lmem read-only
resource AppLMMonikerResource	shared lmem read-only
resource AppLCGAMonikerResource	shared lmem read-only
else
resource AppMonikerResource	shared lmem read-only
endif
resource LightsOutUI ui-object
resource Strings		shared lmem read-only

#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#

export PrefLOGetPrefUITree
#List
export PrefLOGetModuleInfo

# new classes

export PrefLODialogClass
export PrefLOPasswordTextClass
