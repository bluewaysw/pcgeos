##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		prefts.gp
#
# AUTHOR:	Chris Boyke, 3/27/92
#
# Parameters file for:  prefts.geo
#
#	$Id: prefts.gp,v 1.1 97/04/05 01:28:33 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name prefts.lib
#
# Long name
#
longname "Task Switcher Module"
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
resource PrefTSCode			read-only code shared
resource AppLCMonikerResource	shared lmem read-only
resource AppLMMonikerResource	shared lmem read-only
resource AppLCGAMonikerResource	shared lmem read-only
resource TaskSwitchUI ui-object
resource Strings		shared lmem read-only

#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#

export PrefTSGetPrefUITree
#List
export PrefTSGetModuleInfo

# new classes


