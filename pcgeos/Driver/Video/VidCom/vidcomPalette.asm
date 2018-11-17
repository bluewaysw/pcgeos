COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers
FILE:		vidcomPalette.asm

AUTHOR:		Jim DeFrisco, Aug  6, 1992

ROUTINES:
	Name			Description
	----			-----------
    GLB VidGetPalette		Get the current palette
    GLB VidSetPalette		Set the current palette
    GLB VidGetPixel		Get a single pixel from the screen.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	8/ 6/92		Initial revision


DESCRIPTION:
	A few common palette related routines
		
	$Id: vidcomPalette.asm,v 1.1 97/04/18 11:41:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifndef	IS_MEM

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidGetPalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current palette

CALLED BY:	GLOBAL

PASS:		ax	- starting index
		cx	- count of RGBValues to return
		dx:si	- pointer to buffer to fill if GSPF_SINGLE clear

RETURN:		buffer at dx:si filled with RGBValues
		cx	- #entries returned (could be less than requested)

DESTROYED:	none

PSEUDO CODE/STRATEGY:
		just copy over the table.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	07/89		Initial version
	Jim	12/89		Small changes to interface

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidGetPalette	proc	near
		uses	ds,es,di,cx,dx,si
		.enter

		mov	di, si			; set es:di-> buffer
		mov	es, dx

		segmov	ds, ss, si		; copy from table in dgroup
		mov	si, offset currentPalette ; ds:si -> assume custom tab

		; calc index to proper starting entry and loop for rest

		add	si, ax
		shl	ax, 1
		add	si, ax			; ds:si -> correct first entry
		cmp	cx, NUM_PAL_ENTRIES	; see if asking for too many
		jbe	calcSize
		mov	cx, NUM_PAL_ENTRIES	; limit count to # we actually
calcSize:					;  have
		mov	ax, cx
		shl	cx, 1
		add	cx, ax			; cx = 3*#entries
		rep	movsb			; copy block of RGB values

		.leave
		ret
VidGetPalette	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetPalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current palette

CALLED BY:	GLOBAL

PASS:		dx:si	- fptr to array of RGBValues
		ah	- 0 for custom palette
			- 1 for default palette
		al	- palette register to start with
		cx	- count of palette registers to change
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	07/89		Initial version
	Jim	10/92		Rewritten with new API

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSetPalette	proc	near
		uses	ds
		.enter

		; check to see if we are setting the default palette, and
		; it already is set.

		tst	ah			; 1=default
		jz	setCustom
		cmp	ah, cs:[defPalFlag]	; if already default, bail
		je	exit

		; setup destination of write
setCustom:
		mov	cs:[defPalFlag], ah	; set new flag
		clr	ah
		segmov	es, cs			
		mov	di, offset currentPalette ; es:di -> dest buffer
		mov	ds, dx			; ds:si -> source buffer

;	Modify CX so we don't try to store data outside of NUM_PAL_ENTRIES...

		add	cx, ax
		cmp	cx, NUM_PAL_ENTRIES
		jbe	10$
		mov	cx, NUM_PAL_ENTRIES
10$:
		sub	cx, ax
		jbe	exit

		; calc index to proper starting entry and loop for rest

		add	di, ax
		shl	ax, 1
		add	di, ax			; ds:si -> correct first entry
		mov	ax, cx
		shl	cx, 1
		add	cx, ax			; cx = 3*#entries
		rep	movsb			; copy block of RGB values

ifndef IS_CLR24
		call	SetDevicePalette
endif

exit:
		.leave
		ret
VidSetPalette	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidGetPixel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a single pixel from the screen.

CALLED BY:	GLOBAL
PASS:		ax, bx	- pixel coordinate
RETURN:		ah	- raw frame buffer value (except for 24bit devices)
		al	- pixel color (red component)
		bl	- pixel color (green component)
		bh	- pixel color (blue component)
DESTROYED:	

PSEUDO CODE/STRATEGY:
		Grab the 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	8/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidGetPixel		proc	near
ifndef		IS_CMYK
		uses	ds, si, cx, dx
		.enter

		; we want ds:si -> right block of pixels

		SetBuffer ds, cx		; set ds->frame buffer
		mov	si, bx			; calc ptr in si
		clr	cx
		CalcScanLine	si, cx, ds	; ds:si -> frame buffer offset

		; now get the index value.  It's a little different for 
		; each type of device.

ifndef	IS_CLR24

		; it's easy for 8bit devices
C8 <		add	si, ax			; get right pixel	>
C8 <		lodsb				; have index		>

		; a bit more trouble for monochrome
