##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	Preferences
# MODULE:	
# FILE:		prefcomp.gp
#
# AUTHOR:	Adam de Boor
#
# Parameters file for:  prefcomp.geo
#
#	$Id: preffont.gp,v 1.1 97/04/05 01:34:42 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name preffont.lib
#
# Long name
#
longname "Font Module"
#
# Desktop-related definitions
#
tokenchars "PREF"
tokenid 0
#
# Specify geode type
#
type	library, single, c-api
#

# Import library routine definitions
#
library	geos
library	ui
library config
library ansic
#
# Define resources other than standard discardable code
#
nosort
#resource PREFFONT_G		code read-only shared
resource DialogResource ui-object
resource Strings		shared lmem read-only
resource APPLCMONIKERRESOURCE	shared lmem read-only
resource APPLMMONIKERRESOURCE	shared lmem read-only
resource APPLCGAMONIKERRESOURCE	shared lmem read-only

#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#

#export PFGetPrefUITree
export PFGETPREFUITREE
#List
#export PFGetModuleInfo
export PFGETMODULEINFO

# new classes

export PFItemClass
export PFDynamicListClass
export PFItemGroupClass
export PFDialogClass
export PFDeleteTriggerClass
