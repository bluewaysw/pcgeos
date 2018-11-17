COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Ruler Library
FILE:		rulerGuide.asm

AUTHOR:		Jon Witort, 22 October 1991

ROUTINES:
	Name				Description
	----				-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	22 Oct 1991	Initial revision

DESCRIPTION:
	Guide-related methods for VisRuler class.

	$Id: rulerGuide.asm,v 1.1 97/04/07 10:43:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerBasicCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			LockGuideArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si - VisRuler

Return:		bx - handle

		if guides exist:
			carry set
			ax:si - segment:offset of ChunkArray
		else:
			carry clear
			si trashed

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 11, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockGuideArray	proc	far
	class	VisRulerClass
	.enter
	mov	si, ds:[si]
	add	si, ds:[si].VisRuler_offset
	mov	bx, ds:[si].VRI_guideArray.handle
	tst_clc	bx
	jz	done
	mov	si, ds:[si].VRI_guideArray.offset
	call	ObjLockObjBlock
	stc
done:
	.leave
	ret
LockGuideArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisRulerDrawGuides
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_DRAW_GUIDES

Called by:	MSG_VIS_RULER_DRAW_GUIDES

Pass:		*ds:si = VisRuler object
		ds:di = VisRuler instance

		^hbp - GState

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug 19, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerDrawGuides	method dynamic	VisRulerClass,
			MSG_VIS_RULER_DRAW_GUIDES
	.enter

	tst	ds:[di].VRI_guideArray.handle
	jnz	checkShow

sendToSlave:
	call	RulerCallSlave
	.leave
	ret

checkShow:
	test	ds:[di].VRI_rulerAttrs, mask VRA_SHOW_GUIDES
	jz	sendToSlave

	mov	di, bp
	call	DrawGuidesWork
	jmp	sendToSlave
VisRulerDrawGuides	endm

RulerBasicCode	ends

RulerGridGuideConstrainCode	segment	resource

if 0
HGuideRegion	word	-2, -6, 2, -1			;the "vis" bounds
		word	-7, EOREGREC
		word	-6, -2, -1, 1, 2, EOREGREC
		word	-5, -2, 2, EOREGREC
		word	-3, -1, 1, EOREGREC
		word	-1, 0, 0, EOREGREC
		word	EOREGREC

VGuideRegion	word	-6, -2, -1, 2			;the "vis" bounds
		word	-3, EOREGREC
		word	-2, -6, -5, EOREGREC
		word	-1, -6, -3, EOREGREC
		word	0, -5, -1, EOREGREC
		word	1, -6, -3, EOREGREC
		word	2, -6, -5, EOREGREC
		word	EOREGREC
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerTurnGuidesSnappingOn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_TURN_GUIDES_SNAPPING_ON

Pass:		nothing

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 19, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerTurnGuidesSnappingOn	method	dynamic	VisRulerClass,
				MSG_VIS_RULER_TURN_GUIDES_SNAPPING_ON
	.enter

	ornf	ds:[di].VRI_constrainStrategy, \
			mask VRCS_SNAP_TO_GUIDES_X or \
			mask VRCS_SNAP_TO_GUIDES_Y
	.leave
	ret
VisRulerTurnGuidesSnappingOn	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerTurnGuidesSnappingOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_TURN_GUIDES_SNAPPING_OFF

Pass:		nothing

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 19, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerTurnGuidesSnappingOff	method	dynamic	VisRulerClass,
				MSG_VIS_RULER_TURN_GUIDES_SNAPPING_OFF
	.enter

	andnf	ds:[di].VRI_constrainStrategy, \
			not (mask VRCS_SNAP_TO_GUIDES_X or \
			mask VRCS_SNAP_TO_GUIDES_Y)
	.leave
	ret
VisRulerTurnGuidesSnappingOff	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerGetGuideInfluence
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_GET_GUIDE_INFLUENCE

		Returns the number of pixels within which a guideline will
		attract the mouse point.

Pass:		nothing

Return:		cx = influence

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov  4, 1991 	Initial version.
	jon	25 may 92	changed influence -> word sized
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerGetGuideInfluence	method	dynamic	VisRulerClass,
				MSG_VIS_RULER_GET_GUIDE_INFLUENCE
	.enter

	mov	cx, ds:[di].VRI_guideInfluence

	.leave
	ret
