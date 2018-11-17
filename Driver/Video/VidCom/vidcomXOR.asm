COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Common video driver
FILE:		vidcomXOR.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	VidSetXOR		Draw a filled region

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	2/16/89		Initial version
	jeremy	5/91		Added support for the mono EGA driver

DESCRIPTION:
	This file contains XOR region handling routines
	
	$Id: vidcomXOR.asm,v 1.1 97/04/18 11:41:53 newdeal Exp $

-------------------------------------------------------------------------------@

COMMENT @-----------------------------------------------------------------------

FUNCTION:	VidSetXOR

DESCRIPTION:	Set the XOR region

CALLED BY:	GLOBAL

PASS:
	ax - region position X
	bx - region position Y
	^hdx:cx - handle and offset to region definition
		The block that the handle refers to MUST be in memory.
		One way to ensure this is lock the block before calling
		this routine and unlock it afterwards.  Another, less
		preferable way is to have the region in a fixed block.
	si - VisXORFlags:
		VXF_X_POS_FOLLOWS_MOUSE - X position follows mouse X
		VXF_Y_POS_FOLLOWS_MOUSE - Y position follows mouse Y
		VXF_AX_PARAM_FOLLOWS_MOUSE - AX param position follows mouse X
		VXF_BX_PARAM_FOLLOWS_MOUSE - BX param position follows mouse Y
		VXF_CX_PARAM_FOLLOWS_MOUSE - CX param position follows mouse X
		VXF_DX_PARAM_FOLLOWS_MOUSE - DX param position follows mouse Y
	ss:bp - VisXORParams:
		ss:[bp].VXP_ax - ax region parameter
		ss:[bp].VXP_bx - bx region parameter
		ss:[bp].VXP_cx - cx region parameter
		ss:[bp].VXP_dx - dx region parameter
		
		Only needed if setting one of the mouse follow flags above:
		ss:[bp].VXP_mousePos - position of mouse for inital xor
RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	initial state:
	    xorRegion = 0;

	VidSetXOR()
	{
	    HideXOR()
	    store region vars
	    ShowXOR()
	}


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	1/90		Initial version
-------------------------------------------------------------------------------@

VidSetXOR	proc	near	uses ds
	.enter

	segmov	ds, cs

	; Remove any existing XOR region
	
	call	HideXOR

	; Store passed variables

	mov	ds:[xorPositionX1], ax
	mov	ds:[xorPositionX2], ax
	mov	ds:[xorPositionY], bx
	mov	ax, ss:[bp].VXP_ax		;use rectangle structure to
	mov	ds:[xorParams].R_left, ax	;address parameters
	mov	ax, ss:[bp].VXP_bx
	mov	ds:[xorParams].R_top, ax
	mov	ax, ss:[bp].VXP_cx
	mov	ds:[xorParams].R_right, ax
	mov	ax, ss:[bp].VXP_dx
	mov	ds:[xorParams].R_bottom, ax

EC <	test	si, not mask VisXORFlags				>
EC <	ERROR_NZ	BAD_FLAGS_TO_VID_SET_XOR			>
	mov	ds:[xorFlags], si

EGA <	clr	ax							>
EGA <	clr	bx							>
EGA <	mov	al, ds:[cursorHotX]					>
EGA <	mov	bl, ds:[cursorHotY]					>
EGA <	call	UpdateXORParams						>

	; unlock old handle, if any

	mov	bx, ds:[xorRegionHandle]
	tst	bx
	jz	noUnlock
	call	MemUnlock
noUnlock:

	; lock new handle

	mov	ds:[xorRegionHandle], dx
	mov	bx, dx

	call	MemLock
EC <	ERROR_C		BAD_FLAGS_TO_VID_SET_XOR			>
	mov	ds:[xorRegion].segment, ax
	mov	ds:[xorRegion].offset, cx

	; Account for any changes in mouse position since original call.
	
	mov	ax, ds:[cursorX]		;get current mouse position
	mov	bx, ds:[cursorY]
	sub	ax, ss:[bp].VXP_mousePos.P_x	;subtract passed mouse position
	sub	bx, ss:[bp].VXP_mousePos.P_y
	call	UpdateXORParams			;update parameters accordingly

	call	ShowXOR				;draw xor region
	
	; redraw cursor if needed
	
	tst	ds:[hiddenFlag]
	jz	noRedraw
	call	CondShowPtr
