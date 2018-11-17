##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	Preferences
# MODULE:	
# FILE:		qixpref.gp
#
# AUTHOR:	Adam de Boor
#
#	$Id: qixpref.gp,v 1.1 97/04/04 16:46:45 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name qixpf.lib
#
# Long name
#
longname "Qix Options"
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
resource QixOptions	object

#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#

export QixPrefGetPrefUITree
export QixPrefGetModuleInfo


