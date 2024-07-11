COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Service Components (Clipboard component)
FILE:		srvclipb.asm

AUTHOR:		Jon Witort 5 oct 95

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	5 oct 95   	Initial revision

DESCRIPTION:
	Defines Clipboard service component.

	$Id: srvclipb.asm,v 1.1 98/03/11 04:31:25 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
idata segment

	ServiceClipboardClass

idata ends

SBCS<	MAX_STRING_SIZE	equ	4000	>
DBCS<	MAX_STRING_SIZE	equ	2000	>

activeSelectionChangedString	TCHAR	"selectionChanged", C_NULL
clipboardItemChangedString	TCHAR	"clipboardChanged", C_NULL


;; Create property table
;;

makePropEntry clipboard, copyable, LT_TYPE_INTEGER, \
	PDT_SEND_MESSAGE, <PD_message MSG_SCB_GET_CLIPBOARDABLE>, \
	PDT_SEND_MESSAGE, <PD_message MSG_SCB_SET_CLIPBOARDABLE>

makePropEntry clipboard, deletable, LT_TYPE_INTEGER, \
	PDT_SEND_MESSAGE, <PD_message MSG_SCB_GET_DELETABLE>, \
	PDT_SEND_MESSAGE, <PD_message MSG_SCB_SET_DELETABLE>

makePropEntry clipboard, pastable, LT_TYPE_INTEGER, \
	PDT_SEND_MESSAGE, <PD_message MSG_SCB_GET_PASTABLE>, \
	PDT_SEND_MESSAGE, <PD_message MSG_SCB_SET_PASTABLE>

makePropEntry clipboard, activeSelection, LT_TYPE_COMPONENT, \
	PDT_SEND_MESSAGE, <PD_message MSG_SCB_GET_ACTIVE_SELECTION>, \
	PDT_SEND_MESSAGE, <PD_message MSG_SCB_SET_ACTIVE_SELECTION>


compMkPropTable ClipboardProperty, clipboard, activeSelection, copyable, deletable, pastable

;; Create action table
;;
makeActionEntry clipboard, SetItem \
	MSG_SCB_ACTION_SETITEM, LT_TYPE_INTEGER, 1

makeActionEntry clipboard, GetItem \
	MSG_SCB_ACTION_GETITEM, LT_TYPE_UNKNOWN, 1

makeActionEntry clipboard, QueryItem \
	MSG_SCB_ACTION_QUERYITEM, LT_TYPE_INTEGER, 1

makeActionEntry clipboard, Cut \
	MSG_SCB_ACTION_CUT, LT_TYPE_VOID, 0

makeActionEntry clipboard, Copy \
	MSG_SCB_ACTION_COPY, LT_TYPE_VOID, 0

makeActionEntry clipboard, Paste \
	MSG_SCB_ACTION_PASTE, LT_TYPE_VOID, 0

makeActionEntry clipboard, Delete \
	MSG_SCB_ACTION_DELETE, LT_TYPE_VOID, 0

compMkActTable clipboard, SetItem, GetItem, QueryItem,  \
			  Cut, Copy, Paste, Delete

MakeSystemPropRoutines ServiceClipboard, clipboard


;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;% Standard methods for using and resolving non-byte-compiled actions
;% and properties, returning class name.  These are all cookie-cutter
;% routines.
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

COMMENT @
DESCRIPTION:	

@

SCBEntDoAction	method dynamic ServiceClipboardClass, MSG_ENT_DO_ACTION
		segmov	es, cs
		mov	bx, offset clipboardActionTable
		mov	di, offset ServiceClipboardClass
		mov	ax, segment dgroup
		call	EntUtilDoAction
		ret
SCBEntDoAction	endm

SCBEntResolveAction method dynamic ServiceClipboardClass, MSG_ENT_RESOLVE_ACTION
		segmov	es, cs
		mov	bx, offset clipboardActionTable
		mov	di, offset ServiceClipboardClass
		mov	ax, segment dgroup
		call	EntResolveActionCommon
		ret
SCBEntResolveAction endm

SCBEntGetClass method dynamic ServiceClipboardClass, MSG_ENT_GET_CLASS
	; ServiceClipboardString defined with makeECPS
		mov	cx, segment ServiceClipboardString
		mov	dx, offset ServiceClipboardString
		ret
SCBEntGetClass endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCBMetaResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inform system that we are Meta but not Gen or Vis

CALLED BY:	MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:		ds,si,di,bx,es,ax - standard method stuff
		cx	- Master class offset
RETURN:		cxdx	- ClassPtr of superclass
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Return ML2Class, a null-ish class at the 2nd master level

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 8/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCBMetaResolveVariantSuperclass	method dynamic ServiceClipboardClass, 
					MSG_META_RESOLVE_VARIANT_SUPERCLASS
	;uses	ax, bp
	.enter

	; Only variant class to resolve should be Ent
	; since ML2Class is master but not variant
	;
EC <		cmp	cx, Ent_offset					>
EC <		ERROR_NE -1						>
		mov	cx, segment ML2Class
		mov	dx, offset ML2Class
	.leave
	ret
SCBMetaResolveVariantSuperclass	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCBMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear some flags that ent sets

CALLED BY:	MSG_META_INITIALIZE
PASS:		*ds:si	= ServiceClipboardClass object
		ds:di	= ServiceClipboardClass instance data
		ds:bx	= ServiceClipboardClass object (same as *ds:si)
		es 	= segment of ServiceClipboardClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 8/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCBMetaInitialize	method dynamic ServiceClipboardClass, 
					MSG_META_INITIALIZE
	uses	ax, cx, dx, bp
	.enter
		mov	di, offset ServiceClipboardClass
		call	ObjCallSuperNoLock

		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset
		BitClr	ds:[di].EI_state, ES_IS_GEN
		BitClr	ds:[di].EI_state, ES_IS_VIS

	.leave
	ret
