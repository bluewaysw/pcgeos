COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		uiSendDialog.asm

AUTHOR:		Adam de Boor, Oct  4, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/ 4/94	Initial revision


DESCRIPTION:
	Implementation of MailboxSendDialogClass
		

	$Id: uiSendDialog.asm,v 1.1 97/04/05 01:19:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MailboxClassStructures	segment	resource

	MailboxSendDialogClass

MailboxClassStructures	ends

SendControlCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDSetTransport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust our moniker

CALLED BY:	MSG_MSD_SET_TRANSPORT
PASS:		*ds:si	= MailboxSendDialog object
		ds:di	= MailboxSendDialogInstance
		dx:bp	= MailboxMediaTransport to use
RETURN:		cx	= handle of MAC
DESTROYED:	ax, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
 	if MT different from current:
 		remove reference from the current MAC
		update moniker with new transport string
		load transport driver
		get MAC class for the MT
		if any MAC, instantiate
		set current medium invalid so MAC gets called
	call MAC_SET_MEDIUM on current MAC, if any

		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDSetTransport	method dynamic MailboxSendDialogClass, MSG_MSD_SET_TRANSPORT
		uses	bp
		.enter
	;
	; See if the transport is the same as we've got on record.
	; 
		mov	es, dx				; es:bp <- MediaTrans
		mov	ax, es:[bp].MMT_transport.MT_manuf
		cmp	ds:[di].MSDI_curTrans.MMT_transport.MT_manuf, ax
		jne	newTrans

		mov	ax, es:[bp].MMT_transport.MT_id
		cmp	ds:[di].MSDI_curTrans.MMT_transport.MT_id, ax
		jne	newTrans

		mov	ax, es:[bp].MMT_transOption
		cmp	ds:[di].MSDI_curTrans.MMT_transOption, ax
		je	checkMedium

newTrans:
	;
	; Different transport -- go mess with things.
	; 
		call	MSDReplaceTransport
		DerefDI	MailboxSendDialog

checkMedium:
	;
	; Now we're in synch about the transport, see if the medium is the
	; same.
	; 
		clr	bx			; assume not new medium
		mov	ax, es:[bp].MMT_medium.MET_manuf
		cmp	ds:[di].MSDI_curTrans.MMT_medium.MET_manuf, ax
		jne	newMedium
		
		mov	ax, es:[bp].MMT_medium.MET_id
		cmp	ds:[di].MSDI_curTrans.MMT_medium.MET_manuf, ax
		je	setMedium

newMedium:
	;
	; The medium is different, so store it in our instance and tell the
	; MAC about it.
	; 
		movdw	cxdx, es:[bp].MMT_medium
		movdw	ds:[di].MSDI_curTrans.MMT_medium, cxdx
		dec	bx			; flag different medium

setMedium:
		mov	si, ds:[di].MSDI_curMAC
		mov	di, ds:[di].MSDI_sendTrigger
		tst	si
		jz	useDefaultSendMoniker
		
			CheckHack <MACSMA_changed eq MACSetMediumArgs-2>
		push	bx

			CheckHack <MACSMA_transOption eq MACSetMediumArgs-4>
		push	es:[bp].MMT_transOption

			CheckHack <MACSMA_medium eq MACSetMediumArgs-8>
		pushdw	es:[bp].MMT_medium

			CheckHack <MACSMA_medium eq 0>
		mov	bp, sp
		mov	ax, MSG_MAILBOX_ADDRESS_CONTROL_SET_MEDIUM
		call	ObjCallInstanceNoLock
		add	sp, size MACSetMediumArgs
	;
	; Ask the address control what moniker it wants in the transmit trigger
	; 
		mov	ax, MSG_MAILBOX_ADDRESS_CONTROL_GET_TRANSMIT_MONIKER
		call	ObjCallInstanceNoLock
		
		Assert	optr, cxdx

setTransmitMoniker:
	;
	; Set the moniker for the Send trigger as the MAC or we ourselves
	; determined.
	; 
		push	si			; save MAC
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
		mov	bp, VUM_NOW
		mov	si, di			; *ds:si <- Send trigger for
						;  dialog
		call	ObjCallInstanceNoLock
		pop	cx			; *ds:cx <- MAC
		.leave
		ret

useDefaultSendMoniker:
	;
	; No MAC, so just use the default moniker
	; 
		mov	cx, handle uiDefaultTransmitMoniker
		mov	dx, offset uiDefaultTransmitMoniker
		jmp	setTransmitMoniker
MSDSetTransport	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDGetSendControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if we were created by a MailboxSendControl and return
		its optr if so.

CALLED BY:	(INTERNAL)
PASS:		ds	= object block
RETURN:		carry set if have send control available:
			^lbx:si	= MailboxSendControl
		carry clear if not:
			bx, si = destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/25/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDGetSendControl proc	near
		uses	cx, dx, ax, di, bp
		.enter
		movdw	bxsi, ds:[OLMBH_output]
		tst_clc	bx
		jz	done
		push	di
		mov	cx, segment MailboxSendControlClass
		mov	dx, offset MailboxSendControlClass
		mov	ax, MSG_META_IS_OBJECT_IN_CLASS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	di
done:
		.leave
		ret
MSDGetSendControl endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDPassTransportData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we have a MailboxSendControl that has a hint containing
		data for the selected driver tell it about them

CALLED BY:	(INTERNAL) MSDReplaceTransport
PASS:		^lbx:si	= MailboxAddressControl
		*ds:di	= MailboxSendDialog
RETURN:		nothing
DESTROYED:	cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDPassTransportData proc	near
		uses	ax, es, bp, si, di, bx
		class	MailboxSendDialogClass
		.enter
	;
	; See if we have a MailboxSendControl associated with us, by looking
	; at the output of the object block and seeing if it's a send control
	; 
		push	bx, si
		call	MSDGetSendControl
		jc	haveSendControl
		pop	bx, si
		jmp	exit

haveSendControl:
	;
	; Point dx:bp at the current transport descriptor
	; 
		mov	di, ds:[di]
		add	di, ds:[di].MailboxSendDialog_offset
		lea	bp, ds:[di].MSDI_curTrans
		mov	dx, ds
		call	ObjSwapLock
	;
	; Setup for the scan.
	; 
		segmov	es, cs
		mov	di, offset findTransportHandlerTable
		mov	ax, length findTransportHandlerTable
	;
	; Run through all the hints. On return, if a hint was found, cx
	; will be other than it was, and dx will be the offset of the
	; data for the address controller.
	; 
		clr	cx		; assume not hit
		call	ObjVarScanData
		mov	di, bx		; save MSD block handle
		pop	bx, si		; ^lbx:si <- MAC
		push	di		; now push MSD block handle
		jcxz	done		; => didn't find one
	;
	; Pass the transport data to the address controller.
	; 
		mov	cx, ds			; cx:dx <- data address
		mov	bp, ds:[LMBH_handle]	; bp <- block holding data
		mov	ax, MSG_MAILBOX_ADDRESS_CONTROL_PROCESS_TRANSPORT_HINT
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
done:
		pop	bx		; bx <- MSD block
		call	ObjSwapUnlock
exit:
		.leave
		ret
MSDPassTransportData endp

