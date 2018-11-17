COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bodyKeyboard.asm

AUTHOR:		Steve Scholl, Nov 15, 1989

ROUTINES:
	Name			Description
	----			-----------
	GrObjBodySetKeyboardModifiers

MSG_HANDLERS
	Name		
	----		
	GrObjBodyKbdChar	MSG_META_KBD_CHAR
	GrObjBodyFupKbdChar	MSG_META_FUP_KBD_CHAR

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/89		Initial revision


DESCRIPTION:
	This file contains routines to implement the GrObjBody class.
		

	$Id: bodyKeyboard.asm,v 1.1 97/04/04 18:07:58 newdeal Exp $
	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjRequiredInteractiveCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Handle keypress.


PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass
		cx - character value
		dl - CharFlags
		dh - ShiftState
		bp low - ToggleState
		bp high - scan code

RETURN:		
		nothing
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdChar	method dynamic GrObjBodyClass, MSG_META_KBD_CHAR
	.enter

	clr	di					;MessageFlags
	call	GrObjBodyMessageToFocus
	jnz	done

	; Handle DELETE specially

	test	dl, mask CF_RELEASE
	jnz	notDelete
	test	dl, mask CF_FIRST_PRESS
	jz	notDelete
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_DEL			>
DBCS <	cmp	cx, C_SYS_DELETE					>
	je	doDelete
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_BACKSPACE			>
DBCS <	cmp	cx, C_SYS_BACKSPACE					>
	jne	notDelete

doDelete:
	;
	;  If there's an action happening, ignore the delete
	;
	mov	ax, MSG_GO_CHECK_ACTION_MODES
	call	GrObjBodySendToSelectedGrObjsTestAbort
	jc	done

	mov	ax, MSG_META_DELETE
	jmp	toSelfCommon
notDelete:

	;    If there is no edit grab the fup the char to ourselves 
	;    for handling.
	;

	mov	ax,MSG_META_FUP_KBD_CHAR

toSelfCommon:
	call	ObjCallInstanceNoLock

done:
	Destroy 	ax,cx,dx,bp

	.leave
	ret

GrObjBodyKbdChar		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyFupKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Handle keypress that wasn't used by the body or
		the object with the target
		


PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass
]		cx - character value
		dl - CharFlags
		dh - ShiftState
		bp low - ToggleState
		bp high - scan code

RETURN:		
		nothing
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyFupKbdChar	method dynamic GrObjBodyClass, MSG_META_FUP_KBD_CHAR
	.enter

	call	GrObjBodySetKeyboardModifiers
	pushf					;save carry
	call	GrObjBodySetOptions

	popf
	jc	done				;done if handled above

	test	dl, mask CF_RELEASE
	jnz	sendUp

	;
	; For Redwood, we allow repeat presses for the arrow keys.
	;
SBCS <	tst	ch							>
SBCS <	jz	notArrow						>
SBCS <	cmp	cl, VC_UP						>
DBCS <	cmp	cx, C_SYS_UP						>
	jb	notArrow
SBCS <	cmp	cl, VC_LEFT						>
DBCS <	cmp	cx, C_SYS_LEFT						>
	jbe	checkShortcut
notArrow:


	test	dl,mask CF_FIRST_PRESS
	jnz	checkShortcut

sendUp:
;	We need to fup the keypress up, because we let all keypress through
;	to the GeoFile text objects, so if you hit something like ALT-F (to
;	bring up the file menu) it won't activate the file menu if the body
;	eats the FUP.

	mov	ax, MSG_META_FUP_KBD_CHAR
	mov	di, offset GrObjBodyClass
	GOTO	ObjCallSuperNoLock

done:
	.leave
	ret