SCBMetaInitialize	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCBMetaDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes the object from the clipboard notification list
		before dying.

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= ServiceClipboardClass object
		ds:di	= ServiceClipboardClass instance data
		ds:bx	= ServiceClipboardClass object (same as *ds:si)
		es 	= segment of ServiceClipboardClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/28/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCBMetaDetach	method dynamic ServiceClipboardClass, \
		MSG_ENT_DESTROY
	uses	ax, cx, dx
	.enter

	;
	;  Remove ourselves from the relevant notification lists.
	;
	mov	ax, MSG_META_GCN_LIST_REMOVE
	call	SCBAddRemoveGCNCommon

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	ClipboardRemoveFromNotificationList

	.leave

	mov	di, offset ServiceClipboardClass
	call	ObjCallSuperNoLock
	ret
SCBMetaDetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCBEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds the object to the clipboard notification list so
		we can receive changed events.

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= ServiceClipboardClass object
		ds:di	= ServiceClipboardClass instance data
		ds:bx	= ServiceClipboardClass object (same as *ds:si)
		es 	= segment of ServiceClipboardClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Initialize minutes-to-midnight and minutes-to-next-ding.
	Start up a timer which ticks every minute.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 8/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCBEntInitialize	method dynamic ServiceClipboardClass, 
					MSG_ENT_INITIALIZE
	uses	ax, cx, dx
	.enter

	;
	;  Add ourselves to the clipboard notification list so
	;  that we receive changed events.
	;

	mov	ax, MSG_META_GCN_LIST_ADD
	call	SCBAddRemoveGCNCommon

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	ClipboardAddToNotificationList

	.leave

	mov	di, offset ServiceClipboardClass
	call	ObjCallSuperNoLock

	ret
SCBEntInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCBAddRemoveGCNCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds and removes an object from the application local
		GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE list.

PASS:		*ds:si	= ServiceClipboardClass object
		ax	= MSG_META_GCN_LIST_ADD or
			  MSG_META_GCN_LIST_REMOVE
RETURN:		nada
DESTROYED:	nada

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	3 oct 95	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCBAddRemoveGCNCommon	proc	near
	uses	ax, bx, cx, dx, bp, di, si
	.enter

	;
	;  Showing my age by pushing the GCNListParams rather
	;  than doing it more conventionally...
	;
	push	ds:[LMBH_handle]
	push	si

	mov	bx, GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE
	push	bx	
	mov	bx, MANUFACTURER_ID_GEOWORKS
	push	bx

CheckHack <size GCNListParams eq 8>
	mov	dx, size GCNListParams
	mov	bp, sp

	clr	bx
	call	GeodeGetAppObject
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size GCNListParams
	.leave
	ret
SCBAddRemoveGCNCommon	endp	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCBNotifyWithDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This message is sent to the object when the clipboard
		item has changed. We need to record the latest status
		and raise a changed event.

CALLED BY:	MSG_META_NOTIFY_WITH_DATA_BLOCK

PASS:		*ds:si	= ServiceClipboardClass object
		ds:di	= ServiceClipboardClass instance data
		ds:bx	= ServiceClipboardClass object (same as *ds:si)
		es 	= segment of ServiceClipboardClass
		ax	= message #

		cx:dx - NotificationType
		^hbp - the data block

RETURN:		nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	3 oct 95	initial revision
	jmagasin 4/23/96	Check to skip redundant selectionChanged
				events.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCBNotifyWithDataBlock	method dynamic ServiceClipboardClass, 
			MSG_META_NOTIFY_WITH_DATA_BLOCK

	;
	; This should be the only notification type we're getting.
	;
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	dunno
	cmp	dx, GWNT_SELECT_STATE_CHANGE
	jne	dunno

	;
	; Lock the latest update down and see if it is any different
	; than the last update.  If not, bail.
	;
	tst	bp
	jz	noDataBlock
	mov	bx, bp
	call	MemLock
	jc	callSuper

	push	es, cx
	push	di					; save inst data
	mov	es, ax
	clr	di					; es:di = NSSC

	; Check if anything has changed.
	;
	call	SCBConvertNSSC_to_ActiveSelectionState	; al <- flags
	call	MemUnlock
	pop	di
	mov	ah, al
	xchg	al, ds:[di].SCBI_activeSelectionState
	cmp	ah, al
	je	skipEvent
		
	pop	es, cx

callSuper:
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	di, offset ServiceClipboardClass
	call	ObjCallSuperNoLock

	;
	; Now raise an event that things have changed.
	;

	mov	di, ds:[si]
	add	di, ds:[di].ServiceClipboard_offset			
	test	ds:[di].SCBI_eventFlags, mask CEF_DOING_SELECTION_CHANGED
	jnz	done			

	BitSet	ds:[di].SCBI_eventFlags, CEF_DOING_SELECTION_CHANGED
	mov	dx, cs
	mov	ax, offset activeSelectionChangedString
	call	ServiceRaiseEvent

	mov	di, ds:[si]
	add	di, ds:[di].ServiceClipboard_offset			
	BitClr	ds:[di].SCBI_eventFlags, CEF_DOING_SELECTION_CHANGED

done:
	ret

	; Skip the selectionChanged event.
	;
skipEvent:
	add	sp, 4				; quick pop
	jmp	done

	; No data block.  Hmm.. Clear all flags.
	;
noDataBlock:
	clr	al
	xchg	al, ds:[di].SCBI_activeSelectionState
	tst	al
	jz	done				; we were already clear
	jmp	callSuper

	; Some other kind of notification.
	;
