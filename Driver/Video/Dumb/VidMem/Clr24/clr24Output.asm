COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VidMem video driver	
FILE:		clr24Output.asm

AUTHOR:		Jim DeFrisco, Feb 21, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/21/92		Initial revision


DESCRIPTION:
	rectangle drawing routines for 24-bits/pixel
		

	$Id: clr24Output.asm,v 1.1 97/04/18 11:43:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @--------------------------------------------------------------------

FUNCTION:	DrawOptRect

DESCRIPTION:	Draw a rectangle with draw mode GR_COPY and all bits in the
		draw mask set

CALLED BY:	INTERNAL
		DrawSimpleRect

PASS:
	dx - number of pixels covered by rectangle - 1
	zero flag - set if rect is one word wide
	cx - pattern index
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	si - (left x position MOD 16) * 2
	bx - (right x position MOD 16) * 2

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
----------------------------------------------------------------------------@

DrawOptRect	proc	near

                mov     ax, {word}cs:[currentColor].RGB_red
                mov     bl, {byte}cs:[currentColor].RGB_blue

		; calculate #bytes in the middle of the line and
		; offset to next line

		inc	dx			; total #bytes in line
		mov	cx, dx			; setup count
lineLoop:
                push    cx, di
optLoop1:
		stosw
		mov	es:[di], bl
		inc	di
		loop	optLoop1

                pop     cx, di                  ; ptr to start position

		dec	bp			; fewer scans to do
		jz	done

		NextScan di			; adj ptr to next scan line
		tst	cs:[bm_scansNext]	; if negative, bogus
		jns	lineLoop
done:
		ret
DrawOptRect	endp


COMMENT @--------------------------------------------------------------------

FUNCTION:	DrawSpecialRect

DESCRIPTION:	Draw a rectangle with a special draw mask or draw mode clipping
		left and right

CALLED BY:	INTERNAL
		VidDrawRect

PASS:
	dx - number of words covered by rectangle + 1
	zero flag - set if rect is one word wide
	cx - pattern index
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	si - (left x position MOD 16) * 2
	bx - (right x position MOD 16) * 2

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Jim	02/89		Modified to do map mode right
----------------------------------------------------------------------------@

DrawSpecialRect	proc		near

		push	ds	
		segmov	ds, es

		; setup ah to hold a bit flag to use in testing the mask
	
		mov	bl, 80h			; bit zero
		xchg	cx, si			; cx = low three bits of x pos
		and	cl, 7			
		shr	bl, cl			; ah = single bit tester
		mov	cx, si			; restore mask buffer index

		; calculate #bytes in the line, offset to next line

		inc	dx			; number of bytes
		mov	si, cx			; mask index in si
lineLoop:
		push	di, bx			; save pointer
		mov	cx, dx			; setup count
		mov	bh, bl			; reload tester
pixelLoop:
		test	cs:[maskBuffer][si], bh	; skip this pixel ?
		jz	pixelDone

		mov	ax, {word}ds:[di]	; get screen pixel
		mov	bl, {byte}ds:[di+2]	; al=red, ah=green, bl=blue
		call	cs:[modeRoutine]	; apply mix mode
		mov	{word}es:[di], ax	; store result
		mov	{byte}es:[di+2], bl
pixelDone:
		add	di, 3
		shr	bh, 1			; testing next pixel
		jc	reloadTester
haveTester:
		loop	pixelLoop
		pop	di, bx			; restore scan pointer
		dec	bp			; fewer scans to do
		jz	done
		inc	si			; next scan line
		and	si, 0x7
		NextScan di
		segmov	ds, es			; update source reg
		tst	cs:[bm_scansNext]	;
		jns	lineLoop
done:
		pop	ds
		ret

reloadTester:
		mov	bh, 80h
		jmp	haveTester

DrawSpecialRect	endp


COMMENT @--------------------------------------------------------------------

FUNCTION:	ModeCLEAR, ModeCOPY, ModeNOP, ModeAND, ModeINVERT, ModeXOR,
		ModeSET, ModeOR

DESCRIPTION:	Execute draw mode specific action

CALLED BY:	INTERNAL
		SpecialOneWord, BlastSpecialRect

PASS:
	si - pattern (data)
	ax - screen
	dx - new bits AND draw mask

	where:	new bits = bits to write out (as in bits from a
			   bitmap).  For objects like rectangles,
			   where newBits=all 1s, dx will hold the
			   mask only.  Also: this mask is a final
			   mask, including any user-specified draw
			   mask.

RETURN:
	ax - destination (word to write out)

DESTROYED:
	dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Jim	02/89		Modified to do map mode right
----------------------------------------------------------------------------@

;	the comments below use the following conventions (remember 
;	boolean algebra?...)
;		AND	^
;		OR	v
;		NOT	~

ModeRoutines	proc		near
ForceRef	ModeRoutines

ModeCLEAR	label	near
                clr     ax
                clr     bl
ModeNOP         label	near
		ret
ModeCOPY        label	near
                mov     ax, {word} cs:[currentColor].RGB_red
                mov     bl, cs:[currentColor].RGB_blue
		ret
ModeAND         label	near      
                and     ax, {word} cs:[currentColor].RGB_red
                and     bl, cs:[currentColor].RGB_blue
		ret
ModeINVERT      label	near
                xor     ax, 0FFFFh
                xor     bl, 0FFh
		ret
ModeXOR         label	near
                xor     ax, {word} cs:[currentColor].RGB_red
                xor     bl, cs:[currentColor].RGB_blue
		ret
ModeSET         label	near
                mov     ax, 0FFFFh
                mov     bl, 0FFh
		ret
ModeOR          label	near
                or      ax, {word} cs:[currentColor].RGB_red
                or      bl, cs:[currentColor].RGB_blue
		ret

ModeRoutines	endp
