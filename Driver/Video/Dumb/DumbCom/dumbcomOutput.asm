COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Dumb Raster video drivers
FILE:		dumbcomOutput.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	VidDrawRect		Draw a filled rectangle

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version

DESCRIPTION:
	This file contains the line and rectangle output routines
	for the bitmap driver.
	
	$Id: dumbcomOutput.asm,v 1.1 97/04/18 11:42:27 newdeal Exp $

-------------------------------------------------------------------------------@

COMMENT @-----------------------------------------------------------------------

FUNCTION:	DrawOptRect

DESCRIPTION:	Draw a rectangle with draw mode GR_COPY and all bits in the
		draw mask set

CALLED BY:	INTERNAL
		DrawSimpleRect

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

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

DrawOptRect	proc	near

ifdef	LOGGING
	ornf	cs:[curRegFlags], mask RF_CALLED_DRAW_OPT_RECT
endif

	tst	dx
	jz	OptRectOneWord

	; calculate # of words in the middle of the line, offset to next line

	dec	dx				;number of middle words
NMEM <	mov	ax,dx						>
NMEM <	shl	ax,1				; compute #bytes in middle >
NMEM <	add	ax, 4				; account for end words	>
NMEM <	neg	ax							>
NMEM <	StoreNextScanMod	<cs:[BOR_nextScanOffset]>,ax		>

	; compute left masks

	mov	ax,cs:[si][leftMaskTable]	;get mask
	mov	cs:[BOR_leftNewMask],ax
	not	ax
	mov	cs:[BOR_leftOldMask],ax

	; compute right masks

	mov	ax,cs:[bx][rightMaskTable]	;get mask
	mov	cs:[BOR_rightNewMask],ax
	not	ax
	mov	cs:[BOR_rightOldMask],ax

	mov	bx,cx				;pass pattern index in bx

	GOTO	 BlastOptRect

DrawOptRect	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	OptRectOneWord

DESCRIPTION:	Draw an unclipped rectangle in the GR_COPY draw mode

CALLED BY:	INTERNAL
		DrawSimpleRect

PASS:
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
	ax = pattern word, word to store
	bx = pattern index
	cx = mask for bits to save
	dx = mask for new bits
	si = temp (screen AND bits to save)
	es:di = screen buffer address
	bp = counter

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

OptRectOneWord	proc		near
	mov	ax,cs:[si][leftMaskTable]	;get mask
	and	ax,cs:[bx][rightMaskTable]	;composite mask
	mov	dx,ax				;dx = mask for new bits
	not	ax
	mov	bx,cx				;bx = pattern index
	mov	cx,ax				;cx = mask for bits to save
	jmp	short OROW_loopEntry

OROW_loop:
	inc	bx				;increment pattern pointer
	and	bl,7
	NextScan di
MEM <	tst	cs:[bm_scansNext]		; check if off end of bitmap>
MEM <	js	done				;  if so, bail		    >

OROW_loopEntry:
	mov	al,{byte} cs:[bx][ditherMatrix];get pattern byte
	mov	ah,al

	and	ax,dx				;ax = new data bits
ifdef	REVERSE_WORD
	mov_tr	si, ax
	call	MovAXESDI
	xchg	si, ax
else
	mov	si,es:[di]
endif
	and	si,cx				;si = bits to save
	or	ax,si				;or in data bits
ifdef	REVERSE_WORD
	call	MovESDIAX
else
	mov	es:[di], ax
endif

	dec	bp				;loop to do all lines
	jnz	OROW_loop
MEM <done:							>
	ret

OptRectOneWord	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	BlastOptRect

DESCRIPTION:	Draw an unclipped rectangle in the GR_COPY draw mode

CALLED BY:	INTERNAL
		VidDrawRect