dunno:
	mov	di, offset ServiceClipboardClass
	call	ObjCallSuperNoLock
	jmp	done			
SCBNotifyWithDataBlock	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCBConvertNSSC_to_ActiveSelectionState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the passed NotifySelectStateChange buffer
		into an ActiveSelectionState record.

CALLED BY:	SCBNotifyWithDataBlock only
PASS:		es:di	- NotifySelectStateChange
RETURN:		al	- ActiveSelectionState flags
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Caveat:  If NSSC_selectionType != 0 = SDT_TEXT, then
		return 0 for ActiveSelectionStateFlags.  We do this
		to filter out notifications sent by InkClass or any
		other non-ClipboardableClass components that might
		gain the target.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 4/23/96    	Initial version
	jmagasin 4/29/96	Filter out notifications from InkClass.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCBConvertNSSC_to_ActiveSelectionState	proc	near
		.enter
	;
	; Filter out notifications from InkClass.  (See STRATEGY.)
	;
		CheckHack < SDT_TEXT eq 0 >
		cmp	es:[di].NSSC_selectionType, SDT_TEXT
		je	checkCopyable
		clr	al
		jmp	done
		
	;
	; Deal with copyable.
	;
checkCopyable:
		mov	al, mask ASSF_COPYABLE
		tst	es:[di].NSSC_clipboardableSelection
		jnz	getDeletable
		clr	al
	;
	; Deal with deletable.
	;
getDeletable:
		BitSet	al, ASSF_DELETABLE
		tst	es:[di].NSSC_deleteableSelection
		jnz	getPastable
		BitClr	al, ASSF_DELETABLE
	;
	; Deal with pastable.
	;
getPastable:
		BitSet	al, ASSF_PASTABLE
		tst	es:[di].NSSC_pasteable
		jnz	done
		BitClr	al, ASSF_PASTABLE
done:
		.leave
		ret
SCBConvertNSSC_to_ActiveSelectionState	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCBMSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This message is sent to the object when the clipboard
		item has changed. We need to record the latest status
		and tell the active selection that the clipboard has
		changed.  The active selection will raise an
		activeChanged event and then signal us to raise
		a clipboardChanged event.

CALLED BY:	MSG_META_NOTIFY_WITH_DATA_BLOCK

PASS:		*ds:si	= ServiceClipboardClass object
		ds:di	= ServiceClipboardClass instance data
		ds:bx	= ServiceClipboardClass object (same as *ds:si)
		es 	= segment of ServiceClipboardClass
		ax	= message #

		cx:dx - NotificationType
		^hbp - the data block
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	6 oct 95	initial revision
	jmagasin 3/2/96		Tell active selection about clipboard
				change.
	jmagasin 4/10/96	When first run app, app obj can return
				null target.  Handle this.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCBNotifyNormalTransferItemChanged method dynamic ServiceClipboardClass,
			MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED
	.enter

	;
	; Bail if we're already handling a "xfer item changed" msg.
	;
	test	ds:[di].SCBI_eventFlags, mask CEF_DOING_CLIPBOARD_CHANGED
	jnz	done
	BitSet	ds:[di].SCBI_eventFlags, CEF_DOING_CLIPBOARD_CHANGED

	;
	; If the target is not subclassed from GadgetClipboardableClass,
	; then we send ourself a RAISE_CLIPBOARD_CHANGED_EVENT now.
	; Posible that their is no target below the app (when first run
	; app).  If so just send ourself the RAISE msg.  (Hmmm, didn't
	; get null targets in the past). -jmagasin 4/10/96
	;
	clc						; Want app target.
	call	SCBGetTarget
	jcxz	raiseClipboardChangedEventNow		; No target - bail.
	push	si					; Save ourself.
	movdw	bxsi, cxdx				; ^lbx:si = target

	mov	cx, segment GadgetClipboardableClass
	mov	dx, offset GadgetClipboardableClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov_tr	dx, si					; Save target.
	pop	si
	jnc	raiseClipboardChangedEventNow

	;
	; We've got a clipboardable.  Give it a chance to raise an
	; acceptPaste event.  Also set our state as CEF_DOING_CLIPBOARD
	; _CHANGED.
	;
	mov	cx, ds:[LMBH_handle]
	xchg	dx, si					; bx:si <- target
							; cx:dx <- self
	mov	ax, MSG_GADGET_CLIPBOARDABLE_CLIPBOARD_ITEM_CHANGED
	clr	di
	call	ObjMessage
		
done:
	.leave
	Destroy	ax, cx, dx, bp
	ret

raiseClipboardChangedEventNow:
	mov	ax, MSG_SCB_RAISE_CLIPBOARD_CHANGED_EVENT
	call	ObjCallInstanceNoLock
	jmp	done
SCBNotifyNormalTransferItemChanged	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCBGetTarget
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the system or application target depending on
		whether the system or application object is passed.

CALLED BY:	
PASS:		carry	- set if want system target, clear if want
			  application target.
		(and, ds pointing to an LMem block)
RETURN:		cx:dx = optr of target or NULL
		ds    - gets fixed up
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Starting at the system object, walk down the
		target hierarchy until the leaf is reached.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/ 5/96    	Initial version
	jmagasin 4/10/96	App obj can return null target when app
				first launched.  If so, return null.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCBGetTarget	proc	near
	uses	bx, si, ax, di
		.enter

		mov	ax, MSG_META_GET_TARGET_EXCL
		jc	getSystemTarget
		call	UserCallApplication
		jmp	gotTopTargetNode
getSystemTarget:
		call	UserCallSystem