noRedraw:

	.leave
	ret

VidSetXOR	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	VidClearXOR

DESCRIPTION:	Clear the XOR region

CALLED BY:	GLOBAL

PASS:
	none

RETURN:
	ax - new AX param
	bx - new BX param
	cx - new CX param
	dx - new DX param
	si - new x position
	di - new y position

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	initial state:
	    xorRegion = 0;

	VidClearXOR()
	{
	    HideXOR()
	    store region vars
	    ShowXOR()
	}


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	1/90		Initial version
-------------------------------------------------------------------------------@

VidClearXOR	proc	near	uses ds
	.enter

	segmov	ds, cs

	; Remove existing XOR region

	call	HideXOR

	; Clear variables

	clr	bx
	mov	ds:[xorFlags], bx		;zero out flags
	xchg	bx, ds:[xorRegionHandle]	;clear handle, no = handle
	tst	bx
	jz	10$
	call	MemUnlock
10$:

	; redraw cursor if needed

	tst	ds:[hiddenFlag]
	jz	noRedraw
	call	CondShowPtr
noRedraw:

	; Get values to return

	mov	ax, ds:[xorParams].R_left
	mov	bx, ds:[xorParams].R_top
	mov	cx, ds:[xorParams].R_right
	mov	dx, ds:[xorParams].R_bottom
	mov	si, ds:[xorPositionX1]
	mov	di, ds:[xorPositionY]

	.leave
	ret

VidClearXOR	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateXORForPtr

DESCRIPTION:	Update XOR stuff for pointer move

CALLED BY:	INTERNAL

PASS:
	ax - x pointer change
	bx - y pointer change

RETURN:
	none

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

UpdateXORForPtr	proc	near	uses si, ds
	.enter

	segmov	ds, cs

	inc	ds:[hiddenFlag]			;mouse is already gone
	call	HideXOR
	call	UpdateXORParams			;update parameters
	call	ShowXOR				;redraw xor region
	dec	ds:[hiddenFlag]

	.leave
	ret

UpdateXORForPtr	endp
		


COMMENT @----------------------------------------------------------------------

ROUTINE:	UpdateXORParams

SYNOPSIS:	Updates the current xor parameters.

CALLED BY:	INTERNAL

PASS:
	ax - x pointer change
	bx - y pointer change
	ds - video driver variables

RETURN:
	none

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/23/90		Initial version

------------------------------------------------------------------------------@

UpdateXORParams	proc	near
	mov	si, ds:[xorFlags]
	test	si, mask VXF_X_POS_FOLLOWS_MOUSE
	jz	10$
	add	ds:[xorPositionX1],ax
	add	ds:[xorPositionX2],ax
10$:

	test	si, mask VXF_Y_POS_FOLLOWS_MOUSE
	jz	20$
	add	ds:[xorPositionY],bx
20$:

	test	si, mask VXF_AX_PARAM_FOLLOWS_MOUSE
	jz	30$
	add	ds:[xorParams].R_left,ax
30$:

	test	si, mask VXF_BX_PARAM_FOLLOWS_MOUSE
	jz	40$
	add	ds:[xorParams].R_top,bx
40$:

	test	si, mask VXF_CX_PARAM_FOLLOWS_MOUSE
	jz	50$
	add	ds:[xorParams].R_right,ax
50$:

	test	si, mask VXF_DX_PARAM_FOLLOWS_MOUSE
	jz	60$
	add	ds:[xorParams].R_bottom,bx
60$:

	ret
UpdateXORParams	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	CheckXORCollision

DESCRIPTION:	Check for mXOR region collision

CALLED BY:	INTERNAL

PASS:
	ax, bx, cx, dx - bounds to check against

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

CheckXORCollision	proc	near

	; is there an XOR region ?

	cmp	cs:[xorRegionHandle], 0
	jz	done
	cmp	cs:[xorHiddenFlag],0
	jnz	done

	; check for collision

CXOR_b1	label	word
xorBoundsRight	=	CXOR_b1 + 1
	cmp	ax, 1234h
	jg	done			;drawing to the right -> branch
