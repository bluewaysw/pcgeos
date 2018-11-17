COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Chart Library
FILE:		cbodyUI.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/16/91	Initial Revision 

DESCRIPTION:


	$Id: cbodyUI.asm,v 1.1 97/04/04 17:48:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartBodyUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Query each of the selected charts for their
		attributes, and update the UI appropriately.

PASS:		*ds:si - ChartBody
		ds:di - ChartBody
		cx - ChartUpdateUIFlags
		
RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/30/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartBodyUpdateUI	method dynamic ChartBodyClass,
				MSG_CHART_BODY_UPDATE_UI

	uses	ax,cx,dx,bp
	.enter

	tst	ds:[di].GBI_suspendCount
	jz	goAhead

	ornf	ds:[di].CBI_unSuspendFlags, cx
	jmp	done

goAhead:

	clr	bp

startLoop:
	; push the next bit off the face of the earth
	shr	cx, 1
	push	cx
	jnc	nextOne

	; Send the event to the chart objects that will combine the
	; notification data. 

	mov	ax, cs:[UpdateTable][bp].UTE_message
	mov	bx, cs:[UpdateTable][bp].UTE_size
	mov	cx, cs:[UpdateTable][bp].UTE_class.segment
	mov	dx, cs:[UpdateTable][bp].UTE_class.offset


	call	SendCombineEvent
	jc	nextOne

	;
	; Now, update the UI controller
	;

	mov	cx, cs:[UpdateTable][bp].UTE_gcnListType
	mov	dx, cs:[UpdateTable][bp].UTE_notificationType
	call	UpdateControllerLow

nextOne:
	pop	cx
	add	bp, size UpdateTableEntry
	cmp	bp, size UpdateTable
	jl	startLoop

done:
	.leave
	ret
ChartBodyUpdateUI	endm


; WARNING: This table is in the OPPOSITE order of the flags to which
; it corresponds

UpdateTable	UpdateTableEntry	\
\
	<MSG_CHART_GROUP_COMBINE_CHART_TYPE,
	 size TypeNotificationBlock,
	 ChartGroupClass,
	 GAGCNLT_APP_TARGET_NOTIFY_CHART_TYPE_CHANGE,
	 GWNT_CHART_TYPE_CHANGE>,

	<MSG_CHART_GROUP_COMBINE_GROUP_FLAGS,
	 size GroupNotificationBlock,
	 ChartGroupClass,
	 GAGCNLT_APP_TARGET_NOTIFY_CHART_GROUP_FLAGS,
	 GWNT_CHART_GROUP_FLAGS>,

	<MSG_AXIS_COMBINE_NOTIFICATION_DATA,
	 size AxisNotificationBlock,
	 AxisClass,
	 GAGCNLT_APP_TARGET_NOTIFY_CHART_AXIS_ATTRIBUTES,
	 GWNT_CHART_AXIS_ATTRIBUTES>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendCombineEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the event to the selected chart groups

CALLED BY:

PASS:		ax - message to send
		bx - size of notification block
		cx:dx - class to send message to		
		*ds:si - ChartBody object

RETURN:		bx - handle of notification block, or 0 if none

DESTROYED:	es	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendCombineEvent	proc near	
	uses	ax,cx,dx,di
	.enter

	;
	; See if we have the target.  If not, return a NULL block
	;

	mov	di, ds:[si]
	add	di, ds:[di].GrObjBody_offset
	test	ds:[di].GBI_fileStatus, mask GOFS_TARGETED
	jz	notTarget


	call	AllocNotifyBlock
	jc	done

	xchg	bx, cx		; bx - class segment, cx -
				; notification block handle
	push	si
	mov	si, dx		; bx:si - class pointer
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si

	mov	bx, cx		; notify block header

	; Send message to all selected charts

	mov	cx, di		; event handle
	mov	dx, TO_TARGET
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	call	SendClassedEventToSelectedCharts

	; See if any objects responded.  If not, free the notify block

	call	MemLock
	mov	es, ax
	test	es:[CNBH_flags], mask CCF_FOUND
	call	MemUnlock
	jnz	done			; carry is clear
	call	MemFree
	clr	bx			; carry is clear
done:
	.leave
	ret

notTarget:
	clr	bx
	jmp	done

SendCombineEvent	endp



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




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateControllerLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low-level routine to update a UI controller

CALLED BY:

PASS:		bx - Data block to send to controller, or 0 to send
		null data (on LOST_SELECTION) 
		cx - GeoWorksGenAppGCNListType
		dx - GeoWorksNotificationType

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
	call	GeodeGetProcessHandle		; bx - process handle
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
		ChartBodySendClassedEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	If this event is for a chart object, then send it to
		all the selected children.

PASS:		*ds:si	= ChartBodyClass object
		ax      - MSG_META_SEND_CLASSED_EVENT
		cx	- event handle
		dx	- travel option


RETURN:		CARRY SET if classed event is handled here,
		CARRY CLEAR otherwise

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/26/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartBodySendClassedEvent	method	ChartBodyClass, 
					MSG_META_SEND_CLASSED_EVENT
	
	mov	bx, cx		; event handle
	push	ax, cx, si
	call	ObjGetMessageInfo

	;
	; See if the class of this event corresponds to the classes of
	; the chart objects
	;

	mov	si, es
	cmp	cx, si
	pop	ax, cx, si
	jne	sendToSuper

	call	SendClassedEventToSelectedCharts
	ret

sendToSuper:
	mov	di, offset ChartBodyClass
	GOTO	ObjCallSuperNoLock
ChartBodySendClassedEvent	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendClassedEventToSelectedCharts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send a classed event to selected chart groups.  Free
		the event when done

CALLED BY:	ChartBodySendClassedEvent, SendCombineEvent

PASS:		ax - MSG_META_SEND_CLASSED_EVENT
		cx - message handle
		dx - travel option

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendClassedEventToSelectedCharts	proc near
	uses	bx

	.enter

	mov	bx, offset SendClassedEventCB
	call	ChartBodyProcessChildren

	mov	bx, cx
	call	ObjFreeMessage

	.leave
	ret
SendClassedEventToSelectedCharts	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendClassedEventCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Duplicate and send the classed event if the group is
		selected.

CALLED BY:	SendClassedEventToSelectedCharts

PASS:		ax - MSG_META_SEND_CLASSED_EVENT
		cx - event handle
		dx - travel option
		*ds:si - ChartGroup object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendClassedEventCB	proc far

	class	ChartGroupClass

	uses	ax,cx,dx,bp

	.enter

	mov	di, ds:[si]
	tst	ds:[di].COI_selection
	jz	done
	
	push	ax
	mov	bx, cx
	call	ObjDuplicateMessage
	mov_tr	cx, ax			; duplicated message
	pop	ax
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
SendClassedEventCB	endp




