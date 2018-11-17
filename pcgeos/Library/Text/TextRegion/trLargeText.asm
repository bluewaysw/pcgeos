COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		trExternal.asm

AUTHOR:		Tony Requist, August 31, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 2/12/92	Initial revision

DESCRIPTION:
	All of the externally callable routines.

	$Id: trLargeText.asm,v 1.1 97/04/07 11:21:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextStorageCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisLargeTextCreateDataStructures --
		MSG_VIS_LARGE_TEXT_CREATE_DATA_STRUCTURES for VisTextClass

DESCRIPTION:	Create data structures for a large text object

PASS:
	*ds:si - instance data
	es - segment of VisLargeTextClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/22/92		Initial version

------------------------------------------------------------------------------@
VisLargeTextCreateDataStructures	method dynamic	VisLargeTextClass,
				MSG_VIS_LARGE_TEXT_CREATE_DATA_STRUCTURES

EC <	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE		>
EC <	ERROR_NZ VIS_TEXT_OBJECT_IS_ALREADY_LARGE			>

EC <	test	ds:[di].VTI_storageFlags, mask VTSF_MULTIPLE_CHAR_ATTRS \
			or mask VTSF_MULTIPLE_PARA_ATTRS \
			or mask VTSF_TYPES or mask VTSF_GRAPHICS	>
EC <	ERROR_NZ VIS_TEXT_OBJECT_CANNOT_BE_MADE_LARGE			>

EC <	tst	ds:[di].VTI_lines					>
EC <	ERROR_NZ VIS_TEXT_OBJECT_CANNOT_BE_MADE_LARGE			>

EC <	mov	ds:[di].VTI_lastWidth, -1				>
EC <	mov	ds:[di].VTI_height.WBF_int, -1				>
EC <	mov	ds:[di].VTI_height.WBF_frac, -1				>

	mov	ax, ds:[di].VTI_text
	tst	ax
	jz	afterText
	call	ObjFreeChunk
afterText:
	
	ornf	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	call	TS_LargeCreateTextStorage
	
EC <	call	T_AssertIsVisLargeText					>

	ret

VisLargeTextCreateDataStructures	endm

TextStorageCode ends

TextRegion	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisLargeTextSetDisplayMode --
		MSG_VIS_LARGE_TEXT_SET_DISPLAY_MODE for VisLargeTextClass

DESCRIPTION:	Set the display mode

PASS:
	*ds:si - instance data
	es - segment of VisLargeTextClass

	ax - The message

	cx - VisTextDisplayModes

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/27/92		Initial version

------------------------------------------------------------------------------@
VisLargeTextSetDisplayMode	method dynamic VisLargeTextClass,
					MSG_VIS_LARGE_TEXT_SET_DISPLAY_MODE

	call	ObjMarkDirty

	mov	dx, cx
	xchg	dx, ds:[di].VLTI_displayMode		;dx = old mode

	; cx = new mode, dx = old mode

	; if the new mode is not PAGE then we need to recalculate the
	; total height of the object

	push	cx, dx
	call	RecalcTotalSize
	pop	cx, dx

	; if the old mode or the new mode if DRAFT then we need to
	; recalculate the object, otherwise the caller will take care
	; of it

	cmp	cx, VLTDM_DRAFT_WITH_STYLES
	jae	recalc
	cmp	dx, VLTDM_DRAFT_WITH_STYLES
	jb	noRecalc
recalc:

	; We used to SUSPEND, do the RECALC_AND_DRAW and then queue
	; an UNSUSPEND.  This caused bugs in printing in GeoWrite because
	; it counts on the recalculation being done immediately.  Also,
	; queuing the UNSUSPEND would likely cause problems in an auto save
	; kicked in before the UNSUSPEND came through.

	mov	ax, MSG_VIS_TEXT_RECALC_AND_DRAW
	call	ObjCallInstanceNoLock
