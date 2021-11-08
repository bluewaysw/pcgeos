COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1998 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		VGA16 Video Driver
FILE:		vga16Admin.asm

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

	$Id: vga16Admin.asm,v 1.2$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidSegment	Misc

	
if NT_DRIVER
idata	segment
vddHandle	word	0	; used by NT driver
idata	ends


DllName DB      "GEOSVDD.DLL",0
InitFunc  DB    "VDDRegisterInit",0
DispFunc  DB    "VDDDispatch",0
yScreenSizeStr		char	"yScreenSize", 0
screenSizeCategoryStr	char	"ui", 0
InitVideoDLL	proc	near
		push	ds, es
		push	ax, si, di, bx, dx
	;
	; Find out how big they want the screen to be by checking the .ini file
	;
		segmov	ds, cs, cx
		mov	si, offset screenSizeCategoryStr
		mov	dx, offset yScreenSizeStr
		call	InitFileReadInteger
		jnc	afterY
		mov	ax, 480			; default to height of 480
	;		mov	ax, 200
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

		mov	bx, 113	; VDD_FUNC_SET_BPP
		mov	cx, 16			; 4 bits per pixel
		DispatchCall

		mov	dx, 800
		mov	cx, 600
		mov	bx, 108 ; VDD_CREATE_WINDOW		; create window
		DispatchCall
		;
		; Clear video memory
		;
		mov	cx, 65536 / 2
		mov	ax, 0xA000
		mov	es, ax
		clr	ax, di
		rep	stosw
		pop	ax, si, di, bx, dx
		pop	ds, es
		ret
InitVideoDLL	endp
endif			; WINNT



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
if NT_DRIVER
VidScreenOff	proc	far
		ret
VidScreenOff	endp
else	
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
endif	; NT_DRIVER


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
if NT_DRIVER
VidScreenOn	proc	far
	ret
VidScreenOn	endp
else	;  NT_DRIVER
	
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
endif	;  NT_DRIVER

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestVGA16
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for 640x480 16bit VESA mode

CALLED BY:	INTERNAL
		VidTestDevice
PASS:		nothing
RETURN:		ax	- DevicePresent enum
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidTestVGA16	proc	near
		mov	ax, VD_VESA_640x480_16
		call	VidTestVESA
		ret
VidTestVGA16	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestSVGA16
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for 800x600 16bit VESA mode

CALLED BY:	INTERNAL
		VidTestDevice
PASS:		nothing
RETURN:		ax	- DevicePresent enum
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidTestSVGA16	proc	near
		mov	ax, VD_VESA_800x600_16
		call	VidTestVESA
		ret
VidTestSVGA16	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestUVGA16
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for 1024x768 16bit VESA mode

CALLED BY:	INTERNAL
		VidTestDevice
PASS:		nothing
RETURN:		ax	- DevicePresent enum
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidTestUVGA16	proc	near
		mov	ax, VD_VESA_1Kx768_16
		call	VidTestVESA
		ret
VidTestUVGA16	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestHVGA16
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for 1280x1024 16bit VESA mode

CALLED BY:	INTERNAL
		VidTestDevice
PASS:		nothing
RETURN:		ax	- DevicePresent enum
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidTestHVGA16	proc	near
		mov	ax, VD_VESA_1280x1K_16	
		call	VidTestVESA
		ret
VidTestHVGA16	endp

VidTestVESA_640x350_16	proc	near
		mov	ax, VD_VESA_640x350_16
		call	VidTestVESA
		ret
VidTestVESA_640x350_16	endp
		
VidTestVESA_640x400_16	proc	near
		mov	ax, VD_VESA_640x400_16
		call	VidTestVESA
		ret
VidTestVESA_640x400_16	endp
		
VidTestVESA_720x400_16	proc	near
		mov	ax, VD_VESA_720x400_16
		call	VidTestVESA
		ret
VidTestVESA_720x400_16	endp
		
VidTestVESA_800x480_16	proc	near
		mov	ax, VD_VESA_800x480_16
		call	VidTestVESA
		ret
VidTestVESA_800x480_16	endp
		
VidTestVESA_832x624_16	proc	near
		mov	ax, VD_VESA_832x624_16
		call	VidTestVESA
		ret
