COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		ukiKbd.asm

AUTHOR:		jimmy lefkowitz

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/14/91		Initial version.

DESCRIPTION:
	

	the keyboard support for uki has the following features:

	TAB: brings up the keyboard controller box (KCB) in the top
		left cell if the KCB is not already present,
		if the KCB is already present then in moves it to the
		next sqaure to the right, and wraps around both vertically
		and horizontally

	ESCAPE: kills the KCB

	LEFT_ARROW: moves the KCB to the left with wrap around
	
	RIGHT_ARROW: moves the KCB to the right with wrap around

	UP_ARROW: moves the KCB to up with wrap around

	DOWN_ARROW: moves the KCB to down with wrap around

	ENTER (RETURN): same effect as mouse click in that cell

	$Id: ukiKbd.asm,v 1.1 97/04/04 15:47:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	keyboard input

PASS:		bx = key pressed

RETURN:		Void.

DESTROYED:	bx, ds, si, di

PSEUDOCODE/STRATEGY:	calls the corresponding function depending on 
			what key was pressed, uses function table

KNOWN BUGS/SIDEFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/26/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiKbdChar	method	UkiContentClass, MSG_META_KBD_CHAR
	uses	ax, bp
	.enter

SBCS <	cmp	ch, CS_CONTROL			;shortcuts only		>
DBCS <	cmp	ch, CS_CONTROL_HB		;shortcuts only		>
	jne	doSuper

	mov	di, es:[viewWindow]
	call	GrCreateState
	push	ax, ds, si
	mov	ax, (size UkiKbdShortcuts)	;ax <- # shortcuts
	segmov	ds, cs
	mov	si, offset UkiKbdShortcuts	;ds:si <- ptr to shortcut table
	call	FlowCheckKbdShortcut
	mov	bx, si				;di <- offset of shortcut
	pop	ax, ds, si			;ds:si <- ptr to instance data
	jnc	doSuper				;branch if no match
	call	cs:UkiKbdActions[bx]		;call handler routine
	call	GrDestroyState
	jmp	done
doSuper:
	mov	di, offset UkiContentClass
	call	ObjCallSuperNoLock
done:
	.leave
	ret
UkiKbdChar	endm

	;p  a  c  s  s    c
	;h  l  t  h  e    h
	;y  t  r  f  t    a
	;s     l  t       r
	;

if DBCS_PCGEOS

UkiKbdShortcuts KeyboardShortcut \
	<0, 0, 0, 0, C_SYS_ESCAPE and mask KS_CHAR>,	;<Escape>
	<0, 0, 0, 0, C_SYS_ENTER and mask KS_CHAR>,	;<Enter>
	<0, 0, 0, 0, C_SYS_TAB and mask KS_CHAR>,	;<Tab>
	<1, 0, 0, 0, C_SYS_DOWN and mask KS_CHAR>,	;<down arrow>
	<1, 0, 0, 0, C_SYS_UP and mask KS_CHAR>,	;<up arrow>
	<1, 0, 0, 0, C_SYS_RIGHT and mask KS_CHAR>,	;<right arrow>
	<1, 0, 0, 0, C_SYS_LEFT and mask KS_CHAR>	;<left arrow>

else

UkiKbdShortcuts KeyboardShortcut \
	<0, 0, 0, 0, 0xf, VC_ESCAPE>,		;<Escape>
	<0, 0, 0, 0, 0xf, VC_ENTER>,		;<Enter>
	<0, 0, 0, 0, 0xf, VC_TAB>,		;<Tab>
	<1, 0, 0, 0, 0xf, VC_DOWN>,		;<down arrow>
	<1, 0, 0, 0, 0xf, VC_UP>,		;<up arrow>
	<1, 0, 0, 0, 0xf, VC_RIGHT>,		;<right arrow>
	<1, 0, 0, 0, 0xf, VC_LEFT>		;<left arrow>
endif

UkiKbdActions nptr \
	offset UkiKbdEscape,
	offset UkiKbdEnter,
	offset UkiKbdTab,
	offset UkiKbdDown,
	offset UkiKbdUp,
	offset UkiKbdRight,
	offset UkiKbdLeft



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiKbdEnter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	UkiKBdChar

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	erase the KCB, call off routine to see if
			that is a valid move and execute move and
			then redraw the KCB

KNOWN BUGS/SIDEFFECTS/IDEAS:
			erasing the KCB is neccessary so that the
			move can be executed without worrying about
			screwing up the KCB

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/14/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiKbdEnter	proc	near
	.enter
	mov	al, es:[kbdState].x_pos
	mov	bl, es:[kbdState].y_pos
	call	UkiDrawKbdPosition
	mov	cl, es:[kbdState].x_pos
	mov	dl, es:[kbdState].y_pos
	call	UkiCallKeyboardPressed
	mov	al, es:[kbdState].x_pos
	mov	bl, es:[kbdState].y_pos
	call	UkiDrawKbdPosition

	.leave
	ret
UkiKbdEnter	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiKbdEscape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	UkiKdbChar

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	kill KCB if on the screen

KNOWN BUGS/SIDEFFECTS/IDEAS:	

			wanted to leave as near call for jump table
			so made internal code into a far routine that
			can be called by outsiders

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/14/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiKbdEscape	proc	near
	call	UkiKbdEscapeCommon
	ret
UkiKbdEscape	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiKbdEscapeCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	global

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	get rid of KCB if it is on the screen

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/26/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiKbdEscapeCommon	proc	far
	uses	ax
	.enter
	mov	al, es:[kbdState].x_pos
	cmp	al, BAD_COORD
	jz	done
	call	UkiDrawKbdPosition
	mov	es:[kbdState].x_pos, BAD_COORD
