COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CGA Video Driver
FILE:		cgaAdmin.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------
	VidScreenOn		turn on video signal
	VidScreenOff		turn off video signal
	VidTestCGA		test for existance of CGA card
	VidTestCGACompat	assume existance of CGA card
	VidSetCGA		set CGA card to 640x200 b/w mode

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/88		Initial revision
	jeremy	5/91		Added CGA compatible card support

DESCRIPTION:
	This file contains various state testing/setting/saving routines
		

	$Id: cgaAdmin.asm,v 1.1 97/04/18 11:42:30 newdeal Exp $

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

		; first see if the screen is already blank

		dec	ss:videoEnabled		; is it enabled
		js	tooFar			;  oops, called it to often
		jne	done			; someone still wants it off

		; now do the disable thing. 

		mov	dx, CGA_MODE_CONTROL	; CGA control port	
		mov	al, CGA_DISABLE_VIDEO	; no video, no block
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

		mov	dx, CGA_MODE_CONTROL	; CGA control port	
		mov	al, CGA_ENABLE_VIDEO	; enable it
		out	dx, al			;
done:
		.leave
		ret
VidScreenOn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestCGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for the existance of a device

CALLED BY:	GLOBAL
		DriverStrategy

PASS:		nothing

RETURN:		ax	- DevicePresent enum

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

VidTestCGA	proc	near
		uses	cx, dx
		.enter
		mov	dx, 3d4h	; address of 6845 index register
                mov     al,0fh          ;
		out     dx,al           ; select 6845 register f (crsr low)
		inc     dx              ;
		in      al,dx           ; al <- current crsr low
		mov     ah,al           ; save it.
		mov     al,66h          ; trash value
		out     dx,al           ; try to write it
		mov     cx,100h         ; loop value.  this should be long enuf
find6845loop:                           ;  even on a fast machine
		loop    find6845loop    ; Spin wheels waiting for bit to change
		in      al,dx           ;
		xchg    ah,al           ; ah <- new value, al <- old value.
		out     dx,al           ; restore original value.
		cmp     ah,66h          ; Check for register change.
		mov	ax, DP_NOT_PRESENT ; assume it's not there
		jne     exit
		mov	ax, DP_PRESENT	; set to non-zero to indicate success
exit:                              	;
		.leave
		ret                     ;
VidTestCGA	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestCGACompat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Assume the existance of a CGA device.

CALLED BY:	GLOBAL
		DriverStrategy

PASS:		nothing

RETURN:		ax	- DevicePresent enum DP_PRESENT

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jeremy	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidTestCGACompat	proc	near
		mov	ax, DP_PRESENT	; set to non-zero to indicate success
		ret                     ;
VidTestCGACompat	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetCGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the driver for this device

CALLED BY:	INTERNAL
		VidSetDevice

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		initialize the device

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSetCGA	proc	near
		uses	ax, ds, dx
		.enter

		mov	ax, dgroup
		mov	ds, ax

		; set video to normal (not inverse)

		mov	al, NORMAL_VIDEO_MODE
		mov	ds:[inverseDriver], al

		; check with the Kernel to see if the Loader already switched
		; to this video mode, to display the splash screen

		test	ds:[driverState], mask VS_IGNORE_SPLASH_MODE
		jnz	setIt
		
		mov	ax, SGIT_CURRENT_SIMPLE_GRAPHICS_MODE
		call	SysGetInfo		;al = SysSimpleGraphicsMode
						;set by the loader (if any)

		cmp	al, SSGM_CGA		;CGA?
		je	done			;skip to end if so...

		; set the video mode for the CGA card

setIt:
		mov	ah, SET_VMODE		; function # to set video mode
		mov	al, GR02_6420		; set up 640x200 graphics mode
		int	VIDEO_BIOS		; use video BIOS call

done:
		.leave
		ret                     ;
VidSetCGA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetInverseCGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the driver for inverse mono video

CALLED BY:	INTERNAL
		VidSetDevice

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Call VidSetCGA, set internal inverse flag.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jeremy	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSetInverseCGA	proc	near
		uses	ax, ds
		.enter

		call	VidSetCGA

		mov	ax, dgroup
		mov	ds, ax

		; set the inverse video internal flag

		mov	al, INVERSE_VIDEO_MODE		; MUST BE 0 or 1.
		mov	ds:[inverseDriver], al

		; Zero out the last bit in the invertImage instruction,
		; changing it from a jnz to a jz.
		mov	al, 11111110b			; zero out last bit
		and	{byte} ds:[invertImage], al	; see SetColor.

		.leave
		ret                     ;
VidSetInverseCGA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetColorCGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a two-color (as opposed to b&w) CGA mode.

CALLED BY:	INTERNAL
       		VidSetDevice
PASS:		di	= VideoDevice enum
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSetColorCGA	proc	near
		uses	ax, bx, di
		.enter
		call	VidSetCGA
			CheckHack <VD_CGA_BDB eq 2>
		shr	di	; divide by 2 to get color index (VideoDevice
				;  enum goes up by two
		mov	bx, di	; bh = 0 => set foreground color
				; bl = color index
		mov	ah, SET_PALETTE
		int	VIDEO_BIOS
		.leave
		ret
VidSetColorCGA	endp


VideoMisc	ends
