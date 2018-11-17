COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Dumb Raster Video Drivers
FILE:		dumbcomChars.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	VidPutChar		Draw a plaintext character to the screen

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version

DESCRIPTION:
	This file contains the character drawing routines for this driver.

	$Id: dumbcomChars.asm,v 1.1 97/04/18 11:42:29 newdeal Exp $

-------------------------------------------------------------------------------@

COMMENT @-----------------------------------------------------------------------

FUNCTION:	CharXInYOut

DESCRIPTION:	Low level routine to draw a character when the source is
		X bytes wide and the destination is Y bytes wide, the drawing
		mode in GR_COPY and the character is entirely visible.

CALLED BY:	INTERNAL
		DrawVisibleChar

PASS:
	ds:si - character data
	es:di - screen position
	bx - pattern index
	cl - shift count
	ch - number of lines to draw
	on stack - ax

RETURN:
	ax - popped off stack

DESTROYED:
	ch, dx, bp, si, di

REGISTER/STACK USAGE:
	Char1In1Out:
		al - mask
		ah - NOT mask
		dl - temporary
	Char1In2Out, Char2In2Out:
		ax - mask
		bp - NOT mask
		dx - temporary

PSEUDO CODE/STRATEGY:
	dest = (mask AND pattern) or (NOT mask AND screen)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version

-------------------------------------------------------------------------------@

C1I1O_loop:
	inc	bx			;increment pattern pointer
	and	bl,7
	NextScan di
MEM <	tst	cs:[bm_scansNext]	; if negative, off end of bitmap >
MEM <	js	C1I1O_endLoop		;  so bail			>

Char1In1Out	proc		near
	lodsb				;al = mask
	ror	al,cl			;al = mask shifted correctly
	mov	ah,al
BIT <	and	al,byte ptr cs:[bx][ditherMatrix] ;al = mask AND pattern >
	not	ah			; ah = NOT mask
RW <	xornf di, 1h							>
	mov	dl, es:[di]		; dl = screen
RW <	xornf di, 1h							>
	and	dl, ah
	or	al,dl			;al = data to store
RW <	xornf di, 1h							>
	mov	es:[di], al
RW <	xornf di, 1h							>
	dec	ch
	jz	C1I1O_endLoop

	inc	bx			;increment pattern pointer
	and	bl,7
	NextScan di
MEM <	tst	cs:[bm_scansNext]	; if negative, off end of bitmap >
MEM <	js	C1I1O_endLoop		;  so bail			>


	lodsb				;al = mask
	ror	al,cl			;al = mask shifted correctly
	mov	ah,al 
BIT <	and	al,byte ptr cs:[bx][ditherMatrix] ;al = mask AND pattern >
	not	ah

RW <	xornf di, 1h							>
	mov	dl,es:[di]		;dl = screen
RW <	xornf di, 1h							>
	and	dl,ah			;dl = NOT mask AND screen
	or	al,dl			;al = data to store
RW <	xornf di, 1h							>
	mov	es:[di], al
RW <	xornf di, 1h							>
	dec	ch
BIT <	jnz	C1I1O_loop						>

C1I1O_endLoop label near
	pop	ax
	jmp	PSL_afterDraw

Char1In1Out	endp

;-------------------------------

C1I2O_loop:
	inc	bx			;increment pattern pointer
	and	bl,7
	NextScan di
MEM <	tst	cs:[bm_scansNext]	; if negative, off end of bitmap >
MEM <	js	C1I2O_endLoop		;  so bail			>

Char1In2Out	proc		near
	lodsb				;ax = mask
	clr	ah
	ror	ax,cl			;ax = mask shifted correctly
	mov	bp,ax
	not	bp			;bp = NOT mask
	mov	dl, {byte} cs:[bx][ditherMatrix];dx = pattern
	mov	dh,dl
	and	ax,dx			;ax = mask AND pattern
ifdef	REVERSE_WORD
	mov_tr	dx, ax
	call	MovAXESDI
	xchg	dx, ax
else
	mov	dx,es:[di]		;dx = screen
endif
	and	dx, bp			;dx = NOT mask AND screen
	or	ax,dx			;ax = data to store
ifdef	REVERSE_WORD
	call	MovESDIAX
