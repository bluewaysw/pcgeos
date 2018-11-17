##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	Preferences
# MODULE:	Pager
# FILE:		prefpag.gp
#
# AUTHOR:	Jennifer Wu
#
# Parameters file for:  prefpag.geo
#
#	$Id: prefpag.gp,v 1.1 97/04/05 01:29:44 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name prefpag.lib
#
# Long name
#
longname "Pager Module"
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
resource PrefPagUI		ui-object
resource Strings		shared lmem read-only
resource AppLCMonikerResource	shared lmem read-only
resource AppLMMonikerResource 	shared lmem read-only
resource AppLCGAMonikerResource	shared lmem read-only

#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#

export PrefPagGetPrefUITree
export PrefPagGetModuleInfo

#List

# new classes
export PrefPagDialogClass
export PrefPagDynamicListClass

		
		
