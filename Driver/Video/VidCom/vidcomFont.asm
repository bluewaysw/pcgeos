COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		video driver
FILE:		vidcomFont.asm

AUTHOR:		Gene Anderson, June 6th, 1989

ROUTINES:
	Name			Description
	----			-----------
	VidBuildChar		exit the video driver, build a char, return
	SaveVidState		save a table of values
	RestoreVidState		restore table of values
	DoComplexMove		transform character position for complex case
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/11/89		Initial revision

DESCRIPTION:
	This file contains routines for dealing with outline fonts.
		
	$Id: vidcomFont.asm,v 1.1 97/04/18 11:41:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidBuildChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exit the video driver, build a character, and return.

CALLED BY:	INTERNAL: CharLowFast, CharLowCheck (VidPutString)

PASS:		dx - index of character (NOT char number)
		PSL_saveGState - seg addr of gstate
		    contains:
			GS_fontID
			GS_fontSize
			GS_fontHandle
		PSL_saveFont - segment addr of font

RETURN:		character data added to font;
		data ptr to character updated;
		PSL_saveFont - segment addr of font (updated)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	SaveVidState();
	FontBuildChar(character, font, pointsize, rotation);
	RestoreVidState();

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	currently doesn't deal with the save under state or the mouse
	redraw state.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidBuildChar	proc  near
	push	ax, bx, cx, dx, di, si, ds, es, bp

	mov	di, 400
	call	ThreadBorrowStackSpace
	push	di

NMEM <	cmp	cs:[xorHiddenFlag],0	;check for ptr hidden.		>
NMEM <	jz	noRedrawXOR		;go and redraw it if it was hidden.>
NMEM <	call	ShowXOR							>
NMEM <noRedrawXOR:							>

NMEM < 	cmp	cs:[hiddenFlag],0		;check for ptr hidden.	>
NMEM < 	je	noRedraw			;branch if not hidden >
NMEM <	push	dx				;>
NMEM <	call	CondShowPtr			;redraw it if it was hidden.>
NMEM <	pop	dx				;>
NMEM <noRedraw:					;>

	mov	si, offset PutStringState 	; cs:si <- ptr to table
	call	SaveVidState			; save self-modifcations
	mov	bp, cs:[PSL_saveGState]		; bp <- seg addr of gstate
	mov	es, cs:[PSL_saveFont]		; es <- seg addr of font

	VSem	cs, videoSem, TRASH_AX_BX	;release the driver sem
	mov	di, DR_FONT_GEN_CHAR		;di <- driver function
SBCS <	add	dl, es:[FB_firstChar]		;dl <- character (Chars)>
SBCS <	clr	dh				;dx <- character (Chars)>
DBCS <	add	dx, es:[FB_firstChar]		;dx <- character (Chars)>
	mov	ax, es:[FB_maker]		;ax <- font manufacturer
	call	GrCallFontDriverID
	PSem	cs, videoSem, TRASH_AX_BX	 ;get the driver sem

	mov	cs:[PSL_saveFont], es		 ; store (new) font seg
	mov	si, offset PutStringState	 ; cs:si <- ptr to table
	call	RestoreVidState			 ; restore self-modifications

EGA <	mov	dh, cs:[currentColor]					>
EGA <	mov	dl, cs:[currentDrawMode]				>
EGA <	call	SetEGAClrMode						>

NIKEC <	mov	dh, cs:[currentColor]					>
NIKEC <	mov	dl, cs:[currentDrawMode]				>
NIKEC <	call	SetNikeClrMode						>

NMEM <	call	CondHidePtr			;>

NMEM <	clr	ax							>
NMEM <	clr	bx							>
FRES <	mov	cx, SCREEN_PIXEL_WIDTH					>
FRES <	mov	dx, SCREEN_HEIGHT					>
MRES <	mov	cx, cs:[DriverTable].VDI_pageW				>
MRES <	mov	dx, cs:[DriverTable].VDI_pageH				>
NMEM <	call	CheckXORCollision			;>

	pop	di
	call	ThreadReturnStackSpace

	pop	ax, bx, cx, dx, di, si, ds, es, bp
	ret
VidBuildChar	endp

PutStringState	label  word
	word	(EndPSS-PutStringState-2)/2	;<- # words to save
	nptr	PSL_saveYPos
	nptr	PSL_saveWindow
	nptr	PSL_saveStringSeg
	nptr	PSL_saveRoutine
	nptr	CLF_saveLastON
	nptr	CLF_firstChar
	nptr	CLF_lastChar
	nptr	PSL_saveGState
;
;	nptr	textMode			; now saved with stateFlags
;
	nptr	PSL_spacePad
	nptr	PSL_spacePadFrac
	nptr	PSL_spaceOpcode
	nptr	stateFlags			; saves stateFlags and textMode
	nptr	fracPosition			; saves fracPosition and next
	nptr	lastChar			; saves lastChar and lastFlags
if DBCS_PCGEOS
	nptr	lastFlags			; byte size
else
;
;	nptr	lastFlags			; now saved with lastChar
;
endif
	nptr	currentWin
	nptr	PSL_complexOp1
	nptr	PSL_complexOp2
	nptr	kernComplexOp1
	nptr	kernComplexOp2
	nptr	trackKernFrac
	nptr	trackKernInt
	nptr	CLR_lastChar
	nptr	CLR_firstChar
	nptr	CLR_kernOp

ifdef IS_DIRECT_COLOR
	nptr	currentDrawMode			;also gets currentColor.RGB_red
	nptr	currentColor.RGB_green
