COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		mainClavin.asm

AUTHOR:		Adam de Boor, Oct 10, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/10/94	Initial revision


DESCRIPTION:
	Functions for system inbox/outbox support
		

	$Id: mainClavin.asm,v 1.1 97/04/04 15:50:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
	RolSendControlClass
idata	ends

BodyRefs	union
    BR_card	VMTreeAppRef
BodyRefs	end

ClavinCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDMetaMailboxCreateMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a message for sending via Clavin (via some transport
		other than printing or faxing, of course, which use the
		printing model to create the body)

CALLED BY:	MSG_META_MAILBOX_CREATE_MESSAGE
PASS:		*ds:si	= GeoDex object
		ds:di	= GeoDexInstance
		^lcx:dx	= MailboxSendControl
		bp	= transaction handle
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	MSG_MAILBOX_SEND_CONTROL_{REGISTER,CANCEL}_MESSAGE is called
     			on the send control

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/10/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDMetaMailboxCreateMessage method dynamic GeoDexClass, 
				MSG_META_MAILBOX_CREATE_MESSAGE
transHandle	local	word			push bp
bodyType	local	MailboxObjectType
rma		local	MSCRegisterMessageArgs
body		local	BodyRefs
subjBlock	local	hptr
		.enter
		
		mov	ss:[subjBlock], 0	; assume no subject block
						;  needed
	;
	; Find what type of data the user selected.
	;
		push	bp
		mov	bp, ss:[transHandle]
		movdw	bxsi, cxdx
		mov	ax, MSG_MAILBOX_SEND_CONTROL_GET_OBJECT_TYPE
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	bp
		mov_tr	cx, ax			; cx <- object type
	;
	; Call the appropriate routine to create the message body.
	; 
		cmp	cx, MOT_DOCUMENT
		je	exportCards
		Assert	e, cx, MOT_CURRENT_CARD
exportCards:
		call	GDCCreateCardBody
		.assert	$ eq registerMessage
registerMessage::
		jc	doCancel		; => couldn't create body
	;
	; Now have the body, with ss:[body] filled in properly. Set up the
	; arguments for registering the message. Many of them have been
	; set up by the body-specific routine, but we do what we can.
	; 
		lea	ax, ss:[body]
		movdw	ss:[rma].MSCRMA_bodyRef, ssax
	    ;
	    ; The message can be sent any time between now and forever.
	    ; 
		movdw	ss:[rma].MSCRMA_startBound, MAILBOX_NOW
		movdw	ss:[rma].MSCRMA_endBound, MAILBOX_ETERNITY
	    ;
	    ; For now, we send the message to the generic address book appli-
	    ; cation. Might want to make this GeoDex-specific at some point.
	    ; 
		mov	{word}ss:[rma].MSCRMA_destApp.GT_chars[0], 
				'A' or ('D' shl 8)
		mov	{word}ss:[rma].MSCRMA_destApp.GT_chars[2], 
				'B' or ('K' shl 8)
		mov	ss:[rma].MSCRMA_destApp.GT_manufID,
				MANUFACTURER_ID_GENERIC
	;
	; Call the SendControl to register the message.
	; 
		mov	cx, ss
		lea	dx, ss:[rma]
		push	bp
		mov	bp, ss:[transHandle]
		mov	ax, MSG_MAILBOX_SEND_CONTROL_REGISTER_MESSAGE
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	bp

freeThings:
	;
	; If the subject was stored in a memory block, free that block.
	; 
		mov	bx, ss:[subjBlock]
		tst	bx
		jz	done
		call	MemFree

done:
		.leave
		ret

doCancel:
	;
	; Couldn't create the body, so we have to cancel the transaction
	; 
		tst	ax
		jz	done		; => already canceled

		mov	ax, MSG_MAILBOX_SEND_CONTROL_CANCEL_MESSAGE
		push	bp
		mov	bp, ss:[transHandle]
		clr	di, dx		; dx <- 0, notify user
		call	ObjMessage
		pop	bp
		jmp	done
