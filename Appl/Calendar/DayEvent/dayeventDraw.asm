COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/DayEvent
FILE:		dayeventDraw.asm

AUTHOR:		Don Reeves, April 4, 1991

ROUTINES:
	Name			Description
	----			-----------
	DayEventDraw		Draws a DayEvent object & children
	DayEventDrawIcon	Draw the proper icon (bell or repeat)
	DayEventDrawSelect	Draw the selection box, if appropriate

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	04/05/89	Initial revision (from dayevent.asm)
	
DESCRIPTION:
	Defines the "DayEvent" drawing procedures
		
	$Id: dayeventDraw.asm,v 1.1 97/04/04 14:47:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


include		system.def



DayEventCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the time string, and call to draw children

CALLED BY:	UI (MSG_VIS_DRAW)

PASS:		ES	= Dgroup
		DS:*SI	= DayEventClass instance data
		DS:DI	= DayEventClass specific instance data
		BP	= GState
		CL	= DrawFlags

RETURN:		Nothing

DESTROYED:	AX, BX, DX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/89		Initial version
	Don	7/24/89		Brought to new UI

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventDraw	method	DayEventClass, MSG_VIS_DRAW

	; First set up the GState
	;
	push	cx, di				; save DrawFlags
	mov	di, bp				; GState to DI
	mov	ax, CF_INDEX shl 8 or TEXT_COLOR
	call	GrSetLineColor
	call	GrSetTextColor			; set the foreground colors
	movdw	bxax, es:[eventBGColor]
	call	GrSetAreaColor			; set the background color
	pop	cx, di				; restore the DrawFlags
	test	cl, mask DF_PRINT		; are we printing ??
	jnz	complete			; if so, we're done

	; Wash the window (background color)
	;
	push	cx, di				; save DrawFlags, instance data
	clr	cl
	call	VisGetBounds			; get my bounds
	mov	di, bp				; GState to DI
	call	GrFillRect			; draw the rectangle
	pop	cx, di				; restore saved data

	; Now draw the bitmap
	;
	test	ds:[di].DEI_stateFlags, mask EIF_HEADER
	jnz	outline				; if a header, no bitmap
	call	DayEventDrawIcon		; draw the lousy icon

	; Draw the outline ??
	;
outline:
	test	ds:[di].DEI_actFlags, DE_SELECT	; select bit set
	jz	complete
	mov	ax, MSG_DE_DRAW_SELECT
	call	ObjCallInstanceNoLock

	; Call my superclass to continue the draw
	;
complete:
	mov	ax, MSG_VIS_DRAW		; send draw to my SuperClass
	mov	di, offset DayEventClass	; ES:DI is my class
	call	ObjCallSuperNoLock		; call my superclass
	ret
DayEventDraw	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventDrawIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the appropriate icon (bell or repeat)

CALLED BY:	DayEventDraw

PASS:		*DS:SI	= DayEvent object
		DS:DI	= DayEvent instance data
		ES	= DGroup
		BP	= GState

RETURN:		Nothing

DESTROYED:	AX, BX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/20/89	Initial version
	Don	6/20/90		Changed to a near routine
	sean	4/6/95		To Do list changes
	sean	8/10/95		Responder changes
	sean	10/3/95		Cleaned up/EC code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventDrawIcon	proc	near
	uses	cx, di, si, ds
	.enter

	; Some set up work
	;
	test	es:[features], mask CF_ALARMS
	jz	done				; if no alarms, don't draw bell
	mov	di, bp				; GState to DI
	mov	ah, CF_INDEX			; set the color index
	mov	al, C_BLACK
	call	GrSetAreaColor	
	clr	cl				; no flags for VisGetBounds
	call	VisGetBounds			; upper bound in BX
	push	bx				; save top
	push	ax				; save left
	mov	bx, handle DataBlock
	call	MemLock				; lock the block

	; Determine the bell to be drawn (bitmap handle to SI)
	;
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayEvent_offset	; access my instance data
	mov	si, offset DataBlock:RepeatIconMoniker
	test	ds:[di].DEI_stateFlags, mask EIF_REPEAT
	jne	drawIcon
	mov	si, offset DataBlock:AlarmIconOnMoniker
	test	ds:[di].DEI_stateFlags, mask EIF_ALARM_ON
	jnz	drawIcon			; if alarm on, draw ON bell
	mov	si, offset DataBlock:AlarmIconOffMoniker

	; Draw the appropriate icon (bitmap handle in SI)
	;
drawIcon:
	mov	ds, ax				; set the DataBlock segment
	mov	si, ds:[si]			; dereference BM handle
	pop	ax				; left bound of DayEvent
	add	ax, EVENT_LR_MARGIN		; add in the left/right margin
	pop	bx				; upper bound of DayEvent
	add	bx, es:[yIconOffset]
	clr	cx
	clr	dx				; no call back routine
	mov	di, bp				; GState to DI
	call	GrDrawBitmap			; draw it

	; Clean up
	;
cleanUp::
	mov	bx, handle DataBlock
	call	MemUnlock
done:
	.leave
	ret
DayEventDrawIcon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventDrawNoStartTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a hyphen if there is no start time for the current
		event

CALLED BY:	DayEventDraw
PASS:		ds:di	= DayEventInstance
		*ds:si	= DayEvent object
		es	= dgroup
		bp	= GState handle
RETURN:		nothing
DESTROYED:	ds

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	2/ 4/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventDrawSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the select box

CALLED BY:	INTERNAL (MSG_DE_DRAW_SELECT)

PASS:		DS:*SI	= DayEvent instance data
		BP	= GState
		CL	= DrawFlags

RETURN:		Nothing

DESTROYED:	AX, BX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/4/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventDrawSelect	method	DayEventClass,	MSG_DE_DRAW_SELECT
	uses	cx, dx
	.enter

	; First draw the bounding box
	;
	test	cl, mask DF_PRINT		; are we printing ??
	jnz	exit				; if so, do nothing

	clr	cl				; want true bounds
	call	VisGetBounds			; fill AX, BX, CX, DX
	inc	ax				; left bounds++ 
	dec	cx				; right bounds--
	dec	cx				; right bounds-2
	dec	dx				; bottom bounds--
	mov	di, bp				; GState to DI
	call	GrDrawRect			; draw the rectangle

	; Now draw the divider, unless we are a header event
	;
	mov	bp, ds:[si]			; dereference the handle
	add	bp, ds:[bp].DayEvent_offset	; access my instance data
	test	ds:[bp].DEI_stateFlags, mask EIF_HEADER
	jnz	done				; if a header, don't draw this
	mov	bp, ds:[bp].DEI_textHandle	; text object => DS:*BX
	mov	bp, ds:[bp]			; dereference the handle
	add	bp, ds:[bp].Vis_offset		; access my visual data
	mov	cx, ds:[bp].VI_bounds.R_left	; right side => CX
;;;	mov	al, SDM_50			; fifty-percent draw pattern
;;;	call	GrSetLineMask			; set the mask, dude!
	mov	ax, cx			
	dec	ax				; left side => AX
	inc	bx				; move top down by 1
	dec	dx				; move bottom up by one
	call	GrDrawRect			; draw a line
;;;	mov	al, SDM_100			; reset the mask
;;;	call	GrSetLineMask
done:
	mov	bp, di				; GState => BP
exit:
	.leave
	ret
DayEventDrawSelect	endp

DayEventCode	ends



