COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		sysbusy.asm

AUTHOR:		RON, Mar 20, 1996

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	3/20/96   	Initial revision


DESCRIPTION:
	
		

	$Id: sysbusy.asm,v 1.1 98/03/11 04:31:11 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
	SystemBusyClass
	busyTotal	word	0		; Sum of all SBI_busyCounts.
	busyCompArray 	optr	0		; Array of busy components.
idata	ends

;
; Number of busy components we can keep track of
;
udata	segment
udata	ends

makePropEntry busy, busyCount, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_SYSTEM_BUSY_GET_BUSY_COUNT>, \
	PDT_SEND_MESSAGE, <PD_message MSG_SYSTEM_BUSY_SET_BUSY_COUNT>

makePropEntry busy, busyTotal, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_SYSTEM_BUSY_GET_BUSY_TOTAL>, \
	PDT_SEND_MESSAGE, <PD_message MSG_SYSTEM_BUSY_SET_BUSY_TOTAL>


compMkPropTable SystemBusyProperty, busy, busyCount, busyTotal

makeActionEntry busy, Enter, MSG_SYSTEM_BUSY_ACTION_ENTER, LT_TYPE_VOID, 0
makeActionEntry busy, Leave, MSG_SYSTEM_BUSY_ACTION_LEAVE, LT_TYPE_VOID, 0

compMkActTable busy, Enter, Leave

MakeSystemPropRoutines SystemBusy, busy
MakeSystemActionRoutines SystemBusy, busy


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SystemBusyMetaResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the system know our real class tree. 

CALLED BY:	MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:		*ds:si	= SystemBusyClass object
		ds:di	= SystemBusyClass instance data
		ds:bx	= SystemBusyClass object (same as *ds:si)
		es 	= segment of SystemBusyClass
		ax	= message #
RETURN:		cx:dx	= fptr to class
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	3/20/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SystemBusyMetaResolveVariantSuperclass	method dynamic SystemBusyClass, 
					MSG_META_RESOLVE_VARIANT_SUPERCLASS
		
		compResolveSuperclass SystemBusy, ML2

SystemBusyMetaResolveVariantSuperclass	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SystemBusyMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear default bits on object

CALLED BY:	MSG_META_INITIALIZE
PASS:		*ds:si	= SystemBusyClass object
		ds:di	= SystemBusyClass instance data
		ds:bx	= SystemBusyClass object (same as *ds:si)
		es 	= segment of SystemBusyClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	3/20/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SystemBusyMetaInitialize	method dynamic SystemBusyClass, 
					MSG_META_INITIALIZE
		.enter
		mov	di, offset SystemBusyClass
		call	ObjCallSuperNoLock

		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset
	; clear the visual bits
		andnf	ds:[di].EI_state, not (mask ES_IS_GEN or mask ES_IS_VIS)
		.leave
		ret
SystemBusyMetaInitialize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SystemBusyEntGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_ENT_GET_CLASS
PASS:		*ds:si	= SystemBusyClass object
		ds:di	= SystemBusyClass instance data
		ds:bx	= SystemBusyClass object (same as *ds:si)
		es 	= segment of SystemBusyClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	3/20/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SystemBusyEntGetClass	method dynamic SystemBusyClass, 
					MSG_ENT_GET_CLASS
		.enter
		mov	cx, segment SystemBusyString
		mov	dx, offset SystemBusyString
		.leave
		ret
SystemBusyEntGetClass	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBGetBusyCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get this busy component's busyCount.

CALLED BY:	MSG_SYSTEM_BUSY_GET_BUSY_COUNT
PASS:		*ds:si	= SystemBusyClass object
		ds:di	= SystemBusyClass instance data
		ds:bx	= SystemBusyClass object (same as *ds:si)
		es 	= segment of SystemBusyClass
		ax	= message #
		ss:bp	= GetPropertyArgs
