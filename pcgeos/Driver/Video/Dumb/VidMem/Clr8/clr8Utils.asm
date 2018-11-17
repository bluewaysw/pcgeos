COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VidMem video driver	
FILE:		clr8Utils.asm

AUTHOR:		Jim DeFrisco, Feb 11, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/11/92		Initial revision


DESCRIPTION:
	
		

	$Id: clr8Utils.asm,v 1.1 97/04/18 11:42:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDitherIndices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcDitherIndices		proc	far
		.enter
		.leave
		ret
CalcDitherIndices		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDither
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the ditherMatrix

CALLED BY:	CheckSetDither macro
PASS:		ds:[si]	- CommonAttr structure
		es	- Window structure
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		We have quite a few more colors to dither with.  I'm using
		a method suggested in Graphics Gems 2, page 72.  Basically,
		we take the 8-bit component values (RGB), map them into 6
		different base values (0,33,66,99,cc,ff) and achieve shades
		in between those six by dithering.  Thus the remainder of the
		desired color minus the base chosen is used to index into a
		set of dither matrices for each component.  

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDither		proc	far
		uses	ax,bx,cx,dx,si,ds,es,di
		.enter

		; load up the RGB values...

		mov	dl, ds:[si].CA_colorRGB.RGB_red
		mov	dh, ds:[si].CA_colorRGB.RGB_green
		mov	bl, ds:[si].CA_colorRGB.RGB_blue
		mov	ax, es:[W_pattPos]		; get patt ref point
		and	ax, 0x0303			; need low 2, not three

		; check to see if we really need to re-create it.  If the color
		; is the same, and the shift amount is the same, then we're OK.

		cmp	dl, cs:[ditherColor].RGB_red
		jne	setNewDither
		cmp	dh, cs:[ditherColor].RGB_green
		jne	setNewDither
		cmp	bl, cs:[ditherColor].RGB_blue
		jne	setNewDither
		
		; besides the color, we should check the rotation.

		cmp	ax, {word} cs:[ditherRotX]	; same ?
		LONG je	done

		; set up es:di -> at the dither matrix we are about to fill
setNewDither:
		mov	cs:[ditherColor].RGB_red, dl	; set new color
		mov	cs:[ditherColor].RGB_green, dh
		mov	cs:[ditherColor].RGB_blue, bl
		mov	{word} cs:[ditherRotX], ax	; set rotation value

		segmov	es, cs, di
		mov	di, offset ditherMatrix		; es:di -> ditherMatrix

		; init the matrix with the base values...

		clr	bh
		mov	al, cs:[ditherBase][bx]		; get base value
		xchg	al, bl				; do lookup for blue
		mov	ah, cs:[ditherBlue][bx]
		mov	bl, al				; restore blue value
		xchg	bl, dl				; dl=blue, use red
		mov	al, cs:[ditherBase][bx]
		xchg	al, bl				; al=red, bl=baseRedIdx
		add	ah, cs:[ditherRed][bx]		; ah = redBase+blueBase
		mov	bl, al				; bl=red
		xchg	bl, dh				; dh=red, use green
		mov	al, cs:[ditherBase][bx]		; get base index
		xchg	al, bl
		add	ah, cs:[ditherGreen][bx]	; ah = total base value
		mov	bl, al				; bl = green


		; now for each ditherMatrix position, add the base plus the 
		; possible addition of a modification value based on the 
		; remainder of the modulo operation (see vga8Dither.asm)
		
		mov	bl, cs:[ditherMod][bx]		; bl -> green dither
		xchg	bl, dh				; dh=green, load red
		mov	bl, cs:[ditherMod][bx]
		xchg	bl, dl				; dl=red, load blue
		mov	bl, cs:[ditherMod][bx]		; bl=blue

		; now fill in the 16 dither positions.

		segmov	ds, cs, si
		mov	si, offset ditherCutoff		; ds:si = cutoff values
		mov	cx, 16				; 16 values to calc
calcLoop:
		lodsb					; al = cutoff value
		mov	bh, ah			; init with base value
		cmp	al, bl			; add in more blue ?
		jae	tryGreen
		inc	bh
tryGreen:
		cmp	al, dh			; add in more green ?
		jae	tryRed
		add	bh, 6
tryRed:
		cmp	al, dl			; add in more red ?
		jae	storeIt
		add	bh, 36
storeIt:
		mov	al, bh
		stosb					; store next ditherpix
		loop	calcLoop

		; finished, now rotate the dither matrix

		mov	cx, {word} cs:[ditherRotX]	; get rotation amt
		jcxz	done
		call	RotateDither
done:
		.leave
		ret
SetDither		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RotateDither
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dither is offset by the window position.  Rotate it.

CALLED BY:	INTERNAL
		SetDither
PASS:		ditherMatrix initialized
		cl	- x rotation
		ch	- y rotation
RETURN:		nothing
DESTROYED:	cx, bx, ax

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RotateDither	proc	near
		
		; rotate in x first, then in Y

		tst	cl
		jz	handleY
		mov	si, offset cs:ditherMatrix
		call	RotateX
		add	si, 4
		call	RotateX
		add	si, 4
		call	RotateX
		add	si, 4
		call	RotateX
handleY:
		tst	ch
		jz	done
		mov	si, offset cs:ditherMatrix
		call	RotateY
		inc	si
		call	RotateY
		inc	si
		call	RotateY
		inc	si
		call	RotateY
done:
		ret
RotateDither	endp

RotateX		proc	near
		mov	ax, {word} ds:[si]
		mov	bx, {word} ds:[si+2]
		cmp	cl, 2
		ja	doThree
		jb	doOne
		xchg	ax, bx
done:
		mov	{word} ds:[si], ax
		mov	{word} ds:[si+2], bx
		ret
doThree:
		xchg	al, ah
		xchg	ah, bl
		xchg	bl, bh
		jmp	done
doOne:
		xchg	al, bh
		xchg	bh, bl
		xchg	bl, ah
		jmp	done
RotateX		endp

RotateY		proc	near
		mov	al, {byte} ds:[si]
		mov	ah, {byte} ds:[si+4]
		mov	bl, {byte} ds:[si+8]
		mov	bh, {byte} ds:[si+12]
		cmp	ch, 2
		ja	doThree
		jb	doOne
		xchg	ax, bx
done:
		mov	{byte} ds:[si], al
		mov	{byte} ds:[si+4], ah
		mov	{byte} ds:[si+8], bl
		mov	{byte} ds:[si+12], bh
		ret
doThree:
		xchg	al, ah
		xchg	ah, bl
		xchg	bl, bh
		jmp	done
doOne:
		xchg	al, bh
		xchg	bh, bl
		xchg	bl, ah
		jmp	done
RotateY		endp