noRecalc:

	; Set VTF_DONT_SHOW_GRAPHICS if draft, clear otherwise
	
	push	ax, cx, dx, bp
	cmp	cx, VLTDM_DRAFT_WITH_STYLES
	mov	cx, mask VTF_DONT_SHOW_GRAPHICS		; assume draft
	mov	dx, 0					; don't modify flags
	jae	draft					; yup, it's draft
	clr	cx					; so clear V_D_S_G
	mov	dx, mask VTF_DONT_SHOW_GRAPHICS
draft:
	mov	ax, MSG_VIS_TEXT_SET_FEATURES
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp

	FALL_THRU	DisplayModeRecalcCommon

VisLargeTextSetDisplayMode	endm

;---

DisplayModeRecalcCommon	proc	far

	mov	ax, MSG_VIS_RECREATE_CACHED_GSTATES
	call	ObjCallInstanceNoLock

	; send height notification

	call	SendLargeHeightNotify

	mov	ax, VIS_TEXT_STANDARD_NOTIFICATION_FLAGS
	call	TA_SendNotification

	mov	dx, VIS_TEXT_RANGE_SELECTION
	mov	ax, MSG_VIS_TEXT_SHOW_POSITION
	GOTO	ObjCallInstanceNoLock

DisplayModeRecalcCommon	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisLargeTextSetDraftRegionSize --
		MSG_VIS_LARGE_TEXT_SET_DRAFT_REGION_SIZE for VisLargeTextClass

DESCRIPTION:	Set the draft region size

PASS:
	*ds:si - instance data
	es - segment of VisLargeTextClass

	ax - The message

	cx - width
	dx - height

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/ 2/92		Initial version

------------------------------------------------------------------------------@
VisLargeTextSetDraftRegionSize	method dynamic	VisLargeTextClass,
				MSG_VIS_LARGE_TEXT_SET_DRAFT_REGION_SIZE

	cmp	cx, ds:[di].VLTI_draftRegionSize.XYS_width
	jnz	changed
	cmp	dx, ds:[di].VLTI_draftRegionSize.XYS_height
	jz	done
changed:

	call	ObjMarkDirty

	mov	ds:[di].VLTI_draftRegionSize.XYS_width, cx
	mov	ds:[di].VLTI_draftRegionSize.XYS_height, dx
	cmp	ds:[di].VLTI_displayMode, VLTDM_DRAFT_WITH_STYLES
	jb	notDraft
	mov	ds:[di].VLTI_displayModeWidth, cx
notDraft:

	call	RecalcTotalSize

	mov	ax, MSG_VIS_TEXT_RECALC_AND_DRAW
	call	ObjCallInstanceNoLock

	GOTO	DisplayModeRecalcCommon

done:
	ret

VisLargeTextSetDraftRegionSize	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisLargeTextViewSizeChanged --
		MSG_META_CONTENT_VIEW_SIZE_CHANGED for VisLargeTextClass

DESCRIPTION:	Handle the view size changing

PASS:
	*ds:si - instance data
	es - segment of VisLargeTextClass

	ax - The message

	cx - new width
	dx - new height
	bp - window handle

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/ 3/92		Initial version

------------------------------------------------------------------------------@
VisLargeTextViewSizeChanged	method dynamic	VisLargeTextClass,
					MSG_META_CONTENT_VIEW_SIZE_CHANGED

	; if we are if DRAFT mode then change the draft region width

	cmp	ds:[di].VLTI_displayMode, VLTDM_DRAFT_WITH_STYLES
	jb	done

	mov	dx, ds:[di].VLTI_draftRegionSize.XYS_height
	mov	ax, MSG_VIS_LARGE_TEXT_SET_DRAFT_REGION_SIZE
	call	ObjCallInstanceNoLock

done:
	ret

VisLargeTextViewSizeChanged	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	RecalcTotalSize

DESCRIPTION:	Calculate the total size of the object if not in page mode

CALLED BY:	INTERNAL