CXOR_b2	label	word
xorBoundsLeft	=	CXOR_b2 + 2
	cmp	cx, 1234h
	jl	done			;drawing to the left -> branch
CXOR_b3	label	word
xorBoundsBottom	=	CXOR_b3 + 2
	cmp	bx, 1234h
	jg	done			;drawing to the bottom -> branch
CXOR_b4	label	word
xorBoundsTop	=	CXOR_b4 + 2
	cmp	dx, 1234h
	jl	done			;drawing to the top -> branch

	call	HideXOR

done:
	ret

CheckXORCollision	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	HideXOR

DESCRIPTION:	Remove XOR region from screen

CALLED BY:	INTERNAL

PASS:
	none

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	HideXOR()
	{
	    if (xorRegion == NULL && !xorHiddenFlag) {
		DrawXOR();
	    }
	    xorHiddenFlag = TRUE
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

HideXOR	proc	near

	; is there an XOR region ?

	cmp	cs:[xorRegionHandle], 0
	jz	done
	cmp	cs:[xorHiddenFlag],0
	jnz	done

	call	DrawXOR

	mov	cs:[xorHiddenFlag], 1

done:
	ret

HideXOR	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ShowXOR

DESCRIPTION:	Display XOR region on screen

CALLED BY:	INTERNAL

PASS:
	none

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	ShowXOR()
	{
	    if (xorRegion == NULL) {
		DrawXOR();
	    }
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

ShowXORFar	proc	far
		call	ShowXOR
		ret
ShowXORFar	endp

ShowXOR	proc	near

	; is there an XOR region ?

	cmp	cs:[xorRegionHandle], 0
	jz	done

	call	DrawXOR

	mov	cs:[xorHiddenFlag], 0

done:
	ret

ShowXOR	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawXOR

DESCRIPTION:	XOR the XOR region

CALLED BY:	INTERNAL

PASS:
	none

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	DrawXOR()
	{
	    if (xorRegion == NULL) {
		DrawXOR();
	    }
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

DrawXOR	proc	near	uses ax, bx, cx, dx, si, di, bp, ds, es
	.enter
	push	{word} cs:[maskBuffer]
	push	{word} cs:[maskBuffer+2]
	push	{word} cs:[maskBuffer+4]
	push	{word} cs:[maskBuffer+6]
	push	cs:[driverState]
	push	cs:[rectRoutine]	; save routine address
	push	cs:[TRC_pointer]
EGA <	push	{word} cs:[currentDrawMode]				>
NIKEC <	push	{word} cs:[currentDrawMode]				>

	; set color and mode

EGA <	mov	dh, cs:[currentColor]					>
EGA <	mov	dl, MM_INVERT						>
EGA <	call	SetEGAClrMode						>

NIKEC <	mov	dh, cs:[currentColor]					>
NIKEC <	mov	dl, MM_INVERT						>
NIKEC <	call	SetNikeClrMode						>

	; CASIO is in autotransfer by default, so leave it there
ifdef	IS_CASIO
	; for Casio driver, don't write into VRAM, just into DDRAM

	clr	bx			; read the mode
	call	cs:[biosFunctions].CF_autoTransMode
	push	bx			; save for later

	mov	bh, 1			; set the mode
	mov	bl, CASIO_AT_XOR
	call	cs:[biosFunctions].CF_autoTransMode

endif
	
	and	cs:[driverState], not mask VS_DITHER	; don't dither

	; get region boundries and translate them

	push	cs:[xorParams].R_bottom		;put params on stack
	push	cs:[xorParams].R_right
	push	cs:[xorParams].R_top
	push	cs:[xorParams].R_left
	mov	cs:[TRC_pointer],sp

	; set up mask buffer

	mov	ax, -1
	mov	{word} cs:[maskBuffer], ax
	mov	{word} cs:[maskBuffer+2], ax
	mov	{word} cs:[maskBuffer+4], ax
	mov	{word} cs:[maskBuffer+6], ax

	; compute the bounds

	lds	si, cs:[xorRegion]		;ds:si = region

	mov	dx, cs:[xorPositionX1]		;dx = x pos
	mov	cx, dx				;cx = x pos
	mov	bx, cs:[xorPositionY]		;di = ypos

	lodsw
	call	SlowTranslateCoord
	add	dx, ax
	mov	cs:[xorBoundsLeft], dx		;dx = left
	lodsw
	call	SlowTranslateCoord
	add	bx, ax
	mov	cs:[xorBoundsTop], bx		;bx = top
	lodsw
	call	SlowTranslateCoord
	add	cx, ax
	mov	cs:[xorBoundsRight], cx		;cx = right
	lodsw
	call	SlowTranslateCoord
	add	ax, cs:[xorPositionY]
	mov	cs:[xorBoundsBottom], ax
	xchg	ax, dx				;ax = left, dx = bottom

	; check for mouse collision

	call	CheckCursorCollision

	; set rectangle routine to use

ifdef IS_CLR24
	mov	cs:[rectRoutine], DRAW_SPECIAL_RECT
	segmov	cs:[modeRoutine], cs:[drawModeTable][MM_INVERT*2]
else
ifndef IS_MEGA
ifdef IS_CASIO
	mov	cs:[rectRoutine], DRAW_XOR_RECT
else
BIT <	mov	cs:[rectRoutine], DRAW_NOT_RECT				>
endif
endif
endif ; IS_CLR24

EGA <	mov	cs:[rectRoutine], DRAW_SPECIAL_RECT			>

	; check for clipping

	tst	ax				; left < 0 ?
	js	complex
FRES <	cmp	cx, SCREEN_PIXEL_WIDTH		; right > width ?	>
MRES <	cmp	cx, cs:[DriverTable].VDI_pageW				>
	jge	complex
	tst	bx				; top < 0 ?
	js	complex
FRES <	cmp	dx, SCREEN_HEIGHT		; bottom > height ?	>
MRES <	cmp	dx, cs:[DriverTable].VDI_pageH	; bottom > height ?	>
	jge	complex

	mov	cs:[DXOR_call], offset DrawSimpleRect
	mov	cs:[DXOR_trivial], OP_MOV_AX_AX
	jmp	common

complex:
	mov	cs:[DXOR_call], offset DrawXORComplexRect
	mov	cs:[DXOR_trivial], \
		    OP_JMP_SHORT or ((DXOR_checkTrivial-DXOR_trivial-2) shl 8)

common:

	; draw the sucker

	SetBuffer	es, ax		; es points at video ram

	; pointing at Y value, bx = top for this swath

yLoop:
	lodsw			; get first y coord (top) in bx
	cmp	ax,EOREGREC	; done ?
	jz	done
	call	SlowTranslateCoord
	mov	bp, ax
DXOR_s1	label	word
xorPositionY	=	DXOR_s1 + 2
	add	bp, 1234h	; add vertical offset

leftOrEnder:
	lodsw			; get left or line ender
	cmp	ax, EOREGREC	;was it line ender
	jz	eoln		;branch if so
	call	SlowTranslateCoord
	mov	cx,ax		;store left in cx temporarily
	lodsw			;get right into ax temporarily
	call	SlowTranslateCoord
	xchg	ax, cx		;switch left and right into proper regs
DXOR_s2	label	word
xorPositionX1	=	DXOR_s2 + 1
	add	ax, 1234h	;add horizontal offset to left
DXOR_s3	label	word
xorPositionX2	=	DXOR_s3 + 2
	add	cx, 1234h	;add horizontal offset to right

DXOR_trivial	label	word
	jmp	short DXOR_checkTrivial	;selfModified

afterTrivial:
	push	bp

	sub	bp,bx			;bp = # lines
	js	noLinesToDraw
	inc	bp

	push	si

	mov	si,ax			;si = left

	push	bx

	mov	di,cx			;di = right

DXOR_s4	label	word
DXOR_call	=	DXOR_s4 + 1
	mov	ax,1234h
	call	ax

	pop	bx
	pop	si
noLinesToDraw:
	pop	bp
	jmp	short leftOrEnder

;----------------------

	;past EOREGREC for line, move to next line

eoln:
	mov	bx,bp			;bx is new top
	inc	bx
	jmp	yLoop

;----------------------

	;at firstON or EOREGREC, reject line

rejectLine:
	lodsw
	cmp	ax,EOREGREC
	jnz	rejectLine
	jmp	short eoln

;----------------------

	;at end

done:
	add	sp, size Rectangle	;pop off region parameters

	; we're gonna leave it in autotransfer mode now
ifdef	IS_CASIO
	; for Casio driver, restore the previous mode

	pop	bx			; restore mode
	mov	bh, 1			; not set the mode
	call	cs:[biosFunctions].CF_autoTransMode
endif

EGA <	pop	bx							>
EGA <	mov	dl, bl
EGA <	mov	dh, cs:[currentColor]					>
EGA <	call	SetEGAClrMode						>

NIKEC <	pop	bx							>
NIKEC <	mov	dl, bl							>
NIKEC <	mov	dh, cs:[currentColor]					>
NIKEC <	call	SetNikeClrMode						>

	pop	cs:[TRC_pointer]
	pop	cs:[rectRoutine]	; save routine address
	pop	cs:[driverState]	; restore state flags
	pop	{word} cs:[maskBuffer+6]
	pop	{word} cs:[maskBuffer+4]
	pop	{word} cs:[maskBuffer+2]
	pop	{word} cs:[maskBuffer]
	.leave
	ret

;----------------------

	;
	; Trivial rejects
	; - if top of rect to draw is below bottom of mask rect then reject 
	;   rest of region
	; - if left of rect to draw is to right of mask right then reject
	;   rest of x1,x2 pairs on this line of region def
	; - if bottom of rect to draw is above top of mask rect then reject
	;   rest of x1,x2 pairs on this line of region def
	; - if right of rect to draw is to left of mask rect left then reject
	;   this rectangle
	;

DXOR_checkTrivial:
FRES <	cmp 	bx, SCREEN_HEIGHT					>
MRES <	cmp	bx, cs:[DriverTable].VDI_pageH				>
	jg	done

FRES <	cmp	ax, SCREEN_PIXEL_WIDTH					>
MRES <	cmp	ax, cs:[DriverTable].VDI_pageW				>
	jg	rejectLine
	
	tst	bp
	jb	rejectLine
	jmp	afterTrivial

DrawXOR	endp

;-----

SlowTranslateCoord	proc	near
	TranslCoord1	ah, STC1, STC2
	ret
TranslCoord2	ax, STC1, STC2
SlowTranslateCoord	endp


cOMMENT @----------------------------------------------------------------------

FUNCTION:	DrawXORComplexRect

DESCRIPTION:	Draw a rectangle possibly clipped for DrawXOR

CALLED BY:	INTERNAL
		VidDrawRect

PASS:
	si - left coordinate of rect
	di - right coordinate of rect
	bx - top coordinate of rect
	bp - # of lines to draw
	es - video RAM

RETURN:

DESTROYED:
	ax, bx, cx, dx,si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

DrawXORComplexRect	proc	near

	add	bp, bx				; bp = bottom
	dec	bp

	; trivial reject ?

FRES <	cmp	si, SCREEN_PIXEL_WIDTH		; left > width ?	>
MRES <	cmp	si, cs:[DriverTable].VDI_pageW				>
	jge	done
	tst	di				; right < 0 ?
	js	done
FRES <	cmp	bx, SCREEN_HEIGHT		; top > height ?	>
MRES <	cmp	bx, cs:[DriverTable].VDI_pageH	; top > height ?	>
	jge	done
	tst	bp				; bottom < 0 ?
	js	done

	; clip left

	tst	si
	jg	10$
	clr	si
10$:

	; clip right

FRES <	cmp	di, SCREEN_PIXEL_WIDTH					>
MRES <	cmp	di, cs:[DriverTable].VDI_pageW				>
	jl	20$
FRES <	mov	di, SCREEN_PIXEL_WIDTH-1				>
MRES <	mov	di, cs:[DriverTable].VDI_pageW				>
MRES <	dec	di							>
20$:

	; clip top

	tst	bx
	jg	30$
	clr	bx
30$:

	; clip bottom

FRES <	cmp	bp, SCREEN_HEIGHT					>
MRES <	cmp	bp, cs:[DriverTable].VDI_pageH				>
	jl	40$
FRES <	mov	bp, SCREEN_HEIGHT-1					>
MRES <	mov	bp, cs:[DriverTable].VDI_pageH				>
MRES <	dec	bp							>
40$:

	; convert back to # lines

	sub	bp, bx
	inc	bp

	GOTO	DrawSimpleRect
done:
	ret
DrawXORComplexRect	endp
