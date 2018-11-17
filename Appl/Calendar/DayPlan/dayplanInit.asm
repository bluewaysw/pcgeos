COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Dayplan
FILE:		dayplanInit.asm

AUTHOR:		Don Reeves, December 18, 1989

ROUTINES:
	Name			Description
	----			-----------
	DayPlanInit		Initializes the DayPlan object
	DayPlanQuit		Clean up DayPlan loose ends
	DayPlanCalcOneLineHeight Used to calculate minimum widths & heights
				 for events
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/18/89	Initial revision

DESCRIPTION:
	Contains the initialization and detach code
		
	$Id: dayplanInit.asm,v 1.1 97/04/04 14:47:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanRelocate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Relocate/unrelocate the DayPlanClass object

CALLED BY:	GLOBAL (MSG_META_RELOCATE)

PASS:		ES	= Segment of DayPlanClass
		*DS:SI	= DayPlanClass object
		DS:BX	= Dereferenced object
		AX	= MSG_META_RELOCATE or MSG_META_UNRELOCATE
		CX,DX,BP= see MSG_META_RELOCATE/UNRELOCATE

RETURN:		see MSG_META_RELOCATE/UNRELOCATE

DESTROYED:	see MSG_META_RELOCATE/UNRELOCATE

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/21/92	Initial version
		sean	1/11/96		Change to zero out FTVMC_flags
					Fixes #48366

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanRelocate	method dynamic	DayPlanClass,	reloc

		; Zero-out our vis linkage if we are going to state, as
		; our children don't go with us. Also need to clear
		; target & focus, in case we go to state when we are
		; iconified.  Also, clear FTVMC_flags.  (sean 1/11/96)
		;
		cmp	ax, MSG_META_RELOCATE
		jz	done
		add	bx, ds:[bx].Vis_offset
		clrdw	ds:[bx].VCI_comp.CP_firstChild
		clrdw	ds:[bx].VCNI_focusExcl.FTVMC_OD
		clr	ds:[bx].VCNI_focusExcl.FTVMC_flags
		clrdw	ds:[bx].VCNI_targetExcl.FTVMC_OD
		clr	ds:[bx].VCNI_targetExcl.FTVMC_flags
done:
		mov	di, offset DayPlanClass	; ClassStruct => ES:DI
		call	ObjRelocOrUnRelocSuper
		ret
DayPlanRelocate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initalize the DayPlan

CALLED BY:	CalendarAttach

PASS:		ES	= DGroup
		DS:*SI	= DayPlan instance data

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/5/89		Initial version
	sean	2/6/96		Responder change to font for 
				SizeTextObject

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanInit	method	DayPlanClass, MSG_DP_INIT
								
	; Build the visual instance data, and set things up
	;
	mov	bx, Vis_offset			; offset to part to build
	call	ObjInitializePart		; do the building
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].Vis_offset		; access the visual information
	or	ds:[di].VCI_geoAttrs, mask VCGA_CUSTOM_MANAGE_CHILDREN
	or	ds:[di].VCNI_attrs, mask VCNA_SAME_WIDTH_AS_VIEW
	
	; Setup the color scheme
	;
	call	CalendarColorScheme		; get the calendar color scheme

	; Put ourselves on the list of OD's interested in transfer items
	;
	mov	cx, ds:[LMBH_handle]		; block handle => CX
	mov	dx, si				; DayPlan OD => CX:DX
	call	ClipboardAddToNotificationList	; add my OD to the list

	; Create the Buffer table
	;
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayPlan_offset	; access instance data
	mov	ax, ds:[di].DPI_bufferTable	; get the handle
	mov	cx, (size BufferTableHeader)
	call	LMemReAlloc			; resize the sucker

	; Stuff the data
	;
	mov	bx, ax
	mov	bx, ds:[bx]			; derefence the handle
	mov	ds:[bx].BTH_buffers, 0
	mov	ds:[bx].BTH_size, cx

	; Create the "RESIZE" text edit object & store handle
	;
	mov	bx, ds:[LMBH_handle]		; block to hold the object
	mov	di, offset MyTextClass		; ES:DI class of obj to create
	call	ObjInstantiate			; create it
	mov	ax, si
	mov	bx, mask OCF_IGNORE_DIRTY	; bits to set => BL, reset => BH
	call	ObjSetFlags
	mov	es:[SizeTextObject], si		; store the handle away

	; Calculate the height of a one line text object
	;
	mov	si, offset DPResource:DayPlanObject
	mov	ax, MSG_DP_CALC_ONE_LINE_HEIGHT
	call	ObjCallInstanceNoLock
	mov	si, ds:[si]
	add	si, ds:[si].DayPlan_offset
	mov	ds:[si].DPI_textHeight, dx

	; Ensure enough buffers are present
	;
	mov	si, offset DPResource:DayPlanObject
	call	BufferEnsureEnough		; make certain we have buffers
	ret
DayPlanInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanQuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dump all of a day plans events to the database

CALLED BY:	GLOBAL (MSG_DP_QUIT)

PASS:		DS:*SI	= Instance data

RETURN:		Nothing

DESTROYED:	CX, DI, ES

PSEUDO CODE/STRATEGY:
		Go through all buffers in this Day Plan
			Tell each event to dump itself

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/31/89		Initial version
	Don	12/4/89		Major revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanQuit	method	DayPlanClass, MSG_DP_QUIT

	; Remove ourself from the list of OD's interested in transfer items
	;
	mov	cx, ds:[LMBH_handle]		; block handle => CX
	mov	dx, si				; DayPlan OD => CX:DX
						; removed my OD from the list
	call	ClipboardRemoveFromNotificationList

	; Must mark object as dirty, to save preferences state!
	;
	mov	ax, si				; chunk handle => AX
	mov	bx, mask OCF_DIRTY		; bits to set in BL,reset in BH
	call	ObjSetFlags			; change the flags
	ret
DayPlanQuit	endp

InitCode	ends



DayPlanCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanCalcOneLineHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the one line text height

CALLED BY:	GLOBAL
	
PASS:		DS:SI	= DayPlanClass instance data
		ES	= DGroup

RETURN:		DX	= Height in points
		CX	= Minimum Width in points of the time field

DESTROYED:	AX, CX, BP, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TIME_SPACING	= 2 + (2 * EVENT_LR_MARGIN)

DayPlanCalcOneLineHeight	method	DayPlanClass,	\
					MSG_DP_CALC_ONE_LINE_HEIGHT
	.enter

	; Now find height of single line of text
	;
	mov	di, ds:[LMBH_handle]		; block handle => DI
	mov	si, es:[SizeTextObject]		; size object => DI:*SI
	mov	cx, 22 shl 8			; 10 pm
	call	TimeToTextObject		; stuff the text object
	mov	cx, DAYPLAN_TIME_WIDTH_MIN	; minimum width
	clr	dx				; don't use cached size
	mov	ax, MSG_VIS_TEXT_CALC_HEIGHT	; calculate the height
	call	ObjCallInstanceNoLock		; returned in DX	
	push	dx
	clr	cx				; use the entire string
	mov	ax, MSG_VIS_TEXT_GET_ONE_LINE_WIDTH
	call	ObjCallInstanceNoLock		; minimum width => CX
	pop	dx				; one line height => DX
	mov	es:[oneLineTextHeight], dx	; store the height
	add	cx, TIME_SPACING		; allow some extra space
	mov	es:[timeWidth], cx		; store the minimum width

	; Also calculate the vertical offset at which to draw the
	; an event's icon (alarm off, alarm on or repeat icon)
	;
	push	dx
	sub	dx, ICON_HEIGHT
	inc	dx
	sar	dx, 1
	mov	es:[yIconOffset], dx
	pop	dx

	.leave
	ret
DayPlanCalcOneLineHeight	endp



DayPlanCode	ends





