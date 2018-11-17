COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Loader
FILE:		videoEGA.asm

ROUTINES:
	Name			Description
	----			-----------
	LoaderDisplayEGA	Switch to EGA, and display the splash screen.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

DESCRIPTION:


	$Id: videoEGA.asm,v 1.1 97/04/04 17:26:45 newdeal Exp $

------------------------------------------------------------------------------@

EGA_START_SEGMENT	equ	0xA000
EGA_START_OFFSET	equ	0

EGA_WIDTH		equ	640
EGA_HEIGHT		equ	350
EGA_BUF_LENGTH		equ	(EGA_WIDTH * EGA_HEIGHT) / 8

EGA_CHAR_WIDTH		equ	80
EGA_CHAR_HEIGHT		equ	25

L_EGA_L_TEXT_X 	= (EGA_CHAR_WIDTH - size loaderLoadingText) / 2
L_EGA_L_TEXT_Y 	= (EGA_CHAR_HEIGHT / 2) - 3

L_EGA_C_TEXT_X 	= ((EGA_CHAR_WIDTH - size loaderCopyrightText) / 2)
L_EGA_C_TEXT_Y 	= EGA_CHAR_HEIGHT - 1


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderDisplayEGA

DESCRIPTION:	Switch to this video mode, and display the splash screen.

CALLED BY:	LoaderDisplaySplashScreen

PASS:		ds, es	= loader segment

RETURN:		carry set if error

DESTROYED:	ax, bx, cx, dx, si, di, bp

	IMPORTANT: this routine is not permitted to FatalError after
	changing the video mode, because LoaderError will not know that
	it must restore the text video mode (since KLV_curSimpleGraphicsMode
	has not been set yet).

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

------------------------------------------------------------------------------@

LoaderDisplayEGA	proc	near
	
	;set the video mode for the EGA card
	;	(from EGAlike/EGA/egaAdmin.asm::VidSetEGA)

	mov	ah, SET_VMODE		; function # to set video mode
	mov	al, GR0F_6435		; set up 640x350 graphics mode
	int	VIDEO_BIOS		; use video BIOS call

	;Disable this screen, so the user doesn't have to watch us draw
	;(Can't do this before setting the video mode.)
	;	(from EGAlike/EGA/egaAdmin.asm::VidScreenOff)

;	call	LoaderDisableEGA

ifndef INCLUDE_EGA_IMAGE
	;draw the background color

	call	LoaderGetTextBackgroundColor ;ax = background color (0-15)
	push	ax
	call	LoaderClearEGA

	;draw the border

	call	LoaderGetBorderType	;returns ax = LoaderBorderType

	call	LoaderDisplayEGABorder
	pop	ax

	;draw the text (NOT video mode specific)

	call	LoaderGetTextColor	;ah = text color, al = same (bg color)

  ifndef IMAGE_TO_BE_DISPLAYED
	;
	; Display the text from the .ini file (if any exists).
	;
	mov	cx, EGA_CHAR_WIDTH
	mov	dx, EGA_CHAR_HEIGHT
	call	LoaderDisplayTextMessage
  else
	;
	; Display the hardcoded copyright text splash screen.
	;
	mov	cx, (L_EGA_C_TEXT_Y shl 8) or L_EGA_C_TEXT_X
	mov	dx, (L_EGA_L_TEXT_Y shl 8) or L_EGA_L_TEXT_X
	call	LoaderDisplayCopyrightText
  endif

else

	; Clear the screen before the image is put up.
	
	mov	ax, LOADER_DEFAULT_GRAPHIC_BACKGROUND_COLOR
	call	LoaderClearEGA
	call	LoaderDisplayEGABorder

	; draw the bitmaps.
	call	LoaderDisplayBitmapLogo
ifndef NO_LEGAL_IMAGE
	call	LoaderDisplayBitmapLegal
endif

endif

	;enable video signal on card
	;	(from EGAlike/EGA/egaAdmin.asm::VidScreenOn)

;	call	LoaderEnableEGA

	;indicate we were successful

	clc
	ret
LoaderDisplayEGA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoaderDisableEGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable video output, for a screen saver

CALLED BY:	GLOBAL

PASS:		ds, es	= loader segment

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		Disable the video output

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		Initial version
	Eric	3/93		Stolen from video driver

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

LoaderDisableEGA	proc	far
		uses	es

egapalette	local	EGAPalette

		.enter

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

		.leave
		ret
LoaderDisableEGA	endp

	ForceRef	LoaderDisableEGA


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoaderEnableEGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable video output, for a screen saver

CALLED BY:	GLOBAL

PASS:		ds, es	= loader segment

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		Disable the video output

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		Initial version
	Eric	3/93		Stolen from video driver

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LoaderEnableEGA	proc	far
		uses	es
		.enter

		; enable video signal on card.  Do this by restuffing the 
		; palette register with non-black values

		segmov	es, ss, di
		mov	dx, offset palCurEntries ; es:dx -> palette buffer
		mov	ax, SET_PALREGS		 ; set all the registers
		int	VIDEO_BIOS

		.leave
		ret
LoaderEnableEGA	endp

	ForceRef	LoaderEnableEGA

;(These are the default values.)

		; this holds the current palette register values (used
		; by the screen saver to restore registers)

palCurEntries	byte  0,1,2,3,4,5,14h,7,38h,39h,3ah,3bh,3ch,3dh,3eh,3fh
		byte  0                         ; for overscan reg  


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderClearEGA

DESCRIPTION:	Clear this type of display to the background color.

		Set the background to gray (actually, since EGA is 2-color,
		set the background to white.)

CALLED BY:	LoaderDisplayEGA

PASS:		ds, es	= loader segment

RETURN:		ax	= color

DESTROYED:	ax, bx, cx, dx, si, di, bp

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

------------------------------------------------------------------------------@

LoaderClearEGA	proc	near
	uses	es
	.enter

	;
	; set bit mask to all bits
	;

	push	ax
	mov	ah, 0xff			;all bits
	mov	al, GC_BIT_MASK
	mov	dx, GC_ADDR_REG
	out	dx, ax

	;
	; set write mode 2
	;
	mov	al, GC_MODE
	mov	ah, 2
	out	dx, ax

	;
	; set function to replace
	;
	mov	al, GC_FUNCTION_SELECT
	mov	ah, GFS_REPLACE
	out	dx, ax

	;
	; blast it gray!
	;

	mov	ax, EGA_START_SEGMENT
	mov	es, ax
	mov	di, EGA_START_OFFSET
	mov	cx, EGA_BUF_LENGTH
	pop	ax				;al = color value

	rep	stosb

	;
	; reset write mode to default else SVGA will biff
	;

	mov	al, GC_MODE
	mov	ah, 0
	out	dx, ax

	.leave
	ret
LoaderClearEGA	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderDisplayEGABorder

DESCRIPTION:	Display the border on this type of screen.

CALLED BY:	LoaderDisplayEGA

PASS:		ds, es	= loader segment

RETURN:		ax	= LoaderBorderType

DESTROYED:	ax, bx, cx, dx, si, di, bp

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

------------------------------------------------------------------------------@

LoaderDisplayEGABorder	proc	near
	uses	es
	.enter

	cmp	ax, LBT_NONE
	je	done			;skip if none...

done:
	.leave
	ret
LoaderDisplayEGABorder	endp