findTransportHandlerTable	VarDataHandler \
	<ATTR_MAILBOX_SEND_CONTROL_TRANSPORT_HINT, MSDProcessTransportHint>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDProcessTransportHint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the passed bit o' vardata is for the selected transport

CALLED BY:	(INTERNAL) MSCPassTransportData via ObjVarScanData
PASS:		*ds:si	= MailboxSendControl
		ds:bx	= extra data for the hint (MailboxTransportAndOption)
		ax	= ATTR_MAILBOX_SEND_CONTROL_TRANSPORT_HINT
		cx	= 0 if not seen proper hint yet
		dx:bp	= MailboxMediaTransport holding the selected transport
RETURN:		if for selected transport:
			cx	= -1
			dx	= offset of transport data within the hint
		if not for selected transport:
			cx, dx	= unchanged
DESTROYED:	ax, es
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDProcessTransportHint proc	far
		.enter
		jcxz	checkIt
done:
		.leave
		ret
checkIt:
		mov	es, dx
		cmpdw	ds:[bx].MTAO_transport, es:[bp].MMT_transport, ax
		jne	done
		mov	ax, es:[bp].MMT_transOption
		cmp	ds:[bx].MTAO_transOption, ax
		jne	done
		dec	cx		; signal found
		lea	dx, ds:[bx+size MailboxTransportAndOption]
		jmp	done
MSDProcessTransportHint endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDNukeMAC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get rid of any MailboxAddressControl we're currently using

CALLED BY:	(INTERNAL) MSDReplaceTransport, MSDGenRemove
PASS:		ds:di	= MailboxSendDialogInstance
		*ds:si	= MailboxSendDialog
RETURN:		nothing
DESTROYED:	di, bx
SIDE EFFECTS:	MSDI_curMAC set to 0. MAC removed from tree and reference
		deleted

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDNukeMAC	proc	near
		uses	ax, cx, dx, bp, si
		class	MailboxSendDialogClass
		.enter
		mov	bx, si		; preserve dialog for geometry recalc

		clr	si
		xchg	ds:[di].MSDI_curMAC, si
		tst	si
		jz	macNuked
	;
	; If we have a current transaction, tweak it and remove another
	; reference from the MAC (put on it by the transaction)
	;
		mov	di, ds:[di].MSDI_transaction
		tst	di
		jz	removeMAC

		mov	ax, MSG_MAILBOX_ADDRESS_CONTROL_DEL_REF
		call	ObjCallInstanceNoLock

		push	bx
		mov	bx, ds:[OLMBH_output].handle
		call	ObjSwapLock
		mov	di, ds:[di]
		mov	ds:[di].MSCT_addrControl, 0
		call	ObjSwapUnlock
		pop	bx
removeMAC:
	;
	; Need to get rid of the current MAC. First remove it from the
	; generic tree.
	; 
		mov	dl, VUM_NOW
		mov	bp, mask CCF_MARK_DIRTY
		mov	ax, MSG_GEN_REMOVE
		call	ObjCallInstanceNoLock
	;
	; Now delete our reference to it -- if there are no transactions
	; pending involving it, the controller will destroy itself.
	; 
		mov	ax, MSG_MAILBOX_ADDRESS_CONTROL_DEL_REF
		call	ObjCallInstanceNoLock		
	;
	; Recalculate geometry once next MAC is added, or when we're all done,
	; if no new MAC gets added...
	; 
		mov	si, bx
		mov	ax, MSG_GEN_RESET_TO_INITIAL_SIZE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjCallInstanceNoLock
macNuked:
		.leave
		ret
MSDNukeMAC	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDReplaceTransport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the transport of record to that passed, making the
		commensurate adjustments to our UI.

CALLED BY:	(INTERNAL) MDSetTransport
PASS:		*ds:si	= MailboxSendDialog
		ds:di	= MailboxSendDialogInstance
		es:bp	= MailboxMediaTransport with new data
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
 		remove reference from the current MAC
		update moniker with new transport string
		load transport driver
		get MAC class for the MT
		if any MAC, instantiate
		set current medium invalid so MAC gets called
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDReplaceTransport proc	near
		class	MailboxSendDialogClass
		uses	bp, es, si
		.enter
	;
	; Get rid of any current MAC we have.
	; 
		call	MSDNukeMAC

		push	si
		DerefDI	MailboxSendDialog
	;
	; Prepare for MediaGetTransportString while storing the different
	; parts in our instance data.
	; 
		movdw	axbx, es:[bp].MMT_transport
		movdw	ds:[di].MSDI_curTrans.MMT_transport, axbx
	    ;
	    ; Set the current medium to be invalid so the new MAC gets a call
	    ; from us later on.
	    ; 
		mov	ds:[di].MSDI_curTrans.MMT_medium.MET_manuf,
			MANUFACTURER_ID_GEOWORKS
		mov	ds:[di].MSDI_curTrans.MMT_medium.MET_id,
			GMID_INVALID
		movdw	cxdx, es:[bp].MMT_medium
		mov	si, es:[bp].MMT_transOption
		mov	ds:[di].MSDI_curTrans.MMT_transOption, si
	;
	; Fetch the transport string and store it away, freeing what we had
	; before.
	; 
		call	MediaGetTransportString
EC <		ERROR_C	HOW_CAN_MEDIA_TRANSPORT_BE_INVALID?		>
   		pop	si			; *ds:si <- MSD

		DerefDI	MailboxSendDialog
		
		xchg	ds:[di].MSDI_lastTransStr, ax
		tst	ax
		jz	setMoniker
		call	LMemFree
setMoniker:
	;
	; Try and set the moniker. This will fail if we don't have a contents
	; string yet, but that's fine -- we'll get that soon enough.
	; 
		call	MSDSetMoniker
	;
	; Disable the Send trigger for now. The MAC can tell us to enable it
	; again later.
	; 
		clr	cx
		mov	ax, MSG_MSD_SET_ADDRESS_VALID
		call	ObjCallInstanceNoLock
	;
	; Now attempt to load the transport driver.
	; 
		movdw	cxdx, es:[bp].MMT_transport
		call	MailboxLoadTransportDriver
		jc	done			; for now, just leave
						;  curMAC 0 and address invalid
	PrintMessage <COPE WITH ERROR HERE>
	;
	; Ask it for its address controller for this medium & transport option
	; 
		push	ds, si
		call	GeodeInfoDriver
		mov	di, DR_MBTD_GET_ADDRESS_CONTROLLER
		movdw	cxdx, es:[bp].MMT_medium
		mov	ax, es:[bp].MMT_transOption
		call	ds:[si].DIS_strategy
		pop	ds, si
		jcxz	unloadTransport		; => no address controller
						;  needed
		call	MSDCreateMAC
done:
		.leave
		ret

unloadTransport:
	;
	; No address controller needed, so don't need the transport driver
	; any more.
	; 
		call	MailboxFreeDriver
	;
	; If there's no address needed, we assume the user can send whenever
	; s/he wants to.
	; 
		mov	cx, TRUE
		mov	ax, MSG_MSD_SET_ADDRESS_VALID
		call	ObjCallInstanceNoLock
		jmp	done
MSDReplaceTransport endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDCreateMAC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and initialize the address control for the
		transport driver, now we know it needs one.

CALLED BY:	(INTERNAL) MSDReplaceTransport
PASS:		*ds:si	= MSD
		cx:dx	= MAC class
