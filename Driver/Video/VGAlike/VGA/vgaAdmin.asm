COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		VGA Video Driver
FILE:		vgaAdmin.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name		Description
	----		-----------
	VidScreenOff	Turn off video output
	VidScreenOn	Turn on video output
	VidTestVGA	Test for existance of hardware
	VidSetVGA	Set 640x480 16-color mode

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	12/88	initial version
	jim	10/91	changed to moveable modules

DESCRIPTION:
	This file contains routines to implement some of the administrative 
	parts of the driver.

	$Id: vgaAdmin.asm,v 1.2 98/03/04 04:38:00 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

VideoMisc	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidScreenOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable video output, for a screen saver

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Disable the video output

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidScreenOff	proc	far
		.enter

		; first see if the screen is already blank

		dec	ss:videoEnabled		; is it enabled
		js	tooFar			;  oops, called it to often
		jne	done			; someone still wants it off

		; now do the disable thing. 

		mov	ah, ALT_SELECT		; choose BIOS function number
		mov	bl, VIDEO_SCREEN_ON_OFF ; choose sub-function number
		mov	al, VGA_DISABLE_VIDEO	; disable it this time
		int	VIDEO_BIOS
done:
		.leave
		ret

		; decremented too far, get back to zero
tooFar:
		mov	ss:videoEnabled, 0
		jmp	done
VidScreenOff	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidScreenOn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable video output, for a screen saver

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Disable the video output

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidScreenOn	proc	far
		.enter

		; first see if the screen is already enabled

		inc	ss:videoEnabled		; check for turn on
		cmp	ss:videoEnabled, 1	; is it enabled
		jg	done			;  yes, don't do it again
		mov	ss:videoEnabled, 1	;  no, make sure it;s one

		; enable video signal on card

		mov	ah, ALT_SELECT		; choose BIOS function number
		mov	bl, VIDEO_SCREEN_ON_OFF ; choose sub-function number
		mov	al, VGA_ENABLE_VIDEO	; disable video signal
		int	VIDEO_BIOS
done:
		.leave
		ret
VidScreenOn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestVGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for the existance of a device

CALLED BY:	GLOBAL
		DriverStrategy

PASS:		nothing

RETURN:		ax	- VideoPresent enum

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		check for the device

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidTestVGA	proc	near
		uses	bx
		.enter

		; use the Video Display Combination bios call to determine
		; if VGA is present

		mov	ah, 1ah			; function code
		clr	al			; al = 0 >> Get Display Comb
		int	VIDEO_BIOS		; make call to bios
		cmp	al, 1ah			; call successful ?
		mov	ax, DP_NOT_PRESENT	; assume not found (no use CLR)
		jne	exit			; no, bios doesn't support call

		; the call was successful, now check for the type of device

		cmp	bl, 7			; 7,8 = VGA (superset of MCGA)
		jb	exit			; must be MCGA or VGA
		cmp	bl, 8			; 7,8 = VGA (superset of MCGA)
		ja	exit			; must be MCGA or VGA
		mov	ax, DP_PRESENT		; signal found
		clc				;  and happy...
exit:
		.leave
		ret
VidTestVGA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetVGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize 640x480 16-color mode

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		use BIOS

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidSetVGA	proc	near
		uses	ax,dx, ds

		.enter

		; check with the Kernel to see if the Loader already switched
		; to this video mode, to display the splash screen

		segmov	ds, dgroup, ax
		test	ds:[driverState], mask VS_IGNORE_SPLASH_MODE
		jnz	setIt

		mov	ax, SGIT_CURRENT_SIMPLE_GRAPHICS_MODE
		call	SysGetInfo		;al = SysSimpleGraphicsMode
						;set by the loader (if any)

		cmp	al, SSGM_VGA		;VGA?
		je	done			;skip to end if so...

		;set the video mode for the VGA card

setIt:
		mov	ah, SET_VMODE		; function # to set video mode
		mov	al, GR0F_6448		; set up 640x480 graphics mode
		int	VIDEO_BIOS		; use video BIOS call
done:
		.leave
		ret
VidSetVGA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSet16Gray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets a 4- or 8- or 16-level greyscale palette

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidSet16GrayScale	proc	near	uses	dx
	.enter
	call	VidSetVGA

;	Now, set the palette appropriately

	mov	dx, offset Palette16
	call	SetPalette
	.leave
	ret
VidSet16GrayScale	endp

VidSet8GrayScale	proc	near	uses	dx
	.enter
	call	VidSetVGA

;	Now, set the palette appropriately

	mov	dx, offset Palette8
	call	SetPalette
	.leave
	ret
VidSet8GrayScale	endp

VidSet4GrayScale	proc	near	uses	dx
	.enter
	call	VidSetVGA

;	Now, set the palette appropriately

	mov	dx, offset Palette4
	call	SetPalette
	.leave
	ret
VidSet4GrayScale	endp

VidSetVGAII		proc	near	uses	dx
	.enter
	call	VidSetVGA

