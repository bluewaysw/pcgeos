##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		prefos.gp
#
# AUTHOR:	Gene Anderson, Aug 25, 1992
#
# Parameters file for: prefos.geo
#
#	$Id: prefos.gp,v 1.4 98/03/24 21:54:52 gene Exp $
#
##############################################################################
#
# Permanent name
#
name prefos.lib
#
# Long name
#
longname "Geos Module"
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
resource PrefOSCode		read-only code shared
resource AppLCMonikerResource	shared lmem read-only
resource AppLMMonikerResource	shared lmem read-only
resource AppLCGAMonikerResource	shared lmem read-only
resource PrefOSUI 		object
resource Strings		shared lmem


#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#
export PrefOSGetPrefUITree
export PrefOSGetModuleInfo


export	PrefOSSwapTextClass