RETURN:		*ds:si	= MAC
DESTROYED:	ax, bx, cx, dx, di, bp, es
SIDE EFFECTS:	MSDI_curMAC set
     		MSCT_addrControl set if MSDI_transaction set
		address control added to dialog & set usable

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/19/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDCreateMAC	proc	near
		class	MailboxSendDialogClass
		.enter
	;
	; Instantiate the controller in our block.
	; 
		movdw	esdi, cxdx
		mov	cx, bx			; remember driver handle
		push	si
		mov	bx, ds:[LMBH_handle]
		call	ObjInstantiate
	;
	; Tell the controller who its driver is.
	; 
		mov	ax, MSG_MAILBOX_ADDRESS_CONTROL_SET_TRANSPORT_DRIVER
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Cope with transport hints.
	; 
		pop	di
		call	MSDPassTransportData
		movdw	cxdx, bxsi		; ^lcx:dx <- MAC
		mov	si, di			; *ds:si <- MSD
	;
	; Add it to the UI tree.  See if subclass wants to do something
	; special about this.
	;
		push	dx			; save MAC lptr
		mov	ax, MSG_MSD_ADD_ADDRESS_CONTROL
		call	ObjCallInstanceNoLock
		pop	dx			; *ds:dx = MAC
	;
	; Record the chunk in our instance data for later use.
	; 
		DerefDI	MailboxSendDialog
		mov	ds:[di].MSDI_curMAC, dx

	;
	; If we've got a current transaction, store the MAC in the transaction
	; chunk and add another reference to the MAC for the transaction.
	;
		xchg	si, dx			; *ds:si <- MAC
						; ^lcx:dx <- MSD (eventually)
		mov	di, ds:[di].MSDI_transaction
		tst	di
		jz	setValidAction

		mov	bx, ds:[OLMBH_output].handle
		call	ObjSwapLock
		mov	di, ds:[di]
		mov	ds:[di].MSCT_addrControl, si
		call	ObjSwapUnlock

		mov	ax, MSG_MAILBOX_ADDRESS_CONTROL_ADD_REF
		call	ObjCallInstanceNoLock
setValidAction:
	;
	; Tell it to tell us when the address is ready.
	; 
		mov	cx, ds:[LMBH_handle]
		mov	bp, MSG_MSD_SET_ADDRESS_VALID
		mov	ax, MSG_MAILBOX_ADDRESS_CONTROL_SET_VALID_ACTION
		call	ObjCallInstanceNoLock
	;
	; Set the thing usable, but delay the update by a queue length so our
	; caller has time to tell it what the medium is.
	; 
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjCallInstanceNoLock
		.leave
		ret
MSDCreateMAC	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDSetMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace our moniker with one built from the two strings
		we have on record.

CALLED BY:	(INTERNAL) MSDReplaceTransport, MSDSetContents
PASS:		*ds:si	= MailboxSendDialog object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDSetMoniker	proc	near
		class	MailboxSendDialogClass
		uses	es
		.enter
	;
	; Make sure we've got everything we need to build the moniker.
	; 
		DerefDI	MailboxSendDialog
		mov	bx, ds:[di].MSDI_lastTransStr
		tst	bx
		jz	done
		mov	cx, ds:[di].MSDI_lastContentStr
		jcxz	done
	;
	; Have both strings, so first store the transport string in a copy
	; of our template moniker.
	; 
		mov	ax, ds:[di].MSDI_titleMoniker
		Assert	chunk, ax, ds
		Assert	chunk, bx, ds
		call	UtilSetMonikerFromTemplate
	;
	; Now locate the \2 character and replace with \1 so we can use
	; the mangling code to store in the contents string.
	; 
		DerefDI	Gen
		mov	bx, cx			; *ds:bx <- contents string
						;  (for safekeeping)
		mov	di, ds:[di].GI_visMoniker
		segmov	es, ds
		mov	di, ds:[di]
		ChunkSizePtr ds, di, cx
		add	di, offset VM_data + offset VMT_text
		sub	cx, offset VM_data + offset VMT_text
DBCS <		shr	cx			; cx <- # chars		>
     		mov	ax, '\2'		; ax <- look for \2
		LocalFindChar
EC <		ERROR_NE	TITLE_MONIKER_MISSING_SECOND_PLACEHOLDER>
   		LocalPrevChar	esdi
		mov	ax, '\1'
		LocalPutChar	esdi, ax
	;
	; Now use the mangling code to store in the contents string
	; 
		mov_tr	ax, bx			; *ds:ax <- text to store
		call	UtilMangleMoniker
done:
		.leave
		ret
MSDSetMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDAddAddressControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the address control object to our dialog tree.

CALLED BY:	MSG_MSD_ADD_ADDRESS_CONTROL
PASS:		*ds:si	= MailboxSendDialogClass object
		^lcx:dx	= MailboxAddressControl object to add
RETURN:		nothing
DESTROYED:	ax, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/24/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDAddAddressControl	method dynamic MailboxSendDialogClass, 
					MSG_MSD_ADD_ADDRESS_CONTROL

	;
	; Add it as our first child.
	;
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, mask CCF_MARK_DIRTY or CCO_FIRST
	GOTO	ObjCallInstanceNoLock

MSDAddAddressControl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDSetContents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record what's to be sent in the body and update our UI
		accordingly

CALLED BY:	MSG_MSD_SET_CONTENTS
PASS:		*ds:si	= MailboxSendDialog object
		ds:di	= MailboxSendDialogInstance
		cx	= contents index
		dx	= MailboxObjectType
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDSetContents	method dynamic MailboxSendDialogClass, MSG_MSD_SET_CONTENTS
		uses	bp
		.enter
	;
	; Record the selected object type in the current transaction.
	;
		mov	bp, ds:[di].MSDI_transaction
		tst	bp
		jz	getString
		mov	bx, ds:[OLMBH_output].handle
		call	ObjSwapLock
		mov	bp, ds:[bp]
		mov	ds:[bp].MSCT_objType, dx
		call	ObjSwapUnlock

getString:
		push	cx		; save for setting selection
	;
	; Ask the MSC (the output for our block) for the string that
	; corresponds to the index.
	; 
		mov	dx, ds:[LMBH_handle]
		push	si
		movdw	bxsi, ds:[OLMBH_output]
		Assert	objectOD, bxsi, MailboxSendControlClass, FIXUP_DS
		mov	ax, MSG_MAILBOX_SEND_CONTROL_GET_CONTENTS_STRING
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	si
	;
	; Set the string and free the old one.
	; 
		DerefDI	MailboxSendDialog
		xchg	ds:[di].MSDI_lastContentStr, ax
		tst	ax
		jz	setMoniker
		call	LMemFree
setMoniker:
	;
	; Update our moniker.
	; 
		call	MSDSetMoniker
	;
	; Tell content list what it should have selected, in case this is
	; the first time we were called.
	; 
		pop	cx
if	_CAN_SELECT_CONTENTS
		clr	dx		; not indeterminate
		mov	si, offset MSCContentList
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		call	ObjCallInstanceNoLock
endif	; _CAN_SELECT_CONTENTS
		.leave
		ret
MSDSetContents	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDEnableDataObjectUi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add another set of UI for selecting the stuff to go in the
		message body.