RETURN:		GetPropertyArgs filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 4/ 9/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBGetBusyCount	method dynamic SystemBusyClass, 
					MSG_SYSTEM_BUSY_GET_BUSY_COUNT
		.enter
	;
	; Stuff our busyCount into the return parameter.
	;
		les	bx, ss:[bp].GPA_compDataPtr
		Assert	fptr, esbx
		mov	ax, ds:[di].SBI_busyCount
		mov	es:[bx].CD_data.LD_integer, ax
		mov	es:[bx].CD_type, LT_TYPE_INTEGER

		.leave
		Destroy	ax, cx, dx
		ret
SBGetBusyCount	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBGetBusyTotal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the busyTotal global variable.

CALLED BY:	MSG_SYSTEM_BUSY_GET_BUSY_TOTAL
PASS:		*ds:si	= SystemBusyClass object
		ds:di	= SystemBusyClass instance data
		ds:bx	= SystemBusyClass object (same as *ds:si)
		es 	= segment of SystemBusyClass
		ax	= message #
		ss:bp	= GetPropertyArgs
RETURN:		GetPropertyArgs filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 4/ 9/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBGetBusyTotal	method dynamic SystemBusyClass, 
					MSG_SYSTEM_BUSY_GET_BUSY_TOTAL
		.enter
	;
	; Get the busyTotal global.
	;
		mov	ax, seg dgroup
		mov	es, ax
		mov	ax, es:[busyTotal]
		Assert	ge ax, 0
	;
	; Return it.
	;
		les	bx, ss:[bp].GPA_compDataPtr
		mov	es:[bx].CD_type, LT_TYPE_INTEGER
		mov	es:[bx].CD_data.LD_integer, ax
		Assert	ge ax, 0
		
		.leave
		Destroy	ax, cx, dx
		ret
SBGetBusyTotal	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBSetBusyCountOrTotal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	busyCount and busyTotal may not be set.  Return error!

CALLED BY:	MSG_SYSTEM_BUSY_SET_BUSY_COUNT
		MSG_SYSTEM_BUSY_SET_BUSY_TOTAL
PASS:		*ds:si	= SystemBusyClass object
		ds:di	= SystemBusyClass instance data
		ds:bx	= SystemBusyClass object (same as *ds:si)
		es 	= segment of SystemBusyClass
		ax	= message #
		ss:bp	= SetPropertyArgs
RETURN:		error: CPE_READONLY_PROPERTY
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 4/ 9/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBSetBusyCountOrTotal	method dynamic SystemBusyClass, 
					MSG_SYSTEM_BUSY_SET_BUSY_COUNT,
					MSG_SYSTEM_BUSY_SET_BUSY_TOTAL
		.enter

		mov	ax, CPE_READONLY_PROPERTY
		call	GadgetUtilReturnSetPropError
		
		.leave
		Destroy	ax, cx, dx
		ret
SBSetBusyCountOrTotal	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add ourself to the list of busy components.

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= SystemBusyClass object
		ds:di	= SystemBusyClass instance data
		ds:bx	= SystemBusyClass object (same as *ds:si)
		es 	= segment of SystemBusyClass
		ax	= message #
RETURN:		nothing (allocate busy component array if necessary)
DESTROYED:	ax, cx, dx, bp (since superclass destroys these)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/29/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBEntInitialize	method dynamic SystemBusyClass, 
					MSG_ENT_INITIALIZE
		.enter
	;
	; Let the superclass do its thing.
	;
		mov	di, offset SystemBusyClass
		call	ObjCallSuperNoLock
	;
	; Now do the interesting stuff!  Add ourself to the
	; array of busy components.
	;
		mov	ax, MSG_SYSTEM_BUSY_ADD_SELF_TO_BUSY_ARRAY
		call	ObjCallInstanceNoLock

		.leave
		Destroy	ax, cx, dx, bp
		ret
SBEntInitialize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBAddToBusyArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add ourself to the array of busy components.
		This message is only provided because we don't
		want BSystemBusy messing with the busy array.

CALLED BY:	MSG_SYSTEM_BUSY_ADD_SELF_TO_BUSY_ARRAY
PASS:		*ds:si	= SystemBusyClass object
		ds:di	= SystemBusyClass instance data
		ds:bx	= SystemBusyClass object (same as *ds:si)
		es 	= segment of SystemBusyClass
		ax	= message #
