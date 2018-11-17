COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Loader
FILE:		videoHGC.asm

ROUTINES:
	Name			Description
	----			-----------
	LoaderDisplayHGC	Switch to HGC, and display the splash screen.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

DESCRIPTION:


	$Id: videoHGC.asm,v 1.1 97/04/04 17:26:49 newdeal Exp $

------------------------------------------------------------------------------@

HERC_START_OFFSET	equ	0
HERC_BUF_LENGTH		equ	0x8000

HGC_CHAR_WIDTH		equ	80
HGC_CHAR_HEIGHT		equ	20

L_HGC_L_TEXT_X 		= (HGC_CHAR_WIDTH - size loaderLoadingText) / 2
L_HGC_L_TEXT_Y 		= (HGC_CHAR_HEIGHT / 2) - 3

L_HGC_C_TEXT_X 		= ((HGC_CHAR_WIDTH - size loaderCopyrightText) / 2)
L_HGC_C_TEXT_Y 		= HGC_CHAR_HEIGHT - 1


;----------------------------------------------------------------------------
;from Dumb/HGC/hgcConstant.def
;----------------------------------------------------------------------------

;Screen size constants

PHYSICAL_SCREEN_WIDTH	=	10	; width in inches of typical display
PHYSICAL_SCREEN_HEIGHT	=	7	; width in inches of typical display

SCREEN_PIXEL_WIDTH	=	720	; width of screen, pixels
SCREEN_BYTE_WIDTH	=	90	; width of screen, bytes
SCREEN_HEIGHT		=	348	; height of screen, scan lines

;Video buffer constants

HGC_SCREEN_BUFFER	=	0b000h	; HGC video buffer segment addr

SCREEN_BANK_OFFSET	=	2000h

NUM_SCREEN_BANKS	=	4

;BANK_SIZE	=	SCREEN_BYTE_WIDTH * SCREEN_HEIGHT / NUM_SCREEN_BANKS
;LAST_BANK	=	(NUM_SCREEN_BANKS-1)*SCREEN_BANK_OFFSET
;ALT_SCREEN_BUFFER	= SCREEN_BUFFER + ((LAST_BANK + BANK_SIZE + 15) / 16)
;SAVE_AREA_SIZE		=	(0c000h - ALT_SCREEN_BUFFER) * 16

;HGC Registers
;See page 33 of "PC and PS|2 Video Systems"

HGC_MODE		=	3b8h	;Mode Control register

MODE_720_348		=	00000010b	;720 x 348 mode
MODE_VIDEO_ON		=	00001000b	;Video display enabled
MODE_TEXT		=	00000000b	;80x25 text
HGC_ENABLE_VIDEO	=	MODE_720_348 or MODE_VIDEO_ON
HGC_DISABLE_VIDEO	=	MODE_720_348

HGC_CONFIG		=	3bfh	;Configuration Switch Register

CONFIG_ALLOW_GR		=	00000001b	;Bit set to allow graphics
CONFIG_ENABLE_64K	=	00000010b	;Bit set to use 64K of buffer
CONFIG_TEXT		=	00000000b	;No graphics, 32K only

;BIOD Data area

BIOS_DATA_SEGMENT	=	40h	; BIOS data is at 40:49h
BIOS_DATA_OFFSET	=	49h

;----------------------------------------------------------------------------
;from VidCom/vidcomConstant.def:
;----------------------------------------------------------------------------

CRTC_ADDRESS		=	3b4h		; Address register


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderDisplayHGC

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

LoaderDisplayHGC	proc	near