CALLED BY:	MSG_MSD_ENABLE_DATA_OBJECT_UI
PASS:		*ds:si	= MailboxSendDialog object
		ds:di	= MailboxSendDialogInstance
		^lcx:dx	= root of additional data-object UI
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDEnableDataObjectUi method dynamic MailboxSendDialogClass, 
			MSG_MSD_ENABLE_DATA_OBJECT_UI
		.enter
	;
	; Now add the new root below the DataObjectUI interaction, which exists
	; so we can definitively place the data UI without having to worry about
	; whether there's an address controller around.
	; 
		mov	si, offset MSCDataObjectUI
		mov	ax, MSG_GEN_ADD_CHILD
		mov	bp, CCO_LAST or mask CCF_MARK_DIRTY
		call	ObjCallInstanceNoLock
	;
	; Set the new tree usable
	; 
		push	si
		movdw	bxsi, cxdx
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		pop	si
	;
	; Initial assumption is data ui are valid, for backward compatibility.
	;
		mov	cx, mask MSDVS_DATA_UI
		mov	ax, MSG_MSD_SET_VALID
		call	ObjCallInstanceNoLock

		.leave
		ret
MSDEnableDataObjectUi endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDResetDataObjectUi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove any UI added to the dialog via ENABLE_DATA_OBJECT_UI

CALLED BY:	MSG_MSD_RESET_DATA_OBJECT_UI
PASS:		*ds:si	= MailboxSendDialog object
		ds:di	= MailboxSendDialogInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Just send MSG_GEN_REMOVE to all the children of MSCDataObjectUI

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDResetDataObjectUi method dynamic MailboxSendDialogClass, 
				MSG_MSD_RESET_DATA_OBJECT_UI
		uses	bp
		.enter
		push	si
		mov	si, offset MSCDataObjectUI
		mov	ax, MSG_GEN_REMOVE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	bp, mask CCF_MARK_DIRTY
		call	GenSendToChildren
		pop	si
	;
	; Set the MSDVS_DATA_UI bit when we have no data ui.
	;
		mov	cx, mask MSDVS_DATA_UI
		mov	ax, MSG_MSD_SET_VALID
		call	ObjCallInstanceNoLock
		.leave
		ret
MSDResetDataObjectUi endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDSetAddressValid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record whether the address control is satisfied with the
		state of the address.

CALLED BY:	MSG_MSD_SET_ADDRESS_VALID
PASS:		*ds:si	= MailboxSendDialog object
		ds:di	= MailboxSendDialogInstance
		cx	= non-zero if address is valid
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDSetAddressValid method dynamic MailboxSendDialogClass, 
				MSG_MSD_SET_ADDRESS_VALID
		mov	ax, mask MSDVS_ADDRESS shl 8	; assume clearing...
		jcxz	setValid
		xchg	al, ah		; set the address-valid bit, don't
					;  clear it
setValid:
		mov_tr	cx, ax
		mov	ax, MSG_MSD_SET_VALID
		GOTO	ObjCallInstanceNoLock
MSDSetAddressValid endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDSetValid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the set of valid flags

CALLED BY:	MSG_MSD_SET_VALID
PASS:		*ds:si	= MailboxSendDialog object
		ds:di	= MailboxSendDialogInstance
		cl	= MSDValidState bits to set
		ch	= MSDValidState bits to clear
RETURN:		nothing
DESTROYED:	ax, cx
SIDE EFFECTS:	Send trigger enabled or disabled

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/24/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDSetValid	method dynamic MailboxSendDialogClass, MSG_MSD_SET_VALID
		.enter
	;
	; Clear the bits to be cleared, first.
	; 
		not	ch
		and	ds:[di].MSDI_validFlags, ch
	;
	; Set the bits to be set.
	; 
		or	ds:[di].MSDI_validFlags, cl
	;
	; If all bits are set, enable the trigger.
	; 
		mov	ax, MSG_GEN_SET_ENABLED
		cmp	ds:[di].MSDI_validFlags, mask MSDValidState
		je	enableDisable
		mov	ax, MSG_GEN_SET_NOT_ENABLED
enableDisable:
		push	dx, bp
		mov	dl, VUM_NOW
		mov	si, ds:[di].MSDI_sendTrigger
		call	ObjCallInstanceNoLock
		pop	dx, bp
		.leave
		ret
MSDSetValid	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDCreateTransaction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the fields of the passed transaction whose value
		we know, adding a reference to the address control

CALLED BY:	MSG_MSD_CREATE_TRANSACTION
PASS:		*ds:si	= MailboxSendDialog object
		ds:di	= MailboxSendDialogInstance
		*dx:bp	= MSCTransaction to fill in
RETURN:		MSCT_transport, MSCT_transOption, MSCT_addrControl set
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	fill in MSCT_transport + MSCT_transOption
 	if any current MAC:
		stuff current MAC in MSCT
		call MAC_ADD_REF on current MAC
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDCreateTransaction method dynamic MailboxSendDialogClass, 
				MSG_MSD_CREATE_TRANSACTION
		.enter
		mov	es, dx
		mov	bx, es:[bp]
	;
	; Store the transport and transOption in the transaction chunk.
	; 
		movdw	es:[bx].MSCT_transport, \
			ds:[di].MSDI_curTrans.MMT_transport, ax
		mov	ax, ds:[di].MSDI_curTrans.MMT_transOption
		mov	es:[bx].MSCT_transOption, ax

		mov	si, ds:[di].MSDI_curMAC
		mov	es:[bx].MSCT_addrControl, si
		tst	si
		jz	done
	;
	; Add a reference to the MAC to keep it around until the transaction
	; is complete.
	; 
		mov	ax, MSG_MAILBOX_ADDRESS_CONTROL_ADD_REF
		call	ObjCallInstanceNoLockES
done:
		.leave
		ret
MSDCreateTransaction endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDCreateBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare to create the body of the message. Fetch values
		from the data object UI the Mailbox library provides, and
		see if the address control wants to create the thing.

CALLED BY:	MSG_MSD_CREATE_BODY
PASS:		*ds:si	= MailboxSendDialog object
		ds:di	= MailboxSendDialogInstance
		*dx:bp	= MSCTransaction for which to create the body
		cx	= MailboxObjectType
RETURN:		carry set if address control is handling the creation
			ax	= TRUE if body creation isn't re-entrant
				= FALSE if body creation is re-entrant
		carry clear if address control not handling creation
			ax	= destroyed
DESTROYED:	dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/24/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDCreateBody	method dynamic MailboxSendDialogClass, MSG_MSD_CREATE_BODY
		.enter
	;
	; If the selected object type is MOT_PAGE_RANGE, fetch the start and
	; end into the transaction chunk.
	; 
		mov	es, dx			; *es:bp <- MSCTransaction

		cmp	cx, MOT_PAGE_RANGE
		je	checkCurrentPage
		
		mov	di, bp			; save trans chunk in di

		push	si, cx
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		mov	si, offset MSCPageRangeFrom
		call	ObjCallInstanceNoLockES
		mov	bx, dx			; save value for storing
		
		mov	si, offset MSCPageRangeTo
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		call	ObjCallInstanceNoLockES
		mov_tr	ax, bx			; ax <- start
		mov	bx, es:[di]
		mov	es:[bx].MSCT_objData.MSCOD_pageRange.MSCPRD_end, dx
		mov	es:[bx].MSCT_objData.MSCOD_pageRange.MSCPRD_start, ax
		pop	si, cx
		mov	bp, di			; *es:bp <- MSCTransaction again
		
		DerefDI	MailboxSendDialog