PASS:
	*ds:si - object

RETURN:
	height and width in instance data - set

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/27/92		Initial version

------------------------------------------------------------------------------@
RecalcTotalSize	proc	near
	class	VisLargeTextClass
;	ProfilePoint 25

EC <	call	T_AssertIsVisLargeText					>

	; no recalc if in page mode

	call	TextRegion_DerefVis_DI
	cmp	ds:[di].VLTI_displayMode, VLTDM_PAGE
	jz	done

	push	si
	call	SetupForRegionScan		;ds:si = region, cx = count
	clr	bx				;bx = region number
	clr	ax				;ax = widest region
findLastLoop:
	cmp	ax, ds:[si].VLTRAE_size.XYS_width
	jae	10$
	mov	ax, ds:[si].VLTRAE_size.XYS_width
10$:
	call	LargeRegionIsLastRegionInLastSection
	jc	foundLast
	inc	bx
	dec	cx
EC <	ERROR_Z	VIS_TEXT_REGION_ASSUMPTION_FAILED			>
	call	ScanToNextRegion
	jmp	findLastLoop

foundLast:
	pop	si

	cmp	ds:[di].VLTI_displayMode, VLTDM_DRAFT_WITH_STYLES
	jb	notDraft
	mov	ax, ds:[di].VLTI_draftRegionSize.XYS_width
notDraft:
	mov	ds:[di].VLTI_displayModeWidth, ax
	test	ds:[di].VLTI_attrs, mask VLTA_EXACT_HEIGHT
	pushf

	mov	cx, bx				;cx = last region
	push	bp
	sub	sp, size PointDWord
	mov	bp, sp
	call	TR_RegionGetTopLeft
	movdw	bxdi, ss:[bp].PD_y		;bxcx = last region pos
	add	sp, size PointDWord
	pop	bp

	popf
	push	bp
	mov	bp, di				;bxbp = height
	jnz	useExactHeight

	; add in the height of the last region

	call	LargeRegionGetTrueHeight	;dx.al = height
	jmp	gotHeight
useExactHeight:
	call	LargeRegionGetHeight		;dx.al = height
gotHeight:
	ceilwbf	dxal, dx
	add	bp, dx
	adc	bx, 0				;bxbp = total height

	call	TextRegion_DerefVis_DI
	movdw	ds:[di].VLTI_totalHeight, bxbp
	pop	bp

done:
;	ProfilePoint 24
	ret

RecalcTotalSize	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisLargeTextAppendRegion --
		MSG_VIS_LARGE_TEXT_APPEND_REGION for VisLargeTextClass

DESCRIPTION:	Default handler for appending regions

PASS:
	*ds:si - instance data
	es - segment of VisLargeTextClass

	ax - The message

	cx - region to append after

RETURN:
	carry - set if another region cannot be appended

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/ 3/92		Initial version

------------------------------------------------------------------------------@
VisLargeTextAppendRegion	method dynamic	VisLargeTextClass,
						MSG_VIS_LARGE_TEXT_APPEND_REGION

	test	ds:[di].VLTI_attrs, mask VLTA_REGIONS_IN_HUGE_ARRAY
	jnz	huge

	mov	si, ds:[di].VLTI_regionArray

	mov_tr	ax, cx
	cmp	ax, CA_NULL_ELEMENT
	jz	append

	inc	ax					;point at next
	call	ChunkArrayElementToPtr			;ds:di = ptr
	jc	append					;if last then append
	call	ChunkArrayInsertAt			;ds:di = new element

	clc
	ret

append:
	call	ChunkArrayAppend
	clc
	ret

huge:
	mov	di, ds:[di].VLTI_regionArray
	call	T_GetVMFile
	clr	bp

	cmp	cx, CA_NULL_ELEMENT
	jz	appendHuge
	inc	cx
	call	HugeArrayGetCount		;dx.ax = count
	cmp	cx, ax
	jz	appendHuge

	mov_tr	ax, cx				;dx.ax = element
	mov	cx, 1
	call	HugeArrayInsert
	clc
	ret

