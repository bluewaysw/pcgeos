
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Mono module of the vidmem video driver
FILE:		monoTables.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	12/91	initial version


DESCRIPTION:
	This file contains a few tables used by the Mono module of the
	vidmem video driver.

	$Id: monoTables.asm,v 1.1 97/04/18 11:42:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;----------------------------------------------------------------------------
;		Driver jump table (used by DriverStrategy)
;----------------------------------------------------------------------------

driverJumpTable	label	word
	dw	0				; intiialization
	dw	0				; last gasp
	dw	0				; suspend
	dw	0				; unsuspend
	dw	0				; test for device existance
	dw	0				; set device type
	dw	0				; get ptr to info block
	dw	0				; get exclusive
	dw	0				; start exclusive
	dw	0				; end exclusive

	dw	offset Mono:VidGetPixel		; get a pixel color
	dw	offset Mono:MonoCallMod		; GetBits in another module
	dw	0				; set the ptr pic
	dw	0				; hide the cursor
	dw	0				; show the cursor
	dw	0				; move the cursor
	dw	0				; set save under area
	dw	0				; restore save under area
	dw	0				; nuke save under area
	dw	0				; request save under
	dw	0				; check save under
	dw	0				; get save under info
	dw	0		 		; check s.u. collision
	dw	0				; set xor region
	dw	0				; clear xor region

	dw	offset Mono:VidDrawRect		; rectangle
	dw	offset Mono:VidPutString	; char string
	dw	offset Mono:MonoCallMod		; BitBlt in another module
	dw	offset Mono:MonoCallMod		; PutBits in another module
	dw	offset Mono:MonoCallMod		; DrawLine in another module
	dw	offset Mono:VidDrawRegion	; draws a region
	dw	offset Mono:MonoCallMod		; PutLine in another module
	dw	offset Mono:MonoCallMod		; Polygon in another module
	dw	0				; ScreenOn in another module
	dw	0				; ScreenOff in another module
	dw	offset Mono:MonoCallMod		; Polyline in another module
	dw	offset Mono:MonoCallMod		; Polyline in another module
	dw	offset Mono:MonoCallMod		; Polyline in another module
	dw	0				; SetPalette
	dw	0				; GetPalette
.assert ($-driverJumpTable) eq VidFunction

	; this table holds offsets to the routines in different modules
moduleTable	label	fptr
	fptr	0 				; intiialization
	fptr	0				; last gasp
	fptr	0				; suspend
	fptr	0				; unsuspend
	fptr	0				; test for device existance
	fptr	0				; set device type
	fptr	0				; get ptr to info block
	fptr	0				; get exclusive
	fptr	0				; start exclusive
	fptr	0				; end exclusive

	fptr	0				; get a pixel color
	fptr	MonoMisc:VidGetBits  		; GetBits in another module
	fptr	0				; set the ptr pic
	fptr	0				; hide the cursor
	fptr	0				; show the cursor
	fptr	0				; move the cursor
	fptr	0				; set save under area
	fptr	0				; restore save under area
	fptr	0				; nuke save under area
	fptr	0				; request save under
	fptr	0				; check save under
	fptr	0				; get save under info
	fptr	0		 		; check s.u. collision
	fptr	0				; set xor region
	fptr	0				; clear xor region

	fptr	0				; rectangle
	fptr	0				; char string
	fptr	MonoBlt:VidBitBlt		; BitBlt in another module
	fptr	MonoBitmap:VidPutBits  		; PutBits in another module
	fptr	MonoLine:VidDrawLine		; DrawLine in another module
	fptr	0				; draws a region
	fptr	MonoPutLine:VidPutLine		; PutLine in another module
	fptr	MonoLine:VidPolygon		; Polygon in another module
	fptr	0				; ScreenOn in another module
	fptr	0				; ScreenOff in another module
	fptr	MonoLine:VidPolyline		; Polyline in another module
	fptr	MonoLine:VidDashLine		; DashLine in another module
	fptr	MonoLine:VidDashFill		; DashFill in another module
	fptr	0				; SetPalette in another module
	fptr	0				; SetPalette in another module
.assert ($-moduleTable) eq (VidFunction*2)

;----------------------------------------------------------------------------
;		Video Semaphores
;----------------------------------------------------------------------------

videoSem	Semaphore	<1,0>

;------------------------------------------------------------------------------
;		Table of character drawing routines
;------------------------------------------------------------------------------

FCC_table	label	word
	dw	offset Mono:Char1In1Out	;load 1, draw 1
	dw	offset Mono:Char1In2Out	;load 1, draw 2
	dw	offset Mono:NullRoutine	;load 1, draw 3
	dw	offset Mono:NullRoutine	;load 1, draw 4

	dw	offset Mono:NullRoutine	;load 2, draw 1
	dw	offset Mono:Char2In2Out	;load 2, draw 2
	dw	offset Mono:Char2In3Out	;load 2, draw 3
	dw	offset Mono:NullRoutine	;load 2, draw 4

	dw	offset Mono:NullRoutine	;load 3, draw 1
	dw	offset Mono:NullRoutine	;load 3, draw 2
	dw	offset Mono:Char3In3Out	;load 3, draw 3
	dw	offset Mono:Char3In4Out	;load 3, draw 4

	dw	offset Mono:NullRoutine	;load 4, draw 1
	dw	offset Mono:NullRoutine	;load 4, draw 2
	dw	offset Mono:NullRoutine	;load 4, draw 3
	dw	offset Mono:Char4In4Out	;load 4, draw 4