checkMAC:
	;
	; If there's an address controller, see if it wants to create the
	; message for us.
	;
		mov	si, ds:[di].MSDI_curMAC
		tst_clc	si
		jz	done
		
		mov	ax, MSG_MAILBOX_ADDRESS_CONTROL_CREATE_MESSAGE
		mov	dx, es
		call	ObjCallInstanceNoLockES
done:
		.leave
		ret

checkCurrentPage:
		cmp	cx, MOT_CURRENT_PAGE
		jne	checkMAC
		
		mov	ax, TEMP_MAILBOX_SEND_DIALOG_CURRENT_PAGE
		call	ObjVarFindData
EC <		WARNING_NC	I_DONT_KNOW_WHAT_THE_CURRENT_PAGE_IS	>
		mov	ax, 1
		jnc	recordCurrentPage
		mov	ax, ds:[bx]
recordCurrentPage:
		mov	bx, es:[bp]
		mov	es:[bx].MSCT_objData.MSCOD_pageRange.MSCPRD_end, ax
		mov	es:[bx].MSCT_objData.MSCOD_pageRange.MSCPRD_start, ax
		jmp	checkMAC
MSDCreateBody	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDRememberCurrentPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record what the current page is so MSDCreateBody can set
		that in the transaction object data should the need arise

CALLED BY:	MSG_MSD_REMEMBER_CURRENT_PAGE
PASS:		*ds:si	= MailboxSendDialog object
		ds:di	= MailboxSendDialogInstance
		dx	= current page
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	TEMP_MAILBOX_SEND_DIALOG_CURRENT_PAGE will be created or altered

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/13/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDRememberCurrentPage method dynamic MailboxSendDialogClass, 
				MSG_MSD_REMEMBER_CURRENT_PAGE
		.enter
		mov	cx, size word
		mov	ax, TEMP_MAILBOX_SEND_DIALOG_CURRENT_PAGE
		call	ObjVarAddData
		mov	ds:[bx], dx
		.leave
		ret
MSDRememberCurrentPage endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDGetAddresses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ask the address control for the current set of addresses.

CALLED BY:	MSG_MSD_GET_ADDRESSES
PASS:		*ds:si	= MailboxSendDialog object
		ds:di	= MailboxSendDialogInstance
		*dx:bp	= MSCTransaction chunk to fill in
RETURN:		carry set if addresses invalid
		carry clear if addresses ok:
			MSCT_addresses, MSCT_transData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/24/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDGetAddresses	method dynamic MailboxSendDialogClass, MSG_MSD_GET_ADDRESSES
		.enter
		mov	es, dx			; *es:bp <- transaction
	;
	; Disable the Send trigger to avoid multiple presses, whether or not
	; the address is valid.
	;
		mov	ax, ds:[di].MSDI_sendTrigger
		push	ax			; save Send trigger lptr
		push	si, bp
		mov_tr	si, ax			; *ds:si = Send trigger
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLockES
		pop	si, bp			; *ds:si = dialog, *es:bp =
						;  transaction
		DerefDI	MailboxSendDialog

		tst	ds:[di].MSDI_curMAC
		jnz	askMAC
	;
	; No address control, so generate a single, all-zero address of the max
	; significant address size (or 1 byte if all bytes are significant) so
	; the message has an address.
	; 
if	_OUTBOX_FEEDBACK
	;
	; Since we're making up the address, we know it's valid and can start
	; in with the feedback now.
	;
		call	MSDCreateFeedbackBox
endif	; _OUTBOX_FEEDBACK

		push	es:[LMBH_handle]
		call	MSDCreateDefaultAddress
		call	MemDerefStackES
		mov	bx, es:[bp]
		mov	es:[bx].MSCT_addresses, ax
		clr	ax				; (clears carry)
		mov	es:[bx].MSCT_addrControl, ax
		movdw	es:[bx].MSCT_transData, axax
maybeEnableSend:
	;
	; If address isn't valid, re-enable the Send trigger (because it was
	; enabled when we were invoked.)
	;
		pop	si			; *ds:si = Send trigger
		jnc	done

		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
		stc				; signal invalid addresses
done:
		.leave
		ret

askMAC:
	;
	; Have an address control, so we have to talk to it to get the various
	; parameters. Ask the controller to validate its addresses.
	;
if	_OUTBOX_FEEDBACK

		mov	bx, si			; *ds:bx <- MSD so we can
						;  create the feedback box

endif	; _OUTBOX_FEEDBACK

		mov	si, ds:[di].MSDI_curMAC
		push	bp
		mov	ax, MSG_MAILBOX_ADDRESS_CONTROL_VALIDATE_ADDRESSES
		call	ObjCallInstanceNoLockES
		pop	bp
		jc	maybeEnableSend

if	_OUTBOX_FEEDBACK
	;
	; Addresses are fine, so begin the feedback -- it's all downhill from
	; here; ain't no stoppin' us now.
	;
		xchg	bx, si			; *ds:si <- MSD, *ds:bx <- MAC
		call	MSDCreateFeedbackBox
		mov	si, bx			; *ds:si <- MAC
endif	; _OUTBOX_FEEDBACK

	; 
	; Fetch the transData from the address control and store that away.
	; 
		push	bp
		mov	ax, MSG_MAILBOX_ADDRESS_CONTROL_GET_TRANS_DATA
		call	ObjCallInstanceNoLockES
		pop	bp
		mov	bx, es:[bp]
		movdw	es:[bx].MSCT_transData, dxax
	;
	; Call the controller to get the array of addresses for the message.
	; 
		MovMsg	cxdx, dxax
		mov	ax, MSG_MAILBOX_ADDRESS_CONTROL_GET_ADDRESSES
		push	bp
		call	ObjCallInstanceNoLockES
		pop	bp

		tst	ax			; controller unhappy?
if	_OUTBOX_FEEDBACK
		jnz	haveAddresses
		call	MSDAbortFeedback
		jmp	maybeEnableSend
haveAddresses:
else
		stc				; assume yes
		jz	maybeEnableSend		; => yes, very pissed
endif	; _OUTBOX_FEEDBACK

	;
	; Stuff the handle of the address array into the transaction.
	; 
		mov	bx, es:[bp]
		mov	es:[bx].MSCT_addresses, ax

		Assert	ChunkArray, dsax
		clc
		jmp	maybeEnableSend
MSDGetAddresses	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDCreateFeedbackBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and put up the feedback flashing note for the user

CALLED BY:	(INTERNAL) MSDGetAddresses
PASS:		*es:bp	= MSCTransaction
		*ds:si	= MailboxSendDialog
		ds:di	= MailboxSendDialogInstance
RETURN:		ds:di	= MailboxSendDialogInstance
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Eventually this will need to ask the MAC for its string,
		tweak the text object, etc.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_OUTBOX_FEEDBACK
