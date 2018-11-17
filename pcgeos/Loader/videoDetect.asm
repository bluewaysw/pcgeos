COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Loader
FILE:		videoDetect.asm

ROUTINES:
	Name			Description
	----			-----------
   	LoaderDetectVideoModes	Attempt to determine the initial text video
				mode, and which (if any) of the "simple"
				graphics modes is possible on this beast.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

DESCRIPTION:


	$Id: videoDetect.asm,v 1.1 97/04/04 17:26:37 newdeal Exp $

------------------------------------------------------------------------------@

        .ioenable       ; Tell Esp to allow I/O instructions

;------------------------------------------------------------------------------
;from User/userScreen.asm
;------------------------------------------------------------------------------

VIDMISC		=	12h	; Miscellaneous functions. bl selects what
				; is changed: 10h alters color/mono, mem size,
				; feature bits and switch setting.
				; 20h means to use alternate routine to print
				; the scr, when the PrtSc key is pressed.

; Definitions for the hardware itself, rather than its BIOS

HGCADDRPORT	=	03b4h	; Index register for mono adapters (e.g. HGC)
CGAADDRPORT	=	03d4h	; Index register
EGAADDRPORT	=	03d4h	; CRTC Index register (See ScrSetCursor)

;------------------------------------------------------------------------------
;from Video/VidCom/vidcomConstant.def
;------------------------------------------------------------------------------
;VIDEO BIOS EQUATES

VIDEO_BIOS		=	10h		; video bios interrupt number

SET_VMODE		=	00h		; set video mode function #
;SET_CURSIZ		=	01h		; set cursor size
;SET_CURPOS		=	02h		; set cursor position
;GET_CURPOS		=	03h		; get cursor position
;GET_LPENPOS		=	04h		; get light pen position
;DISP_PAGE		=	05h		; set/get display page regs
;SCROLL_UP		=	06h		; scroll window up
;SCROLL_DOWN		=	07h		; scroll window down
;GET_CHRATT		=	08h		; read character and attribute
;SET_CHRATT		=	09h		; write character and attribute
;SET_CHAR		=	0ah		; write character
;SET_PALETTE		=	0bh		; set color palette
;SET_PIXEL		=	0ch		; set pixel
;GET_PIXEL		=	0dh		; get pixel
;PUT_CHAR		=	0eh		; write character as tty
GET_VMODE		=	0fh		; get video mode function #
;SET_1PALREG		=	1000h		; set color palette (pcjr)
;SET_BORDER		=	1001h		; set border color (pcjr)
SET_PALREGS		=	1002h		; set color palette (pcjr)
;GET_PALREG		=	1007h		; get palette entry (vga only)
;SET_DACREG		=	1010h		; set 1 DAC register (vga,mcga)
;SET_DACREGS		=	1012h		; set blk of DAC registers
;GET_CONFIG		=	12h		; vid subsys config (alt sel)

;VIDEO MODES (as identified by the BIOS routines)
;
;	the names of these modes are coded as follows:
;		first two letters 	= CH for character modes
;				    	  GR for graphics modes
;		next two characters 	= hex number for # colors available
;		fifth character 	= underscore
;		next two characters	= horizontal resolution, (chars for
;					  text modes, high two digits of res
;					  for graphics modes)
;		final two characters	= vertical resolution (same encoding
;					  as horizontal resolution)

CH0F_8025		=	03h		; character 80x25 (16-color)
GR04_3220		=	05h		; graphics 320x200 (4-color)
GR02_6420		=	06h		; graphics 640x200 (mono)
CH02_8025		=	07h		; character 80x25 (hi res mono)
GR04_6420		=	0ah		; graphics 640x200 (4-color)
						;  (pcjr and tandy 1000)
GR02_6435		=	0fh		; graphics 640x350 (mono)
GR0F_6435		=	10h		; graphics 640x350 (16-color)
GR02_6448		=	11h		; graphics 640x350 (mono)
GR0F_6448		=	12h		; graphics 640x350 (16-color)
GRFF_3220		=	13h		; graphics 320x200 (256-color)

