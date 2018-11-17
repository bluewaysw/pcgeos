##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		prefsnd.gp
#
# AUTHOR:	Gene Anderson, Aug 25, 1992
#
# Parameters file for: prefsnd.geo
#
#	$Id: prefuic.gp,v 1.4 98/06/17 21:48:01 gene Exp $
#
##############################################################################
#
# Permanent name
#
name prefuic.lib
#
# Long name
#
longname "Change UI Module"
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
resource PrefUICCode		read-only code shared
resource AppLCMonikerResource	shared lmem read-only
resource AppLMMonikerResource	shared lmem read-only
resource AppLCGAMonikerResource	shared lmem read-only
resource PrefUICUI 		object
resource Strings		shared lmem


#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#
export PrefUICGetPrefUITree
#List
export PrefUICGetModuleInfo


export	PrefUICDialogClass
export	PrefUICColorSelectorClass
export	PrefColorsSampleClass