VidTestVESA_832x624_16	endp
		
VidTestVESA_848x480_16	proc	near
		mov	ax, VD_VESA_848x480_16
		call	VidTestVESA
		ret
VidTestVESA_848x480_16	endp

VidTestVESA_1024_600_16	proc	near
		mov	ax, VD_VESA_1024_600_16
		call	VidTestVESA
		ret
VidTestVESA_1024_600_16	endp
		
VidTestVESA_1152x864_16	proc	near
		mov	ax, VD_VESA_1152x864_16
		call	VidTestVESA
		ret
VidTestVESA_1152x864_16	endp
		
VidTestVESA_1280x600_16	proc	near
		mov	ax, VD_VESA_1280x600_16
		call	VidTestVESA
		ret
VidTestVESA_1280x600_16	endp
		
VidTestVESA_1280x720_16	proc	near
		mov	ax, VD_VESA_1280x720_16
		call	VidTestVESA
		ret
VidTestVESA_1280x720_16	endp
		
VidTestVESA_1280x768_16	proc	near
		mov	ax, VD_VESA_1280x768_16
		call	VidTestVESA
		ret
VidTestVESA_1280x768_16	endp
		
VidTestVESA_1280x800_16	proc	near
		mov	ax, VD_VESA_1280x800_16
		call	VidTestVESA
		ret
VidTestVESA_1280x800_16	endp
		
VidTestVESA_1280x854_16	proc	near
		mov	ax, VD_VESA_1280x854_16
		call	VidTestVESA
		ret
VidTestVESA_1280x854_16	endp
		
VidTestVESA_1280x960_16	proc	near
		mov	ax, VD_VESA_1280x960_16
		call	VidTestVESA
		ret
VidTestVESA_1280x960_16	endp
		
VidTestVESA_1360_768_16	proc	near
		mov	ax, VD_VESA_1360_768_16
		call	VidTestVESA
		ret
VidTestVESA_1360_768_16	endp
		
VidTestVESA_1366_768_16	proc	near
		mov	ax, VD_VESA_1366_768_16
		call	VidTestVESA
		ret
VidTestVESA_1366_768_16	endp
		
VidTestVESA_1400_1050_16	proc	near
		mov	ax, VD_VESA_1400_1050_16
		call	VidTestVESA
		ret
VidTestVESA_1400_1050_16	endp
		
VidTestVESA_1440_900_16	proc	near
		mov	ax, VD_VESA_1440_900_16
		call	VidTestVESA
		ret
VidTestVESA_1440_900_16	endp
		
VidTestVESA_1600_900_16	proc	near
		mov	ax, VD_VESA_1600_900_16
		call	VidTestVESA
		ret
VidTestVESA_1600_900_16	endp
		
VidTestVESA_1600_1024_16	proc	near
		mov	ax, VD_VESA_1600_1024_16
		call	VidTestVESA
		ret
VidTestVESA_1600_1024_16	endp
		
VidTestVESA_1600_1200_16	proc	near
		mov	ax, VD_VESA_1600_1200_16
		call	VidTestVESA
		ret
VidTestVESA_1600_1200_16	endp
		
VidTestVESA_1680_1050_16	proc	near
		mov	ax, VD_VESA_1680_1050_16
		call	VidTestVESA
		ret
VidTestVESA_1680_1050_16	endp
		
VidTestVESA_1920_1024_16	proc	near
		mov	ax, VD_VESA_1920_1024_16
		call	VidTestVESA
		ret
VidTestVESA_1920_1024_16	endp
		
VidTestVESA_1920_1080_16	proc	near
		mov	ax, VD_VESA_1920_1080_16
		call	VidTestVESA
		ret
VidTestVESA_1920_1080_16	endp
		
VidTestVESA_1920_1200_16	proc	near
		mov	ax, VD_VESA_1920_1200_16
		call	VidTestVESA
		ret
VidTestVESA_1920_1200_16	endp
		
VidTestVESA_1920_1440_16	proc	near
		mov	ax, VD_VESA_1920_1440_16
		call	VidTestVESA
		ret
VidTestVESA_1920_1440_16	endp
		
