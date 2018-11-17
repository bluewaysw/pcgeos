COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/User
FILE:		userTitleScreen.asm

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/90		Initial version

DESCRIPTION:
	Contains routines to put up, remove title screen
	
	$Id: userTitleScreen.asm,v 1.1 97/04/07 11:45:53 newdeal Exp $

-------------------------------------------------------------------------------@

TitleScreen segment resource

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------

;
; General
;
BACKGROUND_COLOR	= C_DARK_GRAY
SHADOW_OFFSET		= -3


;----------------------------------------
; GEOWORKS company name
;----------------------------------------
;
geoWorksText	byte	'GEOWORKS', 0

GEOWORKS_POINT_SIZE	= 80
GEOWORKS_X 		= 6
GEOWORKS_Y		= 8
GEOWORKS_BOTTOM		= GEOWORKS_POINT_SIZE + GEOWORKS_Y

;GEOWORKS_BOTTOM_COLOR	= C_BLACK
GEOWORKS_MIDDLE_COLOR	= C_CYAN
GEOWORKS_TOP_COLOR	= C_LIGHT_CYAN


;----------------------------------------
; Copyright
;----------------------------------------
;
copyrightText	byte	'Copyright ', C_COPYRIGHT, ' GEOWORKS 1990.  '
		byte	'All rights reserved.', 0

COPYRIGHT_POINT_SIZE	= 20
COPYRIGHT_X	= 155
COPYRIGHT_Y	= 480-36
COPYRIGHT_COLOR	= C_LIGHT_CYAN

;----------------------------------------
; GEOS name
;----------------------------------------
;
textBuf	byte	'GeoVision', 0
START_SIZE	= 146
START_ANGLE	= 22
START_X		=	-13 - REPS*INC_X
START_Y		=	GEOWORKS_BOTTOM + 210 - REPS*INC_Y

REPS	= 12

INC_SIZE	= 0	; change in point size
INC_ANGLE	= 0	; change in angle
INC_X		= 1	; x movement
INC_Y		= 1	; y movement




;patternTab	label	byte
;	byte	C_LIGHT_GRAY
;	byte	C_LIGHT_GRAY
;	byte	C_LIGHT_GRAY
;	byte	C_LIGHT_GRAY
;	byte	C_LIGHT_GRAY
;	byte	C_LIGHT_GRAY
;	byte	C_DARK_GRAY
;	byte	C_WHITE

colorTab	label	byte
	byte	C_LIGHT_GRAY
	byte	C_LIGHT_GRAY
	byte	C_LIGHT_GRAY
	byte	C_LIGHT_GRAY
	byte	C_LIGHT_GRAY
	byte	C_LIGHT_GRAY
	byte	C_LIGHT_GRAY
	byte	C_LIGHT_GRAY
	byte	C_LIGHT_GRAY
	byte	C_LIGHT_GRAY
	byte	C_LIGHT_GRAY
	byte	C_LIGHT_GRAY
	byte	C_LIGHT_GRAY
	byte	C_LIGHT_GRAY
	byte	C_DARK_GRAY
	byte	C_WHITE

NUM_PATS = ($ - colorTab)

;maskTab		label byte

;----------------------------------------
; MISC
;----------------------------------------
;

titleCategoryStr	char	"ui", 0
useTitleScreenStr	char	"showTitleScreen", 0





;------------------------------------------------------------------------------
;		Code
;------------------------------------------------------------------------------



COMMENT @----------------------------------------------------------------------

FUNCTION:	UserPutupTitleScreen

DESCRIPTION:	Draws title screen

CALLED BY:	EXTERNAL

PASS:
	Nothing

RETURN:

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/90		Initial version

------------------------------------------------------------------------------@


