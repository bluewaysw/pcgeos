COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		documentFlow.asm

ROUTINES:
	Name			Description
	----			-----------
    INT FlowDrawHorizBumpedUp	Draw the flow region

    INT LoadHoriz		Draw the flow region

    INT FlowDrawHorizBumpedDown Draw the flow region

    INT FlowDrawVertBumpedLeft	Draw the flow region

    INT LoadVert		Draw the flow region

    INT FlowDrawVertBumpedRight Draw the flow region

METHODS:
	Name			Description
	----			-----------
    FlowRegionBecomeSelected	Filter requests to become selected

				MSG_GO_BECOME_SELECTED,
				MSG_GO_INVERT_HANDLES

				FlowRegionClass

    FlowRegionDrawFG		Draw the flow region

				MSG_GO_DRAW_FG_LINE,
				MSG_GO_DRAW_FG_LINE_HI_RES
				FlowRegionClass

    FlowRegionGetBoundingRectDWFixed  
				Calculate the bounding rect

				MSG_GO_GET_BOUNDING_RECTDWFIXED
				FlowRegionClass

    FlowRegionInitialize	Initialize the object

				MSG_META_INITIALIZE
				FlowRegionClass

    FlowRegionInitToDefaultAttrs  
				Init the object to the default attributes

				MSG_GO_INIT_TO_DEFAULT_ATTRS
				FlowRegionClass

    FlowRegionNotifyAction	Handle notification that the object has
				been acted upon

				MSG_GO_NOTIFY_ACTION
				FlowRegionClass

    FlowRegionSetAssociation	Set the associated master page and article
				block

				MSG_FLOW_REGION_SET_ASSOCIATION
				FlowRegionClass

    FlowRegionSetDrawRegion	Set the draw region

				MSG_FLOW_REGION_SET_DRAW_REGION
				FlowRegionClass

    FlowRegionWriteInstanceToTransfer  
				Write our instance data to the transfer
				item

				MSG_GO_WRITE_INSTANCE_TO_TRANSFER
				FlowRegionClass

    FlowRegionReadInstanceFromTransfer  
				Read our instance data from the transfer
				item

				MSG_GO_READ_INSTANCE_FROM_TRANSFER
				FlowRegionClass

    FlowRegionClearNoNotify	Destroy ourselves without notifying the
				document

				MSG_FLOW_REGION_CLEAR_NO_NOTIFY
				FlowRegionClass

    FlowRegionChangeLocks	Change the locks

				MSG_GO_CHANGE_LOCKS
				FlowRegionClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the code for FlowRegionClass

	$Id: documentFlow.asm,v 1.1 97/04/04 14:38:42 newdeal Exp $

------------------------------------------------------------------------------@

idata segment
	FlowRegionClass
idata ends

DocDrawScroll segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	FlowRegionBecomeSelected -- MSG_GO_BECOME_SELECTED
						for FlowRegionClass

DESCRIPTION:	Filter requests to become selected

PASS:
	*ds:si - instance data
	es - segment of FlowRegionClass

	ax - The message

	dl - HandleUpdateMode

RETURN:
	cx, dx, bp - preserved

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/24/92		Initial version

------------------------------------------------------------------------------@
FlowRegionBecomeSelected	method dynamic	FlowRegionClass,
						MSG_GO_BECOME_SELECTED,
						MSG_GO_INVERT_HANDLES

	push	ax
	call	GetAppFeatures
	test	ax, mask SF_COMPLEX_PAGE_LAYOUT
	pop	ax
	jz	done

	mov	di, offset FlowRegionClass
	call	ObjCallSuperNoLock
done:
	ret

FlowRegionBecomeSelected	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	FlowRegionDrawFG -- MSG_GOA_DRAW_FG for FlowRegionClass

DESCRIPTION:	Draw the flow region

PASS:
	*ds:si - instance data
	es - segment of FlowRegionClass

	ax - The message

	cl - DrawFlags
	dx - gstate to draw through

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/24/92		Initial version

------------------------------------------------------------------------------@
FlowRegionDrawFG	method dynamic	FlowRegionClass, MSG_GO_DRAW_FG_LINE,
						MSG_GO_DRAW_FG_LINE_HI_RES
					uses cx, dx
