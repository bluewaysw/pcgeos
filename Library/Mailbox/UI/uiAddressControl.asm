COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		uiAddressControl.asm

AUTHOR:		Allen Yuen, Jun 16, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	6/16/94   	Initial revision


DESCRIPTION:
	Implementation of the MailboxAddressControlClass
		

	$Id: uiAddressControl.asm,v 1.1 97/04/05 01:18:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MailboxClassStructures	segment	resource

	MailboxAddressControlClass

MailboxClassStructures	ends

MBAddressCtrlCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MACMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the non-zero portions of our instance data

CALLED BY:	MSG_META_INITIALIZE
PASS:		*ds:si	= MailboxAddressControl object
		ds:di	= MailboxAddressControlInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		address controls start with a reference count of 1, since
		we assume they've been created to be used by the send dialog

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MACMetaInitialize method dynamic MailboxAddressControlClass, MSG_META_INITIALIZE
		mov	ds:[di].MACI_refCount, 1
		mov	di, offset MailboxAddressControlClass
		call	ObjCallSuperNoLock
	;
	; Add ourselves to the list of address controls maintained by the
	; MailboxApplication object, so it knows not to go away until we're
	; fully freed.
	; 
		mov	ax, MGCNLT_ADDRESS_CONTROLS
		call	UtilAddToMailboxGCNList
		ret
MACMetaInitialize endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MACGetAddresses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a default address, for drivers that need an address
		control to create transData or something, but don't actually
		need an address

CALLED BY:	MSG_MAILBOX_ADDRESS_CONTROL_GET_ADDRESSES
PASS:		*ds:si	= MailboxAddressControl object
		ds:di	= MailboxAddressControlInstance
RETURN:		*ds:ax	= ChunkArray of MBACAddress structures
DESTROYED:	cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MACGetAddresses method dynamic MailboxAddressControlClass, 
				MSG_MAILBOX_ADDRESS_CONTROL_GET_ADDRESSES

	;
	; Return a copy of MACI_defaultAddrs if it exists.
	;
		mov	si, ds:[di].MACI_defaultAddrs
		tst	si
		jz	createDefault
		mov	bx, ds:[OLMBH_header].LMBH_handle ; ^lbx:si = array
		call	UtilCopyChunk	; *ds:si = duplicate
		mov_tr	ax, si		; *ds:ax = duplicate
		ret

createDefault:
		mov	ax, 1
		FALL_THRU MACCreateDefaultAddress

MACGetAddresses endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MACCreateDefaultAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an array of default addresses

CALLED BY:	(EXTERNAL) MACGetAddresses, MSDCreateDefaultAddress
PASS:		ax	= number of significant bytes (i.e. size of the
			  opaque part of the address)
		ds	= block in which to allocate the array
RETURN:		*ds:ax	= ChunkArray
		es fixed up if pointing to ds on entry
DESTROYED:	bx, cx, dx, si, di
SIDE EFFECTS:	block may move

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 5/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MACCreateDefaultAddress proc	far
		.enter
	;
	; Create an array with variable-sized elements to hold the address.
	; 
   		push	ax		; save # bytes
		clr	bx, cx, ax, si	; bx <- variable-sized elements
					; cx <- default header size
					; al <- no special flags
					; si <- allocate chunk please
		call	ChunkArrayCreate
	;
	; Now to generate the address. We need first to figure out how big the
	; default human-readable address is, so lock down that block and figure
	; it out.
	; 
		mov	bx, handle uiSomeoneElse
		call	MemLock
		push	ds
		mov	ds, ax
		assume	ds:segment uiSomeoneElse
		ChunkSizeHandle ds, uiSomeoneElse, cx
		pop	ds
	;
	; Compute the size of the element: the fixed size + the size of the
	; opaque + size of the user-readable address.
	; 
		pop	bx			; bx <- # address bytes
		add	cx, bx
		add	cx, size MBACAddress
		xchg	ax, cx			; ax <- element size,
						; cx <- string block segment
		call	ChunkArrayAppend
	;
	; Set up the element. The thing is zero-initialized, so we can leave
	; the opaque portion alone.
	; 
		push	es
		segmov	es, ds			; es <- our block
		mov	ds, cx			; ds <- string block
		mov	es:[di].MBACA_opaqueSize, bx
		lea	di, es:[di].MBACA_opaque[bx]	; es:di <- storage for
							;  human-readable
							;  address
		mov_tr	ax, si			; ax <- array handle
		mov	si, ds:[uiSomeoneElse]
		ChunkSizePtr ds, si, cx
		rep	movsb
		call	UtilUnlockDS
	;
	; Set up the relevant portions of the transaction.
	; 
		assume	ds:nothing
		segmov	ds, es			; ds <- our block, again
		pop	es			; es <- passed or fixed-up
						;  es
		.leave
		ret
