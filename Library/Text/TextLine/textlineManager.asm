COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		textlineManager.asm

AUTHOR:		John Wedgwood, Nov 19, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/19/91	Initial revision

DESCRIPTION:
	Manager file for line manager.

 	$Id: textlineManager.asm,v 1.1 97/04/07 11:21:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include	textGeode.def
include texttext.def
include textattr.def
include textgr.def
include textstorage.def
include textregion.def
include textline.def
UseLib	spell.def


;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include	tlMacro.def
include	tlConstant.def

;-----------------------------------------------------------------------------
;	Include code
;-----------------------------------------------------------------------------

if	ERROR_CHECK
include	tlEC.asm
endif

;
; Storage related code
;
include	tlSmallStorage.asm
include	tlLargeStorage.asm

;
; Calculation related routines.
;
include	tlSmallCalc.asm
include	tlLargeCalc.asm

;
; Position related routines.
;
include	tlSmallPosition.asm
include	tlLargePosition.asm

;
; Drawing related routines
;
include	tlSmallDraw.asm
include	tlLargeDraw.asm

;
; Invert related routines
;
include	tlSmallInvert.asm
include	tlLargeInvert.asm

;
; Stuff related to getting offsets.
;
include tlSmallOffset.asm
include tlLargeOffset.asm

;
; Flag related stuff.
;
include	tlSmallFlags.asm
include	tlLargeFlags.asm

;
; Adjustment after replacement.
;
include	tlSmallAdjust.asm
include	tlLargeAdjust.asm

;
; Other information. Stuff like height and blo.
;
include	tlSmallLineInfo.asm
include	tlLargeLineInfo.asm

;
; Utility routines used by everyone.
;
include	tlUtils.asm
include	tlSmallUtils.asm
include	tlLargeUtils.asm
include	tlTabUtils.asm

;
; Code which operates on line and field structures directly and which is
; used by both the large and small line code.
;
include	tlCommonInit.asm	; Line/field initialization
include	tlCommonLineInfo.asm	; LineInfo access/modification
include	tlCommonFieldInfo.asm	; FieldInfo access/modification
include	tlCommonFlags.asm	; Flag access/modification
include	tlCommonAdjust.asm	; Adjust a line after a replacement
include	tlCommonOffset.asm	; Offset related stuff
include	tlCommonPosition.asm	; Position related stuff
include	tlCommonGState.asm	; GState related stuff
include	tlCommonInvert.asm	; Invert related stuff
include	tlCommonCalc.asm	; Calculation related stuff
include	tlCommonDrawExtendedStyles.asm	; Drawing related to extended styles
include	tlCommonDraw.asm	; Draw related stuff

include	tlExternal.asm		; All externally accessible routines

include	tlBorder.asm		; Border stuff
include	tlTabLine.asm		; Tab line stuff
include	tlTabLeader.asm		; Tab leader stuff
include	tlHyphenation.asm	; Auto-hyphenation stuff
