##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		prefserver.gp
#
# AUTHOR:	Chris Boyke, 3/27/92
#
# Parameters file for:  prefserver.geo
#
#	$Id: preflink.gp,v 1.1 97/04/05 01:28:27 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name preflink.lib
#
# Long name
#
longname "Preferences Link Module"
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
resource PrefLinkCode		read-only code shared
resource AppLCMonikerResource	shared lmem read-only
resource AppLMMonikerResource	shared lmem read-only
resource AppLCGAMonikerResource	shared lmem read-only
resource LinkUI object
resource Strings shared lmem read-only


#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#
export PrefLinkGetPrefUITree
#List
export PrefLinkGetModuleInfo

# new classes

export PrefDriveListClass
export DriveLetterClass
export PrefLinkDialogClass
export PrefLinkConnectItemGroupClass
