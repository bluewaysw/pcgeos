COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		splineUI.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/13/92   	Initial version.

DESCRIPTION:
	Procedures for updating the controllers.	

	$Id: splineUI.asm,v 1.1 97/04/07 11:09:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineObjectCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineBeginUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Send a MSG_SPLINE_GENERATE_NOTIFY message to myself

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= dgroup

		cx - SplineGenerateNotifyFlags
RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineBeginUpdateUI	method	dynamic	VisSplineClass, 
					MSG_SPLINE_BEGIN_UPDATE_UI
	.enter

	ECCheckFlags	cx, SplineGenerateNotifyFlags

	call	SplineMethodCommonReadOnly
	call	SplineUpdateUI
	call	SplineEndmCommon
	.leave
	ret
SplineBeginUpdateUI	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put the params on the stack, and send the message

CALLED BY:	EXTERNAL

PASS:		es:[bp] - VisSpline instance
		*ds:si - points

		cx - SplineGenerateNotifyFlags

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUpdateUI	proc far
	uses	ax,bx,cx,dx
	class	VisSplineClass

	.enter

EC <	call	ECSplineInstanceAndLMemBlock	>
EC <	test	cx,not mask	SplineGenerateNotifyFlags	>
EC <	ERROR_NZ SPLINE_BAD_SPLINE_GENERATE_NOTIFY_FLAGS	>


	;
	; If we're suspended, then put this off till later.
	;
	tst	es:[bp].VSI_suspendCount
	jnz	suspended


	sub	sp, size SplineGenerateNotifyParams
	mov	bx, sp

	mov	al, es:[bp].VSI_editState

	mov	ss:[bx].SGNP_notificationFlags, cx
	
	mov	ss:[bx].SGNP_sendFlags, mask SNSF_SEND_AFTER_GENERATION or \
				mask SNSF_UPDATE_APP_TARGET_GCN_LISTS

	mov	ax, MSG_SPLINE_GENERATE_NOTIFY
	call	SplineSendMyselfAMessage

	add	sp, size SplineGenerateNotifyParams

done:
	.leave
	ret
suspended:
	ornf	es:[bp].VSI_unSuspendFlags, mask SUSF_UPDATE_UI
	jmp	done

SplineUpdateUI	endp








COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGenerateNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Update the UI, and any other objects hanging around
		on notification lists out there...

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.

		ss:bp   = SplineGenerateNotifyParams

RETURN:		ss:bp   - SplineGenerateNotifyParams updated

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 4/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineGenerateNotify	method	dynamic	VisSplineClass, 
					MSG_SPLINE_GENERATE_NOTIFY

		mov	ax, ss:[bp].SGNP_notificationFlags
		ECCheckFlags	ax, SplineGenerateNotifyFlags

		mov	bx, ss:[bp].SGNP_sendFlags
		ECCheckFlags	bx, SplineNotifySendFlags

		ornf	ss:[bp].SGNP_sendFlags, mask SNSF_STRUCTURE_INITIALIZED

notifyParams	local	nptr.SplineGenerateNotifyParams	push	bp
notifFlags	local	SplineGenerateNotifyFlags	push	ax
sendFlags	local	SplineNotifySendFlags		push	bx
counter		local	word
notifPtr	local	nptr
gcnParams	local	GCNListMessageParams


ForceRef gcnParams


		class	VisSplineClass

		.enter

	; loop through the various notification types, generating a
	; structure for each and sending it

		clr	counter
		clr	notifPtr

generateLoop:
		test	sendFlags, mask SNSF_NULL_STATUS
		jnz	doThisOne
		shl	notifFlags
		jnc	next
doThisOne:

		mov	di, notifyParams
		add	di, counter
		mov	bx, ss:[di].SGNP_notificationBlocks
		test	sendFlags, mask SNSF_STRUCTURE_INITIALIZED
		jnz	alreadyInitialized
		clr	bx
alreadyInitialized:

	; if we're supposed to generate then do it

		test	sendFlags, mask SNSF_SEND_ONLY
		jnz	afterGenerate
		call	SplineCallGenNotify	; bx = data block (ref count = 1)
afterGenerate:

		mov	ss:[di].SGNP_notificationBlocks, bx

	; if we're supposed to send then do it

		test	sendFlags, mask SNSF_SEND_AFTER_GENERATION or \
						mask SNSF_SEND_ONLY
		jz	next

