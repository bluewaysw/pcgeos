COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) New Deal 1999 -- All Rights Reserved

PROJECT:	GeoSafari
FILE:		safariGame.asm

AUTHOR:		Gene Anderson

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	9/25/98		Initial revision

DESCRIPTION:
	Code for GameCardClass

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include safariGeode.def
include safariConstant.def

idata	segment
	GameCardClass
idata	ends

CommonCode	segment	resource

GetGameCardOffset	proc	near
		mov	di, ds:[si]
		add	di, ds:[di].GameCard_offset
		ret
GetGameCardOffset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameCardRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize the game card

CALLED BY:	MSG_VIS_RECALC_SIZE

PASS:		none
RETURN:		cx - width
		dx - height
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/3/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

GameCardRecalcSize	method dynamic	GameCardClass,
					MSG_VIS_RECALC_SIZE
		mov	cx, SAFARI_GAME_CARD_WIDTH
		mov	dx, SAFARI_GAME_CARD_HEIGHT
		ret
GameCardRecalcSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameCardDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the game card

CALLED BY:	MSG_VIS_DRAW

PASS:		bp - handle of GState
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/3/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

GameCardDraw	method dynamic	GameCardClass,
					MSG_VIS_DRAW
		uses	si

		mov	di, bp
		.enter

		call	GrSaveState
	;
	; any bitmap?
	;
		mov	bx, ds:[si]
		add	bx, ds:[bx].GameCard_offset
		cmp	ds:[bx].GCI_bitmapType, GCBT_NO_BITMAP
		je	drawLogo
		mov	cx, ds:[bx].GCI_bitmapHan
		tst	cx
		jz	drawLogo
	;
	; get the correct file
	;
		push	cx
		cmp	ds:[bx].GCI_bitmapType, GCBT_IMPORTED_BITMAP
		mov	bx, ds:[bx].GCI_fileHan
		jne	gotFile
		call	ClipboardGetClipboardFile
gotFile:
		push	bx
	;
	; draw a grey background
	;
		mov	ax, C_BLUE
		call	GrSetAreaColor
		call	VisGetBounds
		call	GrFillRect
	;
	; set a clip rectangle to handle wayward quizzes
	;
		mov	si, PCT_INTERSECTION
		call	GrSetClipRect
	;
	; draw the bitmap
	;
		pop	dx			;dx <- VM file handle
		pop	cx			;cx <- VM block
		call	DrawBitmapFile

doneDraw:
		call	GrRestoreState

		.leave
		ret

	;
	; no bitmap, draw the logo
	;
drawLogo:
		call	DrawLogoScreen
		jmp	doneDraw
GameCardDraw	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawLogoScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize 

CALLED BY:	GameCardDraw

PASS:		*ds:si - GameCard object
		di - handle of GState
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/3/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

DrawLogoScreen	proc	near
		class	GameCardClass
		.enter

		mov	ax, C_BLUE
		call	GrSetAreaColor
	;
	; draw a rectangle
	;
		call	VisGetBounds
		call	GrFillRect
	;
	; load the logo
	;
		call	LoadLogoBitmap
		jc	noLogoBitmap			;branch if error
	;
	; draw the logo centered
	;
gotBitmap::
		push	cx, dx
		call	VisGetBounds
if _NEW_LOGO
else
;
; new logo is full-screen: no need for centering code
;
		sub	cx, ax				;cx <- width
		sub	cx, LOGO_WIDTH			;cx <- remainder
		shr	cx, 1				;cx <- 1/2 remainder
		add	ax, cx				;ax <- new left
		sub	dx, bx				;dx <- height
		sub	dx, LOGO_HEIGHT			;dx <- remainder
		shr	dx, 1				;dx <- 1/2 remainder
		add	bx, dx				;bx <- new top
endif
		pop	cx, dx
		call	DrawBitmapFile
		mov	bx, dx				;dx <- VM file
		clr	al
		call	VMClose
noLogoBitmap:
if _NEW_LOGO
else
;
; new logo contains copyright text: no need for drawing code
;
	;
	; Draw some copyright text
	;
		mov	bx, COPYRIGHT_Y_1
		mov	dx, offset copyright1String
		call	DrawCenteredString
		mov	bx, COPYRIGHT_Y_2
		mov	dx, offset copyright2String
		call	DrawCenteredString
endif

		.leave
		ret
DrawLogoScreen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameCardSetPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the path for bitmaps, files, etc.

CALLED BY:	MSG_GAME_CARD_SET_PATH

PASS:		cx:dx - ptr to PathName
		bp - StandardPath
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/5/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

