##############################################################################
#
#	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
# PROJECT:	Tiramisu
# FILE:		preffax2.gp
#
# AUTHOR:	Peter Trinh, Jan 16, 1995
#
#
# 
#
#	$Id: preffax2.gp,v 1.2 98/02/25 22:39:14 gene Exp $
#
##############################################################################
#
# Permanent name
#
name preffax2.lib
#
# Long name
#
longname "Fax Preference Module"
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
library faxfile
#
# Define resources other than standard discardable code
#
nosort
resource PrefFaxCode		code read-only shared
resource AppLCMonikerResource	shared lmem read-only
resource AppLMMonikerResource	shared lmem read-only
resource AppLCGAMonikerResource	shared lmem read-only
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
export PrefDialingCodeListClass
