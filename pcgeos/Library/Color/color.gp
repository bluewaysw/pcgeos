##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990, 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Color Library
# FILE:		color.gp
#
# AUTHOR:	Doug Fults,  1/19/91
#
#	$Id: color.gp,v 1.2 98/04/24 00:39:49 gene Exp $
#
##############################################################################
#
# Permanent name
#
name color.lib

library geos
library ui

#
# Specify geode type
#
type	library, single

#
# Desktop-related things
#
longname	"Color Library"
tokenchars	"COLL"
tokenid		0

#
# Define resources other than standard discardable code
#
nosort

ifndef GP_NO_CONTROLLERS
ifndef GP_JEDI
resource ColorSelectorCode read-only code shared
resource ColorSelectorGenerateCode read-only code shared
resource ColorSelectorUI ui-object read-only shared
resource ColorSelectorToolboxUI ui-object read-only shared
resource ColorMonikers lmem data read-only shared
resource ControlStrings lmem
endif		# ifndef GP_JEDI
endif		# ndef GP_NO_CONTROLLERS

#
# Export routines
#
export ColorSelectorClass
#
# XIP-enabled
#

export Color256SelectorClass
export ColorSampleClass
export ColorBarClass
export ColorOtherDialogClass
export CustomColorClass
export ColorValueClass
