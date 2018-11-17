##############################################################################
#
# 	Copyright (c) MyTurn.com 2001.  All rights reserved.
#       MYTURN.COM CONFIDENTIAL
#
# PROJECT:	GlobalPC
# MODULE:	User level pref module
# FILE: 	preflvl.gp
# AUTHOR: 	David Hunter, Jan 08, 2001
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	dhunter 1/08/01   	Initial Revision
#
# DESCRIPTION:
#	Parameters file for user level module of Preferences
#
#	$Id$
#
###############################################################################
#
# Permanent name
#
name preflvl.lib
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
nosort
resource PreflvlCode		read-only code shared
resource PreflvlUI 		object
resource PreflvlMonikers	shared lmem read-only

#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#
export PreflvlGetPrefUITree
export PreflvlGetModuleInfo

export PreflvlDialogClass