RETURN:		nothing (allocate busy component array if necessary)
DESTROYED:	ax, cx, dx, bp 
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBAddToBusyArray	method	dynamic	SystemBusyClass,
				MSG_SYSTEM_BUSY_ADD_SELF_TO_BUSY_ARRAY
		.enter
	;
	; Have the utility routine do everything for us.
	;
		mov	di, offset busyCompArray
		call	GadgetUtilAddSelfToArray

		.leave
		Destroy	ax, cx, dx, bp
		ret
SBAddToBusyArray	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBEntDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take ourself out of the array of busy components.

CALLED BY:	MSG_ENT_DESTROY
PASS:		*ds:si	= SystemBusyClass object
		ds:di	= SystemBusyClass instance data
		ds:bx	= SystemBusyClass object (same as *ds:si)
		es 	= segment of SystemBusyClass
		ax	= message #
RETURN:		
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/29/96   	Initial version
	jmagasin 4/29/96	Undo all our !Enter() actions.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBEntDestroy	method dynamic SystemBusyClass, 
					MSG_ENT_DESTROY
		.enter
	;
	; Clear busyCount, adjust busyTotal, and undo all
	; our !Enter() actions.
	;
		clr	cx
		xchg	cx, ds:[di].SBI_busyCount
		jcxz	removeSelfFromArray

		mov	ax, seg dgroup
		mov	es, ax
		sub	es:[busyTotal], cx
		Assert	ge es:[busyTotal], 0

undoEnterLoop:
		mov_tr	bx, cx
		mov	ax, MSG_GEN_SYSTEM_MARK_NOT_BUSY
		call	UserCallSystem
		mov_tr	cx, bx
		loop	undoEnterLoop
	;
	; Remove self from the array of busy components.
	;
removeSelfFromArray:
		mov	ax, MSG_SYSTEM_BUSY_REMOVE_SELF_FROM_BUSY_ARRAY
		call	ObjCallInstanceNoLock
	;
	; Call superclass.
	;
		mov	ax, MSG_ENT_DESTROY
		mov	di, offset SystemBusyClass
		call	ObjCallSuperNoLock
		
		.leave
		Destroy	ax, cx, dx, bp
		ret
SBEntDestroy	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBRemoveFromBusyArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove self from the array of busy components.
		This message is only provided because we don't
		want BSystemBusy messing with the busy array.

CALLED BY:	MSG_SYSTEM_BUSY_REMOVE_SELF_FROM_BUSY_ARRAY
PASS:		*ds:si	= SystemBusyClass object
		ds:di	= SystemBusyClass instance data
		ds:bx	= SystemBusyClass object (same as *ds:si)
		es 	= segment of SystemBusyClass
		ax	= message #
RETURN:		
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/29/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBRemoveFromBusyArray	method dynamic SystemBusyClass, 
				MSG_SYSTEM_BUSY_REMOVE_SELF_FROM_BUSY_ARRAY
		.enter
	;
	; Have the utility routine do everything.
	;
		mov	di, offset busyCompArray
		call	GadgetUtilRemoveSelfFromArray

		.leave
		Destroy	ax, cx, dx, bp
		ret
SBRemoveFromBusyArray	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBActionEnterOrLeave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enter the busy state.

CALLED BY:	MSG_SYSTEM_BUSY_ACTION_ENTER
		MSG_SYSTEM_BUSY_ACTION_LEAVE
PASS:		*ds:si	= SystemBusyClass object
		ds:di	= SystemBusyClass instance data
		ds:bx	= SystemBusyClass object (same as *ds:si)
		es 	= segment of SystemBusyClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 4/ 9/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBActionEnterOrLeave	method dynamic SystemBusyClass, 
					MSG_SYSTEM_BUSY_ACTION_ENTER,
					MSG_SYSTEM_BUSY_ACTION_LEAVE
		.enter
	;
	; Determine our adjustment value.
	;
		mov	cx, 1				; Assume "Enter()"
		cmp	ax, MSG_SYSTEM_BUSY_ACTION_ENTER
		je	adjustBusyTotal
		neg	cx
	;
	; Adjust our busyTotal.
	;