appendHuge:
	mov	cx, 1
	call	HugeArrayAppend
	clc
	ret

VisLargeTextAppendRegion	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisLargeTextRegionIsLast --
		MSG_VIS_LARGE_TEXT_REGION_IS_LAST for VisLargeTextClass

DESCRIPTION:	Default handler for deleting regions

PASS:
	*ds:si - instance data
	es - segment of VisLargeTextClass

	ax - The message

	cx - last region number

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/ 3/92		Initial version

------------------------------------------------------------------------------@
VisLargeTextRegionIsLast	method dynamic	VisLargeTextClass,
					MSG_VIS_LARGE_TEXT_REGION_IS_LAST

	; This does not support regions in huge arrays
	
	mov	si, ds:[di].VLTI_regionArray

	mov_tr	ax, cx				;ax = last
	inc	ax

	call	ChunkArrayGetCount		;cx = total
	sub	cx, ax				;cx = regions to delete
EC <	ERROR_B	VIS_TEXT_ILLEGAL_REGION_PASSED__MAYBE_BAD_SECTION_BREAK	>
	jz	done
	call	ChunkArrayElementToPtr
deleteLoop:
	call	ChunkArrayDelete
	loop	deleteLoop

done:
	ret

VisLargeTextRegionIsLast	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisLargeTextNotifyGeometryValid --
		MSG_VIS_NOTIFY_GEOMETRY_VALID for VisLargeTextClass

DESCRIPTION:	Deal specially with notify geometry valid

PASS:
	*ds:si - instance data
	es - segment of VisLargeTextClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/ 8/92		Initial version

------------------------------------------------------------------------------@
VisLargeTextNotifyGeometryValid	method dynamic	VisLargeTextClass,
						MSG_VIS_NOTIFY_GEOMETRY_VALID

	ProfilePoint 26
	clr	cx
	mov	ax, TEMP_VIS_TEXT_FORCE_SEND_IS_LAST_REGION
	call	ObjVarAddData

	call	TextRegion_DerefVis_DI
	andnf	ds:[di].VI_optFlags, not mask VOF_GEOMETRY_INVALID

	; if lines already exist then skip this

	tst	ds:[di].VTI_lines
	jnz	done

	; if no regions exist then create one

	call	VisLargeTextGetRegionCount	  ;cx = count
	tst	cx
	jnz	afterRegions
	mov	cx, CA_NULL_ELEMENT
	mov	ax, MSG_VIS_LARGE_TEXT_APPEND_REGION
	call	ObjCallInstanceNoLock
afterRegions:

	call	RecalcTotalSize

	mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID
	mov	di, offset VisLargeTextClass
	call	ObjCallSuperNoLock
done:
;;	ProfilePoint 27	; SI might be messed up at this point
	ret

VisLargeTextNotifyGeometryValid	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisLargeTextHeightNotify -- MSG_VIS_LARGE_TEXT_HEIGHT_NOTIFY
						for VisLargeTextClass

DESCRIPTION:	Deal with the object changing size (in a mode other than
		PAGE)

PASS:
	*ds:si - instance data
	es - segment of VisLargeTextClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/28/92		Initial version

