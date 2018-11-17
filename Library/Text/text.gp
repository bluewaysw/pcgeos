##############################################################################
#
#	Copyright (c) Berkeley Softworks 1990, 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Text Library
# FILE:		text.gp
#
# AUTHOR:	Doug Fults,  1/19/91
#
#	$Id: text.gp,v 1.2 98/03/24 21:20:33 gene Exp $
#
##############################################################################
#
# Permanent name
#
name text.lib

library geos
library ui
library styles
library color
library ruler
library bitmap 	noload
ifdef PRODUCT_RESPONDER
library foam 	noload
endif	# PRODUCT_RESPONDER


#
# Specify geode type
#
type	library, single

#
# Define the library entry point
#
entry TextLibraryEntry

#
# Desktop-related things
#
longname	"Text Library"
tokenchars	"TEXL"
tokenid		0

#
# Define resources other than standard discardable code
#
nosort
resource TextFixed 			fixed code read-only

resource Text				code read-only shared
resource TextBorder			code read-only shared
resource TextAttributes			code read-only shared
resource TextTransfer			code read-only shared
resource TextFilter			code read-only shared
resource TextDrawCode			code read-only shared
resource RulerCommon			code read-only shared
resource RulerCode			code read-only shared
resource TextInstance			code read-only shared
resource TextSelect			code read-only shared
resource TextGraphic			code read-only shared
resource TextStorageCode		code read-only shared
resource TextStyleSheet			code read-only shared
resource TextControlCommon		code read-only shared
resource TextNameType			code read-only shared
resource PenCode			code read-only shared
resource TextSearchSpell		code read-only shared
resource TextRegion			code read-only shared
resource TextObscure			code read-only shared
resource TextUndo			code read-only shared
resource TextControlCode		code read-only shared
resource TextControlInit		code read-only shared
resource TextC				code read-only shared
resource TextCursor			code read-only shared

ifndef GP_NO_CONTROLLERS
resource TextSRControlCommon		code read-only shared
resource TextSRControlCode		code read-only shared
resource TextHelpControlCode		code read-only shared
endif

resource TextStrings 			lmem read-only shared
resource TextTypeStrings 		lmem read-only shared
resource RulerBitmapUI 			lmem read-only shared
resource UndoStrings 			lmem read-only shared
resource TextStyleStrings 		lmem read-only shared
resource TextTransStrings 		lmem read-only shared

ifndef GP_NO_CONTROLLERS
resource AppTCMonikerResource 		ui-object read-only shared
resource AppTMMonikerResource 		ui-object read-only shared
resource AppTCGAMonikerResource 	ui-object read-only shared

resource TextStyleControlUI 		ui-object read-only shared
resource TextStyleControlToolboxUI 	ui-object read-only shared
resource ControlStrings 		lmem read-only shared

resource FontControlUI 			ui-object read-only shared
resource FontControlToolboxUI 		ui-object read-only shared
resource PointSizeControlUI 		ui-object read-only shared
resource PointSizeControlToolboxUI 	ui-object read-only shared
resource FontAttrControlUI 		ui-object read-only shared

resource JustificationControlUI 	ui-object read-only shared
resource JustificationControlToolboxUI 	ui-object read-only shared
resource ParaSpacingControlUI 		ui-object read-only shared
resource LineSpacingControlUI 		ui-object read-only shared
resource LineSpacingControlToolboxUI 	ui-object read-only shared
resource DefaultTabsControlUI 		ui-object read-only shared
resource DropCapControlUI 		ui-object read-only shared
resource ParaAttrControlUI 		ui-object read-only shared
resource BorderControlUI 		ui-object read-only shared
resource HyphenationControlUI 		ui-object read-only shared
resource HyphenationControlToolboxUI 	ui-object read-only shared
resource MarginControlUI 		ui-object read-only shared
resource TabControlUI 			ui-object read-only shared
resource TextCountControlUI 		ui-object read-only shared
resource TextStyleSheetControlUI 	ui-object read-only shared
resource SearchReplaceControlUI 	ui-object read-only shared
resource SearchReplaceControlToolboxUI 	ui-object read-only shared
resource TextRulerControlUI 		ui-object read-only shared
resource TextHelpControlUI 		ui-object read-only shared

