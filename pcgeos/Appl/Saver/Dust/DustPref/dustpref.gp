##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	Preferences
# MODULE:	
# FILE:		dustpref.gp
#
# AUTHOR:	Adam de Boor
#
#	$Id: dustpref.gp,v 1.1 97/04/04 16:48:19 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name dustpf.lib
#
# Long name
#
longname "Dust Options"
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
resource DustOptions	object

#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#

export DustPrefGetPrefUITree
export DustPrefGetModuleInfo


