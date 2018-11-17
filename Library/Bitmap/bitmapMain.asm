COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Bitmap Library
FILE:		bitmapMain.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	2/91		Initial Version

DESCRIPTION:
	This file manages the .asm files that implement the VisBitmap object

RCS STAMP:
$Id: bitmapMain.asm,v 1.1 97/04/04 17:43:40 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

_Library		= 1

;Standard include files


include	geos.def
include geode.def
include ec.def
include geoworks.def
include	library.def
include geode.def

ifdef FULL_EXECUTE_IN_PLACE
include Internal/xip.def
endif

include resource.def

include object.def
include	graphics.def
include Internal/grWinInt.def
include gstring.def
include	win.def
include heap.def
include lmem.def
include timer.def
include timedate.def
include	system.def
include	file.def
include	fileEnum.def
include	vm.def
include hugearr.def
include thread.def
include Objects/inputC.def
include bitmapConstant.def
include driver.def
include initfile.def

include myMacros.def


;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib	ui.def
UseLib	Objects/vTextC.def


;------------------------------------------------------------------------------
;			Library we're defining
;------------------------------------------------------------------------------

DefLib	bitmap.def
UseLib	grobj.def


;------------------------------------------------------------------------------
;			Code to implement this library
;------------------------------------------------------------------------------

include uiManager.rdef

include pointerImages.asm
include bitmap.asm
include bitmapUndo.asm
include bitmapTransfer.asm
include bitmapUI.asm
include bitmapAnts.asm
include bitmapUtils.asm
include bitmapGState.asm
include backupProcess.asm
include bitmapKeyboard.asm

include fatbits.asm

include visTextForBitmaps.asm

include tool.asm
include dragTool.asm
include	lineTool.asm
include rectTool.asm
include drawRectTool.asm
include ellipseTool.asm
include drawEllipseTool.asm
include pencilTool.asm
include eraserTool.asm
include floodFillTool.asm
include textTool.asm
include selectionTool.asm
include fatbitsTool.asm

include uiToolControl.asm
include uiFormatControl.asm

include bitmapC.asm

idata	segment
idata	ends

udata	segment
udata	ends

BitmapBasicCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CardsEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry procedure for the cards library. Since we don't need
		to do anything special for our clients, we just clear the
		carry to indicate our happiness.

CALLED BY:	Kernel
PASS:		di	= LibraryCallType
				LCT_ATTACH	= library just loaded
				LCT_NEW_CLIENT	= client of the library just
						  loaded
				LCT_CLIENT_EXIT	= client of the library is
						  going away
				LCT_DETACH	= library is about to be
						  unloaded
		cx	= handle of client geode, if LCT_NEW_CLIENT or
			  LCT_CLIENT_EXIT
RETURN:		carry set on error
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		
;
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	global	BitmapEntry:far	; so Esp won't whine
BitmapEntry	proc	far
	clc
	ret
BitmapEntry	endp

BitmapBasicCode	 ends