VisRulerGetGuideInfluence	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerSetGuideInfluence
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_SET_GUIDE_INFLUENCE

		Returns the number of pixels within which a guideline will
		attract the mouse point.

Pass:		cx = influence

Return:		nothing

Destroyed:	ax

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov  4, 1991 	Initial version.
	jon	25 may 92	changed influence -> word sized
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerSetGuideInfluence	method	dynamic	VisRulerClass,
				MSG_VIS_RULER_SET_GUIDE_INFLUENCE
	.enter

	mov	ds:[di].VRI_guideInfluence, cx

	.leave
	ret
VisRulerSetGuideInfluence	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerCreateGuideArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_CREATE_GUIDE_ARRAY

Context:	

Source:		

Destination:	

Pass:		nothing

Return:		nothing

Destroyed:	ax, bx, si

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 22, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerCreateGuideArray	method	dynamic	VisRulerClass,
				MSG_VIS_RULER_CREATE_GUIDE_ARRAY
	uses	ax, cx, dx
	.enter

	;
	;	Use object's segment for now...
	;
	mov	di, si
	mov	al, mask OCF_IGNORE_DIRTY	;doesn't go to state YET
	mov	bx, size Guide			;each element is a guide
	mov	cx, size GuideChunkArrayHeader
	clr	si
	call	ChunkArrayCreate

	mov	bx, ds:[si]
	mov	ds:[bx].GCAH_selectedElement, CA_NULL_ELEMENT

	mov	di, ds:[di]
	add	di, ds:[di].VisRuler_offset
	mov	cx, ds:[LMBH_handle]
	mov	ds:[di].VRI_guideArray.handle, cx
	mov	ds:[di].VRI_guideArray.chunk, si
	.leave
	ret
VisRulerCreateGuideArray	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerAddHorizontalGuide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_ADD_HORIZONTAL_GUIDE

Pass:		ss:bp = DWFixed location

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 22, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerAddHorizontalGuide	method	dynamic	VisRulerClass,
				MSG_VIS_RULER_ADD_HORIZONTAL_GUIDE

	call	ObjMarkDirty

	test	ds:[di].VRI_rulerAttrs, mask VRA_HORIZONTAL
	jz	checkSlave

	test	ds:[di].VRI_rulerAttrs, mask VRA_IGNORE_ORIGIN
	jnz	ignore
	adddwf	ss:[bp], ds:[di].VRI_origin, ax
	call	AddGuideCommon
	mov	di, ds:[si]
	add	di, ds:[di].VisRuler_offset
	subdwf	ss:[bp], ds:[di].VRI_origin, ax

inval:
	call	RulerSendInvalAD

	mov	ax, MSG_VIS_RULER_UPDATE_GUIDE_CONTROLLER
	call	ObjCallInstanceNoLock

	.leave
	ret

ignore:
	call	AddGuideCommon
	jmp	inval

checkSlave:
	call	RulerCallSlave
	jmp	inval
VisRulerAddHorizontalGuide	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerAddVerticalGuide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_ADD_VERTICAL_GUIDE

Pass:		ss:bp = DWFixed location

Return:		nothing

Destroyed:	nothing

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 22, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerAddVerticalGuide	method	dynamic	VisRulerClass,
				MSG_VIS_RULER_ADD_VERTICAL_GUIDE

	call	ObjMarkDirty

	test	ds:[di].VRI_rulerAttrs, mask VRA_HORIZONTAL
	jnz	checkSlave

	test	ds:[di].VRI_rulerAttrs, mask VRA_IGNORE_ORIGIN
	jnz	ignore
	adddwf	ss:[bp], ds:[di].VRI_origin, ax
	call	AddGuideCommon
	mov	di, ds:[si]
	add	di, ds:[di].VisRuler_offset
	subdwf	ss:[bp], ds:[di].VRI_origin, ax
inval:
	call	RulerSendInvalAD

	mov	ax, MSG_VIS_RULER_UPDATE_GUIDE_CONTROLLER
	call	ObjCallInstanceNoLock

	.leave
	ret

