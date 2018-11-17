COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bitmapKeyboard.asm

AUTHOR:		Jon Witort, 2 feb 1993

MSG_HANDLERS
	Name		
	----		
	VisBitmapKbdChar	MSG_META_KBD_CHAR
	VisBitmapFupKbdChar	MSG_META_FUP_KBD_CHAR

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2 feb 1993	Initial revision


DESCRIPTION:
	$Id: bitmapKeyboard.asm,v 1.1 97/04/04 17:43:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapEditCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Handle keypress.


PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of VisBitmapClass
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
VisBitmapKbdChar	method dynamic VisBitmapClass, MSG_META_KBD_CHAR
	.enter

	; Handle DELETE specially

	mov	ax,MSG_META_FUP_KBD_CHAR
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
	mov	ax, MSG_META_DELETE
notDelete:
	call	ObjCallInstanceNoLock

	Destroy 	ax,cx,dx,bp

	.leave
	ret
VisBitmapKbdChar		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapFupKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Handle keypress that wasn't used by the Bitmap or
		the object with the target
		


PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of VisBitmapClass
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
VisBitmapFupKbdChar	method dynamic VisBitmapClass, MSG_META_FUP_KBD_CHAR

	.enter

	test	dl,mask CF_FIRST_PRESS
	jnz	checkShortcut

callSuper:
	mov	ax, MSG_META_FUP_KBD_CHAR
	mov	di, segment VisBitmapClass
	mov	es, di
	mov	di, offset VisBitmapClass
	call	ObjCallSuperNoLock

done:
	Destroy	ax, cx, dx, bp

	.leave
	ret

checkShortcut:

	;
	;  If there's an action happening, ignore the keypress
	;

	mov	ax, (length BitmapKbdShortcuts)	;ax <- # shortcuts
	push	ds
	segmov	ds, cs
	mov	di, si
	mov	si, offset BitmapKbdShortcuts	;ds:si <- ptr to shortcut table
	call	FlowCheckKbdShortcut
	pop	ds
	xchg	di, si				;di <- offset of shortcut,
						;*ds:si <- VisBitmap
	jnc	callSuper

	call	cs:BitmapKbdActions[di]		;call handler routine
	stc
	jmp	done
VisBitmapFupKbdChar		endm


	;p  a  c  s  s    c
	;h  l  t  h  e    h
	;y  t  r  f  t    a
	;s     l  t       r
	;
if DBCS_PCGEOS
BitmapKbdShortcuts KeyboardShortcut \
	<1, 0, 0, 0, C_SYS_DOWN and mask KS_CHAR>,	;<down arrow>
	<1, 0, 0, 0, C_SYS_UP and mask KS_CHAR>,	;<up arrow>
	<1, 0, 0, 0, C_SYS_RIGHT and mask KS_CHAR>,	;<right arrow>
	<1, 0, 0, 0, C_SYS_LEFT and mask KS_CHAR>	;<left arrow>
else
BitmapKbdShortcuts KeyboardShortcut \
	<1, 0, 0, 0, 0xf, VC_DOWN>,		;<down arrow>
	<1, 0, 0, 0, 0xf, VC_UP>,		;<up arrow>
	<1, 0, 0, 0, 0xf, VC_RIGHT>,		;<right arrow>
	<1, 0, 0, 0, 0xf, VC_LEFT>		;<left arrow>
endif

BitmapKbdActions nptr \
	offset VisBitmapKbdDown,
	offset VisBitmapKbdUp,
	offset VisBitmapKbdRight,
	offset VisBitmapKbdLeft

CheckHack <length BitmapKbdShortcuts eq length BitmapKbdActions>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapKbdDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the Bitmap does when a Down is pressed

Pass:		*ds:si - VisBitmap

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapKbdDown	proc	near
	.enter

	.leave
	ret
VisBitmapKbdDown	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapKbdUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the Bitmap does when a Up is pressed

Pass:		*ds:si - VisBitmap

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapKbdUp	proc	near
	.enter

	.leave
	ret
VisBitmapKbdUp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapKbdRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the Bitmap does when a Right is pressed

Pass:		*ds:si - VisBitmap

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapKbdRight	proc	near
	.enter

	.leave
	ret
VisBitmapKbdRight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapKbdLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	This is what the Bitmap does when a Left is pressed

Pass:		*ds:si - VisBitmap

Return:		nothing

Destroyed:	allowed to destroy anything

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Dec 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapKbdLeft	proc	near
	.enter

	.leave
	ret
VisBitmapKbdLeft	endp

BitmapEditCode	ends
