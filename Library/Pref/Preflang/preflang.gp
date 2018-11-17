##############################################################################
#
#	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# FILE:		preflang.gp
#
# AUTHOR:	Paul Canavese, Jan 26, 1995
#
#	$Id: preflang.gp,v 1.1 97/04/05 01:43:38 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name preflang.lib
#
# Long name
#
longname "Language Module"
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
resource PrefLangCode		read-only code shared
resource PrefLangUI 		object
resource Strings		shared lmem
resource AppLCMonikerResource	shared lmem read-only
#ifndef GPC_VERSION
#resource AppLMMonikerResource	shared lmem read-only
#resource AppLCGAMonikerResource	shared lmem read-only
# endif


#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#
export PrefLangGetPrefUITree
export PrefLangGetModuleInfo

export PrefIniDynamicListClass
export PrefLangDialogClass
export PrefLangIniDynamicListClass





