COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Loader
FILE:		videoDisplay.asm

ROUTINES:
	Name			Description
	----			-----------
   	LoaderDisplaySplashScreen
				If possible, display a splash screen to keep
				the user busy while we load.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version
	Tom		10/97		Changed copyright notice to
					New Deal
DESCRIPTION:

	$Id: videoDisplay.asm,v 1.3 98/02/23 19:44:33 gene Exp $

------------------------------------------------------------------------------@
;Note: videoDetect.asm must be included first, as it defines many BIOS
;constants for us.

;------------------------------------------------------------------------------
;		Definitions for the Splash Screen Code
;------------------------------------------------------------------------------

ifndef LOADER_DEFAULT_GRAPHIC_BACKGROUND_COLOR

LOADER_DEFAULT_GRAPHIC_BACKGROUND_COLOR equ	(0xff shl 8) or C_WHITE

endif
					;low byte: 16-color value
					;high byte: mask to use in the B&W case

LOADER_DEFAULT_TEXT_BACKGROUND_COLOR 	equ (0xff shl 8) or C_BLACK
					;low byte: 16-color value
					;high byte: mask to use in the B&W case

LOADER_DEFAULT_TEXT_COLOR	equ	C_WHITE ;16-color value

LoaderBorderType	etype	byte
	LBT_NONE				enum	LoaderBorderType, 0
	LBT_GEOS_V2_RETAIL			enum	LoaderBorderType, 1
	LBT_WIZARD_BA_V1			enum	LoaderBorderType, 2

ifndef IMAGE_TO_BE_DISPLAYED
splashScreenKey	char	"splashscreen", 0
endif
splashColorKey	char	"splashcolor", 0
splashBorderKey	char	"splashborder", 0
splashTextKey	char	"splashtext", 0
splashTextColorKey char	"splashtextcolor", 0
;splashBitmapKey char	"splashbitmap", 0


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderDisplaySplashScreen

DESCRIPTION:	Get the current video mode, and see if this machine can display
		one of the 5 basic video modes (CGA, HGC, EGA, MCGA, VGA).
		If so, change to that mode, and display the splash screen.

CALLED BY:	LoadGeos

PASS:		ds, es - loader segment
		KLV_defSimpleGraphicsMode
			- suggested "simple" graphics mode to use, if any.

RETURN:		KLV_curSimpleGraphicsMode
			- set to equal KLV_defSimpleGraphicsMode, if we
			do our thing.

DESTROYED:	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

------------------------------------------------------------------------------@

LoaderDisplaySplashScreen	proc	near

ifdef IMAGE_TO_BE_DISPLAYED
	; If we're a loader that has an image compiled in for a
	; specific video board, see if we can display on that board.
	
	call	LoaderFindImageSpecificDisplay
	mov	al, cl
	jc	loaderTypeInAL		; jump if found (al = type).
endif
	
	;Were we able to find a "simple" graphics mode?

	mov	al, ds:[loaderVars].KLV_defSimpleGraphicsMode
loaderTypeInAL:
	cmp	al, SSGM_NONE
	je	done			;skip if not...


	; j- 4/16/93: We always put up a splash screen now for
	; copyright declaration.

ifndef	IMAGE_TO_BE_DISPLAYED
	;see if the user wants a splash screen

	call	LoaderTestSplashScreenEnabled
	jc	done			;skip if not...
endif

	;finally, make sure that the "/log" argument was not passed on the
	;command line

	call	LoaderCheckForLogging
	jc	done			;skip if so...

	;switch to the new graphics mode, and display the splash screen
	;IMPORTANT: these routines are not permitted to FatalError after
	;changing the video mode, because LoaderError will not know that
	;it must restore the text video mode (since KLV_curSimpleGraphicsMode
	;has not been set yet.)

	push	ax
	clr	ah
	shl	ax, 1
	mov	di, ax
	call	cs:[videoJumpTable-2][di]
	pop	ax
	jc	done			;skip if error...

	;save the new graphics mode, so that the "simple"-type video drivers
	;can see that we've already switched to their mode, and they will
	;not try to do it again.

	mov	ds:[loaderVars].KLV_curSimpleGraphicsMode, al

done:
	ret
LoaderDisplaySplashScreen	endp

.assert (SSGM_VGA eq 1)
.assert (SSGM_EGA eq 2)
.assert (SSGM_MCGA eq 3)
.assert (SSGM_HGC eq 4)
.assert (SSGM_CGA eq 5)
.assert (SSGM_SVGA_VESA eq 7)

