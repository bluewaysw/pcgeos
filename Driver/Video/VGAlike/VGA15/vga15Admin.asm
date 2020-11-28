COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:         VGA16 Video Driver
FILE:           vga16Admin.asm

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
        FR      09/97   update for 16 bit devices

DESCRIPTION:
	This file contains routines to implement some of the administrative 
	parts of the driver.

        $Id: vga16Admin.asm,v 1.2 96/08/05 03:51:55 canavese Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

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
                VidTestVGA15
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Test for 640x480 15bit VESA mode

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
VidTestVGA15     proc    near
                mov     ax, VM_640x480_15        ; mode to check for
		call	VidTestVESA
		ret
VidTestVGA15     endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                VidTestSVGA15
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Test for 800x600 15bit VESA mode

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
VidTestSVGA15   proc    near
                mov     ax, VM_800x600_15       ; mode to check for
		call	VidTestVESA
		ret
VidTestSVGA15   endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                VidTestUVGA15
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Test for 1024x768 15bit VESA mode

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
VidTestUVGA15   proc    near
                mov     ax, VM_1Kx768_15 ; mode to check for
		call	VidTestVESA
		ret
VidTestUVGA15   endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                VidTestHVGA15
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Test for 1280x1024 15bit VESA mode

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
VidTestHVGA15   proc    near
                mov     ax, VM_1280x1K_15 ; mode to check for
		call	VidTestVESA
		ret
VidTestHVGA15   endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestVESA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for VESA compatible board

CALLED BY:	INTERNAL
		VidTestDevice

PASS:		ax	- VESA mode to check for

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
		
		; save away the mode number

		mov	ss:[vesaMode], ax	; save it

		; allocate fixed block to get vesa info

		CheckHack <(size VESAInfoBlock) eq (size VESAModeInfo)>

		mov	ax, size VESAInfoBlock
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
		jne	notPresent	  ; no, exit
		cmp	{word} es:[di].VIB_sig, 'VE' ; gimme a VE
		jne	notPresent
		cmp	{word} es:[di].VIB_sig[2], 'SA' ; gimme a SA
		jne	notPresent

		; OK, there is a VESA board out there.  Check the mode table
		; for the correct mode.  

		les	di, es:[di].VIB_modes	; get pointer to mode info
		mov	ax, ss:[vesaMode]	; mode to check for
checkLoop:
		cmp	es:[di], 0xffff		; at mode table terminator?
		je	notPresent
		scasw				; check this word
		jne	checkLoop		;  nope, on to next mode

		; OK, the mode is supported in the BIOS.  Now check to see if
		; it is supported by the current card/monitor setup.  To do
		; this, we need to call the GetModeInfo function.

		call	MemDerefES
		clr	di			; es:di -> VESAModeInfo
		mov	cx, ax			; cx = mode number
		mov	ah, VESA_BIOS_EXT	; BIOS mode number
		mov	al, VESA_GET_MODE_INFO	; get info about mode
		int	VIDEO_BIOS		; get mode info

		; now see if the current hardware is cool.

		test	es:[di].VMI_modeAttr, mask VMA_SUPPORTED
		jz	notPresent

		; passed the acid test.  Use it.

                mov     ax, DP_PRESENT          ; yep, it's there
done:
		; free allocated memory block

		pop	es
		call	MemFree

		.leave
		ret

notPresent:
                mov     ax, DP_NOT_PRESENT      ; 
		jmp	done
VidTestVESA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetVESA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Set VESA 64K-color modes

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

VidSetVESA	proc	near
		uses	ax,bx,cx,dx,ds,si,es
		.enter

		; just use the BIOS extension

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

		; since we may be using this driver to support a number of
		; other resolutions at 8bits/pixel, copy the information 
		; that we gleaned from the mode info call and stuff the
		; appropriate fields into our own DeviceInfo structure.

                sub     bx, 0x110                       ; get number start at 0
		mov	al, cs:[vesaDtype][bx]
		mov	ss:[DriverTable].VDI_displayType, al
		shl	bx, 1				; bx = word table index
		mov	ax, cs:[vesaHeight][bx]
		mov	ss:[DriverTable].VDI_pageH, ax
		mov	ax, cs:[vesaWidth][bx]
		mov	ss:[DriverTable].VDI_pageW, ax
		mov	ax, cs:[vesaVres][bx]
		mov	ss:[DriverTable].VDI_vRes, ax
		mov	ax, cs:[vesaHres][bx]
		mov	ss:[DriverTable].VDI_hRes, ax
		mov	ax, ss:[modeInfo].VMI_scanSize	; bytes per scan line
		mov	ss:[DriverTable].VDI_bpScan, ax

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
                mov     bx, ss:[modeInfo].VMI_winSize

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


vesaDtype	label	DisplayType
                byte    VGA24_DISPLAY_TYPE
                byte    VGA24_DISPLAY_TYPE
                byte    VGA24_DISPLAY_TYPE

                byte    SVGA24_DISPLAY_TYPE
                byte    SVGA24_DISPLAY_TYPE
                byte    SVGA24_DISPLAY_TYPE

                byte    SVGA24_DISPLAY_TYPE
                byte    SVGA24_DISPLAY_TYPE
                byte    SVGA24_DISPLAY_TYPE

                byte    SVGA24_DISPLAY_TYPE
                byte    SVGA24_DISPLAY_TYPE
                byte    SVGA24_DISPLAY_TYPE

vesaHeight	label	word
                word    480, 480, 480,
                        600, 600, 600,
                        768, 768, 768,
                        1024, 1024, 1024

vesaWidth	label	word
                word    640, 640, 640,
                        800, 800, 800,
                        1024, 1024, 1024,
                        1280, 1280, 1280

vesaVres	label	word
                word    72, 72, 72,
                        80, 80, 80,
                        102, 102, 102,
                        136, 136, 136

vesaHres	label	word
                word    72, 72, 72,
                        80, 80, 80,
                        102, 102, 102,
                        136, 136, 136

VidEnds		Misc