nudgeX		local	word
nudgeY		local	word
bounds		local	Rectangle
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>

	call	GrObjGetCurrentNudgeUnits	;ax, bx = nudge (BBFixed)
	add	ax, 0x80			;round up
	mov	al, ah
	clr	ah
	mov	nudgeX, ax
	add	bx, 0x80			;round up
	mov	bl, bh
	clr	bh
	mov	nudgeY, bx

	; get the bounds

	call	GrObjGetNormalOBJECTDimensions	;dxcx = width, bxax = height
	call	GrObjCalcCorners		;ax, bx, cx, dx = bounds (from
						;center)
	mov	bounds.R_left, ax
	mov	bounds.R_top, bx
	mov	bounds.R_right, cx
	mov	bounds.R_bottom, dx

	; see if we have a draw region

	mov	bx, ds:[si]
	add	bx, ds:[bx].GrObj_offset
	movdw	cxdx, ds:[bx].FRI_drawRegion
	tst	cx
	jnz	useDrawRegion

	; transform by ax, bx
	; ax, bx <- 0, cx, dx <- subtract

	mov	ax, bounds.R_left
	mov	bx, bounds.R_top
	mov	cx, bounds.R_right
	mov	dx, bounds.R_bottom

	; bump out edges.  We need to bump out the right and bottom one less
	; since they will be naturally bumped out by the way that the graphics
	; system draws lines.

	dec	cx
	dec	dx
	sub	ax, nudgeX
	sub	bx, nudgeY
	add	cx, nudgeX
	add	dx, nudgeY

	call	GrDrawRect
	jmp	done

	; a draw region (list of commands) exists for this region -- use it

	; cxdx = region, di = gstate

useDrawRegion:
	push	di
	mov	bx, ds:[LMBH_handle]
	mov	ax, MGIT_OWNER_OR_VM_FILE_HANDLE
	call	MemGetInfo			;ax = VM file
	mov_tr	bx, ax
	movdw	axdi, cxdx
	call	DBLock				;*es:di = data
	segmov	ds, es
	mov	si, ds:[di]			;ds:si = data
	pop	di				;di = gstate

	ChunkSizePtr	ds, si, cx		;cx = size

drawLoop:
	push	cx

	mov	bl, ds:[si].FDRE_command
	and	bx, mask FDRC_OP
	shl	bx
	call	cs:[bx].flowDrawRoutines

	pop	cx
	add	si, size FlowDrawRegionElement
	sub	cx, size FlowDrawRegionElement
	jnz	drawLoop

	call	DBUnlock

done:
	.leave
	ret

FlowRegionDrawFG	endm

;---

flowDrawRoutines	nptr	\
	FlowDrawHorizBumpedUp,		; FDRC_HORIZ_LINE_BUMPED_UP
	FlowDrawHorizBumpedDown,	; FDRC_HORIZ_LINE_BUMPED_DOWN
	FlowDrawVertBumpedLeft,		; FDRC_VERT_LINE_BUMPED_LEFT
	FlowDrawVertBumpedRight		; FDRC_VERT_LINE_BUMPED_RIGHT

FlowDrawHorizBumpedUp	proc	near
	.enter inherit FlowRegionDrawFG
	call	LoadHoriz
	sub	bx, nudgeY
	call	GrDrawHLine
	.leave
	ret
FlowDrawHorizBumpedUp	endp

LoadHoriz	proc	near
	.enter inherit FlowRegionDrawFG
	mov	ax, ds:[si].FDRE_coords.FDRC_horiz.FDHC_x1
	mov	cx, ds:[si].FDRE_coords.FDRC_horiz.FDHC_x2
	mov	bx, ds:[si].FDRE_coords.FDRC_horiz.FDHC_y
	add	ax, bounds.R_left
	add	cx, bounds.R_left
	add	bx, bounds.R_top
	sub	ax, nudgeX
	test	ds:[si].FDRE_command, mask FDRC_BUMP_START_IN
	jz	10$
	add	ax, nudgeX
	add	ax, nudgeX
10$:
	add	cx, nudgeX
	test	ds:[si].FDRE_command, mask FDRC_BUMP_END_IN
	jz	20$
	sub	cx, nudgeX
	sub	cx, nudgeX
20$:
	.leave
	ret
LoadHoriz	endp

;---

