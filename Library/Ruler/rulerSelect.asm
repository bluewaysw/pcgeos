COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		rulerSelect.asm

AUTHOR:		Jon Witort

METHODS:
	Name			Description
	----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12 feb 1991	initial perversion

DESCRIPTION:
	
	$Id: rulerSelect.asm,v 1.1 97/04/07 10:42:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerBasicCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerGainedSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:

	Notify the ruler that its ruled object is "selected" and that the
	ruler should update the UI to reflect its own attributes

	Also registers the passed invalAD as the AD it should send out
	whenever the ruled object needs to redraw itself (as a result
	of a change in grid spacing, addition of a guideline, etc.)

PASS:		*ds:si	= VisRuler object
		ds:di	= VisRuler instance

		^lcx:dx = Object to send inval messages to

RETURN:		nothing

DESTROYED:	ax 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12 feb 1991	initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerGainedSelection	method	VisRulerClass, MSG_VIS_RULER_GAINED_SELECTION
	.enter

	movdw	ds:[di].VRI_invalOD, cxdx

	mov	ax, MSG_VIS_RULER_UPDATE_CONTROLLERS
	call	ObjCallInstanceNoLock

	.leave
	ret
VisRulerGainedSelection	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerLostSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:

	Notify the ruler that its ruled object is "selected" and that the
	ruler should update the UI to reflect its own attributes

	Also registers the passed invalAD as the AD it should send out
	whenever the ruled object needs to redraw itself (as a result
	of a change in grid spacing, addition of a guideline, etc.)

PASS:		*ds:si	= VisRuler object
		ds:di	= VisRuler instance

		^lcx:dx = Object to send inval messages to
		bp      = inval message

RETURN:		nothing

DESTROYED:	ax, bx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12 feb 1991	initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerLostSelection	method	VisRulerClass, MSG_VIS_RULER_LOST_SELECTION

	uses	cx, dx

	.enter

	clr	bx
	mov	ds:[di].VRI_invalOD.handle, bx
	mov	ds:[di].VRI_invalOD.chunk, bx

	mov	cx, GAGCNLT_APP_TARGET_NOTIFY_RULER_TYPE_CHANGE
	mov	dx, GWNT_RULER_TYPE_CHANGE
	call	UpdateControllerLow

	mov	cx, GAGCNLT_APP_TARGET_NOTIFY_RULER_GRID_CHANGE
	mov	dx, GWNT_RULER_TYPE_CHANGE
	call	UpdateControllerLow

	mov	cx, GAGCNLT_APP_TARGET_NOTIFY_RULER_GUIDE_CHANGE
	mov	dx, GWNT_RULER_TYPE_CHANGE
	call	UpdateControllerLow

	.leave
	ret
VisRulerLostSelection	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerUpdateControllers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_UPDATE_CONTROLLERS

Called by:	

Pass:		*ds:si = VisRuler object
		ds:di = VisRuler instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 13, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerUpdateControllers	method	VisRulerClass, MSG_VIS_RULER_UPDATE_CONTROLLERS
	.enter

	mov	ax, MSG_VIS_RULER_UPDATE_TYPE_CONTROLLER
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_RULER_UPDATE_GRID_CONTROLLER
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_RULER_UPDATE_GUIDE_CONTROLLER
	call	ObjCallInstanceNoLock

	.leave
	ret
VisRulerUpdateControllers	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerUpdateTypeController
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_UPDATE_TYPE_CONTROLLER

Called by:	

Pass:		*ds:si = VisRuler object
		ds:di = VisRuler instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 13, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerUpdateTypeController	method dynamic	VisRulerClass,
				MSG_VIS_RULER_UPDATE_TYPE_CONTROLLER

	uses	cx, dx

	.enter

	mov	ax, MSG_VIS_RULER_GET_TYPE
	call	ObjCallInstanceNoLock

	mov	bx, size RulerTypeNotificationBlock
	call	AllocNotifyBlock

	push	ds
	call	MemLock
	mov	ds, ax
	mov	ds:[RTNB_type], cl
	call	MemUnlock
	pop	ds

	mov	cx, GAGCNLT_APP_TARGET_NOTIFY_RULER_TYPE_CHANGE
	mov	dx, GWNT_RULER_TYPE_CHANGE
	call	UpdateControllerLow

	.leave
	ret
VisRulerUpdateTypeController	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerUpdateGridController
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_UPDATE_GRID_CONTROLLER

