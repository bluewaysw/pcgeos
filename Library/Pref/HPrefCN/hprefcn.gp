##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		hprefcn.gp
#
# AUTHOR:	Gene Anderson, Aug 25, 1992
#
# Parameters file for: hprefcn.geo
#
#	$Id: hprefcn.gp,v 1.1 97/04/05 01:37:40 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name hprefcn.lib
#
# Long name
#
longname "Connect Module"
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

driver serial

#
# Define resources other than standard discardable code
#
nosort
resource HPrefCNCode		read-only code shared
resource AppLCMonikerResource	shared lmem read-only
resource AppLMMonikerResource	shared lmem read-only
resource AppLCGAMonikerResource	shared lmem read-only
resource HPrefCNUI 		object
resource Strings		shared lmem


#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#
export HPrefCNGetPrefUITree
#List
export HPrefCNGetModuleInfo


export	HPrefCNDialogClass
export  PrefDriveListClass
export	PrefCompSerialValueClass
