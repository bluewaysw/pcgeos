COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1998 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Cyber16 Video Driver
FILE:		cyber16Admin.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name		Description
	----		-----------
	VidScreenOn	turn on video
	VidScreenOff	turn off video

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jim	10/92	initial version
	FR	09/97	update for 16 bit devices

DESCRIPTION:
	This file contains routines to implement some of the administrative 
	parts of the driver.

	$Id: cyber16Admin.asm,v 1.2$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSegment	Misc


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
		VidTestIGSCyberPro
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for IGS CyberPro board

CALLED BY:	INTERNAL
		VidTestDevice

PASS:		nothing
RETURN:		ax	= DevicePresent enum
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		call Cyber16 inquiry functins

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidTestIGSCyberPro	proc	near
		mov	ax, DP_PRESENT		; yep, it's there
		ret
VidTestIGSCyberPro	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetIGSCyberPro
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set IGS CyberPro 64K-color mode

CALLED BY:	INTERNAL
		VidSetDevice

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if ALLOW_BIG_MOUSE_POINTER
bigPointerKey		char	"bigMousePointer",0
endif ; ALLOW_BIG_MOUSE_POINTER
	
VidSetIGSCyberPro	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter

		mov	ax, ss:[DriverTable].VDI_device
		mov	ss:[cyberProMode], ax

		call	SetIGSMode

		mov	ss:[modeInfo].VMI_scanSize, 640*2
		tst	ss:[tvMode]
		jnz	gotScanSize

		mov	si, ss:[cyberProMode]
		push	si
		shr	si, 1			; byte-sized table
		mov	al, cs:[displayTypeTable][si]
		pop	si
		mov	ss:[DriverTable].VDI_displayType, al

		mov	ax, cs:[displayWidthTable][si]
		mov	ss:[DriverTable].VDI_pageW, ax

		add	ax, ax			; 2 bytes / pixel
		mov	ss:[DriverTable].VDI_bpScan, ax
		mov	ss:[modeInfo].VMI_scanSize, ax

		mov	ax, cs:[displayHeightTable][si]
		mov	ss:[DriverTable].VDI_pageH, ax

		mov	ax, cs:[displayResTable][si]
		mov	ss:[DriverTable].VDI_hRes, ax
		mov	ss:[DriverTable].VDI_vRes, ax