checkShortcut:

	;
	;  If there's an action happening, ignore the keypress
	;
	mov	ax, MSG_GO_CHECK_ACTION_MODES
	call	GrObjBodySendToSelectedGrObjsTestAbort
	jc	sendUp

	mov	ax, (length bodyKbdShortcuts)	;ax <- # shortcuts
	push	ds
	segmov	ds, cs
	mov	di, si
	mov	si, offset bodyKbdShortcuts	;ds:si <- ptr to shortcut table
	call	FlowCheckKbdShortcut
	pop	ds
	xchg	di, si				;di <- offset of shortcut,
						;*ds:si <- GrObjBody
	jnc	sendUp

	call	cs:bodyKbdActions[di]		;call handler routine
	stc
	jmp	done
GrObjBodyFupKbdChar		endm


	;p  a  c  s  s    c
	;h  l  t  h  e    h
	;y  t  r  f  t    a
	;s     l  t       r
	;
if DBCS_PCGEOS
bodyKbdShortcuts KeyboardShortcut \
	<1, 0, 0, 0, C_DIGIT_ZERO>,
	<1, 0, 0, 0, C_HYPHEN_MINUS>,
	<1, 0, 0, 0, C_EQUALS_SIGN>,
	<1, 0, 0, 0, C_LATIN_SMALL_LETTER_B>,
	<1, 0, 0, 0, C_LATIN_CAPITAL_LETTER_B>,
	<1, 0, 0, 0, C_LATIN_SMALL_LETTER_P>,
	<1, 0, 0, 0, C_LATIN_SMALL_LETTER_D>,
	<1, 0, 0, 0, C_LATIN_SMALL_LETTER_F>,
	<1, 0, 0, 0, C_LATIN_CAPITAL_LETTER_F>,
	<1, 0, 0, 0, C_LATIN_SMALL_LETTER_G>,
	<1, 0, 0, 0, C_LATIN_SMALL_LETTER_H>,
	<1, 0, 0, 0, C_LATIN_SMALL_LETTER_L>,
	<1, 0, 0, 0, C_LATIN_SMALL_LETTER_T>,
	<1, 0, 0, 0, C_LATIN_SMALL_LETTER_U>,
	<1, 0, 0, 0, C_LATIN_SMALL_LETTER_V>,
	<1, 0, 0, 0, C_OPENING_SQUARE_BRACKET>,
	<1, 0, 0, 0, C_CLOSING_SQUARE_BRACKET>,
	<1, 0, 0, 1, C_OPENING_SQUARE_BRACKET>,
	<1, 0, 0, 1, C_CLOSING_SQUARE_BRACKET>,
	<1, 0, 0, 0, C_SYS_DOWN and mask KS_CHAR>,	;<down arrow>
	<1, 0, 0, 0, C_SYS_UP and mask KS_CHAR>,	;<up arrow>
	<1, 0, 0, 0, C_SYS_RIGHT and mask KS_CHAR>,	;<right arrow>
	<1, 0, 0, 0, C_SYS_LEFT and mask KS_CHAR>,	;<left arrow>
	<1, 0, 0, 1, C_SYS_DOWN and mask KS_CHAR>,	;<Shift><down arrow>
	<1, 0, 0, 1, C_SYS_UP and mask KS_CHAR>,	;<Shift><up arrow>
	<1, 0, 0, 1, C_SYS_RIGHT and mask KS_CHAR>,	;<Shift><right arrow>
	<1, 0, 0, 1, C_SYS_LEFT and mask KS_CHAR>,	;<Shift><left arrow>
	<1, 0, 1, 0, C_SYS_DOWN and mask KS_CHAR>,	;<Ctrl><down arrow>
	<1, 0, 1, 0, C_SYS_UP and mask KS_CHAR>,	;<Ctrl><up arrow>
	<1, 0, 1, 0, C_SYS_RIGHT and mask KS_CHAR>,	;<Ctrl><right arrow>
	<1, 0, 1, 0, C_SYS_LEFT and mask KS_CHAR>	;<Ctrl><left arrow>
