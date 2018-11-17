##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	Preferences
# MODULE:	
# FILE:		hopalongpref.gp
#
# AUTHOR:	Adam de Boor
#
#	$Id: hopalongpref.gp,v 1.1 97/04/04 16:44:56 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name hopapf.lib
#
# Long name
#
longname "Hopalong Options"
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
resource HopalongOptions	object

#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#

export HopalongPrefGetPrefUITree
export HopalongPrefGetModuleInfo


