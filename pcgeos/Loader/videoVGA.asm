COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Loader
FILE:		videoVGA.asm

ROUTINES:
	Name			Description
	----			-----------
	LoaderDisplayVGA	Switch to VGA, and display the splash screen.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

DESCRIPTION:


	$Id: videoVGA.asm,v 1.1 97/04/04 17:26:50 newdeal Exp $

------------------------------------------------------------------------------@

VGA_START_SEGMENT	equ	0xA000
VGA_START_OFFSET	equ	0

VGA_WIDTH		equ	640
VGA_HEIGHT		equ	480
VGA_BUF_LENGTH		equ	(VGA_WIDTH * VGA_HEIGHT) / 8

VGA_CHAR_WIDTH		equ	80
VGA_CHAR_HEIGHT		equ	30

L_VGA_L_TEXT_X 	= (VGA_CHAR_WIDTH - size loaderLoadingText) / 2
L_VGA_L_TEXT_Y 	= (VGA_CHAR_HEIGHT / 2) - 3

L_VGA_C_TEXT_X 	= ((VGA_CHAR_WIDTH - size loaderCopyrightText) / 2)
L_VGA_C_TEXT_Y 	= VGA_CHAR_HEIGHT - 1
	

COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderDisplayVGA

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

LoaderDisplayVGA	proc	near

	;set the video mode for the VGA card
	;	(from VGAlike/VGA/vgaAdmin.asm::VidSetVGA)

	mov	ah, SET_VMODE		; function # to set video mode
	mov	al, GR0F_6448		; set up 640x480 graphics mode
	int	VIDEO_BIOS		; use video BIOS call

	;Disable this screen, so the user doesn't have to watch us draw
	;(Can't do this before setting the video mode.)
	;	(from VGAlike/VGA/vgaAdmin.asm::VidScreenOff)

;;	mov	ah, ALT_SELECT		; choose BIOS function number
;;	mov	bl, VIDEO_SCREEN_ON_OFF ; choose sub-function number
;;	mov	al, VGA_DISABLE_VIDEO	; disable it this time
;;	int	VIDEO_BIOS

	; If we have an image to blast up, skip the text options.
	; j- 4/16/93

ifndef INCLUDE_VGA_IMAGE
	; draw the background color

	call	LoaderGetTextBackgroundColor ;ax = background color (0-15)
	push	ax
	call	LoaderClearVGA

	; draw the border

	call	LoaderGetBorderType	;returns ax = LoaderBorderType

	call	LoaderDisplayVGABorder
	pop	ax

	; draw the text (NOT video mode specific)

	call	LoaderGetTextColor	;ah = text color, al = same (bg color)

  ifndef IMAGE_TO_BE_DISPLAYED
	;
	; Display the text from the .ini file (if any exists).
	;
	mov	cx, VGA_CHAR_WIDTH
	mov	dx, VGA_CHAR_HEIGHT
	call	LoaderDisplayTextMessage
  else
	;
	; Display the hardcoded copyright text splash screen.
	;
	mov	cx, (L_VGA_C_TEXT_Y shl 8) or L_VGA_C_TEXT_X
	mov	dx, (L_VGA_L_TEXT_Y shl 8) or L_VGA_L_TEXT_X
	call	LoaderDisplayCopyrightText
  endif

else

	; Clear the screen before the image is put up.
	
	mov	ax, LOADER_DEFAULT_GRAPHIC_BACKGROUND_COLOR
	call	LoaderClearVGA
	call	LoaderDisplayVGABorder

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
	mov	al, VGA_ENABLE_VIDEO	; enable video signal
	int	VIDEO_BIOS

	; pause for a little bit of time (about 1/4 second)
	; based on the raster being on/off the screen
	push	ax, cx, dx
	mov	cx, 60
	mov	dx, 03dah
rasterwait1:
	in	al, dx
	test	al, 08h
	jne	rasterwait1
rasterwait2:
	in	al, dx
	test	al, 08h
	je	rasterwait2
	dec	cx
	cmp	cx, 0
	jne	rasterwait1

	pop	ax, cx, dx

	;indicate we were successful

	clc
	ret
LoaderDisplayVGA	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderClearVGA

DESCRIPTION:	Clear this type of display to the background color.

		Set the background to gray (actually, since VGA is 2-color,
		set the background to white.)

CALLED BY:	LoaderDisplayVGA

PASS:		ds, es	= loader segment

RETURN:		ax	= color

DESTROYED:	ax, bx, cx, dx, si, di, bp

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

------------------------------------------------------------------------------@

LoaderClearVGA	proc	near
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
	mov	ax, VGA_START_SEGMENT
	mov	es, ax

	pop	ax
	mov	di, VGA_START_OFFSET
	mov	cx, VGA_BUF_LENGTH
	rep	stosb

	;
	; reset write mode to default else SVGA will biff
	;

	mov	al, GC_MODE
	mov	ah, 0
	out	dx, ax

	.leave
	ret
LoaderClearVGA	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderDisplayVGABorder

DESCRIPTION:	Display the border on this type of screen.

CALLED BY:	LoaderDisplayVGA

PASS:		ds, es	= loader segment

RETURN:		ax	= LoaderBorderType

DESTROYED:	ax, bx, cx, dx, si, di, bp

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

------------------------------------------------------------------------------@

LoaderDisplayVGABorder	proc	near
	uses	es
	.enter

	cmp	ax, LBT_NONE
	je	done			;skip if none...

done:
	.leave
	ret
LoaderDisplayVGABorder	endp

