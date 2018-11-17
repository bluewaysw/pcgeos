COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Dumb Raster video drivers
FILE:		dumbcomUtils.asm

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version

DESCRIPTION:
	These are a set of utility routines used by the bitmap driver.
	
	$Id: dumbcomUtils.asm,v 1.1 97/04/18 11:42:27 newdeal Exp $

-------------------------------------------------------------------------------@

COMMENT @-----------------------------------------------------------------------

FUNCTION:	SetDither

DESCRIPTION:	Set the pattern buffer based on the current color

CALLED BY:	INTERNAL
		VidDrawRectangle

PASS:	ds:si	- CommonAttr structure
	es 	- window segment

RETURN:
	cs:[ditherMatrix] - set

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	The idea behind this routine is to map colors to some pattern on
	a black and white display.  For drivers that can display more than
	2 colors, but less than 16, this routine should map the first 16
	colors, using the available colors as appropriate.

	Eventually, we may want to put all the mapping intelligence into
	the kernel, and have it query the driver to find out what it
	can and can't do.  We'll see.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Jim	02/89		Modified for new way of mapping colors
	Jim	4/89		Modified to shift pattern bytes to align w/scrn
-------------------------------------------------------------------------------@

SetDither	proc		far
	uses	ax,bx,cx,ds
	.enter

	; if we are clustered dither, then the traditional window offset
	; doesn't mean didly.  Compute a new pattern offset based on the 
	; size of the clustered dither pattern.

	mov	ax, es:[W_pattPos]		; get patt ref point
ifdef	MEM_MONO
	test	cs:[bm_flags], mask BM_CLUSTERED_DITHER
	jz	havePattPos
	push	dx
	mov	ax, es:[W_ditherY]		; only need it in y
	cwd					; dxax = dividend
	mov	bx, MONO_DITHER_HEIGHT 		; bx = divisor
	idiv	bx
	mov	ah, dl				; dl = remainder
	mov	al, es:[W_pattPos].low 
	pop	dx
havePattPos:
endif
	; get the values of the color components we are building the
	; matrix for.  

	mov	cl, ds:[si].CA_colorRGB.RGB_red
	mov	ch, ds:[si].CA_colorRGB.RGB_green
	mov	bl, ds:[si].CA_colorRGB.RGB_blue
	mov	bh, ds:[si].CA_mapMode
ifdef 	MEM_MONO
	tst	bl				; check for black
	jnz	notBlack
	jcxz	itsBlack			; do it quick.
notBlack:
endif
	; check to see if we really need to re-create it.  If the color
	; is the same, and the shift amount is the same, then we're OK.

	cmp	cl, cs:[ditherColor].RGB_red
	jne	setNewDither
	cmp	ch, cs:[ditherColor].RGB_green
	jne	setNewDither
	cmp	bl, cs:[ditherColor].RGB_blue
	jne	setNewDither
		
	; also need to check the map mode, as GrMapColorToGrey uses this
	; information

	cmp	bh, cs:[ditherMapMode]
	jne	setNewDither

	; besides the color, we should check the rotation.

	cmp	ax, {word} cs:[ditherRotX]	; same ?
	je	done

		; set up es:di -> at the dither matrix we are about to fill
setNewDither:
	mov	cs:[ditherColor].RGB_red, cl	; set new color
	mov	cs:[ditherColor].RGB_green, ch
	mov	cs:[ditherColor].RGB_blue, bl
	mov	cs:[ditherMapMode], bh
	mov	{word} cs:[ditherRotX], ax	; set rotation value

ifdef	MEM_MONO
	test	cs:[bm_flags], mask BM_CLUSTERED_DITHER
	jnz	clustered
endif
	mov	al, ds:[si].CA_colorIndex
	mov	cs:[currentColor], al

	call	GrMapColorToGrey		;makes ds:bx point at data
						; if we're writing on black,
	mov	cx, cs:[resetColor]		; this is setup already
	mov	ax,word ptr ds:[bx]
	xor	ax, cx
	mov	word ptr cs:[ditherMatrix],ax	; store pattern away
	mov	ax,word ptr ds:[bx][2]
	xor	ax, cx
	mov	word ptr cs:[ditherMatrix+2],ax
	mov	ax,word ptr ds:[bx][4]
	xor	ax, cx
	mov	word ptr cs:[ditherMatrix+4],ax
	mov	ax,word ptr ds:[bx][6]
	xor	ax, cx
	mov	word ptr cs:[ditherMatrix+6],ax

	; shift the pattern buffer content

	mov	ax, {word} cs:[ditherRotX]	; get patt ref point
	call	ShiftPattern			; shift the buffer content