------------------------------------------------------------------------------@
VisLargeTextHeightNotify	method dynamic	VisLargeTextClass,
						MSG_VIS_TEXT_HEIGHT_NOTIFY

	mov_tr	ax, di
	mov	di, 800
	call	ThreadBorrowStackSpace
	push	di
	mov_tr	di, ax

	sub	sp, size RectDWord
	mov	bp, sp

	; get width and height

	mov	ax, ds:[di].VLTI_displayModeWidth
	mov	ss:[bp].RD_right.low, ax
	movdw	dxax, ds:[di].VLTI_totalHeight
	tstdw	dxax
	jz	done
	movdw	ss:[bp].RD_bottom, dxax

	clr	ax
	mov	ss:[bp].RD_right.high, ax
	clrdw	ss:[bp].RD_left, ax
	clrdw	ss:[bp].RD_top, ax

	; now tell the view what the size is

	push	si
	mov	bx, segment VisContentClass
	mov	si, offset VisContentClass
	mov	ax, MSG_VIS_CONTENT_SET_DOC_BOUNDS
	mov	di, mask MF_STACK or mask MF_RECORD
	mov	dx, size RectDWord
	call	ObjMessage			;di = message
	pop	si

	mov	cx, di
	mov	ax, MSG_VIS_VUP_SEND_TO_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock

done:
	add	sp, size RectDWord

	pop	di
	call	ThreadReturnStackSpace

	ret

VisLargeTextHeightNotify	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisLargeTextGetDraftRegionSize --
		MSG_VIS_LARGE_TEXT_GET_DRAFT_REGION_SIZE for VisLargeTextClass

DESCRIPTION:	Get the draft region size

PASS:
	*ds:si - instance data
	es - segment of VisLargeTextClass

	ax - The message

RETURN:
	cx - width
	dx - height

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/10/92		Initial version

------------------------------------------------------------------------------@
VisLargeTextGetDraftRegionSize	method dynamic	VisLargeTextClass,
				MSG_VIS_LARGE_TEXT_GET_DRAFT_REGION_SIZE

	mov	cx, ds:[di].VLTI_draftRegionSize.XYS_width
	mov	dx, ds:[di].VLTI_draftRegionSize.XYS_height
	ret

VisLargeTextGetDraftRegionSize	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisLargeTextGetRegionCount --
		MSG_VIS_LARGE_TEXT_GET_REGION_COUNT for VisLargeTextClass

DESCRIPTION:	Get the region count

PASS:
	*ds:si - instance data
	es - segment of VisLargeTextClass

	ax - The message

RETURN:
	cx - region count

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/10/92		Initial version

------------------------------------------------------------------------------@
VisLargeTextGetRegionCount	method VisLargeTextClass,
				MSG_VIS_LARGE_TEXT_GET_REGION_COUNT
				uses 	ax, bx, dx, si, di
	.enter
EC <	call	T_AssertIsVisLargeText					>

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VLTI_attrs, mask VLTA_REGIONS_IN_HUGE_ARRAY
	jnz	huge

	mov	si, ds:[di].VLTI_regionArray	;*ds:si = array
	call	ChunkArrayGetCount		;cx = count
	jmp	done

huge:
	call	T_GetVMFile			;bx = file
	mov	di, ds:[di].VLTI_regionArray
	call	HugeArrayGetCount
	mov_tr	cx, ax

done:
	.leave
	ret

VisLargeTextGetRegionCount	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisLargeTextGetRegionPos --
		MSG_VIS_LARGE_TEXT_GET_REGION_POS for VisLargeTextClass

DESCRIPTION:	Get the draft region size

PASS:
	*ds:si - instance data
	es - segment of VisLargeTextClass

	ax - The message

	cx - region number

RETURN:
	dxax - y position
	cx - height

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/10/92		Initial version

------------------------------------------------------------------------------@
VisLargeTextGetRegionPos	method dynamic	VisLargeTextClass,
					MSG_VIS_LARGE_TEXT_GET_REGION_POS

	sub	sp, size PointDWord
	mov	bp, sp

	call	TR_RegionGetTopLeft

	call	TR_RegionGetHeight
	ceilwbf	dxal, cx			;cx = height

	movdw	dxax, ss:[bp].PD_y

	add	sp, size PointDWord
	ret

VisLargeTextGetRegionPos	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisLargeTextRegionChanged --
		MSG_VIS_LARGE_TEXT_REGION_CHANGED for VisLargeTextClass

DESCRIPTION:	Handle notification thata region has changed

