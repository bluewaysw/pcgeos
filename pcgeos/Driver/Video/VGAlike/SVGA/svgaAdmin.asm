COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		SVGA Video Driver
FILE:		svgaAdmin.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name		Description
	----		-----------
	VidScreenOn	turn on video
	VidScreenOff	turn off video
	VidTestEverex	test for Everex Super VGA card
	VidSetEverex	set Everex Super VGA mode

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	9/90	initial version
	jeremy	5/91	changed the VGA Wonder initialization to use
			a different mode subfunction; changed the OAK
			Technologies test to do a case-insensitive search
			through memory for the "Oak" validation string.

DESCRIPTION:
	This file contains routines to implement some of the administrative 
	parts of the driver.

	$Id: svgaAdmin.asm,v 1.1 97/04/18 11:42:25 newdeal Exp $

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
		VidTestVESA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for VESA compatible board

CALLED BY:	INTERNAL
		VidTestDevice

PASS:		nothing

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

VESAInfoBlock	struct	
    VIB_sig	byte	4 dup (?)	; 'VESA' - VESA signature
    VIB_ver	word			; version number (hi byte = major #)
    VIB_oem	fptr			; far pointer to OEM string
    VIB_caps	byte	4 dup (?)	; video capabilities
    VIB_modes	fptr			; pointer to table of modes
    VIB_future	byte   240 dup (?)	; pad out to (at least) 256 bytes
VESAInfoBlock	ends

VidTestVESA	proc	near
		uses	es, di
vesaInfo	local	VESAInfoBlock
		.enter

		; use extended BIOS function 0x4f - 0 to determine if this
		; is a VESA compatible board, then check the table of 
		; supported modes to determine if the 800x600 16-color mode
		; is supported.

		segmov	es, ss, di	; es -> stack
		lea	di, vesaInfo	; es:di -> info block
		mov	ah, VESA_BIOS_EXT ; use VESA bios extensions
		mov	al, VESA_GET_SVGA_INFO ; basic info call
		int	VIDEO_BIOS	; make bios call

		; if al = VESA_BIOS_EXT, then there is a VESA compatible board
		; there...actually, we need to check for the VESA signature too

		cmp	ax, VESA_BIOS_EXT ; is this a VESA board ?
		jne	notPresent	  ; no, exit
		cmp	{byte} vesaInfo.VIB_sig, 'V' ; gimme a V
		jne	notPresent
		cmp	{byte} vesaInfo.VIB_sig[1], 'E' ; gimme a E
		jne	notPresent
		cmp	{byte} vesaInfo.VIB_sig[2], 'S' ; gimme a S
		jne	notPresent
		cmp	{byte} vesaInfo.VIB_sig[3], 'A' ; gimme a A
		jne	notPresent

		; OK, there is a VESA board out there.  Check the mode table
		; for the correct mode.  

		les	di, vesaInfo.VIB_modes	; get pointer to mode info
		mov	ax, VESA_800x600_4BIT	; mode to check for
checkLoop:
		cmp	es:[di], 0xffff		; at mode table terminator?
		je	notPresent
		scasw				; check this word
		jne	checkLoop		;  nope, on to next mode
		mov	ax, DP_PRESENT		; yep, it's there
done:	
		.leave
		ret

		; the extended BIOS functions are not supported, but assume
		; that the 0x6a interface is there.
notPresent:
		mov	ax, DP_CANT_TELL ; assume not
		jmp	done
VidTestVESA	endp

if (0)

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetVESA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set VESA 800x600 mode

CALLED BY:	INTERNAL
		VidSetDevice

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		call VESA set mode function

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSetVESA	proc	near
		uses	ax,bx
		.enter

		; just use the BIOS extension

		mov	ah, VESA_BIOS_EXT
		mov	al, VESA_SET_MODE
		mov	bx, VESA_800x600_4BIT 	; mode number, clear memory
		int	VIDEO_BIOS

		.leave
		ret
VidSetVESA	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetWithOldBIOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set VESA 800x600 mode, the old way

CALLED BY:	INTERNAL
		VidSetDevice

PASS:		di	- VideoDevice enum

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		call VESA set mode function

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSetWithOldBIOS proc	near
		uses	ax,bx,di
		.enter

		; check with the Kernel to see if the Loader already switched
		; to this video mode, to display the splash screen

		segmov	ds, dgroup, ax
		test	ds:[driverState], mask VS_IGNORE_SPLASH_MODE
		jnz	setIt

		mov	ax, SGIT_CURRENT_SIMPLE_GRAPHICS_MODE
		call	SysGetInfo		;al = SysSimpleGraphicsMode
						;set by the loader (if any)

		cmp	al, SSGM_SVGA_VESA	;SVGA?
		je	done			;skip to end if so...

setIt:
		;set the video mode for the SVGA card
		;just look up the mode bnumber and set it normally

		shr	di, 1			; make it a byte index
		mov	ah, SET_VMODE
		mov	al, cs:OldBIOSModeNums[di]
		int	VIDEO_BIOS
done:
		; after setting the mode, init the palette.

		clr	bx
		mov	cx, 16			; init first 16 entries
		segmov	es, cs, dx
		mov	dx, offset defVGAPalette
		mov	ax, SET_DACREGS
		int	VIDEO_BIOS

		.leave
		ret
VidSetWithOldBIOS endp

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

OldBIOSModeNums	label	byte
                byte    0x6a		; VD_VESA_800	  (ext mode set)
		byte    0x02		; VD_EVEREX_VP800 (ext mode set)
		byte    0x05		; VD_HEADLAND_800 (ext mode set)
		byte    0x52		; VD_OAK_800
		byte    0x6a		; VD_AHEAD_800
		byte    0x54		; VD_ATI_800
		byte    0x6a		; VD_MAXLOGIC_800
		byte    0x6a		; VD_CHIPS_800
		byte    0x79		; VD_GENOA_800
		byte    0x5b		; VD_TVGA_800
		byte    0x29		; VD_TSENG_800
		byte    0x58		; VD_PARADISE_800
		byte    0x6a		; VD_ZYMOS_POACH51
		byte    0x29		; VD_ORCHID_PRO_800
		byte    0x29		; VD_QUADRAM_SPECTRA
		byte    0x29		; VD_SOTA
		byte    0x29		; VD_STB
		byte    0x64		; VD_CIRRUS_800


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestEverex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for the existance of a device

CALLED BY:	GLOBAL
		DriverStrategy

PASS:		nothing

RETURN:		ax	- VideoPresent enum

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		The following Everex video cards support the 800x600 16-color
		mode we are trying to test for:
			EV-236	(Ultragraphics II)
			EV-678  (Viewpoint VGA)
			EV-673  (EVGA)
			EV-657_3    (Various revs of VGA cards)
			EV-659_2600
			EV-659_2

		The code to determine these board types was taken from 
		a document that can be found on Everex's BBS at 415-683-2924
		for 300/1200/2400 baud 8-1-N

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidTestEverex	proc	near
		uses	bx,di,es,cx, dx
		.enter

		; first check for the Viewpoint and Ultragraphics, since
		; there is a BIOS routine to find them

		mov	ax, 7000h	; set up get-info function
		clr	bx		; function number
		int	VIDEO_BIOS
		cmp	al, 70h		; check for valid completion
		jne	checkSig	; all these cards support the mode

		; OK, the BIOS call is there.  Check to make sure we have
		; a monitor that can support the 800x600 mode

		cmp	cl, 6		; have a super VGA display or better?
		jae	foundIt		;  yes, everything OK

		; check the video bios for a string that starts with the 
		; chars "EV".  This is the first part of the Everex signature,
		; which is actually "EVEREX SYSTEM INC.".  If checking the
		; first two is not enough, we may have to check the whole 
		; string.  We'll worry about that later.  The signature can
		; be anywhere in the first 0x1000 bytes of the BIOS.
checkSig:
		mov	ax, 0xc000	; set up segreg to point there
		mov	es, ax		; ds -> signature
		mov	al, 'E'		; searching for an E
		clr	di		; ds:si -> signature
		mov	cx, 0x1000	; check this far (at most)
searchMore:
		repne	scasb
		jcxz	notFound	; not the right board
		cmp	{byte} es:[di], 'V'	; is 2nd char V ?
		jne	searchMore	;  no, keep looking

		; OK, we have our EV.  Assume it's an Everex and look for
		; the board number. di points at the V, and the board number
		; is the next word after the signature

		mov	ax, es:[di+EVLEN-1] ; get board number
		cmp	ax, 0x5703	; check for EV-657_3
		je	foundIt
		cmp	ax, 0x572b	; check for EV-657_3
		je	foundIt
		cmp	ax, 0x5902	; check for EV-659_2
		je	foundIt
		cmp	ax, 0x5926	; check for EV-659_2600
		jne	notFound

foundIt:
		mov	ax, DP_PRESENT
exit:
		.leave
		ret

notFound:
		mov	ax, DP_NOT_PRESENT
		jmp	exit
VidTestEverex	endp

EverexSig	char	"EVEREX SYSTEM INC."
EVLEN		equ	$-EverexSig

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetEverex
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSetEverex	proc	near
		uses	ax,bx
		.enter

		; initialize display driver variables
		; set the video mode for the View800 card

		mov	ah, SET_VMODE		; function # to set video mode
		mov	al, EVEREX_SET_MODE	; signal Everex extended mode
		mov	bl, EVEREX_800_MODE	; choose 800x600 16-color mode
		int	VIDEO_BIOS		; use video BIOS call

		.leave
		ret
VidSetEverex	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestHeadland
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for Video 7 compatible board

CALLED BY:	INTERNAL
		VidTestDevice

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		just use the BIOS
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidTestHeadland	proc	near
		uses	bx
		.enter

		; check for video 7 product

		mov	ax, HEADLAND_INQUIRE	; extended BIOS mode function
		int	VIDEO_BIOS
		cmp	bx, '7V'	; video 7 product ?
		je	checkBios
		cmp	bx, 'TH'	; will use HT (for HeadlandTech) soon
		jne	notPresent

		; now check for the V7VGA chip
checkBios:
		mov	ax, HEADLAND_GET_CONFIG	; get memory configuration
		int	VIDEO_BIOS
		cmp	bh, 70h			; check chip version
		jb	notPresent
		cmp	bh, 7fh			; between 70 and 7f
		ja	notPresent
		mov	ax, DP_PRESENT
done:
		.leave
		ret

		; not present
notPresent:
		mov	ax, DP_NOT_PRESENT
		jmp	done
VidTestHeadland	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetHeadland
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set Video 7 800x600 mode

CALLED BY:	INTERNAL
		VidSetDevice

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
		Jim	09/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSetHeadland	proc	near
		uses	ax, bx
		.enter

		; set the mode with the BIOS

		mov	ax, HEADLAND_SET_MODE	; function # to set video mode
		mov	bl, HEADLAND_800_MODE	; video mode to set
		int	VIDEO_BIOS
		.leave
		ret
VidSetHeadland	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestOak
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for OTI compatible board

CALLED BY:	INTERNAL
		VidTestDevice

PASS:		nothing

RETURN:		DevicePresent enum

DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

oakString	char	"OAK"
VidTestOak	proc	near
		uses	ds, es, si, di
CHECK_STRING_LEN		equ	3	;

		.enter
		mov	ax, 0xc000		; check for "OAK VGA" at c000
		mov	ds, ax			; ds:si <- c000:0
		clr	si

		segmov	es, cs, ax		; es:di <- ptr to check string
		lea	di, oakString

		mov	bx, 100			; range in memory to search
						; through, from c000.
stringLoop:
		mov	cx, CHECK_STRING_LEN	;
		call	CompareStringIgnoreCase	;
		jnc	stringFound

		inc	si
		dec	bx
		jnz	stringLoop

		; If we made it here, the string was NOT found.
		mov	ax, DP_NOT_PRESENT
		jmp	done
stringFound:
		mov	ax, DP_PRESENT
done:
		.leave
		ret
VidTestOak	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestAhead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for Ahead Systems VGA WIzard

CALLED BY:	INTERNAL
		VidTestDevice

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		got this out of "Advanced Programmers Guide to Super VGA
		Cards" by Sutty and Blair, page 256.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidTestAhead	proc	near
		uses	ds, es, si, di, cx
		.enter

		; first check for signature at c000:0025

		mov	di, 0xc000		; point at VGA bios
		mov	es, di
		mov	di, 0x25
		segmov	ds, cs, si
		mov	si, offset AheadString
		mov	cx, size AheadString
		repe	cmpsb
		mov	ax, DP_PRESENT
		jcxz	done
		mov	ax, DP_NOT_PRESENT
done:
		.leave
		ret
VidTestAhead	endp

AheadString	char	"AHEAD"

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestATI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for ATI VGA Wonder

CALLED BY:	INTERNAL
		VidTestDevice

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		got this out of "Advanced Programmers Guide to Super VGA
		Cards" by Sutty and Blair, page 291.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidTestATI	proc	near
		uses	ds, es, si, di, cx
		.enter

		; first check for signature at c000:0031

		mov	di, 0xc000		; point at VGA bios
		mov	es, di
		mov	di, 0x31
		segmov	ds, cs, si
		mov	si, offset ATISig
		mov	cx, size ATISig
		repe	cmpsb
		mov	ax, DP_PRESENT
		jcxz	done
		mov	ax, DP_NOT_PRESENT
done:
		.leave
		ret
VidTestATI	endp

ATISig	char	"761295520"

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestCirrus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for Cirrus 510/520 chip sets

CALLED BY:	INTERNAL
		VidTestDevice

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		got this out of "Advanced Programmers Guide to Super VGA
		Cards" by Sutty and Blair, page 313.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidTestCirrus	proc	near
		uses	es, dx
		.enter

		; do a quick check first to see if the BIOS is there...

		mov	ax, 0xc000		; point at VGA bios
		mov	es, ax
		mov	ax, DP_PRESENT
		cmp	{word} es:[6], 'LC'	; check for Cirrus...
		je	done			;  yes, all done

		; the easy way didn't work.  try the hard way.

		clr	ax			; point to BIOS data area
		mov	es, ax
		mov	dx, es:[463h]		; fetch CRTC address
		push	dx			; ..and save it
		mov	al, 0x0c		; index to start addr register
		out	dx, al			; set up index
		inc	dx
		in	al, dx			; get current reg value
		mov	ah, al			;  ..and save it
		mov	al, 0x0c		; save pair to restore with
		push	ax
		clr	al
		out	dx, al			; new value for reg
		dec	dx

		; now fetch the unlock password

		mov	al, 1fh			; index of ID reg
		out	dx, al
		inc	dx
		in	al, dx			; read password
		mov	ah, al			; save password
		
		; enable extended registers

		mov	dx, GR_SEQUENCER	; set up sequencer reg
		mov	al, 0x06		; index to extension control
		out	dx, al
		inc	dx
		mov	al, ah			; set up password
		out	dx, al
		in	al, dx			; read back extension reg
		cmp	al, 1			; read back as '1' ?
		jne	notPresent

		; disable extended registers

		mov	al, ah			; unlock password
		ror	al, 1			; compute lock password
		ror	al, 1
		ror	al, 1
		ror	al, 1
		out	dx, al			; lock the registers
		in	al, dx			; read extended control
		tst	al			; is it zero ?
		jne	notPresent
		pop	ax			; restore restore values
		pop	dx
		out	dx, ax			; restore registers
		mov	ax, DP_PRESENT
done:
		.leave
		ret

		; didn't make it.
notPresent:
		pop	ax			; restore stack
		pop	dx
		out	dx, ax			; restore reg
		mov	ax, DP_NOT_PRESENT
		jmp	done
VidTestCirrus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestCHiPS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for CHiPS and Technologies 82C452 chip sets

CALLED BY:	INTERNAL
		VidTestDevice

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		got this out of "Advanced Programmers Guide to Super VGA
		Cards" by Sutty and Blair, page 343.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidTestCHiPS	proc	near
		uses	dx, es
		.enter

		; place VGA in SETUP mode

		cli			; no interrupts now...
		mov	dx, 46e8h	; addr of setup control reg
		in	al, dx		; get current value
		or	al, 10h		; turn setup bit on
		out	dx, al		; place chip in setup mode

		; enable extended register bank

		mov	dx, 103h	; address of extended enable reg
		in	al, dx		; get current value
		or	al, 80h		; turn enable bit on
		out	dx, al		; enable extended regs

		; read global ID

		mov	dx, 104h	; addr of global ID reg
		in	al, dx		; read the ID
		mov	ah, al		; save ID for later

		; place VGA in normal mode

		mov	dx, 46e8h	; address of setup control reg
		in	al, dx		; get current value
		and	al, 0efh	; clear setup bit
		out	dx, al		; enable normal mode
		sti			; re-enable interrupts

		; read version extended reg

		mov	dx, 3d6h	; address of extended reg
		clr	al
		out	dx, al		; select version reg
		inc	dx
		in	al, dx		; get version value

		; check if CHiPS 82C452

		cmp	ah, 5ah		; look for product ID (saved earlier)
		jne	notPresent	;  nope...
		mov	ah, al
		and	ah, 0f0h	; isolate chip id
		cmp	al, 10h		; check for 82C452 id
		jne	notPresent
		mov	ax, DP_PRESENT
done:
		.leave
		ret

		; not here
notPresent:
		mov	ax, DP_NOT_PRESENT
		jmp	done
VidTestCHiPS	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestGenoa
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for Genoa SuperVGA card

CALLED BY:	INTERNAL
		VidTestDevice

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		got this out of "Advanced Programmers Guide to Super VGA
		Cards" by Sutty and Blair, page 356.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidTestGenoa	proc	near
		uses	es
		.enter

		; load up the address of the ID bytes

		mov	ax, 0xc000		; VGA BIOS addr
		mov	es, ax

		; The SuperVGA book says that there is a double-word pointer
		; at this location.  The BIOS that is in the board that I 
		; have, and the User's guide that came from Genoa, both
		; say that this is an offset into the C000 segment, not a
		; dword pointer.

;		les	di, es:[37h]			; load up fptr
		mov	di, es:[37h]			; load up nptr
		cmp	{byte} es:[di], 77h		; check all 4 bytes
		jne	notPresent
		cmp	{byte} es:[di+1], 11h
		jne	notPresent
		cmp	{byte} es:[di+2], 99h
		jne	notPresent
		cmp	{byte} es:[di+3], 66h
		jne	notPresent
		mov	ax, DP_PRESENT
done:
		.leave
		ret

		; not here
notPresent:
		mov	ax, DP_NOT_PRESENT
		jmp	done
VidTestGenoa	endp

; GenoaID		byte	77h,11h,99h,66h

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestTrident
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for Trident TVGA chip (either ver1:8800BR or ver2:8800CS)

CALLED BY:	INTERNAL
		VidTestDevice

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		got this out of "Advanced Programmers Guide to Super VGA
		Cards" by Sutty and Blair, page 413.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		As per Trident documentation, the following version numbers
		are encoded in the chips:

		chip 		version number
		----		--------------
		8800BR			1
		8800CS			2
		8900B			3
		8900C			4

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidTestTrident	proc	near
		uses	dx,es
		.enter

		; address of extended reg bank

		mov	dx, 3c4h
		mov	al, 0bh			; index to version reg
		out	dx, al
		inc	dx
		in	al, dx			; read version
		and	al, 0fh			; only need lower nibble
		jz	notPresent
		cmp	al, 4			; check for version 1-4
		ja	notPresent
		mov	ax, DP_PRESENT
done:
		.leave
		ret

		; not here
notPresent:
		mov	ax, DP_NOT_PRESENT
		jmp	done
VidTestTrident	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestTseng
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for Tseng Labs chip ET3000

CALLED BY:	INTERNAL
		VidTestDevice

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		got this out of "Advanced Programmers Guide to Super VGA
		Cards" by Sutty and Blair, page 443.
		

		NOTE: This also works for the ET4000 chip.  

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		While this will detect the chips, and while most boards that
		have the chip will support the BIOS modes, not all will.  
		Be careful when using this to determine if a video board is
		present...

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidTestTseng	proc	near
		uses	dx,es
		.enter

		mov	dx, 3cdh	; address of page select register
		in	al, dx		; read current value
		mov	ah, al		; save for later
		and	al, 0c0h	; preserve top two bits
		or	al, 55h		; test value one
		out 	dx, al
		in	al, dx		; read value just written
		cmp	al, 55h		; is it the same ?
		jne	notPresent	; nope, not the right device
		mov	al, 0aah	; test value two
		out	dx, al
		in	al, dx
		cmp	al, 0aah	; same value read back ?
		jne	notPresent
		mov	al, ah
		out	dx, al
		mov	ax, DP_PRESENT
done:
		.leave
		ret

		; not here
notPresent:
		mov	al, ah
		out	dx, al
		mov	ax, DP_NOT_PRESENT
		jmp	done
VidTestTseng	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestParadise
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for Western Digital board

CALLED BY:	INTERNAL
		VidTestDevice

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		got this out of "Advanced Programmers Guide to Super VGA
		Cards" by Sutty and Blair, page 443.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidTestParadise	proc	near
		uses	ds, si
		.enter

		; first, we should check for a Paradise BIOS

		mov	ax, 0xc000	; point at the BIOS segment
		mov	ds, ax		; ds -> BIOS
		mov	si, 7dh		; offset to signature
		cmp	{word} ds:[si], 4756h ; check first half of sig
		jne	notPresent	; do more extensive check
		cmp	{word} ds:[si+2], 3d41h ; check first half of sig
		jne	notPresent	; yes, it's a wrap

		mov	ax, DP_PRESENT
done:
		.leave
		ret

		; not here
notPresent:
		mov	ax, DP_NOT_PRESENT
		jmp	done
VidTestParadise	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestLaser
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Don't do anything to test this fucking board

CALLED BY:	INTERNAL
		VidTestDevice

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Just return with a ? code

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidTestLaser	proc	near
		mov	ax, DP_CANT_TELL 	; tell the truth
		ret
VidTestLaser	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetLaser
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out all the CRTC registers and tweak the board in
		the prescribed fashion.

CALLED BY:	INTERNAL
		VidSetDevice

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Write out the proper info, as per the undocumented Pascal
		source that we received from Laser.  Wonderful.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSetLaser	proc	near
		uses	ax, cx, dx, ds, si
		.enter
		mov	ax, 0x12		; set to mode 12h
		int	VIDEO_BIOS
		mov	dx, 0x3c2
		mov	al, 0xeb
		out	dx, al
		segmov	ds, cs, si

		; do sequencer registers

		mov	cx, sizeSeqTable/2
		mov	si, offset seqTable
		mov	dx, 0x3c4		; sequencer i/o address
seqLoop:
		lodsb
		out	dx, al
		inc	dx
		lodsb
		out	dx, al
		dec	dx
		loop	seqLoop

		; do CRTC registers

		mov	cx, sizeCRTCTable/2
		mov	si, offset crtcTable
		mov	dx, 0x3d4		; sequencer i/o address
crtcLoop:
		lodsb
		out	dx, al
		inc	dx
		lodsb
		out	dx, al
		dec	dx
		loop	crtcLoop

		; do some monkeying with the attribute chip

		mov	dx, 0x3ba		; I don't know why we do these
		in	al, dx			; IN instructions...
		mov	dx, 0x3da		; I don't know why we do these
		in	al, dx			; IN instructions...
		mov	dx, 0x3c0		; set up attribute cntrlr addr
		mov	al, 0x11		; address...
		out	dx, al
		mov	al, 0			; data...
		out	dx, al
		mov	al, 0x20
		out	dx, al

		mov	dx, 0x3ba		; I don't know why we do these
		in	al, dx			; IN instructions...
		mov	dx, 0x3da		; I don't know why we do these
		in	al, dx			; IN instructions...
		mov	dx, 0x3c0		; set up attribute cntrlr addr
		mov	al, 0x13		; address...
		out	dx, al
		mov	al, 0			; data...
		out	dx, al
		mov	al, 0x20
		out	dx, al

		.leave
		ret
VidSetLaser	endp

seqTable	label	byte
		byte	0, 0x00		; address, value
		byte	1, 0x01		; address, value
		byte	2, 0x0f		; address, value
		byte	3, 0x00		; address, value
		byte	4, 0x06		; address, value
		byte	0, 0x03		; address, value
sizeSeqTable	equ	$-seqTable

crtcTable	label	byte
		byte	0x11, 0x2c	; address, value
		byte	0x00, 0x7a	; address, value
		byte	0x01, 0x63	; address, value
		byte	0x02, 0x63	; address, value
		byte	0x03, 0x19	; address, value
		byte	0x04, 0x69	; address, value
		byte	0x05, 0x99	; address, value
		byte	0x06, 0x68	; address, value
		byte	0x07, 0xe0	; address, value
		byte	0x08, 0x00	; address, value
		byte	0x09, 0x60	; address, value
		byte	0x0a, 0x00	; address, value
		byte	0x0b, 0x00	; address, value
		byte	0x0c, 0x00	; address, value
		byte	0x0d, 0x00	; address, value
		byte	0x0e, 0x00	; address, value
		byte	0x0f, 0x00	; address, value
		byte	0x10, 0x59	; address, value
		byte	0x12, 0x57	; address, value
		byte	0x13, 0x32	; address, value
		byte	0x14, 0x00	; address, value
		byte	0x15, 0x57	; address, value
		byte	0x16, 0x60	; address, value
		byte	0x17, 0xe3	; address, value
		byte	0x18, 0xff	; address, value
sizeCRTCTable	equ	$-crtcTable


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareStringIgnoreCase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Use this when you want to compare two character strings
		and don't want to consider upper and lower case as
		different.

CALLED BY:	VidTestOak

PASS:		es:[di]		- pointer to one string
		ds:[si]		- pointer to the other
		cx		- number of characters to check, != 0.

RETURN:		carry flag	- set if strings do NOT match,
				  clear if strings DO match.

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jeremy	5/6/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CompareStringIgnoreCase	proc	near
	uses	di, si
	.enter

compareLoop:
	mov	al, ds:[si]		; get character from compare string
	call	ToUpper			; force upper case
	cmp	es:[di], al		;
	je	nextChar		; it's the same character.  Next!

	call	ToLower			; force lower case
	cmp	es:[di], al		;
	je	nextChar		; it's the same character.  Continue.

	stc				; flag: NOT the same string.
	jmp	SHORT allDone

nextChar:
	inc	di			;
	inc	si			;
	loop	compareLoop		;

	clc				; if we made it here, the strings
					; were the same.  Flag it.
allDone:
	.leave
	ret

CompareStringIgnoreCase	endp

;
; Force ASCII character in al to upper case.
;
ToUpper		proc	near

	cmp	al, 'a'			; is it in the range [a-z]?
	jb	allDone			;
	cmp	al, 'z'			;
	ja	allDone			;

	; The character is a lower-case letter.  Convert it.
	sub	al, 'a'			;
	add	al, 'A'			;
allDone:
	ret

ToUpper		endp

;
; Force ASCII character in al to lower case.
;
ToLower		proc	near

	cmp	al, 'A'			; is it in the range [a-z]?
	jb	allDone			;
	cmp	al, 'Z'			;
	ja	allDone			;

	; The character is a lower-case letter.  Convert it.
	sub	al, 'A'			;
	add	al, 'a'			;
allDone:
	ret
ToLower		endp

VideoMisc	ends