else
	mov	es:[di], ax
endif
	dec	ch
	jz	C1I2O_endLoop

	inc	bx			;increment pattern pointer
	and	bl,7
	NextScan di
MEM <	tst	cs:[bm_scansNext]	; if negative, off end of bitmap >
MEM <	js	C1I2O_endLoop		;  so bail			>

	lodsb				;ax = mask
	clr	ah
	ror	ax,cl			;ax = mask shifted correctly
	mov	bp,ax
	not	bp			;bp = NOT mask
	mov	dl,{byte} cs:[bx][ditherMatrix];dx = pattern
	mov	dh,dl
	and	ax,dx			;ax = mask AND pattern
ifdef	REVERSE_WORD
	mov_tr	dx, ax
	call	MovAXESDI
	xchg	dx, ax
else
	mov	dx,es:[di]		;dx = screen
endif
	and	dx,bp			;dx = NOT mask AND screen
	or	ax,dx			;ax = data to store
ifdef	REVERSE_WORD
	call	MovESDIAX
else
	mov	es:[di], ax
endif
	dec	ch
BIT <	jnz	C1I2O_loop						>

C1I2O_endLoop label near
	pop	ax
	jmp	PSL_afterDraw

Char1In2Out	endp

;-------------------------------

C2I2O_loop:
	inc	bx			;increment pattern pointer
	and	bl,7
	NextScan di
MEM <	tst	cs:[bm_scansNext]	; if negative, off end of bitmap >
MEM <	js	C2I2O_endLoop		;  so bail			>

Char2In2Out	proc		near
	lodsw				;ax = mask
	ror	ax,cl			;ax = mask shifted correctly
	mov	bp,ax
	not	bp			;bp = NOT mask
	mov	dl,{byte} cs:[bx][ditherMatrix];dx = pattern
	mov	dh,dl
	and	ax,dx			;ax = mask AND pattern
ifdef	REVERSE_WORD
	mov_tr	dx, ax
	call	MovAXESDI
	xchg	dx, ax
else
	mov	dx,es:[di]		;dx = screen
endif
	and	bp,dx			;bp = NOT mask AND screen
	or	ax,bp			;ax = data to store
ifdef	REVERSE_WORD
	call	MovESDIAX
else
	mov	es:[di], ax
endif
	dec	ch
	jz	C2I2O_endLoop

	inc	bx			;increment pattern pointer
	and	bl,7
	NextScan di
MEM <	tst	cs:[bm_scansNext]	; if negative, off end of bitmap >
MEM <	js	C2I2O_endLoop		;  so bail			>

	lodsw				;ax = mask
	ror	ax,cl			;ax = mask shifted correctly
	mov	bp,ax
	not	bp			;bp = NOT mask
	mov	dl,{byte} cs:[bx][ditherMatrix];dx = pattern
	mov	dh,dl
	and	ax,dx			;ax = mask AND pattern
ifdef	REVERSE_WORD
	mov_tr	dx, ax
	call	MovAXESDI
	xchg	dx, ax
else
	mov	dx,es:[di]		;dx = screen
endif
	and	bp,dx			;bp = NOT mask AND screen
	or	ax,bp			;ax = data to store
ifdef	REVERSE_WORD
	call	MovESDIAX
else
	mov	es:[di], ax
endif
	dec	ch
BIT <	jnz	C2I2O_loop						>

C2I2O_endLoop label near
	pop	ax
	jmp	PSL_afterDraw

Char2In2Out	endp

;-------------------------------

C2I3O_loop:
	inc	bx			;increment pattern pointer
	and	bl,7
	NextScan di
MEM <	tst	cs:[bm_scansNext]	; if negative, off end of bitmap >
MEM <	js	C2I3O_endLoop		;  so bail			>

Char2In3Out	proc		near
	lodsb				;al = mask, ah = extra data
	clr	ah
	ror	ax,cl			;ax = mask shifted correctly
	mov	dh,al
BIT <	and	al,{byte} cs:[bx][ditherMatrix];al = mask AND pattern >
RW <	xornf di, 1							>
	mov	dl,es:[di]		;dl = screen