MSDCreateFeedbackBox proc	near
		class	MailboxSendDialogClass
		uses	bx, si
		.enter
	;
	; Ask the address control to build create the feedback box
	;
		mov	dx, es:[OLMBH_header].LMBH_handle    ; ^ldx:bp = MSCT
		push	si
		mov	si, ds:[di].MSDI_curMAC
		tst	si
		jz	directCall		; => no address control
		mov	ax, MSG_MAILBOX_ADDRESS_CONTROL_CREATE_FEEDBACK
		call	ObjCallInstanceNoLockES
		jmp	afterCall
directCall:
	;
	; No address control.  Use our default feedback box.
	;
		push	dx			; for fix-up transaction
		call	MACCreateFeedback
		call	MemDerefStackES
afterCall:
		pop	si
	;
	; If no feedback box, we are done.
	;
		mov	bx, es:[bp]
		mov	cx, es:[bx].MSCT_feedback.handle
		jcxz	done			; => no feedback
		push	si			; save dialog lptr
		push	es:[bx].MSCT_feedback.chunk
	;
	; Let it know the message summary, if we've got it already.
	;
		tst	es:[bx].MSCT_summary
		jz	bringOnScreen

		push	ds:[LMBH_handle]	; save for fixup of DS
		segmov	ds, es			; ds:bx <- transaction
		call	MSCNotifyFeedbackOfSummary
		segmov	es, ds			; es <- trans segment
		call	MemDerefStackDS		; reload DS
bringOnScreen:
		mov	bx, cx
		pop	si			; ^lbx:si = feedback box
		push	bp			; save transaction again
	;
	; Bring it on-screen.
	;
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
		call	ObjMessage
		pop	bp
		pop	dx
	;
	; Tell it the dialog to remove when it comes down.
	;
		mov	cx, ds:[LMBH_handle]	; ^lcx:dx = dialog
		mov	ax, MSG_OFN_SET_DIALOG
		mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
		call	ObjMessage
		mov	si, es:[bp]
	;
	; Flag that bringing the dialog down will be handled (well, we're
	; claiming it has been handled, which is wrong, but the effect is the
	; same, since when the feedback box comes down, we'll be brought
	; down, too)
	;
		ornf	es:[si].MSCT_flags, mask MSCTF_DIALOG_COMPLETE
done:
		.leave
		DerefDI	MailboxSendDialog
		ret
MSDCreateFeedbackBox endp
endif	; _OUTBOX_FEEDBACK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDAbortFeedback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force down the feedback box -- the message isn't getting 
		registered after all

CALLED BY:	(INTERNAL) MSDGetAddresses
PASS:		*es:bp	= MSCTransaction
RETURN:		carry set
DESTROYED:	nothing
SIDE EFFECTS:	OFN_SET_MESSAGE is sent to the feedback box passing a 0
     			message.
		es:bp->MSCT_feedback.handle is set to 0

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_OUTBOX_FEEDBACK
MSDAbortFeedback proc	near
		class	MailboxSendDialogClass
		uses	bx, si, ax, di, cx, dx
		.enter
		mov	si, es:[bp]
		clr	bx, cx, dx
		xchg	bx, es:[si].MSCT_feedback.handle
		mov	si, es:[si].MSCT_feedback.chunk
		mov	ax, MSG_OFN_SET_MESSAGE
		mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
		call	ObjMessage
		stc
		.leave
		ret
MSDAbortFeedback endp
endif	; _OUTBOX_FEEDBACK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDCreateDefaultAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a chunk array with a single default address for the
		selected transport.

CALLED BY:	(INTERNAL) MSDCreateTransaction
PASS:		ds:di	= MailboxSendDialogInstance
RETURN:		*ds:ax	= array of a single address
DESTROYED:	bx, cx, dx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDCreateDefaultAddress proc	near
		class	MailboxSendDialogClass
		.enter
	;
	; Ask the Media module for the number of significant bytes in
	; an address for this combination.
	; 
		movdw	axbx, ds:[di].MSDI_curTrans.MMT_transport
		movdw	cxdx, ds:[di].MSDI_curTrans.MMT_medium
		mov	si, ds:[di].MSDI_curTrans.MMT_transOption
		call	MediaGetTransportSigAddrBytes
EC <		ERROR_C	HOW_CAN_MEDIA_TRANSPORT_BE_INVALID?		>
	;
	; If driver says everything's significant, use only 1 byte, else
	; use as many as are significant.
	; 
		cmp	ax, MBTD_ALL_BYTES_SIGNIFICANT
		jne	haveNumBytes
		mov	ax, 1
haveNumBytes:
		call	MACCreateDefaultAddress
		.leave
		ret
MSDCreateDefaultAddress endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDTransactionComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note that a transaction is complete and free the
		resources allocated for it.

CALLED BY:	MSG_MSD_TRANSACTION_COMPLETE
PASS:		*ds:si	= MailboxSendDialog object
		ds:di	= MailboxSendDialogInstance
		*dx:bp	= MSCTransaction that's complete
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDTransactionComplete method dynamic MailboxSendDialogClass, 
				MSG_MSD_TRANSACTION_COMPLETE
		.enter
		mov	ax, MSG_MAILBOX_ADDRESS_CONTROL_MESSAGE_REGISTERED
		call	MSDCleanupTransaction
		.leave
		ret
MSDTransactionComplete endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDCancelTransaction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note that a transaction has been canceled and free the
		resources allocated for it.

CALLED BY:	MSG_MSD_CANCEL_TRANSACTION
PASS:		*ds:si	= MailboxSendDialog object
		ds:di	= MailboxSendDialogInstance
		*dx:bp	= MSCTransaction that's been canceled
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDCancelTransaction method dynamic MailboxSendDialogClass, 
				MSG_MSD_CANCEL_TRANSACTION
		.enter
		mov	ax, MSG_MAILBOX_ADDRESS_CONTROL_MESSAGE_CANCELED
		call	MSDCleanupTransaction
		.leave
		ret
MSDCancelTransaction endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDCleanupTransaction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cleans up resources we allocated in initializing the 
		transaction

CALLED BY:	(INTERNAL) MSDCancelTransaction, MSDTransactionComplete
PASS:		*ds:si	= MailboxSendDialog object
		ds:di	= MailboxSendDialogInstance
		*dx:bp	= MSCTransaction
		ax	= message to send to the address control, if any
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, es
SIDE EFFECTS:	addresses are freed, address controller may be freed (loses
     			one reference in any case)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDCleanupTransaction proc	near
		class	MailboxSendDialogClass
		uses	si
		.enter
	;
	; Zero our MSDI_transaction field if the transaction just finished is
	; the one we have on record. This keeps us from removing a non-existent
	; extra reference from the current MAC when we switch transports after
	; having been initiated.
	;
		cmp	ds:[di].MSDI_transaction, bp
		jne	checkAddrCtrl
		mov	ds:[di].MSDI_transaction, 0

checkAddrCtrl:
		mov	es, dx
		mov	bx, es:[bp]
		tst	es:[bx].MSCT_addrControl
		jz	nukeArray
	;
	; Since there was an address control involved, we need to let it know
	; what's happened so it can clean up its transData, if it wants
	; 
		push	bp, si
		movdw	cxdx, es:[bx].MSCT_transData
		mov	si, es:[bx].MSCT_addrControl
		call	ObjCallInstanceNoLockES
		pop	bp, si