ignore:
	call	AddGuideCommon
	jmp	inval

checkSlave:
	call	RulerCallSlave
	jmp	inval
VisRulerAddVerticalGuide	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerSelectHorizontalGuide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_SELECT_HORIZONTAL_GUIDE

Pass:		ss:bp = DWFixed location

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 22, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerSelectHorizontalGuide	method	dynamic	VisRulerClass,
				MSG_VIS_RULER_SELECT_HORIZONTAL_GUIDE

	test	ds:[di].VRI_rulerAttrs, mask VRA_HORIZONTAL
	jz	checkSlave

	test	ds:[di].VRI_rulerAttrs, mask VRA_IGNORE_ORIGIN
	jnz	ignore
	adddwf	ss:[bp], ds:[di].VRI_origin, ax
ignore:
	call	SelectGuideCommon

update:

	mov	ax, MSG_VIS_RULER_UPDATE_GUIDE_CONTROLLER
	call	ObjCallInstanceNoLock

	.leave
	ret

checkSlave:
	call	RulerCallSlave
	jmp	update
VisRulerSelectHorizontalGuide	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerSelectVerticalGuide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_SELECT_VERTICAL_GUIDE

Pass:		ss:bp = DWFixed location

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 22, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerSelectVerticalGuide	method	dynamic	VisRulerClass,
				MSG_VIS_RULER_SELECT_VERTICAL_GUIDE

	test	ds:[di].VRI_rulerAttrs, mask VRA_HORIZONTAL
	jnz	checkSlave

	test	ds:[di].VRI_rulerAttrs, mask VRA_IGNORE_ORIGIN
	jnz	ignore
	adddwf	ss:[bp], ds:[di].VRI_origin, ax
ignore:
	call	SelectGuideCommon

update:

	mov	ax, MSG_VIS_RULER_UPDATE_GUIDE_CONTROLLER
	call	ObjCallInstanceNoLock

	.leave
	ret

checkSlave:
	call	RulerCallSlave
	jmp	update
VisRulerSelectVerticalGuide	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerDeleteVerticalGuide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_DELETE_VERTICAL_GUIDE

Pass:		ss:bp = DWFixed location

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 22, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerDeleteVerticalGuide	method	dynamic	VisRulerClass,
				MSG_VIS_RULER_DELETE_VERTICAL_GUIDE

	test	ds:[di].VRI_rulerAttrs, mask VRA_HORIZONTAL
	jnz	checkSlave

	call	ObjMarkDirty

	test	ds:[di].VRI_rulerAttrs, mask VRA_IGNORE_ORIGIN
	jnz	ignore
	adddwf	ss:[bp], ds:[di].VRI_origin, ax
ignore:
	call	DeleteGuideCommon

update:
	call	RulerSendInvalAD

	mov	ax, MSG_VIS_RULER_DESELECT_ALL_VERTICAL_GUIDES
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_RULER_UPDATE_GUIDE_CONTROLLER
	call	ObjCallInstanceNoLock

	.leave
	ret

checkSlave:
	call	RulerCallSlave
	jmp	update
VisRulerDeleteVerticalGuide	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerDeleteHorizontalGuide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_DELETE_HORIZONTAL_GUIDE

Pass:		ss:bp = DWFixed location

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 22, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerDeleteHorizontalGuide	method	dynamic	VisRulerClass,
				MSG_VIS_RULER_DELETE_HORIZONTAL_GUIDE

	test	ds:[di].VRI_rulerAttrs, mask VRA_HORIZONTAL
	jz	checkSlave

	call	ObjMarkDirty

	test	ds:[di].VRI_rulerAttrs, mask VRA_IGNORE_ORIGIN
	jnz	ignore
	adddwf	ss:[bp], ds:[di].VRI_origin, ax
ignore:
	call	DeleteGuideCommon

update:
	call	RulerSendInvalAD

	mov	ax, MSG_VIS_RULER_DESELECT_ALL_HORIZONTAL_GUIDES
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_RULER_UPDATE_GUIDE_CONTROLLER
	call	ObjCallInstanceNoLock

	.leave
	ret

checkSlave:
	call	RulerCallSlave
	jmp	update
