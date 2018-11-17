##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990, 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Styles Library
# FILE:		styles.gp
#
# AUTHOR:	Tonmy Requist, 12/18/91
#
#	$Id: styles.gp,v 1.1 97/04/07 11:15:36 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name styles.lib

library geos
library ui

#
# Specify geode type
#
type	library, single

#
# Desktop-related things
#
longname	"Styles Library"
tokenchars	"STYL"
tokenid		0

#
# Define resources other than standard discardable code
#

resource CommonCode			code read-only shared

resource ManipCode			code read-only shared

ifndef GP_NO_CONTROLLERS
resource StyleSheetControlCommon	code read-only shared
resource StyleSheetControlCode		code read-only shared
resource AppTCMonikerResource 		ui-object read-only shared
ifndef GPC_ART
resource AppTMMonikerResource 		ui-object read-only shared
resource AppTCGAMonikerResource 	ui-object read-only shared
endif
resource StyleSheetControlUI 		ui-object read-only shared
resource StyleSheetControlToolboxUI 	ui-object read-only shared
endif		# ndef GP_NO_CONTROLLERS


resource ControlStrings 		lmem read-only shared
ifdef GP_FULL_EXECUTE_IN_PLACE
resource StylesXIPCode			code fixed read-only shared
endif

#
# Export routines
#
export StyleSheetControlClass

export StyleSheetCopyElement
export StyleSheetImportStyles
export StyleSheetDescribeStyle
export StyleSheetDescribeAttrs
export StyleSheetGetStyle
export StyleSheetGetStyleCounts
export StyleSheetRequestEntryMoniker
export StyleSheetUpdateModifyBox
export StyleSheetModifyStyle
export StyleSheetDeleteStyle
export StyleSheetDefineStyle
export StyleSheetRedefineStyle
export StyleSheetGetStyleToApply

export StyleSheetGetNotifyCounter
export StyleSheetIncNotifyCounter

export StyleSheetGenerateChecksum
export StyleSheetCallDescribeRoutines
export StyleSheetCallMergeRoutines

ifdef GP_FULL_EXECUTE_IN_PLACE
export StyleSheetDescribeExclusiveWordXIP as StyleSheetDescribeExclusiveWord
export StyleSheetDescribeNonExclusiveWordXIP as StyleSheetDescribeNonExclusiveWord
else
export StyleSheetDescribeExclusiveWord
export StyleSheetDescribeNonExclusiveWord
endif

export StyleSheetDescribeWWFixed
export StyleSheetDescribeDistance
export StyleSheetAddNameFromChunk
export StyleSheetAddCharToDescription
export StyleSheetAddAttributeHeader
export StyleSheetLockStyleChunk
export StyleSheetUnlockStyleChunk
export StyleSheetOpenFileForImport
export StyleSheetAddNameFromPtr
export StyleSheetAddWord
export StyleSheetSaveStyle
export StyleSheetPrepareForRecallStyle
#
# XIP-enabled
#