nukeArray:
	;
	; If any address array allocated, free it.
	; 
		mov	ax, es:[bx].MSCT_addresses
		tst	ax
		jz	nukeMAC
		call	LMemFree

nukeMAC:
	;
	; If any address controller involved, remove one reference from it.
	; 
		mov	si, es:[bx].MSCT_addrControl
		tst	si
		jz	done
		
		mov	ax, MSG_MAILBOX_ADDRESS_CONTROL_DEL_REF
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
MSDCleanupTransaction endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDGenRemove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure our current address controller is shut down before
		we allow ourselves to go away.

CALLED BY:	MSG_GEN_REMOVE
PASS:		*ds:si	= MailboxSendDialog object
		ds:di	= MailboxSendDialogInstance
		dl	= VisUpdateMode
		bp	= CompChildFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDGenRemove	method dynamic MailboxSendDialogClass, MSG_GEN_REMOVE
		call	MSDNukeMAC
		mov	di, offset MailboxSendDialogClass
		GOTO	ObjCallSuperNoLock
MSDGenRemove	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDPageRangeBoundsAdjusted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look at the current page range bounds and tweak the AllFromList
		appropriately

CALLED BY:	MSG_MSD_PAGE_RANGE_BOUNDS_ADJUSTED
PASS:		*ds:si	= MailboxSendDialog object
		ds:di	= MailboxSendDialogInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/30/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDPageRangeBoundsAdjusted method dynamic MailboxSendDialogClass, MSG_MSD_PAGE_RANGE_BOUNDS_ADJUSTED
		.enter
	;
	; See if From is at the start
	;
		mov	si, offset MSCPageRangeFrom
		mov	ax, MSG_GEN_VALUE_GET_MINIMUM
		call	checkValue
		jne	doFrom
	;
	; It is. See if To is at the end.
	;
		mov	si, offset MSCPageRangeTo
		mov	ax, MSG_GEN_VALUE_GET_MAXIMUM
		call	checkValue
		mov	cx, MSDRT_ALL_PAGES	; assume it is
		je	setList			; => it is
doFrom:
		mov	cx, MSDRT_PAGE_RANGE	; else select From
setList:
	;
	; Set the All/From list appropriately.
	;
	; cx = identifier to select.
	;
		mov	si, offset MSCPageAllFromList
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	dx			; nothing indeterminate about it
		call	ObjCallInstanceNoLock
		.leave
		ret

	;--------------------
	; See if the given GenValue is at the given level
	;
	; Pass:	ax	= MSG_GEN_VALUE_GET_MINIMUM/MSG_GEN_VALUE_GET_MAXIMUM
	; 	*ds:si	= GenValue to check
	; Return:	jne if not at the min/max
	; 
checkValue:
		call	ObjCallInstanceNoLock
		mov	bx, dx
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		call	ObjCallInstanceNoLock
		cmp	bx, dx
		retn
MSDPageRangeBoundsAdjusted endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDAdjustAllOrFrom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the GenValues for the page range based on the
		selection

CALLED BY:	MSG_MSD_ADJUST_ALL_OR_FROM
PASS:		*ds:si	= MailboxSendDialog object
		ds:di	= MailboxSendDialogInstance
		cx	= MSDRangeType
		dx	= # selections
		bp	= GenItemGroupStateFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/30/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDAdjustAllOrFrom method dynamic MailboxSendDialogClass, MSG_MSD_ADJUST_ALL_OR_FROM
		.enter
		cmp	cx, MSDRT_ALL_PAGES
		jne	done
	;
	; When change to All, adjust the GenValues to their limits.
	;
		mov	ax, MSG_GEN_VALUE_GET_MINIMUM
		mov	si, offset MSCPageRangeFrom
		call	adjustValue
		
		mov	ax, MSG_GEN_VALUE_GET_MAXIMUM
		mov	si, offset MSCPageRangeTo
		call	adjustValue

done:
		.leave
		ret
	;--------------------
	; Adjust a GenValue to one of its limits
	;
	; Pass:	ax 	= MSG_GEN_VALUE_GET_MINIMUM/MSG_GEN_VALUE_GET_MAXIMUM
	; 	*ds:si	= GenValue to adjust
	; Return:	nothing
	; 
adjustValue:
		call	ObjCallInstanceNoLock
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		clr	bp
		call	ObjCallInstanceNoLock
		retn
MSDAdjustAllOrFrom endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDSetAddresses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the current addresses of this send dialog to be the
		address stored in the passed message.

CALLED BY:	MSG_MSD_SET_ADDRESSES
PASS:		*ds:si	= MailboxSendDialogClass object
		ds:di	= MailboxSendDialogClass instance data
		ds:bx	= MailboxSendDialogClass object (same as *ds:si)
		es 	= segment of MailboxSendDialogClass
		ax	= message #
		cxdx	= MailboxMessage
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	2/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDSetAddresses	method dynamic MailboxSendDialogClass, 
					MSG_MSD_SET_ADDRESSES
mitaArray	local	lptr.ChunkArrayHeader
mitaIndex	local	word
mbacaArray	local	lptr.ChunkArrayHeader
	.enter

	;
	; If no address controller, we assume the address is the default
	; one and no address needs to be stored.
	;
	mov	ax, ds:[di].MSDI_curMAC
	tst	ax
	LONG jz	done
	push	ax			; save addr control lptr for call

	;
	; Create an array for MBACAddress structures.
	;
	segmov	es, ds			; es = ds = object block
	push	cx			; save MailboxMessage.high
	clr	bx, cx, si
	mov	ss:[mitaIndex], bx	; init index to 0
	mov	al, bl
	call	ChunkArrayCreate	; *ds:si = MBACAddress array, es fixed
	mov	ss:[mbacaArray], si

	;
	; Lock the message
	;
	pop	cx			; cxdx = MailboxMessage
	call	MessageLockCXDX		; *ds:di = MailboxMessage
	mov	di, ds:[di]
	mov	si, ds:[di].MMD_transAddrs
	mov	ss:[mitaArray], si
EC <	call	ChunkArrayGetCount	; cx = count			>
EC <	Assert	ne, cx, 0						>
	; In non-ec, we don't check for zero-address here, since in theory
	; the send control shouldn't be sending us this message if there's
	; no address.
EC <	cmp	cx, 1							>
EC <	WARNING_NE MESSAGE_TO_REPLY_TO_DOESNT_HAVE_EXACTLY_ONE_ADDR	>

nextAddr:
	;
	; Get one MailboxInternalTransAddr.
	;
	mov	si, ss:[mitaArray]
	mov	ax, ss:[mitaIndex]
	call	ChunkArrayElementToPtr	; ds:di = MITA, cx = size
	jc	endOfArray
	pushdw	dsdi			; save MITA	

	;
	; Append one SACAddress.
	;
	segmov	ds, es
	mov	si, ss:[mbacaArray]	; *ds:si = MBACAddress array
	mov	ax, cx
	add	ax, size MBACAddress - size MailboxInternalTransAddr
					; ax = size for this MBACAddress entry
	call	ChunkArrayAppend	; ds:di = es:di = MBACAddress
	popdw	dssi			; ds:si = MailboxInternalTransAddr

	;
	; Copy opaque and user-readable addrs.
	;
	sub	cx, size MailboxInternalTransAddr
					; cx = size of opaque and user-readable
					;  addrs
	mov	ax, ds:[si].MITA_opaqueLen
		CheckHack <MBACA_opaqueSize eq 0>
		CheckHack <size MBACA_opaqueSize eq size word>
	stosw				; store MBACA_opaqueSize
		CheckHack <MBACA_opaqueSize + size MBACA_opaqueSize \
			eq MBACA_opaque>	; es:di = MBACA_opaque
	add	si, offset MITA_opaque	; ds:si = MITA_opaque
	rep	movsb

	inc	ss:[mitaIndex]
	jmp	nextAddr