else
bodyKbdShortcuts KeyboardShortcut \
	<1, 0, 0, 0, 0x0, C_ZERO>,
	<1, 0, 0, 0, 0x0, C_MINUS>,
	<1, 0, 0, 0, 0x0, C_EQUAL>,
	<1, 0, 0, 0, 0x0, C_SMALL_B>,
	<1, 0, 0, 0, 0x0, C_CAP_B>,
	<1, 0, 0, 0, 0x0, C_SMALL_P>,
	<1, 0, 0, 0, 0x0, C_SMALL_D>,
	<1, 0, 0, 0, 0x0, C_SMALL_F>,
	<1, 0, 0, 0, 0x0, C_CAP_F>,
	<1, 0, 0, 0, 0x0, C_SMALL_G>,
	<1, 0, 0, 0, 0x0, C_SMALL_H>,
	<1, 0, 0, 0, 0x0, C_SMALL_L>,
	<1, 0, 0, 0, 0x0, C_SMALL_T>,
	<1, 0, 0, 0, 0x0, C_SMALL_U>,
	<1, 0, 0, 0, 0x0, C_SMALL_V>,
	<1, 0, 0, 0, 0x0, C_LEFT_BRACKET>,
	<1, 0, 0, 0, 0x0, C_RIGHT_BRACKET>,
	<1, 0, 0, 1, 0x0, C_LEFT_BRACKET>,
	<1, 0, 0, 1, 0x0, C_RIGHT_BRACKET>,
	<1, 0, 0, 0, 0xf, VC_DOWN>,		;<down arrow>
	<1, 0, 0, 0, 0xf, VC_UP>,		;<up arrow>
	<1, 0, 0, 0, 0xf, VC_RIGHT>,		;<right arrow>
	<1, 0, 0, 0, 0xf, VC_LEFT>,		;<left arrow>
	<1, 0, 0, 1, 0xf, VC_DOWN>,		;<Shift><down arrow>
	<1, 0, 0, 1, 0xf, VC_UP>,		;<Shift><up arrow>
	<1, 0, 0, 1, 0xf, VC_RIGHT>,		;<Shift><right arrow>
	<1, 0, 0, 1, 0xf, VC_LEFT>,		;<Shift><left arrow>
	<1, 0, 1, 0, 0xf, VC_DOWN>,		;<Ctrl><down arrow>
	<1, 0, 1, 0, 0xf, VC_UP>,		;<Ctrl><up arrow>
	<1, 0, 1, 0, 0xf, VC_RIGHT>,		;<Ctrl><right arrow>
	<1, 0, 1, 0, 0xf, VC_LEFT>		;<Ctrl><left arrow>
endif

bodyKbdActions nptr \
	offset GrObjBodyKbdZero,
	offset GrObjBodyKbdMinus,
	offset GrObjBodyKbdEqual,
	offset GrObjBodyKbdSmallB,
	offset GrObjBodyKbdCapB,
	offset GrObjBodyKbdSmallP,
	offset GrObjBodyKbdSmallD,
	offset GrObjBodyKbdSmallF,
	offset GrObjBodyKbdCapF,
	offset GrObjBodyKbdSmallG,
	offset GrObjBodyKbdSmallH,
	offset GrObjBodyKbdSmallL,
	offset GrObjBodyKbdSmallT,
	offset GrObjBodyKbdSmallU,
	offset GrObjBodyKbdSmallV,
	offset GrObjBodyKbdLeftBracket,
	offset GrObjBodyKbdRightBracket,
	offset GrObjBodyKbdShiftLeftBracket,
	offset GrObjBodyKbdShiftRightBracket,
	offset GrObjBodyKbdDown,
	offset GrObjBodyKbdUp,
	offset GrObjBodyKbdRight,
	offset GrObjBodyKbdLeft,
	offset GrObjBodyKbdShiftDown,
	offset GrObjBodyKbdShiftUp,
	offset GrObjBodyKbdShiftRight,
	offset GrObjBodyKbdShiftLeft,
	offset GrObjBodyKbdCtrlDown,
	offset GrObjBodyKbdCtrlUp,
	offset GrObjBodyKbdCtrlRight,
	offset GrObjBodyKbdCtrlLeft

