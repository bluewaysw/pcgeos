COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	Lights Out
MODULE:		Background Bitmaps
FILE:		saverBitmap.asm

AUTHOR:		Gene Anderson, Oct 29, 1991

ROUTINES:
	Name				Description
	----				-----------
GLBL	SaverDrawBGBitmap		Draw background bitmap

	VerifyBGFile			Verify file is a BG bitmap we can draw
	DrawBGBitmap			Do actual drawing of BG bitmap
	DestroyBGBitmap			Clean up after drawing BG bitmap
	SetBGPos			Set position and drawing mode

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	10/29/91	Initial revision

DESCRIPTION:
	Code for drawing background bitmaps as part of screen savers

	$Id: saverBitmap.asm,v 1.1 97/04/07 10:44:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SaverFadeCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverDrawBGBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a background bitmap
CALLED BY:	(GLOBAL)

PASS:		di - handle of GState to draw with
		ax - SaverBitmapMode for drawing
		(cx,dx) - width, height of Window to draw to
		bx - VM file handle
RETURN:		carry - set if error
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SaverDrawBGBitmap	proc	far
	uses	bx, si
	.enter

	;
	; verify the BG file
	;
	call	VerifyBGFile			;verify me jesus
	jc	quit				;branch if error
	;
	; Draw it as appropriate
	;
	call	DrawBGBitmap
	;
	; destroy the gstring and clean up
	;
	call	DestroyBGBitmap
	clc					;carry <- no error
quit:
	.leave
	ret
SaverDrawBGBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VerifyBGFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the passed file is something we can handle
CALLED BY:	SaverDrawBGBitmap()

PASS:		ds:si - ptr to NULL-terminated filename
RETURN:		carry - set if error
		bx - file handle
		si - gstring handle
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VerifyBGFile	proc	near
	uses	ax, cx, dx
	.enter

	;
	; Do sanity check on background file data
	;
	sub	sp, size GeodeToken
	mov	di, sp
	segmov	es, ss
	mov	ax, FEA_TOKEN
	mov	cx, size GeodeToken
	call	FileGetHandleExtAttributes
	cmp	{word}es:[di].GT_chars[0], 'B' or ('K' shl 8)
	jne	clearStackAndQuit
	cmp	{word}es:[di].GT_chars[2], 'G' or ('D' shl 8)
	jne	clearStackAndQuit
	
		CheckHack <size GeodeToken ge size ProtocolNumber>
	mov	ax, FEA_PROTOCOL
	mov	cx, size ProtocolNumber
	call	FileGetHandleExtAttributes
	cmp	es:[di].PN_major, BG_PROTO_MAJOR
	jne	clearStackAndQuit
	cmp	es:[di].PN_minor, BG_PROTO_MINOR
	jb	clearStackAndQuit
	
	add	sp, size GeodeToken
	;
	; Try to get the data...
	;
	call	VMGetMapBlock			;ax <- VM handle of map block
	push	bp
	call	VMLock				;lock the map block
	mov	ds, ax				;ds <- seg addr of map block
	mov	si, ds:[FBGMB_data]		;si <- VM handle of start
	cmp	ds:[FBGMB_type], FBGFT_STANDARD_GSTRING
	call	VMUnlock			;unlock the map block (flags OK)
	pop	bp
	jne	closeAndQuit			;branch if we don't understand
	;
	; Create a graphics string out of the data
	;
	mov	cl, GST_VMEM			;cl <- GStringType
	call	GrLoadGString
	clc					;carry <- no error
	jmp	quit

clearStackAndQuit:
	add	sp, size GeodeToken

closeAndQuit:
	stc					;carry <- error
quit:

	.leave
	ret
VerifyBGFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawBGBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the BG file as specififed
CALLED BY:	SaverDrawBitmap()

PASS:		bx - VM file handle
		si - gstring handle
		di - gstate handle
		(cx,dx) - width, height of Window
		ax - SaverBitmapMode
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawBGBitmap	proc	near
	uses	ax, bx, cx, dx