;------------------------------------------------------------------------------
;from MCGA/mcgaConstant.def
;------------------------------------------------------------------------------

SCREEN_BUFFER		=	0a000h	; MCGA video buffer segment addr

MCGA_MODE_CONTROL	equ	3d8h	  ; mode control reg, for disable video
MCGA_ENABLE_VIDEO	equ	00011000b ; value to enable video
MCGA_DISABLE_VIDEO	equ	00010000b ; value to enable video

ALT_SELECT		=	12h		; major bios function number
VIDEO_SCREEN_ON_OFF	=	36h		; subfunction number
VGA_ENABLE_VIDEO 	=	0h		;  bios arg, video enabled
VGA_DISABLE_VIDEO 	=	1h		;  bios arg, video disabled

;------------------------------------------------------------------------------
;from Chung's research
;------------------------------------------------------------------------------

; Graphics Controller Address Register

GC_ADDR_REG		equ	3ceh

; Graphics Controller registers

CGRegister		etype	byte
GC_SET_RESET		enum CGRegister, 0
GC_ENABLE_SR		enum CGRegister, 1
GC_COLOR_CMP		enum CGRegister, 2
GC_FUNCTION_SELECT	enum CGRegister, 3
GC_READ_MAP_SELECT	enum CGRegister, 4
GC_MODE			enum CGRegister, 5
GC_MISC			enum CGRegister, 6
GC_COLOR_DONT_CARE	enum CGRegister, 7
GC_BIT_MASK		enum CGRegister, 8

GFS_REPLACE		equ	0

;------------------------------------------------------------------------------
;from VGAlike/SVGA/svgaConstant.def
;------------------------------------------------------------------------------

VESA_BIOS_EXT		=	0x4f		; VESA defined BIOS extensions

			; VESA extended BIOS functions
VESA_GET_SVGA_INFO	=	0		; VESA fn 0, get SVGA info

			; VESA defined mode numbers
VESA_800x600_4BIT	=	0x102		; 800x600 16-color (new #)


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderDetectVideoModes

DESCRIPTION:	Attempt to determine the initial text video mode, and which
		(if any) of the "simple" graphics modes is possible on
		this beast.

CALLED BY:	LoadGeos

PASS:		ds, es - loader segment

RETURN:		KLV_initialTextMode
			- set to the current text mode, if possible.

		KLV_defSimpleGraphicsMode
			- set to the recommended "simple" graphics mode, if any

DESTROYED:	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

------------------------------------------------------------------------------@

LoaderDetectVideoModes	proc	near

	;Ask BIOS what the current text mode is, so we can pass it onto the
	;kernel.
	; (VESA standard says that this should work with VESA boards as well...
	; VESA Super VGA Standard VS891001, page 6, 10/1/89)

	mov	ah, GET_VMODE		;get current mode
	int	VIDEO_BIOS

EC <	cmp	al, SITM_UNKNOWN					>
EC <	ERROR_E BIOS_RETURNED_A_WEIRD_TEXT_MODE_VALUE			>
					;make sure that BIOS never returns
					;the same value that we use to indicate
					;that there is no text mode (0)

	;Save the current text mode, so that the kernel can quickly restore
	;it in case of emergency, and can pass it on to the proper video
	;driver, so it can restore that mode when PC/GEOS exits.

	mov	ds:[loaderVars].KLV_initialTextMode, al


	;Now attempt to determine which of the "simple" graphics modes
	;this machine is capable of.

	;Check for SVGA:

	call	LoaderFindSVGA
	mov	cl, SSGM_SVGA_VESA
	jc	saveDefaultMode		;skip if found it (cl = type)...

	;Check for VGA or MCGA:

	call	LoaderFindVGAOrMCGA
	jc	saveDefaultMode		;skip if found it (cl = type)...

	;Check for EGA:

	call	LoaderFindEGA
	mov	cl, SSGM_EGA
	jc	saveDefaultMode		;skip if found it (cl = type)...

	;Check for Hercules:

	call	LoaderFindHerc
	mov	cl, SSGM_HGC
	jc	saveDefaultMode		;skip if found it (cl = type)...

	;Check for CGA:

	call	LoaderFindCGA
	mov	cl, SSGM_CGA
	jnc	done			;skip if could not find...

saveDefaultMode:


	;Save this default type, so that 1) LoaderDisplaySplashScreen will know
	;what type of video mode to switch to, and/or 2) the UI library will
	;know which video driver to load if there is none specified in
	;the GEOS.INI file.

	mov	ds:[loaderVars].KLV_defSimpleGraphicsMode, cl

