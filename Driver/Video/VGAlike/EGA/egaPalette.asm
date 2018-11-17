
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Video driver
FILE:		egaPalette.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	7/89	initial version
	jeremy	5/91	added support for EGA compatible, monochrome,
			and inverse mono EGA drivers

DESCRIPTION:
	This file contains the default palette used by the EGA driver.
		
	$Id: egaPalette.asm,v 1.1 97/04/18 11:42:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDevicePalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the actual device palette

CALLED BY:	INTERNAL
		VidSetPalette
PASS:		palCurRGBValues buffer up to date
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDevicePalette	proc	near
		.enter
		.leave
		ret
SetDevicePalette	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixColorRGB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate a 24-bit RGB value to a valid 6-bit EGA palette
		entry

CALLED BY:	INTERNAL

PASS:		al	- red component
		bl	- green component
		bh	- blue component

RETURN:		al	- fixed red component
		bl	- fixed green component
		bh	- fixed blue component
		dl	- EGA palette entry

DESTROYED:	dh

PSEUDO CODE/STRATEGY:
		fix each component, combine results.
		form the correct EGA palette entry, with format:
			xxrgbRGB
		where:
			x 	- don't care
			r,g,b	- secondary components	( = 0x55 intensity)
			R,G,B	- primary components	( = 0xAA intensity)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	07/89		Initial version
	Jim	12/89		Fixed it so it gives the right values (oops)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	FixColorRGB
FixColorRGB	proc	near
		call	FixComponent		; fix red component
		shl	dh, 1			; shift bits to red spot
		shl	dh, 1
		mov	dl, dh			; save then in final place
		xchg	al, bl			; do green next, save new red
		call	FixComponent		; fix green component
		shl	dh, 1			; shift bits to green spot
		or	dl, dh			; combine with red bits
		xchg	al, bh			; do blue next, save green
		call	FixComponent		; fix blue component
		or	dl, dh			; finish ega palette bits
		xchg	al, bh			; get everything back in right
		xchg	al, bl			;  registers
		ret
FixColorRGB	endp


;	FixComponent - utility routine used by FixColorRGB
;
;	in:	al = component
;	out:	al = new component, dh = ega palette bits
;
;	the following mapping is used
;
;		orig intensity		new intensity		ega pal bits
;		0x00 - 0x2a		0x00			0000
;		0x2b - 0x7f		0x55			1000
;		0x80 - 0xd4		0xAA			0001
;		0xd5 - 0xff		0xFF			1001

FixComponent	proc	near
		tst	al			; first part of binary search
		js	highEnd
		cmp	al, 0x2a		; 0 or 1 ?
		ja	set55
		clr	ax			; total zero
		ret
set55:
		mov	ax, 0x5508		; one-third power
		ret
highEnd:
		cmp	al, 0xd5		; high filter
		jb	setAA
		mov	ax, 0xff09		; highest level
		ret
setAA:
		mov	ax, 0xaa01		; two-thirds level
		ret
FixComponent	endp

		

		; this holds the current palette register values (used
		; by the screen saver to restore registers)
palCurEntries	byte  0,1,2,3,4,5,14h,7,38h,39h,3ah,3bh,3ch,3dh,3eh,3fh
			byte  0                         ; for overscan reg  