done:
	.leave
	ret
UkiKbdEscapeCommon	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiKbdTab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	UkiKdbChar

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	advance the KCB to the next cell to the right
			with horizontal and vertical advance wrap around

KNOWN BUGS/SIDEFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/14/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiKbdTab	proc	near
	.enter
	tst	es:[computerTwoPlayer]
	jnz	absolutlydone
	cmp	es:[kbdState].x_pos, BAD_COORD
	jnz	testIfVisible
doInit:
	mov	es:[kbdState].x_pos, 0
	mov	es:[kbdState].y_pos, 0
	jmp	done
testIfVisible:
	tst	es:[kbdVisible]
	jz	done

	; increment position
	call	UkiDrawKbdPosition
	mov	al, es:[cells]
	dec	al
	cmp	al, es:[kbdState].x_pos
	jz	wrapToNextLine
	inc	es:[kbdState].x_pos
	jmp	done
wrapToNextLine:
	cmp	al, es:[kbdState].y_pos
	jz	doInit	
	inc	es:[kbdState].y_pos
	mov	es:[kbdState].x_pos, 0
done:
	mov	es:[kbdVisible], 1
	call	UkiDrawKbdPosition
absolutlydone:
	.leave
	ret
UkiKbdTab	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiDrawKbdPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	global

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	draw the KCB in the its current postion
			XOR used so this routine erases as well as draws

KNOWN BUGS/SIDEFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/14/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiDrawKbdPosition	proc	near
	uses	cx, dx
	.enter
	cmp	es:[kbdState].x_pos, BAD_COORD
	jz	done
	call	GrGetMixMode
	push	ax
	mov	al, MM_XOR
	call	GrSetMixMode
	mov	al, C_LIGHT_CYAN
	mov	ah, CF_INDEX
	call	GrSetAreaColor
	mov	al, es:[kbdState].x_pos
	mov	bl, es:[kbdState].y_pos
	call	UkiDrawGetCellCoords
	call	GrFillRect	
	pop	ax
	call	GrSetMixMode
;	tst	es:[kbdVisible]
;	jz	makeVisible
;	mov	es:[kbdVisible], 0
;	jmp	done
;makeVisible:
;	mov	es:[kbdVisible], 1
done:
	.leave
	ret
UkiDrawKbdPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiKbdRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	UkiKdbChar

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	adavance the KCB to the right with wrap around

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/14/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiKbdRight	proc	near
	.enter
	mov	al, es:[kbdState].x_pos
	cmp	al, BAD_COORD
	jz	doTab
	tst	es:[kbdVisible]
	jz	doTab
	call	UkiDrawKbdPosition
	mov	al, es:[kbdState].x_pos
	inc	al
	cmp	al, es:[cells]
	jz	wrapAround
	inc	es:[kbdState].x_pos
	jmp	drawPosition
wrapAround:
	mov	es:[kbdState].x_pos, 0
drawPosition:
	call	UkiDrawKbdPosition
done:
	.leave
	ret
doTab:
	call	UkiKbdTab
	jmp	done
UkiKbdRight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiKbdLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	UkiKdbChar

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	advance KCB to the left with wrap around

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/14/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiKbdLeft	proc	near
	.enter
	mov	al, es:[kbdState].x_pos
	cmp	al, BAD_COORD
	jz	doTab
	tst	es:[kbdVisible]
	jz	doTab
	call	UkiDrawKbdPosition
	tst	es:[kbdState].x_pos
	jz	wrapAround
	dec	es:[kbdState].x_pos
	jmp	drawPosition
wrapAround:
	mov	al, es:[cells]
	dec	al
	mov	es:[kbdState].x_pos, al
drawPosition:
	call	UkiDrawKbdPosition
done:
	.leave
	ret
doTab:
	call	UkiKbdTab
	jmp	done
UkiKbdLeft	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiKbdDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	UkiKbdChar

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	advance  KCB down with wrap around

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/14/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiKbdDown	proc	near
	.enter
	mov	al, es:[kbdState].x_pos
	cmp	al, BAD_COORD
	jz	doTab
	tst	es:[kbdVisible]
	jz	doTab
	call	UkiDrawKbdPosition
	mov	al, es:[kbdState].y_pos
	inc	al
	cmp	al, es:[cells]
	jz	wrapAround
	inc	es:[kbdState].y_pos
	jmp	drawPosition
wrapAround:
	mov	es:[kbdState].y_pos, 0
drawPosition:
	call	UkiDrawKbdPosition
done:
	.leave
	ret
doTab:
	call	UkiKbdTab
	jmp	done
UkiKbdDown	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiKbdUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	UkiKbdChar

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	advance KCB up with wrap around

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/14/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiKbdUp	proc	near
	.enter
	mov	al, es:[kbdState].x_pos
	cmp	al, BAD_COORD
	jz	doTab
	tst	es:[kbdVisible]
	jz	doTab
	call	UkiDrawKbdPosition
	tst	es:[kbdState].y_pos
	jz	wrapAround
	dec	es:[kbdState].y_pos
	jmp	drawPosition
wrapAround:
	mov	al, es:[cells]
	dec	al
	mov	es:[kbdState].y_pos, al
drawPosition:
	call	UkiDrawKbdPosition
done:
	.leave
	ret
doTab:
	call	UkiKbdTab
	jmp	done
UkiKbdUp	endp