CheckHack <length bodyKbdShortcuts eq length bodyKbdActions>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdZero
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a Zero is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdZero	proc	near
	.enter

	mov	ax,MSG_GB_SET_NORMAL_SIZE_ABOUT_POINT
	call	GrObjBodyKbdZoomCommon	

	.leave
	ret
GrObjBodyKbdZero	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdMinus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a Minus is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdMinus	proc	near
	.enter

	mov	ax,MSG_GB_ZOOM_OUT_ABOUT_POINT
	call	GrObjBodyKbdZoomCommon

	.leave
	ret
GrObjBodyKbdMinus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdEqual
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a Equal is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdEqual	proc	near
	.enter

	mov	ax,MSG_GB_ZOOM_IN_ABOUT_POINT
	call	GrObjBodyKbdZoomCommon	

	.leave
	ret
GrObjBodyKbdEqual	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdZoomCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Common routine for kbd shortcut zoom stuff

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	everything

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdZoomCommon	proc	near
	class	GrObjBodyClass
	.enter

	;
	;  Make way for our lastPtr on the stack
	;
	sub	sp,size PointDWFixed
	mov	bp,sp

	push	si
	mov	si,ds:[si]
	add	si,ds:[si].GrObjBody_offset
	add	si,offset GBI_lastPtr
	segmov	es,ss
	mov	di,bp
	MoveConstantNumBytes	<size PointDWFixed>,cx
	pop	si

	;
	;  Send the relevant zoom message to ourselves
	;
	call	ObjCallInstanceNoLock
	add	sp,size PointDWFixed

	.leave
	ret
GrObjBodyKbdZoomCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdSmallB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a B is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdSmallB	proc	near
	.enter

	mov	ax, MSG_GB_PUSH_SELECTED_GROBJS_TO_BACK
	call	ObjCallInstanceNoLock	

	.leave
	ret
GrObjBodyKbdSmallB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdCapB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a B is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdCapB	proc	near
	.enter

	mov	ax, MSG_GB_SHUFFLE_SELECTED_GROBJS_DOWN
	call	ObjCallInstanceNoLock	

	.leave
	ret
GrObjBodyKbdCapB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdSmallP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a P is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdSmallP	proc	near
	.enter

	mov	ax, MSG_GB_CLONE_SELECTED_GROBJS
	call	ObjCallInstanceNoLock	

	.leave
	ret
GrObjBodyKbdSmallP	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdSmallD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a D is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdSmallD	proc	near
	.enter

	mov	ax, MSG_GB_DUPLICATE_SELECTED_GROBJS
	call	ObjCallInstanceNoLock	

	.leave
	ret
GrObjBodyKbdSmallD	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdSmallF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a F is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdSmallF	proc	near
	.enter

	mov	ax, MSG_GB_PULL_SELECTED_GROBJS_TO_FRONT
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjBodyKbdSmallF	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdCapF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a F is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdCapF	proc	near
	.enter

	mov	ax, MSG_GB_SHUFFLE_SELECTED_GROBJS_UP
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjBodyKbdCapF	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdSmallG
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a G is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdSmallG	proc	near
	.enter

	;
	; If < 2 selected children, then don't bother.
	;
	call	GrObjBodyGetNumSelectedGrObjs
	cmp	bp, 1
	jle	done
	
	mov	ax, MSG_GB_GROUP_SELECTED_GROBJS
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
GrObjBodyKbdSmallG	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdSmallH
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a G is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdSmallH	proc	near
	.enter

	mov	cl, mask AT_ALIGN_X or (CLRW_CENTER shl offset AT_CLRW)
	mov	ax, MSG_GB_ALIGN_SELECTED_GROBJS
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjBodyKbdSmallH	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdSmallL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a L is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdSmallL	proc	near
	.enter

	mov	ax, MSG_GO_FLIP_HORIZ
	call	GrObjBodySendToSelectedGrObjs

	.leave
	ret