PASS:
	bx - index into pattern buffer (0-7)
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	dx - number of middle words
	BOR_leftNewMask - mask for bits to set on left
	BOR_leftOldMask - mask for bits to preserve on left
	BOR_rightNewMask - mask for bits to set on right
	BOR_rightOldMask - mask for bits to preserve on right
	BOR_nextScanOffset - Stored with StoreNextScanMod with
				SCREEN_BYTE_WIDTH - ( (# middle words) + 2) * 2

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:
	ax = pattern word, word to store
	bx = pattern index
	cx = for left and right: (screen AND bits to save), for middle: counter
	si = temp for left (pattern word)
	dx = offset to next scan line
	es:di = screen buffer address
	bp = counter

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@


BOR_loop:
	inc	bx			;increment pattern pointer
	and	bl,7
NMEM <	NextScanMod	di, BOR_nextScanOffset		>
MEM  <	NextScan di					>
MEM <	tst	cs:[bm_scansNext]		; check if off end of bitmap>
MEM <	js	BOR_done			;  if so, bail		    >

BlastOptRect	proc		near
MEM  <	push	di					>
	mov	al,{byte} cs:[bx][ditherMatrix] ;get pattern byte
	mov	ah,al

	; handle left word specially

	mov	si,ax			; save pattern for later
BOR_leftNewMask	equ	(this word) + 1	
	and	ax,1234h		;modified

ifdef	REVERSE_WORD
	mov_tr	cx, ax
	call	MovAXESDI
	xchg	cx, ax
else
	mov	cx,es:[di]		;get word
endif
BOR_leftOldMask	equ	(this word) + 2
	and	cx,1234h		;modified
	or	ax,cx
ifdef	REVERSE_WORD
	call	DoStosw
else
	stosw
endif
	mov	ax,si

	; draw middle words

	mov	cx,dx			;# of words to store
ifdef	REVERSE_WORD
	call	DoRepStosw
else
	rep stosw
endif

	; handle right word specially

BOR_rightNewMask	equ (this word) + 1
	and	ax,1234h		;modified

ifdef	REVERSE_WORD
	mov_tr	cx, ax
	call	MovAXESDI
	xchg	cx, ax
else
	mov	cx,es:[di]		;get word
endif
BOR_rightOldMask	equ	(this word) + 2
	and	cx,1234h		;modified
	or	ax,cx
ifdef	REVERSE_WORD
	call	DoStosw
else
	stosw
endif

MEM  <	pop	di			; restore start of scan		>
	dec	bp			;loop to do all lines
	jnz	BOR_loop
MEM <BOR_done	label	near						>
	ret

BlastOptRect	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	DrawNOTRect

DESCRIPTION:	Draw a rectangle with draw mode GR_COPY and all bits in the
		draw mask set

CALLED BY:	INTERNAL
		DrawSimpleRect

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

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

DrawNOTRect	proc		near
	tst	dx
	jz	NOTRectOneWord

	; calculate # of words in the middle of the line, offset to next line

	dec	dx				;number of middle words
NMEM <	mov	ax,dx							>
NMEM <	shl	ax,1				; calc #bytes in middle	>
NMEM <	add	ax, 4				; account for end words >
NMEM <	neg	ax							>
NMEM <	StoreNextScanMod	<cs:[BNR_nextScanOffset]>,ax		>

	; compute right masks

	mov	ax,cs:[bx][rightMaskTable]	;get mask
	not	ax
	mov	cs:[BNR_rightMask],ax

	; compute left masks

	mov	ax,cs:[si][leftMaskTable]	;get mask
	not	ax
	mov	bx,ax

	GOTO	 BlastNOTRect

DrawNOTRect	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	NOTRectOneWord

DESCRIPTION:	Draw an unclipped rectangle in the GR_COPY draw mode

CALLED BY:	INTERNAL
		DrawSimpleRect

PASS:
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	si - (left x position MOD 16) * 2
	bx - (right x position MOD 16) * 2

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:
	ax = pattern word, word to store
	bx = pattern index
	cx = mask for bits to save
	dx = mask for new bits
	si = temp (screen AND bits to save)
	es:di = screen buffer address
	bp = counter

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

NOTRectOneWord	proc		near
	mov	ax,cs:[si][leftMaskTable]	;get mask
	and	ax,cs:[bx][rightMaskTable]	;compisite mask
	not	ax
	mov	dx,ax				;dx = mask for bits to preserve
	mov	cx,bp
	jmp	short NROW_loopEntry

NROW_loop:
	NextScan	di
MEM <	tst	cs:[bm_scansNext]		; check if off end of bitmap>
MEM <	js	done				;  if so, bail		    >

NROW_loopEntry:
ifdef	REVERSE_WORD
	call	MovAXESDI
else
	mov	ax,es:[di]
endif
	not	ax
	xor	ax,dx
ifdef	REVERSE_WORD
	call	MovESDIAX
else
	mov	es:[di], ax
endif

	loop	NROW_loop
MEM <done:							>
	ret

NOTRectOneWord	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	BlastNOTRect

DESCRIPTION:	Draw an unclipped rectangle in the GR_COPY draw mode

CALLED BY:	INTERNAL
		VidDrawRect

PASS:
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	dx - number of middle words
	bx - mask for bits to preserve on left
	BNR_rightMask - mask for bits to preserve on right
	BNR_nextScanOffset - Stored with StoreNextScanMod with
				SCREEN_BYTE_WIDTH - ( (# middle words) + 2) * 2

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:
	ax = pattern word, word to store
	cx = for left and right: (screen AND bits to save), for middle: counter
	si = temp for left (pattern word)
	dx = offset to next scan line
	es:di = screen buffer address
	bp = counter

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@


BNR_loop:
NMEM <	NextScanMod	di, BNR_nextScanOffset				>
MEM  <	NextScan	di						>
MEM <	tst	cs:[bm_scansNext]		; check if off end of bitmap>
MEM <	js	BNR_done			;  if so, bail		    >

BlastNOTRect	proc		near

	; handle left word specially

MEM  <	push	di						>
ifdef	REVERSE_WORD
	call	MovAXESDI
else
	mov	ax,es:[di]		;get word
endif
	not	ax
	xor	ax,bx
ifdef	REVERSE_WORD
	call	DoStosw
else
	stosw
endif

	; draw middle words

	mov	cx,dx			;# of words to store
	jcxz	BNR_noMiddle
BNR_middle:
ifdef	REVERSE_WORD
	call	MovAXESDI
else
	mov	ax,es:[di]
endif
	not	ax
ifdef	REVERSE_WORD
	call	DoStosw
else
	stosw
endif
	loop	BNR_middle
BNR_noMiddle:

	; handle right word specially

ifdef	REVERSE_WORD
	call	MovAXESDI
else
	mov	ax,es:[di]		;get word
endif
	not	ax
BNR_rightMask	equ	(this word) + 1
	xor	ax,1234h		;modified
ifdef	REVERSE_WORD
	call	DoStosw
else
	stosw
endif

MEM  <	pop	di						>
	dec	bp			;loop to do all lines
	jnz	BNR_loop
MEM <BNR_done	label	near					>
	ret

BlastNOTRect	endp

COMMENT @-----------------------------------------------------------------------

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
-------------------------------------------------------------------------------@

DrawSpecialRect	proc		near
	tst	dx
	jz	SpecialOneWord

	; calculate # of words in the middle of the line, offset to next line

	dec	dx				;number of middle words
	mov	cs:[BSR_middleCount], dx	;save parameter
NMEM <	shl	dx, 1				; calc #middle bytes	>
NMEM <	add	dx, 4				; account for end words >
NMEM <	neg	dx							>
NMEM <	StoreNextScanMod	<cs:[BSR_nextScanOffset]>,dx		>

	; compute left masks

	mov	ax, cs:[si][leftMaskTable]	;get mask
	mov	cs:[BSR_leftNewMask], ax

	; compute right masks

	mov	ax, cs:[bx][rightMaskTable]	;get mask
	mov	cs:[BSR_rightNewMask], ax

	mov	bx, cx				;pass pattern index in bx

	jmp	short BlastSpecialRect

DrawSpecialRect	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	SpecialOneWord

DESCRIPTION:	Draw an unclipped rectangle in the any draw mode

CALLED BY:	INTERNAL
		DrawSimpleRect

PASS:
	cx - pattern index
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	si - (left x position MOD 16) * 2
	bx - (right x position MOD 16) * 2
	maskBuffer - draw mask to use
	wDrawMode - drawing mode to use

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:
	ax = pattern word, word to store
	bx = pattern index
	cx = mask for bits to save
	dx = mask for new bits
	si = temp (screen AND bits to save)
	es:di = screen buffer address
	bp = counter

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Jim	02/89		Modified to do map mode stuff right
-------------------------------------------------------------------------------@

SpecialOneWord	proc		near
	mov	ax, cs:[si][leftMaskTable]	; get mask
	and	ax, cs:[bx][rightMaskTable]	; composite mask
	mov	cs:[SOW_newBits],ax
	mov	bx, cx				; bx = pattern index
	jmp	short SOW_loopEntry

SOW_loop:
	inc	bx				; increment pattern pointer
	and	bx, 7
	NextScan di
MEM <	tst	cs:[bm_scansNext]		; check if off end of bitmap>
MEM <	js	done				;  if so, bail		    >

SOW_loopEntry:
	mov	al, {byte} cs:[bx][ditherMatrix]; get pattern byte
	mov	ah, al				; ax = pattern bits
	mov	si, ax				; si = pattern bits
	mov	dl, {byte} cs:[bx][maskBuffer]	; get draw mask byte
	mov	dh, dl				; dx = draw mask
SOW_newBits	equ	(this word) + 2
	and	dx, 1234h			; apply left/right masks
ifdef	REVERSE_WORD
	call	MovAXESDI
else
	mov	ax, es:[di]			; ax = screen
endif
	call	cs:[modeRoutine]		; ax = word to write
ifdef	REVERSE_WORD
	call	MovESDIAX
else
	mov	es:[di], ax
endif

	dec	bp				; loop to do all lines
	jnz	SOW_loop
MEM <done:								>
	ret

SpecialOneWord	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	BlastSpecialRect

DESCRIPTION:	Draw an unclipped rectangle in the any draw mode

CALLED BY:	INTERNAL
		VidDrawRect

PASS:
	bx - index into pattern buffer (0-7)
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	BSR_leftNewMask - mask for bits to set on left
	BSR_rightNewMask - mask for bits to set on right
	BSR_middleCount - number of full words in middle of rectangle
	BSR_nextScanOffset - Stored with StoreNextScanMod with
				SCREEN_BYTE_WIDTH - ( (# middle words) + 2) * 2

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:
	ax = pattern word, word to store
	bx = pattern index
	cx = for left and right: (screen AND bits to save), for middle: counter
	si = temp for left (pattern word)
	dx = offset to next scan line
	es:di = screen buffer address
	bp = counter

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Jim	02/89		Modified to do map mode right
-------------------------------------------------------------------------------@


BSR_loop:
	inc	bx			;increment pattern pointer
	and	bx, 7
NMEM <	NextScanMod	di, BSR_nextScanOffset			>
MEM  <	NextScan	di					>
MEM <	tst	cs:[bm_scansNext]		; check if off end of bitmap>
MEM <	js	BSR_done			;  if so, bail		    >

BlastSpecialRect	proc		near
MEM  <	push	di						>
	mov	al, {byte} cs:[bx][ditherMatrix]; get pattern byte
	mov	ah, al				;  make it a word
	mov	dl, {byte} cs:[bx][maskBuffer]; get draw mask byte
	mov	dh, dl				;  make it a word
	push	bx				; save pattern index
	mov	bx, dx				; bx,dx  = mask bits
	mov	si, ax				; si = pattern bits

	; handle left word specially

BSR_leftNewMask	equ	(this word) + 2
	and	dx,1234h			; apply left-side mask
ifdef	REVERSE_WORD
	call	MovAXESDI
else
	mov	ax, es:[di]			; ax = screen
endif
	call	cs:[modeRoutine]		; ax = word to write
ifdef	REVERSE_WORD
	call	DoStosw
else
	stosw
endif

	; draw middle words

BSR_middleCount	equ	(this word) + 1
	mov	cx, 1234h			; # words to store -- modified
	jcxz	BSR_noMiddle
BSR_midLoop:
	mov	dx, bx				; dx = pattern (data)
ifdef	REVERSE_WORD
	call	MovAXESDI
else
	mov	ax, es:[di]			; ax = screen
endif
	call	cs:[modeRoutine]		; ax = word to write
ifdef	REVERSE_WORD
	call	DoStosw
else
	stosw
endif
	loop	BSR_midLoop
BSR_noMiddle:

	; handle right word specially

ifdef	REVERSE_WORD
	call	MovAXESDI
else
	mov	ax, es:[di]			; ax = screen
endif
	mov	dx, bx				; dx = mask bits
BSR_rightNewMask	equ	(this word) + 2
	and	dx, 1234h			; apply right-side mask
	call	cs:[modeRoutine]		; ax = word to write
ifdef	REVERSE_WORD
	call	DoStosw
else
	stosw
endif

	pop	bx
MEM  <	pop	di						>
	dec	bp			;loop to do all lines
	jnz	BSR_loop
MEM <BSR_done	label	near					>
	ret

BlastSpecialRect	endp

ifdef IS_CASIO

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSolidRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rectangle by setting bits in the frame buffer.  Used
		By the XOR code in casio driver to make things fast (and work
		with hardware)

CALLED BY:	
PASS:
	dx - number of words covered by rectangle + 1
	zero flag - set if rect is one word wide
	cx - pattern index
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	si - (left x position MOD 16) * 2
	bx - (right x position MOD 16) * 2
DESTROYED:	
	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawSolidRect	proc	near
	tst	dx
	jz	SolidRectOneWord

	; calculate # of words in the middle of the line, offset to next line

	dec	dx				;number of middle words
	mov	ax,dx						
	shl	ax,1				; compute #bytes in middle 
	add	ax, 4				; account for end words	
	neg	ax							
	StoreNextScanMod	<cs:[BSoR_nextScanOffset]>,ax		

	; compute left and right masks

	mov	ax,cs:[si][leftMaskTable]	;get mask
	mov	cs:[BSoR_leftNewMask],ax
	mov	ax,cs:[bx][rightMaskTable]	;get mask
	mov	cs:[BSoR_rightNewMask],ax
	GOTO	 BlastSolidRect

DrawSolidRect	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SolidRectOneWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:
	cx - pattern index
	es:di - buffer address for first left:top of rectangle
	ds - Window structure
	bp - number of lines to draw
	si - (left x position MOD 16) * 2
	bx - (right x position MOD 16) * 2

RETURN:		
DESTROYED:	
	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		
REGISTER/STACK USAGE:
	ax = pattern word, word to store
	bx = pattern index
	cx = mask for bits to save
	dx = mask for new bits
	si = temp (screen AND bits to save)
	es:di = screen buffer address
	bp = counter


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SolidRectOneWord	proc		near
	mov	ax,cs:[si][leftMaskTable]	;get mask
	and	ax,cs:[bx][rightMaskTable]	;composite mask
	mov	cx, bp
	jmp	short SoROW_loopEntry

SoROW_loop:
	NextScan di
SoROW_loopEntry:
ifdef	REVERSE_WORD
	call	MovESDIAX
else
	mov	es:[di], ax
endif
	loop	SoROW_loop
MEM <done:							>
	ret

SolidRectOneWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlastSolidRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go as fast as possible, for Zoomer XOR mode

CALLED BY:	INTERNAL
		DrawXOR code
PASS:		see above
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSoR_loop:
	NextScanMod	di, BSoR_nextScanOffset

BlastSolidRect	proc		near
	; handle left word specially

BSoR_leftNewMask	equ	(this word) + 1	
	mov	ax, 0x1234		;modified
ifdef	REVERSE_WORD
	call	DoStosw
else
	stosw
endif

	; draw middle words

	mov	ax, 0xffff		; want solid in the middle
	mov	cx, dx			;# of words to store
ifdef	REVERSE_WORD
	call	DoRepStosw
else
	rep stosw
endif

	; handle right word specially

BSoR_rightNewMask	equ (this word) + 1
	mov	ax, 0x1234		;modified
ifdef	REVERSE_WORD
	call	DoStosw
else
	stosw
endif
	dec	bp			;loop to do all lines
	jnz	BSoR_loop
	ret

BlastSolidRect	endp

endif


COMMENT @-----------------------------------------------------------------------

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
-------------------------------------------------------------------------------@

;	the comments below use the following conventions (remember 
;	boolean algebra?...)
;		AND	^
;		OR	v
;		NOT	~

ModeRoutines	proc		near
		ForceRef	ModeRoutines
ModeCLEAR	label near	; (screen^~(data^mask))v(data^mask^resetColor
	not	dx
	and	ax, dx
	not	dx
	and	dx, cs:[resetColor]
	or	ax, dx
ModeNOP		label near
	ret

;-----------------

ModeCOPY	label  near	; (screen^~(data^mask))v(data^mask^pattern)
	not	dx
	and	ax, dx
	not	dx
	and	dx, si
	or	ax, dx
	ret

;-----------------

MA_orNotMask	word	

ModeAND		label  near	; (screen^((data^mask^pattern)v~(data^mask))
	not	dx
	mov	cs:[MA_orNotMask], dx
	not	dx
	and	dx, si
	or	dx, cs:[MA_orNotMask]
	and	ax, dx
	ret

;-----------------

ModeINVERT	label  near	; screenXOR(data^mask)
	xor	ax, dx
	ret

;-----------------

ModeXOR		label  near	; screenXOR(data^mask^pattern)
INVRSE <tst	cs:[inverseDriver]					>
INVRSE <jz	notInverse						>
INVRSE <not	si							>
	; Ok, this goes against style guidelines, but we need speed and
	; si back in its original form: duplicate three lines
	; and "ret" in the middle of this function.
INVRSE <and	dx, si							>
INVRSE <not	si							>
INVRSE <xor	ax, dx							>
INVRSE <ret								>
INVRSE <notInverse:							>
	and	dx, si
	xor	ax, dx
	ret

;-----------------

ModeSET		label  near	; (screen^~(data^mask))v(data^mask^setColor)
	not	dx
	and	ax, dx
	not	dx
	and	dx, cs:[setColor]
	or	ax, dx
	ret

;-----------------

ModeOR		label  near	; screen v (data^mask^pattern)
	and	dx, si
	or	ax, dx
	ret

ModeRoutines	endp



ifdef	REVERSE_WORD

MovAXESDI	proc	near
	pushf
	test	di, 1
	jnz	odd
	mov	ax, es:[di]
	xchg	al, ah
	popf
	ret

odd:
	mov	al, es:[di-1]
	mov	ah, es:[di+2]
	popf
	ret
MovAXESDI	endp



MovESDIAX	proc	near
	pushf
	test	di, 1
	jnz	odd
	xchg	al, ah
	mov	es:[di], ax
	xchg	al, ah
	popf
	ret

odd:
	mov	es:[di-1], al
	mov	es:[di+2], ah
	popf
	ret
MovESDIAX	endp



DoStosw	proc	near
	call	MovESDIAX
	lea	di, [di+2]
	ret
DoStosw	endp



DoRepStosw	proc	near
	jcxz	done

next:
	call	DoStosw
	loop	next

done:
	ret
DoRepStosw	endp



DoLodsbFar	proc	far
	call	DoLodsb
	ret
DoLodsbFar	endp



DoLodsb	proc	near
	pushf
	xornf	si, 1
	mov	al, ds:[si]
	xornf	si, 1
	inc	si
	popf
	ret
DoLodsb	endp



DoLodsbBackFar	proc	far
	call	DoLodsbBack
	ret
DoLodsbBackFar	endp



DoLodsbBack	proc	near
	pushf
	xornf	si, 1
	mov	al, ds:[si]
	xornf	si, 1
	dec	si
	popf
	ret
DoLodsbBack	endp



DoStosbFar	proc	far
	call	DoStosb
	ret
DoStosbFar	endp



DoStosb	proc	near
	pushf
	xornf	di, 1
	mov	es:[di], al
	xornf	di, 1
	inc	di
	popf
	ret
DoStosb	endp



DoStosbBackFar	proc	far
	call	DoStosbBack
	ret
DoStosbBackFar	endp



DoStosbBack	proc	near
	pushf
	xornf	di, 1
	mov	es:[di], al
	xornf	di, 1
	dec	di
	popf
	ret
DoStosbBack	endp



; ds = non-video memory
; es = video memory
DoMovsb	proc	near
	push	ax
	lodsb
	call	DoStosb
	pop	ax
	ret
DoMovsb	endp



; ds = non-video memory
; es = video memory
DoMovsw	proc	near
	push	ax
	lodsw
	call	DoStosw
	pop	ax
	ret
DoMovsw	endp



; ds, es = video memory
DoRepMovsbFar	proc	far
	call	DoRepMovsb
	ret
DoRepMovsbFar	endp

DoRepMovsb	proc	near
	pushf
	push	ax

	Assert	ne, cx, 0

	mov	ax, ds
	cmp	ax, SCREEN_BUFFER
	jne	movLoop3

	mov	ax, es
	cmp	ax, SCREEN_BUFFER
	jne	movLoop2

movLoop1:
	; video to video
	call	DoLodsb
	call	DoStosb
	loop	movLoop1
	jmp	done

movLoop2:
	; video to non-video
	call	DoLodsb
	stosb
	loop	movLoop2
	jmp	done


movLoop3:
	; non-video to video
if	ERROR_CHECK
	mov	ax, es
	Assert	e, ax, SCREEN_BUFFER
endif
	lodsb
	call	DoStosb
	loop	movLoop3

done:
	pop	ax
	popf
	ret
DoRepMovsb	endp



;
; only supports video->video
;
DoRepMovsbBackFar	proc	far
	pushf
	push	ax

	Assert	ne, cx, 0

if ERROR_CHECK
	mov	ax, ds
	Assert	e, ax, SCREEN_BUFFER

	mov	ax, es
	Assert	e, ax, SCREEN_BUFFER
endif

movLoop1:
	; video to video
	call	DoLodsbBack
	call	DoStosbBack
	loop	movLoop1

	pop	ax
	popf
	ret
DoRepMovsbBackFar	endp

endif	; REVERSE_WORD
