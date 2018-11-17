COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Common screen driver code
FILE:		vidcomColor.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------
    GLB VidGetPalette		Get the current palette
    GLB VidSetPalette		Set the current palette

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	12/89	initial version


DESCRIPTION:
	Palette setting routines

	$Id: vidcomColor.asm,v 1.1 97/04/18 11:41:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


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
		mov	si, offset palCurRGBValues ; ds:si -> assume custom tab

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
done:
		.leave
		ret
VidGetPalette	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetPalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current palette

CALLED BY:	GLOBAL

PASS:		dx:si	- fptr to array of RGBValues
		ax	- palette register to start with
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

		; setup destination of write

		mov	es, cs			
		mov	di, offset palCurRGBValues ; es:di -> dest buffer
		mov	ds, dx			; ds:si -> source buffer

		; calc index to proper starting entry and loop for rest

		add	di, ax
		shl	ax, 1
		add	di, ax			; ds:si -> correct first entry
		cmp	cx, NUM_PAL_ENTRIES	; see if asking for too many
		jbe	calcSize
		mov	cx, NUM_PAL_ENTRIES	; limit count to # we actually
calcSize:					;  have
		mov	ax, cx
		shl	cx, 1
		add	cx, ax			; cx = 3*#entries
		rep	movsb			; copy block of RGB values
		call	SetDevicePalette	; call 
		.leave
		ret
VidSetPalette	endp

