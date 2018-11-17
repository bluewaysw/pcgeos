COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tslMethodCursor.asm

AUTHOR:		John Wedgwood, Apr 20, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 4/20/92	Initial revision

DESCRIPTION:
	Methods relating to the cursor.

	$Id: tslMethodCursor.asm,v 1.1 97/04/07 11:20:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextCursor	segment	resource

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextFlashCursorOn -- MSG_VIS_TEXT_FLASH_CURSOR_ON for
					VisTextClass

DESCRIPTION:	Flash the cursor on

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The method

RETURN:

DESTROYED:
	bx, si, di, ds, es (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/89		Initial version

------------------------------------------------------------------------------@
VisTextFlashCursorOn	proc	far	; MSG_VIS_TEXT_FLASH_CURSOR_ON
	class	VisTextClass
	
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	mov	ds:[di].VTI_timerHandle, 0

	mov	ax, ATTR_VIS_TEXT_CURSOR_NO_FOCUS
	call	ObjVarFindData
	jc	noCheck

	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_FOCUS
	jz	done

noCheck:	
	; If this thing isn't editable, then we don't want to do anything
	; including starting the timer again.  When and if it is made
	; editable again, the timer will be restarted.
	call	CheckNotEditable
	jc	done

	clr	bx
	call	GrGetExclusive
	tst	bx
	jnz	noDraw
	call	CursorForceOn
noDraw:
	mov	ax, ATTR_VIS_TEXT_CURSOR_NO_FOCUS
	call	ObjVarFindData
	jc	done

	mov	dx, MSG_VIS_TEXT_FLASH_CURSOR_OFF
	call	TextTimerStart
done:
	ret

VisTextFlashCursorOn	endp

;-------

VisTextFlashCursorOff	proc	far	; MSG_VIS_TEXT_FLASH_CURSOR_OFF
	class	VisTextClass

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	mov	al, ds:[di].VTI_intSelFlags

	mov	ds:[di].VTI_timerHandle, 0

	push	ax
	mov	ax, ATTR_VIS_TEXT_CURSOR_NO_FOCUS
	call	ObjVarFindData
	pop	ax
	jc	noCheck

	; if not still the focus then exit

	test	al, mask VTISF_IS_FOCUS
	jz	done

noCheck:
	; If this thing isn't editable, then we don't want to do anything
	; including starting the timer again.  When and if it is made
	; editable again, the timer will be restarted.
	call	CheckNotEditable
	jc	done

	; if not realized then we're off the screen and this method just
	; got left around so don't do anything

	call	TextCheckCanDraw
	jc	20$

	; if enabled then toggle the cursor

	test	al, mask VTISF_CURSOR_ENABLED
	jz	10$

	; if already off then don't toggle

	test	al, mask VTISF_CURSOR_ON
	jz	20$


	clr	bx			;Don't draw a cursor if someone has
	call	GrGetExclusive		; the exclusive (like, if someone is
	tst	bx			; drawing ink)
	jnz	20$

	push	ax
	call	CursorToggle
	pop	ax
10$:

;	call	Text_DerefVis_DI
	andnf	al, not mask VTISF_CURSOR_ON
	mov	ds:[di].VTI_intSelFlags, al

20$:
	;
	; If we don't have the focus, then don't flash the cursor
	;

	mov	ax, ATTR_VIS_TEXT_CURSOR_NO_FOCUS
	call	ObjVarFindData
	jc	done

	; start a timer to turn the cursor back on

	mov	dx, MSG_VIS_TEXT_FLASH_CURSOR_ON
	call	TextTimerStart
done:
	ret

VisTextFlashCursorOff	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	TextTimerStart

DESCRIPTION:	Start a timer to go to the text object

CALLED BY:	VisTextFlashCursorOn, VisTextFlashCursorOff

PASS:
	dx - method
	*ds:si - object
	*ds:di - text instance data

RETURN:

DESTROYED:
	ax, bx, cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

TextTimerStart	proc	near
	class	VisTextClass

	mov	ax, TIMER_EVENT_ONE_SHOT
	mov	bx, ds:[LMBH_handle]			;send event to us
	mov	cx, VIS_TEXT_CURSOR_FLASH
	call	TimerStart

	; save the handle

	mov	ds:[di].VTI_timerHandle, bx
	mov	ds:[di].VTI_timerID, ax

	ret
TextTimerStart	endp

TextCursor	ends
