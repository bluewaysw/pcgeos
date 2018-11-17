##############################################################################
#
#	Copyright (c) GlobalPC 1998 -- All Rights Reserved
#
# PROJECT:	Backup and Restore Application
# MODULE:	The front-end application
# FILE:		backrest.gp
#
# AUTHOR:	Edwin Yu
#
# DESCRIPTION:
#
# RCS STAMP:
#	$Id: $
#
##############################################################################
#
name bkrt.app
#
longname "Backup Manager"
#
type	appl, process, single
#
class	BKRTProcessClass
#
appobj	BKRTApp
#
tokenchars "BKRT"
tokenid 17
#
#heapspace 4330
#
library	geos
library	ui
library ansic
library bckrst
#
resource APPRESOURCE ui-object
resource INTERFACE ui-object
resource APPMONIKERRESOURCE lmem read-only shared
resource TEXTSTRINGS lmem data

export BackupListClass
export MyItemGroupClass
export MyDocumentFolderWindowClass
export MyGenTextClass
export MyGenInteractionClass
export MyGenFileSelectorClass
export MyGenTriggerClass