VidTestVESA_2048_1536_16	proc	near
		mov	ax, VD_VESA_2048_1536_16
		call	VidTestVESA
		ret
VidTestVESA_2048_1536_16	endp
		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestVESA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for VESA compatible board

CALLED BY:	INTERNAL
		VidTestDevice

PASS:		ax	- device index to check for

RETURN:		ax	- DevicePresent enum

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		call VESA inquiry functins

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidTestVESA	proc	near
		uses	di, bx, cx
		.enter

		push	es
if  NT_DRIVER
	; Be lazy and only return true for the
	; mode we know we support.
		mov	bx, DP_NOT_PRESENT
		cmp	ax, VM_800x600_16
		jne	done
		mov	bx, DP_PRESENT
done:
		mov	ax, bx

else ; NT_DRIVER
		; save away the mode number

		mov	ss:[vesaMode], ax	; save it

		; allocate fixed block to get vesa info

		;CheckHack <(size VESAInfoBlock) eq (size VESAModeInfo)>

		mov	ax, size VESAInfoBlock + size VESAModeInfo
		mov	cx, ALLOC_FIXED
		call	MemAlloc

		; use extended BIOS function 0x4f - 0 to determine if this
		; is a VESA compatible board, then check the table of 
		; supported modes to determine if the 640x480x256-color mode
		; is supported.

		mov	es, ax
		clr	di			; es:di -> VESAInfoBlock
		mov	ah, VESA_BIOS_EXT 	; use VESA bios extensions
		mov	al, VESA_GET_SVGA_INFO 	; basic info call
		int	VIDEO_BIOS		; make bios call

		; if al = VESA_BIOS_EXT, then there is a VESA compatible board
		; there...actually, we need to check for the VESA signature too

		cmp	ax, VESA_BIOS_EXT ; is this a VESA board ?
		jne	notPresent		; no, exit
		cmp	{word} es:[di].VIB_sig, 'VE' ; gimme a VE
		jne	notPresent
		cmp	{word} es:[di].VIB_sig[2], 'SA' ; gimme a SA
		jne	notPresent

		; OK, there is a VESA board out there.  Check the mode table
		; for the correct mode.  

		les	di, es:[di].VIB_modes	; get pointer to mode info
checkLoop:
		cmp	es:[di], 0xffff		; at mode table terminator?
		je	notPresent
		mov	ax, es:[di]
		push	ax
		push	bx
		push	es
		push	di
		
		; OK, the mode is supported in the BIOS.  Now check to see if
		; it is supported by the current card/monitor setup.  To do
		; this, we need to call the GetModeInfo function.

		call	MemDerefES
		mov	di, size VESAInfoBlock	; es:di -> VESAModeInfo
		mov	cx, ax			; cx = mode number
		mov	ah, VESA_BIOS_EXT	; BIOS mode number
		mov	al, VESA_GET_MODE_INFO	; get info about mode
		int	VIDEO_BIOS		; get mode info

		; now see if the current hardware is cool.
		
		test	es:[di].VMI_modeAttr, mask VMA_SUPPORTED
		jz	checkNext	

		; check for right color
		mov	al, es:[di].VMI_bitsPerPixel
		cmp	al, 16
		jne	checkNext
		
		; check for resolution
		mov	bx, ss:[vesaMode]
		mov	ax, cs:[vesaWidth][bx]
		cmp	ax, es:[di].VMI_Xres
		jne	checkNext
		
		mov	ax, cs:[vesaHeight][bx]
		cmp	ax, es:[di].VMI_Yres
		jne	checkNext

		; Hit, found matching mode
		pop	di
		pop	es
		pop	bx
		pop	ax
		mov	ss:[vesaMode], ax	; remember the VESA mode

		; passed the acid test.  Use it.
		mov	ax, DP_PRESENT		; yep, it's there

		jmp	done
checkNext::
		pop	di
		pop	es
		pop	bx
		pop	ax
		
		inc	di
		inc	di
		jmp	checkLoop
		
done:
		; free allocated memory block

		pop	es
		call	MemFree
endif  ; not NT_DRIVER
		.leave
		ret

notPresent::
		mov	ax, DP_NOT_PRESENT	; 
		jmp	done
VidTestVESA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetVESA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set VESA 64K-color modes