gotTopTargetNode:
		jnc	returnNull
		jcxz	returnNull
		Assert	optr cxdx

	;
	;  ^lcx:dx contains the optr of the top level target; we'll
	;  recursively send the GET_TARGET message until we get no
	;  response.
	;
targetLoop:
		movdw	bxsi, cxdx
		mov	ax, MSG_META_GET_TARGET_EXCL
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
		jnc	afterLoop
		jcxz	afterLoop		; bx:si was last node
		jmp	targetLoop
afterLoop:
		movdw	cxdx, bxsi
done:
		.leave
		ret
	;
	;  Apparently, there ain't no focus/target
	;
returnNull:		
		clr	cx, dx
		jmp	done
SCBGetTarget	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ServiceClipboardScbRaiseClipboardChangedEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This message should only be sent by the active selection
		in response to our sending it
		MSG_GADGET_CLIPBOARDABLE_CLIPBOARD_ITEM_CHANGED, or
		directly from SCBNotifyNormalTransferItemChanged if
		the active selection is not a clipboardable component.

CALLED BY:	MSG_SCB_RAISE_CLIPBOARD_CHANGED_EVENT
PASS:		*ds:si	= ServiceClipboardClass object
		ds:di	= ServiceClipboardClass instance data
		ds:bx	= ServiceClipboardClass object (same as *ds:si)
		es 	= segment of ServiceClipboardClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/ 2/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ServiceClipboardScbRaiseClipboardChangedEvent	method dynamic ServiceClipboardClass, 
					MSG_SCB_RAISE_CLIPBOARD_CHANGED_EVENT
	.enter

EC <	test	ds:[di].SCBI_eventFlags, mask CEF_DOING_CLIPBOARD_CHANGED >
EC <	ERROR_Z -1						>
	mov	dx, cs
	mov	ax, offset clipboardItemChangedString
	call	ServiceRaiseEvent

	mov	di, ds:[si]
	add	di, ds:[di].ServiceClipboard_offset			
	BitClr	ds:[di].SCBI_eventFlags, CEF_DOING_CLIPBOARD_CHANGED
		
	.leave
	Destroy	ax, cx, dx, bp
	ret
ServiceClipboardScbRaiseClipboardChangedEvent	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCBGetActiveSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the most recent clipboardable boolean.

CALLED BY:	MSG_SCB_GET_ACTIVE_SELECTION

PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	3 oct 95	initial revision
	jmagasin 4/29/96	Changed check for GadgetClipboardableClass
				to check for GadgetClass.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCBGetActiveSelection	method dynamic ServiceClipboardClass,
			MSG_SCB_GET_ACTIVE_SELECTION
	.enter

		push	bp
		stc				; Want system target.
		call	SCBGetTarget		; ^lcx:dx = target
		jcxz	returnCXDX
		movdw	bxsi, cxdx
		
	;
	; Make sure the focus is really an ent object.
	;

	; first make sure we are the thread running this object block
	; so ObjLockObjBlock doesn't barf at us with LOCK_BY_WRONG_THREAD
		push	bx
		clr	bx
		mov	ax, TGIT_THREAD_HANDLE
		call	ThreadGetInfo
		mov	di, bx
	; di now is handle of current thread
		pop	bx
		mov	ax, MGIT_EXEC_THREAD
		call	MemGetInfo
		cmp	ax, di
		jne	returnNull
		
	; ok, at least we are the right thread, lets check out the block
		push	ds	; sysui object block
		call	ObjLockObjBlock
		mov	ds, ax
		mov	ax, segment GadgetClass
		mov	es, ax
		mov	di, offset GadgetClass
		call	ObjIsObjectInClass
		call	MemUnlock
		pop	ds		; sysui object block
		jc	returnCXDX
returnNull:
		clrdw	cxdx
		
returnCXDX:
		pop	bp
		Assert	fptr	ssbp
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_COMPONENT
		movdw	es:[di].CD_data.LD_comp, cxdx
		
		.leave
		Destroy	ax, cx, dx
		ret
SCBGetActiveSelection	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCBGetClipboardAble
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the most recent clipboardable boolean.

CALLED BY:	MSG_SCB_GET_CLIPBOARDABLE

PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	3 oct 95	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCBGetClipboardable	method dynamic ServiceClipboardClass,
			MSG_SCB_GET_CLIPBOARDABLE
	.enter

	mov	al, ds:[di].SCBI_activeSelectionState
	and	al, mask ASSF_COPYABLE
	call	SCBGetWhateverableCommon

	.leave
	Destroy	ax, cx, dx
	ret
SCBGetClipboardable	endm

SCBGetDeletable	method dynamic ServiceClipboardClass,
			MSG_SCB_GET_DELETABLE
	.enter

	mov	al, ds:[di].SCBI_activeSelectionState
	and	al, mask ASSF_DELETABLE
	call	SCBGetWhateverableCommon

	.leave
	Destroy	ax, cx, dx
	ret
SCBGetDeletable	endm

SCBGetPastable		method dynamic ServiceClipboardClass,
			MSG_SCB_GET_PASTABLE
	.enter

	mov	al, ds:[di].SCBI_activeSelectionState
	and	al, mask ASSF_PASTABLE
	call	SCBGetWhateverableCommon

	.leave
	Destroy	ax, cx, dx
	ret
SCBGetPastable	endm

SCBGetWhateverableCommon	proc	near
	clr	ah
	tst	ax
	jz	gotIt

	mov	ax, 1
gotIt:
	les	di, ss:[bp].SPA_compDataPtr
	Assert	fptr	esdi
	mov	es:[di].CD_type, LT_TYPE_INTEGER
	mov	es:[di].CD_data.LD_integer, ax
	ret