videoJumpTable	label	word
	dw	offset LoaderDisplayVGA	
	dw	offset LoaderDisplayEGA	
	dw	offset LoaderDisplayMCGA	
	dw	offset LoaderDisplayHGC	
	dw	offset LoaderDisplayCGA	
	dw	0	
	dw	offset LoaderDisplaySVGA	


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderTestSplashScreenEnabled

DESCRIPTION:	See if the splash screen is enabled in the .ini file

CALLED BY:	LoaderDisplay{MCGA,VGA,etc.}

PASS:		ds, es	= loader segment

RETURN:		carry set if not enabled

DESTROYED:	bx, cx, dx, si, di, bp

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

------------------------------------------------------------------------------@

ifndef	IMAGE_TO_BE_DISPLAYED

LoaderTestSplashScreenEnabled	proc	near
	uses	ax
	.enter

	mov	si, offset cs:[systemCategoryString]
	mov	cx, cs
	mov	dx, offset cs:[splashScreenKey]
	call	LoaderInitFileReadBoolean

	;return carry set if not enabled
	.leave
	ret
LoaderTestSplashScreenEnabled	endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderGetTextBackgroundColor

DESCRIPTION:	Get the text background color value from the .ini
		file.  Note that the graphic splash screen uses a
		hard-coded background color.

CALLED BY:	LoaderDisplay{MCGA,VGA,etc.}

PASS:		ds, es	= loader segment

RETURN:		al	= color (Color enum type, 0-15)
		ah	= B&W color mask (0x00, 0xFF, or 0x55)

DESTROYED:	bx, cx, dx, si, di, bp

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version
	jeremy		10/93		Change to text background color

------------------------------------------------------------------------------@

LoaderGetTextBackgroundColor	proc	near

	mov	si, offset cs:[systemCategoryString]
	mov	cx, cs
	mov	dx, offset cs:[splashColorKey]
	call	LoaderInitFileReadInteger
	jnc	haveColor		;skip if have color...

	mov	ax, LOADER_DEFAULT_TEXT_BACKGROUND_COLOR ;use default color

haveColor:
	;calculate the B&W color mask

	mov	ah, 0x00
	cmp	al, C_BLACK
	je	done

	mov	ah, 0xFF
	cmp	al, C_WHITE
	je	done

;disabled for now. See TODO file.
;	mov	ah, 0x55		;use a 50% pattern for all other colors

done:
	ret
LoaderGetTextBackgroundColor	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderGetTextColor

DESCRIPTION:	Get the background color value from the .ini file.

CALLED BY:	LoaderDisplay{MCGA,VGA,etc.}

PASS:		ds, es	= loader segment

RETURN:		ah	= color (Color enum type, 0-15)
			(In the B&W case, this value will simply be ignored,
			because we use XOR mode to draw the text.)

DESTROYED:	nothing (al = same)

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

------------------------------------------------------------------------------@

LoaderGetTextColor	proc	near
	uses	bx, cx, dx, si, di, bp
	.enter

	push	ax
	mov	si, offset cs:[systemCategoryString]
	mov	cx, cs
	mov	dx, offset cs:[splashTextColorKey]
	call	LoaderInitFileReadInteger
	mov	ah, al			;ah = text color
	jnc	haveColor		;skip if have color...

	mov	ah, LOADER_DEFAULT_TEXT_COLOR ;use default color

haveColor:
	pop	bx
	mov	al, bl			;restore ah (background color)

	.leave
	ret
LoaderGetTextColor	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderGetBorderType

DESCRIPTION:	Get the border type from the .ini file.

CALLED BY:	LoaderDisplay{MCGA,VGA,etc.}

PASS:		ds, es	= loader segment

RETURN:		ax	= LoaderBorderType (0 = none)

DESTROYED:	bx, cx, dx, si, di, bp

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

------------------------------------------------------------------------------@

LoaderGetBorderType	proc	near
	uses	ds
	.enter

	mov	si, offset cs:[systemCategoryString]
	mov	cx, cs
	mov	dx, offset cs:[splashBorderKey]
	call	LoaderInitFileReadInteger
	jnc	haveBorder		;skip if have border type...

	mov	ax, LBT_NONE 		;use default border (none)

haveBorder:
	;ax = LoaderBorderType

	.leave
	ret
LoaderGetBorderType	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderDisplayTextMessage

DESCRIPTION:	Get the text message for the splash screen from the .ini file

CALLED BY:	LoaderDisplay{MCGA,VGA,etc.}