MACCreateDefaultAddress endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MACSetAddresses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the addresses as our default addresses.

CALLED BY:	MSG_MAILBOX_ADDRESS_CONTROL_SET_ADDRESSES
PASS:		*ds:si	= MailboxAddressControlClass object
		ds:di	= MailboxAddressControlClass instance data
		^lcx:dx	= chunk array of MBACAddress structures
			if chunk array is zero the default addresses are
			deleted.
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	2/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MACSetAddresses	method dynamic MailboxAddressControlClass, 
				MSG_MAILBOX_ADDRESS_CONTROL_SET_ADDRESSES

	;
	; Free old default addresses, if any.
	;
	clr	ax
	xchg	ax, ds:[di].MACI_defaultAddrs
	tst	ax
	jz	copyArray
	call	LMemFree

copyArray:
	;
	; If the chunk array optr is zero it means that we just want to
	; delete the defaultAddrs and not copy a new one.
	;
	tstdw	cxdx
	jz	done
		
	;
	; Copy the new array into our block.
	;
	push	si			; save self lptr
	movdw	bxsi, cxdx
	call	UtilCopyChunk		; *ds:si = duplicated array
	pop	di			; *ds:di = self
	mov	di, ds:[di]
	add	di, ds:[di].MailboxAddressControl_offset
	mov	ds:[di].MACI_defaultAddrs, si	
done:
	ret
MACSetAddresses	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MACGetTransData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just be tidy and always return 0 if subclass doesn't handle
		this.

CALLED BY:	MSG_MAILBOX_ADDRESS_CONTROL_GET_TRANS_DATA
PASS:		*ds:si	= MailboxAddressControl object
		ds:di	= MailboxAddressControlInstance
RETURN:		dxax	= 32-bit transData to store with message
DESTROYED:	cx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MACGetTransData method dynamic MailboxAddressControlClass, 
				MSG_MAILBOX_ADDRESS_CONTROL_GET_TRANS_DATA
		.enter
		clr	dx, ax
		Destroy	cx, bp
		.leave
		ret
MACGetTransData endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MACAddRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note another reference to this controller.

CALLED BY:	MSG_MAILBOX_ADDRESS_CONTROL_ADD_REF
PASS:		*ds:si	= MailboxAddressControl object
		ds:di	= MailboxAddressControlInstance
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MACAddRef	method dynamic MailboxAddressControlClass, 
				MSG_MAILBOX_ADDRESS_CONTROL_ADD_REF
		.enter
		inc	ds:[di].MACI_refCount
		.leave
		ret
MACAddRef	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MACDelRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a reference to this controller. If the count is 0,
		destroy the controller.

CALLED BY:	MSG_MAILBOX_ADDRESS_CONTROL_DEL_REF
PASS:		*ds:si	= MailboxAddressControl object
		ds:di	= MailboxAddressControlInstance
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We assume the controller has been removed from the generic
		tree and set not usable (causing children to be destroyed,
		objects to come off GCN lists, etc.) before this happens, so
		we are free to use META_OBJ_FREE on ourselves to commit
		suicide.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MACDelRef	method dynamic MailboxAddressControlClass, 
				MSG_MAILBOX_ADDRESS_CONTROL_DEL_REF
		.enter
		Assert	ne, ds:[di].MACI_refCount, 0
		dec	ds:[di].MACI_refCount
		jnz	done
		push	ax, cx, dx, bp
		mov	ax, MSG_META_OBJ_FREE
		call	ObjCallInstanceNoLock
		pop	ax, cx, dx, bp
done:
		.leave
		ret
MACDelRef	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MACMetaFinalObjFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unload the transport driver from which we came before we
		perish.