VisRulerDeleteHorizontalGuide	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerDeselectAllHorizontalGuides
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_DESELECT_ALL_HORIZONTAL_GUIDES

Pass:		nothing

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 22, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerDeselectAllHorizontalGuides	method	dynamic	VisRulerClass,
				MSG_VIS_RULER_DESELECT_ALL_HORIZONTAL_GUIDES

	push	si

	test	ds:[di].VRI_rulerAttrs, mask VRA_HORIZONTAL
	jz	checkSlave

	call	LockGuideArray
	jnc	update
	mov	es, ax

	mov	si, es:[si]
	mov	es:[si].GCAH_selectedElement, CA_NULL_ELEMENT
	call	MemUnlock

update:
	pop	si
	mov	ax, MSG_VIS_RULER_UPDATE_GUIDE_CONTROLLER
	call	ObjCallInstanceNoLock

	.leave
	ret

checkSlave:
	call	RulerCallSlave
	jmp	update
VisRulerDeselectAllHorizontalGuides	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerDeselectAllVerticalGuides
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_DESELECT_ALL_VERTICAL_GUIDES

Pass:		nothing

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 22, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerDeselectAllVerticalGuides	method	dynamic	VisRulerClass,
				MSG_VIS_RULER_DESELECT_ALL_VERTICAL_GUIDES

	push	si

	test	ds:[di].VRI_rulerAttrs, mask VRA_HORIZONTAL
	jnz	checkSlave

	call	LockGuideArray
	jnc	update
	mov	es, ax

	mov	si, es:[si]
	mov	es:[si].GCAH_selectedElement, CA_NULL_ELEMENT
	call	MemUnlock

update:
	pop	si
	mov	ax, MSG_VIS_RULER_UPDATE_GUIDE_CONTROLLER
	call	ObjCallInstanceNoLock

	.leave
	ret

checkSlave:
	call	RulerCallSlave
	jmp	update
VisRulerDeselectAllVerticalGuides	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			AddGuideCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Adds a guideline to the VisRuler's guide array

Pass:		*ds:si = VisRuler object
		ds:di  = VisRuler instance
		ss:[bp] = DWFixed location of guideline (in ruler coords)

Return:		ax = # of new guide

Destroyed:	bx,di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb  3, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddGuideCommon	proc	near
	class	VisRulerClass
	uses	bx, cx,dx,bp,si
	.enter
	push	ds:[LMBH_handle]			;save ruler segment
	mov	di, ds:[si]
	add	di, ds:[di].VisRuler_offset

	tst	ds:[di].VRI_guideArray.handle
	jnz	haveArray

	mov	ax, MSG_VIS_RULER_CREATE_GUIDE_ARRAY
	call	ObjCallInstanceNoLock

	mov	di, ds:[si]
	add	di, ds:[di].VisRuler_offset
haveArray:
	call	LockGuideArray
	mov	ds, ax

	;
	;  Find the position at which to insert the new guide
	;
	;	cx <- # of guide before new (CA_NULL_ELEMENT if none)
	;	dx <- # guide after (CA_NULL_ELEMENT if none)
	;
	call	FindBoundingGuides

	;
	;  See if this is the rightmost guide
	;
	cmp	dx, CA_NULL_ELEMENT
	je	append

	;
	;  If the guide exactly overlaps another, then bail
	;
	cmp	dx, cx
	je	unlock

	;
	;  Create our new guide
	;
	mov_tr	ax, dx				;ax <- right guide #
	call	ChunkArrayElementToPtr		;ds:di <- right guide ptr
	call	ChunkArrayInsertAt		;ds:di <- new guide ptr
	jmp	recordNewGuide

append:
	call	ChunkArrayAppend

recordNewGuide:
	;
	;	Fill  new element with passed guidline info
	;
	movdwf	ds:[di].Guide_location, ss:[bp], ax

	;
	;  Select our new guide
	;
	call	ChunkArrayPtrToElement
	mov	di, ds:[si]
	mov	ds:[di].GCAH_selectedElement, ax

unlock:
	;	
	;	Unlock the block
	;
	call	MemUnlock

	pop	bx
	call	MemDerefDS			;fixup ds

	.leave
	ret
AddGuideCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectGuideCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Common routine for selecting a guideline

