##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	Lights Out
# FILE:		flamepref.gp
#
# AUTHOR:	Jim Guggemos, Aug 26, 1994
#
#
# Preferences module for flame screen saver
#
#	$Id: flamepref.gp,v 1.1 97/04/04 16:49:10 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name flamepf.lib
#
# Long name
#
longname "Flame Fractal Options"
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
resource FlameOptions	object

#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#

export FlamePrefGetPrefUITree
export FlamePrefGetModuleInfo


