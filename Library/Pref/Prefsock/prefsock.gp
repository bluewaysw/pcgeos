##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		prefsock.gp
#
# AUTHOR:	Steve Jang, 11/8/94
#
# Parameters file for: prefsock.geo
#
#	$Id: prefsock.gp,v 1.1 97/04/05 01:43:09 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name prefsock.lib
#
# Long name
#
longname "Socket Module"
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
resource PrefSocketCode		read-only code shared
resource PrefSocketResidentCode	read-only code fixed shared
resource AppLCMonikerResource	shared lmem read-only
resource AppLMMonikerResource	shared lmem read-only
resource AppLCGAMonikerResource	shared lmem read-only
resource PrefSocketUI 		ui-object
resource Strings		shared lmem
resource PrefSocketClassStructures read-only fixed shared


#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#
export PrefSocketGetPrefUITree
export PrefSocketGetModuleInfo

#
# Exported classes
#
export PrefSocketDialogClass
export PrefSocketEditClass