Pass		*ds:si = VisRuler instance

		ss:[bp] - DWFixed location of guide to select

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov  3, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectGuideCommon	proc	near
	uses	ax, bx, cx, dx, di, si
	.enter

	push	ds:[LMBH_handle]

	;
	;	See if we have guidelines
	;
	call	LockGuideArray
	jnc	done
	mov	ds, ax

	;
	;	Find least sensitive, unselected guideline to sense passed
	;	location, and store it's number
	;
	call	FindBoundingGuides
	cmp	cx, dx

	je	setSelected

	mov	cx, CA_NULL_ELEMENT

setSelected:
	mov	di, ds:[si]
	mov	ds:[di].GCAH_selectedElement, cx

	;
	;	Unlock the guideline block
	;
	call	MemUnlock
done:
	pop	bx
	call	MemDerefDS
	.leave
	ret
SelectGuideCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteGuideCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Common routine for deleteing a guideline

Pass		*ds:si = VisRuler instance

		ss:[bp] - DWFixed location of guide to delete

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov  3, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteGuideCommon	proc	near
	uses	ax, bx, cx, dx, di, si
	.enter

	push	ds:[LMBH_handle]


	;
	;	See if we have guidelines
	;
	call	LockGuideArray
	jnc	done
	mov	ds, ax

	;
	;	Find least sensitive, undeleteed guideline to sense passed
	;	location, and store it's number
	;
	call	FindBoundingGuides
	cmp	cx, dx
	jne	unlock

	cmp	cx, CA_NULL_ELEMENT
	je	unlock

	mov_tr	ax, cx
	mov	cx, 1
	call	ChunkArrayDeleteRange
unlock:
	;
	;	Unlock the guideline block
	;
	call	MemUnlock
done:
	pop	bx
	call	MemDerefDS

	.leave
	ret
DeleteGuideCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DrawGuidesWork
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Does the real work of drawing the guidelines

Pass:		*ds:si - VisRuler
		di - gstate

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 22, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawGuidesWork	proc	far
	class	VisRulerClass
	uses	ax, bx, cx, dx, bp, di, si, es, ds

	.enter

	call	GrSaveState

	mov	bx, si				;*ds:bx <- VisRuler

	sub	sp, size RectDWord
	mov	si, sp
	push	ds, bx
	segmov	es, ds
	segmov	ds, ss
	call	GrGetWinBoundsDWord

	mov	bx, es:[bx]
	add	bx, es:[bx].VisRuler_offset
	test	es:[bx].VRI_rulerAttrs, mask VRA_HORIZONTAL	
	jnz	horiz

	movdw	dxcx, ss:[si].RD_right
	adddw	dxcx, ss:[si].RD_left
	sardw	dxcx

	clr	ax, bx
	call	GrApplyTranslationDWord

	mov_tr	ax, cx
	mov	cx, ss:[si].RD_left.low
	sub	cx, ax
	mov	dx, ss:[si].RD_right.low
	sub	dx, ax
	mov	di, offset VGuideDraw
	jmp	afterTrans

horiz:
	movdw	bxax, ss:[si].RD_bottom
	adddw	bxax, ss:[si].RD_top
	sardw	bxax
	clr	cx,dx
	call	GrApplyTranslationDWord

	mov	cx, ss:[si].RD_top.low
	sub	cx, ax
	mov	dx, ss:[si].RD_bottom.low
	sub	dx, ax
	mov	di, offset HGuideDraw

afterTrans:
	pop	ds, si
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].VisRuler_offset
	call	LockGuideArray
	pop	di
	push	bx
	mov	ds, ax
	mov	bx, cs
	call	ChunkArrayEnum
	mov	di, bp
	call	GrRestoreState
	pop	bx
	call	MemUnlock
	add	sp, size RectDWord

	.leave
	ret
DrawGuidesWork	endp

HGuideDraw	proc	far
	push	cx, dx
	movdwf	dxcxax, ds:[di].Guide_location
	rnddwf	dxcxax

	clr	ax, bx
	mov	di, bp
	call	GrSaveState
	call	GrApplyTranslationDWord
	pop	bx, dx
	call	GrDrawVLine
	call	GrRestoreState
	mov	cx, bx
	ret