UserPutupTitleScreen	proc	far
	mov	ds:[titleScreenGState], 0	; No gstate yet

					; See if we should show title or not
	push	ds
	segmov	ds, cs, cx
	mov	si, offset cs:[titleCategoryStr]
	mov	dx, offset cs:[useTitleScreenStr]
	call	InitFileReadBoolean	;ax <- integer value
	pop	ds
	jc	doDone			; no title if error
	tst	ax
	jnz	continue		; no title if false
doDone:
	jmp	done

continue:
	; FIRST, OPEN THE WINDOW
	;
	push	ds			; preserve dgroup

	; Push owner on stack  as first parameter to WinOpen, so that same
	; owner will own window.
	;
	call	GeodeGetProcessHandle	;returns bx = process handle
	push	bx			; Push layer ID to use (owner of obj)
	push	bx			; Push owner of window on stack


	; NOW, get the video driver to put window on
	;
	call	GeodeInfoDefaultDriver
					; bx = default video driver handler
	push	bx			; Pass on stack to WinOpen

	call	GeodeInfoDriver		; ds:si is video driver structure
	mov     cx, ds:[si][DI_pageW]   ; x size
	mov     dx, ds:[si][DI_pageH]   ; y size


	clr	ax			; stack param:  pass region
	clr	bx			;		(rectangular)

	push	ax
	push	bx

	dec	dx			; Push bounds for window
	push	dx
	dec	cx
	push	cx
	push	bx
	push	ax

	mov	ax, ((mask WCF_PLAIN or mask WCF_TRANSPARENT) shl 8) \
							or BACKGROUND_COLOR
	
	clr	bp		; NO input OD
	clr	di
	mov	cx, di		; pass enter/leave OD same
	mov	dx, bp
	mov	si, mask WPF_CREATE_GSTATE or mask WPF_ROOT or WIN_PRIO_ON_TOP
				; pass handle of video driver
	call	WinOpen
	pop	ds		; restore dgroup
	mov	ds:[titleScreenGState], di	; store away win gstate

	; FETCH BOUNDS again
	;
	push	di
	push	ds
	call	GeodeInfoDefaultDriver
	call	GeodeInfoDriver		; ds:si is video driver structure
	mov     cx, ds:[si][DI_pageW]   ; x size
	mov     dx, ds:[si][DI_pageH]   ; y size
	pop	ds
	pop	di

	; FILL IN BACKGROUND COLOR
	;
	push	ds
	mov	ax, cs
	mov	ds, ax

	mov	al, BACKGROUND_COLOR
	mov	ah, CF_INDEX
	call	GrSetAreaColor
	clr	ax
	clr	bx
	mov	cx, 4000
	mov	dx, 4000
	call	GrFillRect


	; DRAW COMPANY TITLE
	;
	mov	cx, FID_DTC_URW_ROMAN		;cx <- font ID
	mov	dx, GEOWORKS_POINT_SIZE
	mov	ah, 0				;dx:ah <- pointsize
	call	GrSetFont
	mov	al, mask TS_ITALIC
	clr	ah
;	call	GrSetTextStyle

