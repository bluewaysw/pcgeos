COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Loader
FILE:		videoDCGA.asm

ROUTINES:
	Name			Description
	----			-----------
	LoaderDisplayDCGA	Switch to DCGA, and display the splash screen.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

DESCRIPTION:

	$Id: videoDCGA.asm,v 1.1 97/04/04 17:26:48 newdeal Exp $

------------------------------------------------------------------------------@

DCGA_START_SEGMENT	equ	0xB800
DCGA_SCREEN_BUF_OFFSET	equ	0x2000
DCGA_BUF1_START_OFFSET	equ	0
DCGA_BUF2_START_OFFSET	equ	DCGA_SCREEN_BUF_OFFSET * 1
DCGA_BUF3_START_OFFSET	equ	DCGA_SCREEN_BUF_OFFSET * 2
DCGA_BUF4_START_OFFSET	equ	DCGA_SCREEN_BUF_OFFSET * 3
DCGA_WIDTH		equ	640

DCGA_HEIGHT		equ	400

DCGA_BUF_LENGTH		equ	((DCGA_WIDTH * DCGA_HEIGHT)/8)/NUM_SCREEN_BANKS

DCGA_GRAPHIC_BACKGROUND_COLOR equ C_BLACK

;-----------------------------------------------------------------------------
;from Dumb/ATT6300/att6300Constant.def:
;-----------------------------------------------------------------------------
;SCREEN SIZE EQUATES

PHYSICAL_SCREEN_WIDTH	=	10	; width in inches of typical display
PHYSICAL_SCREEN_HEIGHT	=	7	; width in inches of typical display

SCREEN_PIXEL_WIDTH	=	640	; width of screen, pixels
SCREEN_BYTE_WIDTH	=	80	; width of screen, bytes
SCREEN_HEIGHT		=	400	; height of screen, scan lines

;Video buffer constants

SCREEN_BUFFER		=	0b800h	; CGA video buffer segment addr

SCREEN_BANK_OFFSET	=	DCGA_SCREEN_BUF_OFFSET

NUM_SCREEN_BANKS	=	4

ATT6300_MODE		=	0x40


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderDisplayDCGA

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

LoaderDisplayDCGA	proc	near

	;
	; This driver was cobbled together for the Bullet project, so
	; it only supports image mode.
	;

	;set the video mode for the CGA card
	;	(from Dumb/CGA/cgaAdmin.asm::VidSetCGA)

	mov	ah, SET_VMODE		; function # to set video mode
	mov     al, ATT6300_MODE        ; set up 640x400 graphics mode
	int	VIDEO_BIOS		; use video BIOS call

	; Clear the screen before the image is displayed.

	; Note that the background color is black rather than white,
	; because this is an inverse display.
	mov	ax, DCGA_GRAPHIC_BACKGROUND_COLOR
	call	LoaderClearDCGA


ifdef	INCLUDE_DCGA_IMAGE
	; draw the bitmap.
	call	LoaderDisplayBitmapLogo
ifndef NO_LEGAL_IMAGE
	call	LoaderDisplayBitmapLegal
endif
endif

	;indicate we were successful

	clc
	ret
LoaderDisplayDCGA	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderClearDCGA

DESCRIPTION:	Clear this type of display to the background color.

		Set the background to gray (actually, since DCGA is 2-color,
		set the background to white.)

CALLED BY:	LoaderDisplayDCGA

PASS:		ds, es	= loader segment

		ah	= B&W color mask (0x00, 0xFF, or 0x55)

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

------------------------------------------------------------------------------@

LoaderClearDCGA	proc	near
	uses	es
	.enter

	mov	di, DCGA_START_SEGMENT
	mov	es, di
	mov	di, DCGA_BUF1_START_OFFSET
	mov	cx, DCGA_BUF_LENGTH / 2 ; Buffer length is even, so
					; save a few cycles by storing words.
	mov	al, ah		;al = B&W color mask (0 or 0xFF or 0x55)
				;ah = same
	rep	stosw

	mov	di, DCGA_BUF2_START_OFFSET
	mov	cx, DCGA_BUF_LENGTH / 2
	rep	stosw

	mov	di, DCGA_BUF3_START_OFFSET
	mov	cx, DCGA_BUF_LENGTH / 2
	rep	stosw

	mov	di, DCGA_BUF4_START_OFFSET
	mov	cx, DCGA_BUF_LENGTH / 2
	rep	stosw

	.leave
	ret
LoaderClearDCGA	endp

