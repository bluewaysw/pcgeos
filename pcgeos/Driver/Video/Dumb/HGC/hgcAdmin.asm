COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers
FILE:		hgcAdmin.asm

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	jeremy	5/91		Added support for HGC compatible cards.

DESCRIPTION:
	This file contains routines to initialize and exit the driver.

	$Id: hgcAdmin.asm,v 1.1 97/04/18 11:42:35 newdeal Exp $

-------------------------------------------------------------------------------@

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

		mov	dx, HGC_MODE		; HGC control port	
		mov	al, HGC_DISABLE_VIDEO	; no video, no block
		out	dx, al			; kill it	
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

		mov	dx, HGC_MODE		; HGC control port	
		mov	al, HGC_ENABLE_VIDEO	; enable it
		out	dx, al			;
done:
		.leave
		ret
VidScreenOn	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestHGC
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

VidTestHGC	proc	near
		uses	cx, dx
		.enter
		mov	dx,3b4h		; dx <- crtc address of hercules

                mov     al,0fh          ;
		out     dx,al           ; select 6845 register f (crsr low)
		inc     dx              ;
		in      al,dx           ; al <- current crsr low
		mov     ah,al           ; save it.
		mov     al,66h          ; trash value
		out     dx,al           ; try to write it
		mov     cx,100h         ; loop value
find6845loop:                           ;
		loop    find6845loop    ; Spin wheels waiting for bit to change
		in      al,dx           ;
		xchg    ah,al           ; ah <- new value, al <- old value.
		out     dx,al           ; restore original value.
		cmp     ah,66h          ; Check for register change.
		jne     notFound
		;
		; We know it is either an MDA or an HGC.
		; Check for the sync bit of the status port changing.
		; If it does change then this is an HGC (hercules) card.
		;
		mov	dx,3bah		; dx <- status port address
		in	al,dx		; al <- value of status byte
		and	al,80h		; only interested in the sync bit.
		mov	ah,al		; ah <- bit 7 (corresponds to vertical
					;    sync bit on hercules card).
		mov	cx,8000h	; loop for a long time.
SFH_loop:			; Loop, waiting for change in sync bit.
		in	al,dx		; get status byte again.
		and	al,80h		; check status bit
		cmp	ah,al		; check for difference.
		loope	SFH_loop	; loop until bit changes or cx = 0.
		je	notFound	; if bit hasn't changed then this is
		mov	ax, DP_PRESENT	; signal we're OK
exit:
		.leave
		ret

		; didn't find it
notFound:
		mov	ax, DP_NOT_PRESENT ; signal no-findee
		jmp	exit
VidTestHGC	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestHGCCompat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Assume the existance of a device

CALLED BY:	GLOBAL
		DriverStrategy

PASS:		nothing

RETURN:		ax	- VideoPresent enum DP_PRESENT

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jeremy	5/7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidTestHGCCompat	proc	near
		mov	ax, DP_PRESENT	; signal we're OK
		ret
VidTestHGCCompat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetHGC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the graphics mode for the Hercules card

CALLED BY:	INTERNAL
		VidSetDevice

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		program the CRT controller to do the right thing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Tony	10/88		Initial version
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSetHGC	proc	near
		uses	ax, es, di, si, cx, dx, ds
		.enter

		mov	ax, dgroup
		mov	ds, ax

		; Set video to normal

		mov	al, NORMAL_VIDEO_MODE
		mov	ds:[inverseDriver], al

		; check with the Kernel to see if the Loader already switched
		; to this video mode, to display the splash screen

		test	ds:[driverState], mask VS_IGNORE_SPLASH_MODE
		jnz	setForHGC

		mov	ax, SGIT_CURRENT_SIMPLE_GRAPHICS_MODE
		call	SysGetInfo		;al = SysSimpleGraphicsMode
						;set by the loader (if any)

		cmp	al, SSGM_HGC		;HGC?
		je	done			;skip to end if so...

setForHGC::
		; Update video BIOS with reasonable values

		mov	ax,BIOS_DATA_SEGMENT	; BIOS data area
		mov	es,ax
		mov	di,BIOS_DATA_OFFSET

		mov	si,offset dgroup:BIOSData
		mov	cx,BIOS_DATA_LENGTH
		rep movsb

		; Set configuration switch

		mov	dx,HGC_CONFIG		;Allow graphics mode
		mov	al,CONFIG_ALLOW_GR or CONFIG_ENABLE_64K
		out	dx,al

		; Blank screen to avoid interference during initialization

		mov	dx,HGC_MODE
		clr	ax
		out	dx,al

		; Program the CRT Controller

		mov	dx,CRTC_ADDRESS
		mov	si,offset dgroup:CRTCParams
		mov	cx,CRTC_PARAMS_LENGTH
VI_configLoop:
		mov	al,ah			;output address
		out	dx,al
		inc	dx
		lodsb
		out	dx,al
		dec	dx
		inc	ah
		loop	VI_configLoop

		; Set graphics mode

		mov	dx,HGC_MODE		;Enable graphics mode
		mov	al,MODE_720_348 or MODE_VIDEO_ON
		out	dx,al

		; Clear screen

		SetBuffer	es, ax
		mov	cx,8000h / 2
		clr	ax
		clr	di
		rep stosw

done:
		.leave
		ret
VidSetHGC	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetInverseHGC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the graphics mode for inverse video

CALLED BY:	INTERNAL
		VidSetDevice

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Call VidSetHGC, set internal inverse flag.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jeremy	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSetInverseHGC	proc	near
		uses	ax, ds
		.enter

		call	VidSetHGC

		; set the inverse video internal flag

		mov	ax, dgroup
		mov	ds, ax
		mov	al, INVERSE_VIDEO_MODE		; MUST BE 0 or 1.
		mov	ds:[inverseDriver], al

		; Zero out the last bit in the invertImage instruction,
		; changing it from a jnz to a jz.
		mov	al, 11111110b			; zero out last bit >
		and	{byte} ds:[invertImage], al	; see SetColor. >

		.leave
		ret
VidSetInverseHGC	endp

VideoMisc	ends