RW <	xornf di, 1							>
	not	dh			;dh = NOT mask
	and	dl,dh			;dl = NOT mask AND screen
	or	al,dl			;al = data to store
ifdef	REVERSE_WORD
	call	DoStosb
else
	stosb
endif
	mov	dl,ah			;dl = extra bits
	lodsb				;al = mask (byte 2)
	clr	ah
	ror	ax,cl			;ax = mask shifted correctly
	or	al,dl			;ax = mask with all bits correct

	mov	bp,ax
	not	bp			;bp = NOT mask
	mov	dl,{byte} cs:[bx][ditherMatrix];dx = pattern
	mov	dh,dl
	and	ax,dx			;ax = mask AND pattern
ifdef	REVERSE_WORD
	mov_tr	dx, ax
	call	MovAXESDI
	xchg	dx, ax
else
	mov	dx,es:[di]		;dx = screen
endif
	and	bp,dx			;bp = NOT mask AND screen
	or	ax,bp			;ax = data to store
ifdef	REVERSE_WORD
	call	MovESDIAX
else
	mov	es:[di], ax
endif
	dec	di
	dec	ch
BIT <	jnz	C2I3O_loop						>
MEM <C2I3O_endLoop	label near					>
	pop	ax
	jmp	PSL_afterDraw

Char2In3Out	endp

;-------------------------------

C3I3O_loop:
	inc	bx			;increment pattern pointer
	and	bl,7
	NextScan di
MEM <	tst	cs:[bm_scansNext]	; if negative, off end of bitmap >
MEM <	js	C3I3O_endLoop		;  so bail			>

Char3In3Out	proc		near
	lodsb				;al = mask, ah = extra data
	clr	ah
	ror	ax,cl			;ax = mask shifted correctly
	mov	dh,al
BIT <	and	al,{byte} cs:[bx][ditherMatrix];al = mask AND pattern >
	not	dh			;dh = NOT mask
RW <	xornf di, 1							>
	mov	dl,es:[di]		;dl = screen
RW <	xornf di, 1							>
	and	dl,dh			;dl = NOT mask AND screen
	or	al,dl			;al = data to store
ifdef	REVERSE_WORD
	call	DoStosb
else
	stosb
endif
	mov	dl,ah			;dl = extra bits
	lodsw				;al = mask (bytes 2 and 3)
	ror	ax,cl			;ax = mask shifted correctly
	or	al,dl			;ax = mask with all bits correct

	mov	bp,ax
	not	bp			;bp = NOT mask
	mov	dl,{byte} cs:[bx][ditherMatrix];dx = pattern
	mov	dh,dl
	and	ax,dx			;ax = mask AND pattern
ifdef	REVERSE_WORD
	mov_tr	dx, ax
	call	MovAXESDI
	xchg	dx, ax
else
	mov	dx,es:[di]		;dx = screen
endif
	and	bp,dx			;bp = NOT mask AND screen
	or	ax,bp			;ax = data to store
ifdef	REVERSE_WORD
	call	MovESDIAX
else
	mov	es:[di], ax
endif
	dec	di
	dec	ch
BIT <	jnz	C3I3O_loop						>
MEM <C3I3O_endLoop label near						>
	pop	ax
	jmp	PSL_afterDraw

Char3In3Out	endp

;-------------------------------

C3I4O_loop:
	inc	bx			;increment pattern pointer
	and	bl,7
	NextScan di
MEM <	tst	cs:[bm_scansNext]	; if negative, off end of bitmap >
MEM <	js	C3I4O_endLoop		;  so bail			>

Char3In4Out	proc		near
	lodsb				;al = mask, ah = extra data
	clr	ah
	ror	ax,cl			;ax = mask shifted correctly
	mov	dh,al
BIT <	and	al,{byte} cs:[bx][ditherMatrix];al = mask AND pattern>
	not	dh			;dh = NOT mask
RW <	xornf di, 1							>
	mov	dl,es:[di]		;dl = screen
RW <	xornf di, 1							>
	and	dl,dh			;dl = NOT mask AND screen
	or	al,dl			;al = data to store
ifdef	REVERSE_WORD
	call	DoStosb
else
	stosb
