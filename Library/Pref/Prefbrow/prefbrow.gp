##############################################################################
#
# 	Copyright (c) MyTurn.com 2001.  All rights reserved.
#       MYTURN.COM CONFIDENTIAL
#
# PROJECT:	GlobalPC
# MODULE:	Browser pref module
# FILE: 	prefbrow.gp
# AUTHOR: 	Brian Chin, Mar 30, 2001
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	brianc  3/30/01   	Initial Revision
#
# DESCRIPTION:
#	Parameters file for browser module of Preferences
#
#	$Id$
#
###############################################################################
#
# Permanent name
#
name prefbrow.lib
#
# Long name
#
longname "Browser Module"
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
resource PrefbrowCode		read-only code shared
resource PrefbrowUI 		object
resource PrefbrowMonikers	shared lmem read-only

#
# Exported routines.  These MUST be exported first, and they must be
# in the same order as the PrefModuleEntryType etype
#
export PrefbrowGetPrefUITree
export PrefbrowGetModuleInfo

export PrefbrowDialogClass