PASS:
	*ds:si - instance data
	es - segment of VisLargeTextClass

	ax - The message

	cx - region number

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/12/92		Initial version

------------------------------------------------------------------------------@
VisLargeTextRegionChanged	method dynamic	VisLargeTextClass,
					MSG_VIS_LARGE_TEXT_REGION_CHANGED

	sub	sp, size VisTextRange
	mov	bp, sp

	call	TS_GetTextSize			;dxax = size
	movdw	bxdi, dxax			;bxdi = size

	call	TR_RegionGetStartOffset		;dxax = start offset

	; if we're at the end of the text AND the text is non-empty
	; then move back a character

	cmpdw	dxax, bxdi
	jnz	10$
	tstdw	bxdi
	jz	10$
	decdw	dxax
10$:
	movdw	ss:[bp].VTR_start, dxax

	call	TR_RegionGetCharCount		;dxax = char count
	adddw	dxax, ss:[bp].VTR_start
	movdw	ss:[bp].VTR_end, dxax

	; if we have an empty range AND the text is non-empty then move back
	; a character

	cmpdw	dxax, ss:[bp].VTR_start
	jnz	20$
	tstdw	dxax
	jz	20$
	decdw	ss:[bp].VTR_start
20$:

	mov	dx, ss
	mov	ax, MSG_VIS_TEXT_INVALIDATE_RANGE
	call	ObjCallInstanceNoLock

	add	sp, size VisTextRange

	mov	ax, MSG_VIS_RECREATE_CACHED_GSTATES
	call	ObjCallInstanceNoLock

	mov	ax, mask VTNF_PARA_ATTR
	call	TA_SendNotification
	ret

VisLargeTextRegionChanged	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisLargeTextRegionFromPoint --
		MSG_VIS_LARGE_TEXT_REGION_FROM_POINT for VisLargeTextClass

DESCRIPTION:	Given a point, return the region in which it lies

PASS:
	*ds:si - instance data
	es - segment of VisLargeTextClass

	ax - The message

	ss:bp - PointDWFixed

RETURN:
	cx - region #
	ax - relative X position
	dx - relative y position

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/10/92		Initial version

------------------------------------------------------------------------------@
VisLargeTextRegionFromPoint	method dynamic	VisLargeTextClass,
					MSG_VIS_LARGE_TEXT_REGION_FROM_POINT
	call	LargeRegionFromPoint
	ret

VisLargeTextRegionFromPoint	endm



	SetGeosConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MsgVisLargeTextRegionFromPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	MsgVisLargeTextRegionFromPoint

	call vltObj::MSG_VIS_LARGE_TEXT_REGION_FROM_POINT();

C DECLARATION:

extern void
    _pascal MsgVisLargeTextRegionFromPoint(
			VisLargeTextRegionFromPointParams *retValue,
			optr object,
			PointDWFixed point);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cassie	1/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global MSGVISLARGETEXTREGIONFROMPOINT:far
MSGVISLARGETEXTREGIONFROMPOINT	proc far \
				retVal:fptr.VisLargeTextRegionFromPointParams,
				object:optr,
				point:PointDWFixed
		uses	ds,si, es,di
		.enter
	;
	; @call object::MSG_VIS_LARGE_TEXT_REGION_FROM_POINT()
	;
		movdw	bxsi, ss:[object]
		mov	ax, MSG_VIS_LARGE_TEXT_REGION_FROM_POINT

		push	bp
		lea	bp, ss:[point]
		mov	di, mask MF_CALL or mask MF_STACK
		call	ObjMessage
		pop	bp
	;
	; Setup return values
	;
		lds	si, ss:[retVal]
		mov	ds:[si].VLTRFPP_region, cx
		mov	ds:[si].VLTRFPP_xPosition, ax
		mov	ds:[si].VLTRFPP_yPosition, dx

		.leave
		ret
MSGVISLARGETEXTREGIONFROMPOINT	endp

	SetDefaultConvention


TextRegion ends