SCBGetWhateverableCommon	endp
 

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCBActionQueryItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tests the current clipboard item for the specified format

CALLED BY:	MSG_SCB_ACTION_QUERYITEM
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- EntDoActionArgs
RETURN:		EDAA_retval filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	ACTION QueryItem(format as string)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	3 oct 95	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCBActionQueryItem	method dynamic ServiceClipboardClass, 
			MSG_SCB_ACTION_QUERYITEM
	uses	bp
	.enter

	mov	si, bp
	call	SCBQueryItemCommon
	jc	done

	;
	;  If there aren't any formats, then we don't bother checking
	;  for any one in particular.
	;
	tst	bp
	jz	setVal

	;
	;  See about our particular format
	;
	call	ClipboardTestItemFormat

	;
	;  bp is still contains the number of formats on the
	;  clipboard, which we'll use as the "true" value
	jnc	setVal

	clr	bp

setVal:
	les	di, ss:[si].EDAA_retval
	mov	es:[di].CD_type, LT_TYPE_INTEGER
	mov	es:[di].CD_data.LD_integer, bp

	call	ClipboardDoneWithItem

done:

	.leave
	ret
SCBActionQueryItem	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCBActionGetItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the specified format from the clipboard if it exists.

CALLED BY:	MSG_SCB_ACTION_GETITEM
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- EntDoActionArgs
RETURN:		EDAA_retval filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	ACTION GetItem(format as string)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	3 oct 95	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCBActionGetItem	method dynamic ServiceClipboardClass, 
			MSG_SCB_ACTION_GETITEM
	uses	bp
	.enter

	;
	;  First we have to see if the thing exists
	;
	mov	si, bp
	call	SCBQueryItemCommon
	jc	done

	pushdw	bxax

	;
	;  If there aren't any formats, then we're busted.
	;
	tst	bp				; any formats?
	jnz	request

notAvailable:

	popdw	bxax
	call	ClipboardDoneWithItem

	les	di, ss:[si].EDAA_retval
	mov	es:[di].CD_type, LT_TYPE_ERROR
	mov	es:[di].CD_data.LD_error, CPE_SPECIFIC_PROPERTY_ERROR
	jmp	done

popCIFIDnotAvailable:
	popdw	cxdx
	jmp	notAvailable

request:
	
	push	cx				; save CIFID in case we
	push	dx				; need it to make a complex
						; out of the thing
	call	ClipboardRequestItemFormat	; bxaxbp

	tst	ax
	jz	popCIFIDnotAvailable

	;
	; 
	cmp	di, LCBT_STRING
	jne	notText

	;
	;  the thing is in text format, so let's convert it to a string
	;

	mov	cx, bx				; cx <- vm file
	mov_tr	di, ax				; di <- vm block

	;
	;  Allocate a text object to do our dirty work for us
	;
	push	si				; save EDAA
	clr	ax, bx
	call	TextAllocClipboardObject

	;
	;  Stuff the CIF_TEXT transfer item into the thing
	;
	mov	dx, size CommonTransferParams
	sub	sp, dx
	mov	bp, sp
	clr	ax
	movdw	ss:[bp].CTP_range.VTR_start, axax
	movdw	ss:[bp].CTP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ss:[bp].CTP_pasteFrame, ax
	mov	ss:[bp].CTP_vmFile, cx
	mov	ss:[bp].CTP_vmBlock, di

	mov	ax, MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_FORMAT
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage

	add	sp, size CommonTransferParams

	;
	;  Figure out how big a block we'll need to hold the text
	;

	mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage				;dx:ax <- size

	;
	;  FIXME: check for too much text. Or maybe we'll just take the
	;  first MAX_STRING_SIZE chars
	;

	tst	dx
	jnz	maxSize
	tst	ax
	jz	haveString
	cmp	ax, MAX_STRING_SIZE
	jbe	haveSize
maxSize:
	mov	ax, MAX_STRING_SIZE

haveSize:

	;
	;  Create string space on the heap
	;
	mov_tr	cx, ax					; cx <- text size
	inc	cx
DBCS <	shl	cx						>
	push	bx
	mov	bx, RHT_STRING
	clr	ax, dx, di
	call	RunHeapAlloc_asm
	pop	bx

	;
	;  Lock the new string down so we can scrawl into it.
	;
	call	RunHeapLock_asm
	push	ax

	;
	;  Spew the text into the allocated buffer
	;
	sub	sp, size VisTextGetTextRangeParameters
	mov	bp, sp
	movdw	ss:[bp].VTGTRP_range.VTR_start, 0
	movdw	ss:[bp].VTGTRP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ss:[bp].VTGTRP_textReference.TR_type, TRT_POINTER
	movdw	ss:[bp].VTGTRP_textReference.TR_ref.TRU_pointer.TRP_pointer, esdi
	clr	ss:[bp].VTGTRP_flags
	mov	ax, MSG_VIS_TEXT_GET_TEXT_RANGE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	add	sp, size VisTextGetTextRangeParameters

	;
	;  FIXME: Free our the text object. Maybe use
	;  TextFinishWithClipboardObject with TCO_RETURN_NOTHING??? Why???
	;
	call	MemFree

	;
	;  Unlock the heap, and done.
	;
	pop	ax
	call	RunHeapUnlock_asm

haveString:
	pop	si					; ss:si <- EDAA
	les	di, ss:[si].EDAA_retval
	mov	es:[di].CD_type, LT_TYPE_STRING
	mov	es:[di].CD_data.LD_string, ax
	jmp	doneWithItem

	
