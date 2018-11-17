##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Geo Manager
# FILE:		manager.gp
#
# AUTHOR:	Tony, 10/89
#
#
# Parameters file for: manager.geo
#
#	$Id: manager.gp,v 1.2 97/07/02 09:24:59 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name manager.app
#
# Long filename
#
longname "GeoManager"
#
# token information
#
ifdef FILEMGR
tokenchars "DESK"
tokenid 0
else
tokenchars "nDSK"
tokenid 16
endif
#
# Specify geode type
#
type	appl, process, single
#
# Specify class name for process
#
class	DesktopClass
#
# Specify application object
#
appobj	Desktop
#
# Import library routine definitions
#
library	geos
library	ui
library shell
#
# Define resources other than standard discardable code
#
resource FixedCode 		fixed code read-only
resource FileMgrsClassStructures	fixed read-only shared
resource InitCode 		preload read-only code shared discard-only
resource DragIconResource 	data read-only
resource GenAppInterface	ui-object
resource Interface 		ui-object
resource PrimaryInterface 	ui-object
resource TreeUI 		ui-object
resource FileOperationUI 	ui-object
resource MenuMoveUI 		ui-object
resource MenuRecoverUI 		ui-object
resource MenuCopyUI ui-object

#
# comment this back in if the CREATE_LINKS flag is ever set...
#resource MenuCreateLinkUI ui-object
#

#resource DisplayOptionsUI 		ui-object
#resource AssociateUI 			ui-object
resource MiscUI 			ui-object
resource ActiveUI 			ui-object
resource ProgressUI 			ui-object
resource ToolUI 			ui-object
resource DiskMenuResource 		ui-object
resource IconAreaResource 		ui-object
resource IconAreaTemplates 		ui-object read-only
resource DesktopUI 			object		# application-run
resource FolderWindowTemplate 		ui-object read-only
resource FolderObjectTemplate 		object read-only
resource MonikerResource 		shared lmem read-only
resource AppLCMonikerResource 		shared lmem read-only
resource AppLMMonikerResource 		shared lmem read-only
resource AppSCMonikerResource 		shared lmem read-only
resource AppSMMonikerResource 		shared lmem read-only
resource AppSCGAMonikerResource 	shared lmem read-only
resource AppYMMonikerResource 		shared lmem read-only
resource AppYCMonikerResource 		shared lmem read-only
resource AppDrivesSCMonikerResource 	shared lmem read-only
resource AppDrivesSMMonikerResource 	shared lmem read-only
resource AppDrivesSCGAMonikerResource 	shared lmem read-only
resource AppDrivesYMMonikerResource 	shared lmem read-only
resource AppIconAreaSCMonikerResource 	shared lmem read-only
resource AppIconAreaSMMonikerResource 	shared lmem read-only
resource AppIconAreaSCGAMonikerResource shared lmem read-only
resource DeskStringsCommon 		lmem shared read-only
resource DeskStringsRare 		lmem shared read-only
resource DeskTriggerMonikers 		lmem shared read-only
resource DOSLauncherResource 		ui-object
resource DummyResource 			object
#
# Define classes
#
export DesktopViewClass
export DeskVisClass
export ShellObjectClass
export TreeClass
export FolderClass
export DeskApplicationClass
export DeskDisplayGroupClass
export DeskDisplayClass
export DeskToolClass
export DirToolClass
export DriveToolClass
export DriveLetterClass
export DriveListClass
export FileOperationBoxClass
export FileOpAppActiveBoxClass
export FileOpFileListClass
export CancelTriggerClass
export PathnameStorageClass
export WFileSelectorClass
export ToolAreaClass
export ToolManagerClass
export ToolTriggerClass
export DeskDisplayControlClass
ifdef DO_PIZZA
else
export MaximizedPrimaryClass
endif
#
# XIP-enabled
#
