COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) New Deal 1999 -- All Rights Reserved

PROJECT:	GeoSafari
FILE:		safariBitmap.asm

AUTHOR:		Gene Anderson

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/5/99		Initial revision

DESCRIPTION:
	Code for loading and drawing bitmaps

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include safariGeode.def
include safariConstant.def

CommonCode	segment	resource

if _NEW_LOGO
else
;
; new logo contains copyright text: no need for drawing code
;


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawCenteredString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a string centered horizontally in an object

CALLED BY:	UTILITY

PASS:		di - GState
		bx - y pos
		dx - chunk of string (in Strings resource)
		*ds:si - object to draw in

RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/12/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

DrawCenteredString	proc	near
		uses	ax, bx, cx, ds, si
yPos		local	word	push bx
left		local	word
right		local	word
		.enter

	;
	; Prep for drawing
	;
		push	dx
		call	VisGetBounds
		mov	ss:left, ax
		mov	ss:right, cx
		pop	dx
		mov	ax, C_WHITE
CheckHack <CF_INDEX eq 0>
		call	GrSetTextColor
	;
	; Lock the string
	;
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	si, dx
		mov	si, ds:[si]			;ds:si <- string
	;
	; get the width and figure out the x position
	;
		clr	cx
		call	GrTextWidth			;dx <- string width
		mov	ax, ss:right
		sub	ax, ss:left			;ax <- object width
		sub	ax, dx				;ax <- difference
		shr	ax, 1				;ax <- difference/2
		add	ax, ss:left			;ax <- x pos
	;
	; draw the pup
	;
		mov	bx, ss:yPos			;bx <- y position
		call	GrDrawText
	;
	; Unlock the string
	;
		mov	bx, handle Strings
		call	MemUnlock

		.leave
		ret
DrawCenteredString	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDisplayType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of colors and screen type

CALLED BY:	UTILITY

PASS:		none
RETURN:		al - DisplayType
		ah - DisplayClass
		z flag (je) - set if 16 color
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/6/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

GetDisplayType	proc	near
		uses	bx, cx, si
		.enter

		clr	bx				;bx <- current process
		call	GeodeGetAppObject		;^lbx:si <- app obj
		call	UserGetDisplayType
		mov	al, ah				;al <- DisplayType
		andnf	ah, mask DT_DISP_CLASS
if offset DT_DISP_CLASS ne 0
		mov	cl, offset DT_DISP_CLASS
		shr	ah, cl				;ah <- DisplayClass
endif
		cmp	ah, DC_COLOR_4			;set z flag

		.leave
		ret
GetDisplayType	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsSmallDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if on a small (e.g., TV) display

CALLED BY:	UTILITY

PASS:		none
RETURN:		carry - set if on a smalll display
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/6/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

IsSmallDisplay	proc	near
		uses	ax, bx, cx, dx, bp, si, di
		.enter

		clr	bx				;bx <- current process
		call	GeodeGetAppObject		;^lbx:si <- app obj
		mov	ax, MSG_GEN_GUP_QUERY
		mov	cx, GUQT_SCREEN
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		mov	di, bp				;di <- window handle
		call	WinGetWinScreenBounds
		sub	dx, bx				;dx <- height
		cmp	dx, 479				;carry set for 'jb'

		.leave
		ret
IsSmallDisplay	endp

CommonCode	ends