GrObjBodyKbdSmallL	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdSmallT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a T is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdSmallT	proc	near
	.enter

	mov	ax, MSG_GO_FLIP_VERT
	call	GrObjBodySendToSelectedGrObjs

	.leave
	ret
GrObjBodyKbdSmallT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdSmallU
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a U is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdSmallU	proc	near
	.enter

	mov	ax, MSG_GB_UNGROUP_SELECTED_GROUPS
	call	ObjCallInstanceNoLock
	
	.leave
	ret
GrObjBodyKbdSmallU	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdSmallV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a G is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdSmallV	proc	near
	.enter

	mov	cl, mask AT_ALIGN_Y or (CTBH_CENTER shl offset AT_CTBH)
	mov	ax, MSG_GB_ALIGN_SELECTED_GROBJS
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjBodyKbdSmallV	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdLeftBracket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a LeftBracket is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdLeftBracket	proc	near
	.enter

	mov	cx, 15
	clr	dx, bp
	mov	ax, MSG_GO_ROTATE
	call	GrObjBodySendToSelectedGrObjs

	.leave
	ret
GrObjBodyKbdLeftBracket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdRightBracket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a RightBracket is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdRightBracket	proc	near
	.enter

	mov	cx, -15
	clr	dx, bp
	mov	ax, MSG_GO_ROTATE
	call	GrObjBodySendToSelectedGrObjs

	.leave
	ret
GrObjBodyKbdRightBracket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdShiftLeftBracket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a LeftBracket is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdShiftLeftBracket	proc	near
	.enter

	mov	cx, 1
	clr	dx, bp
	mov	ax, MSG_GO_ROTATE
	call	GrObjBodySendToSelectedGrObjs

	.leave
	ret
GrObjBodyKbdShiftLeftBracket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdShiftRightBracket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a RightBracket is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdShiftRightBracket	proc	near
	.enter

	mov	cx, -1
	clr	dx, bp
	mov	ax, MSG_GO_ROTATE
	call	GrObjBodySendToSelectedGrObjs

	.leave
	ret
GrObjBodyKbdShiftRightBracket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a Down is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdDown	proc	near
	.enter

	clr	cx
	mov	dx, 10
	mov	ax, MSG_GO_NUDGE
	call	GrObjBodySendToSelectedGrObjs

	.leave
	ret
GrObjBodyKbdDown	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a Up is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdUp	proc	near
	.enter

	clr	cx
	mov	dx, -10
	mov	ax, MSG_GO_NUDGE
	call	GrObjBodySendToSelectedGrObjs

	.leave
	ret
GrObjBodyKbdUp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a Right is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdRight	proc	near
	.enter

	mov	cx, 10
	clr	dx
	mov	ax, MSG_GO_NUDGE
	call	GrObjBodySendToSelectedGrObjs

	.leave
	ret
GrObjBodyKbdRight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a Left is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdLeft	proc	near
	.enter

	mov	cx, -10
	clr	dx
	mov	ax, MSG_GO_NUDGE
	call	GrObjBodySendToSelectedGrObjs

	.leave
	ret
GrObjBodyKbdLeft	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdShiftDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a Down is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdShiftDown	proc	near
	.enter

	clr	cx
	mov	dx, 1
	mov	ax, MSG_GO_NUDGE
	call	GrObjBodySendToSelectedGrObjs

	.leave
	ret
GrObjBodyKbdShiftDown	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdShiftUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a Up is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdShiftUp	proc	near
	.enter

	clr	cx
	mov	dx, -1
	mov	ax, MSG_GO_NUDGE
	call	GrObjBodySendToSelectedGrObjs

	.leave
	ret
GrObjBodyKbdShiftUp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdShiftRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a Right is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdShiftRight	proc	near
	.enter

	mov	cx, 1
	clr	dx
	mov	ax, MSG_GO_NUDGE
	call	GrObjBodySendToSelectedGrObjs

	.leave
	ret
GrObjBodyKbdShiftRight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdShiftLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a Left is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdShiftLeft	proc	near
	.enter

	mov	cx, -1
	clr	dx
	mov	ax, MSG_GO_NUDGE
	call	GrObjBodySendToSelectedGrObjs

	.leave
	ret
