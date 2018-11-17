##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		prefui.gp
#
# AUTHOR:	Chris Boyke, 3/27/92
#
# Parameters file for:  prefui.geo
#
#	$Id: prefui.gp,v 1.1 97/04/05 01:42:47 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name prefui.lib
#
# Long name
#
longname "User Level Module"
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
resource PrefUIUI ui-object
resource Strings		shared lmem read-only
#resource AppLCMonikerResource	shared lmem read-only
#resource AppLMMonikerResource	shared lmem read-only
#resource AppLCGAMonikerResource	shared lmem read-only

export PrefUIGetPrefUITree
export PrefUIGetMonikerList

# new classes

export PrefUIDialogClass
