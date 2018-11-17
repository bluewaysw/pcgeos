##############################################################################
#
#	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Spreadsheet
# FILE:		spreadsheet.gp
#
# AUTHOR:	Gene, 2/91
#
#
# Parameters file for: spreadsheet.geo
#
#	$Id: ssheet.gp,v 1.1 97/04/07 11:14:46 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
name ssheet.lib
#
# Desktop stuff
#
longname "Spreadsheet Library"
tokenchars "SSHT"
tokenid 0
#
# Geode type
#
type	library, single

#
# Import other library definitions
#
library geos
library ui
library cell
library parse
library math
library ruler
#
# The Jedi version doesn't have any charting support.  But we can't test
# the GP_CHARTS symbol, because when library/driver clauses are processed,
# glue hasn't read any obj files yet.  So we'll have to test against
# the product symbol.
#
library chart

library text
library color
library ssmeta

#
# Define resources other than standard discardable code
#
nosort
resource DrawCode			code read-only shared
resource RulerCode			code read-only shared
resource RulerPrintCode			code read-only shared
resource InitCode			code read-only shared
resource SpreadsheetNameCode			code read-only shared
resource RareCode			code read-only shared
resource AttrCode			code read-only shared
resource EditCode			code read-only shared
resource SpreadsheetSortSpaceCode			code read-only shared
resource CommonCode			code read-only shared
resource NotesCode			code read-only shared
resource PrintCode			code read-only shared
resource SpreadsheetFormatCode			code read-only shared
resource HeaderFooterCode			code read-only shared
resource ExtentCode			code read-only shared
resource CutPasteCode			code read-only shared
resource SpreadsheetSearchCode			code read-only shared
resource SpreadsheetFunctionCode			code read-only shared
resource SpreadsheetChartCode			code read-only shared
resource EditBarControlCode			code read-only shared
resource EditBarMouseCode			code read-only shared
resource SortControlCode			code read-only shared
resource ChooseFuncControlCode			code read-only shared
resource DefineNameControlCode			code read-only shared
resource ChooseNameControlCode			code read-only shared
resource WidthControlCode			code read-only shared
resource EditControlCode			code read-only shared
resource HeaderControlCode			code read-only shared
resource BorderControlCode			code read-only shared
resource RecalcControlCode			code read-only shared
resource OptionsControlCode			code read-only shared
resource NoteControlCode			code read-only shared
resource FillControlCode			code read-only shared
resource ChartControlCode			code read-only shared
resource PointerImages read-only shared lmem
resource CutPasteStrings lmem shared read-only
ifdef GPC
resource SearchStrings lmem shared read-only
endif
resource EditBarControlUI	object 
resource EditBarControlToolUI	object 
resource ControlStrings lmem read-only shared
resource AppTCMonikerResource ui-object read-only shared
resource AppTMMonikerResource ui-object read-only shared
resource AppTCGAMonikerResource ui-object read-only shared
resource SSSortControlUI	object
resource SSSortControlToolboxUI	object
resource SSChooseFuncControlUI	object
resource StringsUI	lmem shared read-only
resource SSDefineNameControlUI	object
resource SSChooseNameControlUI	object
resource SSColumnWidthUI	object
resource SSRowHeightUI	object
resource SSEditUI	object
resource SSEditToolUI	object
resource SSHeaderUI	object
resource SSBorderUI	object
resource SSRecalcUI	object
resource SSRecalcToolUI	object
resource SSOptionsControlUI	object
resource SSNoteControlUI	object
resource SSFillUI	object
ifdef GP_CHARTS
resource SSChartUI	object
resource SSChartToolUI	object
endif
resource ECCode		code read-only shared
ifdef GP_FULL_EXECUTE_IN_PLACE
resource SpreadsheetControlInfoXIP	read-only shared
endif
resource SpreadsheetClassStructures	read-only fixed shared

#
# Define library entry point
#
entry SpreadsheetEntry

#
# Exported Classes
#
export	SpreadsheetClass
export	SpreadsheetRulerClass
export	SSEditBarControlClass
export	EBCEditBarClass
export	SSSortControlClass
export	SSChooseFuncControlClass
export	SSDefineNameControlClass
export	SSChooseNameControlClass
export  SSColumnWidthControlClass
export  SSRowHeightControlClass
export	SSEditControlClass
export	SSHeaderFooterControlClass
export	SSBorderControlClass
export	SSBorderColorControlClass
export	SSRecalcControlClass
export	SSOptionsControlClass
export	SSNoteControlClass
export	SSFillControlClass
export	SSChartControlClass
export	SSDNTextClass

#
# Exported Routines
#
export	SpreadsheetInitFile
export	SpreadsheetCheckShortcut
export	SpreadsheetGetTokenByStyle
export	SpreadsheetDeleteStyleByToken
export	SpreadsheetGetStyleByToken
export	SpreadsheetGetAttrByToken
export	SPREADSHEETINITFILE
export	SPREADSHEETPARSENAMETOTOKEN
export	SPREADSHEETPARSECREATECELL
export	SPREADSHEETPARSEEMPTYCELL
export	SPREADSHEETPARSEDEREFCELL
export	SPREADSHEETNAMETEXTFROMTOKEN
export	SPREADSHEETNAMETOKENFROMTEXT
export	SPREADSHEETNAMELOCKDEFINITION
export	SPREADSHEETCELLADDREMOVEDEPS
export	SPREADSHEETRECALCDEPENDENTS
export	SpreadsheetClearRange

incminor SSheetNewForRedwood

# this is for the cell protection added
incminor

skip 1

incminor

skip 2

incminor ModifyNumFormat
