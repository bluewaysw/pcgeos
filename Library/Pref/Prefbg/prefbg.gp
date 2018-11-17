##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		prefbg.gp
#
# AUTHOR:	Gene Anderson, Aug 25, 1992
#
# Parameters file for: prefbg.geo
#
#	$Id: prefbg.gp,v 1.1 97/04/05 01:29:16 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name prefbg.lib
#
# Long name
#
longname "Background Module"
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
library color
library convert noload
#
# Define resources other than standard discardable code
#
nosort
resource PrefBGCode		code read-only shared
resource AppLCMonikerResource	shared lmem read-only
resource PrefBGUI 		object
resource Strings		shared lmem


#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#
export PrefBGGetPrefUITree
#List
export PrefBGGetModuleInfo


# Exported classes

export PrefBGDialogClass
export PrefBGChooseListClass
# Moved to config Library	 9/94 -mohsin
#export PrefBGColorSelectorClass	