HGuideDraw	endp

VGuideDraw	proc	far
	push	cx, dx
	movdwf	bxaxcx, ds:[di].Guide_location
	rnddwf	bxaxcx

	clr	cx, dx
	mov	di, bp
	call	GrSaveState
	call	GrApplyTranslationDWord
	clr	bx
	pop	ax, cx
	call	GrDrawHLine
	call	GrRestoreState
	mov	dx, cx
	mov_tr	cx, ax
	ret
VGuideDraw	endp

if 0
VisRulerDrawGuideIndicators	method	dynamic	VisRulerClass, MSG_VIS_RULER_DRAW_GUIDE_INDICATORS
	;
	;	No guidelines, no indicators
	;
	tst	ds:[di].VRI_guideArray.handle
	jz	done

	;
	;	Find out where to draw the indicators
	;
	mov	ax, MSG_VIS_RULER_GET_PREF_SIZE
	call	ObjCallInstanceNoLock

	;
	;	Translate to where we want to draw the indicator
	;
	push	cx					;save size
	mov_tr	ax, cx
	cwd
	mov	bx, dx
	clr	cx, dx
	mov	di, bp
	call	GrApplyTranslationDWord

	;
	;	Why not?
	;
	call	GrGetAreaColor
	mov	ah, CF_RGB
	push	ax, bx
	mov	ax, C_RED
	call	GrSetAreaColor

	;
	;	dx:cx <- scale factor
	;
	mov	di, ds:[si]
	add	di, ds:[di].VisRuler_offset
	mov	dx, ds:[di].VRI_scale.WWF_int
	mov	cx, ds:[di].VRI_scale.WWF_frac

	;
	;	ds:si <- Locked guideline block
	;
	call	LockGuideArray
	push	bx					;save mem handle
	mov	ds, ax

	;
	;	bx:di <- GuideDrawIndicator callback routine
	;
	mov	bx, cs
	mov	di, offset GuideDrawIndicator

	;
	;	es:ax <- region to draw (should change to method)
	;
	segmov	es, cs
	mov	ax, offset HGuideRegion

	;
	;	Make all the guidelines draw themselves
	;
	call	ChunkArrayEnum

	;
	;	Unlock the guideline block
	;
	pop	bx					;bx <- mem handle
	call	MemUnlock

	;
	;	Restore color
	;
	mov	di, bp
	pop	ax, bx
	call	GrSetAreaColor

	;
	;	Untranslate
	;
	pop	ax
	cwd
	mov	bx, dx
	negdw	bxax
	clr	cx, dx
	call	GrApplyTranslationDWord
done:
	ret
VisRulerDrawGuideIndicators	endm

GuideDrawIndicator	proc	far
	uses	ds, ax, cx, dx

	.enter

	push	ax					;save region offset

	;
	;	si:bx:ax <- location
	;
	mov	si, ds:[di].Guide_location.DWF_int.high
	mov	bx, ds:[di].Guide_location.DWF_int.low
	mov	ax, ds:[di].Guide_location.DWF_frac

	;
	;	di:dx:cx <- scale factor
	;
	clr	di

	;
	;	dx:cx:bx <- scaled location
	;
	call	GrMulDWFixed

	;
	;	Round dx:cx to nearest coord
	;
	rnddwf	dxcxbx

	;
	;	Translate to our calculated coord
	;
	clr	ax, bx
	mov	di, bp
	call	GrApplyTranslationDWord

	;
	;	Draw the passed region
	;
	segmov	ds, es
	pop	si					;si <- region offset
	call	GrDrawRegion

	;
	;	Undo the previous translation
	;
	negdw	dxcx
	call	GrApplyTranslationDWord
	.leave
	ret
GuideDrawIndicator	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerSnapToGuides
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_SNAP_TO_GUIDES

Pass:		*ds:si = VisRuler object
		ds:di = VisRuler instance
		ss:[bp] = DWFixed to snap