lwinWidth	local	word	push	cx
lwinHeight	local	word	push	dx
drawMode	local	SaverBitmapMode	push	ax
BGWidth		local	word
BGHeight	local	word
xOff		local	word
	.enter

	;
	; Copy gstring information out of map block
	;

	call	VMGetMapBlock
	mov	dx, bp				;dx <- offset to locals
	call	VMLock
	xchg	dx, bp				;dx <- mem handle
						;bp <- ptr to locals
	mov	ds, ax
	mov	ax, ds:[FBGMB_width]
	mov	ss:BGWidth, ax
	mov	ax, ds:[FBGMB_height]
	mov	ss:BGHeight, ax
	xchg	dx, bp				;dx <- ptr to locals 
						;bp <- mem handle
	call	VMUnlock
	mov	bp, dx				;bp <- ptr to locals
	;
	; Set start position and tiling flags
	;
	call	SetBGPos
	mov	ss:xOff, ax			;save start x
	;
	; Draw the graphic
	;
yLoop:
	mov	ax, ss:xOff			;ax <- starting x
xLoop:
	push	bp, ax
	clr	bp
	call	GrDrawGString
	mov	al, GSSPT_BEGINNING
	call	GrSetGStringPos
	pop	bp, ax
	;
	; Are we tiling?
	;
	cmp	ss:drawMode, SAVER_BITMAP_TILE	;tiling?
	jne	exit				;if not tiled, done
	;
	; Tile until done...
	;
	add	ax, ss:BGWidth			;ax <- next x position
	cmp	ax, ss:lwinWidth		;to right edge?
	jb	xLoop				;branch if not
	add	bx, ss:BGHeight			;bx <- next y position
	cmp	bx, ss:lwinHeight		;to bottom edge?
	jb	yLoop				;branch if not
exit:
	.leave
	ret
DrawBGBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetBGPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set start position for BG and tiling mode
CALLED BY:	DrawBGFile()

PASS:		ss:bp - inherited locals
RETURN:		(ax,bx) - starting (x,y) position
		ss:drawMode - SaverBitmapMode
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetBGPos	proc	near
	.enter	inherit	DrawBGBitmap

	cmp	ss:drawMode, SAVER_BITMAP_TILE
	je	tileBitmap
	cmp	ss:drawMode, SAVER_BITMAP_CENTER
	je	centerBitmap
	cmp	ss:drawMode, SAVER_BITMAP_UPPER_LEFT
	je	upperLeft
	;
	; "Do the right thing" based on the size of the bitmap compared
	; with the size of the window.  If it is over half as big as
	; the window, then center it, otherwise tile it.
	;
	mov	dx, ss:lwinWidth
	shr	dx, 1				;dx <- (window width)/2
	cmp	ss:BGWidth, dx			;bitmap >= 1/2 of window?
	jb	tileBitmap			;branch if not
	mov	dx, ss:lwinHeight
	shr	dx, 1				;dx <- (window height)/2
	cmp	ss:BGHeight, dx			;bitmap >= 1/2 of window?
	jae	centerBitmap			;branch if so
	;
	; Tiling the bitmap...set the start (x,y) to the upper left
	;
tileBitmap:
	mov	ss:drawMode, SAVER_BITMAP_TILE
upperLeft:
	clr	ax
	clr	bx				;(ax,bx) <- start (x,y) pos
done:
	.leave
	ret

	;
	; Centering the bitmap...set the start (x,y) appropriately
	;
centerBitmap:
	mov	ss:drawMode, SAVER_BITMAP_CENTER
	clr	ax
	mov	dx, ss:lwinWidth		;dx <- window width
	sub	dx, ss:BGWidth			;dx <- border
	jc	bigX				;branch if bitmap > width
	shr	dx, 1				;dx <- border / 2
	mov	ax, dx				;ax <- start x
bigX:
	clr	bx
	mov	dx, ss:lwinHeight		;dx <- window height
	sub	dx, ss:BGHeight			;dx <- border
	jc	bigY				;branch if bitmap > height
	shr	dx, 1				;dx <- border / 2
	mov	bx, dx				;bx <- start y
bigY:
	jmp	done
SetBGPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroyBGBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up
CALLED BY:	SaverDrawBitmap()

PASS:		si - gstring handle
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DestroyBGBitmap	proc	near
	uses	dx, di
	.enter

	mov	di, si				;di <- gstring handle
	mov	dl, GSKT_LEAVE_DATA		;dl <- GStringKillType
	call	GrDestroyGString

	.leave
	ret
DestroyBGBitmap	endp

SaverFadeCode	ends
