COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Driver
FILE:		simp4bitAdmin.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------
	VidScreenOff		turn off video
	VidScreenOn		turn on video
	VidTestSimp4Bit		look for device
	VidSetSimp4Bit		set proper video mode

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	7/90		Initial Version


DESCRIPTION:
	a few bookeeping routines for the driver
		
	$Id: simp4bitAdmin.asm,v 1.1 97/04/18 11:43:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

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
		VidTestSimp4Bit
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
		There is no non-device-specific way to check for this device


REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidTestSimp4Bit	proc	near
		mov	ax, DP_CANT_TELL	; fake it for now
		ret
VidTestSimp4Bit	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetSimp4Bit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the video controller into 4 bit/pixel mode

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

if not NT_DRIVER
VidSetSimp4Bit	proc	near
		
if	_BOR1

	push	ds, si, ax, dx, bx
	
	
	;
	; Set appropriate registers as listed in the table below.
	;

	segmov	ds, cs, ax
	mov	si, offset vidSetRegisters

tableLoop:
	lodsb
	
	mov	bl, al			; DisplayControlRegisterType in bl
	lodsw
	mov_tr	dx, ax
	lodsw				; dx = reg, ax = value
	
	test	bl, mask DCRT_INDIRECT
	jnz	handleIndirectTable
	
	test	bl, mask DCRT_WORD
	jnz	doWord
	
	out	dx, al
	jmp	nextLoop
    
doWord:
	out	dx, ax
	jmp	nextLoop

handleIndirectTable:
	push	ax
	mov	ax, E3G_DCADDR
	xchg	ax, dx			; dx = E3G_DCADDR, al = register #
	out	dx, al			; write out register to DCADDR
	inc	dx
	pop	ax			; dx = E3G_DCDATA, al = value
	out	dx, al			; write out value to register, indirect
	
nextLoop:
	test	bl, mask DCRT_END_OF_TABLE
	jz	tableLoop

	pop	ds, si, ax, dx, bx

endif ; _PENELOPE or _BOR1

		ret
VidSetSimp4Bit	endp



if	_BOR1

	
vidSetRegisters	DisplayControlRegister	\
	<mask DCRT_WORD, E3G_DCPATR5,	04411h>,	; col 1 = light gray
	<mask DCRT_WORD, E3G_DCPATR11,	02842h>,
	
	<mask DCRT_WORD, E3G_DCPATR4,	05555h>,	; col 2 = dark gray
	<mask DCRT_WORD, E3G_DCPATR10,	0aaaah>,
	
	<mask DCRT_WORD, E3G_DCPATR3,	00000h>,	; col 3 = white
	<mask DCRT_WORD, E3G_DCPATR9,	00000h>,
	
	<mask DCRT_WORD, E3G_DCPATR2,	0ffffh>,	; col 4 = black
	<mask DCRT_WORD, E3G_DCPATR8,	0ffffh>,
	
	<mask DCRT_WORD, E3G_DCPATR1,	04411h>,	; col 5 = light gray
	<mask DCRT_WORD, E3G_DCPATR7,	02842h>,
	
	<mask DCRT_WORD, E3G_DCPATR0,	05555h>,	; col 6 = dark gray
	<mask DCRT_WORD or mask DCRT_END_OF_TABLE, E3G_DCPATR6,	0aaaah>
    
endif	; _PENELOPE or _BOR1

endif	; !NT_DRIVER
if NT_DRIVER
idata	segment
vddHandle	word	0	; used by NT driver
idata	ends

DllName DB      "GEOSVDD.DLL",0
InitFunc  DB    "VDDRegisterInit",0
DispFunc  DB    "VDDDispatch",0
yScreenSizeStr		char	"yScreenSize", 0
screenSizeCategoryStr	char	"ui", 0
VidSetSimp4Bit	proc	near
		push	ds, es
		push	ax, si, di, bx, dx
	;
	; Find out how big they want the screen to be by checking the .ini file
	;
		segmov	ds, cs, cx
		mov	si, offset screenSizeCategoryStr
		mov	dx, offset yScreenSizeStr
;		call	InitFileReadInteger
;		jnc	afterY
;		mov	ax, 480			; default to height of 480
		mov	ax, 200
afterY:
		push	ax			; screen height

		mov	ax, cs
		mov	ds, ax
		mov	es, ax
	
		;
		; Register the dll
		;
	        ; Load ioctlvdd.dll
	        mov     si, offset DllName                   ; ds:si = dll name
	        mov     di, offset InitFunc                  ; es:di = init routine
	        mov     bx, offset DispFunc                  ; ds:bx = dispatch routine
	
	        RegisterModule
		mov	si, dgroup
		mov	ds, si
		mov	ds:[vddHandle], ax
		pop	cx				; screen size
		mov	bx, 108 ; VDD_CREATE_WINDOW		; create window
		DispatchCall
		mov	bx, 113	; VDD_FUNC_SET_BPP
		mov	cx, 4			; 4 bits per pixel
		DispatchCall
		;
		; Create a buffer for scan lines
		;
if 0
		mov	ax, 4000
		mov	cl, mask HF_FIXED
		mov	ch, mask HAF_ZERO_INIT
		call	MemAlloc
		mov	ds:[bufferSeg],ax
endif
		;
		; Clear video memory
		;
		mov	cx, SCREEN_BYTE_WIDTH * SCREEN_HEIGHT / 2
		mov	ax, 0xA000
		mov	es, ax
		clr	ax, di
		rep	stosw
		pop	ax, si, di, bx, dx
		pop	ds, es
		ret
VidSetSimp4Bit	endp
endif			; WINNT

VideoMisc	ends