Called by:	

Pass:		*ds:si = VisRuler object
		ds:di = VisRuler instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 13, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerUpdateGridController	method dynamic	VisRulerClass,
				MSG_VIS_RULER_UPDATE_GRID_CONTROLLER

	uses	cx, dx

	.enter

	;
	;	dxcx <- x spacing
	;	bpax <- y spacing
	;
	mov	ax, MSG_VIS_RULER_GET_GRID_SPACING
	call	ObjCallInstanceNoLock
	mov	bp, cx					;dxbp <- x spacing

	;
	;	cx <- VisRulerConstrainStategy
	;
	mov	ax, MSG_VIS_RULER_GET_CONSTRAIN_STRATEGY
	call	ObjCallInstanceNoLock

	clr	al					;init GridOptions
	test	cx, VRCS_SNAP_TO_GRID_ABSOLUTE
	jz	checkShowGrid

	or	al, mask GO_SNAP_TO_GRID

checkShowGrid:
	mov	di, ds:[si]
	add	di, ds:[di].VisRuler_offset
	test	ds:[di].VRI_rulerAttrs, mask VRA_SHOW_GRID
	jz	saveOpts

	or	al, mask GO_SHOW_GRID

saveOpts:
	push	ax					;save GridOptions

	mov	cx, size RulerGridNotificationBlock
	call	AllocNotifyBlock

	pop	cx					;cl <- GridOptions

	push	ds
	call	MemLock
	mov	ds, ax
	movwwf	ds:[RGNB_gridSpacing], dxbp
	mov	ds:[RGNB_gridOptions], cl
	call	MemUnlock
	pop	ds

	mov	cx, GAGCNLT_APP_TARGET_NOTIFY_RULER_GRID_CHANGE
	mov	dx, GWNT_RULER_GRID_CHANGE
	call	UpdateControllerLow

	.leave
	ret
VisRulerUpdateGridController	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerUpdateGuideController
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_UPDATE_GUIDE_CONTROLLER

Called by:	

Pass:		*ds:si = VisRuler object
		ds:di = VisRuler instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 13, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerUpdateGuideController	method dynamic	VisRulerClass,
				MSG_VIS_RULER_UPDATE_GUIDE_CONTROLLER
	.enter

	;
	;  If we're not the master, then we can't do this update
	;
	test	ds:[di].VRI_rulerAttrs, mask VRA_MASTER
	jz	done

	mov	ax, LMEM_TYPE_GENERAL
	mov	cx, size VisRulerNotifyGuideChangeBlockHeader
	call	AllocLMemNotifyBlock

	call	MemLock
	mov	es, ax
	clr	es:[VRNGCBH_vertGuideArray]
	clr	es:[VRNGCBH_horizGuideArray]
	call	MemUnlock

	mov	cx, bx

	mov	ax, MSG_VIS_RULER_COMBINE_GUIDE_INFO
	call	ObjCallInstanceNoLock

	mov	cx, GAGCNLT_APP_TARGET_NOTIFY_RULER_GUIDE_CHANGE
	mov	dx, GWNT_RULER_GUIDE_CHANGE
	call	UpdateControllerLow

done:
	.leave
	ret
VisRulerUpdateGuideController	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisRulerCombineGuideInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisRuler method for MSG_VIS_RULER_COMBINE_GUIDE_INFO

Called by:	

Pass:		*ds:si = VisRuler object
		ds:di = VisRuler instance

		cx - data block

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 13, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisRulerCombineGuideInfo	method dynamic	VisRulerClass,
				MSG_VIS_RULER_COMBINE_GUIDE_INFO
	uses	cx, bp
	.enter


	mov	bp, si					;bp <- obj chunk
	call	LockGuideArray
	xchg	bp, si					;*ds:si <- VisRuler,
							;ax:bp <- guides
	LONG jnc sendToSlave

	push	ds, si, bp, bx				;save ruler, message, 
							; guide block
	push	{word} ds:[di].VRI_rulerAttrs
	pushdwf	ds:[di].VRI_origin
	push	cx					;save notify block
	mov	es, ax
	ChunkSizeHandle		es, bp, cx

	test	ds:[di].VRI_rulerAttrs, mask VRA_HORIZONTAL	
	mov	di, offset VRNGCBH_vertGuideArray
	jnz	allocChunk
	mov	di, offset VRNGCBH_horizGuideArray