GDMetaMailboxCreateMessage endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDMetaMailboxMessageRegistered
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after a successful or failed message registration

CALLED BY:	MSG_META_MAILBOX_MESSAGE_REGISTERED
PASS:		ds	= dgroup
		^hcx	= MSCMessageRegisteredArgs
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	VM file is closed and body may be deleted

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDMetaMailboxMessageRegistered method dynamic GeoDexClass, 
				MSG_META_MAILBOX_MESSAGE_REGISTERED
		.enter
		mov	bx, cx
		call	MemLock
		mov	ds, ax
		mov	si, offset MSCMRA_bodyRef
	;
	; If body is in a VM tree, and registration failed, free the VM tree
	; 
		cmp	ds:[MSCMRA_bodyStorage].MS_manuf,
				MANUFACTURER_ID_GEOWORKS
		jne	done
		cmp	ds:[MSCMRA_bodyStorage].MS_id, 
				GMSID_VM_TREE
		jne	done
		mov	bx, ds:[si].VMTAR_vmFile

		tst	ds:[MSCMRA_error]
		jz	doneWithVMFile		; => successful
		
		movdw	axbp, ds:[si].VMTAR_vmChain
		call	VMFreeVMChain

doneWithVMFile:
	;
	; Now tell the Mailbox library we're done with the file.
	;
		call	MailboxDoneWithVMFile
done:
		mov	bx, cx
		call	MemUnlock
		.leave
		ret
GDMetaMailboxMessageRegistered endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDCCreateCardBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the body and subject of the message for the current
		address card, storing pointers to them in the args in the
		inherited stack frame.

CALLED BY:	(INTERNAL) GDMetaMailboxCreateMessage
PASS:		ds	= dgroup
		^lbx:si	= MailboxSendControl
		cx	= MOT_DOCUMENT or MOT_CURRENT_CARD
		ss:bp	= inherited frame
RETURN:		carry set on error
			ax	= non-zero to cancel transaction
		carry clear if ok	
		MSCRMA_bodyRefLen, MSCRMA_summary, ss:[subjBlock],
			MSCRMA_bodyStorage, MSCRMA_bodyFormat, MSCRMA_flags,
			ss:[body] all set (body.BR_card.VMTAR_vmFile may be
			0)
DESTROYED:	ax, cx, dx, di
SIDE EFFECTS:	VM file is gotten from the Mailbox library and must be
     			released if body.BR_card.VMTAR_vmFile is non-zero

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/10/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
possibleFormats	MailboxDataFormat	<
	GMDFID_ADDRESS_CARD, MANUFACTURER_ID_GEOWORKS
>, <
	GMDFID_TRANSFER_ITEM, MANUFACTURER_ID_GEOWORKS
>, <
	GMDFID_INVALID, MANUFACTURER_ID_GEOWORKS
>

GDCCreateCardBody proc	near
		uses	bx, si
		.enter	inherit	GDMetaMailboxCreateMessage
		
		push	cx, bp
		mov	cx, cs
		mov	dx, offset possibleFormats
		mov	bp, ss:[transHandle]
		mov	ax, MSG_MAILBOX_SEND_CONTROL_CHOOSE_FORMAT
		mov	di, mask MF_CALL
		call	ObjMessage
		or	cx, dx
		pop	cx, bp
		jnz	haveFormat
		
		clr	ax
		stc
		jmp	done