CALLED BY:	MSG_META_FINAL_OBJ_FREE
PASS:		*ds:si	= MailboxAddressControl object
		ds:di	= MailboxAddressControlInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	Driver may be unloaded, so this method should not have to
		return to any code of the subclass...

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MACMetaFinalObjFree method dynamic MailboxAddressControlClass, 
				MSG_META_FINAL_OBJ_FREE
		mov	bx, ds:[di].MACI_driver
	;
	; Change the thing to be a straight MailboxAddressControl object, since
	; we may cause the actual class of the thing to go away when we free
	; the driver.
	; 
		mov	di, offset MailboxAddressControlClass
		call	UtilChangeClass
	;
	; Unload the transport driver.
	; 
		call	MailboxFreeDriver
	;
	; Remove ourselves from the list of address controls maintained by the
	; MailboxApplication object, so it knows it can go away now, the trans-
	; port driver being now unloaded.
	; 
		push	ax
		mov	ax, MGCNLT_ADDRESS_CONTROLS
		call	UtilRemoveFromMailboxGCNList
		pop	ax
		GOTO	ObjCallSuperNoLock
MACMetaFinalObjFree endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MACSetValidState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the dialog know whether its Send trigger should be
		enabled.

CALLED BY:	MSG_MAILBOX_ADDRESS_CONTROL_SET_VALID_STATE
PASS:		*ds:si	= MailboxAddressControl object
		ds:di	= MailboxAddressControlInstance
		cx	= FALSE if address not valid
			= TRUE if address is valid
RETURN:		nothing
DESTROYED:	ax, cx
SIDE EFFECTS:	guess

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MACSetValidState method dynamic MailboxAddressControlClass, 
				MSG_MAILBOX_ADDRESS_CONTROL_SET_VALID_STATE
		.enter
EC <		jcxz	argsOK						>
EC <		cmp	cx, TRUE					>
EC <		ERROR_NE VALID_STATE_FLAG_NEITHER_TRUE_NOR_FALSE	>
EC <argsOK:								>
		push	ax, dx, bp
		mov	ax, ds:[di].MACI_validMsg	; ax <- message to send
		mov	bp, si
		mov	dx, ds:[LMBH_handle]		; ^ldx:bp <- sender
		pushdw	ds:[di].MACI_validDest
		mov	di, mask MF_FIXUP_DS
		call	GenProcessAction
		pop	ax, dx, bp
		.leave
		ret
MACSetValidState endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MACSetValidAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record where the valid notification should be sent

CALLED BY:	MSG_MAILBOX_ADDRESS_CONTROL_SET_VALID_ACTION
PASS:		*ds:si	= MailboxAddressControl object
		ds:di	= MailboxAddressControlInstance
		^lcx:dx	= notification OD
		bp	= notification message
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/24/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MACSetValidAction method dynamic MailboxAddressControlClass, 
				MSG_MAILBOX_ADDRESS_CONTROL_SET_VALID_ACTION
		.enter
		Assert	optr, cxdx
		movdw	ds:[di].MACI_validDest, cxdx
		mov	ds:[di].MACI_validMsg, bp
		Destroy	cx, dx, bp
		.leave
		ret
MACSetValidAction endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MACGetTransmitMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the moniker to use in the Send trigger of the dialog

CALLED BY:	MSG_MAILBOX_ADDRESS_CONTROL_GET_TRANSMIT_MONIKER
PASS:		*ds:si	= MailboxAddressControl object
		ds:di	= MailboxAddressControlInstance
RETURN:		^lcx:dx	= moniker to use
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/24/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MACGetTransmitMoniker method dynamic MailboxAddressControlClass, 
				MSG_MAILBOX_ADDRESS_CONTROL_GET_TRANSMIT_MONIKER
		.enter
		mov	cx, handle uiDefaultTransmitMoniker
		mov	dx, offset uiDefaultTransmitMoniker
		.leave
		ret
MACGetTransmitMoniker endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MACCreateMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default method to tell the caller it should create the
		message the usual way

CALLED BY:	MSG_MAILBOX_ADDRESS_CONTROL_CREATE_MESSAGE
PASS:		*ds:si	= MailboxAddressControl object
		ds:di	= MailboxAddressControlInstance
		cx	= MailboxObjectType
		*dx:bp	= MSCTransaction
RETURN:		carry set if message will be created by transport driver
		carry clear if caller should create it
DESTROYED:	ax, dx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/25/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MACCreateMessage method dynamic MailboxAddressControlClass, 
				MSG_MAILBOX_ADDRESS_CONTROL_CREATE_MESSAGE
		.enter
		Destroy	dx
		clc
		.leave
		ret
