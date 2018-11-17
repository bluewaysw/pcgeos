COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VGALike Drivers
FILE:		vgacomChars.asm

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version
	jeremy	5/91		added support for EGA compatible cards,
				monochrome, and inverse monochrome EGA drivers.

DESCRIPTION:
	This file contains the character drawing routines for this driver.

	$Id: vgacomChars.asm,v 1.1 97/04/18 11:42:21 newdeal Exp $

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
	bl - BITMASK
	cl - shift count
	ch - number of lines to draw
	dx - GR_CONTROL
	on stack - ax

RETURN:
	ax - popped off stack

DESTROYED:
	ch, dx, bp, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	dest = (mask AND pattern) or (NOT mask AND screen)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version

-------------------------------------------------------------------------------@

MEGA <Char1In1Out	proc	near					>
MEGA <	mov	ah, cs:[patternBuffer]					>
MEGA <	clr	al			; set color fill index		>
MEGA <	out	dx, ax							>
MEGA <	jmp	short Char1In1OutEntry					>

C1I1O_loop:
	add	di,SCREEN_BYTE_WIDTH

CEGA <Char1In1Out	proc	near					>
MEGA <Char1In1OutEntry:							>
	lodsb				;al = mask
	ror	al,cl			;ax = mask shifted correctly
	mov	ah,al

	mov	al,bl
	out	dx,ax
	or	es:[di],al

	dec	ch
	jz	C1I1O_endLoop

	add	di,SCREEN_BYTE_WIDTH

	lodsb				;al = mask
	ror	al,cl			;ax = mask shifted correctly
	mov	ah,al

	mov	al,bl
	out	dx,ax
	or	es:[di],al

	dec	ch
	jz	C1I1O_endLoop

	add	di,SCREEN_BYTE_WIDTH

	lodsb				;al = mask
	ror	al,cl			;ax = mask shifted correctly
	mov	ah,al

	mov	al,bl
	out	dx,ax
	or	es:[di],al

	dec	ch
	jnz	C1I1O_loop
C1I1O_endLoop:
	pop	ax
	jmp	PSL_afterDraw

Char1In1Out	endp
	public	Char1In1Out

;-------------------------------

MEGA <Char1In2Out	proc	near					>
MEGA <	mov	ah, cs:[patternBuffer]					>
MEGA <	clr	al			; set color fill index		>
MEGA <	out	dx,ax							>
MEGA <	jmp	Char1In2OutEntry					>

C1I2O_loop:
	add	di,SCREEN_BYTE_WIDTH-1

CEGA <Char1In2Out	proc	near					>
MEGA <Char1In2OutEntry:							>
	lodsb				;ax = mask
	clr	ah
	ror	ax,cl			;ax = mask shifted correctly
	mov	bh,ah			;save extra bits
	mov	ah,al

	mov	al,bl
	out	dx,ax
	or	es:[di],al
	inc	di

	mov	ah,bh			;do other bits
	out	dx,ax
	or	es:[di],al

	dec	ch
	jz	C1I2O_endLoop

	add	di,SCREEN_BYTE_WIDTH-1

	lodsb				;ax = mask
	clr	ah
	ror	ax,cl			;ax = mask shifted correctly
	mov	bh,ah			;save extra bits
	mov	ah,al

	mov	al,bl
	out	dx,ax
	or	es:[di],al
	inc	di

	mov	ah,bh			;do other bits
	out	dx,ax
	or	es:[di],al

	dec	ch
	jnz	C1I2O_loop
C1I2O_endLoop:
	pop	ax
	jmp	PSL_afterDraw

Char1In2Out	endp
	public	Char1In2Out

;-------------------------------

MEGA <Char2In2Out	proc	near					>
MEGA <	mov	ah, cs:[patternBuffer]					>
MEGA <	clr	al			; set color fill index		>
MEGA <	out	dx, ax							>
MEGA <	jmp	Char2In2OutEntry					>

C2I2O_loop:
	add	di,SCREEN_BYTE_WIDTH-1

CEGA <Char2In2Out	proc	near					>
MEGA <Char2In2OutEntry:							>
	lodsw				;ax = mask
	ror	ax,cl			;ax = mask shifted correctly
	mov	bh,ah			;save extra bits
	mov	ah,al

	mov	al,bl
	out	dx,ax
	or	es:[di],al
	inc	di

	mov	ah,bh			;do other bits
	out	dx,ax
	or	es:[di],al

	dec	ch
	jz	C2I2O_endLoop

	add	di,SCREEN_BYTE_WIDTH-1

	lodsw				;ax = mask
	ror	ax,cl			;ax = mask shifted correctly
	mov	bh,ah			;save extra bits
	mov	ah,al

	mov	al,bl
	out	dx,ax
	or	es:[di],al
	inc	di

	mov	ah,bh			;do other bits
	out	dx,ax
	or	es:[di],al

	dec	ch
	jnz	C2I2O_loop
C2I2O_endLoop:
	pop	ax
	jmp	PSL_afterDraw

Char2In2Out	endp
	public	Char2In2Out

;-------------------------------

MEGA <Char2In3Out	proc	near					>
MEGA <	mov	ah, cs:[patternBuffer]					>
MEGA <	clr	al			; set color fill index		>
MEGA <	out	dx, ax							>
MEGA <	jmp	Char2In3OutEntry					>

C2I3O_loop:
	add	di,SCREEN_BYTE_WIDTH-2

