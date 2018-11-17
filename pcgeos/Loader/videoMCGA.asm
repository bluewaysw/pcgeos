COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Loader
FILE:		videoMCGA.asm

ROUTINES:
	Name			Description
	----			-----------
	LoaderDisplayMCGA	Switch to MCGA, and display the splash screen.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

DESCRIPTION:


	$Id: videoMCGA.asm,v 1.1 97/04/04 17:26:47 newdeal Exp $

------------------------------------------------------------------------------@

MCGA_CHAR_WIDTH		equ	80
MCGA_CHAR_HEIGHT	equ	30

L_MCGA_L_TEXT_X 	= (MCGA_CHAR_WIDTH - size loaderLoadingText) / 2
L_MCGA_L_TEXT_Y 	= (MCGA_CHAR_HEIGHT / 2) - 3

L_MCGA_C_TEXT_X 	= ((MCGA_CHAR_WIDTH - size loaderCopyrightText) / 2)
L_MCGA_C_TEXT_Y 	= MCGA_CHAR_HEIGHT - 1


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderDisplayMCGA

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

LoaderDisplayMCGA	proc	near

	;set the video mode for the MCGA card
	;		(from MCGA/mcgaAdmin.asm:VidScreenOff)

	mov	ah, SET_VMODE		; function # to set video mode
	mov	al, GR02_6448		; set up 640x200 graphics mode
	int	VIDEO_BIOS		; use video BIOS call

	;Disable this screen, so the user doesn't have to watch us draw
	;(Can't do this before setting the video mode.)
	;		(from MCGA/mcgaAdmin.asm:VidScreenOff)

	mov	ah, ALT_SELECT		; choose BIOS function number
	mov	bl, VIDEO_SCREEN_ON_OFF ; choose sub-function number
	mov	al, VGA_DISABLE_VIDEO	; disable it this time
	int	VIDEO_BIOS

ifndef INCLUDE_MCGA_IMAGE
	;draw the background color

	call	LoaderGetTextBackgroundColor
	push	ax
	call	LoaderClearMCGA

	;draw the border

	call	LoaderGetBorderType	;returns ax = LoaderBorderType

	call	LoaderDisplayMCGABorder
	pop	ax

	;draw the text (NOT video mode specific)

	call	LoaderGetTextColor	;ah = text color, al = same (bg color)

  ifndef IMAGE_TO_BE_DISPLAYED
	mov	cx, MCGA_CHAR_WIDTH
	mov	dx, MCGA_CHAR_HEIGHT
	call	LoaderDisplayTextMessage
  else
	mov	cx, (L_MCGA_C_TEXT_Y shl 8) or L_MCGA_C_TEXT_X
	mov	dx, (L_MCGA_L_TEXT_Y shl 8) or L_MCGA_L_TEXT_X
	call	LoaderDisplayCopyrightText
  endif

else
	; Clear the screen before the image is put up.
	
	mov	ax, LOADER_DEFAULT_GRAPHIC_BACKGROUND_COLOR
	call	LoaderClearMCGA
	call	LoaderDisplayMCGABorder

	; draw the bitmaps.
	call	LoaderDisplayBitmapLogo
ifndef NO_LEGAL_IMAGE
	call	LoaderDisplayBitmapLegal
endif

endif

	;enable video signal on card

	mov	ah, ALT_SELECT		; choose BIOS function number
	mov	bl, VIDEO_SCREEN_ON_OFF ; choose sub-function number
	mov	al, VGA_ENABLE_VIDEO	; disable video signal
	int	VIDEO_BIOS

	;no error

	clc
	ret
LoaderDisplayMCGA	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderClearMCGA

DESCRIPTION:	Clear this type of display to the background color.

		Set the background to gray (actually, since MCGA is 2-color,
		set the background to white.)

CALLED BY:	LoaderDisplayMCGA

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

LoaderClearMCGA	proc	near
	uses	es
	.enter

	mov	cx, 0x4b00		;number of words in screen memory

	mov	di, 0xA000		;start of screen memory
	mov	es, di

	mov	al, ah			;al = B&W color mask (0 or 0xFF or 0x55)
					;ah = same
	clr	di
	rep 	stosw

	.leave
	ret
LoaderClearMCGA	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderDisplayMCGABorder

DESCRIPTION:	Display the border on this type of screen.

CALLED BY:	LoaderDisplayMCGA

PASS:		ds, es	= loader segment

RETURN:		ax	= LoaderBorderType

DESTROYED:	ax, bx, cx, dx, si, di, bp

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

------------------------------------------------------------------------------@

LoaderDisplayMCGABorder	proc	near
	uses	es
	.enter
	
if 0	;DISABLED FOR NOW
	cmp	ax, LBT_NONE
	je	done			;skip if none...

	;
	; draw the border 32 bits away from the edges of the screen.
	;

	;
	;TOP
	;

	mov	ax, 0xa000		;start of video memory
	mov	es, ax

	mov	di, 0x0a04		;x=32, y=32 
					;(32 * 640 + 32) / 8 = 0x0a04
	mov	cx, 0x24		;number of words to copy
					;(640 - 64) / 16 = 0x24
	clr	ax			;draw in black
	rep	stosw

	;
	;BOTTOM
	;

MCGA_WIDTH		equ	640
MCGA_HEIGHT		equ	480

MCGA_BORDER_LEFT	equ	32
MCGA_BORDER_RIGHT	equ	MCGA_WIDTH-32
MCGA_BORDER_TOP		equ	32
MCGA_BORDER_BOTTOM	equ	MCGA_HEIGHT-32


	mov	di, (MCGA_BORDER_BOTTOM * MCGA_WIDTH + MCGA_BORDER_LEFT) / 8
;	mov	di, 0x8c04		;x=448, y=32 
					;(448 * 640 + 32) / 8 = 0x8c04
	mov	cx, 0x24		;number of words to copy
					;(640 - 64) / 16 = 0x24
	clr	ax			;draw in black
	rep	stosw

	;
	;LEFT
	;

	mov	cx, 0x1a0		;480 - 64 = 0x1a0
	mov	di, 0xa54		;x=33, y=32
					;(33 * 640 + 32) / 8 = 0xa54

drawLeft:	
	mov	{byte} es:[di], 0x7f ;bit mask 0111 1111
	add	di, 0x50
	loop	drawLeft

	;
	;RIGHT
	;

	mov	cx, 0x1a0		;480 - 64 = 0x1a0
	mov	di, 0xa9c		;x=33, y=608
					;(33 * 640 + 608) / 8 = 0xa9c

drawRight:
	mov	es:[di], 0xfe		;bit mask 1111 1110
	add	di, 0x50
	loop	drawRight
endif

	.leave
	ret
LoaderDisplayMCGABorder	endp