Return:		carry set if snapped

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 22, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerSnapToGuides	method	dynamic	VisRulerClass,
			MSG_VIS_RULER_SNAP_TO_GUIDES
	uses	cx, dx

	.enter
	mov	di, si					;*ds:di <- vis ruler

	call	LockGuideArray
	LONG jnc done

	push	bx					;save for unlocking

	;
	; Calculate the influence in points
	;
	push	ds, di					;save ruler ptr
	push	ax					;save guide segment
	mov	di, ds:[di]
	add	di, ds:[di].VisRuler_offset	
	mov	dx, ds:[di].VRI_guideInfluence
	clr	cx
	movdw	bxax, ds:[di].VRI_scale
	call	GrUDivWWFixed				;dxcx <- wwfixed points

if 0
	test	ds:[di].VRI_rulerAttrs, mask VRA_IGNORE_ORIGIN
	jnz	10$
	subdwf	ss:[bp], ds:[di].VRI_origin, bx
10$:
endif
	pop	ds					;ds <- guide segment

	mov	bx, dx
	mov_tr	ax, cx					;bxax <- influence

	;
	;  cx, dx <- guide indices to the left,right of the passed point
	;
	call	FindBoundingGuides

	push	cx, dx					;save guides
	push	bx, ax					;save influence

	;
	;  bxax <- wwfixed distance from left guide
	;
	mov	bx, 0xffff				;some huge value
	cmp	cx, CA_NULL_ELEMENT
	je	calcRightDist

	mov_tr	ax, cx
	call	ChunkArrayElementToPtr			;ds:di <- left guide

	mov	ax, ds:[di].Guide_location.DWF_int.high
	cmp	ax, ss:[bp].DWF_int.high
	jne	calcRightDist

	mov	ax, ss:[bp].DWF_frac
	sub	ax, ds:[di].Guide_location.DWF_frac

	mov	bx, ss:[bp].DWF_int.low
	sbb	bx, ds:[di].Guide_location.DWF_int.low

calcRightDist:
	xchg	dx, ax					;ax <- right #
							;bxdx <- dist from left
	;
	;  cxax <- wwfixed distance from right guide
	;
	mov	cx, 0xffff				;some huge value
	cmp	ax, CA_NULL_ELEMENT
	je	cmpDists

	call	ChunkArrayElementToPtr			;ds:di <- left guide

	mov	ax, ds:[di].Guide_location.DWF_int.high
	cmp	ax, ss:[bp].DWF_int.high
	jne	cmpDists

	mov	ax, ds:[di].Guide_location.DWF_frac
	sub	ax, ss:[bp].DWF_frac

	mov	cx, ds:[di].Guide_location.DWF_int.low
	sbb	cx, ss:[bp].DWF_int.low

cmpDists:
	;
	;  bxax <- lesser of bxdx and cxax
	;
	xchg	ax, dx				;cxdx <- distance from right
						;bxax <- distance from left

	cmp	cx, bx
	ja	gotDist				;carry clear if so
	jb	useRight			;carry set if so

	cmp	dx, ax
	jae	gotDist				;carry clear if so

useRight:
	movdw	bxax, cxdx
gotDist:
	pop	dx, cx				;dxcx <- influence
	pushf					;save carry

	cmp	bx, dx
	ja	outsideInfluence
	jb	withinInfluence

	cmp	ax, cx
	ja	outsideInfluence

withinInfluence:
	;
	;  Point is within guide's influence, so figure out which
	;  guide it is and copy the location
	;
	popf					;carry set if right guide
	pop	cx, ax				;get left, right guides
	jc	gotGuide
	mov_tr	ax, cx
gotGuide:
	call	ChunkArrayElementToPtr
	movdwf	ss:[bp], ds:[di].Guide_location, ax
	mov	ax, 1				;indicate that we did something
	jmp	unlock

outsideInfluence:
	add	sp, 6				;clear stack of flags, guides
	clr	ax				;didn't snap...
unlock:
	pop	ds, di
if 0
	mov	di, ds:[di]
	add	di, ds:[di].VisRuler_offset
	test	ds:[di].VRI_rulerAttrs, mask VRA_IGNORE_ORIGIN
	jnz	20$
	adddwf	ss:[bp], ds:[di].VRI_origin, bx
20$:
endif

	pop	bx
	call	MemUnlock
	shr	ax				;carry <- low bit of ax
done:
	.leave
	ret
VisRulerSnapToGuides	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerSnapToGuidesY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_SNAP_TO_GUIDES_Y

