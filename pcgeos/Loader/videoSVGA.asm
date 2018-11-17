COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Loader
FILE:		videoSVGA.asm

ROUTINES:
	Name			Description
	----			-----------
	LoaderDisplaySVGA	Switch to SVGA, and display the splash screen.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Ted		4/93		Initial version

DESCRIPTION:

	$Id: videoSVGA.asm,v 1.1 97/04/04 17:26:46 newdeal Exp $

------------------------------------------------------------------------------@

SVGA_START_SEGMENT	equ	0xA000
SVGA_START_OFFSET	equ	0

SVGA_WIDTH		equ	800
SVGA_HEIGHT		equ	600
SVGA_BUF_LENGTH		equ	(SVGA_WIDTH * SVGA_HEIGHT) / 8

SVGA_CHAR_WIDTH		equ	100
SVGA_CHAR_HEIGHT	equ	30
SVGA_CHAR_HEIGHT2	equ	45	; height used for .ini text string

L_SVGA_L_TEXT_X 	= (SVGA_CHAR_WIDTH - size loaderLoadingText) / 2
L_SVGA_L_TEXT_Y 	= (SVGA_CHAR_HEIGHT / 2) - 3

L_SVGA_C_TEXT_X 	= ((SVGA_CHAR_WIDTH - size loaderCopyrightText) / 2)
L_SVGA_C_TEXT_Y 	= SVGA_CHAR_HEIGHT - 1
	
;****************************************************************************
;	VESA BIOS EXTENSIONS
;****************************************************************************

VESA_BIOS_EXT		=	0x4f		; VESA defined BIOS extensions

			; VESA extended BIOS functions
VESA_SET_MODE		=	2		; VESA fn 2, set video mode

			; VESA defined mode numbers
VESA_800x600_4BIT	=	0x102		; 800x600 16-color (new #)


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderDisplaySVGA

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
	thk		4/93		Initial version

------------------------------------------------------------------------------@

LoaderDisplaySVGA	proc	near

	;set the video mode for the SVGA card
	;	(from VGAlike/SVGA/svgaAdmin.asm::VidSetVESA)

	mov	ah, VESA_BIOS_EXT
	mov	al, VESA_SET_MODE
	mov	bx, VESA_800x600_4BIT 	; mode number, clear memory
	int	VIDEO_BIOS

	;Disable this screen, so the user doesn't have to watch us draw
	;(Can't do this before setting the video mode.)
	;	(from VGAlike/VGA/vgaAdmin.asm::VidScreenOff)

	mov	ah, ALT_SELECT		; choose BIOS function number
	mov	bl, VIDEO_SCREEN_ON_OFF ; choose sub-function number
	mov	al, VGA_DISABLE_VIDEO	; disable it this time
	int	VIDEO_BIOS

	; If we have an image to blast up, skip the text options.
	; j- 4/16/93

ifndef INCLUDE_SVGA_IMAGE
	; draw the background color

	call	LoaderGetTextBackgroundColor ;ax = background color (0-15)
	push	ax
	call	LoaderClearSVGA

	; draw the border

	call	LoaderGetBorderType	;returns ax = LoaderBorderType

	call	LoaderDisplaySVGABorder
	pop	ax

	; draw the text (NOT video mode specific)

	call	LoaderGetTextColor	;ah = text color, al = same (bg color)

  ifndef IMAGE_TO_BE_DISPLAYED
	;
	; Display the text from the .ini file (if any exists).
	;
	mov	cx, SVGA_CHAR_WIDTH
	mov	dx, SVGA_CHAR_HEIGHT2
	call	LoaderDisplayTextMessage
  else
	;
	; Display the hardcoded copyright text splash screen.
	;
	mov	cx, (L_SVGA_C_TEXT_Y shl 8) or L_SVGA_C_TEXT_X
	mov	dx, (L_SVGA_L_TEXT_Y shl 8) or L_SVGA_L_TEXT_X
	call	LoaderDisplayCopyrightText
  endif

else

	; Clear the screen before the image is put up.
	
	mov	ax, LOADER_DEFAULT_GRAPHIC_BACKGROUND_COLOR
	call	LoaderClearSVGA
	call	LoaderDisplaySVGABorder

	; draw the bitmaps.
	call	LoaderDisplayBitmapLogo
ifndef NO_LEGAL_IMAGE
	call	LoaderDisplayBitmapLegal
endif

endif

	;enable video signal on card
	;	(from VGAlike/VGA/vgaAdmin.asm::VidScreenOn)

	mov	ah, ALT_SELECT		; choose BIOS function number
	mov	bl, VIDEO_SCREEN_ON_OFF ; choose sub-function number
	mov	al, VGA_ENABLE_VIDEO	; disable video signal
	int	VIDEO_BIOS

	;indicate we were successful

	clc
	ret
LoaderDisplaySVGA	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderClearSVGA

DESCRIPTION:	Clear this type of display to the background color.

		Set the background to gray (actually, since SVGA is 2-color,
		set the background to white.)

CALLED BY:	LoaderDisplaySVGA

PASS:		ds, es	= loader segment

RETURN:		ax	= color

DESTROYED:	ax, bx, cx, dx, si, di, bp

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

------------------------------------------------------------------------------@

LoaderClearSVGA	proc	near
	uses	es
	.enter

	;
	; set bit mask to all bits
	;

	push	ax
	mov	ah, 0xff			;repeat the write operation
						;over all 8 bits in the byte
						;(write 8 pixels at once)
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
	mov	ax, SVGA_START_SEGMENT
	mov	es, ax

	pop	ax
	mov	di, SVGA_START_OFFSET
	mov	cx, SVGA_BUF_LENGTH
	rep	stosb

	;
	; reset write mode to default else SVGA will biff
	;

	mov	al, GC_MODE
	mov	ah, 0
	out	dx, ax

	.leave
	ret
LoaderClearSVGA	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderDisplaySVGABorder

DESCRIPTION:	Display the border on this type of screen.

CALLED BY:	LoaderDisplaySVGA

PASS:		ds, es	= loader segment

RETURN:		ax	= LoaderBorderType

DESTROYED:	ax, bx, cx, dx, si, di, bp

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

------------------------------------------------------------------------------@

LoaderDisplaySVGABorder	proc	near
	uses	es
	.enter

	cmp	ax, LBT_NONE
	je	done			;skip if none...

done:
	.leave
	ret
LoaderDisplaySVGABorder	endp