GameCardSetPath	method dynamic	GameCardClass,
					MSG_GAME_CARD_SET_PATH
		uses	ds, es, si, di
		.enter

	;
	; save the StandardPath
	;
		mov	ds:[di].GCI_stdPath, bp
	;
	; copy the PathName
	;
		segmov	es, ds
		lea	di, ds:[di].GCI_path
		mov	ds, cx
		mov	si, dx
		mov	cx, (size PathName)/(size word)
		rep	movsw

		.leave
		ret
GameCardSetPath	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameCardClearBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the bitmap for the game card

CALLED BY:	MSG_GAME_CARD_SET_BITMAP

PASS:		none
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/30/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

GameCardClearBitmap	method dynamic	GameCardClass,
					MSG_GAME_CARD_CLEAR_BITMAP
		clr	ax
		xchg	ax, ds:[di].GCI_bitmapHan
		tst	ax
		jz	noOldBitmap
	;
	; free the bitmap only if it is in the clipboard file
	; i.e.,	imported temporarily
	;
		cmp	ds:[di].GCI_bitmapType, GCBT_IMPORTED_BITMAP
		jne	noOldBitmap
		call	ClipboardGetClipboardFile
		call	SafariFreeBitmap
noOldBitmap:
		mov	ds:[di].GCI_bitmapType, GCBT_NO_BITMAP
		mov	ds:[di].GCI_bitmapHan, 0
		ret
GameCardClearBitmap	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameCardSetBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the bitmap for the game card

CALLED BY:	MSG_GAME_CARD_SET_BITMAP

PASS:		cx:dx - ptr to FileLongName
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/5/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

GameCardSetBitmap	method dynamic	GameCardClass,
					MSG_GAME_CARD_SET_BITMAP
		uses	es, di
		.enter

	;
	; copy the FileLongName	
	;
		push	ds, si
		segmov	es, ds
		lea	di, ds:[di].GCI_bitmap
		mov	ds, cx
		mov	si, dx
		mov	cx, (size FileLongName)/(size word)
		rep	movsw
		pop	ds, si
	;
	; free any old bitmap
	;
		mov	ax, MSG_GAME_CARD_CLEAR_BITMAP
		call	ObjCallInstanceNoLock
	;
	; load the new bitmap, if any
	;
		call	GetGameCardOffset
		tst	ds:[di].GCI_bitmap[0]
		jz	noNewBitmap
		call	FilePushDir
		mov	bx, ds:[di].GCI_stdPath		;bx <- StandardPath
		lea	dx, ds:[di].GCI_path		;dx:dx <- path
		call	FileSetCurrentPath
		push	si
		call	ClipboardGetClipboardFile	;bx <- VM file handle
		lea	si, ds:[di].GCI_bitmap
		call	ImportBitmapFile
		pop	si
		call	GetGameCardOffset
		mov	ds:[di].GCI_bitmapHan, ax
		mov	ds:[di].GCI_bitmapType, GCBT_IMPORTED_BITMAP
		call	FilePopDir
noNewBitmap:
	;
	; redraw ourselves (use MF_FORCE_QUEUE to avoid deadlock)
	;
		mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
		mov	ax, MSG_VIS_REDRAW_ENTIRE_OBJECT
		mov	bx, ds:OLMBH_header.LMBH_handle
		call	ObjMessage

		.leave
		ret
GameCardSetBitmap	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameCardSetImportedBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the bitmap for the game card from a pre-imported bitmap

CALLED BY:	MSG_GAME_CARD_SET_IMPORTED_BITMAP

PASS:		cx - VMBlockHandle
		dx - VM file handle
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/28/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

GameCardSetImportedBitmap	method dynamic	GameCardClass,
					MSG_GAME_CARD_SET_IMPORTED_BITMAP
	;
	; free any old bitmap
	;
		mov	ax, MSG_GAME_CARD_CLEAR_BITMAP
		call	ObjCallInstanceNoLock
	;
	; set the new bitmap
	;
		call	GetGameCardOffset
		mov	ds:[di].GCI_bitmapHan, cx
		mov	ds:[di].GCI_bitmapType, GCBT_IMBEDDED_BITMAP
	;
	; redraw ourselves (use MF_FORCE_QUEUE to avoid deadlock)
	;
		mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
		mov	ax, MSG_VIS_REDRAW_ENTIRE_OBJECT
		mov	bx, ds:OLMBH_header.LMBH_handle
		call	ObjMessage
		ret
GameCardSetImportedBitmap	endm

CommonCode	ends