EC <	; clear out the SGNP_notificationBlocks field			>
EC <		mov	ss:[di].SGNP_notificationBlocks, 0cccch		>

		mov	di, notifPtr

		test	sendFlags, mask SNSF_UPDATE_APP_TARGET_GCN_LISTS
		jz	noAppGCNListSend

	; Update the specified GenApplication GCNList status event with a
	; MSG_META_NOTIFY_WITH_DATA_BLOCK of the specified notification type,
	; with the specified status block.
	;
		call	SplineUpdateAppGCNList

noAppGCNListSend:
		call	MemDecRefCount		;One less reference -- we
						;don't need block for ourself
						;anymore (balances init of
						;ref count to 1 at time of
						;creation)
next:
		add	counter, size word
		add	notifPtr, size UpdateTableEntry
		cmp	notifPtr, (size UpdateTable)
		LONG jl generateLoop

		.leave
		ret

SplineGenerateNotify	endm



UpdateTable	UpdateTableEntry	\
\
	<SplineUpdateMarkerShape,
	 size MarkerNotificationBlock,
	 GAGCNLT_APP_TARGET_NOTIFY_SPLINE_MARKER_SHAPE,
	 GWNT_SPLINE_MARKER_SHAPE>,

	<SplineUpdatePointOrPolyline,
	size SplinePointNotificationBlock,
	GAGCNLT_APP_TARGET_NOTIFY_SPLINE_POINT,
	GWNT_SPLINE_POINT>,

	<SplineUpdatePointOrPolyline,
	size SplinePointNotificationBlock,
	GAGCNLT_APP_TARGET_NOTIFY_SPLINE_POLYLINE,
	GWNT_SPLINE_POLYLINE>,

	<SplineUpdateSmoothness,
	size SplinePointNotificationBlock,
	GAGCNLT_APP_TARGET_NOTIFY_SPLINE_SMOOTHNESS,
	GWNT_SPLINE_SMOOTHNESS>,

	<SplineUpdateOpenClose,
	size SplineOpenCloseNotificationBlock,
	GAGCNLT_APP_TARGET_NOTIFY_SPLINE_OPEN_CLOSE_CHANGE,
	GWNT_SPLINE_OPEN_CLOSE_CHANGE>,

	<SplineUpdateEditControl,
	size SplineOpenCloseNotificationBlock,
	GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE,
	GWNT_SELECT_STATE_CHANGE>



COMMENT @----------------------------------------------------------------------

FUNCTION:	SplineUpdateAppGCNList

DESCRIPTION:	Updates GenApplication GCN list with status passed.

		Calls MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST on process, passing
		event consisting of update information for passed list.

CALLED BY:	INTERNAL
		TA_SendNotification

PASS:
	*ds:si - spline
	ss:bp - inherited variables
	bx - handle of status block, or zero if none, to be passed in
	     MSG_META_NOTIFY_WITH_DATA_BLOCK

RETURN:	
	none

DESTROYED:
	ax, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

		Assumes GeoWorks manufacturer types for GCNListType &
		NotificationType, and use of MSG_META_NOTIFY_WITH_DATA_BLOCK.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/91		Initial version, pulled out of
				TA_SendNotification because of its size (would
				not assemble).  Updated to provide info
				needed for optimizations.
------------------------------------------------------------------------------@
SplineUpdateAppGCNList	proc	near
	uses	bx, dx, bp, si

	.enter inherit SplineGenerateNotify

	call	MemIncRefCount			;one more reference, for send
	push	bp
	mov	bp, bx				;bp - block
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, cs:[UpdateTable][di].UTE_notificationType
	mov	di, mask MF_RECORD
	call	ObjMessage			; di is event
	pop	bp

	mov	gcnParams.GCNLMP_event, di



	mov	di, notifPtr
	mov	cx, cs:[UpdateTable][di].UTE_gcnListType
	mov	gcnParams.GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	gcnParams.GCNLMP_ID.GCNLT_type, cx
	mov	gcnParams.GCNLMP_block, bx

	; if clearing status, meaning we're no longer the target, set bit to
	; indicate this clearing should be avoided if the status will get
	; updated by a new target.

	mov	ax, mask GCNLSF_SET_STATUS
	tst	bx
	jnz	afterTransitionCheck
	ornf	ax, mask GCNLSF_IGNORE_IF_STATUS_TRANSITIONING
afterTransitionCheck:
	mov	gcnParams.GCNLMP_flags, ax

	mov	dx, size GCNListMessageParams	; create stack frame
	lea	bp, gcnParams

	mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST ; Update GCN list

	call	GeodeGetProcessHandle
	clr	si
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage

	.leave
	ret

SplineUpdateAppGCNList	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SplineCallGenNotify

DESCRIPTION:	Generate notification block

CALLED BY:	INTERNAL

PASS:
	*ds:si - vis spline
	bx - block

RETURN:
	bx - block

DESTROYED:
	ax, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/ 6/91	Initial version

------------------------------------------------------------------------------@

SplineCallGenNotify	proc	near	
	uses di

	.enter inherit SplineGenerateNotify

EC <	call	ECCheckSplineDSSI	>


	test	sendFlags, mask SNSF_NULL_STATUS
	jnz	afterGenerate

	mov	di, notifPtr

	; allocate the block

	tst	bx
	jnz	afterAllocate

	mov	ax, cs:[UpdateTable][di].UTE_size
	mov	cx, ALLOC_DYNAMIC_NO_ERR or mask HF_SHARABLE \
			or (mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	mov	ax, 1
	call	MemInitRefCount
afterAllocate:

	call	MemLock
	mov	es, ax

	push	bx, si, ds
	call	cs:[UpdateTable][di].UTE_routine
	pop	bx, si, ds

	call	MemUnlock

afterGenerate:

	.leave
	ret

SplineCallGenNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUpdateMarkerShape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stick the current marker shape in the notification
		block 

CALLED BY:	SplineUpdateUI

PASS:		*ds:si - spline
		es - notification block

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 4/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUpdateMarkerShape	proc near
	uses	ax,bx
	class	VisSplineClass 
	.enter	inherit	SplineGenerateNotify

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	mov	al, ds:[di].VSI_markerShape
	mov	cx, offset MNB_markerShape
	call	UpdateByteEtype

	.leave
	ret
SplineUpdateMarkerShape	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateByteEtype
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update an etype at es:bx

CALLED BY:

PASS:		es:cx - current value
		al - new value

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateByteEtype	proc near
	uses	bx

	.enter  inherit SplineGenerateNotify

	mov	bx, cx
	test	sendFlags, mask SNSF_STRUCTURE_INITIALIZED
	jnz	notFirst
	mov	es:[bx], al
done:	
	.leave
	ret

notFirst:
	cmp	es:[bx], al
	je	done
	mov	{byte} es:[bx], -1
	jmp	done

UpdateByteEtype	endp


; Same as above, but uses AX
UpdateWordEtype	proc near
	uses	bx

	.enter  inherit SplineGenerateNotify

	mov	bx, cx
	test	sendFlags, mask SNSF_STRUCTURE_INITIALIZED
	jnz	notFirst
	mov	es:[bx], ax
done:	
	.leave
	ret

notFirst:
	cmp	es:[bx], ax
	je	done
	mov	{word} es:[bx], -1
	jmp	done

UpdateWordEtype	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateByteFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update a byte of flags in the notification block

CALLED BY:	SplineUpdateOpenClose

PASS:		ss:bp - inherited local vars
		al - byte of flags
		es:bx - address of dest flags
		es:di - address of diffs

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateByteFlags	proc near
	uses	bx
	.enter	inherit	SplineGenerateNotify

	test	sendFlags, mask SNSF_STRUCTURE_INITIALIZED
	jnz	notFirst
	mov	es:[bx], al
done:
	.leave
	ret

notFirst:
	xor	al, es:[bx]
	or	es:[di], al
	jmp	done

UpdateByteFlags	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUpdateSmoothness
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the "smoothness" in the UI data block

CALLED BY:	SplineUpdateUI

PASS:		*ds:si - spline
		es - notification block

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/13/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUpdateSmoothness	proc near

	class	VisSplineClass

	.enter

	call	FillInPointNotificationBlock

	; Now, fill in smoothtype

	push	es, bp

EC <	call	ECCheckSplineDSSI	>

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	call	SplineMethodCommonReadOnly

	clr	dx		; starting parameter for
				; SplineGetSmoothness. 
	mov	cx, -1		; start with an illegal value
	mov	al, SOT_GET_SMOOTHNESS
	mov	bx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnSelectedPointsFar

	SplineDerefScratchChunk di
	mov	cx, ds:[di].SD_paramCX
	call	SplineEndmCommon
	pop	es, bp

	mov	al, cl
	mov	cx, offset SPNB_smoothness
	call	UpdateByteEtype

	.leave
	ret
SplineUpdateSmoothness	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUpdateOpenClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the SplineState field of the notification block

CALLED BY:	SplineUpdateUI

PASS:		*ds:si - instance data
		es - segment of notification block

RETURN:		nothing 

DESTROYED:	ax,bx,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUpdateOpenClose	proc near

	class	VisSplineClass 

	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	mov	al, ds:[di].VSI_state
	mov	bx, offset SOCNB_state
	mov	di, offset SOCNB_stateDiffs
	call	UpdateByteFlags

	.leave
	ret
SplineUpdateOpenClose	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUpdatePoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update info for the point controller

CALLED BY:

PASS:		*ds:si - instance data
		es - notification block

RETURN:		nothing 

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/13/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUpdatePointOrPolyline	proc near

	class	VisSplineClass
	.enter
	call	FillInPointNotificationBlock
	.leave
	ret
SplineUpdatePointOrPolyline	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillInPointNotificationBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the data for this block.  The block is used by
		3 different controllers.

CALLED BY:

PASS:		es - segment of SplinePointNotificationBlock
		*ds:si - spline
		al - SplineMode

RETURN:		nothing  

DESTROYED:	di, ax, bx, cx, dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/13/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FillInPointNotificationBlock	proc near
	class	VisSplineClass

	.enter

EC <	call	ECCheckSplineDSSI	>


	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	GetEtypeFromRecord	al, SS_MODE, ds:[di].VSI_state 

	mov	cx, offset SPNB_mode
	call	UpdateByteEtype


	GetEtypeFromRecord	al, SES_ACTION, ds:[di].VSI_editState


	mov	cx, offset SPNB_actionType
	call	UpdateByteEtype

	; Have to lock the spline's block, etc.  to get number of
	; points. 

	push	ds, es, si, bp
	call	SplineMethodCommonReadOnly

	mov	al, SOT_GET_NUM_CONTROLS
	mov	bx, mask SWPF_ANCHOR_POINT
	mov	cl, -1
	clr	dx
	call	SplineOperateOnSelectedPointsFar

	mov	si, es:[bp].VSI_selectedPoints
	call	ChunkArrayGetCount

	SplineDerefScratchChunk di
	mov	dx, ds:[di].SD_paramCX
	call	SplineEndmCommon
	pop	ds, es, si, bp

	; cx - # selected points
	; dl - # controls around each anchor

	mov_tr	ax, cx
	mov	cx, offset SPNB_numSelected
	call	UpdateWordEtype

	mov	al, dl
	mov	cx, offset SPNB_numControls
	call	UpdateByteEtype

	.leave
	ret
FillInPointNotificationBlock	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUpdateEditControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the NotifySelectStateChange structure

CALLED BY:	SplineGenerateNotify

PASS:		*ds:si - spline instance data
		es - segment of notification block

RETURN:		nothing 

DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineUpdateEditControl	proc near
		class	VisSplineClass
		.enter
		mov	es:[NSSC_selectionType], SDT_GRAPHICS ; ???

		mov	al, BB_FALSE
		mov	es:[NSSC_pasteable], al
		mov	es:[NSSC_clipboardableSelection], al


		dec	al			; BB_TRUE
		mov	es:[NSSC_deleteableSelection], al


	;
	; Select-all is unavailable in create mode.
	;
		mov	di, ds:[si]
		add	di, ds:[di].VisSpline_offset
		mov	ah, ds:[di].VSI_state
		andnf	ah, mask SS_MODE
		cmp	ah, SM_BEGINNER_EDIT
		je	setFlags
		cmp	ah, SM_ADVANCED_EDIT
		je	setFlags
		clr	al
setFlags:
		mov	es:[NSSC_selectAllAvailable], al

		.leave
		ret
SplineUpdateEditControl	endp


SplineObjectCode	ends