endOfArray:
	call	UtilVMUnlockDS		; unlock message
	segmov	ds, es
	pop	si			; *ds:si = address control
	mov	ax, MSG_MAILBOX_ADDRESS_CONTROL_SET_ADDRESSES
	mov	cx, ds:[OLMBH_header].LMBH_handle
	mov	dx, ss:[mbacaArray]	; ^lcx:dx = MBACAddress array
	push	dx, bp			; save array lptr and frame ptr
	call	ObjCallInstanceNoLock
	pop	ax, bp			; *ds:ax = MBACAddress array
	call	LMemFree		; free MBACAddress array
done:
	.leave
	ret
MSDSetAddresses	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDSetAddressesWithTransport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the current addresses of this send dialog to be the
		pass addresses, if the passed transport + option match the
		ones we're using in the dialog.

CALLED BY:	MSG_MSD_SET_ADDRESSES_WITH_TRANSPORT
PASS:		ds:di	= MailboxSendDialogClass instance data
		ss:bp	= MSDSetAddressesWithTransportArgs
RETURN:		carry set if the dialog is for a different transport + option
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	2/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDSetAddressesWithTransport	method dynamic MailboxSendDialogClass, 
					MSG_MSD_SET_ADDRESSES_WITH_TRANSPORT
	uses	bp
	.enter

	Assert	stackFrame, bp
EC <	tstdw	ss:[bp].MSDSAWTA_addresses				>
EC <	jz	notOptr							>
EC <	Assert	optr, ss:[bp].MSDSAWTA_addresses			>
EC <notOptr:								>

	;
	; If we don't have a MAC there is no need to set the addresses.
	;
	mov	si, ds:[di].MSDI_curMAC		
	tst	si
	jz	done

	;
	; Return carry set if passed transport + option don't match ours.
	;
	cmpdw	ss:[bp].MSDSAWTA_transAndOption.MTAO_transport, \
			ds:[di].MSDI_curTrans.MMT_transport, ax
	stc
	jne	done
	mov	ax, ss:[bp].MSDSAWTA_transAndOption.MTAO_transOption
	cmp	ax, ds:[di].MSDI_curTrans.MMT_transOption
	stc
	jne	done

	;
	; Pass MBACAddress array to address control.
	;
	mov	ax, MSG_MAILBOX_ADDRESS_CONTROL_SET_ADDRESSES
	movdw	cxdx, ss:[bp].MSDSAWTA_addresses ; ^lcx:dx = MBACAddress array
	call	ObjCallInstanceNoLock
	clc				; return transport match

done:
	.leave
	ret
MSDSetAddressesWithTransport	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDGenInteractionInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a transaction chunk and begin body creation, if
		necessary and possible

CALLED BY:	MSG_GEN_INTERACTION_INITIATE
PASS:		*ds:si	= MailboxSendDialog object
		ds:di	= MailboxSendDialogInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/25/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDGenInteractionInitiate method dynamic MailboxSendDialogClass, 
				MSG_GEN_INTERACTION_INITIATE
		uses	si
		.enter
		mov	di, si
		call	MSDGetSendControl
		jnc	toSuper
		
		push	di
		mov	ax, MSG_MAILBOX_SEND_CONTROL_CREATE_TRANSACTION
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		mov	bp, si
		pop	si
		DerefDI	MailboxSendDialog
		mov	ds:[di].MSDI_transaction, ax

ife 	_CAN_SELECT_CONTENTS
	;
	; See if the transport driver wishes to receive the message body
	; early.
	;
		movdw	cxdx, ds:[di].MSDI_curTrans.MMT_transport
		call	AdminGetTransportDriverMap
		call	DMapGetAttributes
EC <		ERROR_C	HOW_CAN_TRANSPORT_DRIVER_BE_INVALID?		>
		test	ax, mask MBTC_NEED_MESSAGE_BODY
		jz	toSuper
	;
	; It does. Ask the send control to create the body.
	;
	; 12/1/95: we force-queue this message so we have a chance to be
	; initiated before an error loading the transport driver causes
	; us to be canceled. -- ardeb
	;
		mov	si, bp
		mov	bp, ds:[di].MSDI_transaction
		mov	ax, MSG_MAILBOX_SEND_CONTROL_CREATE_BODY
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
endif	; !_CAN_SELECT_CONTENTS
toSuper:
		.leave
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, offset MailboxSendDialogClass
		GOTO	ObjCallSuperNoLock
MSDGenInteractionInitiate endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDCancel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cancel the transaction

CALLED BY:	MSG_MSD_CANCEL
PASS:		*ds:si	= MailboxSendDialog object
		ds:di	= MailboxSendDialogInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	MSDI_transaction set to 0

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/25/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDCancel	method dynamic MailboxSendDialogClass, MSG_MSD_CANCEL
		.enter
		tst	ds:[di].MSDI_transaction
		jz	done
		
		call	MSDGetSendControl
		clr	bp, dx		; dx <- 0, notify user
		xchg	bp, ds:[di].MSDI_transaction
		mov	ax, MSG_MAILBOX_SEND_CONTROL_CANCEL_MESSAGE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
done:
		.leave
		ret
MSDCancel	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset transparent detach bit in application.

CALLED BY:	MSG_VIS_CLOSE
PASS:		*ds:si	= MailboxSendDialogClass object
		ds:di	= MailboxSendDialogClass instance data
		ds:bx	= MailboxSendDialogClass object (same as *ds:si)
		es 	= segment of MailboxSendDialogClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	9/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDDetachOrQuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cancel the transaction if it's active.

CALLED BY:	MSG_META_DETACH, MSG_META_QUIT
PASS:		*ds:si	= MailboxSendDialog object
		ds:di	= MailboxSendDialogInstance
		stuff
RETURN:		nothing
DESTROYED:	?
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/11/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDDetachOrQuit	method dynamic MailboxSendDialogClass, MSG_META_DETACH,
					MSG_META_QUIT
		uses	ax, cx, dx, bp
		.enter
		mov	ax, MSG_MSD_CANCEL
		call	ObjCallInstanceNoLock
		.leave
		mov	di, offset MailboxSendDialogClass
		GOTO	ObjCallSuperNoLock
MSDDetachOrQuit	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDMetaBringUpHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	bring up help for transport driver, if any

CALLED BY:	MSG_META_BRING_UP_HELP
PASS:		*ds:si	= MailboxSendDialogClass object
		ds:di	= MailboxSendDialogClass instance data
		ds:bx	= MailboxSendDialogClass object (same as *ds:si)
		es 	= segment of MailboxSendDialogClass
		ax	= message #
RETURN:		nothing
DESTROYED:	bx, si, di, es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/13/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SendControlCode	ends