done:
	.leave
	ret

ifdef	MEM_MONO
clustered:
	call	SetDitherClustered
	jmp	done	

		; if the color is black, do the quick fill.
itsBlack:
		mov	al, ds:[si].CA_colorIndex
		mov	cs:[currentColor], al
		mov	{word} cs:[ditherColor].RGB_red, cx	; set new color
		mov	cs:[ditherColor].RGB_blue, bl
		push	es, di
		segmov	es, cs, ax
		mov	di, offset ditherMatrix
		mov	ax, 0xffff
		mov	cx, (length ditherMatrix)/2
		rep	stosw
		pop	es, di
		jmp	done
endif
SetDither	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShiftPattern
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shift the pattern buffer to align it with the screen

CALLED BY:	INTERNAL

PASS:		al		 - new x bit shift
		ah		 - new y bit shift
		cs:ditherMatrix - pattern buffer

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		rotate the bytes in x and shuffle them in y

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShiftPattern	proc		near
		push	bx, cx, dx
		push	bp				; allocate local space
		mov	bp, sp
		sub	sp, 2				; just need 2 bytes

		; store new shift value

		mov	[bp-2], ax			; [bp-2]=xshift,[bp-1]=y
 
		; first get bytes into registers (can fit all but one)

		mov	ah, {byte} cs:[ditherMatrix+1]	; use all regs but cl
		mov	al, {byte} cs:[ditherMatrix+2]
		mov	bh, {byte} cs:[ditherMatrix+3]
		mov	bl, {byte} cs:[ditherMatrix+4]
		mov	ch, {byte} cs:[ditherMatrix+5]
		mov	dh, {byte} cs:[ditherMatrix+6]
		mov	dl, {byte} cs:[ditherMatrix+7]

		; next, do rotates in x

		mov	cl, [bp-2]			; set up shift count
		tst	cl				; see if neg
		js	SP_absX				;  yes, shift left
		jz	SP_Xshifted			; no change
		ror	byte ptr cs:[ditherMatrix], cl	; shift all 8 bytes
		ror	ah, cl
		ror	al, cl
		ror	bh, cl
		ror	bl, cl
		ror	ch, cl
		ror	dh, cl
		ror	dl, cl

		; now shuffle bytes in y
SP_Xshifted:		
		mov	cl, [bp-1]			; get count in cl
		tst	cl				; see if negative
		js	SP_absY				;  yes, shuffle up
		jz	SP_done				; no change
SP_10:
		xchg	dl, dh
		xchg	dh, ch
		xchg	ch, bl
		xchg	bl, bh
		xchg	bh, al
		xchg	al, ah
		xchg	ah, {byte} cs:[ditherMatrix]; start shuffling
		dec	cl
		jnz	SP_10
SP_done:
		mov	{byte} cs:[ditherMatrix+1], ah	; write out new values
		mov	{byte} cs:[ditherMatrix+2], al
		mov	{byte} cs:[ditherMatrix+3], bh
		mov	{byte} cs:[ditherMatrix+4], bl
		mov	{byte} cs:[ditherMatrix+5], ch
		mov	{byte} cs:[ditherMatrix+6], dh
		mov	{byte} cs:[ditherMatrix+7], dl
		mov	sp, bp				; restore stack ptr
		pop	bp				; restore frame ptr
		pop	bx, cx, dx
		ret

SP_absX:
		neg	cl			
		rol	byte ptr cs:[ditherMatrix], cl	; shift all 8 bytes
		rol	ah, cl
		rol	al, cl
		rol	bh, cl
		rol	bl, cl
		rol	ch, cl
		rol	dh, cl
		rol	dl, cl
		jmp	SP_Xshifted

SP_absY:
		neg	cl
SP_20:
		xchg	ah, {byte} cs:[ditherMatrix]; start shuffling
		xchg	ah, al
		xchg	al, bh
		xchg	bh, bl
		xchg	bl, ch
		xchg	ch, dh
		xchg	dh, dl
		dec	cl
		jnz	SP_20
		jmp	SP_done
ShiftPattern	endp