endif
	mov	dl,ah			;dl = extra bits
	lodsb				;al = mask (byte 2)
	clr	ah
	ror	ax,cl			;ax = mask shifted correctly
	or	al,dl
	mov	dh,al
BIT <	and	al,{byte} cs:[bx][ditherMatrix];al = mask AND pattern >
	not	dh			;dh = NOT mask
RW <	xornf di, 1							>
	mov	dl,es:[di]		;dl = screen
RW <	xornf di, 1							>
	and	dl,dh			;dl = NOT mask AND screen
	or	al,dl			;al = data to store
ifdef	REVERSE_WORD
	call	DoStosb
else
	stosb
endif
	mov	dl,ah			;dl = extra bits
	lodsb				;al = mask (byte 3)
	clr	ah
	ror	ax,cl			;ax = mask shifted correctly
	or	al,dl			;ax = mask with all bits correct

	mov	bp,ax
	not	bp			;bp = NOT mask
	mov	dl,{byte} cs:[bx][ditherMatrix];dx = pattern
	mov	dh,dl
	and	ax,dx			;ax = mask AND pattern
ifdef	REVERSE_WORD
	mov_tr	dx, ax
	call	MovAXESDI
	xchg	dx, ax
else
	mov	dx,es:[di]		;dx = screen
endif
	and	bp,dx			;bp = NOT mask AND screen
	or	ax,bp			;ax = data to store
ifdef	REVERSE_WORD
	call	DoStosw
else
	stosw
endif
	sub	di, 4
	dec	ch
BIT <	jnz	C3I4O_loop						>
MEM <C3I4O_endLoop label near						>
	pop	ax
	jmp	PSL_afterDraw

Char3In4Out	endp

;-------------------------------

C4I4O_loop:
	inc	bx			;increment pattern pointer
	and	bl,7
	NextScan di
MEM <	tst	cs:[bm_scansNext]	; if negative, off end of bitmap >
MEM <	js	C4I4O_endLoop		;  so bail			>

Char4In4Out	proc		near
	lodsb				;al = mask, ah = extra data
	clr	ah
	ror	ax,cl			;ax = mask shifted correctly
	mov	dh,al
BIT <	and	al,{byte} cs:[bx][ditherMatrix];al = mask AND pattern>
	not	dh			;dh = NOT mask
RW <	xornf di, 1							>
	mov	dl,es:[di]		;dl = screen
RW <	xornf di, 1							>
	and	dl,dh			;dl = NOT mask AND screen
	or	al,dl			;al = data to store
ifdef	REVERSE_WORD
	call	DoStosb
else
	stosb
endif
	mov	dl,ah			;dl = extra bits
	lodsb				;al = mask (byte 2)
	clr	ah
	ror	ax,cl			;ax = mask shifted correctly
	or	al,dl
	mov	dh,al
BIT <	and	al,{byte} cs:[bx][ditherMatrix];al = mask AND pattern>
	not	dh			;dh = NOT mask
RW <	xornf di, 1							>
	mov	dl,es:[di]		;dl = screen
RW <	xornf di, 1							>
	and	dl,dh			;dl = NOT mask AND screen
	or	al,dl			;al = data to store
ifdef	REVERSE_WORD
	call	DoStosb
else
	stosb
endif
	mov	dl,ah			;dl = extra bits
	lodsw				;al = mask (bytes 3 and 4)
	ror	ax,cl			;ax = mask shifted correctly
	or	al,dl			;ax = mask with all bits correct

	mov	bp,ax
	not	bp			;bp = NOT mask
	mov	dl,{byte} cs:[bx][ditherMatrix];dx = pattern
	mov	dh,dl
	and	ax,dx			;ax = mask AND pattern
ifdef	REVERSE_WORD
	mov_tr	dx, ax
	call	MovAXESDI
	xchg	dx, ax
else
	mov	dx,es:[di]		;dx = screen
endif
	and	bp,dx			;bp = NOT mask AND screen
	or	ax,bp			;ax = data to store
ifdef	REVERSE_WORD
	call	DoStosw
else
	stosw
endif
	sub	di, 4
	dec	ch
BIT <	jnz	C4I4O_loop						>
MEM <C4I4O_endLoop label near						>
	pop	ax
	jmp	PSL_afterDraw

Char4In4Out	endp








