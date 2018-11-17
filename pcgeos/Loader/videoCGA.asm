COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Loader
FILE:		videoCGA.asm

ROUTINES:
	Name			Description
	----			-----------
	LoaderDisplayCGA	Switch to CGA, and display the splash screen.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

DESCRIPTION:


	$Id: videoCGA.asm,v 1.1 97/04/04 17:26:39 newdeal Exp $

------------------------------------------------------------------------------@

CGA_START_SEGMENT	equ	0xB800
CGA_BUF1_START_OFFSET	equ	0
CGA_BUF2_START_OFFSET	equ	0x2000
CGA_WIDTH		equ	640
CGA_HEIGHT		equ	200
CGA_BUF_LENGTH		equ	(CGA_WIDTH * 100) / 8

CGA_CHAR_WIDTH		equ	80
CGA_CHAR_HEIGHT		equ	24

L_CGA_L_TEXT_X 		= (CGA_CHAR_WIDTH - size loaderLoadingText) / 2
L_CGA_L_TEXT_Y 		= (CGA_CHAR_HEIGHT / 2) - 3

L_CGA_C_TEXT_X 		= ((CGA_CHAR_WIDTH - size loaderCopyrightText) / 2)
L_CGA_C_TEXT_Y 		= CGA_CHAR_HEIGHT - 1

;-----------------------------------------------------------------------------
;from Dumb/CGA/cgaConstant.def:
;-----------------------------------------------------------------------------
;SCREEN SIZE EQUATES

PHYSICAL_SCREEN_WIDTH	=	10	; width in inches of typical display
PHYSICAL_SCREEN_HEIGHT	=	7	; width in inches of typical display

SCREEN_PIXEL_WIDTH	=	640	; width of screen, pixels
SCREEN_BYTE_WIDTH	=	80	; width of screen, bytes
SCREEN_HEIGHT		=	200	; height of screen, scan lines

;Video buffer constants

SCREEN_BUFFER		=	0b800h	; CGA video buffer segment addr

SCREEN_BANK_OFFSET	=	2000h	; offset for odd lines

NUM_SCREEN_BANKS	=	2

;Misc hardware equates

CGA_MODE_CONTROL	equ	3d8h	  ; mode control reg, for disable video
CGA_ENABLE_VIDEO	equ	00011110b ; value to enable video
CGA_DISABLE_VIDEO	equ	00010110b ; value to enable video


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderDisplayCGA

DESCRIPTION:	Switch to this video mode, and display the splash screen.
		If we're actually a doublescan CGA driver, jump to that
		loader function.

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

LoaderDisplayCGA	proc	near

ifdef INCLUDE_DCGA_IMAGE
	; This is pretty hokey, but we've got to make due since there
	; is no SSGM_DCGA type.
	call	LoaderDisplayDCGA
else

	;set the video mode for the CGA card
	;	(from Dumb/CGA/cgaAdmin.asm::VidSetCGA)

	mov	ah, SET_VMODE		; function # to set video mode
	mov	al, GR02_6420		; set up 640x200 graphics mode
	int	VIDEO_BIOS		; use video BIOS call

	;Disable this screen, so the user doesn't have to watch us draw
	;(Can't do this before setting the video mode.)
	;	(from Dumb/CGA/cgaAdmin.asm::VidScreenOff)

	mov	dx, CGA_MODE_CONTROL	; CGA control port	
	mov	al, CGA_DISABLE_VIDEO	; disable it
	out	dx, al			;

ifndef INCLUDE_CGA_IMAGE
	;draw the background color

	call	LoaderGetTextBackgroundColor ;ax = background color (0-15)
	push	ax
	call	LoaderClearCGA

	;draw the border

	call	LoaderGetBorderType	;returns ax = LoaderBorderType

	call	LoaderDisplayCGABorder
	pop	ax

	;draw the text (NOT video mode specific)

	call	LoaderGetTextColor	;ah = text color, al = same (bg color)

  ifndef IMAGE_TO_BE_DISPLAYED
	mov	cx, CGA_CHAR_WIDTH
	mov	dx, CGA_CHAR_HEIGHT
	call	LoaderDisplayTextMessage
  else
	mov	cx, (L_CGA_C_TEXT_Y shl 8) or L_CGA_C_TEXT_X
	mov	dx, (L_CGA_L_TEXT_Y shl 8) or L_CGA_L_TEXT_X
	call	LoaderDisplayCopyrightText
  endif

else	; INCLUDE_CGA_IMAGE

	; Clear the screen before the image is displayed.

	mov	ax, LOADER_DEFAULT_GRAPHIC_BACKGROUND_COLOR
	call	LoaderClearCGA

	; draw the bitmaps.
	call	LoaderDisplayBitmapLogo
ifndef NO_LEGAL_IMAGE
	call	LoaderDisplayBitmapLegal
endif

endif	; INCLUDE_CGA_IMAGE

	;enable video signal on card
	;	(from Dumb/CGA/cgaAdmin.asm::VidScreenOn)

	mov	dx, CGA_MODE_CONTROL	; CGA control port	
	mov	al, CGA_ENABLE_VIDEO	; enable it
	out	dx, al			;

	;indicate we were successful
	clc

endif	; INCLUDE_DCGA_IMAGE
	ret
LoaderDisplayCGA	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderClearCGA

DESCRIPTION:	Clear this type of display to the background color.

		Set the background to gray (actually, since CGA is 2-color,
		set the background to white.)

CALLED BY:	LoaderDisplayCGA

PASS:		ds, es	= loader segment

		al	= color (Color enum type, 0-15)
		ah	= B&W color mask (0x00, 0xFF, or 0x55)

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

------------------------------------------------------------------------------@

ifndef	INCLUDE_DCGA_IMAGE
LoaderClearCGA	proc	near
	uses	es
	.enter

	mov	di, CGA_START_SEGMENT
	mov	es, di
	mov	di, CGA_BUF1_START_OFFSET
	mov	cx, CGA_BUF_LENGTH
	mov	al, ah			;al = B&W color mask (0 or 0xFF or 0x55)
					;ah = same
	rep	stosb

	mov	di, CGA_BUF2_START_OFFSET
	mov	cx, CGA_BUF_LENGTH
	rep	stosb

	.leave
	ret
LoaderClearCGA	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderDisplayCGABorder

DESCRIPTION:	Display the border on this type of screen.

CALLED BY:	LoaderDisplayCGA

PASS:		ds, es	= loader segment

RETURN:		ax	= LoaderBorderType

DESTROYED:	ax, bx, cx, dx, si, di, bp

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

------------------------------------------------------------------------------@

ifndef	INCLUDE_CGA_IMAGE
LoaderDisplayCGABorder	proc	near
	uses	es
	.enter

	cmp	ax, LBT_NONE
	je	done			;skip if none...

done:
	.leave
	ret
LoaderDisplayCGABorder	endp
endif

endif
