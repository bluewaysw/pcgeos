COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		MCGA driver
FILE:		mcgaAdmin.asm

ROUTINES:
	Name			Description
	----			-----------
	VidScreenOn		turn on video
	VidScreenOff		turn off video
	VidTestMCGA		check for device
	VidSetMCGA		set device
	VidSetInverseMCGA	set inverse device

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	7/90		Initial version
	jeremy	5/91		inverse version

DESCRIPTION:
	This file contains routines to initialize and exit the driver.

	$Id: mcgaAdmin.asm,v 1.1 97/04/18 11:42:32 newdeal Exp $

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
		VidTestMCGA
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

VidTestMCGA	proc	near
		uses	bx
		.enter

		; use the Video Display Combination bios call to determine
		; if MCGA is present

		mov	ah, 1ah			; function code
		clr	al			; al = 0 >> Get Display Comb
		int	VIDEO_BIOS		; make call to bios
		cmp	al, 1ah			; call successful ?
		mov	ax, DP_NOT_PRESENT	; assume not found (no use CLR)
		jne	exit			;  no, bios doesn't support call

		; the call was successful, now check for the type of device

		cmp	bl, 7			; 7,8 = VGA (superset of MCGA)
						; 10,11,12 = MCGA
		jb	exit			; must be MCGA or VGA
		mov	ax, DP_PRESENT		; signal found
exit:
		.leave
		ret
VidTestMCGA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetMCGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize 640x480 monochrome mode

CALLED BY:	INTERNAL
		VidSetDevice

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		call the BIOS

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSetMCGA	proc	near
		uses	ax, ds, dx
		.enter

		; Make this a normal mono driver.

		mov	ax, dgroup
		mov	ds, ax
		mov	al, NORMAL_VIDEO_MODE	; MUST BE 0 or 1.
		mov	ds:[inverseDriver], al	;

		; check with the Kernel to see if the Loader already switched
		; to this video mode, to display the splash screen

		test	ds:[driverState], mask VS_IGNORE_SPLASH_MODE
		jnz	setIt

		mov	ax, SGIT_CURRENT_SIMPLE_GRAPHICS_MODE
		call	SysGetInfo		;al = SysSimpleGraphicsMode
						;set by the loader (if any)

		cmp	al, SSGM_MCGA		;MCGA?
		je	done			;skip to end if so...

		; set the video mode for the MCGA card
	
setIt:
		mov	ah, SET_VMODE		; function # to set video mode
		mov	al, GR02_6448		; set up 640x200 graphics mode
		int	VIDEO_BIOS		; use video BIOS call

done:
		.leave
		ret
VidSetMCGA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetInverseMCGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize 640x480 inverse monochrome mode

CALLED BY:	INTERNAL
		VidSetDevice

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		call VidSetMCGA
		set inverse flags

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jeremy	5/91		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSetInverseMCGA	proc	near
		uses	ax, ds
		.enter

		call	VidSetMCGA

		mov	ax, dgroup
		mov	ds, ax
		; The value in al sets inverse or normal mode.
		mov	al, INVERSE_VIDEO_MODE		; MUST BE 0 or 1.
		mov	ds:[inverseDriver], al

		; Zero out the last bit in the invertImage instruction,
		; changing it from a jnz to a jz.
		mov	al, 11111110b			; zero out last bit
		and	{byte} ds:[invertImage], al	; see SetColor.

		.leave
		ret
VidSetInverseMCGA	endp

VideoMisc	ends