gotScanSize:
if	SAVE_UNDER_COUNT gt 0
		; Calculate start of save-under area, and the size.
		mov	ax, ss:[DriverTable].VDI_bpScan
		mul	ss:[DriverTable].VDI_pageH
		movdw	ss:[suSaveAreaStart], dxax
		mov	bx, dx
		mov_tr	si, ax			; bxsi = save-under start addr

		; HACK: On 2meg VRAM machines, the hardware reports 2megs
		; correctly.  But on 1meg machines, the hardware still reports
		; 2megs.  Since the final hardware will be 1meg, we hard-code
		; the amount to be 1meg instead of relying on the value from
		; hardware.  -- ayuen 1/28/00
		;;;call	GetVMemSize		; cl = log2 (# megs)
		clr	cl			; cl = log2 (1)

		mov	dx, 16
		shl	dx, cl
		clr	ax			; dxax = total VRAM size
		subdw	dxax, bxsi		; dxax = save under size
		movdw	ss:[suSaveAreaSize], dxax
endif	; SAVE_UNDER_COUNT gt 0

if ALLOW_BIG_MOUSE_POINTER
		; default cursor size is big for TV, user-chosen in
		; Preferences for monitor.
		; can override using screen0::bigMousePointer = true/false.
	
		mov	al, TRUE	; assume default to big ptr
		tst	ss:[tvMode]
		jnz	hasDefault	; => TV mode, default to big ptr
			; Hack: make use of the fact that all the big-pointer
			; VideoDevice enums are divisible by 4 and all the
			; small-pointer ones are not.
			CheckHack <not (VD_IGS_CYBER_PRO_640x480_16_SP and 2)>
			CheckHack <not (VD_IGS_CYBER_PRO_800x600_16_SP and 2)>
if	ALLOW_1Kx768_16
			CheckHack <not (VD_IGS_CYBER_PRO_1Kx768_16_SP and 2)>
endif	; ALLOW_1Kx768_16
			CheckHack <VD_IGS_CYBER_PRO_640x480_16_BP and 2>
			CheckHack <VD_IGS_CYBER_PRO_800x600_16_BP and 2>
if	ALLOW_1Kx768_16
			CheckHack <VD_IGS_CYBER_PRO_1Kx768_16_BP and 2>
endif	; ALLOW_1Kx768_16
		test	ss:[cyberProMode], 0x0002
		jnz	hasDefault	; => even, default to big ptr
		clr	ax		; default to small ptr
hasDefault:
		mov	cx, cs
		mov	dx, offset bigPointerKey
		segmov	ds, dgroup
		mov	si, offset screenCategory
		call	InitFileReadBoolean
		tst	al
		jz	afterCursor
		mov	ss:[cursorSize], CUR_SIZE * 2
afterCursor:
endif ; ALLOW_BIG_MOUSE_POINTER

		.leave
		ret
VidSetIGSCyberPro	endp

if	ALLOW_BIG_MOUSE_POINTER

displayTypeTable	label	DisplayType
	DisplayType	VGA24_DISPLAY_TYPE; VD_IGS_CYBER_PRO_640x480_16_SP
	DisplayType	VGA24_DISPLAY_TYPE; VD_IGS_CYBER_PRO_640x480_16_BP
	DisplayType	SVGA24_DISPLAY_TYPE; VD_IGS_CYBER_PRO_800x600_16_SP
	DisplayType	SVGA24_DISPLAY_TYPE; VD_IGS_CYBER_PRO_800x600_16_BP
if	ALLOW_1Kx768_16
	DisplayType	SVGA24_DISPLAY_TYPE; VD_IGS_CYBER_PRO_1Kx768_16_SP
	DisplayType	SVGA24_DISPLAY_TYPE; VD_IGS_CYBER_PRO_1Kx768_16_BP
endif	; ALLOW_1Kx768_16

displayWidthTable	label	word
	word	640			; VD_IGS_CYBER_PRO_640x480_16_SP
	word	640			; VD_IGS_CYBER_PRO_640x480_16_BP
	word	800			; VD_IGS_CYBER_PRO_800x600_16_SP
	word	800			; VD_IGS_CYBER_PRO_800x600_16_BP
if	ALLOW_1Kx768_16
	word	1024			; VD_IGS_CYBER_PRO_1Kx768_16_SP
	word	1024			; VD_IGS_CYBER_PRO_1Kx768_16_BP
endif	; ALLOW_1Kx768_16

displayHeightTable	label	word
	word	480			; VD_IGS_CYBER_PRO_640x480_16_SP
	word	480			; VD_IGS_CYBER_PRO_640x480_16_BP
	word	600			; VD_IGS_CYBER_PRO_800x600_16_SP
	word	600			; VD_IGS_CYBER_PRO_800x600_16_BP
if	ALLOW_1Kx768_16
	word	768			; VD_IGS_CYBER_PRO_1Kx768_16_SP
	word	768			; VD_IGS_CYBER_PRO_1Kx768_16_BP
endif	; ALLOW_1Kx768_16

displayResTable		label	word
	word	72			; VD_IGS_CYBER_PRO_640x480_16_SP
	word	72			; VD_IGS_CYBER_PRO_640x480_16_BP
	word	80			; VD_IGS_CYBER_PRO_800x600_16_SP
	word	80			; VD_IGS_CYBER_PRO_800x600_16_BP
if	ALLOW_1Kx768_16
	word	102			; VD_IGS_CYBER_PRO_1Kx768_16_SP
	word	102			; VD_IGS_CYBER_PRO_1Kx768_16_BP
endif	; ALLOW_1Kx768_16

else

displayTypeTable	label	DisplayType
	DisplayType	VGA24_DISPLAY_TYPE	; VD_IGS_CYBER_PRO_640x480_16
	DisplayType	SVGA24_DISPLAY_TYPE	; VD_IGS_CYBER_PRO_800x600_16
if	ALLOW_1Kx768_16
	DisplayType	SVGA24_DISPLAY_TYPE	; VD_IGS_CYBER_PRO_1Kx768_16
endif	; ALLOW_1Kx768_16

displayWidthTable	label	word
	word	640				; VD_IGS_CYBER_PRO_640x480_16
	word	800				; VD_IGS_CYBER_PRO_800x600_16
if	ALLOW_1Kx768_16
	word	1024				; VD_IGS_CYBER_PRO_1Kx768_16
endif	; ALLOW_1Kx768_16

displayHeightTable	label	word
	word	480				; VD_IGS_CYBER_PRO_640x480_16
	word	600				; VD_IGS_CYBER_PRO_800x600_16
if	ALLOW_1Kx768_16
	word	768				; VD_IGS_CYBER_PRO_1Kx768_16
endif	; ALLOW_1Kx768_16

displayResTable		label	word
	word	72				; VD_IGS_CYBER_PRO_640x480_16
	word	80				; VD_IGS_CYBER_PRO_800x600_16
if	ALLOW_1Kx768_16
	word	102				; VD_IGS_CYBER_PRO_1Kx768_16
endif	; ALLOW_1Kx768_16

endif	; ALLOW_BIG_MOUSE_POINTER

VidEnds		Misc