done:
	ret
LoaderDetectVideoModes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoaderFindImageSpecificDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This function will determine if the image specific to
		this loader can be displayed.  If it can be displayed,
		it'll return the video type in cl and set the carry.

CALLED BY:	LoaderDetectVideoModes

PASS:		nothing

RETURN:		Carry set if the image-specific card is detected
		cl = card type.

DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	5/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifndef NO_SPLASH_SCREEN

LoaderFindImageSpecificDisplay	proc	near
	.enter

ifdef INCLUDE_SVGA_IMAGE
	call	LoaderFindSVGA
	mov	cl, SSGM_SVGA_VESA
	jc	done			;skip if found it (cl = type)...
endif

ifdef INCLUDE_VGA_IMAGE
	;Check for VGA or MCGA:
	call	LoaderFindVGAOrMCGA
	jc	done			;skip if found it (cl = type)...
endif
	
ifdef INCLUDE_MCGA_IMAGE
	;Check for MCGA:
	call	LoaderFindVGAOrMCGA
	mov	cl, SSGM_MCGA
	jc	done			;skip if found it (cl = type)...
endif
	
ifdef INCLUDE_EGA_IMAGE
	;Check for EGA:
	call	LoaderFindEGA
	mov	cl, SSGM_EGA
	jc	done			;skip if found it (cl = type)...
endif

ifdef INCLUDE_HGC_IMAGE
	;Check for Hercules:
	call	LoaderFindHerc
	mov	cl, SSGM_HGC
	jc	done			;skip if found it (cl = type)...
endif

ifdef INCLUDE_CGA_IMAGE
	;Check for CGA:
	call	LoaderFindCGA
	mov	cl, SSGM_CGA
	jc	done			;skip if found it (cl = type)...
endif

ifdef INCLUDE_DCGA_IMAGE
	; There is no check for doublescan-CGA.  Just say we're a CGA
	; beast and hope for the best.
	mov	cl, SSGM_CGA
endif

done::
	.leave
	ret
LoaderFindImageSpecificDisplay	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoaderFindHerc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for the existence of a hercules card.

CALLED BY:	LoaderFindCard

PASS:		nothing

RETURN:		carry set if a Hercules card is present.

DESTROYED:	ax, bx, cx, dx, si, di, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/12/89		Initial version
	eric	3/93		Borrowed from the UI

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


LoaderFindHerc	proc	near

		mov	dx, HGCADDRPORT	; dx <- crtc address of hercules
		call	LoaderFind6845	; Try to find the crtc.
		jnc	done		; skip if not there (CY=0)...

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

waitLoop:				; Loop, waiting for change in sync bit.
		in	al,dx		; get status byte again.
		and	al,80h		; check status bit
		cmp	ah,al		; check for difference.
		loope	waitLoop	; loop until bit changes or cx = 0.

		clc			; default: is not Hercules
		je	done		; if bit hasn't changed then this is
					; not a Hercules card

		; else fall thru to signal we have found a hercules card.

found::					; Hercules found
		stc			; Signal found

done:		;return carry set if is Hercules card

		ret			;
LoaderFindHerc	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoaderFindCGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for the existence of a CGA card.

CALLED BY:	LoaderFindCard

PASS:		nothing

RETURN:		carry set if a CGA card is present.

DESTROYED:	ax, bx, cx, dx, si, di, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mav	1/26/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


LoaderFindCGA	proc	near
		mov	dx, EGAADDRPORT	; dx <- crtc address of hercules
		call	LoaderFind6845	; Try to find the crtc.
	;
	; this returns the carry correctly so just return
	;
		ret
LoaderFindCGA	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoaderFind6845
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks for the existence of the crtc that is in the Hercules
		card.