adjustBusyTotal:
		mov	ax, seg dgroup
		mov	es, ax
		push	es:[busyTotal]			; save old busyTotal
		add	es:[busyTotal], cx
		js	fixupBusyTotal			; 32768 is too big!
							; or -1 is illegal
	;
	; Adjust the busyCount.
	;
		add	ds:[di].SBI_busyCount, cx
		js	fixupBusyCount			; -1 is illegal
EC <		push	cx						>
EC <		mov	cx, es:[busyTotal]				>
EC <		Assert	le ds:[di].SBI_busyCount, cx			>
EC <		pop	cx						>
	;
	; Tell the system object to that we're busy/not busy.  It'll
	; change the cursor.
	;
		mov	ax, MSG_GEN_SYSTEM_MARK_BUSY
		dec	cl
		jz	tellSysObj
		mov	ax, MSG_GEN_SYSTEM_MARK_NOT_BUSY
		Assert	ge es:[busyTotal], 0
tellSysObj:
		call	UserCallSystem
	;
	; Notify other busy components of the busyTotal change.
	;
		mov	cx, es:[busyTotal]
		cmp	cx, 1
		ja	done			; was not a 0 <-> 1 change
		pop	cx			; get old busyTotal
		push	cx
		cmp	cx, 2
		je	done			; was a 2->1 change
		call	SBNotifyBusyCompsOfBusyTotalChange

done:
		add	sp, 2
		.leave
		Destroy	ax, cx, dx
		ret

fixupBusyCount:
		sub	ds:[di].SBI_busyCount, cx
fixupBusyTotal:
		sub	es:[busyTotal], cx
		Assert	srange es:[busyTotal], 0, 32767
		Assert	srange ds:[di].SBI_busyCount, 0, 32767
		jmp	done
SBActionEnterOrLeave	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBNotifyBusyCompsOfBusyTotalChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify busy components that the busyTotal has changed.

CALLED BY:	SBActionEnterOrLeave
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es, ds
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBNotifyBusyCompsOfBusyTotalChange	proc	near
		.enter
	;
	; Utility routine does everything for us.
	;
		mov	ax, MSG_SYSTEM_BUSY_RAISE_BUSY_TOTAL_CHANGED_EVENT
		mov	di, offset busyCompArray
		call	GadgetUtilNotifyCompsOfChange

		.leave
		Destroy	ax, cx, dx, bx, si, di
		ret
SBNotifyBusyCompsOfBusyTotalChange	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SBRaiseBusyTotalChangedEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Raise a busyTotalChanged event.

CALLED BY:	MSG_SYSTEM_BUSY_RAISE_BUSY_TOTAL_CHANGED_EVENT
PASS:		*ds:si	= SystemBusyClass object
		ds:di	= SystemBusyClass instance data
		ds:bx	= SystemBusyClass object (same as *ds:si)
		es 	= segment of SystemBusyClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 4/10/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
busyTotalChangedString	TCHAR	"busyTotalChanged", C_NULL
SBRaiseBusyTotalChangedEvent	method dynamic SystemBusyClass, 
				MSG_SYSTEM_BUSY_RAISE_BUSY_TOTAL_CHANGED_EVENT
params	local	EntHandleEventStruct
		.enter
	;
	; Raise an event.
	;
		lea	ax, cs:[busyTotalChangedString]
		movdw	ss:[params].EHES_eventID.EID_eventName, csax
		lea	ax, ss:[params]
		movdw	ss:[params].EHES_result, ssax
		clr	ss:[params].EHES_argc

		mov	ax, MSG_ENT_HANDLE_EVENT
		lea	dx, params
		mov	cx, ss
		call	ObjCallInstanceNoLock

		.leave
		Destroy	ax, cx, dx
		ret
SBRaiseBusyTotalChangedEvent	endm