notText:
	cmp	di, LCBT_INTEGER
	jne	checkLong

	les	di, ss:[si].EDAA_retval
	mov	es:[di].CD_type, LT_TYPE_INTEGER
	mov	es:[di].CD_data.LD_integer, dx
	jmp	doneWithItem

checkLong:

	cmp	di, LCBT_LONG
	jne	checkFloat

	les	di, ss:[si].EDAA_retval
	mov	es:[di].CD_type, LT_TYPE_LONG
	movdw	es:[di].CD_data.LD_long, cxdx
	jmp	doneWithItem

checkFloat:

	cmp	di, LCBT_FLOAT
	jne	nan

	push	ax, bx

	mov	ax, FP_MIN_STACK_ELEMENTS
	mov	bl, FLOAT_STACK_DEFAULT_TYPE
	call	FloatInit

	pop	ax, bx
	call	VMLock
	mov	ds, ax
	les	di, ss:[si].EDAA_retval
	mov	si, size FloatTransferBlockHeader

	call	FloatPushNumber
	call	VMUnlock
	call	FloatGeos80ToIEEE32		; dx:ax <- IEEE32 format
	call	FloatExit

	mov	es:[di].CD_type, LT_TYPE_FLOAT
	movdw	es:[di].CD_data.LD_long, dxax
	jmp	doneWithItem

nan:

;default:
	;
	;  The default case is going to be to make a copy of the
	;  thing and stuff a pointer to it on the runtime heap.
	;

	push	bx				; save vm file header

	mov	dx, bx				
	call	VMCopyVMChain

	pushdw	axbp				; save vm chain of duplicate

	;
	;  Allocate a LegosComplex on the runtime heap
	;
	mov	cx, size LegosComplex
	mov	bx, RHT_COMPLEX
	clr	ax, dx, di
	call	RunHeapAlloc_asm
	call	RunHeapLock_asm

	;
	;  Spew in the data
	;
	popdw	es:[di].LC_chain
	pop	es:[di].LC_vmfh
	pop	es:[di].LC_format.CIFID_type
	pop	es:[di].LC_format.CIFID_manufacturer

	call	RunHeapUnlock_asm

	les	di, ss:[si].EDAA_retval
	mov	es:[di].CD_type, LT_TYPE_COMPLEX
	mov	es:[di].CD_data.LD_complex, ax
	jmp	doneWithItemNoClear

doneWithItem:
	popdw	axax				; clear CIFID
doneWithItemNoClear:
	popdw	bxax
	call	ClipboardDoneWithItem

done:
	.leave
	ret
SCBActionGetItem	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SCBQueryItemCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decodes the passed string arg into a ClipboardItemFormatID,
		and calls ClipboardQueryItem; ClipboardDoneWithItem must
		be called if this routine returns success.

CALLED BY:	MSG_SCB_ACTION_GETITEM, MSG_SCB_ACTION_QUERYITEM

PASS:		ss:[si] - EntDoActionArgs with a single LT_TYPE_STRING arg

RETURN:		carry clear:

		  Note: ClipboardDoneWithItem must subsequently be called!

			bp - number of formats available on clipboard

			cx:dx - ClipboardItemFormatID associated
				with the passed string arg

			bx:ax - (VM file handle):(VM block handle)
				to transfer item header
				(pass to ClipboardRequestItemFormat)

		carry set:

			EDAA_retval filled in with error

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	3 oct 95	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LegosClipboardFormatTranslationTable	ClipboardItemFormatID	\
	<CIF_TEXT, MANUFACTURER_ID_GEOWORKS>,
	<CIF_INTEGER, MANUFACTURER_ID_LEGOS>,
	<CIF_LONG, MANUFACTURER_ID_LEGOS>,	
	<CIF_FLOAT, MANUFACTURER_ID_LEGOS>,	
	<0, 0>,
	<CIF_GRAPHICS_STRING, MANUFACTURER_ID_GEOWORKS>,
	<CIF_FAX_FILE_PAGE_WITH_INK, MANUFACTURER_ID_GEOWORKS>,
	<CIF_SOUND_SAMPLE, MANUFACTURER_ID_GEOWORKS>,
	<CIF_SPREADSHEET, MANUFACTURER_ID_GEOWORKS>

CheckHack <length LegosClipboardFormatTranslationTable eq LegosClipboardableType>

SCBQueryItemCommon	proc	near
	.enter
				
	;
	; Make sure we got the 1 argument
	;

		les	di, ss:[si].EDAA_argv
		Assert	fptr esdi
		cmp	es:[di].CD_type, LT_TYPE_STRING
		jne	typeError

	;
	;  Lock the string down into es:di
	;
		mov	ax, es:[di].CD_data.LD_string
		push	ax
		call	RunHeapLock_asm
		Assert	fptr esdi

		pushdw	esdi
ifdef __HIGHC__
		call	SCBString2LCBT			; ax <- LCBT
else
		call	_SCBString2LCBT			; ax <- LCBT
endif
		add	sp, 4

		cmp	ax, LegosClipboardableType
		jae	lcbtError

		cmp	ax, LCBT_ARRAY
		je	lcbtError

		mov_tr	di, ax
		push	di
		shl	di
		shl	di
		movdw	cxdx, cs:[LegosClipboardFormatTranslationTable][di]
		pop	di

		mov_tr	bp, ax
		pop	ax
		pushdw	cxdx
		call	RunHeapUnlock_asm
		mov_tr	ax, bp

		clr	bp				; not quick
		call	ClipboardQueryItem		; bp <- # formats
		popdw	cxdx				; cx:dx <- id:type

		clc
done:
	.leave
	ret

lcbtError:
		pop	ax
		call	RunHeapUnlock_asm
		mov	ax, CPE_SPECIFIC_PROPERTY_ERROR