FlowDrawHorizBumpedDown	proc	near
	.enter inherit FlowRegionDrawFG
	call	LoadHoriz

	; bump down one less since the line will be naturally bumped out by the
	; way that the graphics system draws lines

	dec	bx
	add	bx, nudgeY

	call	GrDrawHLine
	.leave
	ret
FlowDrawHorizBumpedDown	endp

;---

FlowDrawVertBumpedLeft	proc	near
	.enter inherit FlowRegionDrawFG
	call	LoadVert
	sub	ax, nudgeX
	call	GrDrawVLine
	.leave
	ret
FlowDrawVertBumpedLeft	endp

LoadVert	proc	near
	.enter inherit FlowRegionDrawFG
	mov	bx, ds:[si].FDRE_coords.FDRC_vert.FDVC_y1
	mov	dx, ds:[si].FDRE_coords.FDRC_vert.FDVC_y2
	mov	ax, ds:[si].FDRE_coords.FDRC_vert.FDVC_x
	add	bx, bounds.R_top
	add	dx, bounds.R_top
	add	ax, bounds.R_left
	sub	bx, nudgeY
	test	ds:[si].FDRE_command, mask FDRC_BUMP_START_IN
	jz	10$
	add	bx, nudgeY
	add	bx, nudgeY
10$:
	add	dx, nudgeY
	test	ds:[si].FDRE_command, mask FDRC_BUMP_END_IN
	jz	20$
	sub	dx, nudgeY
	sub	dx, nudgeY
20$:
	.leave
	ret
LoadVert	endp

;---

FlowDrawVertBumpedRight	proc	near
	.enter inherit FlowRegionDrawFG
	call	LoadVert

	; bump out one less since the line will be naturally bumped out by the
	; way that the graphics system draws lines

	dec	ax
	add	ax, nudgeX

	call	GrDrawVLine
	.leave
	ret
FlowDrawVertBumpedRight	endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	FlowRegionGetBoundingRectDWFixed --
		MSG_GO_GET_BOUNDING_RECTDWFIXED for FlowRegionClass

DESCRIPTION:	Calculate the bounding rect

PASS:
	*ds:si - instance data
	es - segment of FlowRegionClass

	ax - The message

	ss:bp - BoundingRectData

RETURN:

DESTROYED:
	ax
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/14/92		Initial version

------------------------------------------------------------------------------@
FlowRegionGetBoundingRectDWFixed	method dynamic	FlowRegionClass,
					MSG_GO_GET_BOUNDING_RECTDWFIXED

	mov	di, offset FlowRegionClass
	call	ObjCallSuperNoLock

	subdw	ss:[bp].BRD_rect.RDWF_left.DWF_int, FLOW_REGION_BOUNDS_BUMP
	subdw	ss:[bp].BRD_rect.RDWF_top.DWF_int, FLOW_REGION_BOUNDS_BUMP
	adddw	ss:[bp].BRD_rect.RDWF_right.DWF_int, FLOW_REGION_BOUNDS_BUMP
	adddw	ss:[bp].BRD_rect.RDWF_bottom.DWF_int, FLOW_REGION_BOUNDS_BUMP

	ret

FlowRegionGetBoundingRectDWFixed	endm

DocDrawScroll ends

DocPageCreDest segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	FlowRegionInitialize -- MSG_META_INITIALIZE for FlowRegionClass

DESCRIPTION:	Initialize the object

PASS:
	*ds:si - instance data
	es - segment of FlowRegionClass

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
	Tony	9/15/92		Initial version

------------------------------------------------------------------------------@
FlowRegionInitialize	method dynamic	FlowRegionClass, MSG_META_INITIALIZE

	mov	di, offset FlowRegionClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].GrObj_offset
	ornf	ds:[di].GOI_msgOptFlags, mask GOMOF_NOTIFY_ACTION

	ret

FlowRegionInitialize	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	FlowRegionInitToDefaultAttrs -- MSG_GO_INIT_TO_DEFAULT_ATTRS
							for FlowRegionClass

DESCRIPTION:	Init the object to the default attributes

PASS:
	*ds:si - instance data
	es - segment of FlowRegionClass

	ax - The message

RETURN:
	cx, dx, bp - unchanged

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/28/92		Initial version

