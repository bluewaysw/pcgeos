##############################################################################
#
#	Copyright (c) Geoworks 1997.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	Geos WWW Library
# FILE:		html.gp
#
# AUTHOR:	Kok Kin Kee, Sep 24, 1997
#
#
# HTML Converter.
#
#	$Id: html.gp,v 1.1.2.13 98/06/09 14:49:32 jeremyb Exp $
#
##############################################################################
#
#
# Permanent name: is required by Glue to set the permanent name and extension
# of the geode. The permanent name of a library is what goes in the imported
# library table of a geode (along with the protocol number). It is also
# what Swat uses to name the patient.
#
name html.lib

#
# Long filename: this name can be displayed by GeoManager, and is used to 
# identify the application for inter-application communication.
#
longname        "HTML Converter Library"
tokenchars      "HTML"
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
library htcore
library htmem


#
#  UI Classes
#
#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource MOUSEIMAGE      read-only shared data
resource BMPDATA      read-only shared data
resource ARROWBITMAP	read-only data
#
#       Export routines:
#
export HTGenViewClass
export HTGenImageClass
export HTGenTextClass
export HTGenFormTextClass
export HTGenFormTriggerClass
export HTGenInputClass
export HTMLSelectClass
export HTGenHtmlContentClass
export TextAreaClass
export TextAreaTextClass
export HTOtherOptionClass
export HTGenHRClass
export HTGenTableClass
export HTGenTCellClass
export HTGenCaptionClass
export PresentationManagerClass
export HTMLContentClass
export PMSearchCtrClass

#
# UIDoc APIs.
#

export UIDOCREGISTER
export UIDOCEXIT
export UIDOCCLEANMEMCACHE
export UINEWDOC
export UIFINDDOC
export UILOADDOC
export UIFREEDOC
export UIDELETEDOC
export UIDELETECURRENTDOC
export UILASTMODIFIEDTIME
export UIDOCCURRENTTITLE
export UIDOCCURRENTBASEURL
export UIDOCCURRENTURL
export UIGETFOCUSIMAGE
export UIGETNEXTIMAGE
export UIDOCGETFORMQUERY
export UIUNLOADIMAGE
export UIGETFOCUSLINK
export UIGOTONEXTFOCUSABLEFIELD
export UIDOCSIZE
export UIDOCPRINT
export UIDOCSEARCH
export UIDOCCOPYSELECTED
export UIDOCMEMORYNEEDED
export UpdateGlobalSearchVariables
export UIGETREFRESHTIMEANDURL
export UIDOCGETCURRENTDOCHANDLE
ifdef BROTHER_KERNEL
export GETPATHTOFOCUSIMAGE
endif

#
# UIDoc bulding APIs.
#
export UIGEN_START_TITLE
export UIGEN_END_TITLE
export UIGEN_CREATE_BASE
export UIGEN_CREATE_HR
export UIGEN_APPEND_TEXT_PTR
export UIGEN_CREATE_TEXT_OBJECT
export UIGEN_START_FORM
export UIGEN_END_FORM
export UIGEN_START_SELECT
export UIGEN_END_SELECT
export UIGEN_CREATE_OPTION
export UIGEN_CREATE_INPUT
export UIGEN_START_TEXTAREA
export UIGEN_END_TEXTAREA
export UIGEN_START_TABLE
export UIGEN_END_TABLE
export UIGEN_START_CAPTION
export UIGEN_END_CAPTION
export UIGEN_START_TR
export UIGEN_CREATE_TH
export UIGEN_CREATE_TD
export UIGEN_CREATE_IMAGE
export UIGEN_START_MAP
export UIGEN_END_MAP
export UIGEN_CREATE_AREA
export UIGEN_END_FORMAT
export UIGEN_END_FORMAT_TWICE
export UIGEN_GET_CONTENT
export UIGEN_START_BOLD
export UIGEN_START_ITALIC
export UIGEN_START_BOLD_ITALIC
export UIGEN_START_KBD
export UIGEN_START_STRIKE
export UIGEN_START_SUPERSCRIPT
export UIGEN_START_SUBSCRIPT
export UIGEN_START_FONT_SIZE
export UIGEN_START_ADDRESS
export UIGEN_END_ADDRESS
export UIGEN_CHANGE_SMALL_FONT
export UIGEN_CHANGE_BIG_FONT
export UIGEN_SET_BASEFONT
export UIGEN_ADD_BR
export UIGEN_START_HEADER6
export UIGEN_START_HEADER5
export UIGEN_START_HEADER4
export UIGEN_START_HEADER3
ifdef BROTHER_KERNEL
export UIGEN_START_HEADER2
export UIGEN_START_HEADER1
endif
export UIGEN_START_FIXED_WIDTH_FONT
export UIGEN_START_PRE
export UIGEN_START_UNORDERED_LIST
export UIGEN_END_LIST
export UIGEN_START_ORDERED_LIST
export UIGEN_CREATE_LIST_ITEM
export UIGEN_CREATE_UNORDERED_LIST_ITEM
export UIGEN_CREATE_ORDERED_LIST_ITEM
export UIGEN_START_DEFINITION_LIST
export UIGEN_CREATE_DEFINITION_DT
export UIGEN_CREATE_DEFINITION_DD
export UIGEN_START_BLOCKQUOTE
ifdef BROTHER_KERNEL
export UIGEN_START_BODY
endif
export UIGEN_START_CENTER
export UIGEN_END_ALIGN
export UIGEN_START_PARAGRAPH
export UIGEN_START_DIV
export UIGEN_START_NOBR
export UIGEN_END_NOBR
export UIGEN_START_ANCHOR
export UIGEN_PROCESS_A_ATTRIBUTE
export UIGEN_END_HTML
export UIGEN_CREATE_SINGLE_IMAGE
export UIGEN_BROADCAST_RESIZE_POSITION
export UIGEN_START_META

export UIDOCCURRENTVMFILEHANDLE