MONO <		mov	bx, ax			; save x value		>
MONO <		and	bx, 7			; isolate bit position 	>
MONO <		mov	cl, 3			; need byte index	>
MONO <		shr	ax, cl			; ax = byte index	>
MONO <		add	si, ax			; ds:si -> right byte	>
MONO <		lodsb				; get byte value	>
MONO <		and	al, cs:[monoBitPos][bx]	; isolate byte		>
MONO <		tst	al			; if set, move to first bit >
MONO <		jz	haveIndex					>
MONO <		mov	al, 1			; if not zero, it's one	>

ifdef IS_MEM
C4 <		mov	bx, ax			; save x value		>
C4 <		shr	ax, 1			; get byte index	>
C4 <		add	si, ax			; ds:si -> byte 	>
C4 <		lodsb				; grab byte		>
C4 <		test	bl, 1			; to see which nibble	>
C4 <		jnz	haveShift		; right nibble aligned	>
C4 <		mov	cl, 4			; shift 4 times		>
C4 <		shr	al, cl			; get pixel in right nibble >
C4 <haveShift:								>
C4 <		and	al, 0xf			; isolate pixel		>
endif

		; it's a bit tricky for EGA-like devices		
ifdef IS_VGALIKE
C4 <		mov	bx, ax			; save x value		>
C4 <		and	bx, 7			; isolate bit position 	>
C4 <		mov	cl, 3			; need byte index	>
C4 <		shr	ax, cl			; ax = byte index	>
C4 <		add	si, ax			; ds:si -> right byte	>
C4 <		mov	ah, cs:[pixelMask][bx]	; get pixel mask	>
C4 <		mov	cl, cs:[pixelShift][bx]	; and shift count	>
C4 <		call	ReadVGAPixel		; get pixel in al	>
endif
		; OK, we have the palette index.  Load up the components.
		; This code is common to all drivers except 24-bit
MONO <haveIndex:							>
		clr	ah			; make it a word
		mov	cl, al			; save index
		mov	bx, ax			; *3 to index into palette
		shl	ax, 1
		add	bx, ax			; bx = palette byte index
		mov	al, cs:[currentPalette][bx].RGB_red ; get RED
		mov	ah, cl			; restore index
		mov	bx, {word}cs:[currentPalette][bx+1]
else
		CLR24GetPixel
endif

MEM <		ReleaseHugeArray		; release data block >
		.leave
endif
		ret
VidGetPixel		endp

MONO <monoBitPos	label	byte					>
MONO <		byte	0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01	>

ifdef	IS_VGALIKE
;--------	utility routine used by GetOneScan.  Reads entire byte into
;		four registers (bh,bl,ch,cl). assumes ds:si -> screen buffer
;		trashes ax,dx. bumps si

C4 <ReadVGAPixel	proc	near		; reads 4 bit planes into regs>
C4 <		mov	al, READ_MAP_0					>
C4 <		mov	dx, GR_CONTROL		; set up i/o address	>
C4 <		out	dx, al			; point cntrlr at map reg >
C4 <		inc	dx			; point at cntlr data reg >
C4 <		mov	al, 3			; start with plane 3	>
C4 <		out	dx, al						>
C4 <		mov	bh, ds:[si]		; get plane 3 data	>
C4 <		and	bh, ah			; isolate pixel		>
C4 <		ror	bh, cl						>
C4 <		inc	cl						>
C4 <		dec	ax			; to next plane 	>
C4 <		out	dx, al						>
C4 <		mov	bl, ds:[si]		; get plane 2 data	>
C4 <		and	bl, ah						>
C4 <		ror	bl, cl						> 
C4 <		or	bh, bl						>
C4 <		inc	cl						>
C4 <		dec	ax			; to next plane 	>
C4 <		out	dx, al						>
C4 <		mov	bl, ds:[si]		; get plane 1 data	>
C4 <		and	bl, ah						>
C4 <		ror	bl, cl						>
C4 <		or	bh, bl						>
C4 <		inc	cx						>
C4 <		dec	ax			; to next plane 	>
C4 <		out	dx, al						>
C4 <		lodsb				; get plane 0 data & advance>
C4 <		and	al, ah						>
C4 <		ror	al, cl						>
C4 <		or	al, bh			;  return result in al 	>
C4 <		ret							>
C4 <ReadVGAPixel	endp						>

C4 <pixelMask	label	byte						>
C4 <		byte	0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01	>
C4 <pixelShift	label	byte						>
C4 <		byte	4, 3, 2, 1, 0, 7, 6, 5				>

endif