CALLED BY:	INTERNAL
		VidSetDevice

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		call VESA set mode function

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		assumes that VidTestVESA has been called and passed.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if ALLOW_BIG_MOUSE_POINTER
screenCategory	char	"screen0",0
bigPointerKey	char	"bigMousePointer",0
tvModeKey	char	"tvMode",0
endif ; ALLOW_BIG_MOUSE_POINTER
	
VidSetVESA	proc	near
		uses	ax,bx,cx,dx,ds,si,es
		.enter

if ALLOW_BIG_MOUSE_POINTER
		; default cursor size is big for 640x480, small for other modes
		; can override using screen0::bigMousePointer = true/false.
	
		mov	cx, cs
		mov	dx, offset bigPointerKey
		mov	ds, cx
		mov	si, offset screenCategory
		call	InitFileReadBoolean
		jc	defaultCursor
		tst	al
		jz	afterCursor
		mov	ss:[cursorSize], CUR_SIZE * 2
		jmp	afterCursor
defaultCursor:
		cmp	ss:[vesaMode], VM_640x480_16
		jne	afterCursor
		mov	ss:[cursorSize], CUR_SIZE * 2
afterCursor:
endif ; ALLOW_BIG_MOUSE_POINTER

		; just use the BIOS extension

if not NT_DRIVER
		mov	ah, VESA_BIOS_EXT
		mov	al, VESA_SET_MODE
		mov	bx, ss:[vesaMode] 	; mode number, clear memory
		int	VIDEO_BIOS

		segmov	es, ss, di		; es -> dgroup
		lea	di, ss:[vesaInfo]	; es:di -> info block
		mov	ah, VESA_BIOS_EXT	; use VESA bios extensions
		mov	al, VESA_GET_SVGA_INFO	; basic info call
		int	VIDEO_BIOS		; make bios call

		lea	di, ss:[modeInfo]	; es:di -> info block
		mov	ah, VESA_BIOS_EXT	; use VESA bios extensions
		mov	al, VESA_GET_MODE_INFO	; get info about mode
		mov	cx, bx			; cx = mode number
		int	VIDEO_BIOS		; make bios call

else
	;;  I should just create driver calls for the above ints, but
	;;  I can't do that at the moment so I'll just stuff values.
	;;  -- ron
	;; NT_DRIVER
		call	InitVideoDLL
		cmp	ss:[vesaMode], VM_640x480_16
		jne	800$

		mov	ss:[modeInfo].VMI_modeAttr, VESAModeAttr <0,1,1,0,0,1>
		mov	ss:[modeInfo].VMI_winAAttr, VESAWinAttr <0,1,1,1>
		mov	ss:[modeInfo].VMI_winBAttr, VESAWinAttr <0,0,0,0>
		mov	ss:[modeInfo].VMI_winGran, 64
		mov	ss:[modeInfo].VMI_winSize, 64
		mov	ss:[modeInfo].VMI_winASeg, 0xa000
		mov	ss:[modeInfo].VMI_winBSeg, 0
		clrdw	ss:[modeInfo].VMI_winFunc
		mov	ss:[modeInfo].VMI_scanSize, 640 * 2

		mov	ss:[modeInfo].VMI_Xres, 640
		mov	ss:[modeInfo].VMI_Yres, 480
		mov	ss:[modeInfo].VMI_Xcharsize, 8	;  ?????? FIXME
		mov	ss:[modeInfo].VMI_Ycharsize, 8	;  ?????? FIXME
		mov	ss:[modeInfo].VMI_nplanes, 1
		mov	ss:[modeInfo].VMI_bitsPerPixel, 16
		mov	ss:[modeInfo].VMI_nbanks, 16;
		mov	ss:[modeInfo].VMI_memModel, VMM_PACKED
		mov	ss:[modeInfo].VMI_backSize, 64	;  in K
	
		mov	bx, VM_640x480_16
		jmp	setDriverTable