ifdef PROFILE_TIMES
resource TextProfile                    fixed
endif

endif		# ndef GP_NO_CONTROLLERS

#resource TextPositionControlUI 	ui-object read-only shared

ifdef	USE_FEP
resource TextInit				code read-only shared
resource TextFep				code read-only shared
endif

ifdef GP_FULL_EXECUTE_IN_PLACE
ifndef GP_NO_CONTROLLERS
resource ControlInfoXIP			read-only shared
endif		# ndef GP_NO_CONTROLLERS
resource TabLeaderStringsXIP		read-only shared
endif

resource TextClassStructures		fixed read-only shared

#
# Export routines
#
export VisTextClass
export TextMapDefaultCharAttr
export TextFindDefaultCharAttr
export TextMapDefaultParaAttr
export TextFindDefaultParaAttr
export TextGetSystemCharAttrRun

export TextAllocClipboardObject
export TextFinishWithClipboardObject

export TextStyleControlClass

export TextSearchInString
export TextSearchInHugeArray

export TEXTSEARCHINSTRING
export TEXTSEARCHINHUGEARRAY
export FontControlClass
export PointSizeControlClass
export CharFGColorControlClass
export CharBGColorControlClass
export FontAttrControlClass

export JustificationControlClass
export ParaSpacingControlClass
export DefaultTabsControlClass
export ParaBGColorControlClass
export ParaAttrControlClass
export BorderControlClass
export BorderColorControlClass
export DropCapControlClass
export HyphenationControlClass

#export TextPositionControlClass
#export TextCountControlClass

export TextStyleSheetControlClass
export SearchReplaceControlClass
export TextRulerClass

export MarginControlClass
export TabControlClass

#export TextSendSearchNotification
#export TEXTSENDSEARCHNOTIFICATION

export TEXTALLOCCLIPBOARDOBJECT
export TEXTFINISHWITHCLIPBOARDOBJECT

export TextRulerControlClass
export VisLargeTextClass

export TextHelpControlClass
export TextCountControlClass

export VISTEXTFORMATNUMBER

export TextSuspendOnApplyInteractionClass	# used internally only

export TextSetSpellLibrary
export TEXTSETHYPHENATIONCALL

export LineSpacingControlClass

export NoGraphicsTextClass

incminor TextNewForZoomer

export VTFClearSmartQuotes

incminor

publish TEXTMAPDEFAULTCHARATTR
publish TEXTFINDDEFAULTCHARATTR
publish TEXTMAPDEFAULTPARAATTR
publish TEXTFINDDEFAULTPARAATTR
publish TEXTGETSYSTEMCHARATTRRUN

publish MSGVISLARGETEXTREGIONFROMPOINT
publish MSGVISTEXTLOADSTYLESHEETPARAMS

incminor TextNewForHelpEditor

export	VisTextGraphicCompressGraphic
#
# XIP-enabled
#

incminor TextNewForCondo
incminor TextNewForPizza
incminor TextNewerForCondo
incminor TextNewForQuickFax
incminor TextNewFor2_1
incminor TextEvenNewerForCondo
incminor TextNew2ForPizza
incminor TextNew4ForCondo

# Adding new error string to TextTypeStrings
incminor

incminor TextNewForJedi

incminor TextNewForResponder

incminor TextNewForLeia

incminor TextNewForDove

incminor TextNewForPenelope

incminor TextFullWidthFilters

incminor TemplateWizard

ifdef GPC_SEARCH
export OverrideCenterOnMonikersClass
endif

incminor TextNewForWM
incminor TextShowSelectionAtTop
incminor TextNewForGPC