allocChunk:
	pop	bx					;bx <- notify block
	call	MemLock
	mov	ds, ax
	mov	al, mask OCF_IGNORE_DIRTY
	call	LMemAlloc

	mov	ds:[di], ax				;save chunk handle

	;
	;  Copy the chunk array into our new chunk
	;

	segxchg	ds, es
	mov	si, bp	
	mov	si, ds:[si]
	mov_tr	di, ax
	mov	di, es:[di]
	push	di					;save array
	shr	cx
	jnc	moveWords
	movsb
moveWords:
	rep movsw
	pop	di					;es:di = array
	popdwf	dxaxsi					;dxaxsi = origin
	pop	cx
	test	cl, mask VRA_IGNORE_ORIGIN
	jnz	afterAdjust

	; adjust all guides by VRI_origin

	mov	cx, es:[di].CAH_count
	jcxz	afterAdjust
	add	di, es:[di].CAH_offset
adjustLoop:
	subdwf	es:[di], dxaxsi
	add	di, size DWFixed
	loop	adjustLoop
afterAdjust:

	call	MemUnlock
	mov	cx, bx					;cx <- combine block
	pop	ds, si, ax, bx				;*ds:si <- ruler
							;ax <- message #
							;bx <- guide block
	call	MemUnlock

sendToSlave:
	mov	ax, MSG_VIS_RULER_COMBINE_GUIDE_INFO
	call	RulerCallSlave

	.leave
	ret
VisRulerCombineGuideInfo	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateControllerLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low-level routine to update a UI controller

CALLED BY:

PASS:		bx - Data block to send to controller, or 0 to send
		null data (on LOST_SELECTION) 
		cx - GenAppGCNListType
		dx - NotifyStandardNotificationTypes

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/30/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateControllerLow	proc near	
	uses	ax,bx,cx,dx,di,si,bp
	.enter

	; create the event

	call	MemIncRefCount			;one more reference
	push	bx, cx, si
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	bp, bx				; data block
	clr	bx, si
	mov	di, mask MF_RECORD
	call	ObjMessage			; di is event
	pop	bx, cx, si

	; Create messageParams structure on stack

	mov	dx, size GCNListMessageParams	; create stack frame
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, cx
	push	bx				; data block
	mov	ss:[bp].GCNLMP_block, bx
	mov	ss:[bp].GCNLMP_event, di
	
	; If data block is null, then set the IGNORE flag, otherwise
	; just set the SET_STATUS_EVENT flag

	mov	ax,  mask GCNLSF_SET_STATUS
	tst	bx
	jnz	gotFlags
	ornf	ax, mask GCNLSF_IGNORE_IF_STATUS_TRANSITIONING
gotFlags:
	mov	ss:[bp].GCNLMP_flags, ax
	mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
	mov	bx, ds:[LMBH_handle]
	call	MemOwner			; bx <- owner
	clr	si

	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx				; data block
	
	add	sp, size GCNListMessageParams	; fix stack
	call	MemDecRefCount			; we're done with it 
	.leave
	ret
UpdateControllerLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocNotifyBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate the block of memory that will be used to
		update the UI.

CALLED BY:

PASS:		bx - size to allocate

RETURN:		bx - block handle
		carry set if unable to allocate

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
	Initialize to zero 	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocNotifyBlock	proc near	
	uses	ax, cx
	.enter
	mov	ax, bx			; size
	mov	cx, ALLOC_DYNAMIC or mask HF_SHARABLE or \
			(mask HAF_ZERO_INIT) shl 8
	call	MemAlloc
	jc	done
	mov	ax, 1
	call	MemInitRefCount
	clc
done:
	.leave
	ret
AllocNotifyBlock	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	AllocLMemNotifyBlock

DESCRIPTION:	Utility routine to allocate a block with a local memory heap
		that can be used for notification purposes

CALLED BY:	GLOBAL

PASS:
	ax - type of heap (LMemType)
	cx - size of block header (or 0 for default)

RETURN:
	bx - block handle:
		lmem handles - 2 (the minimum)
		lmem heap space - 64 bytes

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	24 sept 92	initial revision
------------------------------------------------------------------------------@
AllocLMemNotifyBlock	proc	near
	uses ax
	.enter

	call	MemAllocLMem
	mov	ax, mask HF_SHARABLE		;make it sharable
	call	MemModifyFlags
	mov	ax, 1
	call	MemInitRefCount

	.leave
	ret

AllocLMemNotifyBlock	endp

RulerBasicCode ends