;	mov	al, GEOWORKS_BOTTOM_COLOR
;	mov	ah, CF_INDEX
;	call	GrSetTextColor
;	mov	si, offset geoWorksText		;ds:si <- ptr to text
;	clr	cx				;cx <- flag: NULL termintated
;	mov	ax, GEOWORKS_X 
;	mov	bx, GEOWORKS_Y 			;(ax,bx) <- position
;	call	GrDrawText

	mov	al, GEOWORKS_MIDDLE_COLOR
	mov	ah, CF_INDEX
	call	GrSetTextColor
	mov	si, offset geoWorksText		;ds:si <- ptr to text
	clr	cx				;cx <- flag: NULL termintated
	mov	ax, GEOWORKS_X-SHADOW_OFFSET
	mov	bx, GEOWORKS_Y-SHADOW_OFFSET		;(ax,bx) <- position
	call	GrDrawText
	mov	al, GEOWORKS_TOP_COLOR
	mov	ah, CF_INDEX
	call	GrSetTextColor
	mov	si, offset geoWorksText		;ds:si <- ptr to text
	clr	cx				;cx <- flag: NULL termintated
	mov	ax, GEOWORKS_X-2*SHADOW_OFFSET
	mov	bx, GEOWORKS_Y-2*SHADOW_OFFSET		;(ax,bx) <- position
	call	GrDrawText
	clr	al
	mov	ah, mask TS_ITALIC
	call	GrSetTextStyle


	; DRAW CUTE ROTATION STUFF
	;
	call	DrawRotatedImage


	; DRAW COPYRIGHT NOTICE
	;
	mov	cx, FID_DTC_URW_ROMAN		;cx <- font ID
	mov	dx, COPYRIGHT_POINT_SIZE
	mov	ah, 0				;dx:ah <- pointsize
	call	GrSetFont
	mov	al, COPYRIGHT_COLOR
	mov	ah, CF_INDEX
	call	GrSetTextColor
	mov	si, offset copyrightText		;ds:si <- ptr to text
	clr	cx				;cx <- flag: NULL termintated
	mov	ax, COPYRIGHT_X
	mov	bx, COPYRIGHT_Y			;(ax,bx) <- position
	call	GrDrawText


	pop	ds

	mov	ax, 20				; Wait for a bit, while
						; we're admired.
	call	TimerSleep
done:
	ret

UserPutupTitleScreen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawRotatedImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do an funky rotation demo
CALLED BY:	DrawIt

PASS:		ds - seg addr of tables
		di - handle of gstate
RETURN:		none
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	11/30/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawRotatedImage	proc	near
	mov	al, CMT_DITHER		;al <- map mode
	call	GrSetTextColorMap

	mov	dx, START_X			; translate to draw point 
	clr	cx
	mov	bx, START_Y
	clr	ax
	call	GrApplyTranslation		

	mov	dx, START_ANGLE
	clr	cx				;dx:cx <- angle
	call	GrApplyRotation

	mov	dx, START_SIZE			;dx <- pointsize
	clr	bp
myloop:
	push	dx

	mov	cx, FID_DTC_URW_ROMAN		;cx <- font ID
	mov	ah, 0				;dx:ah <- pointsize
	call	GrSetFont

	mov	si, bp
;	mov	bx, ds:curCycle			;bx <- cycle offset
	mov	bx, 0				;bx <- cycle offset
;	tst	ds:isColor
;	je	drawBW
	mov	al, ds:colorTab[bx][si]		;al <- color to draw in
	jmp	doDraw
;drawBW:
;	mov	al, ds:patternTab[bx][si]	;al <- color to map to
doDraw:	
	mov	ah, CF_INDEX
	call	GrSetTextColor

	mov	si, offset textBuf		;ds:si <- ptr to text
	clr	cx				;cx <- flag: NULL termintated
	mov	ax, 0 
	mov	bx, 0 				;(ax,bx) <- position
	call	GrDrawText

	mov	dx, INC_ANGLE
	clr	cx				;dx:cx <- angle
	call	GrApplyRotation

	mov	dx, INC_X			; move draw location
	clr	cx
	mov	bx, INC_Y
	clr	ax
	call	GrApplyTranslation		

	pop	dx
	add	dx, INC_SIZE			;dx <- new pointsize
	inc	bp				;bp <- index of new pattern
	cmp	bp, NUM_PATS
	jb	myloop				;branch if more patterns

	call	GrSetNullTransform
	ret
DrawRotatedImage	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	UserRemoveTitleScreen

DESCRIPTION:	Removes title screen

CALLED BY:	EXTERNAL

PASS:
	Nothing

RETURN:

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/90		Initial version

------------------------------------------------------------------------------@


UserRemoveTitleScreen	proc	far
	mov	di, ds:[titleScreenGState]
	tst	di
	jz	done
	mov	ds:[titleScreenGState], 0
	call	WinClose
done:
	ret
UserRemoveTitleScreen	endp

TitleScreen ends

