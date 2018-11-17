##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	Preferences
# MODULE:	
# FILE:		tilespref.gp
#
# AUTHOR:	Adam de Boor
#
#	$Id: tilespref.gp,v 1.1 97/04/04 16:47:55 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name tilespf.lib
#
# Long name
#
longname "Tiles Options"
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
resource TilesOptions	object

#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#

export TilesPrefGetPrefUITree
export TilesPrefGetModuleInfo


