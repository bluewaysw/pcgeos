##############################################################################
#
#	Copyright (c) New Deal 1998 -- All Rights Reserved
#
# PROJECT:	Newdeal
# MODULE:	
# FILE:		tweakui.gp
#
# AUTHOR:	Gene Anderson
#
# Parameters file for: prefsnd.geo
#
#	$Id: tweakui.gp,v 1.3 98/05/14 00:04:21 gene Exp $
#
##############################################################################
#
# Permanent name
#
name tweakui.lib
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
resource TweakUICode		read-only code shared
resource AppLCMonikerResource	shared lmem read-only
resource AppLMMonikerResource	shared lmem read-only
resource AppLCGAMonikerResource	shared lmem read-only
resource TweakUIUI 		object
resource Strings		shared lmem read-only
resource SchemeStrings		shared lmem read-only


#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#
export TweakUIGetPrefUITree
#List
export TweakUIGetModuleInfo


export TweakUIDialogClass
export TweakUIStartupListClass
#export TweakUIHideDriveBooleanClass
export PrefUICColorSelectorClass
export PrefColorsSampleClass
export PrefMinuteValueClass
export TweakUIFontAreaClass
export PrefUICSchemeListClass
