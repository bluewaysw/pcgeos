
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Video driver
FILE:		egaAdmin.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------
	VidScreenOn		turn video on
	VidScreenOff		turn video off
	VidTestEGA		test for existance of EGA card
	VidTestEGACompat 	assume existance of EGA card
	VidSetEGA		init 640x350 16-color/monochome mode
	VidSetMEGAInverse 	init 640x350 inverse monochome mode

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	5/88	initial version
	jeremy	5/91	Added monochome and mono-inverse support

DESCRIPTION:
	This file contains routines to implement some of the administrative 
	parts of the driver.

	$Id: egaAdmin.asm,v 1.1 97/04/18 11:42:10 newdeal Exp $

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

EGAPalette	struct
    EGAP_entry0	byte	?	; first entry
    EGAP_entry1	byte	?
    EGAP_entry2	byte	?
    EGAP_entry3	byte	?
    EGAP_entry4	byte	?
    EGAP_entry5	byte	?
    EGAP_entry6	byte	?
    EGAP_entry7	byte	?
    EGAP_entry8	byte	?
    EGAP_entry9	byte	?
    EGAP_entrya	byte	?
    EGAP_entryb	byte	?
    EGAP_entryc	byte	?
    EGAP_entryd	byte	?
    EGAP_entrye	byte	?
    EGAP_entryf	byte	?
    EGAP_overscan byte	?
EGAPalette	ends


VidScreenOff	proc	far
egapalette	local	EGAPalette
		.enter

		; first see if the screen is already blank

		dec	ss:videoEnabled		; is it enabled
		js	tooFar			;  oops, called it to often
		jne	done			; someone still wants it off

		; now do the disable thing. Since there is no reliable way
		; to disable the output signal, we'll just stuff the 
		; palette registers with all black.  

		mov	al, 0			; clear out the palette buffer
		segmov	es, ss, di
		lea	di, egapalette		; es:di -> palette buffer
		mov	dx, di			; es:dx -> table
		mov	cx, size EGAPalette	; set up size of stores
		rep	stosb			; fill the buffer
		mov	ax, SET_PALREGS		; set all the registers
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

		; enable video signal on card.  Do this by restuffing the 
		; palette register with non-black values

		segmov	es, ss, di
		mov	dx, offset palCurEntries ; es:dx -> palette buffer
		mov	ax, SET_PALREGS		 ; set all the registers
		int	VIDEO_BIOS
done:
		.leave
		ret
VidScreenOn	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestEGA
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

VidTestEGA	proc	near
		uses	bx
		.enter

		; use the miscellaneous function to get info about the card

		mov	bl, 10h		; 10h == return ega info
		mov	ah, GET_CONFIG	; 12h == miscellaneous functions
		int	VIDEO_BIOS	; use video bios
		cmp	bl, 10h		; if unchanged, then no EGA present
		mov	ax, DP_NOT_PRESENT ; assume we didn't find it
		je	exit
		cmp	bl, 3		; 3 = 256K installed (req'd for color)
		jne	exit		; if not, don't use mode
		mov	ax, DP_PRESENT	; signal we fount it
exit:
		.leave
		ret
VidTestEGA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestEGACompat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dummy function that will assume that an EGA compatable
		card exists.

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
		jeremy	5/6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidTestEGACompat	proc	near
		mov	ax, DP_PRESENT	; signal we fount it
		ret
VidTestEGACompat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetEGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a string 

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		put pseudo code here

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version
		jeremy	5/7/91		MEGA normal mode support

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSetEGA	proc	near
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

		cmp	al, SSGM_EGA		;EGA?
		je	done			;skip to end if so...

		; initialize display driver variables
		; set the video mode for the EGA card

setIt:
		mov	ah, SET_VMODE		; function # to set video mode
		mov	al, GR0F_6435		; set up 640x350 graphics mode >
		int	VIDEO_BIOS		; use video BIOS call

done:
		.leave
		ret
VidSetEGA	endp

VideoMisc	ends