error:
		les	di, ss:[si].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, ax
		stc
		jmp	done

typeError:
		mov	ax, CPE_PROPERTY_TYPE_MISMATCH
		jmp	error		
SCBQueryItemCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCBActionSetItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Registers the passed data as the current clipboard item.

CALLED BY:	MSG_SCB_ACTION_SETITEM
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- EntDoActionArgs
RETURN:		EDAA_retval filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	ACTION SetItem(data as variant)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	3 oct 95	initial revision
	jmagasin 4/30/96	Handle nulling of transfer item.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCBActionSetItem	method dynamic ServiceClipboardClass, 
			MSG_SCB_ACTION_SETITEM
	uses	bp
	.enter

		les	di, ss:[bp].EDAA_argv
		Assert	fptr esdi

	;
	; If we're given a null run-heap token, nuke the transfer item.
	;
		mov	ax, es:[di].CD_type
		cmp	ax, LT_TYPE_COMPLEX
		jne	checkIfString

		tst	{word}es:[di].CD_data			; NULL?
		jnz	isComplex
		call	SCBNukeTransferItem
		jmp	done
		
checkIfString:
		cmp	ax, LT_TYPE_STRING
		jne	notString
	;
	; It's a string. No problem.
	;

		clr	ax, bx
		call	TextAllocClipboardObject

	;
	;  Lock the string down into es:di
	;
		mov	ax, es:[di].CD_data.LD_string
		call	RunHeapLock_asm

		Assert	fptr esdi

		push	bp
		push	ax
		movdw	dxbp, esdi
		clr	cx
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage

		pop	ax
		call	RunHeapUnlock_asm

		mov	ax, TCO_COPY
		clrdw	cxdx
		mov	di, -1
		call	TextFinishWithClipboardObject
		pop	bp
		jmp	success

notString:
		cmp	ax, LT_TYPE_COMPLEX
		jne	notComplex
	;
	;  The thing's just a complex data type, so make a copy of
	;  the thing and let's go!
	;
isComplex:
		mov	ax, es:[di].CD_data.LD_complex
		tst	ax
		jz	blech
		call	RunHeapLock_asm

		push	ax, bp				; save complex
							; token, local ptr

		mov	dx, es:[di].LC_vmfh
		movdw	axbp, es:[di].LC_chain

		call	ClipboardGetClipboardFile	; bx <- clipboard file
		xchg	bx, dx				; dx <- clipboard file
							; bx <- source vm file
		call	VMCopyVMChain			; dxaxbp <- copied item
		mov	bx, dx
		mov	cx, es:[di].LC_format.CIFID_manufacturer
		mov	dx, es:[di].LC_format.CIFID_type
		clr	di, si
		call	SCBGenerateTransferItem

		pop	ax, bp				;ax <- complex,
							;bp <- local ptr
		call	RunHeapUnlock_asm
		jmp	success

notComplex:
		cmp	ax, LT_TYPE_INTEGER
		jne	checkLong

		push	bp, di, si
		call	ClipboardGetClipboardFile
		clr	ax, bp
	;
	; The clipboard mechanism requires that we pass something in
	; here, but we don't *need* any other data, since the "other data"
	; dword serves our purposes just fine. We allocate a byte here
	; 'cause allocating nothing will give us an empty block, which
	; would confuse the clipboard mechanism when it tries to free the
	; thing.
	;
		mov	cx, 1
		call	VMAlloc
		mov	si, es:[di].CD_data.LD_integer
		clr	di
		mov	cx, MANUFACTURER_ID_GEOWORKS	;  ID_LEGOS
		mov	dx, CIF_INTEGER
		call	SCBGenerateTransferItem
		pop	bp, di, si
		jmp	success

checkLong:
		cmp	ax, LT_TYPE_LONG
		jne	checkFloat
	
		push	bp, di, si
		call	ClipboardGetClipboardFile
		clr	ax, bp
		mov	cx, 1
		call	VMAlloc
		mov	si, es:[di].CD_data.LD_long.low
		mov	di, es:[di].CD_data.LD_long.high
		mov	cx, MANUFACTURER_ID_GEOWORKS	; ID_LEGOS 
		mov	dx, CIF_LONG
		call	SCBGenerateTransferItem
		pop	bp, di, si
		jmp	success

checkFloat:
		cmp	ax, LT_TYPE_FLOAT
		jne	blech

		movdw	cxdx, es:[di].CD_data.LD_float

		push	bp				; save local ptr.
		push	cx, dx				; save data
		push	ax				; save LT
		mov	ax, FP_MIN_STACK_ELEMENTS
		mov	bl, FLOAT_STACK_DEFAULT_TYPE
		call	FloatInit

		call	ClipboardGetClipboardFile
		clr	ax
		mov	cx, size FloatTransferBlockHeader + size FloatNum
		call	VMAlloc
		mov	si, ax				;si <- new block
		call	VMLock
		mov	es, ax			;es = transfer item
		mov	es:[FTBH_link].VMCL_next, 0
		mov	es:[FTBH_numFloats], 1

		pop	ax				; ax <- CIF

		cmp	ax, LT_TYPE_FLOAT
		jne	notFloat

		pop	dx, ax
		push	dx, ax
		call	FloatIEEE32ToGeos80		;once for Float2DWord
		pop	dx, ax
		call	FloatIEEE32ToGeos80		;and once for FloatPop
		call	FloatFloatToDword	;dx:ax <- dword equivalent
		jmp	numOnStack

notFloat:
		pop	dx, ax
		push	ax
		call	FloatDwordToFloat
		pop	ax