GrObjBodyKbdShiftLeft	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdCtrlDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a CtrlDown is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdCtrlDown	proc	near
	.enter

	mov	cl, mask AT_ALIGN_Y or (CTBH_BOTTOM shl offset AT_CTBH)
	mov	ax, MSG_GB_ALIGN_SELECTED_GROBJS
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjBodyKbdCtrlDown	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdCtrlUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a CtrlUp is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdCtrlUp	proc	near
	.enter

	mov	cl, mask AT_ALIGN_Y or (CTBH_TOP shl offset AT_CTBH)
	mov	ax, MSG_GB_ALIGN_SELECTED_GROBJS
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjBodyKbdCtrlUp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdCtrlRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a CtrlRight is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdCtrlRight	proc	near
	.enter

	mov	cl, mask AT_ALIGN_X or (CLRW_RIGHT shl offset AT_CLRW)
	mov	ax, MSG_GB_ALIGN_SELECTED_GROBJS
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjBodyKbdCtrlRight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyKbdCtrlLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the body does when a CtrlLeft is pressed

Pass:		*ds:si - GrObjBody

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyKbdCtrlLeft	proc	near
	.enter

	mov	cl, mask AT_ALIGN_X or (CLRW_LEFT shl offset AT_CLRW)
	mov	ax, MSG_GB_ALIGN_SELECTED_GROBJS
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjBodyKbdCtrlLeft	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySetKeyboardModifiers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store current modifiers that the grobj is interested in

CALLED BY:	INTERNAL
		GrObjBodyKbdChar

PASS:		
		*ds:si - GrObjBody
		dl - CharFlags
		cx - character value

RETURN:		
		carry set if handled

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/ 1/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySetKeyboardModifiers		proc	near
	class	GrObjBodyClass
	uses	ax,di,es
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	test	dl, mask CF_FIRST_PRESS
	jz	done

	;
	;  Scan for any acceptable "from center" key
	;
	mov_tr	ax, cx					;ax <- char value
	segmov	es, cs
	mov	di, offset fromCenterTable
	mov	cx, length fromCenterTable
	repne	scasw
	mov	cx, mask GOFA_FROM_CENTER or mask GOFA_ABOUT_OPPOSITE
	jz	toggleBits				;toggle bits if found

	;
	;  Scan for any acceptable "snap to" key
	;
CheckHack<(offset fromCenterTable + size fromCenterTable) eq offset snapToTable>
	mov	cx, length snapToTable
	repne	scasw
	mov	cx, mask GOFA_SNAP_TO
	jz	toggleBits				;toggle bits if found

	clc						;not found
restoreCX:
	mov_tr	cx, ax

done:
	.leave
	ret

toggleBits:
	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	xor	ds:[di].GBI_currentModifiers, cx
	stc
	jmp	restoreCX
GrObjBodySetKeyboardModifiers		endp

if DBCS_PCGEOS

fromCenterTable	word	\
	C_LATIN_SMALL_LETTER_C,
	C_LATIN_CAPITAL_LETTER_C,
	C_COMMA,
	C_LESS_THAN_SIGN

snapToTable	word	\
	C_LATIN_SMALL_LETTER_X,
	C_LATIN_CAPITAL_LETTER_X,
	C_PERIOD,
	C_GREATER_THAN_SIGN

else

fromCenterTable	word	\
	C_SMALL_C or CS_BSW shl 8,
	C_CAP_C or CS_BSW shl 8,
	C_COMMA or CS_BSW shl 8,
	C_LESS_THAN or CS_BSW shl 8

snapToTable	word	\
	C_SMALL_X or CS_BSW shl 8,
	C_CAP_X or CS_BSW shl 8,
	C_PERIOD or CS_BSW shl 8,
	C_GREATER_THAN or CS_BSW shl 8
endif

GrObjRequiredInteractiveCode	ends