haveFormat:
		

	;
	; Set up the constant portions of the registration args:
	; 	- use the VM_TREE storage driver
	; 	- we're shipping across one or more address cards
	; 	- the cards should be "filed" and delivered first-class, plus
	;	  the body should be nuked once the message is gone
	;
		mov	ss:[rma].MSCRMA_bodyStorage.MS_id,
				GMSID_VM_TREE
		mov	ss:[rma].MSCRMA_bodyStorage.MS_manuf,
				MANUFACTURER_ID_GEOWORKS

		mov	ss:[rma].MSCRMA_bodyFormat.MDF_id, dx
		mov	ss:[rma].MSCRMA_bodyFormat.MDF_manuf,
				MANUFACTURER_ID_GEOWORKS
		
		mov	ss:[rma].MSCRMA_flags,
				(MDV_FILE shl offset MMF_VERB) or \
				(MMP_FIRST_CLASS shl offset MMF_PRIORITY) or \
				mask MMF_DELETE_BODY_AFTER_TRANSMISSION

		mov	ss:[body].BR_card.VMTAR_vmFile, 0	; signal no VM
								;  file gotten
								;  until it is
	;
	; Make sure there's a current record to export.
	; 
		tst	ds:[curRecord]
		jnz	initMetaShme
		
doCancel:
		mov	ax, TRUE		; cancel, please
		stc
		jmp	done

initMetaShme:
	;
	; Ask for a VM file with the default number of blocks.
	; 
		clr	bx
		cmp	cx, MOT_CURRENT_CARD
		je	haveNumBlocks
		mov	bx, 0xffff		; potentially many, so ask for
						;  our own file, to be safe
haveNumBlocks:
		call	MailboxGetVMFile
		jc	doCancel
	;
	; Export the current record.
	; 
		mov	ax, ss:[rma].MSCRMA_bodyFormat.MDF_id
		mov	ss:[body].BR_card.VMTAR_vmFile, bx
		cmp	cx, MOT_DOCUMENT
		je	exportDoc
		call	GDCExportCard
		jmp	setBody

exportDoc:
		call	GDCExportDoc

setBody:
		jc	done
	;
	; Set up the body reference and the length of same in the reg args
	; 
		mov	ss:[body].BR_card.VMTAR_vmChain.high, ax
		clr	ss:[body].BR_card.VMTAR_vmChain.low
		mov	ss:[rma].MSCRMA_bodyRefLen, size BR_card
	;
	; Point to the subject the routine returned.
	; 
		movdw	ss:[rma].MSCRMA_summary, cxdx
		mov	ss:[subjBlock], bx
		clc			; signal happy
done:
		.leave
		ret
GDCCreateCardBody endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDCExportCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare to export one or more cards from the file as the
		body of a message

CALLED BY:	(INTERNAL) GDCExportCard, GDCExportDoc
PASS:		bx	= VM file in which to place the result
		ss:bp	= inherited frame with ssMeta as first local variable
		ax	= number of rows to export
		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	ssMeta structure is initialized
     		current record is saved
		ds:[exportFlag] is set to IE_CLIPBOARD

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 3/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDCExportCommon proc	near
ssMeta		local	SSMetaStruc
		.enter	inherit
	;
	; Make sure current record is current.
	; 
		push	bp, bx, si, di, es, ax
		call	SaveCurRecord
		pop	bp, bx, si, di, es, ax
	;
	; Initialize the ssMeta structure so we can store stuff in it.
	; 
		push	bp
		push	ax
		lea	bp, ss:[ssMeta]
		clr	ax, cx
		mov	dx, ss
		call	SSMetaInitForStorage
		pop	ax
	;		
	; set the transfer item size
	; ax = # rows
	;
		mov	cx, GEODEX_NUM_FIELDS		; cx - number of columns
		call	SSMetaSetScrapSize		; unlock the header
							;  block
		pop	bp
	;
	; Set exportFlag properly.
	; 
		mov	ds:[exportFlag], IE_CLIPBOARD	; this is a clipboard
							;  item; leave multi-
							;  line fields unaltered
		.leave
		ret
GDCExportCommon	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDCFinishExportCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish up creating a message body by converting it to
		a transfer item, if necessary.

CALLED BY:	(INTERNAL) GDCExportCard, GDCExportDoc
PASS:		ss:bp	= inherited frame
RETURN:		carry set on error:
			ax	= non-zero (cancel transaction)
		carry clear if ok:
			ax	= vm chain head