------------------------------------------------------------------------------@
FlowRegionInitToDefaultAttrs	method dynamic	FlowRegionClass,
						MSG_GO_INIT_TO_DEFAULT_ATTRS
	mov	di, offset FlowRegionClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].GrObj_offset
			CheckHack <GOWTT_DONT_WRAP eq 0>
	andnf	ds:[di].GOI_attrFlags, not mask GOAF_WRAP

	ret

FlowRegionInitToDefaultAttrs	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	FlowRegionNotifyAction -- MSG_GO_NOTIFY_ACTION
							for FlowRegionClass

DESCRIPTION:	Handle notification that the object has been acted upon

PASS:
	*ds:si - instance data
	es - segment of FlowRegionClass

	ax - The message

	bp - GrObjActionNotificationType

RETURN:
	bp - data

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
FlowRegionNotifyAction	method dynamic	FlowRegionClass, MSG_GO_NOTIFY_ACTION

	tst	es:[suspendNotification]
	jnz	done

	; tell the document what has happened (if it is anything that
	; we care about)

	mov	ax, GOANT_DELETED		;ax = notification to send on
	cmp	bp, GOANT_REDO_DELETE
	jz	sendNotification
	mov	ax, GOANT_PASTED
	cmp	bp, GOANT_UNDO_DELETE
	jz	sendNotification
	mov	ax, GOANT_RESIZED
	cmp	bp, GOANT_UNDO_GEOMETRY
	jz	sendNotification

	mov_tr	ax, bp
	cmp	ax, GOANT_DELETED
	jz	sendNotification
	cmp	ax, GOANT_PASTED
	jz	sendNotification
	cmp	ax, GOANT_QUERY_DELETE
	jz	sendNotification
	cmp	ax, GOANT_MOVED
	jz	sendNotification
	cmp	ax, GOANT_RESIZED
	jnz	done

sendNotification:

	mov	bx, di
	mov	di, 1300
	call	ThreadBorrowStackSpace
	push	di
	mov	di, bx

	; push FlowRegionChangedParams

			CheckHack <offset FRCP_article eq 8>
	push	ds:[di].FRI_article
			CheckHack <offset FRCP_masterPage eq 6>
	push	ds:[di].FRI_masterPage
			CheckHack <offset FRCP_object eq 2>
	push	ds:[LMBH_handle], si
			CheckHack <offset FRCP_action eq 0>
	push	ax
	mov	bp, sp

	mov	bx, segment GenDocumentClass
	mov	si, offset GenDocumentClass
	mov	ax, MSG_STUDIO_DOCUMENT_FLOW_REGION_CHANGED
	mov	dx, size FlowRegionChangedParams
	mov	di, mask MF_RECORD or mask MF_STACK
	call	ObjMessage			;di = message

	add	sp, size FlowRegionChangedParams

	mov	cx, di
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	ObjBlockGetOutput
	mov	di, mask MF_CALL
	call	ObjMessage

	pop	di
	call	ThreadReturnStackSpace

done:
	ret

FlowRegionNotifyAction	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	FlowRegionSetAssociation -- MSG_FLOW_REGION_SET_ASSOCIATION
							for FlowRegionClass

DESCRIPTION:	Set the associated master page and article block

PASS:
	*ds:si - instance data
	es - segment of FlowRegionClass

	ax - The message

	cx - master page
	dx - article

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
FlowRegionSetAssociation	method dynamic	FlowRegionClass,
						MSG_FLOW_REGION_SET_ASSOCIATION

	mov	ds:[di].FRI_masterPage, cx
	mov	ds:[di].FRI_article, dx
	call	ObjMarkDirty
	ret

FlowRegionSetAssociation	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	FlowRegionSetDrawRegion -- MSG_FLOW_REGION_SET_DRAW_REGION
							for FlowRegionClass

DESCRIPTION:	Set the draw region

PASS:
	*ds:si - instance data
	es - segment of FlowRegionClass

	ax - The message

	cxdx - draw region (db item)

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/21/92		Initial version

------------------------------------------------------------------------------@
FlowRegionSetDrawRegion	method dynamic	FlowRegionClass,
						MSG_FLOW_REGION_SET_DRAW_REGION
	movdw	ds:[di].FRI_drawRegion, cxdx
	call	ObjMarkDirty
	ret

FlowRegionSetDrawRegion	endm

DocPageCreDest ends

DocRegion segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	FlowRegionWriteInstanceToTransfer --
			MSG_GO_WRITE_INSTANCE_TO_TRANSFER for FlowRegionClass