elifdef IS_CLR24
	nptr	currentDrawMode			;also gets currentColor.RGB_red
	nptr	currentColor
else
BIT <	nptr	currentMapMode			;also gets currentDrawMode  >
BIT <	nptr	currentColor						    >
endif

EGA <	nptr	currentColor						>
EGA <	nptr	currentDrawMode						>
NIKEC <	nptr	currentColor						>
NIKEC <	nptr	currentDrawMode						>

ifdef IS_MEM
	nptr	bm_segment	
	nptr	bm_handle.segment
	nptr	bm_handle.offset
	nptr	bm_byteOffset	
	nptr	bm_lastSeg	
MONO <	nptr	bm_flags					>
CMYK <	nptr	bm_flags					>
	nptr	bm_scansNext	
	nptr	bm_bpScan	
	nptr	bm_bpMask	
	nptr	bm_cacheWid	
	nptr	bm_dataOffset	
	nptr	bmScan		
	nptr	bm_cacheTypeWord
endif

; ALSO: need to figure out how to deal with mouse position and save under
; state that are checked early on, but may change if we release the
; driver semaphore...

;
; the following are self-modifications that are updated, so DON'T INCLUDE THEM!
;	--	PSL_saveFont
;
EndPSS:


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveVidState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save necessary state variables on the stack.

CALLED BY:	INTERNAL: VidBuildChar

PASS:		cs:si - table of addresses of variables to save
			format:
			dw	# WORDS
			dw	address #1 (in cs)
			dw	address #2
			...
			dw	address #n

RETURN:		sp - stack contains save variables

DESTROYED:	bx, si, di, cx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SaveVidState	proc	near

	XchgTopStack	bx		;bx <- return address

	mov	cx, cs:[si]		;cx <- # words to save
	add	si, 2			;si <- ptr to first address
SVS_loop:
	mov	di, cs:[si]		;di <- address of value to save
	push	cs:[di]			;save value on stack
	add	si, 2			;advance to next address
	loop	SVS_loop		;loop while more words

	jmp	bx
SaveVidState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RestoreVidState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore state variables from the stack.

CALLED BY:	INTERNAL: VidBuildChar

PASS:		cs:si - table of addresses of variables to restore
			format:
			dw	# WORDS
			dw	address #1 (in cs)
			dw	address #2
			...
			dw	address #n

RETURN:		sp - updated, variables pulled off

DESTROYED:	si, di, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		
RestoreVidState	proc	near

	pop	bx			;bx <- return address

	mov	cx, cs:[si]		;cx <- # words to save
	mov	dx, cx
	shl	dx, 1			;dx = # words *2
	add	si, dx

RVS_loop:
	mov	di, cs:[si]		;di <- address to restore to
	pop	cs:[di]			;recover value from stack
	sub	si, 2			;advance to previous address
	loop	RVS_loop		;loop while more words

	pop	si			;clear misc crap
	jmp	bx
RestoreVidState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoComplexMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the pen position for a complex transform.
CALLED BY:	INTERNAL: PutStringLow, DoKern

PASS:		ax.fracPosition - x position (WBFixed)
		bx.fracYPosition - y position (WBFixed)
		TOS --> near return address
			old x position (WWFixed, WWF_frac.low garbage)
RETURN:		ax.fracPosition - updated
		bx.fracYPosition - updated
DESTROYED:	none

PSEUDO CODE/STRATEGY:
		The old pen position is on the stack. The new pen
	position is in ax.fracPosition and bx.fracYPosition. The
	new y position is assumed to be the same as the old position,
	as the normal text code will not affect the y position at all.
		The transformed pen position is calculated by taking
	the difference between the new x position and old x position,
	and transforming that by the transform in the window. If
	there is only scaling, this is simply scaling the x position.
	If there is rotation, a y component is introduced as well.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The old position is left on the stack upon exiting.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/13/89		Initial version
	Gene	2/90		Removed guts from kernel, fixed for kerning

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoComplexMove	proc	near
	uses	cx, dx, si, di, ds, es
	.enter

	mov	di, sp
	add	di, 2 + 6*2			;skip return addr, saved regs
	segmov	es, ss				;es:di <- ptr to old x

	mov	ds, cs:PSL_saveWindow
	mov	si, offset W_curTMatrix		;ds:si <- addr of xform

	mov	dl, cs:fracPosition
	sub	dl, es:[di].WWF_frac.high
	sbb	ax, es:[di].WWF_int		;ax.dl <- (new x - old x)

	xchg	es:[di].WWF_frac.high, dl
	xchg	es:[di].WWF_int, ax
	clr	es:[di].WWF_frac.low		;es:di <- ptr to (new x - old x)
	mov	cs:fracPosition, dl		;ax.fracPosition <- old x

	test	ds:[si].TM_flags, TM_ROTATED	;see if rotated
	jz	notRotated			;branch if not rotated
	push	si
	add	si, offset TM_12		;ds:si <- ptr to tm12
	call	GrMulWWFixedPtr			;rotate difference by tm12
	add	cs:fracYPosition, ch
	adc	bx, dx				;bx.fracYPosition <- new y pos
	mov	cs:PSL_saveYPos, bx		;store PutStringLow copy
	pop	si
notRotated:
	add	si, offset TM_11		;ds:si <- ptr to tm11
	call	GrMulWWFixedPtr			;scale difference by tm11
	add	cs:fracPosition, ch
	adc	ax, dx				;ax.fracPosition <- new x pos

	.leave
	ret
DoComplexMove	endp
