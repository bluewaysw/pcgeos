##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Library/Spool
# FILE:		spool.gp
#
# AUTHOR:	Tony, 2/90
#
#
# Parameters file for: spool.geo
#
#	$Id: spool.gp,v 1.1 97/04/07 11:11:38 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name spool.lib
#
# Long name
#
longname "Print Spool Library"
#
# DB Token
#
tokenchars "SL00"
tokenid 0
#
# Specify geode type
#
type	appl, library, process, single
#
# Specify stack size
#
stack	3000
#
# Heap space requirement - measured the same for XIP & non-XIP.
#
heapspace 6k
#
# Define library entry point (currently none)
#
#entry	SpoolLibraryEntry
#
# Specify class name for process
#
class	SpoolProcClass
#
# Specify application object
#
appobj	spoolAppObj
#
# Import kernel routine definitions
#
library	geos
library ui
#
# Define resources other than standard discardable code
#
nosort
resource SpoolInit 		code read-only shared discard-only preload
resource PrintError		code read-only shared
resource SpoolPaper		code read-only shared
resource SpoolPrinter		code read-only shared
resource SpoolMisc		code read-only shared
resource QueueManagement	code read-only shared
resource PrintThread		code read-only shared

resource IBM437Table 		data shared read-only conforming
resource IBM850Table 		data shared read-only conforming
resource IBM860Table 		data shared read-only conforming
resource IBM863Table 		data shared read-only conforming
resource IBM865Table 		data shared read-only conforming
resource RomanTable 		data shared read-only conforming
resource VenturaTable 		data shared read-only conforming
resource WindowsTable 		data shared read-only conforming
resource LatinTable 		data shared read-only conforming

resource C_Spool		code read-only shared
resource PrintText		code read-only shared
resource PrintGraphics		code read-only shared
resource PrintPDL		code read-only shared
resource PrintInit		code read-only shared
resource SpoolExit		code read-only shared
resource SpoolerApp		code read-only shared
resource PrintControlCommon	code read-only shared
resource PrintControlCode	code read-only shared
resource SpoolSummonsCode	code read-only shared
resource PageSizeControlCode	code read-only shared

resource ErrorBoxesUI		lmem discardable
resource SpoolAppUI		object
resource PrinterControlPanelUI	object
resource Strings		lmem data read-only shared
resource PageSizeData		lmem data read-only shared

resource AppTCMonikerResource	lmem read-only shared
resource AppTMMonikerResource	lmem read-only shared
resource AppTCGAMonikerResource	lmem read-only shared
resource PrintControlUI		object read-only shared
resource PrintControlToolboxUI	object read-only shared
resource ControlStrings		lmem data read-only shared

resource PrintUI		object read-only shared
resource SizeVerifyUI		object read-only shared
resource ProgressUI		object read-only shared

resource SpoolErrorBlock	lmem data read-only shared

resource AppSCMonikerResource	lmem read-only shared
resource AppSMMonikerResource	lmem read-only shared
resource AppSCGAMonikerResource	lmem read-only shared


resource PageSizeControlUI	object read-only shared
resource PageSizeToolboxUI	object read-only shared

ifdef PRINTING_DIALOG
resource PrintDialogUI		lmem read-only shared
endif

ifdef NONSPOOL
resource PaperFeedBoxUI		lmem read-only shared
endif

#
# Exported routines (and classes)
#
export	PrintControlClass
export	SpoolSummonsClass
export	SpoolChangeClass
export	SpoolApplicationClass
export	PageSizeControlClass
#
export	SpoolGetNumPaperSizes
export	SpoolGetPaperString
export	SpoolGetPaperSize
export	SpoolConvertPaperSize
export	SpoolGetPaperSizeOrder
export	SpoolSetPaperSizeOrder
export	SpoolCreatePaperSize
export	SpoolDeletePaperSize
#
export	SpoolGetNumPrinters
export	SpoolGetPrinterString
export	SpoolGetPrinterInfo
export	SpoolCreatePrinter
export	SpoolDeletePrinter
export	SPOOLGETDEFAULTPRINTER
export	SpoolSetDefaultPrinter
#
export	SpoolCreateSpoolFile
export	SpoolSetDocSize
#
export	SpoolAddJob
export	SpoolDelJob
export 	SpoolInfo
export	SpoolHurryJob
export	SpoolDelayJob
export	SpoolModifyPriority
export	SpoolVerifyPrinterPort
#
export	SpoolMapToPrinterFont
export	SpoolUpdateTranslationTable
#
# uiC.asm routines
#
export	SPOOLSETDOCSIZE
#
# Move to correct place later
#
export	SpoolGetDefaultPageSizeInfo
export	SpoolSetDefaultPageSizeInfo
export	SPOOLGETDEFAULTPAGESIZEINFO
export	SPOOLSETDEFAULTPAGESIZEINFO

incminor

publish	SPOOLGETNUMPAPERSIZES
publish	SPOOLGETPAPERSTRING
publish	SPOOLGETPAPERSIZE
publish	SPOOLCONVERTPAPERSIZE
publish	SPOOLGETPAPERSIZEORDER
publish	SPOOLSETPAPERSIZEORDER
publish	SPOOLCREATEPAPERSIZE
publish	SPOOLDELETEPAPERSIZE
#
publish	SPOOLGETNUMPRINTERS
publish	SPOOLGETPRINTERSTRING
publish	SPOOLCREATEPRINTER
publish	SPOOLDELETEPRINTER
publish	SPOOLSETDEFAULTPRINTER
#
publish	SPOOLCREATESPOOLFILE
#
publish	SPOOLDELJOB
publish	SPOOLINFO
publish	SPOOLHURRYJOB
publish	SPOOLDELAYJOB
publish	SPOOLMODIFYPRIORITY
publish	SPOOLVERIFYPRINTERPORT
#
incminor PostZoomerMessages
#
# XIP-enabled
#
export SizeVerifyDialogClass
incminor
#
incminor SpoolNewPost21
#
export SpoolEMOMClass
incminor
#
export SpoolPrinterNameToMedium
incminor SpoolMailboxSupport
