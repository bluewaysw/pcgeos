COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1996 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		Calendar\Main
FILE:		mainEventsContent.asm

AUTHOR:		Jason Ho, Dec 11, 1996

METHODS:
	Name				Description
	----				-----------
	MSG_VIS_DRAW		Draw the event list in window next to
				confirm dialog.
	MSG_CALENDAR_EVENTS_LIST_CONTENT_SET_GSTRING
				Set the gstring associated with the
				content, and resize myself according
				to bound of gstate.
	MSG_VIS_CLOSE		When closing, destroy the gstate
				associated with this content.

ROUTINES:
	Name				Description
	----				-----------

	
REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho		12/11/96   	Initial revision


DESCRIPTION:
	Code for CalendarEventsListContentClass. This is a content that shows
	(statically) the events of the day, when appointment confirm
	dialog comes up.
		

	$Id: mainEventsContent.asm,v 1.1 97/04/04 14:48:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	HANDLE_MAILBOX_MSG

	;
	; There must be an instance of every class in a resource.
	;
idata		segment
	CalendarEventsListContentClass
idata		ends

MailboxCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarEventsListContentVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the event list in window next to confirm dialog.

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= CalendarEventsListContentClass object
		ds:di	= CalendarEventsListContentClass instance data
		ds:bx	= CalendarEventsListContentClass object
			(same as *ds:si)
		es 	= segment of CalendarEventsListContentClass
		ax	= message #
		cl	= DrawFlags:  DF_EXPOSED set if GState is set
			  to update window
		^hbp	= gstate to draw through.
RETURN:		nothing
		GState	= The graphics state must be returned
			  unchanged except for pen position, colors --
			  can be destroyed.
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/11/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarEventsListContentVisDraw	method dynamic \
					CalendarEventsListContentClass, 
					MSG_VIS_DRAW
		.enter
		Assert	gstate, bp
	;
	; GString to be drawn.
	;
		mov	si, ds:[di].CELCI_gsHandle
	;
	; Move gstate to something useful
	;
		mov	di, bp				; di = GState
		clr	ax, bx, dx			; coordinates to
							;  draw, flags
		call	GrDrawGString

		.leave
		ret
CalendarEventsListContentVisDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarEventsListContentSetGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the gstring associated with the content, and
		resize myself according to bound of gstate.

CALLED BY:	MSG_CALENDAR_EVENTS_LIST_CONTENT_SET_GSTRING
PASS:		*ds:si	= CalendarEventsListContentClass object
		ds:di	= CalendarEventsListContentClass instance data
		ds:bx	= CalendarEventsListContentClass object
			  (same as *ds:si)
		es 	= segment of CalendarEventsListContentClass
		ax	= message #
		cx	= handle of gstring block
		dx	= gstring chunk handle
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Store the gstate handle to instance data.
		Figure out the bounds to gstring, and set the bounds
		of self.

		If the bound overflows, the default bound of the
		content is 600 (CONFIRM_EVENT_LIST_HEIGHT), and that's
		all the user can scroll.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/13/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarEventsListContentSetGString	method dynamic \
				CalendarEventsListContentClass, 
				MSG_CALENDAR_EVENTS_LIST_CONTENT_SET_GSTRING
		uses	cx, dx
		.enter
	;
	; Set instance data.
	;
		Assert	handle, cx
		Assert	gstate, dx
		mov	ds:[di].CELCI_gsBlock, cx
		mov	ds:[di].CELCI_gsHandle, dx
	;
	; Find the bound of gstring. GrGetGStringBounds documentation
	; seems to be wrong, and it wants gstate handle to be in si.
	;
		push	si
		mov	si, dx
		clr	di, dx
		clr	dx				; no GSControl
		call	GrGetGStringBounds		; c set if overflow,
							; else (ax,bx),
							; (cx,dx) <- bounds
		pop	si
		jc	quit
	;
	; Set the vis size.
	;
		clr	cx				; don't want
							; to set right bound
		call	VisSetSize
quit:
		.leave
		ret
CalendarEventsListContentSetGString	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarEventsListContentVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When closing, destroy the gstate associated with this
		content.

CALLED BY:	MSG_VIS_CLOSE
PASS:		*ds:si	= CalendarEventsListContentClass object
		ds:di	= CalendarEventsListContentClass instance data
		ds:bx	= CalendarEventsListContentClass object
			  (same as *ds:si)
		es 	= segment of CalendarEventsListContentClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	12/14/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarEventsListContentVisClose	method dynamic \
					CalendarEventsListContentClass, 
					MSG_VIS_CLOSE
	;
	; First destroy the gstring, and free the gstring block.
	;
		push	si
		mov	bx, ds:[di].CELCI_gsBlock
		mov	si, ds:[di].CELCI_gsHandle
		clr	di
		mov	dl, GSKT_KILL_DATA
		call	GrDestroyGString

		call	MemFree				; bx destroyed
		pop	si
	;
	; Call super.
	;
		mov	di, offset CalendarEventsListContentClass
		GOTO	ObjCallSuperNoLock
CalendarEventsListContentVisClose	endm


MailboxCode	ends

endif	; HANDLE_MAILBOX_MSG