800$:
		mov	ss:[modeInfo].VMI_modeAttr, VESAModeAttr <0,1,1,0,0,1>
		mov	ss:[modeInfo].VMI_winAAttr, VESAWinAttr <0,1,1,1>
		mov	ss:[modeInfo].VMI_winBAttr, VESAWinAttr <0,0,0,0>
		mov	ss:[modeInfo].VMI_winGran, 64
		mov	ss:[modeInfo].VMI_winSize, 64
		mov	ss:[modeInfo].VMI_winASeg, 0xa000
		mov	ss:[modeInfo].VMI_winBSeg, 0
		clrdw	ss:[modeInfo].VMI_winFunc
		mov	ss:[modeInfo].VMI_scanSize, 800 * 2

		mov	ss:[modeInfo].VMI_Xres, 800
		mov	ss:[modeInfo].VMI_Yres, 600
		mov	ss:[modeInfo].VMI_Xcharsize, 8	;  ?????? FIXME
		mov	ss:[modeInfo].VMI_Ycharsize, 8	;  ?????? FIXME
		mov	ss:[modeInfo].VMI_nplanes, 1
		mov	ss:[modeInfo].VMI_bitsPerPixel, 16
		mov	ss:[modeInfo].VMI_nbanks, 16;
		mov	ss:[modeInfo].VMI_memModel, VMM_PACKED
		mov	ss:[modeInfo].VMI_backSize, 64	;  in K
	
		mov	bx, VM_800x600_16

setDriverTable:
endif
		; since we may be using this driver to support a number of
		; other resolutions at 8bits/pixel, copy the information 
		; that we gleaned from the mode info call and stuff the
		; appropriate fields into our own DeviceInfo structure.

		sub	bx, 0x110			; get number start at 0
		shl	bx, 1				; bx = word table index
		mov	ax, ss:[modeInfo].VMI_Yres
		mov	ss:[DriverTable].VDI_pageH, ax
		mov	ax, ss:[modeInfo].VMI_Xres
		mov	ss:[DriverTable].VDI_pageW, ax
		
		mov	cl, VGA24_DISPLAY_TYPE
		mov	bx, 72
		cmp	ax, 640
		jbe	applyRes
		mov	cl, SVGA24_DISPLAY_TYPE
		mov	bx, 80
		cmp	ax, 800
		jbe	applyRes
		mov	bx, 102
		cmp	ax, 1024
		jbe	applyRes
		mov	bx, 136
		
applyRes:
		mov	ss:[DriverTable].VDI_vRes, bx
		mov	ss:[DriverTable].VDI_hRes, bx
		mov	ss:[DriverTable].VDI_displayType, cl
		
		mov	ax, ss:[modeInfo].VMI_scanSize	; bytes per scan line
		mov	ss:[DriverTable].VDI_bpScan, ax

if NT_DRIVER
		mov	cx, cs
		mov	dx, offset tvModeKey
		mov	ds, cx
		mov	si, offset screenCategory
		call	InitFileReadBoolean
		jc	notTV
		tst	al
		jz	notTV
		mov	ss:[DriverTable].VDI_displayType, TV24_DISPLAY_TYPE
notTV:
endif

		; initialize some things about the memory windows.
		; first determine the window that we write to

		mov	al, ss:[modeInfo].VMI_winAAttr
		mov	ah, ss:[modeInfo].VMI_winBAttr
		test	ah, mask VWA_SUPPORTED or mask VWA_WRITEABLE
		jz	winAWrite
		jnp	winAWrite			; if two not set...
		mov	bl, VW_WINDOW_B			; bl = write window
		mov	cx, ss:[modeInfo].VMI_winBSeg	; cx = write win addr
tryWinARead:
		test	al, mask VWA_SUPPORTED or mask VWA_READABLE
		jz	winBRead
		jnp	winBRead
		mov	bh, VW_WINDOW_A
		mov	dx, ss:[modeInfo].VMI_winASeg
storeRWWin:
		mov	{word} ss:[writeWindow], bx	; save results
		mov	ss:[writeSegment], cx
		mov	ss:[readSegment], dx
		
		; calculate the last offset in the window

		mov	bx, ss:[modeInfo].VMI_winSize
		mov	ax, bx
		xchg	al, ah				; *256
		shl	ax, 1				; *512
		shl	ax, 1				; *1024
		dec	ax				; last offset
		mov	ss:[curWinEnd], ax		; last offset in 64K

		; calculate the window bump when going to the next window.
		; It's the size divided by the granularity

		mov	ax, bx				; ax = winSize
		mov	bx, ss:[modeInfo].VMI_winGran	; bx = granularity
		div	bl				; al = #to bump
		mov	ss:[nextWinInc], ax		; set increment

		.leave
		ret

		; window B doesn't exist or is not writeable.  Use window A
		; and try window B for reading.