DESTROYED:	nothing
SIDE EFFECTS:	vm block allocated in the file, maybe

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/12/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDCFinishExportCommon proc	near
ssMeta		local	SSMetaStruc
format		local	GeoworksMailboxDataFormatID
		.enter	inherit
		mov	ax, ss:[ssMeta].SSMDAS_hdrBlkVMHan
		cmp	ss:[format], GMDFID_TRANSFER_ITEM
		jne	done
		
		push	bx, cx, dx, ds, es, si, di

	;
	; Create the ClipboardItemHeader for the thing.
	;
		push	dx, bp
		mov	dx, ss
		lea	bp, ss:[ssMeta]
		call	SSMetaDoneWithCutCopyNoRegister
		pop	dx, bp
	;
	; Now we need to transform that into a MailboxTransferItemHeader.
	; First compute the size of the MTIH
	;
		mov	ax, ss:[ssMeta].SSMDAS_tferItemHdrVMHan
		mov	bx, ss:[ssMeta].SSMDAS_vmFileHan
		mov	dx, bp			; dx <- frame pointer
		call	VMLock
		xchg	dx, bp			; dx <- mem handle, bp <- fp

		mov	ds, ax
		mov	ax, ds:[CIH_formatCount]
		shl	ax			; room for the chains
		shl	ax
		add	ax, size VMChainTree + size ClipboardItemHeader
	;
	; Enlarge the block to be that big.
	;
		mov	bx, dx
		clr	cx
		call	MemReAlloc
		jc	fail
	;
	; Shift the ClipboardItemHeader up to MTIH_cih
	;
		mov	ds, ax
		mov	es, ax
		mov	si, size ClipboardItemHeader - 1
		mov	di, offset MTIH_cih + size ClipboardItemHeader - 1
		mov	cx, size ClipboardItemHeader
		std
		rep	movsb
		cld
	;
	; Set up the VMChainTree structure.
	;
		mov	ds:[MTIH_meta].VMCT_meta.VMCL_next, VM_CHAIN_TREE
		mov	cx, ds:[MTIH_cih].CIH_formatCount
		mov	ds:[MTIH_meta].VMCT_count, cx
		mov	di, offset MTIH_branch
		mov	ds:[MTIH_meta].VMCT_offset, di
		jcxz	unlockDone
	;
	; Copy the CIFI_vmChain fields into the branch table at the end of
	; the block.
	;
		mov	si, offset MTIH_cih.CIH_formats.CIFI_vmChain
chainLoop:
		movsw
		movsw
		add	si, size ClipboardItemFormatInfo - size dword
		loop	chainLoop

unlockDone:
		xchg	dx, bp			; bp <- mem, dx <- fp
		call	VMDirty
		call	VMUnlock
		mov	bp, dx
	;
	; Return the MTIH handle as the head of the chain/tree
	;
		mov	ax, ss:[ssMeta].SSMDAS_tferItemHdrVMHan
		clc
error:
		pop	bx, cx, dx, ds, es, si, di
done:
		.leave
		ret

fail:
	;
	; Failed to enlarge -- nuke the header.
	;
		xchg	bp, dx
		call	VMUnlock
		mov	bp, dx
		mov	ax, ss:[ssMeta].SSMDAS_tferItemHdrVMHan
		mov	bx, ss:[ssMeta].SSMDAS_vmFileHan
		call	VMFree
		mov	ax, ss:[ssMeta].SSMDAS_hdrBlkVMHan
		call	VMFreeVMChain
		call	MailboxDoneWithVMFile
		mov	ax, TRUE		; cancel transaction
		stc
		jmp	error
		
GDCFinishExportCommon endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDCExportCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform the actual export of the current card (so Export*
		routines have local variables they expect)

CALLED BY:	(INTERNAL) GDCCreateCardBody
PASS:		bx	= VM file in which to place the result
		ax	= data format ID
		ds	= dgroup
RETURN:		carry set on error:
			ax	= non-zero if should cancel transaction
		carry clear if ok:
			ax	= VM block handle of the resulting VM chain
			bx	= subjBlock
			cx:dx	= subject
DESTROYED:	nothing
SIDE EFFECTS:	current record is saved

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/10/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDCExportCard	proc	near
ssMeta		local	SSMetaStruc
format		local	GeoworksMailboxDataFormatID
		.enter
		mov	ss:[format], ax

		mov	ax, 1				; ax - number of rows
		call	GDCExportCommon
	;
	; create the transfer item
	;
		call	InitFieldSize			; initialize 'fieldSize'
							;  array to all 0
		clr	cx				; cx - current row
							;  number
		call	ExportRecord			; create a transfer
							;  item block
		call	ExportFieldName			; export field names 
	;
	; Fetch the index field into sortBuffer and use that for the subject.
	; 
		mov	si, ds:[curRecord]
		call	GetLastName

		clr	bx
		mov	dx, offset sortBuffer
		mov	cx, ds
	;
	; Return the handle of the header block as the start of the vm tree
	; 
		call	GDCFinishExportCommon

		.leave
		ret
GDCExportCard	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDCExportDoc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Export the current document as a message body.

CALLED BY:	(INTERNAL) GDCCreateCardBody
PASS:		bx	= VM file in which to place the result
		ax	= data format ID
		ds	= dgroup
RETURN:		carry set on error:
			ax	= non-zero to cancel transaction
		carry clear if ok:
			ax	= VM block handle of the resulting VM chain
			bx	= subjBlock
			cx:dx	= subject
DESTROYED:	si, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 3/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDCExportDoc	proc	near
ssMeta		local	SSMetaStruc
format		local	GeoworksMailboxDataFormatID
		.enter

		mov	ss:[format], ax
		; is the database file empty?

		tst	ds:[gmb.GMB_numMainTab]
		jz	err			; if empty, just exit

	;
	; Want the document name for the subject. Allocate a buffer for it.
	;
		mov	dx, bx			; dx <- VM file
		mov	ax, size FileLongName
		mov	cx, ALLOC_FIXED
		call	MemAlloc
		jc	err
	;
	; Find the document object and ask it for the name.
	; 
		push	bx			; save buffer handle for return
		push	dx			; save VM file
		push	ax			; save buffer seg for next call

		mov	cx, ds:[fileHandle]
		GetResourceHandleNS RolAppDocControl, bx
		mov	si, offset RolAppDocControl
		mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_DOC_BY_FILE
		mov	di, mask MF_CALL
		call	ObjMessage

		movdw	bxsi, cxdx
		pop	cx			; cx <- buffer segment
		clr	dx			; cx:dx <- buffer
		mov	ax, MSG_GEN_DOCUMENT_GET_FILE_NAME
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	bx			; bx <- VM file
		push	cx			; save buffer segment for return
	;
	; Prepare for export, specifying the number of records as the number
	; of rows.
	; 
		mov	ax, ds:[gmb.GMB_numMainTab]
		call	GDCExportCommon
	;
	; Now export the entire file.
	; 
		call	FileExport
	;
	; Set up return registers.
	; 
		call	GDCFinishExportCommon
		pop	cx
		clr	dx			; cx:dx <- subject
		pop	bx			; bx <- subjBlock
		clc
exit:
		.leave
		ret
err:
		mov	ax, TRUE		; cancel transaction
		stc
		jmp	exit
GDCExportDoc	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDMetaMailboxNotifyMessageAvailable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process a received message.

CALLED BY:	MSG_META_MAILBOX_NOTIFY_MESSAGE_AVAILABLE
PASS:		*ds:si	= GeoDex object
		ds:di	= GeoDexInstance
		cxdx	= MailboxMessage
RETURN:		carry set to indicate GEOS message handled
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDMetaMailboxNotifyMessageAvailable method dynamic GeoDexClass, 
				MSG_META_MAILBOX_NOTIFY_MESSAGE_AVAILABLE
		.enter
	;
	; Take possession of the message, for good or ill.
	; 
		call	MailboxAcknowledgeMessageReceipt
	;
	; See if it's something we understand.
	; 
		call	MailboxGetBodyFormat
		cmp	bx, MANUFACTURER_ID_GEOWORKS
		jne	honk
		cmp	ax, GMDFID_ADDRESS_CARD
		je	importAddressCard
		; do something with document, here
honk:
done:
		call	MailboxDeleteMessage
		stc
		.leave
		ret

importAddressCard:
		call	GDCReadAddressCard
		push	cx, dx
		mov	si, ds:[curRecord]
		call	DisplayCurRecord
		pop	cx, dx
		jmp	done
GDMetaMailboxNotifyMessageAvailable endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GDCReadAddressCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Import one or more address cards into the current document,
		allowing the user to specify how duplicate cards are to be
		handled (in contrast to the Paste Record trigger, which
		always creates a duplicate record)

CALLED BY:	GDMetaMailboxNotifyMessageAvailable
PASS:		ds	= dgroup
		cxdx	= MailboxMessage to process
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	records added/merged into the document

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GDCReadAddressCard proc	near
ssMeta		local	SSMetaStruc
		uses	cx, dx
		.enter
	;
	; First gain access to the message body.
	; 
		mov	ax, size VMTreeAppRef
		sub	sp, ax
		mov	di, sp
		segmov	es, ss
		call	MailboxGetBodyRef
		mov	ax, es:[di].VMTAR_vmChain.high
		mov	bx, es:[di].VMTAR_vmFile
	;
	; Now initialize the ssMeta variable so we can read the data out of
	; the body.
	; 
		push	cx, dx, di, es
		push	bp
		mov	dx, ss
		lea	bp, ss:[ssMeta]
		call	SSMetaInitForRetrieval
		pop	bp
	;
	; Call the common routine to paste stuff into the current document from
	; an ssmeta scrap. We set the mergeFlag global variable so the code
	; knows to ask the user what to do about duplicate cards.
	; 
		push	ds:[mergeFlag]
		mov	ds:[mergeFlag], IMS_HAVENT_ASKED
		call	PasteFromSSMeta
		pop	ds:[mergeFlag]
	;
	; Let the Mailbox library know we're done with the body.
	; 
		pop	cx, dx, di, es
		mov	ax, size VMTreeAppRef
		call	MailboxDoneWithBody

		add	sp, ax			; clear the app-ref from the
						;  stack
		.leave
		ret
GDCReadAddressCard endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RSCMailboxSendControlObjectTypeSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust UI objects to react to the selected object type

CALLED BY:	MSG_MAILBOX_SEND_CONTROL_OBJECT_TYPE_SELECTED
PASS:		*ds:si	= RolSendControl object
		ds:di	= RolSendControlInstance
		cx	= MailboxObjectType selected
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	things in the print app ui might be set usable or not

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 2/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RSCMailboxSendControlObjectTypeSelected method dynamic RolSendControlClass, 
				MSG_MAILBOX_SEND_CONTROL_OBJECT_TYPE_SELECTED
		.enter
		push	cx
		mov	di, offset RolSendControlClass
		call	ObjCallSuperNoLock
		pop	cx
		
		mov	si, offset PrintCurrent
		call	setNotUsable
		
		mov	ax, offset setUsable
		cmp	cx, MOT_DOCUMENT
		je	manglePrintAllPrintPhone
		mov	ax, offset setNotUsable
manglePrintAllPrintPhone:
		mov	si, offset PrintAll
		call	ax
		mov	si, offset PrintPhone
		call	ax
		.leave
		ret

setUsable:
		push	ax
		mov	ax, MSG_GEN_SET_USABLE
		jmp	usableNotUsableCommon
setNotUsable:
		push	ax
		mov	ax, MSG_GEN_SET_NOT_USABLE

usableNotUsableCommon:
		mov	dl, VUM_NOW
		GetResourceHandleNS PrintGroup, bx
		mov	di, mask MF_FIXUP_DS
		push	cx
		call	ObjMessage
		pop	cx
		pop	ax
		retn
RSCMailboxSendControlObjectTypeSelected endm

ClavinCode	ends
