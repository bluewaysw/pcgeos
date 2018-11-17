COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		jsWelcome.asm

AUTHOR:		Steve Yegge, Jul 15, 1993

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_META_START_SELECT   Make ourselves go away!

    MTD MSG_META_END_SELECT     Make ourselves go away!

    MTD MSG_VIS_DRAW            Draw the picture (if any) and welcome
				string.

    INT DrawCenteredString      Draw a string centered horizontally

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/15/93		Initial revision

DESCRIPTION:

	************************ NOTE ******************************

	This file is no longer in use!  Notice the "if 0" at the start!

	************************ NOTE ******************************
	

	$Id: jsWelcome.asm,v 1.1 97/04/04 16:53:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if 0
WelcomeCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WelcomeStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make ourselves go away!

CALLED BY:	MSG_META_START_SELECT

PASS:		*ds:si	= WelcomeContentClass object
		ds:di	= WelcomeContentClass instance data

RETURN:		ax	= MouseReturnFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WelcomeStartSelect	method dynamic	WelcomeContentClass, 
					MSG_META_START_SELECT,
					MSG_META_KBD_CHAR
		uses	cx, dx, bp
		.enter
	;
	;  Get the block our view is in (this is the same block
	;  as the main dialog).  Tell ourselves to disappear.
	;
if 0
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	bx, ds:[di].VCNI_view.handle
		mov	si, offset WelcomeDialog
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		call	ObjMessage
else
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		mov	bx, ds:[di].VCNI_view.handle
		mov	si, offset WelcomeScreen
		mov	cx, IC_DISMISS
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
endif
	;
	;  Put up calibration screen.
	;
		mov	ax, MSG_JS_PRIMARY_DO_CALIBRATION
		mov	bx, handle MyJSPrimary
		mov	si, offset MyJSPrimary
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
done:
		mov	ax, mask MRF_PROCESSED
		
		.leave
		ret
WelcomeStartSelect	endm

if 0
WelcomeEndSelect	method dynamic	WelcomeContentClass, 
					MSG_META_END_SELECT,
					MSG_META_PTR
		ret
WelcomeEndSelect	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WelcomeVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the picture (if any) and welcome string.

CALLED BY:	MSG_VIS_DRAW

PASS:		*ds:si	= WelcomeContentClass object
		ds:di	= WelcomeContentClass instance data
		^hbp	= gstate to draw through

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WelcomeVisDraw	method dynamic WelcomeContentClass, MSG_VIS_DRAW
		uses	ax, cx, dx, bp
		.enter
if 0
	;
	;  Draw the hello-there string.
	;
		mov	di, bp			; gstate
		mov	bp, TRUE
		mov	bx, WELCOME_STRING_TOP
		mov	si, offset WelcomeString
		call	DrawCenteredString
	;
	;  Draw the touch-me string.  Touch me, touch me.
	;
		mov	bx, TOUCH_SCREEN_STRING1_TOP
		mov	si, offset TouchAnywhere1String
		call	DrawCenteredString

		mov	bx, TOUCH_SCREEN_STRING2_TOP
		mov	si, offset TouchAnywhere2String
		call	DrawCenteredString
else
	;
	; fake entry into calibration screen
	;
		mov	ax, MSG_META_START_SELECT
		clr	cx, dx, bp			; fake press
		mov	bx, handle JSWelcomeContent
		mov	si, offset JSWelcomeContent
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
endif
		.leave
		ret
WelcomeVisDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawCenteredString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a string centered horizontally

CALLED BY:	UTILITY

PASS:		SI	= Chunk handle of string
		DI	= GState handle
		BP	= TRUE (draw) or FALSE (don't draw)
		BX	= Top of string

RETURN:		AX	= Left
		CX	= Right
		DX	= Top

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawCenteredString	proc	far
		uses	si, ds
		.enter
	;		
	; Lock the done string
	;
		push	bx
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	si, ds:[si]		; string => DS:SI
		pop	bx
	;
	; Set the GState state properly
	;
		mov	cx, FID_BERKELEY
		mov	dx, SCREEN_FONT_SIZE
		clr	ah
		call	GrSetFont
	;
	; Calculate the text width
	;
		clr	cx			; NULL-terminated
		call	GrTextWidth
		mov	ax, SCREEN_WIDTH
		mov	cx, ax
		sub	ax, dx
		sar	ax, 1			; left => AX
		sub	cx, ax			; right => CX
		mov	dx, bx
		add	dx, SCREEN_FONT_SIZE	; bottom => DX
	;
	; Now draw the sucker
	;
		cmp	bp, TRUE
		jne	done			; don't draw if not TRUE
		push	cx, dx
		clr	cx			; NULL-terminated
		call	GrDrawText		; draw the text
		pop	cx, dx
done:
	;
	; Clean up
	;
		push	bx
		mov	bx, handle Strings
		call	MemUnlock
		pop	bx
		
		.leave
		ret
DrawCenteredString	endp


WelcomeCode	ends

endif