PASS:		ds, es	= loader segment
		al	= background color value (one of 16 colors)
		ah	= text color value (one of 16 colors)
				(THIS IS IGNORED WHEN DRAWING TO A B&W SCREEN.)

		cx	= width of screen in chars
		dx	= height of screen in chars

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp

	See P231-234 "Programmer's Guide to VGA and EGA Cards"

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

------------------------------------------------------------------------------@

MAX_MESSAGE_LENGTH	equ	SPLASH_SCREEN_BUFFER_SIZE-2

LoaderDisplayTextMessage	proc	near
	uses	ds
	.enter

	mov	di, SPLASH_SCREEN_BUFFER	;es:di = big buffer

	push	cx, dx, ax

	segmov	ds, cs				;ds:si = category string
	mov	si, offset cs:[systemCategoryString]

	mov	cx, cs				;cx:dx = key string
	mov	dx, offset cs:[splashTextKey]

	mov	ax, 255				;search all .ini files in chain
	mov	bx, offset loaderVars.KLV_initFileBufHan
						;start with the primary .ini
	mov	bp, MAX_MESSAGE_LENGTH
	call	LoaderInitFileReadString	;scan the file whose memory
	pop	bp, dx, ax			;BP = width, DX = height
	jc	done				;skip if none...

	;find the length of the widest line (in chars), and the number
	;of rows that are in this text block.
	;	es:di	= start of text
	;	cx	= length of entire block
	;	bp	= width of screen in chars
	;	dx	= height of screen in line

	push	cx, ax
	mov	si, di			;si = position at start of text
	clr	bx			;bx = number of lines = 0

scanTextLine:
	;scan for the end of this line
	;	cx	= number of chars remaining in the block
	;	bx	= number of text lines

	inc	bx			;we've got at least one line of text
	jcxz	foundEnd		;skip if cx = 0...

	mov	al, 0x0d
	repne	scasb			;scan for CR char
	je	scanTextLine		;loop if found it...

foundEnd:
	;reached the end of the text
	;determine the vertical centering for this text
	;	dx	= height of screen in rows
	;	bx	= number of lines of text

	sub	dx, bx			;dx = extra lines on screen
	jnc	foundEnd2		;skip if still a decent value...

	clr	dx

foundEnd2:
	shr	dx, 1			;al = Y offset for centered block
	mov	dh, dl			;dh = Y offset for centered block

	;see if we want to center it

	mov	dl, 0			;default: flush against left edge,
					;because we have multiple lines

	dec	bx			;was there more than one line?
	jnz	haveCoords		;skip if more than one line...

onlyOneLine::
	;there was only one line: calculate the offset to center this text
	;	bp	= width of screen in chars
	;	di	= pointer to char after end of string
	;	si	= pointer to start of line

	sub	di, si			;di = length of string
	sub	bp, di			;bp = extra space on line
	mov	ax, bp			;ax = extra space on line
	shr	ax, 1			;al = X offset for centered text
	mov	dl, al			;dl = X offset for centered text

haveCoords:
	mov	bp, si			;es:bp = start of text again
	pop	cx, ax			;cx = length of string block
					;al = text color

	call	LoaderDisplayTextAtXY

done:
	.leave
	ret
LoaderDisplayTextMessage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoaderDisplayTextAtXY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This function displays some text on screen via a BIOS call.

CALLED BY:	LoaderDisplay{TextMessage,MCGA,VGA,etc.}

PASS:		es:bp	= text message
		cx	= length
		al	= background color value
		ah	= text color value
		dl	= X offset for text
		dh	= Y offset for text

RETURN:		nothing	

DESTROYED:	bx, si, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LoaderDisplayTextAtXY	proc	near
	uses	ax, cx, dx

	.enter

	;	cx	= length
	;	al	= background color value
	;	ah	= text color value
	;	dl	= X offset for text
	;	dh	= Y offset for text

	xor	al, ah			;al = text color, XORd with background
					;color, because we draw using XOR
	or	al, 0x80		;set the XOR bit in this ATTR byte
	mov	bl, al			;bl = ATTR
					;B7 = xor, B3-B0 = color to XOR
					;	with pixels on screen.
	mov	bh, 0			;bh = video page # = 0

	mov	ax, 0x1300		;use bios function 13h, don't move 
					;cursor, and use attribute in bl.
	int	10h

	.leave
	ret
LoaderDisplayTextAtXY	endp


loaderLoadingText	char	VBAR, ' Loading PC/GEOS Ensemble... ', VBAR
loaderLoadingBoxTop	char	ULCORNER
			char	((size loaderLoadingText) - 2) dup (HBAR)
			char	URCORNER
