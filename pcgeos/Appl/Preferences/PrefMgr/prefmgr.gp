##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	PrefMgr
# FILE:		prefmgr.gp
#
# AUTHOR:	cheng, 1/90
#
#
# Parameters file for: prefmgr.geo
#
#	$Id: prefmgr.gp,v 1.3 98/05/15 17:50:40 gene Exp $
#
##############################################################################
#
# Permanent name
#
name prefmgr.app
#
# Long filename
#
longname "Preferences"
#
# token information
#
tokenchars "PMGR"
tokenid 0
#
# Specify geode type
#
type	appl, process, single
#
# Specify class name for process
#
class	PrefMgrClass
#
# Specify application object
#
appobj	PrefMgrApp

heapspace 15676		#Includes 30K of UI for pref modules

# Give ourselves more stack space to deal with especially large UI
# trees
stack 3000

#
# Import library routine definitions
#
library	geos
library	ui
library spool
library text
library spell
library config
driver  serial
#
# Define resources other than standard discardable code
#
resource AppResource 		object
resource MainUI 		object
resource PrinterUI 		object
resource ModemUI 		object
resource SerialUI 		object
resource TextUI 		object

#
# Art work
#

resource AppLCMonikerResource	read-only shared lmem
resource AppLMMonikerResource	read-only shared lmem
resource AppLCGAMonikerResource	read-only shared lmem
ifndef GPC_VERSION
resource AppSCMonikerResource 	read-only shared lmem
resource AppSMMonikerResource	read-only shared lmem
resource AppSCGAMonikerResource	read-only shared lmem
else
ifdef GPC_ONLY
resource GPCLogoResource	read-only shared lmem
endif
resource AppMonikerResource	read-only shared lmem
resource AppTinyMonikerResource	read-only shared lmem
resource PrntMonikerResource	read-only shared lmem
resource TextMonikerResource	read-only shared lmem
endif
resource Strings		read-only shared lmem
resource PrefMgrStrings		read-only shared lmem

#
# Export defined  classes
#

export 	PrefNotifyDialogClass
export	PrefTitledTriggerClass
export	PrefMgrApplicationClass
ifdef GPC_ONLY
export  PrefMgrGenPrimaryClass
endif
ifdef GPC_VERSION
export  PrefDebugGenInteractionClass
export  PrinterGenDynamicListClass
endif

#
# Define exported VisOpen/VisClose routines for state-file relocation
#

export	VisOpenModem
export  VisOpenText
export  TextCloseEditBox
export	VisOpenChooseDictionary
export  VisOpenPrinter

export  PrefSerialDialogClass