numOnStack:
		mov	di, size FloatTransferBlockHeader
		call	FloatPopNumber		;es:di <- float
		call	VMUnlock
		call	FloatExit

		xchg	si, ax			;ax <- vm block handle
						;si <- low word
		mov	di, dx	
		mov	cx, MANUFACTURER_ID_GEOWORKS	; was ID_LEGOS 
		mov	dx, CIF_FLOAT
		clr	bp		; not a dbitem
		call	SCBGenerateTransferItem
		pop	bp
		jmp	success

	;
	; FIXME: return something meaningful here...?
	;
blech:
success:
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, 1
done::
	.leave
	ret
SCBActionSetItem	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	SCBGenerateTransferItem

DESCRIPTION:	Generate a transfer item for the currently selected region

CALLED BY:	

PASS:
	bx:ax:bp - vm file:block:dbitem of item
	cx:dx - manuf id:format 
	di - extra data 1
	si - extra data 2
RETURN:
	nothing

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@
SCBGenerateTransferItem	proc	near	uses ax, bx, cx, dx, si, di, bp, es
	.enter

	push	cx				; save manuf. id
	push	dx				; save format #

	;
	; Allocate a ClipboardItemHeader and fill in the relevant fields
	;
	mov	cx, size ClipboardItemHeader

	pushdw	axbp				;save block:dbitem

	clr	ax				;user ID?
	call	VMAlloc
	mov	dx, ax				;save block handle in dx
	call	VMLock
	mov	es, ax				;es = transfer item

	; set up header

	clrdw	es:[CIH_sourceID]
	clrdw	es:[CIH_owner]
	mov	es:[CIH_formatCount], 1

	popdw	es:[CIH_formats][0].CIFI_vmChain

	pop	es:[CIH_formats][0].CIFI_format.CIFID_type
	pop	es:[CIH_formats][0].CIFI_format.CIFID_manufacturer

	mov	es:[CIH_formats][0].CIFI_extra1, di
	mov	es:[CIH_formats][0].CIFI_extra2, si

	; copy name

	clr	es:[CIH_name][0]

	call	VMUnlock

	clr	bp
	mov_tr	ax, dx				;ax <- block handle
	call	ClipboardRegisterItem

	.leave
	ret
SCBGenerateTransferItem	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCBNukeTransferItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nukes the current transfer item (if any).

CALLED BY:	SCBActionSetItem only
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bp, bx
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 4/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCBNukeTransferItem	proc	near
		.enter

		call	ClipboardGetClipboardFile	; bx <- file handle
		clr	ax, bp				; null the nrml item
		call	ClipboardRegisterItem
		Assert	carryClear
		
		.leave
		ret
SCBNukeTransferItem	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SCBActionCut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a 

CALLED BY:	MSG_SCB_ACTION_GETDAYOFWEEK
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- EntDoActionArgs
RETURN:		EDAA_retval filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	ACTION GetDayOfWeek(year as int, month as int, day as int) AS integer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/23/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCBActionCut	method dynamic ServiceClipboardClass, MSG_SCB_ACTION_CUT
	.enter

	mov	al, ds:[di].SCBI_activeSelectionState
	test	al, mask ASSF_DELETABLE
	jz	done
	test	al, mask ASSF_COPYABLE
	jz	done
	mov	ax, MSG_META_CLIPBOARD_CUT
	call	SCBOutputActionCommon
done:
	.leave
	ret
SCBActionCut	endm


SCBActionCopy	method dynamic ServiceClipboardClass, MSG_SCB_ACTION_COPY
	.enter

	test	ds:[di].SCBI_activeSelectionState, mask ASSF_COPYABLE
	jz	done
	mov	ax, MSG_META_CLIPBOARD_COPY
	call	SCBOutputActionCommon
done:
	.leave
	ret
SCBActionCopy	endm


SCBActionPaste	method dynamic ServiceClipboardClass, MSG_SCB_ACTION_PASTE
	.enter

	test	ds:[di].SCBI_activeSelectionState, mask ASSF_PASTABLE
	jz	done
	mov	ax, MSG_META_CLIPBOARD_PASTE
	call	SCBOutputActionCommon
done:
	.leave
	ret
SCBActionPaste	endm


SCBActionDelete	method dynamic ServiceClipboardClass, MSG_SCB_ACTION_DELETE
	.enter

	test	ds:[di].SCBI_activeSelectionState, mask ASSF_DELETABLE
	jz	done
	mov	ax, MSG_META_DELETE
	call	SCBOutputActionCommon
done:
	.leave
	ret
SCBActionDelete	endm


SCBOutputActionCommon	proc near
	uses	ax, bx, cx, dx, di, si
	.enter

	;
	;  Record a classless classed event with the passed message
	;
	clr	bx, si
	mov	di, mask MF_RECORD
	call	ObjMessage

	;
	;  Send the thing to the application
	;
	clr	bx
	call	GeodeGetAppObject

	mov	cx, di
	mov	dx, TO_TARGET
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
SCBOutputActionCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCReadonlyError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a readonly property error

CALLED BY:	MSG_SCB_SET_PASTABLE
PASS:		*ds:si	= ServiceClipboardClass object
		ds:di	= ServiceClipboardClass instance data
		ds:bx	= ServiceClipboardClass object (same as *ds:si)
		es 	= segment of ServiceClipboardClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	1/19/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCScbSetPastable	method dynamic ServiceClipboardClass, 
					MSG_SCB_SET_PASTABLE, \
					MSG_SCB_SET_DELETABLE, \
					MSG_SCB_SET_CLIPBOARDABLE, \
					MSG_SCB_SET_ACTIVE_SELECTION
		.enter

		call	GadgetUtilReturnReadOnlyError
		
		.leave
		ret
SCScbSetPastable	endm


.warn @private
