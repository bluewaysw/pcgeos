##############################################################################
#
#	Copyright (c) Geoworks 1996 -- All Rights Reserved
#
# PROJECT:	
# FILE:		uigenerator.gp
#
# AUTHOR:	Edwin Yu, Apr 23, 1996
#
#
# 
#
#	$Id: uigenera.gp,v 1.15.1.3 97/09/23 18:50:33 kkee Exp $
#
##############################################################################
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name    uigenera.lib
#
# Long filename: this name can be displayed by GeoManager, and is used to 
# identify the application for inter-application communication.
#
longname        "UI Generator Library"
tokenchars      "UIGN"
tokenid         0
#
#       Specify geode type
#
type            library, single
#
#       Libraries
#
library geos
library ui
library ansic
library text
library pmanager
library htcore
library htmem
#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource MOUSEIMAGE      read-only shared data
resource BMPDATA      read-only shared data
#
#       Export routines:
#
export HTGenImageClass
export HTGenTextClass
export HTGenFormTextClass
export HTGenFormTriggerClass
export HTGenOptionClass
export HTGenInputClass
export HTGenSelectClass
export HTGenHtmlContentClass
export TextAreaClass
export TextAreaTextClass
export HTGenMultiLineSelectClass
export HTOtherOptionClass
export HTGenHRClass
export HTGenTableClass
export HTGenTCellClass
export HTGenFormClass
export HTGenOuterSelectClass
export HTGenCaptionClass
export HTGenFormHiddenClass

export UINewDoc
export UIDeleteDoc
export UISetCurrentDoc
export UIResetCurrentDoc
export UIDocTitle
export UICurrentBaseURL
export UIGotoNextFocusableField
export UISubmitForm
export UIDocSize
export UIDocPrint
export UIDocSearch
export UIDocCopySelected
export UIDocMemoryNeeded


export UIGen_START_TITLE
export UIGen_END_TITLE
export UIGen_CREATE_BASE
export UIGen_CREATE_HR
export UIGen_APPEND_TEXT_PTR
export UIGen_CREATE_TEXT_OBJECT
export UIGen_START_FORM
export UIGen_END_FORM
export UIGen_START_SELECT
export UIGen_END_SELECT
export UIGen_CREATE_OPTION
export UIGen_CREATE_INPUT
export UIGen_START_TEXTAREA
export UIGen_END_TEXTAREA
export UIGen_START_TABLE
export UIGen_END_TABLE
export UIGen_START_CAPTION
export UIGen_END_CAPTION
export UIGen_START_TR
export UIGen_CREATE_TH
export UIGen_CREATE_TD
export UIGen_CREATE_IMAGE
export UIGen_START_MAP
export UIGen_END_MAP
export UIGen_CREATE_AREA
export UIGen_END_FORMAT
export UIGen_GET_CONTENT
export UIGen_START_BOLD
export UIGen_START_ITALIC
export UIGen_START_STRIKE
export UIGen_START_SUPERSCRIPT
export UIGen_START_SUBSCRIPT
export UIGen_START_FONT_SIZE
export UIGen_START_ADDRESS
export UIGen_END_ADDRESS
export UIGen_CHANGE_SMALL_FONT
export UIGen_CHANGE_BIG_FONT
export UIGen_SET_BASEFONT
export UIGen_ADD_BR
export UIGen_START_HEADER
export UIGen_START_FIXED_WIDTH_FONT
export UIGen_START_PRE
export UIGen_START_UNORDERED_LIST
export UIGen_END_LIST
export UIGen_START_ORDERED_LIST
export UIGen_CREATE_LIST_ITEM
export UIGen_CREATE_UNORDERED_LIST_ITEM
export UIGen_CREATE_ORDERED_LIST_ITEM
export UIGen_START_DEFINITION_LIST
export UIGen_CREATE_DEFINITION_DT
export UIGen_CREATE_DEFINITION_DD
export UIGen_START_BLOCKQUOTE
export UIGen_START_CENTER
export UIGen_END_ALIGN
export UIGen_START_PARAGRAPH
export UIGen_START_DIV
export UIGen_START_NOBR
export UIGen_END_NOBR
export UIGen_START_ANCHOR
export UIGen_PROCESS_A_ATTRIBUTE
export UIGen_END_HTML
export UIGen_CREATE_SINGLE_IMAGE
export UIGen_BROADCAST_RESIZE_POSITION
