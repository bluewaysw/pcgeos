COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		textstorageManager.asm

AUTHOR:		John Wedgwood, Nov 19, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/19/91	Initial revision

DESCRIPTION:
	Manager file for the text storage module.

	$Id: textstorageManager.asm,v 1.1 97/04/07 11:22:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include	textGeode.def
include texttext.def
include textstorage.def
include textssp.def
include textattr.def
include textselect.def
include textgr.def
include texttrans.def

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include	tsConstant.def

;-----------------------------------------------------------------------------
;	Include variables and tables for this module
;-----------------------------------------------------------------------------

include	tsVariables.asm

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------
if	ERROR_CHECK
include	tsEC.asm		; Error checking code
endif

include	tsUtils.asm		; Misc utility routines
include	tsReference.asm		; Code for accessing text references

include tsEnum.asm

;
; Code for creating/destroying text storage.
;
include	tsSmallCreDest.asm
include	tsLargeCreDest.asm

;
; Various routines for accessing text in text objects.
;
include	tsSmallAccess.asm	; Access routines for small text objects
include	tsLargeAccess.asm	; Access routines for large text objects
include	tsSmallGetText.asm	; Getting text from small text objects
include	tsLargeGetText.asm	; Getting text from large text objects

;
; Various routines for modifying text in text objects.
;
include	tsSmallModify.asm	; Modification routines for small text objects
include	tsLargeModify.asm	; Modification routines for large text objects

;
; Routines for finding text in text objects.
;
include	tsSmallFind.asm		; Find routines for small text objects
include	tsLargeFind.asm		; Find routines for large text objects

;
; Routines for checking, skipping, etc classes of characters.
;
include	tsCharClassUtils.asm
include	tsSmallCharClass.asm
include	tsLargeCharClass.asm

;
; Mysterious "other" files.
;
include	tsParams.asm		; Manipulates VisTextReplaceParameters struct

;
; Routines to load from/save to DB items
;
include tsLoadSave.asm

include	tsExternal.asm
