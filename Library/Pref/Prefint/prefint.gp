##############################################################################
#
#	Copyright (c) New Deal 1998 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		prefint.gp
#
# AUTHOR:	Gene Anderson, Mar. 25, 1998
#
# Parameters file for: prefint.geo
#
#	$Id: prefint.gp,v 1.1 98/04/24 00:10:33 gene Exp $
#
##############################################################################
#
# Permanent name
#
name prefint.lib
#
# Long name
#
longname "Internet"
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
resource PrefIntCode		read-only code shared
resource AppLCMonikerResource	shared lmem read-only
resource AppLMMonikerResource	shared lmem read-only
resource AppLCGAMonikerResource	shared lmem read-only
resource PrefIntUI 		object
resource Strings		shared lmem


#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#
export PrefIntGetPrefUITree
#List
export PrefIntGetModuleInfo


export	PrefIntDialogClass
export	PrefModemDialogClass