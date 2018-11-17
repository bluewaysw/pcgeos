##############################################################################
#
#	Copyright (c) GeoWorks 1994 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Prefspui
# FILE:		prefspui.gp
#
# AUTHOR:	Tony Requist, Sep 12, 1994
#
# Parameters file for: prefspui.geo
#
#	$Id: prefspui.gp,v 1.1 97/04/05 01:42:55 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name prefspui.lib
#
# Long name
#
longname "Specific UI Module"
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
resource PrefSpuiCode		read-only code shared
resource AppLCMonikerResource	shared lmem read-only
resource AppLMMonikerResource	shared lmem read-only
resource AppLCGAMonikerResource	shared lmem read-only
resource PrefSpuiUI 		object
resource PrefSpuiStrings	shared lmem


#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#
export PrefSpuiGetPrefSpuiTree
#List
export PrefSpuiGetModuleInfo


export	PrefSpuiDialogClass
export	PrefSpuiDynamicListClass
export	PSDescriptiveDLClass