MACCreateMessage endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MACSetTransportDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the handle of the driver that returned the subclass
		of which this object is an instance.

CALLED BY:	MSG_MAILBOX_ADDRESS_CONTROL_SET_TRANSPORT_DRIVER
PASS:		*ds:si	= MailboxAddressControl object
		ds:di	= MailboxAddressControlInstance
		cx	= driver handle
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MACSetTransportDriver method dynamic MailboxAddressControlClass, 
				MSG_MAILBOX_ADDRESS_CONTROL_SET_TRANSPORT_DRIVER
		.enter
		mov	ds:[di].MACI_driver, cx
		.leave
		ret
MACSetTransportDriver endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MACCreateFeedback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the feedback box, add it as a child under MailboxApp.

CALLED BY:	MSG_MAILBOX_ADDRESS_CONTROL_CREATE_FEEDBACK,
		MSDCreateFeedbackBox
PASS:		^ldx:bp	= MSCTransaction to fill in
		ds	= any valid segment (for fix-up)
RETURN:		(^ldx:bp).MSCT_feedback set to duplicated block
		ds fixed up
DESTROYED:	ax, bx, si, di
		es possibly invalidated
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	3/ 6/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_OUTBOX_FEEDBACK
MACCreateFeedback	method MailboxAddressControlClass, 
				MSG_MAILBOX_ADDRESS_CONTROL_CREATE_FEEDBACK
	uses	cx, dx, bp
	.enter

	;
	; Build the feedback note on the mailbox thread (so animation can
	; run concurrently to message creation)
	;
	mov	bx, dx			; ^lbx:si = MSCTransaction
	mov	si, bp
	mov	cx, handle OutboxFeedbackNoteRoot
	mov	dx, offset OutboxFeedbackNoteRoot
	mov	ax, MSG_GEN_APPLICATION_BUILD_DIALOG_FROM_TEMPLATE
	mov	di, mask MF_FIXUP_DS
	call	UtilCallMailboxApp

	push	ds
	call	ObjLockObjBlock
	mov	ds, ax			; *ds:si = MSCTransaction
	mov	si, ds:[si]
	movdw	ds:[si].MSCT_feedback, cxdx
	call	MemUnlock
	pop	ds

	.leave
	ret
MACCreateFeedback	endm
endif	; _OUTBOX_FEEDBACK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MACGenControlGetNormalFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hacked routine to return a non-zero features mask so we
		don't get marked not user-initiatable. We don't have
		features, but we have children...

CALLED BY:	MSG_GEN_CONTROL_GET_NORMAL_FEATURES
PASS:		nothing
RETURN:		ax	= current normal feature set
		cx	= required normal features
		dx	= prohibited normal features
		bp	= normal features supported by controller
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/25/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MACGenControlGetNormalFeatures	method dynamic MailboxAddressControlClass, 
					MSG_GEN_CONTROL_GET_NORMAL_FEATURES,
					MSG_GEN_CONTROL_GET_TOOLBOX_FEATURES

	clr	ax, dx			; xor + cwd
	dec	ax
	mov	cx, ax
	mov	bp, ax

	ret
MACGenControlGetNormalFeatures	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MACMetaDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept for META_DETACH that we don't want to process
		normally, since we always get destroyed before the application
		is allowed to finish detaching.

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= MailboxAddressControl object
		ds:di	= MailboxAddressControlInstance
		cx	= callerID
		dx:bp	= ack OD
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		For every DETACH, we generate an ACK immediately, unless
		our subclass has called ObjInitDetach (in which case we
		wait for the right number of ACK's to come in).
		
		In no case do we pass META_DETACH to our superclass, as that
		would cause our UI to be destroyed and wreak havoc when
		the MailboxSendControl cancels the sole remaining in-progress
		transaction, sometimes.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/28/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MACMetaDetach	method dynamic MailboxAddressControlClass, MSG_META_DETACH
		.enter
		mov	ax, DETACH_DATA
		call	ObjVarFindData
		jc	done			; => subclass called
						;  ObjInitDetach, so we wait for
						;  ACKs before declaring detach
						;  complete

		mov	ax, MSG_META_DETACH_COMPLETE
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
MACMetaDetach	endm
MBAddressCtrlCode	ends

; Local Variables:
; messages-use-class-abbreviation: nil
; End:
