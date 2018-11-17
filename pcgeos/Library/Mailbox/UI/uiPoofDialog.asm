COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		UI
FILE:		uiPoofDialog.asm

AUTHOR:		Allen Yuen, Oct 17, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT UPDAllocVMTAppRef	Allocate a VMTreeAppRef and fill in
				appropriate MRA_ fields.

    INT UPDAllocSubject		Allocate a chunk and copy the desired
				subject.

    INT UPDCleanupVMTBody	Cleanup message body of VM tree type.

    GLB MailboxConvertToMailboxTransferItem 
				Convert a clipboard transfer item to a
				mailbox transfer item.

    GLB MailboxConvertToClipboardTransferItem 
				Convert a mailbox transfer item to a
				clipboard transfer item.

    INT UPDReceiveClipboard	Receive a Clipboard transfer item message.

    INT UPDReceiveFile		Receive a File message.

    INT UPDReceiveQuickMsg	Receive a Quick Message and display on
				screen.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/17/94   	Initial revision


DESCRIPTION:
	Implementation of sending and receiving system (Poof) messages.

	$Id: uiPoofDialog.asm,v 1.1 97/04/05 01:18:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_POOF_MESSAGE_CREATION

MailboxClassStructures	segment	resource
	PoofSendDialogClass
	PoofQuickMessageSendDialogClass
	PoofFileSendDialogClass
	PoofClipboardSendDialogClass
MailboxClassStructures	ends

PoofControlCode	segment	resource

PoofControlCodeDerefGen proc near
	class	GenClass
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ret
PoofControlCodeDerefGen endp

PCCCallInstance	proc	near
	call	ObjCallInstanceNoLock
	ret
PCCCallInstance	endp

if ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls FatalError if some unexpected messages have reached
		this class.

CALLED BY:	messages that should not be received be PoofSendDialogClass
PASS:		nothing
RETURN:		never
DESTROYED:	GEOS session
SIDE EFFECTS:	death

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/17/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDError	method dynamic PoofSendDialogClass, 
	; These messages should not be sent to a PoofSendDialogClass or its
	; subclasses.
					MSG_MSD_SET_CONTENTS,

	; These messages must be intercepted by our subclasses.
					MSG_PSD_SEND_MESSAGE_GET_BODY

	ERROR	METHOD_MUST_BE_SUBCLASSED

PSDError	endm
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDMsdDataObjectUi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ignore messages regarding data object UI, as we have no
		place for it in these dialogs

CALLED BY:	MSG_MSD_ENABLE_DATA_OBJECT_UI
PASS:		*ds:si	= PoofSendDialog object
		ds:di	= PoofSendDialogInstance
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/11/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDMsdEnableDataObjectUi method dynamic PoofSendDialogClass, 
			 		MSG_MSD_ENABLE_DATA_OBJECT_UI,
					MSG_MSD_RESET_DATA_OBJECT_UI
		.enter
		.leave
		ret
PSDMsdEnableDataObjectUi endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDGenSetUsable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we're run by the mailbox thread, make ourselves sysmodal
		so we appear.

CALLED BY:	MSG_GEN_SET_USABLE
PASS:		*ds:si	= PoofSendDialog object
		ds:di	= PoofSendDialogInstance
		dl	= VisUpdateMode
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	dialog may change to be sysmodal

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/11/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDGenSetUsable	method dynamic PoofSendDialogClass, MSG_GEN_SET_USABLE
		CheckHack <PoofSendDialog_offset eq Gen_offset>
		test	ds:[di].GI_states, mask GS_USABLE
		jnz	toSuper		; => redundant
	;
	; See if we're run by the mailbox thread.
	;
		push	cx, dx, bp, ax
		call	GeodeGetProcessHandle
		cmp	bx, handle 0
		jne	buildTransport		; => we're not, but we want to
						;  build the transport list
						;  anyway
	;
	; We are -- make ourselves sysmodal.
	;
		mov	ax, MSG_GEN_INTERACTION_SET_ATTRS
		mov	cx, (mask GIA_SYS_MODAL) or \
				(mask GIA_MODAL shl 8)
		call	ObjCallInstanceNoLock
buildTransport:
	;
	; The first time we're set usable, we also need to initialize the 
	; transport list.
	;
		push	si
		mov	si, offset PoofQuickMessageSendTransports
		mov	ax, MSG_OTL_REBUILD_LIST
		call	ObjCallInstanceNoLock
		pop	si

		pop	cx, dx, bp, ax
toSuper:
		mov	di, offset PoofSendDialogClass
		GOTO	ObjCallSuperNoLock
PSDGenSetUsable	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDSetTransport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the UI to account for the user having selected a
		(possibly different) transport + option + medium for sending
		a message.

CALLED BY:	MSG_PSD_SET_TRANSPORT
PASS:		*ds:si	= PoofSendDialogClass object
		ds:di	= PoofSendDialogClass instance data
		cx	= transport index # (must be mapped via
			  MSG_OTL_GET_TRANSPORT)
		bp	= number of selections (0 or 1)
RETURN:		nothing
DESTROYED:	ax, dx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/19/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDSetTransport	method dynamic PoofSendDialogClass, MSG_PSD_SET_TRANSPORT
	;
	; Done if not selection
	;
	tst	bp
	jz	done

	;
	; Contact the transport list to map the index to the transport+medium
	; 
	sub	sp, size MailboxMediaTransport
	movdw	dxbp, sssp
	push	si
	mov	si, ds:[di].PSDI_transportList	; *ds:si = transport list
	mov	ax, MSG_OTL_GET_TRANSPORT
	call	PCCCallInstance
	pop	si			; *ds:si = self

if ERROR_CHECK
	;
	; Make sure MSDI_lastContentStr is null, such that the handler of
	; MSG_MSD_SET_TRANSPORT in superclass will leave our moniker untouched.
	;
	DerefDI	MailboxSendDialog
	Assert	e, ds:[di].MSDI_lastContentStr, 0
endif

	;
	; Send MSG_MSD_SET_TRANSPORT to ourselves, which is handled by our
	; superclass.
	;
	mov	ax, MSG_MSD_SET_TRANSPORT
	call	PCCCallInstance

	;
	; Store the transport in the current transaction chunk, too.
	;
	DerefDI	MailboxSendDialog
	mov	bp, ds:[di].MSDI_transaction
	tst	bp
	jz	transactionTweaked

	mov	ax, ds:[di].MSDI_curMAC
	mov	bx, ds:[OLMBH_output].handle
	call	ObjSwapLock
	mov	si, ds:[bp]
	mov	bp, sp
	mov	ds:[si].MSCT_addrControl, ax
	movdw	ds:[si].MSCT_transport, ss:[bp].MMT_transport, ax
	mov	ax, ss:[bp].MMT_transOption
	mov	ds:[si].MSCT_transOption, ax
	call	ObjSwapUnlock

transactionTweaked:
	add	sp, size MailboxMediaTransport

done:
	ret
PSDSetTransport	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDMsdCreateBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the message

CALLED BY:	MSG_MSD_CREATE_BODY
PASS:		*ds:si	= PoofSendDialog object
		ds:di	= PoofSendDialogInstance
		*dx:bp	= MSCTransaction
RETURN:		carry set if creation being handled (always set)
			ax	= TRUE if not re-entrant (always FALSE)
		carry clear if creation not being handled
DESTROYED:	ax, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/11/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDMsdCreateBody method dynamic PoofSendDialogClass, MSG_MSD_CREATE_BODY
		uses	cx, bp
		.enter
	;
	; Get the info for beginning the transaction.
	;
		mov	es, dx		; *es:bp <- MSCTransaction
	;
	; Setup arguments to register message.
	;
		mov	bx, bp			; *es:bx = MSCTransaction
		sub	sp, size MSCRegisterMessageArgs
		mov	bp, sp			; ss:bp = MSCRegisterMessageArgs

	;
	; Call subclass to get message body and summary.
	;
		mov	ax, MSG_PSD_SEND_MESSAGE_GET_BODY
		call	ObjCallInstanceNoLockES	; *ds:ax = app-ref, CF clear if
						;  no error, *ds:cx = summary,
						;  dx = MailboxMessageFlags
		jnc	setupFptrs

	;
	; Error.  Cancel transaction and destroy our block.
	;
		mov	bp, bx
		call	ObjBlockGetOutput
		mov	ax, MSG_MAILBOX_SEND_CONTROL_CANCEL_MESSAGE
		clr	dx			; notify user
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		jmp	done

setupFptrs:
	;
	; Store the remaining registration args, dereferencing the body
	; and summary chunks.
	;
		mov	ss:[bp].MSCRMA_flags, dx
		
		mov	di, ax
		mov	di, ds:[di]
		movdw	ss:[bp].MSCRMA_bodyRef, dsdi
		mov	di, cx
		mov	di, ds:[di]
		movdw	ss:[bp].MSCRMA_summary, dsdi

		mov	{word} ss:[bp].MSCRMA_destApp.GT_chars[0], 'MB'
		mov	{word} ss:[bp].MSCRMA_destApp.GT_chars[2], 'OX'
		mov	ss:[bp].MSCRMA_destApp.GT_manufID,
				MANUFACTURER_ID_GEOWORKS
		movdw	ss:[bp].MSCRMA_startBound, MAILBOX_NOW
		movdw	ss:[bp].MSCRMA_endBound, MAILBOX_ETERNITY
	;
	; Call the send control to register the message.
	;
		push	ax, cx
		mov	cx, ss			; cx:dx <- registration args
		mov	dx, bp
		mov	bp, bx			; bp <- transaction handle
		call	ObjBlockGetOutput	; ^lbx:si <- MSC
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		mov	ax, MSG_MAILBOX_SEND_CONTROL_REGISTER_MESSAGE
		call	ObjMessage
		pop	ax, cx
	;
	; Free the body and summary chunks, as all data have been copied out
	; of them.
	;
		call	LMemFree
		mov_tr	ax, cx
		call	LMemFree
done:
		add	sp, size MSCRegisterMessageArgs
		clr	ax		; ax <- is reentrant
		stc			; CF <- creation handled

		.leave
		ret
PSDMsdCreateBody endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDMsdTransactionComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Message was registered, so call subclass to cleanup body

CALLED BY:	MSG_MSD_TRANSACTION_COMPLETE
PASS:		*ds:si	= PoofSendDialog object
		ds:di	= PoofSendDialogInstance
		*dx:bp	= MSCTransaction
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/11/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDMsdTransactionComplete method dynamic PoofSendDialogClass, MSG_MSD_TRANSACTION_COMPLETE
		clr	cx
		call	PSDCleanupCommon
		mov	di, offset PoofSendDialogClass
		GOTO	ObjCallSuperNoLock
PSDMsdTransactionComplete endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDMsdCancelTransaction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Message was canceled, so call subclass to delete body

CALLED BY:	MSG_MSD_CANCEL_TRANSACTION
PASS:		*ds:si	= PoofSendDialog object
		ds:di	= PoofSendDialogInstance
		*dx:bp	= MSCTransaction
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/11/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDMsdCancelTransaction method dynamic PoofSendDialogClass, MSG_MSD_CANCEL_TRANSACTION
		mov	cx, TRUE
		call	PSDCleanupCommon
		mov	di, offset PoofSendDialogClass
		GOTO	ObjCallSuperNoLock
PSDMsdCancelTransaction endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSDCleanupCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Point to the body reference and call ourselves to cleanup

CALLED BY:	(INTERNAL) PSDMsdCancelTransaction,
			   PSDMsdTransactionComplete
PASS:		*ds:si	= PSD
		cx	= TRUE if canceled
		*dx:bp	= MSCTransaction
RETURN:		nothing
DESTROYED:	bx, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/11/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSDCleanupCommon proc	near
		class	PoofSendDialogClass
		uses	dx, bp, ax, es
		.enter
		mov	es, dx
		mov	bx, es:[bp]
		mov	bp, es:[bx].MSCT_bodyRef
		tst	bp
		jz	done
		mov	ax, MSG_PSD_SEND_MESSAGE_CLEANUP_BODY
		call	PCCCallInstance
done:
		.leave
		ret
PSDCleanupCommon endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UPDAllocVMTAppRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a VMTreeAppRef and fill in appropriate MRA_ fields.

CALLED BY:	(INTERNAL) PQMSDPsdSendMessageGetBody,PCSDPsdSendMessageGetBody
PASS:		ss:bp	= MailboxRegisterMessageArgs
RETURN:		*ds:di	= VMTreeAppRef (VMTAR_vmFile set to null)
		MRA_bodyStorage, MRA_bodyFormat.MDF_manuf and MRA_bodyRefLen
		filled in
DESTROYED:	ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UPDAllocVMTAppRef	proc	near

	Assert	fptr, ssbp
	mov	ss:[bp].MSCRMA_bodyStorage.MS_id, GMSID_VM_TREE
		CheckHack <MANUFACTURER_ID_GEOWORKS eq 0>
	clr	ax			; ax = MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].MSCRMA_bodyStorage.MS_manuf, ax
	mov	ss:[bp].MSCRMA_bodyFormat.MDF_manuf, ax

	;
	; Allocate VMTreeAppRef chunk.
	;
	mov	cx, size VMTreeAppRef
	mov	ss:[bp].MSCRMA_bodyRefLen, cx
	mov	al, mask OCF_DIRTY
	call	LMemAlloc
	mov	di, ax
	mov	di, ds:[di]		; ds:[di] = VMTreeAppRef
	clr	ds:[di].VMTAR_vmFile
	mov_tr	di, ax			; *ds:di = VMTreeAppRef

	ret
UPDAllocVMTAppRef	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UPDAllocSubject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a chunk and copy the desired subject.

CALLED BY:	(INTERNAL) PQMSDPsdSendMessageGetBody
PASS:		si	= lptr of subject template in ROStrings resource
		ds	= LMem block to allocate the chunk
RETURN:		*ds:cx	= lptr of subject chunk in passed block
		si	= cx
		es fixed up (if same as ds when passed)
		carry always clear
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UPDAllocSubject	proc	near

	mov	bx, handle ROStrings	; ^lbx:si = string to copy
	call	UtilCopyChunk		; *ds:si = chunk created
	mov	cx, si			; cx = lptr of chunk
	clc				; always return CF clear

	ret
UPDAllocSubject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UPDAddAddressControlCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the address control object to the dialog tree, putting
		it next to the transport list.

CALLED BY:	(INTERNAL) PoofFileSendDialog::MSD_ADD_ADDRESS_CONTROL,
			   PoofQuickMessageSendDialog::MSD_ADD_ADDRESS_CONTROL
PASS:		ds	= segment of poof dialog block
		^lcx:dx	= MailboxAddressControl object to add (must be in the
			  same block)
RETURN:		ds fixed up
DESTROYED:	ax, bp, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	We assume that the transport list is the first child within it's
	parent interaction.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UPDAddAddressControlCommon	method	dynamic PoofFileSendDialogClass,
					MSG_MSD_ADD_ADDRESS_CONTROL
	method	UPDAddAddressControlCommon, 
		PoofQuickMessageSendDialogClass,
		MSG_MSD_ADD_ADDRESS_CONTROL

	CheckHack <PoofFileSendDialog_offset eq Gen_offset>
	mov	al, ds:[di].GII_attrs

	Assert	e, cx, ds:[OLMBH_header].LMBH_handle

	;
	; Change the moniker of the address control to "To Whom".
	;
	push	cx			; save handle of this block
	push	ax			; save interaction attrs
	mov	si, dx			; *ds:si = MAC
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	mov	cx, handle uiToWhom
	mov	dx, offset uiToWhom
	mov	bp, VUM_NOW
	call	PCCCallInstance

	;
	; Change the visibility to GIV_DIALOG.
	mov	ax, MSG_GEN_INTERACTION_SET_VISIBILITY
	mov	cl, GIV_DIALOG
	call	PCCCallInstance

	;
	; Need to make its modality match our own.
	;
	pop	cx			; cl <- our attrs
	andnf	cx, mask GIA_MODAL or mask GIA_SYS_MODAL
	mov	ch, cl			; ch <- inverse of our attrs
	xornf	ch, mask GIA_MODAL or mask GIA_SYS_MODAL

	mov	ax, MSG_GEN_INTERACTION_SET_ATTRS
	call	PCCCallInstance

	;
	; Make it a properties box so that it'll have an "OK" trigger.
	;
	mov	ax, MSG_GEN_INTERACTION_SET_TYPE
	mov	cl, GIT_PROPERTIES
	call	PCCCallInstance

	;
	; Add it as the second child of the interaction containing the
	; transport list.
	;
	pop	cx
	mov	dx, si			; ^lcx:dx = MAC
		.assert offset PoofQuickMessageSendTransportGroup \
			eq offset PoofFileSendTransportGroup
	mov	si, offset PoofQuickMessageSendTransportGroup

if ERROR_CHECK
	;
	; Verify that the transport list is the first child.
	;
	push	dx
	mov	ax, MSG_GEN_FIND_CHILD
		.assert offset PoofQuickMessageSendTransports \
			eq offset PoofFileSendTransports
	mov	dx, offset PoofQuickMessageSendTransports
	call	PCCCallInstance
	Assert	e, bp, 0
	pop	dx
endif

	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, mask CCF_MARK_DIRTY or (1 shl offset CCF_REFERENCE)
	call	PCCCallInstance

	ret
UPDAddAddressControlCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UPDCleanupVMTBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cleanup message body of VM tree type.

CALLED BY:	(INTERNAL)
PASS:		*dx:bp	= VMTreeAppRef (VMTAR_vmFile non-null if
			  MailboxDoneWithVMFile is to be called)
		cx	= TRUE if tree should be deleted
RETURN:		nothing
DESTROYED:	bx, bp, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UPDCleanupVMTBody	method	dynamic PoofClipboardSendDialogClass,
					MSG_PSD_SEND_MESSAGE_CLEANUP_BODY

	method	UPDCleanupVMTBody,
		PoofQuickMessageSendDialogClass,
		MSG_PSD_SEND_MESSAGE_CLEANUP_BODY

	mov	es, dx
	mov	bp, es:[bp]
	mov	bx, es:[bp].VMTAR_vmFile
	tst	bx
	jz	done

	jcxz	doneWithFile

	mov	ax, es:[bp].VMTAR_vmChain.high
	mov	bp, es:[bp].VMTAR_vmChain.low
	call	VMFreeVMChain

doneWithFile:
	call	MailboxDoneWithVMFile	
done:
	ret
UPDCleanupVMTBody	endp

;------------------------------------------------------------------------------
;
;			QUICK MESSAGE SUBCLASS
;
;------------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PQMSDPsdSendMessageGetBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get message body and summary for sending Quick Message.

CALLED BY:	MSG_PSD_SEND_MESSAGE_GET_BODY
PASS:		ds	= dialog block
		ss:bp	= MailboxRegisterMessageArgs
RETURN:		ax	= lptr of body-ref in object block
		carry clear if no error
			cx	= lptr of summary in object block
			dx	= MailboxMessageFlags
			MRA_bodyStorage, MRA_bodyFormat, MRA_bodyRefLen filled
			in.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/19/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PQMSDPsdSendMessageGetBody	method dynamic PoofQuickMessageSendDialogClass,
					MSG_PSD_SEND_MESSAGE_GET_BODY
	uses	bp
	.enter

	mov	ss:[bp].MSCRMA_bodyFormat.MDF_id, GMDFID_TEXT_CHAIN
	call	UPDAllocVMTAppRef	; *ds:di = VMTreeAppRef

	;
	; Get size of text.  Allocate a VM block for it with the VMChainLink
	; header.
	;
	mov	si, offset PoofQuickMessageSendText
	mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
	call	PCCCallInstance		; dxax = length excl. null
DBCS <	shl	ax, 1							>
DBCS < EC <	adc	dx, 0		; so it dies if too long      >	>
	Assert	e, dx, 0
	Assert	be, ax, <0xfffe - size VMChainLink - size TCHAR>
	add	ax, size VMChainLink + size TCHAR	; header + null
	mov_tr	cx, ax			; cx = size of VM block
	mov	bx, 1			; one VM block
	call	MailboxGetVMFile	; bx = VM file handle
	jc	error
	clr	ax			; no user id
	call	VMAlloc			; ax = VM block handle, marked dirty
	mov	bp, ds:[di]		; ds:bp = VMTreeAppRef
	mov	ds:[bp].VMTAR_vmChain.high, ax
	clr	ds:[bp].VMTAR_vmChain.low
	mov	ds:[bp].VMTAR_vmFile, bx

	;
	; Fill in header.  Store text in the VM block.
	;
	call	VMLock			; ax = sptr, bp = hptr
	mov	es, ax
	mov_tr	dx, ax
	clr	ax, es:[VMCL_next]	; 6 bytes (ax not actually used)

	push	bp			; save hptr of VM block
	mov	bp, size VMChainLink	; dx:bp = buffer for text
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	PCCCallInstance		; chunks in object block *NOT* moved

	pop	bp			; bp = VM block hptr
	call	VMDirty			; mark it dirty again
	call	VMUnlock

	;
	; Create a chunk for the subject.
	;
	mov	si, offset uiPoofSubjectQuickMessage
	call	UPDAllocSubject	; cx = lptr of subject, CF clear

	mov	dx, MailboxMessageFlags <0, 0, MMP_EMERGENCY, MDV_VIEW, 1>

done:
	mov_tr	ax, di			; ax = VMTreeAppRef lptr

	.leave
	ret

error:
	jmp	done			; CF already set

PQMSDPsdSendMessageGetBody	endm

;------------------------------------------------------------------------------
;
;			    FILE SUBCLASS
;
;------------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PFSDFileSelectionChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the Send trigger status, and activate it if it's a
		double-click.

CALLED BY:	MSG_PFSD_FILE_SELECTION_CHANGED
PASS:		*ds:si	= PoofFileSendDialogClass object
		bp	= GenFileSelectorEntryFlags
RETURN:		nothing
DESTROYED:	ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Sets the valid state before checking for double-click, so that we
	won't activate the trigger for a non-file selection.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/25/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PFSDFileSelectionChanged	method dynamic PoofFileSendDialogClass, 
					MSG_PFSD_FILE_SELECTION_CHANGED

	push	ds:[di].MSDI_sendTrigger

	;
	; Only allow files.
	;
	mov	cx, mask MSDVS_FILE_SELECTION	; assume set the bit
		CheckHack <GFSET_FILE eq 0>
	test	bp, mask GFSEF_TYPE	; 0 if GFSET_FILE
	jz	haveFlags		; set bit if it's a file
	xchg	ch, cl			; clear the bit instead

haveFlags:
	mov	ax, MSG_MSD_SET_VALID
	call	PCCCallInstance

	;
	; Activate the trigger if it's a double-click.
	;
	pop	si			; *ds:si = send trigger
	test	bp, mask GFSEF_OPEN
	jz	done
	mov	ax, MSG_GEN_TRIGGER_SEND_ACTION
	call	PCCCallInstance		; it won't hurt even if the selection
					;  is not a file.

done:
	ret
PFSDFileSelectionChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PFSDPsdSendMessageGetBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get body and summary for sending a File.

CALLED BY:	MSG_PSD_SEND_MESSAGE_GET_BODY
PASS:		ds	= dialog block
		ss:bp	= MailboxRegisterMessageArgs
RETURN:		ax	= lptr of body-ref in object block
		carry clear if no error
			cx	= lptr of summary in object block
			dx	= MailboxMessageFlags
			MRA_bodyStorage, MRA_bodyFormat, MRA_bodyRefLen filled
			in.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/21/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PFSDPsdSendMessageGetBody	method dynamic PoofFileSendDialogClass, 
					MSG_PSD_SEND_MESSAGE_GET_BODY
	uses	bp
	.enter

	mov	ss:[bp].MSCRMA_bodyFormat.MDF_id, GMDFID_DOCUMENT
		CheckHack <MANUFACTURER_ID_GEOWORKS eq 0>
		CheckHack <GMSID_FILE eq 0>
	clr	ax		; ax = MANUFACTURER_ID_GEOWORKS = GMSID_FILE
	mov	ss:[bp].MSCRMA_bodyFormat.MDF_manuf, ax
	mov	ss:[bp].MSCRMA_bodyStorage.MS_id, ax
	mov	ss:[bp].MSCRMA_bodyStorage.MS_manuf, ax

	;
	; Allocate FileDDMaxAppRef chunk
	;
	mov	cx, size FileDDMaxAppRef
	mov	ss:[bp].MSCRMA_bodyRefLen, cx
	mov	al, mask OCF_DIRTY
	call	LMemAlloc		; *ds:ax = FileDDMaxAppRef

	;
	; Get currently selected file from file selector.  Use buffer on stack.
	;
	mov_tr	di, ax			; *ds:di = FileDDMaxAppRef
	segmov	cx, ds
	mov	dx, ds:[di]
		CheckHack <offset FMAR_filename eq 2>
	inc	dx
	inc	dx			; cx:dx = FMAR_filename
	mov	si, offset PoofFileSendFileSelector
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_FULL_SELECTION_PATH
	call	PCCCallInstance		; ax = disk handle,
					;  bp = GenFileSelectorEntryFlags

if ERROR_CHECK
	; The file selector should be set up to only allow files.
	andnf	bp, mask GFSEF_TYPE
	Assert	e, bp, <GFSET_FILE shl offset GFSEF_TYPE>
endif

	;
	; Store disk handle in FMAR_diskHandle.
	;
	mov	si, dx			; ds:si = FMAR_filename
	mov	ds:[si - offset FMAR_filename + offset FMAR_diskHandle], ax
	mov_tr	bx, ax			; bx = disk handle

	;
	; Get size of file path name.
	;
	push	di			; save FileDDMaxAppRef lptr
	movdw	esdi, dssi
	LocalStrSize	includeNull	; cx = size incl. null
	mov	al, mask OCF_DIRTY

	;
	; See if we got a disk handle or StandardPath
	;
	test	bx, DISK_IS_STD_PATH_MASK
	jnz	stdPath

	;
	; It's a disk handle.  Allocate a subject buffer, and get the drive
	; letter and volume name into the buffer.
	;
	add	cx, (4 + VOLUME_NAME_LENGTH) * size TCHAR
					; e.g. "C:[volume name]"
	call	LMemAlloc		; *ds:ax = *es:ax = subject buffer
	push	ax			; save subject lptr
	mov_tr	di, ax
	mov	di, ds:[di]		; es:di = subject buffer
	call	DiskGetDrive		; al = 0-based drive number
	cbw				; ax = 0-based drive number
SBCS <	add	ax, C_CAP_A		; ax = drive letter		>
DBCS <	add	ax, C_LATIN_CAPITAL_LETTER_A	; ax = drive letter	>
	LocalPutChar	esdi, ax
	mov	ax, C_COLON		; ':'
	LocalPutChar	esdi, ax
SBCS <	mov	ax, C_LEFT_BRACKET	; '['				>
DBCS <	mov	ax, C_OPENING_SQUARE_BRACKET	; '['			>
	LocalPutChar	esdi, ax
	call	DiskGetVolumeName
	LocalClrChar	ax
	; cx still valid here
	LocalFindChar			; es:di = char after null
	LocalPrevChar	esdi		; es:di = null
SBCS <	mov	ax, C_RIGHT_BRACKET	; ']'				>
DBCS <	mov	ax, C_CLOSING_SQUARE_BRACKET	; ']'			>
	LocalPutChar	esdi, ax
	jmp	copyPathName

stdPath:
	;
	; It's a standard path.  Allocate a subject buffer and convert the
	; StandardPath enum to text string.
	;
	add	cx, UHTA_NO_NULL_TERM_BUFFER_SIZE + size TCHAR	; add 1 for ':'
	call	LMemAlloc		; *ds:ax = *es:ax = subject buffer
	push	ax			; save subject lptr
	mov_tr	di, ax
	mov	di, ds:[di]		; es:di = subject buffer
	mov_tr	ax, bx			; ax = StandardPath
		CheckHack <StandardPath lt 8000h>
	cwd				; zero-pad dx, dxax = StandardPath
	mov	cx, dx			; cx = 0, no flags
	call	UtilHex32ToAscii	; cx = length of string
DBCS <	shl	cx			; cx = size of string		>
	add	di, cx			; es:di = char after string
	LocalLoadChar	ax, C_COLON
	LocalPutChar	esdi, ax

copyPathName:
	;
	; Now append the file path name in FMAR_filename to the subject buffer.
	;
	pop	cx			; cx = lptr of subject buffer
	pop	si			; *ds:si = FileDDMaxAppRef
	mov	dx, si			; dx = lptr of body-ref
	mov	si, ds:[si]
		CheckHack <offset FMAR_filename eq 2>
	inc	si
	inc	si			; ds:si = FMAR_filename
	LocalCopyString

	mov_tr	ax, dx			; ax = lptr of body-ref
	mov	dx, MailboxMessageFlags <0, 0, MMP_FIRST_CLASS, MDV_ACCEPT, 0>
	clc

	.leave
	ret
PFSDPsdSendMessageGetBody	endm

;------------------------------------------------------------------------------
;
;			  CLIPBOARD SUBCLASS
;
;------------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCSDMsdAddAddressControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the address control object to our dialog tree.

CALLED BY:	MSG_MSD_ADD_ADDRESS_CONTROL
PASS:		*ds:si	= PoofClipboardSendDialogClass object
		ds:di	= PoofClipboardSendDialogClass instance data
		ds:bx	= PoofClipboardSendDialogClass object (same as *ds:si)
		es 	= segment of PoofClipboardSendDialogClass
		ax	= message #
		^lcx:dx	= MailboxAddressControl object to add
RETURN:		nothing
DESTROYED:	ax, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	We assume that our transport list (PoofClipboardSendTransportGroup)
	is the first child of the dialog.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/24/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCSDMsdAddAddressControl	method dynamic PoofClipboardSendDialogClass, 
					MSG_MSD_ADD_ADDRESS_CONTROL

if ERROR_CHECK
	;
	; Verify our assumption.
	;
	pushdw	cxdx
	mov	cx, ds:[OLMBH_header].LMBH_handle
	mov	dx, offset PoofClipboardSendTransportGroup
	mov	ax, MSG_GEN_FIND_CHILD
	call	PCCCallInstance		; bp = -1 if not found
	Assert	e, bp, 0		; assert that it's the first child
	popdw	cxdx
endif

	;
	; Add the MAC as our second child, which is below the transport list.
	;
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, mask CCF_MARK_DIRTY or (1 shl offset CCF_REFERENCE)
	call	PCCCallInstance

	ret
PCSDMsdAddAddressControl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCSDPsdSendMessageGetBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get body and summary for sending a Clipboard item.

CALLED BY:	MSG_PSD_SEND_MESSAGE_GET_BODY
PASS:		ds	= dialog block
		ss:bp	= MailboxRegisterMessageArgs
RETURN:		ax	= lptr of body-ref in object block
		carry clear if no error
			cx	= lptr of summary in object block
			dx	= MailboxMessageFlags
			MRA_bodyStorage, MRA_bodyFormat, MRA_bodyRefLen filled
			in.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/21/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCSDPsdSendMessageGetBody	method dynamic PoofClipboardSendDialogClass, 
					MSG_PSD_SEND_MESSAGE_GET_BODY
	uses	bp
	.enter

	mov	ss:[bp].MSCRMA_bodyFormat.MDF_id, GMDFID_TRANSFER_ITEM
	call	UPDAllocVMTAppRef	; *ds:di = VMTreeAppRef

	;
	; Get current clipboard item.
	;
	clr	bp			; no ClipboardItemFlags
	call	ClipboardQueryItem	; ^vbx:ax = item, bp = # of formats
	tst	bp
	jz	error
	push	bx
	mov_tr	cx, ax			; cx = item VM block handle

	;
	; Convert it to mailbox transfer item format.
	;
	clr	bx			; don't know how many blocks
	call	MailboxGetVMFile	; bx = VM file hptr
	jc	errorDoneWithItem
	mov	dx, bx			; dx = dest VM file hptr
	pop	bx			; ^vbx:cx = clipboard item
	clr	ax			; no ID
	mov	si, TRUE		; create an item name chunk
	call	MailboxConvertToMailboxTransferItem
					; ^vdx:ax = mailbox transfer item,
					;  *ds:si = item name
	push	si			; save subject chunk

	;
	; Fill in body-ref
	;
	mov	si, ds:[di]		; ds:si = VMTreeAppRef
	mov	ds:[si].VMTAR_vmChain.high, ax
	clr	ds:[si].VMTAR_vmChain.low
	mov	ds:[si].VMTAR_vmFile, dx

	mov_tr	ax, cx			; ^vbx:ax = clipboard item
	call	ClipboardDoneWithItem

	pop	cx			; cx = subject chunk lptr
	mov	dx, MailboxMessageFlags <0, 0, MMP_FIRST_CLASS, MDV_ACCEPT, 1>
	clc

done:
	mov_tr	ax, di			; ax = VMTreeAppRef lptr

	.leave
	ret

errorDoneWithItem:
	pop	bx
	mov_tr	ax, cx			; ^vbx:ax = clipboard item
	call	ClipboardDoneWithItem

error:
	stc
	jmp	done
	
PCSDPsdSendMessageGetBody	endm

PoofControlCode	ends

endif	; _POOF_MESSAGE_CREATION

;------------------------------------------------------------------------------
;
;		       TRANSFER ITEM CONVERSION
;
;------------------------------------------------------------------------------
PoofControlCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxConvertToMailboxTransferItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a clipboard transfer item to a mailbox transfer item.

CALLED BY:	(GLOBAL)
PASS:		^vbx:cx	= clipboard item (ClipboardItemHeader)
			  bx can be any VM file, not necessarily the clipboard
			  file.
		dx	= VM file handle to create mailbox transfer item (not
			  necessarily obtained from MailboxGetVMFile)
		ax	= user specified id for the VM tree created
		if si non-zero
			ds	= lmem block to create the chunk which stores
				  name of clipboard item (CIH_name)
		else
			ds not used
RETURN:		^vdx:ax	= mailbox transfer item (a VM tree)
		If si passed non-zero (clipboard item name requested)
			*ds:si	= clipboard item name
		else
			ds, si unchanged
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxConvertToMailboxTransferItem	proc	far
	uses	cx,bp,di,es
	.enter

	;
	; Lock clipboard item
	;
	mov_tr	di, ax			; di = user specified id
	mov_tr	ax, cx			; ^vbx:ax = CIH
	call	VMLock			; ax = sptr, bp = hptr

	;
	; Create a chunk to store the item name if requested.
	;
	mov	cx, ds			; value to return in ds if clipboard
					;  item name not requested
	tst	si
	jz	allocMTIH

	push	di			; save user specified ID
	mov	es, ax
	mov	di, offset CIH_name	; es:di = CIH_name
	mov	si, di
	LocalStrSize	includeNull	; cx = size of name
	mov	al, mask OCF_DIRTY
	call	LMemAlloc		; *ds:ax = chunk
	mov	di, ax
	mov	di, ds:[di]
	segxchg	ds, es			; es:di = dest chunk
					; ds:si = CIH_name
	rep	movsb
	mov	cx, es			; cx = object block sptr (fixed up)
	mov_tr	si, ax			; si = lptr of name
	mov	ax, ds			; ax = ClipboardItemHeader sptr
	pop	di			; di = user specified ID

allocMTIH:
	;
	; Allocate temporary MaiboxTransferItemHeader in the source VM file.
	;
	push	cx, si			; values to return in ds, si
	push	dx			; save dest VM file hptr
	push	bp			; save CIH hptr
	mov	ds, ax			; ds:0 = ClipboardItemHeader
	mov	cx, ds:[CIH_formatCount]	; cx = # of branches
	Assert	be, cx, CLIPBOARD_MAX_FORMATS
	push	cx
	shl	cx
	shl	cx			; cx *= size dword
	add	cx, size MailboxTransferItemHeader	; cx = size of header
	mov_tr	ax, di			; ax = user specified id
	call	VMAlloc			; ax = VM block handle
	mov	dx, ax			; dx = temporary MAIH VM block handle
	call	VMLock			; ^hbp = MailboxTransferItemHeader
	mov	es, ax

	;
	; Copy the whole ClipboardItemHeader to the temporary block.
	;
	mov	es:[MTIH_meta].VMCT_meta.VMCL_next, VM_CHAIN_TREE
	mov	es:[MTIH_meta].VMCT_offset, offset MTIH_branch
	clr	si			; ds:si = ClipboardItemHeader
	mov	di, offset MTIH_cih	; es:di = MTIH_cih
	mov	cx, size ClipboardItemHeader	; somehow the size is odd :-(
	rep	movsb
	    CheckHack <offset MTIH_cih + size MTIH_cih eq offset MTIH_branch>
					; es:di = MTIH_branch

	;
	; Loop thru each clipboard format and copy the tree link.
	;
	mov	si, offset CIH_formats.CIFI_vmChain	; ds:si = first link
	pop	cx
	mov	es:[MTIH_meta].VMCT_count, cx
	jcxz	unlock

next:
	movsw
	movsw				; one dword copied
	add	si, size ClipboardItemFormatInfo - size CIFI_vmChain
					; ds:si = next CIFI_vmChain
	loop	next

unlock:
	;
	; Unlock VM blocks.
	;
	call	VMDirty
	call	VMUnlock		; unlock MailboxTransferItemHeader
	mov_tr	ax, dx			; ^vbx:ax = MailboxTransferItemHeader
	pop	bp			; bp = ClipboardItemHeader block handle
	call	VMUnlock		; unlock ClipboardItemHeader

	;
	; Copy the tree to destination VM file.  Free temporary MTIH.
	;
	mov	cx, ax			; ^vbx:cx = temporary MTIH
	pop	dx			; dx = dest VM file hptr
	clr	bp			; source is a tree, not a DB item
	call	VMCopyVMChain		; ^vdx:ax = destination tree
	xchg	ax, cx			; ^vdx:cx = dest tree,
					;  ^vbx:ax = temp MTIH block
	call	VMFree
	mov_tr	ax, cx			; ^vdx:ax = dest tree

	;
	; Now fixup the CIFI_vmChain fields of all the formats for the new
	; file.
	;
	push	ax
	xchg	bx, dx
	call	VMLock
	mov	ds, ax
	mov	es, ax
	mov	cx, ds:[VMCT_count]
	mov	si, offset MTIH_branch
	mov	di, offset MTIH_cih.CIH_formats.CIFI_vmChain
	jcxz	formatsFixedUp
fixupLoop:
	movsw
	movsw
	add	di, size ClipboardItemFormatInfo - size CIFI_vmChain
	loop	fixupLoop
formatsFixedUp:
	call	VMDirty
	call	VMUnlock
	pop	ax
	xchg	bx, dx

	pop	ds, si			; values to return in ds, si

	.leave
	ret
MailboxConvertToMailboxTransferItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxConvertToClipboardTransferItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a mailbox transfer item to a clipboard transfer item.

CALLED BY:	(GLOBAL)
PASS:		^vbx:cx	= mailbox transfer item (MailboxTransferItemHeader)
			  bx can be any VM file, not necessarily obtained from
			  MailboxGetVMFile.
		dx	= VM file handle to create clipboard transfer item
			  (not necessarily the clipboard file)
		ax	= user specified id for the VM tree created
RETURN:		^vdx:ax	= clipboard transfer item (a VM tree)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxConvertToClipboardTransferItem	proc	far
	uses	bx,cx,bp,si,di,ds,es
	.enter

	;
	; Copy the VM tree to the destination VM file.
	;
	mov_tr	si, ax			; si = id
	mov_tr	ax, cx			; ^vbx:ax = source VM tree
	clr	bp			; source is a tree, not a DB item
	call	VMCopyVMChain		; ^vdx:ax = tree created
	push	ax			; save VM block handle of MTIH
	mov	bx, dx			; ^vbx:ax = tree created
	call	VMLock			; ax = sptr, bp = hptr
	mov	ds, ax			; ds:0 = MailboxTransferItemHeader

	;
	; Create ClipboardItemHeader block in destination file
	;
	mov_tr	ax, si			; ax = id
	mov	cx, size ClipboardItemHeader
	call	VMAlloc			; ax = VM block handle
	push	ax			; save VM block handle of CIH
	call	VMLock			; ax = sptr, bp = hptr
	mov	es, ax			; es:0 = ClipboardItemHeader

	;
	; Copy the whole CIH first.  We'll fix up VM branches later.
	;
	mov	si, offset MTIH_cih	; ds:si = ClipboardItemHeader src
	clr	di			; es:di = ClipboardItemHeader dest
	mov	cx, size ClipboardItemHeader	; size is odd!
	rep	movsb
	    CheckHack <offset MTIH_cih + size MTIH_cih eq offset MTIH_branch>
					; ds:si = MTIH_branch

	;
	; Copy VM block handle of each branch from MTIH to CIH
	;
	mov	di, offset CIH_formats.CIFI_vmChain	; es:di = first link
	mov	cx, ds:[MTIH_meta].VMCT_count	; cx = # of branches
	jcxz	stuffNull
next:
	movsw
	movsw				; one dword copied
	add	di, size ClipboardItemFormatInfo - size CIFI_vmChain
					; es:di = next CIFI_vmChain
	loop	next

stuffNull:
	;
	; Put null in CIH_owner and CIH_sourceID.
	;
		CheckHack <CIH_owner eq 0>
	clr	ax, di			; es:di = CIH_owner
	stosw
	stosw				; es:CIH_owner = null
	mov	di, offset CIH_sourceID
	stosw
	stosw				; es:CIH_sourceID = null

	;
	; Unlock the CIH block and free the MITH in dest file.
	;
	call	VMUnlock		; unlock CIH
	pop	bp			; bp = VM block handle of CIH
	pop	ax			; ^vbx:ax = MTIH
	call	VMFree			; free MTIH
	mov_tr	ax, bp			; ax = VM block handle of CIH

	.leave
	ret
MailboxConvertToClipboardTransferItem	endp

;------------------------------------------------------------------------------
;
;			RECEIVE POOF MESSAGES
;
;------------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UPDMetaMailboxNotifyMessageAvailable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notification received when some system message has arrived.

CALLED BY:	MSG_META_MAILBOX_NOTIFY_MESSAGE_AVAILABLE
PASS:		cxdx	= MailboxMessage
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Call the appropriate routine to receive the message, and delete the
	message right afterwards.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/15/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UPDMetaMailboxNotifyMessageAvailable	method extern MailboxProcessClass, 
				MSG_META_MAILBOX_NOTIFY_MESSAGE_AVAILABLE

	;
	; Figure out what type of poof message it is.  If it's not supported,
	; just delete it. 
	;
	call	MailboxGetBodyFormat	; bxax = MailboxDataFormat
		CheckHack <MANUFACTURER_ID_GEOWORKS eq 0>
	tst	bx
	jne	delete			; jump if not MANUFACTURER_ID_GEOWORKS

	cmp	ax, GMDFID_TRANSFER_ITEM
	jne	checkFile
	call	UPDReceiveClipboard
	jmp	delete

checkFile:
	cmp	ax, GMDFID_DOCUMENT
	jne	checkQuickMsg
	call	UPDReceiveFile
	jmp	delete

checkQuickMsg:
	cmp	ax, GMDFID_TEXT_CHAIN
	jne	delete
	call	UPDReceiveQuickMsg

delete:
	call	MailboxAcknowledgeMessageReceipt	; take possession
	call	MailboxDeleteMessage			;  ...and nuke it

	ret
UPDMetaMailboxNotifyMessageAvailable	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UPDReceiveClipboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Receive a Clipboard transfer item message.

CALLED BY:	(INTERNAL) UPDMetaMailboxNotifyMessageAvailable
PASS:		cxdx	= MailboxMessage
RETURN:		nothing
DESTROYED:	ax, bx, bp, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UPDReceiveClipboard	proc	near
	uses	cx,dx
	.enter

	;
	; Get body ref.
	;
	mov	ax, size VMTreeAppRef
	sub	sp, ax
	movdw	esdi, sssp		; es:di = VMTreeAppRef
	call	MailboxGetBodyRef
	jc	error			; just cleanup if can't get body ref

	;
	; Coonver mailbox transfer item to clipboard item.
	;
	call	ClipboardGetClipboardFile	; bx = clipboard file hptr
	tst	bx
	jz	error			; cleanup if no clipboard

	pushdw	cxdx			; save MailboxMessage
	mov	dx, bx			; dx = clipboard file hptr
	mov	cx, es:[di].VMTAR_vmChain.high
	mov	bx, es:[di].VMTAR_vmFile	; ^vbx:cx = mailbox transfer
						;  item
	clr	ax			; no user id
	call	MailboxConvertToClipboardTransferItem
					; ^vdx:ax = clipboard item

	;
	; Register the item with clipboard.
	;
	mov	bx, dx			; ^vbx:ax = clipboard item
	clr	bp			; no ClipboardItemFlags
	call	ClipboardRegisterItem	; CF set on error

	popdw	cxdx			; cxdx = MailboxMessage

done:
	;
	; We're done with the body.
	;
	mov	ax, size VMTreeAppRef
	call	MailboxDoneWithBody
	add	sp, ax			; pop VMTreeAppRef

	.leave
	ret

error:
	jmp	done
UPDReceiveClipboard	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UPDReceiveFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Receive a File message.

CALLED BY:	(INTERNAL) UPDMetaMailboxNotifyMessageAvailable
PASS:		cxdx	= MailboxMessage
RETURN:		nothing
DESTROYED:	ax, bx, si, di, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UPDReceiveFile	proc	near
appRef		local	FileDDMaxAppRef
stdPath		local	StandardPath
startOfPath	local	nptr.TCHAR

; used in UPDReceiveFileHandleFont
fontFileListSptr	local	sptr.TCHAR
fontInfoBlkSptr		local	sptr.LMemBlockHeader
fileHandled		local	BooleanByte
	ForceRef	fontFileListSptr
	ForceRef	fontInfoBlkSptr
	ForceRef	fileHandled

; used in UPDReceiveFileMoveFileRemoteOrLocal
destFileActualPath	local	PathName
	ForceRef	destFileActualPath

	uses	cx,dx
	.enter

	call	FilePushDir

	;
	; Get the subject line.
	;
	call	MailboxGetSubjectBlock	; ^hbx = subject
	LONG jc	error

	;
	; Steal message body.
	;
	segmov	es, ss
	lea	di, ss:[appRef]
	mov	ax, size FileDDMaxAppRef
	call	MailboxStealBody
	LONG jc	error			; just cleanup if can't get body ref

	call	MemLock
	mov	es, ax			; es:0 = subject

	;
	; If the subject line starts with a drive specification (e.g.
	; "C:[volume name]...", just put the file in SP_DOCUMENT.
	;
	LocalCmpChar	<es:[size TCHAR]>, C_COLON	; 2nd char
	jne	checkStdPath
SBCS <	LocalCmpChar	<es:[2 * size TCHAR]>, C_LEFT_BRACKET	; 3rd char>
DBCS <	LocalCmpChar	<es:[2 * size TCHAR]>, C_OPENING_SQUARE_BRACKET	>
	jne	checkStdPath
	mov	di, 3 * size TCHAR	; es:di = volume name
	call	LocalStringLength	; cx = length excl. null
SBCS <	mov	ax, C_RIGHT_BRACKET	; look for ']'			>
DBCS <	mov	ax, C_CLOSING_SQUARE_BRACKET	; look for ']'		>
	LocalFindChar			; es:di = start of path name
	jne	errorFreeSubject	; jump if ']' not found

	mov	ax, SP_DOCUMENT
	jmp	cdStdPath

checkStdPath:
	;
	; The subject line starts with a standard path.  (e.g. "DOCUMENT:...")
	; Try to match it with our stardard path strings to see which one
	; it is.
	;

	clr	di			; es:di = subject
	call	UPDReceiveFileParseStandardPath	; CF clear if found, ax =
						;  StandardPath, es:di = char
						;  after ':'
	jc	errorFreeSubject

	;
	; Skip any leading backslash in subpath
	;
	LocalCmpChar	es:[di], C_BACKSLASH
	jne	gotStartOfPath
	LocalNextChar	esdi		; skip leading backslash
gotStartOfPath:
	mov	ss:[startOfPath], di

	;
	; Chdir to the appropriate StandardPath.
	;
cdStdPath:
	mov	ss:[stdPath], ax
	call	FileSetStandardPath
ifdef FLOPPY_BASED_DOCUMENT
if FLOPPY_BASED_DOCUMENT
	jc	errorFreeSubject
endif
endif

	;
	; If it's anything other than SP_DOCUMENT, create each level of
	; sub-directory.
	;
	cmp	ax, SP_DOCUMENT
	je	inDestDir
	call	UPDReceiveFileCreateSubdir	; es:di = file name
	jc	errorFreeSubject

inDestDir:
	;
	; Check for special cases.  If it's under SP_PRIVDATA, the file is
	; possibly a patch file.
	;
	cmp	ss:[stdPath], SP_PRIVATE_DATA
	jne	checkIfFontDir
	call	UPDReceiveFileHandlePatch	; CF clear if it is patch file
	jnc	freeSubject		; exit if patch file already handled

checkIfFontDir:
	;
	; If it's under SP_FONT, the file is possibly a font file.
	;
	cmp	ss:[stdPath], SP_FONT
	jne	notSpecialFile
	call	UPDReceiveFileHandleFont	; CF clear if it is font file
	jnc	freeSubject

notSpecialFile:
	;
	; Move the actual file.  Destination filename is the last component
	; in the pathname at es:di.
	;
	call	UPDReceiveFileMoveOrdinaryFile

freeSubject:
	call	MemFree			; free subject block

done:
	call	FilePopDir

	.leave
	ret

errorFreeSubject:
	call	MemFree			; free subject block

error:
	jmp	done

UPDReceiveFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UPDReceiveFileParseStandardPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse the subject string to see which StandardPath it
		represents.

CALLED BY:	(INTERNAL) UPDReceiveFile
PASS:		es:di	= writable string (e.g. cannot be in ROM) to match,
			  terminated with C_COLON
RETURN:		es:di	= point to char after original C_COLON
		C_COLON in string replaced with C_NULL
		carry clear if okay
			ax	= StandardPath
		carry set if error
DESTROYED:	cx, dx, si, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UPDReceiveFileParseStandardPath	proc	near
	uses	bx
	.enter

	;
	; First replace the colon with null, so that string comparison is
	; easier.
	;
	movdw	dssi, esdi		; ds:si = ds:di = string
	call	LocalStringLength	; cx = length excl. null
	mov	ax, C_COLON		; ':'
	LocalFindChar			; es:di = path name under standard path
	jne	error			; jump if ':' not found
	LocalClrChar <es:[di - size TCHAR]>	; replace ':' with null

	;
	; Convert the number string to StandardPath enum.
	;
	call	UtilAsciiToHex32	; dxax = standard path
	jc	error
	tst	dx
	jnz	error			; too large
	cmp	ax, StandardPath
	jae	error			; too large
	test	ax, DISK_IS_STD_PATH_MASK	; clears carry flag
	jz	error			; not std path

done:
	.leave
	ret

error:
	stc
	jmp	done

UPDReceiveFileParseStandardPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UPDReceiveFileCreateSubdir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create all levels of sub-directories under the current
		directory.

CALLED BY:	(INTERNAL) UPDReceiveFile
PASS:		es:di	= the multi-level path name that a subdir is to be
			  created accordingly (buffer must be writable)
		current directory set to where subdir is to be created.
RETURN:		CF clear if no error
			es:di	= name of file (ie. last component in passed
				  path name)
			current dir changed to bottom level of subdir created
		CF set if error
			ax	= FileError
			string in es:di might be changed
DESTROYED:	cx, dx, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UPDReceiveFileCreateSubdir	proc	near
	uses	bx
	.enter

	;
	; If there's a leading backslash, skip it.
	;
	LocalCmpChar	es:[di], C_BACKSLASH
	jne	getLen
	LocalNextChar	esdi		; skip leading backslash (if any)

getLen:
	call	LocalStringLength	; cx = length excl. null
	segmov	ds, es			; ds = subject block

nextLevel:
	; Find next backslash in path
	mov	dx, di			; ds:dx = current component in path
	mov	ax, C_BACKSLASH		; '\'
	LocalFindChar			; es:di = char after '\',
					;  cx = remaining length
	jne	bottomReached		; jump if no more backslash found
	LocalClrChar <es:[di - size TCHAR]>	; replace '\' with null
	call	FileCreateDir		; CF set on error, ax = FileError
	jnc	cdDown
	cmp	ax, ERROR_FILE_EXISTS	; it's okay if dir already exists
	stc				; assume an error
	jne	done

cdDown:
	;
	; Chdir down one level.
	;
	clr	bx			; relative to current path
	call	FileSetCurrentPath	; CF set on error, ax = FileError
	jc	done			; something's wrong (VERY unlikely),
					;  return CF set.
	mov	{TCHAR} es:[di - size TCHAR], C_BACKSLASH	; restore '\'
	jmp	nextLevel

bottomReached:
	mov	di, dx			; es:di = filename
	clc

done:
	.leave
	ret
UPDReceiveFileCreateSubdir	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UPDReceiveFileHandlePatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	(INTERNAL) UPDReceiveFile
PASS:		es:di	= name of file (without any path info)
		ss:bp	= inherited stack frame from UPDReceiveFile
		current dir set to where the file should sit in (must be under
		SP_PRIVATE_DATA)
RETURN:		carry clear if file is handled, set if not
DESTROYED:	ax, cx, dx, si, ds
SIDE EFFECTS:	current dir changed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UPDReceiveFileHandlePatch	proc	near
	uses	bx, di
	.enter inherit UPDReceiveFile

	Assert	stackFrame, bp

	;
	; See if the file is in PATCH\ subdir.
	;
	mov	dx, di			; es:dx = filename
	segmov	ds, cs
	mov	si, offset patchDirName
	mov	di, ss:[startOfPath]	; es:di = subpath under SP_PRIVDATA
	mov	cx, length patchDirName
	call	LocalCmpStrings
	jne	checkLanguage		; not patch file if wrong dir

	;
	; The file is somewhere under PATCH\ directory.  For it to be a patch
	; file, it has to sit directly in PATCH\ but not any deeper subdir.
	; We check this by comparing the offset of the char after "PATCH\" and
	; the passed filename offset.
	;
SBCS <	add	di, cx			; es:di = char after "PATCH\"	>
DBCS <	add	di, size patchDirName	; es:di = char after "PATCH\"	>
	cmp	di, dx			; compare to es:dx (= filename)
	jne	notPatch		; jump if filename doesn't start after
					;  "PATCH\"
	jmp	isPatch

checkLanguage:
	;
	; See if the file is in LANGUAGE\FOOLANGUAGE subdir.
	;
	mov	si, offset languageDirName	; ds:si = "LANGUAGE\"
	mov	cx, length languageDirName
	call	LocalCmpStrings
	jne	notPatch

	;
	; The file is somewhere under LANGUAGE\ directory.  For it to be a
	; language file, it has to sit exactly one level down under LANGUAGE\.
	; We check this by looking at the # of backslashes in the path.
	;
SBCS <	add	di, cx			; es:di = char after "LANGUAGE\">
DBCS <	add	di, size languageDirName    ; es:di = char after "LANGUAGE\">
	call	LocalStringLength	; cx = length excl. null
	mov	ax, C_BACKSLASH
	LocalFindChar			; es:di = char after one more '\'
	jne	notPatch		; not valid if backslash not found
	cmp	di, dx			; compare to es:dx (= filename)
	jne	notPatch		; jump if filename doesn't start after
					;  "LANGUAGE\*\"
isPatch:
	;
	; If the patch file already exists, no need to apply the patch again.
	;
	segmov	ds, es			; ds:dx = filename
	call	FileGetAttributes	; CF set if error, ax = FileError
	jnc	fileExists

	;
	; Move the file over, and then apply the patch
	;
	call	UPDReceiveFileMoveFile	; es:di = filename, CF set if error
	jc	errorRemoveSrc
	movdw	dssi, esdi
	call	GeodeInstallPatch	; CF set if error
	jc	errorRemoveDest

done:
	.leave
	ret

notPatch:
	stc				; file not processed
	jmp	done

fileExists:
	;
	; The patch file already exists, remove the source file in mailbox
	;
	mov	si, offset uiPoofReceiveFilePatchExists
	jmp	doErrorDeleteFile

errorRemoveSrc:
	mov	si, offset uiPoofReceiveFilePatchError

doErrorDeleteFile:
	call	UtilDoError

	mov	ax, ss:[appRef].FMAR_diskHandle
	call	FileSetStandardPath
	segmov	ds, ss
	lea	dx, ss:[appRef].FMAR_filename
	call	FileDelete
doneClc:
	clc				; file processed
	jmp	done

errorRemoveDest:
	mov	si, offset uiPoofReceiveFilePatchError
	call	UtilDoError
	movdw	dsdx, esdi
	call	FileDelete

	jmp	doneClc

UPDReceiveFileHandlePatch	endp

LocalDefNLString	patchDirName, "PATCH\\"	; doesn't need C_NULL
LocalDefNLString	languageDirName, "LANGUAGE\\"	; doesn't need C_NULL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UPDReceiveFileHandleFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	(INTERNAL) UPDReceiveFile
PASS:		es:di	= name of file (without any path info)
		ss:bp	= inherited stack frame from UPDReceiveFile
		current dir set to SP_FONT
RETURN:		carry clear if file is handled, set if not
DESTROYED:	ax, cx, dx, si, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UPDReceiveFileHandleFont	proc	near
	uses	bx
	.enter inherit UPDReceiveFile

	Assert	stackFrame, bp

	clr	ss:[fileHandled]

	;
	; The file must come from directly in SP_FONT, but not under any subdir
	;
	cmp	di, ss:[startOfPath]
	LONG jne exit			; jump if file not directly in SP_FONT

	;
	; Create a font file list block.
	;
	mov	ax, size FileLongName
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc		; ^hbx = font file list
	mov	ss:[fontFileListSptr], ax

	;
	; Lock font info block
	;
	call	FontDrLockInfoBlock	; ds = font info block
	mov	ss:[fontInfoBlkSptr], ds

	;
	; STEP 1: Deal with any local file having the same file name.
	;

	;
	; See if another local file with the same name exists.  (It may be
	; for the same font or a different font, or not a font file at all.)
	;
	movdw	dsdx, esdi		; ds:dx = name of file in msg
	call	FileGetAttributes	; cx = FileAttrs, CF set if error
	jc	copyFile		; jump if file not exists
	call	UPDReceiveFileGetDirPathInfo	; cx = DirPathInfo
	test	cx, mask DPI_EXISTS_LOCALLY
	jz	copyFile		; if not local, just ignore it
	push	bx
	call	UPDReceiveFileTestIfOverwritable	; CF clear if so
	pop	bx
	LONG jc	error			; can't do anything if we can't
					;  overwrite the file

	;
	; A file with the same name exists.  If that file is a font file in
	; use, delete the font first.
	;
	call	FontDrGetFontIDFromFile	; cx = FontID
	jc	copyFile		; jump if not font file
	mov	ds, ss:[fontInfoBlkSptr]
	call	FontDrFindFileName	; CF set if found, ds:si = file in use
	jnc	copyFile
	; (On some really messy systems, the file in use with this FontID
	; might be yet another different file.  So we have to compare the
	; filenames.)
	; es:di = filename from message (same as name of file found in SP_FONT)
	; ds:si = name of file in use for same FontID as file in SP_FONT.
	clr	cx			; null-terminated
	call	LocalCmpStrings
	jne	copyFile		; jump if a different font file is also
					;  being used for this FontID

	;
	; The local file found is used for a font.  Delete the font first.
	;
	call	FillFontFileList
	mov	cx, 1			; 1 font
	mov	ax, TRUE		; force delete
	call	FontDrDeleteFonts
	jc	error

copyFile:
	;
	; Copy the file over from mailbox, overwriting any existing file.
	;
	mov	ss:[fileHandled], BB_TRUE
	mov	ax, IC_PLACE_IN_LOCAL
	call	UPDReceiveFileMoveFileRemoteOrLocal
	jc	freeFileList		; jump if error (error message already
					;  displayed)

	;
	; STEP 2: Deal with any font file being used for the same FontID as
	; the new file.
	;
	movdw	dsdx, esdi		; ds:dx = filename of new file
	call	FontDrGetFontIDFromFile	; cx = FontID
	jc	freeFileList		; jump if not font file

	;
	; See if the font already exists.
	;
	mov	ds, ss:[fontInfoBlkSptr]
	call	FontDrFindFileName	; CF set if found, ds:si = font file
	jnc	addFont

	;
	; Font already exists.  Remove the font first.
	;
	pushdw	esdi
	movdw	esdi, dssi
	call	FillFontFileList
	popdw	esdi			; es:di = name of new file
	mov	cx, 1			; 1 font
	mov	ax, TRUE
	call	FontDrDeleteFonts

addFont:
	;
	; Add the font back with the new font file.
	;
	call	FillFontFileList
	mov	cx, 1			; 1 font
	call	FontDrAddFonts
	jc	error

freeFileList:
	;
	; Free font file list, unlock font info block.
	;
	call	MemFree			; free font file list
	call	FontDrUnlockInfoBlock

exit:
	tst_clc	ss:[fileHandled]
	jnz	haveFlag
	stc
haveFlag:
	.leave
	ret

error:
	;
	; Display error.	
	;
	mov	si, offset uiPoofReceiveFileFontError
	call	UtilDoError
	jmp	freeFileList

UPDReceiveFileHandleFont	endp

;
; Pass:		es:di	= filename to copy into file list buffer
; Return:	ds	= es
; Destroyed:	ax, si
;
FillFontFileList	proc	near
	uses	di,es
	.enter inherit UPDReceiveFile

	movdw	dssi, esdi
	mov	es, ss:[fontFileListSptr]
	clr	di			; es:di = font file list
	LocalCopyString

	.leave
	ret
FillFontFileList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UPDReceiveFileMoveOrdinaryFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the file from mailbox to it's final destination.  The
		file is not any special file (e.g. patch file, font file.)

CALLED BY:	
PASS:		es:di	= path whose last component is the filename
			  File is always moved to current directory.  Path info
			  in passed es:di is ignored.
		ss:bp	= inherited stack from from UPDReceiveFile
RETURN:		es:di	= filename (last component in path)
DESTROYED:	ax, cx, dx, si, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	11/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IC_OVERWRITE_REMOTE	equ	IC_CUSTOM_START
IC_PLACE_IN_LOCAL	equ	(IC_CUSTOM_START + 1)

RemoteLocalTriggerTable	label	StandardDialogResponseTriggerTable
	word	3
	StandardDialogResponseTriggerEntry <
		uiPoofReceiveFileOverwriteRemote,
		IC_OVERWRITE_REMOTE
	>
	StandardDialogResponseTriggerEntry <
		uiPoofReceiveFilePlaceInLocal,
		IC_PLACE_IN_LOCAL
	>
	StandardDialogResponseTriggerEntry <
		uiPoofCancel,
		IC_DISMISS
	>

UPDReceiveFileMoveOrdinaryFile	proc	near
	uses	bx
	.enter

	Assert	stackFrame, bp

	call	UtilLocateFilenameInPathname	; es:di = filename

	;
	; See if the file exists.
	;
	movdw	dsdx, esdi		; ds:dx = filename
	call	FileGetAttributes	; CF set if error, ax = FileError
	jnc	fileExists
	cmp	ax, ERROR_FILE_NOT_FOUND
	jne	error
	jmp	moveToLocal

fileExists:
	;
	; File exists.  First test if we can overwrite it.
	;
	call	UPDReceiveFileTestIfOverwritable
					; bx = non-zero if can overwrite file

	;
	; See whether the file is local or remote.
	;
	call	UPDReceiveFileGetDirPathInfo	; cx = DirPathInfo
	test	cx, mask DPI_EXISTS_LOCALLY
	jnz	existLocally

	;
	; File exists remotely.
	; If remote file can be overwritten, options are: 1) overwrite remote
	;						  2) move to local dir
	; Else, we just move the file to local dir.
	;
	tst	bx
	mov	ax, IC_PLACE_IN_LOCAL
	jz	moveRemoteExists	; jump to place file in local tree

	;
	; Ask user which option he wants.
	;
	mov	cx, offset RemoteLocalTriggerTable
	mov	bx, cs			; bx:cx is fptr, NOT vfptr.  Works even
					;  for XIP.
	mov	si, offset uiPoofReceiveFileRemoteOrLocal
	call	UtilDoMultiResponse	; ax = InteractionCommand

		CheckHack <IC_OVERWRITE_REMOTE gt IC_DISMISS>
		CheckHack <IC_PLACE_IN_LOCAL gt IC_DISMISS>
	cmp	ax, IC_DISMISS
	jbe	done			; jump if IC_DISMISS or IC_NULL

moveRemoteExists:
	;
	; Move the file, either overwriting remote or place in local tree
	;
	call	UPDReceiveFileMoveFileRemoteOrLocal
	jmp	done

existLocally:
	;
	; File exists locally.  Only option is overwrite local file.
	; See if user wants to overwrite it.
	;
	mov	si, offset uiPoofReceiveFileConfirmOverwrite
	call	UtilDoConfirmation	; ax = InteractionCommand
	cmp	ax, IC_YES
	jne	done
moveToLocal:
	mov	ax, IC_PLACE_IN_LOCAL
	call	UPDReceiveFileMoveFileRemoteOrLocal

done:
	.leave
	ret

error:
	mov	si, offset uiPoofReceiveFileCopyError
	call	UtilDoError
	jmp	done

UPDReceiveFileMoveOrdinaryFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UPDReceiveFileMoveFileRemoteOrLocal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	(INTERNAL)
PASS:		es:di	= filename
		ax	= IC_OVERWRITE_REMOTE or IC_PLACE_IN_LOCAL
		ss:bp	= inherited stack from UPDReceiveFile
		current directory set to where file should be moved to.
RETURN:		carry set on error
DESTROYED:	ax, cx, dx, si, ds
SIDE EFFECTS:	Pops up error dialog box if a file error occurs.

PSEUDO CODE/STRATEGY:
	Call FileCopy to overwrite any existing remote file or FileCopyLocal
	to place file in local tree.  Then call FileDelete to delete the file
	in mailbox.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	11/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UPDReceiveFileMoveFileRemoteOrLocal	proc	near
	uses	bx,di,es
	.enter inherit UPDReceiveFile

	Assert	stackFrame, bp

	cmp	ax, IC_OVERWRITE_REMOTE
	je	remote

	;
	; Move to local dir.
	;
	segmov	ds, ss
	lea	si, ss:[appRef].FMAR_filename
	mov	cx, ss:[appRef].FMAR_diskHandle
	clr	dx			; copy to current dir
	call	FileMoveLocal
	jmp	afterMove

remote:
	;
	; Get the actual disk handle and path of the existing file, then
	; remove it.
	;
	movdw	dssi, esdi		; ds:si = dest file name
	segmov	es, ss
	lea	di, ss:[destFileActualPath]
	mov	cx, size destFileActualPath
	clr	bx, dx			; current path, no drive name
	call	FileConstructActualPath	; bx = disk handle
	jc	error

	;
	; Delete the existing file.
	;
	mov	dx, si			; ds:dx = dest file name
	call	FileDelete

	;
	; Move the file
	;
	segmov	ds, ss
	lea	si, ss:[appRef].FMAR_filename
	mov	cx, ss:[appRef].FMAR_diskHandle
	mov	dx, bx			; dx = dest disk handle
	call	FileMove

afterMove:
	jnc	done

error:
	;
	; Display error string.
	;
	mov	si, offset uiPoofReceiveFileCopyError
	call	UtilDoError
	stc

done:
	.leave
	ret
UPDReceiveFileMoveFileRemoteOrLocal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UPDReceiveFileMoveFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform the actual FileMove to the current directory.

CALLED BY:	(INTERNAL)
PASS:		es:di	= path whose last component is the filename
			  File is always moved to current directory.  Path info
			  in passed es:di is ignored.
		ss:bp	= inherited stack frame from UPDReceiveFile
RETURN:		es:di	= filename (last component in path)
		carry set if error
			ax	= FileError
DESTROYED:	cx, dx, si, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	11/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UPDReceiveFileMoveFile	proc	near
	.enter inherit UPDReceiveFile

	Assert	stackFrame, bp

	call	UtilLocateFilenameInPathname	; es:di = filename
	segmov	ds, ss
	lea	si, ss:[appRef].FMAR_filename
	mov	cx, ss:[appRef].FMAR_diskHandle
	clr	dx			; move to current dir
	call	FileMove

	.leave
	ret
UPDReceiveFileMoveFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UPDReceiveFileTestIfOverwritable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test if the file is overwritable.

CALLED BY:	(INTERNAL)
PASS:		ds:dx	= filename
RETURN:		if file can be overwritten
			carry clear
			bx	= non-zero
		else
			carry set
			bx	= 0
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Try to open the file with write-only access.  If it succeeds, the
	file can be overwritten.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	11/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UPDReceiveFileTestIfOverwritable	proc	near
	uses	ax
	.enter

	clr	bx			; assume we cannot overwrite
	mov	al, FILE_DENY_RW or FILE_ACCESS_W
	call	FileOpen		; ax = file handle
	jc	done			; jump if can't write to file
	mov_tr	bx, ax			; bx = file handle (bx != 0)
	call	FileClose
	clc				; ignore any error

done:
	.leave
	ret
UPDReceiveFileTestIfOverwritable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UPDReceiveFileGetDirPathInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get DirPathInfo of a file.

CALLED BY:	(INTERNAL)
PASS:		ds:dx	= filename
RETURN:		carry clear if no error
			cx	= DirPathInfo
			ax destroyed
		carry set if error
			ax	= FileError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	11/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UPDReceiveFileGetDirPathInfo	proc	near
	uses	di,es
	.enter

	mov	cx, size DirPathInfo
		CheckHack <size DirPathInfo eq size word>
	push	ax			; allocate DirPathInfo on stack (the
					;  value pushed doesn't do anything)
	movdw	esdi, sssp		; es:di = DirPathInfo
	mov	ax, FEA_PATH_INFO
	call	FileGetPathExtAttributes
	pop	cx			; cx = DirPathInfo

	.leave
	ret
UPDReceiveFileGetDirPathInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UPDReceiveQuickMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Receive a Quick Message and display on screen.

CALLED BY:	(INTERNAL) UPDMetaMailboxNotifyMessageAvailable
PASS:		cxdx	= MailboxMessage
RETURN:		nothing
DESTROYED:	ax, bx, si, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UPDReceiveQuickMsg	proc	near
appRef	local	VMTreeAppRef
	.enter

	;
	; Get body ref.
	;
	segmov	es, ss
	lea	di, ss:[appRef]
	mov	ax, size VMTreeAppRef
	call	MailboxGetBodyRef
	jc	done			; just cleanup if can't get body ref

	;
	; Instantiate a dialog block and bring it up on screen after placing
	; the subject text in the moniker for the dialog.
	;
	mov	bx, handle PoofQuickMessageReceivePanel
	mov	si, offset PoofQuickMessageReceivePanel
	call	UserCreateDialog	; ^lbx:si = dialog
	
	call	MailboxGetSubjectLMem
	mov_tr	di, ax

	push	ds
	call	ObjLockObjBlock
	mov	ds, ax
	mov	ax, di
	call	UtilMangleMoniker
	call	LMemFree
	call	MemUnlock
	; (use ObjMessage here to avoid having to save cx, dx, and bp across
	; this call...)
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	clr	di
	call	ObjMessage
	pop	ds

	;
	; Pass message text to panel
	;
	push	bp
	push	bx
	mov	bx, ss:[appRef].VMTAR_vmFile
	mov	ax, ss:[appRef].VMTAR_vmChain.high
	call	VMLock			; ax = sptr, bp = hptr
	pop	bx			; ^hbx = dialog block
	push	bp, cx, dx

	mov	si, offset PoofQuickMessageReceiveText	; ^lbx:si = text obj
	mov_tr	dx, ax
	mov	bp, size VMChainLink	; dx:bp = text string
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx			; null-terminated
	mov	di, mask MF_CALL	; because we're passing an fptr
	call	ObjMessage

	pop	bp, cx, dx		; bp = hptr, cxdx = MailboxMessage
	call	VMUnlock
	pop	bp			; restore frame ptr

done:
	lea	di, ss:[appRef]		; es:di = appRef
	mov	ax, size VMTreeAppRef
	call	MailboxDoneWithBody

	.leave
	ret
UPDReceiveQuickMsg	endp

PoofControlCode	ends