Pass:		ss:bp - point

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 19, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerSnapToGuidesY	method	dynamic	VisRulerClass,
			MSG_VIS_RULER_SNAP_TO_GUIDES_Y
	.enter

	test	ds:[di].VRI_rulerAttrs, mask VRA_HORIZONTAL
	jnz	checkSlave
	
	add	bp, offset PDF_y
	mov	ax, MSG_VIS_RULER_SNAP_TO_GUIDES
	call	ObjCallInstanceNoLock
	pushf						;preserve carry
	sub	bp, offset PDF_y
	popf						;restore carry
done:	
	.leave
	ret
checkSlave:
	call	RulerCallSlave
	jmp	done
VisRulerSnapToGuidesY	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerSnapToGuidesX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_SNAP_TO_GUIDES_X

Pass:		ss:bp - point

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 19, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerSnapToGuidesX	method	dynamic	VisRulerClass,
			MSG_VIS_RULER_SNAP_TO_GUIDES_X
	.enter

	test	ds:[di].VRI_rulerAttrs, mask VRA_HORIZONTAL
	jz	checkSlave
	
	mov	ax, MSG_VIS_RULER_SNAP_TO_GUIDES
	call	ObjCallInstanceNoLock
	jmp	done

checkSlave:
	call	RulerCallSlave
done:	
	.leave
	ret
VisRulerSnapToGuidesX	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			FindBoundingGuides
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Returns the least sensitive guidline that senses the
		passed point.

Pass:		*ds:si = array
		ss:bp = DWFixed (horiz/vert) location of point

Return:		cx = index of guide to the left of the passed point
		dx = index of guide to the right of the passed point

		cx = dx for a perfect match

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 22, 1991 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindBoundingGuides	proc	near
	uses	ax, bx, es, di
	.enter

	clr	ax
	mov	cx, CA_NULL_ELEMENT	;no candidates yet
	mov	dx, cx
	mov	bx, cs				;bx:di <- callback
	mov	di, offset FindBoundingGuidesCB
	segmov	es, ss
	call	ChunkArrayEnum

	.leave
	ret
FindBoundingGuides	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			FindBoundingGuidesCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		ds:di = Guide
		es:bp = DWFixed location

		ax = guide's index
		cx = index of guide last checked

Return:		if passed point > guide location:
			ax = guide's index + 1 (next guides index)
			cx = this guide's index
			carry clear to continue search

		if passed point < guide location:
			dx = this guide's index
			carry set to terminate search

		if passed point = guide location:
			cx = dx = this guide's index
			carry set to terminate search

Destroyed:	bx, si

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	26 may 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindBoundingGuidesCB	proc	far

	.enter

	;
	;	Determine the distance between the passed point and the
	;	guideline
	;
	mov	si, ds:[di].Guide_location.DWF_int.high
	cmp	si, es:[bp].DWF_int.high
	jg	terminate
	jl	guideLesser

	mov	bx, ds:[di].Guide_location.DWF_int.low
	cmp	bx, es:[bp].DWF_int.low
	ja	terminate
	je	checkFracs

guideLesser:
	;
	;  the guide's is lesser than the passed point,
	;  so keep searching
	;
	mov	cx, ax
	inc	ax
	clc
done:
	.leave
	ret

terminate:
	;
	;  the guide's location is greater than the passed point,
	;  so we're done with our search
	;
	mov_tr	dx, ax
	stc
	jmp	done

checkFracs:
	tst	si
	mov	si, ds:[di].Guide_location.DWF_frac
	js	checkFracNeg

	;
	;  The numbers are positive, so a greater frac = greater number
	;
	cmp	si, es:[bp].DWF_frac
	ja	terminate
	jb	guideLesser

exactlyEqual:
	;
	;  The two numbers are equal; set the before/after indices to
	;  this guide and return carry set
	;
	mov	cx, ax
	jmp	terminate

checkFracNeg:
	;
	;  The numbers are negative, so a greater frac = lesser number
	;
	cmp	si, es:[bp].DWF_frac
	ja	guideLesser
	jb	terminate
	jmp	exactlyEqual
FindBoundingGuidesCB	endp
RulerGridGuideConstrainCode	ends