loaderLoadingBoxBot	char	LLCORNER
			char	((size loaderLoadingText) - 2) dup (HBAR)
			char	LRCORNER

loaderCopyrightText	char	'Copyright (C) blueway.Softworks 2018-2024. All Rights Reserved'




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoaderDisplayCopyrightText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This function puts up a loading message and copyright
		notice in the screen.

CALLED BY:	Loader{VGA, EGA, MCGA, etc.}

PASS:		ax - text color
		ch - y position for the first line of the copyright
		     message for this display
		cl - x position for every line of the copyright message
		     for this display
		dh - y position for the first line of the loading
		     message for this display (3 lines total)
		dl - x position for every line of the loading message
		     for this display

RETURN:		nothing

DESTROYED:	bx, cx, es, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/17/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LoaderDisplayCopyrightText	proc	near
	uses	es
	.enter

	push	cx
	segmov	es, cs, bp
	mov	bp, offset loaderLoadingBoxTop
	mov	cx, size loaderLoadingText
	call	LoaderDisplayTextAtXY

	inc	dh
	mov	bp, offset loaderLoadingText
	call	LoaderDisplayTextAtXY

	inc	dh
	mov	bp, offset loaderLoadingBoxBot
	call	LoaderDisplayTextAtXY

	pop	dx		; recover x,y position for copyright text
	mov	bp, offset loaderCopyrightText
	mov	cx, size loaderCopyrightText
	call	LoaderDisplayTextAtXY

	.leave
	ret
LoaderDisplayCopyrightText	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderDisplayRestoreTextMode

DESCRIPTION:	If we have already switched to a splash screen,
		restore the previous text screen now.

CALLED BY:	LoaderError

PASS:		ds, es - loader segment

		KLV_initialTextMode
			- initial text video mode

		KLV_curSimpleGraphicsMode
			- current video mode

RETURN:		ds, es	- same

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	IMPORTANT: since this routine is called by LoaderError, you
	cannot FatalError in here!

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	Eric/Chung	3/93		Initial version

------------------------------------------------------------------------------@

LoaderDisplayRestoreTextMode	proc	near

	;Have we switched from text mode to a simple graphics mode to
	;put up the splash screen?

	cmp	ds:[loaderVars].KLV_curSimpleGraphicsMode, SSGM_NONE
	je	done			;skip if not...

	; set the previous video mode.  The VESA standard says that
	; this should work with VESA boards as well...
	; (VESA Super VGA Standard VS891001, page 6, 10/1/89)

	push	ax
	mov	ah, SET_VMODE
	mov	al, ds:[loaderVars].KLV_initialTextMode
	int	VIDEO_BIOS
	pop	ax

done:
	ret
LoaderDisplayRestoreTextMode	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoaderCheckForLogging

DESCRIPTION:	Get the real .ini key (in case /pXXX was passed)

CALLED BY:	LoaderDisplaySplashScreen

PASS:		ds, es - loader segment

RETURN:		ds, es - same
		carry set if /log (or /LOG) flag is present.

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/ 2/92	Initial version

------------------------------------------------------------------------------@

LoaderCheckForLogging	proc	near
	uses	es, ax, cx, di
	.enter

	mov	es, ds:[loaderVars].KLV_pspSegment
	mov	dx, es:[PSP_endAllocBlk]	; end heap at end of
	mov	di, offset PSP_cmdTail
	mov	cl, es:[di]
	clr	ch				; length of command tail -> cx

	clc					; default: "NO"
	jcxz	done				; skip if no tail...
						; (does not affect flags)

	inc	di				; point past count

;nuked 1/25/93: there is no CR at the end
;	dec	cx				; don't count CR at end
;	jcxz	done

	;Now scan for any arguments

next:
	mov	al, '/'				;switch delimiter -> al
	repne	scasb				;scan for delimiter
	clc					;default: "NO"
	jnz	done				;skip if none found...

	;ugly, yes, but coding time we have not while code space in the loader
	;we have much of.

	mov	al, es:[di]+0
	call	LoaderUpcaseChar
	cmp	al, 'L'
	jne	next

	mov	al, es:[di]+1
	call	LoaderUpcaseChar
	cmp	al, 'O'
	jne	next

	mov	al, es:[di]+2
	call	LoaderUpcaseChar
	cmp	al, 'G'
	jne	next

	stc					;return: "YES"

done:
	.leave
	ret
LoaderCheckForLogging	endp


LoaderUpcaseChar	proc	near
	cmp	al, 'a'
	jb	done

	cmp	al, 'z'
	ja	done

	sub	al, 'a'-'A'

done:
	ret
LoaderUpcaseChar	endp

