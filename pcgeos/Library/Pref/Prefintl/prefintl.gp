##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		prefintl.gp
#
# AUTHOR:	Gene Anderson, Aug 25, 1992
#
# Parameters file for: prefintl.geo
#
#	$Id: prefintl.gp,v 1.1 97/04/05 01:39:10 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name prefintl.lib
#
# Long name
#
longname "International Module"
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
resource PrefIntlCode		read-only code shared
resource AppLCMonikerResource	shared lmem read-only
resource AppLMMonikerResource	shared lmem read-only
resource AppLCGAMonikerResource	shared lmem read-only
resource PrefIntlUI 		object
resource Strings		shared lmem


#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#
export PrefIntlGetPrefUITree
#List
export PrefIntlGetModuleInfo


export	PrefIntlDialogClass
export	CustomSpinClass

ifdef DO_PIZZA
export PrefGengoInteractionClass
endif