CALLED BY:	LoaderFindHerc

PASS:		dx	= port to use.

RETURN:		carry set if the 6845 is found

DESTROYED:	ax, bx, cx, dx, si, di, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/12/89		Initial version
	eric	3/93		Borrowed from the UI

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


LoaderFind6845	proc	near

		mov	al,0fh		;
		out	dx,al		; select 6845 register f (crsr low)
		inc	dx		;

		in	al,dx		; al <- current crsr low

		mov	ah,al		; save it.
		mov	al,66h		; trash value
		out	dx,al		; try to write it

		mov	cx,100h		; loop value

waitLoop:				;
		loop	waitLoop	; Spin wheels waiting for bit to change
		in	al,dx		;

		xchg	ah,al		; ah <- new value, al <- old value.
		out	dx,al		; restore original value.

		cmp	ah,66h		; Check for register change.
		stc			; default: found it
		je	done

		clc			; Signal : not found.

done:
		ret			;

LoaderFind6845	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoaderFindVGAOrMCGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for the existence of an VGA card.

CALLED BY:	LoaderGetCardType

PASS:		nothing

RETURN:		carry set if VGA or MCGA card is found.
		cl = SSGM_VGA or SSGM_MCGA

DESTROYED:	ax, bx, cx, dx, si, di

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eds	11/92		Adapted from EGA version and code from
				the VGA video driver.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


LoaderFindVGAOrMCGA	proc	near

		; use the Video Display Combination BIOS call to determine
		; if VGA is present

		mov	ah, 1ah			; function code
		clr	al			; al = 0 >> Get Display Comb
		int	VIDEO_BIOS

		cmp	al, 1ah			; call successful ?
		jne	failed			; skip if not...

		;the call was successful, now check for the type of device

		cmp	bl, 7			; ignore anything below 7 or 8
		jb	failed

		mov	cx, SSGM_VGA
		cmp	bl, 9			; 7,8 = VGA (superset of MCGA)
		jb	haveMode		; skip if is VGA...
		je	failed			; skip if is type 9...

		mov	cx, SSGM_MCGA		; type 10, 11, 12: MCGA

haveMode:
		stc

done:
		ret

failed:
		clc
		jmp	short done
LoaderFindVGAOrMCGA	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoaderFindEGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for the existence of an EGA card.

CALLED BY:	LoaderGetCardType

PASS:		nothing

RETURN:		carry set if EGA card is found.

DESTROYED:	ax, bx, cx, dx, si, di, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/12/89		Initial version
	eric	3/93		Borrowed from the UI

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


LoaderFindEGA	proc	near

;which constant?
		mov	bl,10h		; 10h == return ega info

		mov	ah, VIDMISC
;VIDEO_BIOS?
		int	10h		; if bl returns unchanged then there
					; is no EGA present.
		cmp	bl,10h		;
		jne	SFE_Found	;

		; Not found if bl has not changed. (carry already clear)

		ret			;

SFE_Found:				;
		stc			; Found if bl has changed.
		ret			;
LoaderFindEGA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoaderFindSVGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for the existence of a SVGA card.

CALLED BY:	LoaderGetCardType

PASS:		nothing

RETURN:		carry set if SVGA card is found.

DESTROYED:	ax, bx, cx, dx, si, di

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	thk	4/93		Adapted from video driver code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


VESAInfoBlock	struct	
    VIB_sig	byte	4 dup (?)	; 'VESA' - VESA signature
    VIB_ver	word			; version number (hi byte = major #)
    VIB_oem	fptr			; far pointer to OEM string
    VIB_caps	byte	4 dup (?)	; video capabilities
    VIB_modes	fptr			; pointer to table of modes
    VIB_future	byte   240 dup (?)	; pad out to (at least) 256 bytes
VESAInfoBlock	ends

LoaderFindSVGA	proc	near
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
		stc				; yep, it's there
done:	
		.leave
		ret

		; the extended BIOS functions are not supported, but assume
		; that the 0x6a interface is there.
notPresent:
		clc 				; SVGA not present
		jmp	done
LoaderFindSVGA	endp






