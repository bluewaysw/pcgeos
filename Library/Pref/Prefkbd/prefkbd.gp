##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		prefkbd.gp
#
# AUTHOR:	Gene Anderson, Aug 25, 1992
#
# Parameters file for: prefkbd.geo
#
#	$Id: prefkbd.gp,v 1.1 97/04/05 01:28:55 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name prefkbd.lib
#
# Long name
#
longname "Keyboard Module"
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
resource PrefKbdCode		read-only code shared
ifndef GPC_VERSION
resource AppLCMonikerResource	shared lmem read-only
resource AppLMMonikerResource	shared lmem read-only
resource AppLCGAMonikerResource	shared lmem read-only
else
resource AppMonikerResource	shared lmem read-only
endif
resource PrefKbdUI 		object
resource Strings		shared lmem


#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#

export PrefKbdGetPrefUITree
#List
export PrefKbdGetModuleInfo


# new classes

export PrefKbdDialogClass
