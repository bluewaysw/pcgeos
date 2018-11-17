##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		prefvid.gp
#
# AUTHOR:	Gene Anderson, Aug 25, 1992
#
# Parameters file for: prefvid.geo
#
#	$Id: prefvid.gp,v 1.1 97/04/05 01:37:29 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name prefvid.lib
#
# Long name
#
longname "Video Module"
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
resource PrefVidCode		code read-only shared
ifndef GPC_VERSION
resource AppLCMonikerResource	shared lmem read-only
resource AppLMMonikerResource	shared lmem read-only
resource AppLCGAMonikerResource	shared lmem read-only
else
resource AppMonikerResource	shared lmem read-only
endif
resource PrefVidUI 		object
resource Strings		shared lmem


#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#
export PrefVidGetPrefUITree
export PrefVidGetModuleInfo


export	PrefVidDialogClass
export	PrefVidDeviceListClass
ifdef	GPC_VERSION
export	PrefVidTvPosInteractionClass
export	PrefVidTvSizeInteractionClass
export	PrefVidTvSizeBordersPrimaryClass
export	PrefVidBooleanGroupClass
export	PrefVidBooleanClass
endif	# GPC_VERSION