;before disabling the screen, do we need to do these? (They are right
;now a part of the LoaderSetHGC routine.)
;
;		; Update video BIOS with reasonable values
;push es!
;		mov	ax,BIOS_DATA_SEGMENT	; BIOS data area
;		mov	es,ax
;		mov	di,BIOS_DATA_OFFSET
;
;set ds, save it first
;		mov	si,offset loaderHGCBIOSData
;		mov	cx,BIOS_DATA_LENGTH
;		rep movsb
;
;		; Set configuration switch
;
;		mov	dx,HGC_CONFIG		;Allow graphics mode
;		mov	al,CONFIG_ALLOW_GR or CONFIG_ENABLE_64K
;		out	dx,al

	;Disable this screen, so the user doesn't have to watch us draw
	;(Can't do this before setting the video mode.)
	;	(from Dumb/HGC/hgcAdmin.asm::VidScreenOff)

	mov	dx, HGC_MODE		; HGC control port	

;this would set the video mode to be 720x348 prematurely
;	mov	al, HGC_DISABLE_VIDEO	; no video, no block

	mov	al, 0			; no video, no mode, no block
	out	dx, al			; kill it	

	;set the video mode for the HGC card
	;	(from Dumb/HGC/hgcAdmin.asm::VidSetHGC)

	call	LoaderSetHGC

	;draw the background color

	call	LoaderGetTextBackgroundColor ;ax = background color (0-15)
	push	ax

	mov	ax, LOADER_DEFAULT_GRAPHIC_BACKGROUND_COLOR
	call	LoaderClearHGC

	;draw the border

	call	LoaderGetBorderType	;returns ax = LoaderBorderType

	call	LoaderDisplayHGCBorder
	pop	ax

	;draw the text (NOT video mode specific)

	call	LoaderGetTextColor	;ah = text color, al = same (bg color)

	mov	cx, HGC_CHAR_WIDTH
	mov	dx, HGC_CHAR_HEIGHT
	call	LoaderDisplayTextMessage

;PrintMessage <LoaderDisplayHGC: May already be on>

	;enable video signal on card
	;	(from Dumb/HGC/hgcAdmin.asm::VidScreenOn)

	mov	dx, HGC_MODE		;Enable graphics mode
	mov	al, MODE_720_348 or MODE_VIDEO_ON
					;(Same as HGC_ENABLE_VIDEO constant)
	out	dx,al

ifdef INCLUDE_HGC_IMAGE
	;draw the bitmap, if we should

	call	LoaderDisplayBitmapLogo
ifndef NO_LEGAL_IMAGE
	call	LoaderDisplayBitmapLegal
endif

endif

	;indicate we were successful

	clc
	ret
LoaderDisplayHGC	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoaderSetHGC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the graphics mode for the Hercules card

CALLED BY:	INTERNAL
		LoaderSetHGC

PASS:		ds, es	= loader segment

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		program the CRT controller to do the right thing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Tony	10/88		Initial version
		Jim	03/90		Initial version
		Eric	3/93		Stolen from video driver

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

loaderHGCBIOSData	label	byte
	db	7		; CRT Mode
	dw	80		; CRT Columns
	dw	8000h		; CRT Length
	dw	0		; CRT Start
	dw	8 dup (0)	; Cursor position
	dw	0		; Cursor mode
	db	0		; Active Page
	dw	CRTC_ADDRESS	; CRT Controller Address
	db	0ah		; CRT Mode Set
	db	0		; CRT Palette (unused)
loaderHGCEndBIOSData	label	byte

BIOS_DATA_LENGTH	=	loaderHGCEndBIOSData - loaderHGCBIOSData

loaderHGC_CRTCParams	label	word
	db	35h		; CRTC_REG_HORIZ_TOTAL
	db	2dh		; CRTC_REG_HORIZ_DISPLAYED
	db	2eh		; CRTC_REG_HORIZ_SYNC_POS
	db	07h		; CRTC_REG_HORIZ_SYNC_WIDTH
	db	5bh		; CRTC_REG_VERT_TOTAL
	db	02h		; CRTC_REG_VERT_ADJUST
	db	57h		; CRTC_REG_VERT_DISPLAYED
	db	57h		; CRTC_REG_VERT_SYNC_POS
	db	02h		; CRTC_REG_INTERLACE_MODE
	db	03h		; CRTC_REG_MAX_SCAN_LINE
;disabled in the HGC video driver code also:
;	db	00h		; CRTC_REG_CURSOR_START
;	db	00h		; CRTC_REG_CURSOR_END
loaderHGC_EndCRTCParams	label	word

CRTC_PARAMS_LENGTH	=	loaderHGC_EndCRTCParams - loaderHGC_CRTCParams


LoaderSetHGC	proc	near
		uses	ds, es
		.enter

		mov	ax, cs
		mov	ds, ax

		; Update video BIOS with reasonable values

		mov	ax,BIOS_DATA_SEGMENT	; BIOS data area
		mov	es,ax
		mov	di,BIOS_DATA_OFFSET

		mov	si,offset loaderHGCBIOSData
		mov	cx,BIOS_DATA_LENGTH
		rep movsb

		; Set configuration switch

		mov	dx,HGC_CONFIG		;Allow graphics mode
		mov	al,CONFIG_ALLOW_GR or CONFIG_ENABLE_64K
		out	dx,al

;moved to LoaderDisplayHGC
;		; Blank screen to avoid interference during initialization
;
;		mov	dx, HGC_MODE
;		clr	ax
;		out	dx,al

		; Program the CRT Controller

		clr	ax
		mov	dx,CRTC_ADDRESS
		mov	si,offset loaderHGC_CRTCParams
		mov	cx,CRTC_PARAMS_LENGTH
VI_configLoop:
		mov	al,ah			;output address
		out	dx,al
		inc	dx
		lodsb
		out	dx,al
		dec	dx
		inc	ah
		loop	VI_configLoop

		; Set graphics mode

		mov	dx, HGC_MODE		;Enable graphics mode

;Ack! it seems like this will turn the video signal back on, prematurely.
;		mov	al,MODE_720_348 or MODE_VIDEO_ON

		mov	al,MODE_720_348
		out	dx,al

;moved to LoaderDisplayHGC
;		; Clear screen
;
;		mov	ax, SCREEN_BUFFER
;		mov	es, ax
;		mov	cx, 8000h / 2
;		clr	ax
;		clr	di
;		rep stosw

		.leave
		ret
LoaderSetHGC	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderClearHGC

DESCRIPTION:	Clear this type of display to the background color.

		Set the background to gray (actually, since HGC is 2-color,
		set the background to white.)

CALLED BY:	LoaderDisplayHGC

PASS:		ds, es	= loader segment

RETURN:		ax	= color

DESTROYED:	ax, bx, cx, dx, si, di, bp

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

------------------------------------------------------------------------------@

LoaderClearHGC	proc	near
	uses	es
	.enter

	mov	di, HGC_SCREEN_BUFFER
	mov	es, di
	mov	di, HERC_START_OFFSET
	mov	cx, HERC_BUF_LENGTH
	mov	al, ah			;al = 0, 0xFF, or 0x55 (B&W color value)
	rep	stosb	

if 0
10$:
	blast one line

	xor	al, 0xff
	blast one line
	xor	al, 0xf
	loop	10$
endif

	.leave
	ret
LoaderClearHGC	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderDisplayHGCBorder

DESCRIPTION:	Display the border on this type of screen.

CALLED BY:	LoaderDisplayHGC

PASS:		ds, es	= loader segment

RETURN:		ax	= LoaderBorderType

DESTROYED:	ax, bx, cx, dx, si, di, bp

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

------------------------------------------------------------------------------@

LoaderDisplayHGCBorder	proc	near
	uses	es
	.enter

	cmp	ax, LBT_NONE
	je	done			;skip if none...

done:
	.leave
	ret
LoaderDisplayHGCBorder	endp

