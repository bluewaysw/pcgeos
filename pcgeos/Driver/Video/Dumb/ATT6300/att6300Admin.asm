COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Driver
FILE:		att6300Admin.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------
	VidScreenOff		turn off video
	VidScreenOn		turn on video
	VidTestATT6300		look for device
	VidSetATT6300		set proper video mode

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	7/90		Initial Version


DESCRIPTION:
	a few bookeeping routines for the driver
		
	$Id: att6300Admin.asm,v 1.1 97/04/18 11:42:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include		initfile.def

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
		.leave
		ret
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
		.leave
		ret
VidScreenOn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestATT6300
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for the existance of a device

CALLED BY:	GLOBAL
		VidTestDevice

PASS:		nothing

RETURN:		ax	- DevicePresent enum

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		check for the device

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		we need some info on how to test for this. maybe in the 
		TurboC graphics library

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidTestTosh3100	label	near
VidTestGridPad	label	near
VidTestATT6300	proc	near
		mov	ax, DP_CANT_TELL	; fake it for now
		ret
VidTestATT6300	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetATT6300
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the AT&T 6300 into 640x400 mode

CALLED BY:	INTERNAL
		VidSetDevice

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		set the video mode

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if NT_DRIVER
DllName   DB	"GEOSVDD.DLL",0
InitFunc  DB	"VDDRegisterInit",0
DispFunc  DB	"VDDDispatch",0
yScreenSizeStr		char	"yScreenSize", 0
screenSizeCategoryStr	char	"ui", 0
VidSetATT6300	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter
	;
	; Find out how big they want the screen to be by checking the .ini file
	;
		segmov	ds, cs, cx
		mov	si, offset screenSizeCategoryStr
		mov	dx, offset yScreenSizeStr
		call	InitFileReadInteger
		jnc	afterY
		mov	ax, 480			; default to height of 480
afterY:
		push	ax			; screen height

		mov	ax, cs
		mov	ds, ax
		mov	es, ax
	
		;
		; Register the dll
		;
		; Load ioctlvdd.dll
		mov	si, offset DllName	; ds:si = dll name
		mov	di, offset InitFunc	; es:di = init routine
		mov	bx, offset DispFunc	; ds:bx = dispatch routine
	
		RegisterModule
		mov	si, dgroup
		mov	ds, si
		mov	ds:[vddHandle], ax
		pop	cx			; screen size
		mov	bx, 108			; create window
		DispatchCall
		;
		; Clear video memory
		;
		mov	cx, SCREEN_BYTE_WIDTH * SCREEN_HEIGHT / 2
		mov	ax, 0xA000
		mov	es, ax
		clr	ax, di
		rep	movsw
		
		; create event thread to update windows display

		mov	cx, segment ATT6300ProcessClass
		mov	dx, offset ATT6300ProcessClass
		movdw	esdi, cxdx
		mov	ax, MSG_PROCESS_CREATE_EVENT_THREAD
		clr	bp			; default stack size
		call	ObjCallClassNoLock

		mov	ss:[windowUpdateThread], ax

		; update the window

		mov	bx, ax
		mov	ax, MSG_ATT6300_PROCESS_UPDATE_WINDOW
		clr	di
		call	ObjMessage

		.leave
		ret
VidSetATT6300	endp

else


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetATT6300
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the AT&T 6300 into 640x400 mode

CALLED BY:	INTERNAL
		VidSetDevice

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		set the video mode

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSetATT6300	proc	near
		push	ds
		push	ax

		mov	ax, dgroup		; ds -> dgroup
		mov	ds, ax

		; set the video mode for the ATT6300 card

		mov	al, ATT6300_MODE	; set up 640x400 graphics mode
setvmode	label	near
		mov	ah, SET_VMODE		; function # to set video mode
		int	VIDEO_BIOS		; use video BIOS call
		pop	ax
		pop	ds
		ret
VidSetATT6300	endp
VidSetGridPad	proc	near
		push	ds
		push	ax

		; we want to reverse video the image, so change a key 
		; instruction (changes a "jz" to a "jnz"

		mov	ds:[inverseDriver], INVERSE_VIDEO_MODE
		xor	ds:[invertImage], 0x01	; invert the low bit

		; set the video mode for the ATT6300 card

		mov	al, ATT6300_MODE	; set up 640x400 graphics mode
		jmp	setvmode
VidSetGridPad	endp

VidSetTosh3100	proc	near
		push	ds
		push	ax

		; set the video mode for the ATT6300 card

		mov	al, TOSH3100_MODE	; set up 640x400 graphics mode
		jmp	setvmode
VidSetTosh3100	endp

endif

VideoMisc	ends


idata		segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ATT6300ProcessUpdateWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update window and restart update timer

CALLED BY:	MSG_ATT6300_PROCESS_UPDATE_WINDOW
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		joon	10/19/98	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if NT_DRIVER
ATT6300ProcessUpdateWindow	method	ATT6300ProcessClass,
					MSG_ATT6300_PROCESS_UPDATE_WINDOW
		UPDATE_SCREEN
		
		mov	bx, ds:[windowUpdateThread]
		tst	bx
		jz	done

		mov	al, TIMER_EVENT_ONE_SHOT
		mov	cx, 1			; update every tick
		mov	dx, MSG_ATT6300_PROCESS_UPDATE_WINDOW
		call	TimerStart
done:
		ret
ATT6300ProcessUpdateWindow	endm
endif ; NT_DRIVER

idata		ends