;	Now, set the palette appropriately

	mov	dx, offset PaletteVGAII
	call	SetPalette
	.leave
	ret
VidSetVGAII		endp

VidSetDefaultPalette	proc	near	uses	dx
	.enter
	call	VidSetVGA

;	Now, set the palette appropriately

	mov	dx, offset defVGAPalette
	call	SetPalette
	.leave
	ret
VidSetDefaultPalette	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the palette entries for the device

CALLED BY:	GLOBAL
PASS:		dx - offset of palette entry to set
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetPalette	proc	near
	.enter

	mov	bx, 0	;Start at index #0
	mov	di, dx
	segmov	es, cs			;ES:DX <- palette entries to set
	mov	cx, 16	;Set all 16 palette registers
next:
	push	bx, cx
	mov	ax, GET_PALREG
	int	VIDEO_BIOS		;BH <- color code read
	mov	bl, bh
	clr	bh			;BX <- color code
	mov	dh, es:[di]
	mov	ch, es:[di+1]
	mov	cl, es:[di+2]
	add	di, 3
	mov	ax, SET_DACREG
	int	VIDEO_BIOS
	pop	bx, cx
	inc	bx
	loop	next

	.leave
	ret
SetPalette	endp

Palette16	byte	00, 00, 00	; entry 0 -- black
		byte	05, 05, 05
		byte	08, 08, 08
		byte	11, 11, 11
		byte	14, 14, 14
		byte	17, 17, 17
		byte	20, 20, 20
		byte	24, 24, 24
		byte	28, 28, 28
		byte	32, 32, 32
		byte	36, 36, 36
		byte	40, 40, 40
		byte	45, 45, 45
		byte	50, 50, 50
		byte	56, 56, 56
		byte	63, 63, 63

Palette8	byte	00, 00, 00	; entry 0 -- black
		byte	14, 14, 14
		byte	22, 22, 22
		byte	29, 29, 29
		byte	36, 36, 36
		byte	45, 45, 45
		byte	54, 54, 54
		byte	63, 63, 63
		byte	00, 00, 00	; entry 8 -- black
		byte	14, 14, 14	;
		byte	22, 22, 22
		byte	29, 29, 29
		byte	36, 36, 36
		byte	45, 45, 45
		byte	54, 54, 54
		byte	63, 63, 63

Palette4	byte	00, 00, 00	; C_BLACK
		byte	21, 21, 21	; C_BLUE	 = C_DARK_GRAY
		byte	21, 21, 21	; C_GREEN	 = C_DARK_GRAY
		byte	21, 21, 21	; C_CYAN	 = C_DARK_GRAY
		byte	21, 21, 21	; C_RED		 = C_DARK_GRAY
		byte	21, 21, 21	; C_VIOLET	 = C_DARK_GRAY
		byte	21, 21, 21	; C_BROWN	 = C_DARK_GRAY
		byte	42, 42, 42	; C_LIGHT_GRAY
		byte	21, 21, 21	; C_DARK_GRAY
		byte	42, 42, 42	; C_LIGHT_BLUE	 = C_LIGHT_GRAY
		byte	42, 42, 42	; C_LIGHT_GREEN	 = C_LIGHT_GRAY
		byte	42, 42, 42	; C_LIGHT_CYAN	 = C_LIGHT_GRAY
		byte	42, 42, 42	; C_LIGHT_RED	 = C_LIGHT_GRAY
		byte	42, 42, 42	; C_LIGHT_VIOLET = C_LIGHT_GRAY
		byte	42, 42, 42	; C_YELLOW	 = C_LIGHT_GRAY
		byte	63, 63, 63	; C_WHITE

PaletteVGAII	byte	00, 00, 00	; entry 0 -- black
		byte	00, 00, 42
		byte	00, 42, 00
		byte	00, 42, 42
		byte	42, 00, 00
		byte	42, 00, 42
		byte	42, 21, 00
		byte	48, 48, 48	; brighter light gray
		byte	32, 32, 32	; brighter dark gray
		byte	21, 21, 63
		byte	21, 63, 21
		byte	21, 63, 63
		byte	63, 21, 21
		byte	63, 21, 63
		byte	63, 63, 21
		byte	63, 63, 63	; entry 15 -- white

defVGAPalette	label	byte
		byte	0x00, 0x00, 0x00
		byte	0x00, 0x00, 0x2a
		byte	0x00, 0x2a, 0x00
		byte	0x00, 0x2a, 0x2a
		byte	0x2a, 0x00, 0x00
		byte	0x2a, 0x00, 0x2a
		byte	0x2a, 0x15, 0x00
		byte	0x2a, 0x2a, 0x2a
		byte	0x15, 0x15, 0x15
		byte	0x15, 0x15, 0x3f
		byte	0x15, 0x3f, 0x15
		byte	0x15, 0x3f, 0x3f
		byte	0x3f, 0x15, 0x15
		byte	0x3f, 0x15, 0x3f
		byte	0x3f, 0x3f, 0x15
		byte	0x3f, 0x3f, 0x3f

VideoMisc	ends