CEGA <Char2In3Out	proc	near					>
MEGA <Char2In3OutEntry:							>
	lodsb				;al = mask, ah = extra data
	clr	ah
	ror	ax,cl			;ax = mask shifted correctly
	mov	bh,ah			;bh = extra bits
	mov	ah,al

	mov	al,bl
	out	dx,ax
	or	es:[di],al
	inc	di

	lodsb				;al = mask (byte 2)
	clr	ah
	ror	ax,cl			;ax = mask shifted correctly
	or	al,bh			;ax = mask with all bits correct
	mov	bh,ah			;bh = extra bits
	mov	ah,al

	mov	al,bl
	out	dx,ax
	or	es:[di],al
	inc	di

	mov	ah,bh			;do other bits
	out	dx,ax
	or	es:[di],al

	dec	ch
	jnz	C2I3O_loop

	pop	ax
	jmp	PSL_afterDraw

Char2In3Out	endp
	public	Char2In3Out

;-------------------------------

MEGA <Char3In3Out	proc	near					>
MEGA <	mov	ah, cs:[patternBuffer]					>
MEGA <	clr	al			; set color fill index		>
MEGA <	out	dx, ax							>
MEGA <	jmp	Char3In3OutEntry					>

C3I3O_loop:
	add	di,SCREEN_BYTE_WIDTH-2

CEGA <Char3In3Out	proc	near					>
MEGA <Char3In3OutEntry:							>
	lodsb				;al = mask, ah = extra data
	clr	ah
	ror	ax,cl			;ax = mask shifted correctly
	mov	bh,ah			;bh = extra bits
	mov	ah,al

	mov	al,bl
	out	dx,ax
	or	es:[di],al
	inc	di

	lodsb				;al = mask (byte 2)
	clr	ah
	ror	ax,cl			;ax = mask shifted correctly
	or	al,bh			;ax = mask with all bits correct
	mov	bh,ah			;bh = extra bits
	mov	ah,al

	mov	al,bl
	out	dx,ax
	or	es:[di],al
	inc	di

	lodsb				;al = mask (byte 3)
	clr	ah
	ror	ax,cl			;ax = mask shifted correctly
	or	al,bh			;ax = mask with all bits correct
	mov	ah,al

	mov	al,bl
	out	dx,ax
	or	es:[di],al

	dec	ch
	jnz	C3I3O_loop

	pop	ax
	jmp	PSL_afterDraw

Char3In3Out	endp
	public	Char3In3Out

;-------------------------------

MEGA <Char3In4Out	proc	near					>
MEGA <	mov	ah, cs:[patternBuffer]					>
MEGA <	clr	al			; set color fill index		>
MEGA <	out	dx, ax							>
MEGA <	jmp	Char3In4OutEntry					>

C3I4O_loop:
	add	di,SCREEN_BYTE_WIDTH-3

CEGA <Char3In4Out	proc	near					>
MEGA <Char3In4OutEntry:							>
	lodsb				;al = mask, ah = extra data
	clr	ah
	ror	ax,cl			;ax = mask shifted correctly
	mov	bh,ah			;bh = extra bits
	mov	ah,al

	mov	al,bl
	out	dx,ax
	or	es:[di],al
	inc	di

	lodsb				;al = mask (byte 2)
	clr	ah
	ror	ax,cl			;ax = mask shifted correctly
	or	al,bh			;ax = mask with all bits correct
	mov	bh,ah			;bh = extra bits
	mov	ah,al

	mov	al,bl
	out	dx,ax
	or	es:[di],al
	inc	di

	lodsb				;al = mask (byte 3)
	clr	ah
	ror	ax,cl			;ax = mask shifted correctly
	or	al,bh			;ax = mask with all bits correct
	mov	bh,ah			;bh = extra bits
	mov	ah,al

	mov	al,bl
	out	dx,ax
	or	es:[di],al
	inc	di

	mov	ah,bh			;do other bits
	out	dx,ax
	or	es:[di],al

	dec	ch
	jnz	C3I4O_loop

	pop	ax
	jmp	PSL_afterDraw

Char3In4Out	endp
	public	Char3In4Out

;-------------------------------

MEGA <Char4In4Out	proc	near					>
MEGA <	mov	ah, cs:[patternBuffer]					>
MEGA <	clr	al			; set color fill index		>
MEGA <	out	dx, ax							>
MEGA <	jmp	Char4In4OutEntry					>

C4I4O_loop:
	add	di,SCREEN_BYTE_WIDTH-3

CEGA <Char4In4Out	proc	near					>
MEGA <Char4In4OutEntry:							>
	lodsb				;al = mask, ah = extra data
	clr	ah
	ror	ax,cl			;ax = mask shifted correctly
	mov	bh,ah			;bh = extra bits
	mov	ah,al

	mov	al,bl
	out	dx,ax
	or	es:[di],al
	inc	di

	lodsb				;al = mask (byte 2)
	clr	ah
	ror	ax,cl			;ax = mask shifted correctly
	or	al,bh			;ax = mask with all bits correct
	mov	bh,ah			;bh = extra bits
	mov	ah,al

	mov	al,bl
	out	dx,ax
	or	es:[di],al
	inc	di

	lodsb				;al = mask (byte 3)
	clr	ah
	ror	ax,cl			;ax = mask shifted correctly
	or	al,bh			;ax = mask with all bits correct
	mov	bh,ah			;bh = extra bits
	mov	ah,al

	mov	al,bl
	out	dx,ax
	or	es:[di],al
	inc	di

	lodsb				;al = mask (byte 3)
	clr	ah
	ror	ax,cl			;ax = mask shifted correctly
	or	al,bh			;ax = mask with all bits correct
	mov	ah,al

	mov	al,bl
	out	dx,ax
	or	es:[di],al

	dec	ch
	jnz	C4I4O_loop

	pop	ax
	jmp	PSL_afterDraw

Char4In4Out	endp
	public	Char4In4Out
