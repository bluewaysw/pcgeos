##############################################################################
#
#	Copyright (c) Designs in Light 2002 -- All Rights Reserved
#
# FILE:		configui.gp
#
##############################################################################
#
# Permanent name
#
name configui.lib
#
# Long name
#
longname "Configure UI Module"
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
library color
#
# Define resources other than standard discardable code
#
nosort
resource ConfigUICode		read-only code shared
resource AppLCMonikerResource	shared lmem read-only
resource AppLMMonikerResource	shared lmem read-only
resource AppLCGAMonikerResource	shared lmem read-only
resource ConfigUIUI 		object
resource Strings		shared lmem read-only
resource SchemeStrings		shared lmem read-only


#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#
export ConfigUIGetPrefUITree
#List
export ConfigUIGetModuleInfo


export ConfigUIDialogClass
export ConfigUIListClass
export StartupListClass
export FileAssocListClass
export IconTokenListClass
export ConfigUICColorSelectorClass
export PrefColorsSampleClass
export PrefMinuteValueClass
export ConfigUIFontAreaClass
export ConfigUICSchemeListClass
export SectionsPrefClass
