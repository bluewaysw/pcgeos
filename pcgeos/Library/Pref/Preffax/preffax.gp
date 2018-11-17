##############################################################################
#
#	Copyright (c) Geoworks 1994.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	Pasta
# MODULE:	PrefFax
# FILE:		PrefFax.gp
#
# AUTHOR:	Don Reeves, November 30, 1992
#
# Parameters file for: PrefFax.geo
#
#	$Id: preffax.gp,v 1.1 97/04/05 01:38:36 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name preffax.lib
#
# Long name
#
longname "Fax Pref Module"
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
library spool
#
# Define resources other than standard discardable code
#
nosort
resource PrefFaxCode		code read-only shared
resource AppLMMonikerResource	shared lmem read-only
resource PrefFaxUI 		object
resource Strings		shared lmem
#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#
export PrefFaxGetPrefUITree
export PrefFaxGetModuleInfo
#
export PrefFaxDialogClass
export PrefInteractionSpecialClass
export PrefItemGroupSpecialClass
export PreffaxOKTriggerClass