DESCRIPTION:	Write our instance data to the transfer item

PASS:
	*ds:si - instance data
	es - segment of FlowRegionClass

	ax - The message

	ss:bp - GrObjTransferParams

RETURN:
	ss:[bp].GTP_curPos - updated to just past the last written data

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/13/92		Initial version

------------------------------------------------------------------------------@
FlowRegionWriteInstanceToTransfer	method dynamic	FlowRegionClass,
					MSG_GO_WRITE_INSTANCE_TO_TRANSFER

	push	ds:[di].FRI_masterPage, ds:[di].FRI_article

	mov	di, offset FlowRegionClass
	call	ObjCallSuperNoLock

	add	ss:[bp].GTP_curSize, size FlowRegionTransferData

	mov	bx, ss:[bp].GTP_vmFile
	movdw	axdi, ss:[bp].GTP_id

	mov	cx, ss:[bp].GTP_curSize
	call	DBReAlloc
	call	DBLock				;*es:di = data
	mov	di, es:[di]
	add	di, ss:[bp].GTP_curPos		;es:di = data to write
	pop	es:[di].FRTD_masterPage, es:[di].FRTD_article
	call	DBDirty
	call	DBUnlock

	add	ss:[bp].GTP_curPos, size FlowRegionTransferData

	ret

FlowRegionWriteInstanceToTransfer	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	FlowRegionReadInstanceFromTransfer --
			MSG_GO_READ_INSTANCE_FROM_TRANSFER for FlowRegionClass

DESCRIPTION:	Read our instance data from the transfer item

PASS:
	*ds:si - instance data
	es - segment of FlowRegionClass

	ax - The message

	ss:bp - GrObjTransferParams

RETURN:
	ss:[bp].GTP_curPos - updated to just past the last written data

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/13/92		Initial version

------------------------------------------------------------------------------@
FlowRegionReadInstanceFromTransfer	method dynamic	FlowRegionClass,
					MSG_GO_READ_INSTANCE_FROM_TRANSFER

	mov	di, offset FlowRegionClass
	call	ObjCallSuperNoLock

	; read in our data

	mov	si, ds:[si]
	add	si, ds:[si].GrObj_offset

	mov	bx, ss:[bp].GTP_vmFile
	movdw	axdi, ss:[bp].GTP_id

	call	DBLock				;*es:di = data
	mov	di, es:[di]
	add	di, ss:[bp].GTP_curPos		;es:di = data to write
	mov	ax, es:[di].FRTD_masterPage
	mov	ds:[si].FRI_masterPage, ax
	mov	ax, es:[di].FRTD_article
	mov	ds:[si].FRI_article, ax
	call	DBUnlock

	add	ss:[bp].GTP_curPos, size FlowRegionTransferData

	ret

FlowRegionReadInstanceFromTransfer	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlowRegionClearNoNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Destroy ourselves without notifying the document

PASS:		*ds:si	- FlowRegionClass object
		ds:di	- FlowRegionClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/ 7/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FlowRegionClearNoNotify	method	dynamic	FlowRegionClass, 
					MSG_FLOW_REGION_CLEAR_NO_NOTIFY

		call	SuspendFlowRegionNotifications
		mov	ax, MSG_GO_CLEAR
		call	ObjCallInstanceNoLock
		call	UnsuspendFlowRegionNotifications
		.leave
		ret
FlowRegionClearNoNotify	endm


DocRegion ends

DocCreate segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	FlowRegionChangeLocks -- MSG_GO_CHANGE_LOCKS for FlowRegionClass

DESCRIPTION:	Change the locks

PASS:
	*ds:si - instance data
	es - segment of FlowRegionClass

	ax - The message

	cx - GrObjLocks - bits to set
	dx - GrObjLocks - bits to clear

RETURN:
	cx, dx, bp - unchanged

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/22/92		Initial version

------------------------------------------------------------------------------@
FlowRegionChangeLocks	method dynamic	FlowRegionClass, MSG_GO_CHANGE_LOCKS

	; don't ever allow the SHOW lock to be set

	and	cx, not mask GOL_SHOW

	mov	di, offset FlowRegionClass
	GOTO	ObjCallSuperNoLock

FlowRegionChangeLocks	endm


DocCreate ends
