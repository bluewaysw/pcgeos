##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Graphical Setup
# FILE:		setup.gp
#
# AUTHOR:	cheng, 1/90
#
#
# Parameters file for: setup 
#
#	$Id: setup.gp,v 1.2 98/06/17 21:26:51 gene Exp $
#
##############################################################################
#
# Permanent name
#
name setup.app
#
# Long name
#
ifdef DO_DBCS
longname "G Setup"
else
longname "Graphical Setup"
endif
#
# Desktop-related definitions
#
tokenchars "PREF"
tokenid 0
#
# Specify geode type
#
type	appl, process, single
#
# Specify class name for process
#
class	SetupClass
#
# Specify application object
#
appobj	SetupApp
#
# Import library routine definitions
#
library	geos
library	ui
library spool
library config
driver serial
driver parallel

#
# Define resources other than standard discardable code
#
resource Interface ui-object
resource ScreenTemplates ui-object, read-only
resource Strings lmem, shared, read-only
resource SysInfoUI lmem, shared, read-only

resource ColorUIBitmaps1 lmem, read-only
resource ColorUIBitmaps2 lmem, read-only

export	SetupScreenClass
export	SetupColorBoxClass
export	SetupDeviceListClass
export 	SetupTextDisplayClass
#
# For relocating things
#
export	SetupDrawCornerArrows
export	PrinterSpecialDevice
export	SetupSPUISampleClass
export  SetupUIListClass