winAWrite:
		mov	bl, VW_WINDOW_A
		mov	cx, ss:[modeInfo].VMI_winASeg
		test	ah, mask VWA_SUPPORTED or mask VWA_READABLE
		jz	tryWinARead
		jnp	tryWinARead
winBRead:
		mov	bh, VW_WINDOW_B
		mov	dx, ss:[modeInfo].VMI_winBSeg
		jmp	storeRWWin
VidSetVESA	endp

vesaHeight	label	word
		word	480             ; VD_VESA_640x480_16
		word    600		; VD_VESA_800x600_16
ifndef PRODUCT_WIN_DEMO
		word	350		; VD_VESA_640x350_16
		word	400		; VD_VESA_640x400_16
		word	400		; VD_VESA_720x400_16
		word	480		; VD_VESA_800x480_16
		word	624		; VD_VESA_832x624_16
		word	480		; VD_VESA_848x480_16
		word	600		; VD_VESA_1024_600_16

		word	768		; VD_VESA_1Kx768_16

		word	864		; VD_VESA_1152x864_16
		word	600		; VD_VESA_1280x600_16
		word	720		; VD_VESA_1280x720_16
		word	768		; VD_VESA_1280x768_16
		word	800		; VD_VESA_1280x800_16
		word	854		; VD_VESA_1280x854_16
		word	960		; VD_VESA_1280x960_16

		word	1024		; VD_VESA_1280x1K_16

		word	768		; VD_VESA_1360_768_16
		word	768		; VD_VESA_1366_768_16
		word	1050		; VD_VESA_1400_1050_16
		word	900		; VD_VESA_1440_900_16
		word	900		; VD_VESA_1600_900_16
		word	1024		; VD_VESA_1600_1024_16
		word	1200		; VD_VESA_1600_1200_16
		word	1050		; VD_VESA_1680_1050_16
		word	1024		; VD_VESA_1920_1024_16
		word	1080		; VD_VESA_1920_1080_16
		word	1200		; VD_VESA_1920_1200_16
		word	1440		; VD_VESA_1920_1440_16
		word	1536		; VD_VESA_2048_1536_16
endif

vesaWidth	label	word
		word	640             ; VD_VESA_640x480_16
		word    800		; VD_VESA_800x600_16
ifndef PRODUCT_WIN_DEMO
		word	640		; VD_VESA_640x350_16
		word	640		; VD_VESA_640x400_16
		word	720		; VD_VESA_720x400_16
		word	800		; VD_VESA_800x480_16
		word	832		; VD_VESA_832x624_16
		word	848		; VD_VESA_848x480_16
		word	1024		; VD_VESA_1024_600_16

		word	1024		; VD_VESA_1Kx768_16

		word	1152		; VD_VESA_1152x864_16
		word	1280		; VD_VESA_1280x600_16
		word	1280		; VD_VESA_1280x720_16
		word	1280		; VD_VESA_1280x768_16
		word	1280		; VD_VESA_1280x800_16
		word	1280		; VD_VESA_1280x854_16
		word	1280		; VD_VESA_1280x960_16

		word	1280		; VD_VESA_1280x1K_16

		word	1360		; VD_VESA_1360_768_16
		word	1366		; VD_VESA_1366_768_16
		word	1400		; VD_VESA_1400_1050_16
		word	1440		; VD_VESA_1440_900_16
		word	1600		; VD_VESA_1600_900_16
		word	1600		; VD_VESA_1600_1024_16
		word	1600		; VD_VESA_1600_1200_16
		word	1680		; VD_VESA_1680_1050_16
		word	1920		; VD_VESA_1920_1024_16
		word	1920		; VD_VESA_1920_1080_16
		word	1920		; VD_VESA_1920_1200_16
		word	1920		; VD_VESA_1920_1440_16
		word	2048		; VD_VESA_2048_1536_16
endif

VidEnds		Misc
