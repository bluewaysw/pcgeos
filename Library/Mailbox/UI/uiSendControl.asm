COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Mailbox
MODULE:		UI
FILE:		uiSendControl.asm

AUTHOR:		Allen Yuen, Jun 16, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	6/16/94   	Initial revision


DESCRIPTION:
	Implementation of the MailboxSendControlClss
		

	$Id: uiSendControl.asm,v 1.1 97/04/05 01:19:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MailboxClassStructures	segment	resource

	MailboxSendControlClass

MailboxClassStructures	ends


SendControlCode	segment	resource

SendControlCodeDerefGen proc near
	class	GenClass
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ret
SendControlCodeDerefGen endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCGenControlGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the GenControlbuildInfo for this controller

CALLED BY:	GLOBAL (MSG_GEN_CONTROL_GET_INFO)

PASS:		*DS:SI	= MailboxSendControl object
		DS:DI	= MailboxSendControlInstance
		CX:DX	= GenControlBuildInfo buffer

RETURN:		CX:DX	= GenControlBildInfo buffer filled

DESTROYED:	CX

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MSCGenControlGetInfo	method dynamic	MailboxSendControlClass,
					MSG_GEN_CONTROL_GET_INFO
		.enter
	;
	; Copy the information from our structure to the buffer
	;
		push	ds, si
		movdw	esdi, cxdx
		segmov	ds, cs
		mov	si, offset MSCBuildInfo
	CheckHack <(size MSCBuildInfo and 1) eq 0>
		mov	cx, size MSCBuildInfo / 2
		rep	movsw
		pop	ds, si
	;
	; If the controller has been duplicated or instantiated, then do
	; the active list thing automatically, not manually. We only do the
	; manual thing when the object should have been on it from the start.
	;
	; 5/22/95: also don't insist on being always on the GCN lists when
	; duplicated or instantiated, on the assumption that the thing doesn't
	; live long enough... or something -- ardeb
	;
		test	ds:[LMBH_flags], mask LMF_DUPLICATED
		jnz	noManualActiveList
		
		mov	ax, si
		call	ObjGetFlags
		test	al, mask OCF_IN_RESOURCE
		jnz	done
noManualActiveList:
		mov	di, dx
		andnf	es:[di].GCBI_flags, 
			not (mask GCBF_MANUALLY_REMOVE_FROM_ACTIVE_LIST or \
			     mask GCBF_ALWAYS_ON_GCN_LIST or \
			     mask GCBF_IS_ON_ACTIVE_LIST)
done:
		.leave
		ret
MSCGenControlGetInfo	endm

MSCBuildInfo	GenControlBuildInfo <
		mask GCBF_MANUALLY_REMOVE_FROM_ACTIVE_LIST or
		mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST or
		mask GCBF_IS_ON_ACTIVE_LIST or
		mask GCBF_ALWAYS_ON_GCN_LIST,
		MSC_iniKey,			; GCBI_initFileKey
		MSC_gcnList,			; GCBI_gcnList
		length MSC_gcnList,		; GCBI_gcnCount
		0,				; GCBI_notificationList
		0,				; GCBI_notificationCount
		MSCName,			; GCBI_controllerName

		handle SendControlUI,		; GCBI_dupBlock
		MSC_childList,			; GCBI_childList
		length MSC_childList,		; GCBI_childCount
		MSC_featuresList,		; GCBI_featuresList
		length MSC_featuresList,	; GCBI_featuresCount
		MSC_DEFAULT_FEATURES,		; GCBI_features

		handle SendControlToolboxUI,	; GCBI_toolBlock
		MSC_toolList,			; GCBI_toolList
		length MSC_toolList,		; GCBI_toolCount
		MSC_toolFeaturesList,		; GCBI_toolFeaturesList
		length MSC_toolFeaturesList,	; GCBI_toolFeaturesCount
		MSC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_toolFeatures
		MSC_helpContext,		; GCBI_helpContext
		0>				; GCBI_reserved

if _FXIP
ControlInfoXIP	segment	resource
endif

MSC_iniKey		char	"mailboxSendControl", 0

MSC_gcnList		GCNListType \
			<MANUFACTURER_ID_GEOWORKS, \
				GAGCNLT_MAILBOX_SEND_CONTROL>

MSC_ALWAYS_KIDS	equ	<>

if	_POOF_MESSAGE_CREATION

MSC_childList		GenControlChildInfo MSC_ALWAYS_KIDS \
			<offset MSCTransportMenu,
				mask MSCF_TRANSPORT_LIST,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset MSCPoofMenu,
				mask MSCF_POOF_LIST,
				mask GCCF_IS_DIRECTLY_A_FEATURE>

MSC_featuresList	GenControlFeaturesInfo \
			<offset MSCTransportMenu, MSCTransportMenuName, 0>,
			<offset MSCPoofMenu, MSCPoofMenuName, 0>

else

MSC_childList		GenControlChildInfo MSC_ALWAYS_KIDS \
			<offset MSCTransportMenu,
				mask MSCF_TRANSPORT_LIST,
				mask GCCF_IS_DIRECTLY_A_FEATURE>

MSC_featuresList	GenControlFeaturesInfo \
			<offset MSCTransportMenu, MSCTransportMenuName, 0>

endif	; _POOF_MESSAGE_CREATION

MSC_toolList		GenControlChildInfo \
			<offset MSCToolMenu, mask MSCTF_SEND_DIALOG,
				mask GCCF_IS_DIRECTLY_A_FEATURE>

MSC_toolFeaturesList	GenControlFeaturesInfo \
			<offset MSCToolMenu, MSCToolTriggerName, 0>

MSC_helpContext		char	"dbSendCtrl", 0

if _FXIP
ControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCMetaAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform requisite operations at startup, most notably
		ripping the PrintControl from its cherished position in the
		File menu, if it's there

CALLED BY:	MSG_META_ATTACH
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
		cx	= AppAttachFlags
		dx	= handle of AppLaunchBlock
		bp	= handle of extra state block
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	guess

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/28/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCMetaAttach	method dynamic MailboxSendControlClass, MSG_META_ATTACH
		uses	es, ax, cx
		.enter
		segmov	es, cs
		mov	di, offset attachScanHandlers
		mov	ax, length attachScanHandlers
		mov	cx, TRUE
		call	ObjVarScanData
		.leave
		
		mov	di, offset MailboxSendControlClass
		GOTO	ObjCallSuperNoLock
MSCMetaAttach	endm

attachScanHandlers	VarDataHandler \
	<ATTR_MAILBOX_SEND_CONTROL_TRANSPORT_HINT, MSCProcessTransportHint>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCProcessTransportHint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the given hint is for the spool transport driver
		and remove the print control object that's pointed to by
		it, if it is.

CALLED BY:	(INTERNAL) MSCMetaAttach via ObjVarScanData
PASS:		*ds:si	= MailboxSendControl
		ds:bx	= MailboxTransportAndOption in the hint
		cx	= 0 if already found the print control
			= non-z if not yet seen hint for transport that
			  uses the print control
		ax	= ATTR_MAILBOX_SEND_CONTROL_TRANSPORT_HINT
RETURN:		nothing
DESTROYED:	bx, si, ax, di
SIDE EFFECTS:	PrintControl pointed to by the spooler transport hint is
		removed from the generic tree, pending reattachment to
		MailboxSpoolAddressControl object

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/28/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCProcessTransportHint proc	far
		.enter
		jcxz	done
	;
	; See if it's a hint for the spooler.
	;
		CmpTok	ds:[bx].MTAO_transport, MANUFACTURER_ID_GEOWORKS, \
				GMTID_PRINT_SPOOLER, checkFax
		tst	ds:[bx].MTAO_transOption
		jnz	checkFax
haveHint:
		clr	cx
	;
	; It is. Relocate the PrintControl optr, please.
	; 
		push	cx, dx, bp
		movdw	cxdx, ds:[bx+MailboxTransportAndOption].MSTH_pc
		mov	bx, ds:[LMBH_handle]
		mov	al, RELOC_HANDLE
		call	ObjDoRelocation
	;
	; Now call the thing to tell it to remove itself from the tree; it'll
	; get added in at the appropriate time when the user tries to print.
	; 
		movdw	bxsi, cxdx
		mov	ax, MSG_GEN_REMOVE
		mov	dl, VUM_NOW
		mov	bp, mask CCF_MARK_DIRTY
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	cx, dx, bp
done:
		.leave
		ret

checkFax:
	;
	; Allow fax-only apps by looking for hint for fax
	;
		CmpTok	ds:[bx].MTAO_transport, MANUFACTURER_ID_GEOWORKS, \
				GMTID_FAX_SEND, done
		tst	ds:[bx].MTAO_transOption
		jnz	done
		jmp	haveHint
MSCProcessTransportHint endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCGenControlRemoveFromGcnLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure our kids are removed from all the GCN lists on the
		mailbox application object

CALLED BY:	MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS
		MSG_GEN_CONTROL_DESTROY_UI
		MSG_GEN_CONTROL_DESTROY_TOOLBOX_UI
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCGenControlRemoveFromGCNLists method dynamic MailboxSendControlClass, 
				MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS,
				MSG_GEN_CONTROL_DESTROY_UI,
				MSG_GEN_CONTROL_DESTROY_TOOLBOX_UI
	;
	; REMOVE_FROM_GCN_LISTS is when we know we're no longer interactible
	; and want to destroy the dialog if we can (as we won't get a
	; META_DETACH once we're off the active list).
	; 
		cmp	ax, MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS
		jne	doKids
		call	MSCNukeDialogIfPossible
doKids:
	;
	; Remove the kids and ourselves from all the GCN lists they might
	; be on, on both potential app objects.
	; 
		call	MSCRemoveKidsFromAllLists
	;
	; Let the superclass work its will.
	; 
		mov	di, offset MailboxSendControlClass
		GOTO	ObjCallSuperNoLock
MSCGenControlRemoveFromGCNLists endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCRemoveKidsFromAllLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure we and our children and our dialog box are off
		the various GCN lists in the current app and in the mailbox
		app.

CALLED BY:	(INTERNAL) MSCGenControlRemoveFromGCNLists,
			   MSCMetaDetach
PASS:		*ds:si	= MailboxSendControl object
RETURN:		nothing
DESTROYED:	bx, di
SIDE EFFECTS:	guess

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 4/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCRemoveKidsFromAllLists proc	near
		uses	ax, cx, dx, bp
		class	MailboxSendControlClass
		.enter
		mov	ax, MSG_META_GCN_LIST_REMOVE
		call	MSCCopeWithPageRangeGCN

		call	MSCGetChildBlockAndFeatures
		jc	checkDialog
		call	MSCRemoveFromAllLists

checkDialog:
		call	MSCGetDialogBlock
		call	MSCRemoveFromAllLists
		.leave
		ret
MSCRemoveKidsFromAllLists endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCMetaDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prevent detach if there are still transactions in progress

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
		cx	= detach ID
		^ldx:bp	= ack OD
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 4/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCMetaDetach	method dynamic MailboxSendControlClass, MSG_META_DETACH
		.enter
	;
	; Prepare for detach, storing away the detach params
	; 
		call	ObjInitDetach
	;
	; If there are any transactions still pending, up the detach count
	; by one, which will be removed when there are no more transactions
	; around.
	; 
		call	MSCNukeDialogIfPossible
		jc	doGCNStuff
		call	ObjIncDetach
doGCNStuff:
	;
	; Remove the dialog, children, and ourselves from any and all GCN
	; lists we might be on.
	; 
		call	MSCRemoveKidsFromAllLists
	;
	; Give our superclass a shot
	; 
		mov	di, offset MailboxSendControlClass
		call	ObjCallSuperNoLock
	;
	; Allow detach to complete. This may send us a META_DETACH_COMPLETE
	; during the call, which cause us to destroy any dialog we've got.
	; 
		call	ObjEnableDetach
		.leave
		ret
MSCMetaDetach	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCMetaDetachComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the dialog block, if it's around.

CALLED BY:	MSG_META_DETACH_COMPLETE
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
RETURN:		nothing
DESTROYED:	?
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 4/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCMetaDetachComplete method dynamic MailboxSendControlClass, 
				MSG_META_DETACH_COMPLETE
	;
	; Finally destroy the dialog block.
	;
		call	MSCNukeDialog

		mov	ax, MSG_META_DETACH_COMPLETE
		mov	di, offset MailboxSendControlClass
		GOTO	ObjCallSuperNoLock
MSCMetaDetachComplete endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCNukeDialogIfPossible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If there are no pending transactions, destroy any companion
		dialog we've got. Else flag the dialog as needing destruction.

CALLED BY:	(INTERNAL) MSCGenControlRemoveFromGCNLists,
			   MSCMetaDetach
PASS:		*ds:si	= MailboxSendControl object
RETURN:		carry set if dialog destroyed
		carry clear if dialog couldn't be nuked yet
DESTROYED:	nothing
SIDE EFFECTS:	either dialog is biffed or TEMP_MAILBOX_SEND_CONTROL_DESTROY_-
		DIALOG_PENDING is set on the object

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 4/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCNukeDialogIfPossible proc	near
		uses	bx
		class	MailboxSendControlClass
		.enter
	;
	; If there are no pending transactions, destroy the dialog.
	; Note that if the dialog is on-screen, it should be brought down
	; by nuking it... XXX: do we need to worry about a stray
	; _SEND_MESSAGE arriving here after we biff the box?
	;
	; 11/28/95: ignore any transaction whose dialog hasn't been completed.
	; There should, in theory, only be one... -- ardeb
	; 
		DerefDI	MailboxSendControl
		mov	bx, ds:[di].MSCI_transactions
transLoop:
		tst	bx
		jz	nukeDialog
		mov	bx, ds:[bx]
		test	ds:[bx].MSCT_flags, mask MSCTF_DIALOG_COMPLETE
		jnz	setFlag
		mov	bx, ds:[bx].MSCT_next
		jmp	transLoop
nukeDialog:
		call	MSCNukeDialog
		stc
done:
		.leave
		ret

setFlag:
	;
	; Set vardata flag so we know we need to biff the dialog when the
	; last transaction is gone.
	; 
		push	ax, cx
		mov	ax, TEMP_MAILBOX_SEND_CONTROL_DESTROY_DIALOG_PENDING
		clr	cx
		call	ObjVarAddData
		pop	ax, cx
		clc
		jmp	done
MSCNukeDialogIfPossible endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCMaybeFreeDialogBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the passed dialog block isn't being used for anything,
		nuke it. Dialog should have been unhooked and completely reset
		by this time.

CALLED BY:	(INTERNAL) MSCNukeDialog, 
			   MSCDeleteTransaction
PASS:		bx	= handle of dialog
		*ds:si	= MailboxSendControl
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	Object block may be freed with necessary queue delays

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/11/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCMaybeFreeDialogBlock proc	near
		class	MailboxSendControlClass
		uses	di, ax
		.enter
	;
	; First see if the block is for the current dialog.
	;
		mov	ax, TEMP_MAILBOX_SEND_CONTROL_CURRENT_DIALOG
		mov	di, bx
		call	ObjVarFindData
		xchg	bx, di
		jnc	notCurrent	; => no current
		cmp	ds:[di].TMDD_block, bx
		je	done		; => is current, so don't nuke block

notCurrent:
	;
	; Now run down the list of transactions, please.
	;
		DerefDI	MailboxSendControl
		mov	di, ds:[di].MSCI_transactions
transLoop:
		tst	di
		jz	nukeIt
		mov	di, ds:[di]
		cmp	bx, ds:[di].MSCT_dataBlock
		je	done
		mov	di, ds:[di].MSCT_next
		jmp	transLoop
nukeIt:
		call	ObjFreeObjBlock
done:
		.leave
		ret
MSCMaybeFreeDialogBlock endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCNukeDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we've got a companion dialog, destroy it with due caution

CALLED BY:	(INTERNAL) MSCMetaDetachComplete
			   MSCSpecUnbuild?
PASS:		*ds:si	= MailboxSendControl
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	dialog block may be freed and TEMP_MAILBOX_SEND_CONTROL_-
		CURRENT_DIALOG is deleted

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 4/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCNukeDialog	proc	near
		class	MailboxSendControlClass
		uses	ax, cx, dx, bp, bx
		.enter
		call	MSCGetDialogBlock
		tst	bx
		jz	done

	;
	; Cancel any transaction that was in-progress
	;
		mov	ax, MSG_MSD_CANCEL
		push	si
		mov	si, offset MSCSendDialog
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	si

		call	MSCRemoveFromAllLists
	;
	; Nuke the vardata that tracks the dialog's block handle
	; 
		mov	ax, TEMP_MAILBOX_SEND_CONTROL_CURRENT_DIALOG
		call	ObjVarDeleteData
	;
	; Lock down the dialog block and tell the dialog to unhook any
	; data-object UI it has hooked in.
	; 
		push	si
		call	ObjSwapLock
		mov	si, offset MSCSendDialog
		clr	cx, dx
		mov	ax, MSG_MSD_RESET_DATA_OBJECT_UI
		call	ObjCallInstanceNoLock
	;
	; Remove the dialog from the tree.
	; 
		mov	ax, MSG_GEN_REMOVE
		mov	dl, VUM_NOW
		mov	bp, mask CCF_MARK_DIRTY
		call	ObjCallInstanceNoLock
		call	ObjSwapUnlock
		pop	si
	;
	; Maybe free the block
	; 
		call	MSCMaybeFreeDialogBlock
done:
		.leave
		ret
MSCNukeDialog	endp

		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCRemoveFromAllLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that no objects in the passed block are on any
		GCN list in the mailbox application object

CALLED BY:	(INTERNAL) MSCGenControlRemoveFromGCNLists
			   PSDSendMessage
PASS:		bx	= block containing objects who shouldn't be on
			  any lists (may be 0)
		ds	= segment that can be fixed up
RETURN:		nothing
DESTROYED:	ax, cx, di, dx, bp
SIDE EFFECTS:	see above

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 4/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCRemoveFromAllLists proc	far
		.enter
		mov	cx, bx
		jcxz	done
		mov	ax, MSG_MA_REMOVE_BLOCK_OBJECTS_FROM_ALL_GCN_LISTS
		mov	di, mask MF_FIXUP_DS
		call	UtilCallMailboxApp
done:
		.leave
		ret
MSCRemoveFromAllLists endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCTransportSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up the Send dialog for the indicated transport

CALLED BY:	MSG_MAILBOX_SEND_CONTROL_TRANSPORT_SELECTED
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
		cx	= transport index # within transport menu
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 4/94	Initial version
	AY	2/ 9/95		Moved common code to
				MSCInitiateDialogWithTransport

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCTransportSelected method dynamic MailboxSendControlClass,
		     	MSG_MAILBOX_SEND_CONTROL_TRANSPORT_SELECTED
		.enter
	;
	; Ask the transport menu to map this to a transport + transOpt + medium
	; tuple.
	; 
		call	MSCGetChildBlockAndFeatures
EC <		ERROR_C	UNKNOWN_SOURCE_FOR_TRANSPORT_SELECTED		>
		sub	sp, size MailboxMediaTransport
		mov	bp, sp
		mov	dx, ss
		mov	ax, MSG_OTM_GET_TRANSPORT
		push	si
		mov	si, offset MSCTransportMenu
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
		pop	si

		mov	ax, \
			MSG_MAILBOX_SEND_CONTROL_INITIATE_DIALOG_WITH_TRANSPORT
		call	ObjCallInstanceNoLock
	;
	; Clear the stack and boogie.
	; 
		add	sp, size MailboxMediaTransport
		.leave
		ret
MSCTransportSelected endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCInitiateDialogWithTransport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up the send control dialog with the address control
		for this medium + transport.

CALLED BY:	MSG_MAILBOX_SEND_CONTROL_INITIATE_DIALOG_WITH_TRANSPORT
PASS:		*ds:si	= MailboxSendControlClass object
		ss:bp	= MailboxMediaTransport to be displayed
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	2/ 9/95   	Initial version (moved code from
				MSCTransportSelected)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCInitiateDialogWithTransport	method dynamic MailboxSendControlClass, 
			MSG_MAILBOX_SEND_CONTROL_INITIATE_DIALOG_WITH_TRANSPORT

EC <		CmpTok	ss:[bp].MMT_transport, MANUFACTURER_ID_GEOWORKS, \
   			GMTID_LOCAL>
EC <		ERROR_E	INVALID_TRANSPORT_SELECTED			>
	;
	; If any transaction marked non-reentrant pending for this transport,
	; bitch at the user and do nothing.
	; 
		call	MSCEnforceReentrancy
		LONG jc	done
	;
	; Now find or create the dialog box for this here controller.
	; 
		mov	ax, MDT_APPLICATION
   		call	MSCEnsureDialogBlock
	;
	; Tell the dialog what the transport is.
	; 
		push	si
		mov	si, offset MSCSendDialog
		mov	ax, MSG_MSD_SET_TRANSPORT
		mov	dx, ss
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; See if we already have some addresses stored in vardata for this
	; transport + option.
	;
		pop	si		; *ds:si = self
		mov	di, bx		; di = send dialog hptr
		mov	ax, TEMP_MAILBOX_SEND_CONTROL_ADDRESSES_AND_TRANSPORT
		call	ObjVarFindData	; CF set if found, ds:bx =
					;  MSCAddressesAndTransport
		xchg	bx, di		; ds:di = MSCAddressesAndTransport
		push	si		; save self lptr
		jnc	resetObj
		cmpdw	ds:[di].MSCAAT_transport.MTAO_transport, \
				ss:[bp].MMT_transport, ax
		jne	resetObj
		mov	ax, ds:[di].MSCAAT_transport.MTAO_transOption
		cmp	ax, ss:[bp].MMT_transOption
		jne	resetObj
	;
	; We stored some addresses for this transport + option.  Pass these
	; addresses to the send dialog.
	;
		mov	ax, ds:[OLMBH_header].LMBH_handle
		mov	cx, ds:[di].MSCAAT_addresses
					; ^lax:cx = MBACAddress array
		push	cx		; save array lptr
		mov	dx, size MSDSetAddressesWithTransportArgs
		sub	sp, dx
		mov	bp, sp
		movdw	ss:[bp].MSDSAWTA_addresses, axcx
		movdw	ss:[bp].MSDSAWTA_transAndOption.MTAO_transport, \
				ds:[di].MSCAAT_transport.MTAO_transport, ax
		mov	ax, ds:[di].MSCAAT_transport.MTAO_transOption
		mov	ss:[bp].MSDSAWTA_transAndOption.MTAO_transOption, ax

		mov	si, offset MSCSendDialog	; ^lbx:si = send dialog
		mov	ax, MSG_MSD_SET_ADDRESSES_WITH_TRANSPORT
		mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
		call	ObjMessage
		add	sp, size MSDSetAddressesWithTransportArgs
	;
	; Free the chunk array and vardata
	;
		pop	ax		; *ds:ax = MBACAddress array
		pop	si		; *ds:si = self
		push	si		; save again
		call	LMemFree
		mov	ax, TEMP_MAILBOX_SEND_CONTROL_ADDRESSES_AND_TRANSPORT
		call	ObjVarDeleteData

resetObj:
		pop	si
		DerefDI	MailboxSendControl
		mov	cx, ds:[di].MSCI_defBodyType
		call	MSCInitiateDialog
done:
		ret
MSCInitiateDialogWithTransport	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCInitiateDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the current dialog and bring it on screen

CALLED BY:	(INTERNAL) MSCInitiateDialogWithTransport,
			   MSCPoofSelected
PASS:		*ds:si	= MailboxSendControl
		bx	= duplicated dialog block
		cx	= MailboxObjectType to use
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/11/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCInitiateDialog proc	near
		.enter
	;
	; Tell the dialog to reset its data-object UI before we tell ourselves
	; what object type to use.
	; 
		push	si
		mov	si, offset MSCSendDialog
		mov	ax, MSG_MSD_RESET_DATA_OBJECT_UI
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		pop	si
	;
	; Tell ourselves what the current body type is. This will update the
	; dialog properly.
	; 
		mov	ax, MSG_MAILBOX_SEND_CONTROL_OBJECT_TYPE_SELECTED
		call	ObjCallInstanceNoLock
	;
	; Bring the dialog up on screen.
	; 
		mov	di, 1500		; need room for loading the
						;  transport driver, etc,
						;  sometimes...
		call	ThreadBorrowStackSpace
		push	di
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_FIXUP_DS
		mov	si, offset MSCSendDialog
		call	ObjMessage
		pop	di
		call	ThreadReturnStackSpace
		.leave
		ret
MSCInitiateDialog endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCPoofSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up the relevant dialog for sending a poof message

CALLED BY:	MSG_MAILBOX_SEND_CONTROL_POOF_SELECTED
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
		dx	= MailboxDialogType
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	current dialog may be destroyed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/11/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_POOF_MESSAGE_CREATION
mscPoofObjectTypes	MailboxObjectType	MOT_FILE, 
						MOT_CLIPBOARD,
						MOT_QUICK_MESSAGE

MSCPoofSelected	method dynamic MailboxSendControlClass, 
				MSG_MAILBOX_SEND_CONTROL_POOF_SELECTED
		.enter
		mov	bx, dx
		shl	bx
		mov	cx, cs:[mscPoofObjectTypes-MDT_FILE*2][bx]

		mov_tr	ax, dx
		call	MSCEnsureDialogBlock
		call	MSCInitiateDialog
		.leave
		ret
MSCPoofSelected	endm
endif	; _POOF_MESSAGE_CREATION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCEnforceReentrancy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for a transaction for this transport and see if it's
		marked non-reentrant. If so, complain to the user and refuse
		to bring up the dialog box.

CALLED BY:	(INTERNAL) MSCTransportSelected
PASS:		*ds:si	= MailboxSendControl
		ss:bp	= MailboxMediaTransport selected
RETURN:		carry set if shouldn't bring up the dialog
DESTROYED:	ax, di, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/28/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCEnforceReentrancy proc	near
		class	MailboxSendControlClass
		.enter
		DerefDI	MailboxSendControl
		lea	bx, ds:[di].MSCI_transactions-MSCT_next
		movdw	cxdx, ss:[bp].MMT_transport
		mov	ax, ss:[bp].MMT_transOption
transLoop:
		mov	bx, ds:[bx].MSCT_next
		tst_clc	bx
		jz	done
		mov	bx, ds:[bx]
		CmpTok	ds:[bx].MSCT_transport, cx, dx, transLoop
		cmp	ds:[bx].MSCT_transOption, ax
		jne	transLoop
		test	ds:[bx].MSCT_flags, mask MSCTF_NON_REENTRANT
		jz	done
		stc
	; XXX: PUT UP DIALOG HERE TELLING USER WHAT IS WRONG
done:
		.leave
		ret
MSCEnforceReentrancy endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCEnsureDialogBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the handle of the duplicated resource with the
		Send dialog box in it for this controller. If the dialog
		hasn't yet been duplicated, duplicate it.

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= MailboxSendControl
		ax	= MailboxDialogType
RETURN:		bx	= handle of dup block
DESTROYED:	nothing
SIDE EFFECTS:	TEMP_MAILBOX_SEND_CONTROL_CURRENT_DIALOG set

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 4/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCEnsureDialogBlock proc	near
		uses	ax, dx
		.enter
	;
	; Use the delightful ObjVarDerefData to get or create and get the
	; dialog box handle.
	; 
		mov_tr	dx, ax			; dx <- pass dialog type
again:
		mov	ax, TEMP_MAILBOX_SEND_CONTROL_CURRENT_DIALOG
		call	ObjVarDerefData
		cmp	ds:[bx].TMDD_type, dx
		je	getBlock
	;
	; Wrong type of dialog -- destroy it and try again.
	;
		call	MSCNukeDialog
		jmp	again

getBlock:
		mov	bx, ds:[bx]
		
	;
	; Make sure the destroy flag is gone, since we assume that asking
	; to be sure the dialog is there means we don't want it to go away.
	;
		mov	ax, TEMP_MAILBOX_SEND_CONTROL_DESTROY_DIALOG_PENDING
		call	ObjVarDeleteData
		.leave
		ret
MSCEnsureDialogBlock endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCMetaInitializeVarData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Duplicate the dialog for the controller, if that's what
		needs initialization.

CALLED BY:	MSG_META_INITIALIZE_VAR_DATA
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
		cx	= vardata tag
		dx	= MailboxDialogType, if TEMP_MAILBOX_SEND_CONTROL_-
			  CURRENT_DIALOG
RETURN:		ax	= offset to extra data created, as would be returned
			  in bx by ObjVarAddData
DESTROYED:	cx, dx, bp allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 4/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_POOF_MESSAGE_CREATION
mscDialogTable	hptr	handle MSCSendDialog,		; MDT_APPLICATION
			handle PoofFileSendPanel,	; MDT_FILE
			handle PoofClipboardSendPanel,	; MDT_CLIPBOARD
			handle PoofQuickMessageSendPanel; MDT_QUICK_MESSAGE
	.assert length mscDialogTable eq MailboxDialogType
	.assert offset MSCSendDialog eq offset PoofFileSendPanel
	.assert offset MSCSendDialog eq offset PoofClipboardSendPanel
	.assert offset MSCSendDialog eq offset PoofQuickMessageSendPanel
endif

MSCMetaInitializeVarData method dynamic MailboxSendControlClass, 
				MSG_META_INITIALIZE_VAR_DATA
		cmp	cx, TEMP_MAILBOX_SEND_CONTROL_CURRENT_DIALOG
		je	createDialog
		mov	di, offset MailboxSendControlClass
		GOTO	ObjCallSuperNoLock

createDialog:
	;
	; Duplicate the dialog resource, after fetching the number of data
	; types the controller supports (while we've got *ds:si
	; 
		push	si
		mov	si, ds:[di].MSCI_dataTypes
		Assert	ChunkArray, dssi
		call	ChunkArrayGetCount	; cx <- # types

if	_POOF_MESSAGE_CREATION

		Assert	etype, dx, MailboxDialogType
		mov	bx, dx
	CheckHack <MDT_FILE eq MDT_APPLICATION+1>	; steps by 1...
		shl	bx
		mov	bx, cs:[mscDialogTable][bx]

else	; !_POOF_MESSAGE_CREATION

		mov	bx, handle MSCSendDialog

endif	; !_POOF_MESSAGE_CREATION
		mov	si, offset MSCSendDialog
		call	UtilCreateDialogFixupDS
		pop	si
	;
	; Set the controller as the output for the block
	; 
		call	ObjSwapLock
		call	ObjBlockSetOutput
	;
	; Tell the content list how many items it has
	; 
if	_CAN_SELECT_CONTENTS
 if	_POOF_MESSAGE_CREATION
 		cmp	dx, MDT_APPLICATION
		jne	contentsHandled
 endif	; _POOF_MESSAGE_CREATION
		push	si, dx
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		mov	si, offset MSCContentList
		call	ObjCallInstanceNoLock
		pop	si, dx
contentsHandled::
endif	; _CAN_SELECT_CONTENTS
		call	ObjSwapUnlock
	;
	; Add the vardata entry to the controller.
	; 
		mov	bp, bx
		mov	ax, TEMP_MAILBOX_SEND_CONTROL_CURRENT_DIALOG
		mov	cx, size TempMailboxDialogData
		call	ObjVarAddData
		mov	ds:[bx].TMDD_block, bp
		mov	ds:[bx].TMDD_type, dx
	;
	; If MOT_PAGE_RANGE is an option, add ourselves to the page-range
	; GCN list.
	; 
		cmp	dx, MDT_APPLICATION
		jne	done			; => done, as no page info
						;  with poof messages

		mov	ax, MSG_META_GCN_LIST_ADD
		call	MSCCopeWithPageRangeGCN
done:
	;
	; Return the offset of the added vardata in AX
	; 
		mov	ax, TEMP_MAILBOX_SEND_CONTROL_CURRENT_DIALOG
		call	ObjVarFindData
		mov_tr	ax, bx
		ret
MSCMetaInitializeVarData endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCCopeWithPageRangeGCN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add or remove the controller from the PAGE_STATE_CHANGE
		list to keep the page range UI updated

CALLED BY:	(INTERNAL)
PASS:		ax	= MSG_META_GCN_LIST_ADD/MSG_META_GCN_LIST_REMOVE
		*ds:si	= MailboxSendControl object
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	guess

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 4/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCCopeWithPageRangeGCN proc	near
		class	MailboxSendControlClass
		uses	bx, cx, dx, bp, si, di
		.enter
	;
	; If data type array not built yet (as can happen if we get a DETACH
	; before we ever generate our UI), we don't need to worry about anything
	; here.
	;
		DerefDI	MailboxSendControl
		tst	ds:[di].MSCI_dataTypes
		jz	done
	;
	; Find the MOT_PAGE_RANGE or MOT_CURRENT_PAGE in the array of data
	; types.
	; 
		mov	cx, MOT_PAGE_RANGE
		call	MSCFindDataType
		jc	doIt
		mov	cx, MOT_CURRENT_PAGE
		call	MSCFindDataType
		jnc	done
doIt:
	;
	; It was indeed there, so set up the params for add/remove
	; 
		mov	dx, size GCNListParams
		sub	sp, dx
		mov	bp, sp
		mov	bx, ds:[LMBH_handle]
		movdw	ss:[bp].GCNLP_optr, bxsi
		mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
		mov	ss:[bp].GCNLP_ID.GCNLT_type, 
				GAGCNLT_APP_TARGET_NOTIFY_PAGE_STATE_CHANGE
				
	;
	; Call the current application object to do the work.
	; 
		clr	bx
		call	GeodeGetAppObject
		mov	di, mask MF_FIXUP_DS or mask MF_CALL or mask MF_STACK
		call	ObjMessage
		add	sp, size GCNListParams
done:
		.leave
		ret
MSCCopeWithPageRangeGCN endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCGetDialogBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the handle of the duplicated resource with the
		Send dialog box in it for this controller.

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= MailboxSendControl
RETURN:		bx	= handle of dup block (0 if none)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 4/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCGetDialogBlock proc	near
		uses	ax
		.enter
		mov	ax, TEMP_MAILBOX_SEND_CONTROL_CURRENT_DIALOG
		call	ObjVarFindData
		jnc	nothing
		mov	bx, ds:[bx]
done:
		.leave
		ret
nothing:
		clr	bx
		jmp	done
MSCGetDialogBlock endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCGetContentsMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the moniker for an element of the dataTypes array

CALLED BY:	MSG_MAILBOX_SEND_CONTROL_GET_CONTENTS_MONIKER
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
		^lcx:dx	= dynamic list requesting the moniker
		bp	= moniker # being sought
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 4/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCGetContentsMoniker method dynamic MailboxSendControlClass, 
				MSG_MAILBOX_SEND_CONTROL_GET_CONTENTS_MONIKER
		.enter
		pushdw	cxdx
		mov	cx, bp				; cx <- index
		call	MSCGetContentTextMoniker	; ^lcx:dx <- moniker
	;
	; Give the moniker to the list.
	;
		popdw	bxsi		; ^lbx:si <- dynamic list
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER_OPTR
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		ret
MSCGetContentsMoniker endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCGetContentTextMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a text moniker in the list for the passed index

CALLED BY:	(INTERNAL) MSCGetContentsMoniker,
			   MSCGetContentsString
PASS:		ds:di	= MailboxSendControlInstance
		cx	= index
RETURN:		^lcx:dx	= moniker to use (might not be text, if programmer
			  was a goob and didn't provide one...)
DESTROYED:	ax, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCGetContentTextMoniker proc	near
		class	MailboxSendControlClass
		uses	bp, es, si
		.enter
	;
	; Point to the element in the array
	; 
		mov	si, ds:[di].MSCI_dataTypes
		Assert	ChunkArray, dssi
		mov_tr	ax, cx
		call	ChunkArrayElementToPtr
EC <		ERROR_C	REQUEST_FOR_INVALID_CONTENTS_MONIKER		>
	;
	; Get the moniker/moniker list for the entry.
	; 
		mov	di, ds:[di].MSOT_desc
		Assert	chunk, di, ds
	;
	; Use VisFindMoniker to find the right moniker.
	; 
		segmov	es, dgroup, ax
		mov	bh, es:[uiDisplayType]
		mov	bp, VMS_TEXT shl offset VMSF_STYLE
		call	VisFindMoniker	; ^lcx:dx <- moniker
		.leave
		ret
MSCGetContentTextMoniker endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCGetContentsString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the string that corresponds to a data type.

CALLED BY:	MSG_MAILBOX_SEND_CONTROL_GET_CONTENTS_STRING
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
		cx	= contents index
		^hdx	= block in which to place null-term string
RETURN:		^ldx:ax	= string
DESTROYED:	cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCGetContentsString method dynamic MailboxSendControlClass, 
				MSG_MAILBOX_SEND_CONTROL_GET_CONTENTS_STRING
		.enter
	;
	; Fetch the text moniker for the data type.
	; 
		push	dx
		call	MSCGetContentTextMoniker
		movdw	bxsi, cxdx
		pop	dx
	;
	; Lock down the moniker and figure out how much of it is text string.
	; 
		call	ObjSwapLock
		mov	si, ds:[si]
		ChunkSizePtr	ds, si, cx
EC <		test	ds:[si].VM_type, mask VMT_GSTRING		>
EC <		ERROR_NZ	TEXT_MONIKER_MISSING_FOR_DATA_TYPE	>
	;
	; Point to the start of the text, adjusting the number of bytes to
	; copy accordingly.
	; 
		add	si, offset VM_data + offset VMT_text
		sub	cx, offset VM_data + offset VMT_text
	;
	; Lock down the destination block.
	; 
		xchg	bx, dx
		call	ObjLockObjBlock
	;
	; Allocate a suitable chunk in the destination block.
	; 
		push	ds
		mov	ds, ax
		mov	al, mask OCF_DIRTY
		call	LMemAlloc
	;
	; Copy the moniker text into the destination chunk
	; 
		mov	di, ax
		mov	di, ds:[di]
		segmov	es, ds			; es:di <- destination
		pop	ds			; ds:si <- moniker text
		rep	movsb
	;
	; Unlock the destination block.
	; 
		call	MemUnlock
	;
	; Unlock the moniker block, locking the object block again.
	; 
		xchg	bx, dx
		call	ObjSwapUnlock
		.leave
		ret
MSCGetContentsString endm

MSCAugmentElement struct
    MSCAE_dataType	MailboxObjectType
    MSCAE_monikerList	optr
MSCAugmentElement ends

MSCAugmentInfo struct
    MSCAI_hint		MailboxSendControlVarData
    MSCAI_numElements	word
    MSCAI_elements	label	MSCAugmentElement
MSCAugmentInfo	ends

;----------

mscPagesElements	MSCAugmentInfo	<
	ATTR_MAILBOX_SEND_CONTROL_SEND_PAGES, 2
>
MSCAugmentElement <MOT_CURRENT_PAGE, uiCurrentPageMonikers>,
		  <MOT_PAGE_RANGE, uiPageRangeMonikers>

;----------

mscDocumentElements	MSCAugmentInfo <
	ATTR_MAILBOX_SEND_CONTROL_SEND_DOCUMENT, 1
>
MSCAugmentElement <MOT_DOCUMENT, uiDocumentMonikers>

;----------

mscSelectionElements	MSCAugmentInfo <
	ATTR_MAILBOX_SEND_CONTROL_SEND_SELECTION, 1
>
MSCAugmentElement <MOT_SELECTION, uiSelectionMonikers>

;----------

mscAugmentTable	nptr.MSCAugmentInfo	mscPagesElements,
					mscDocumentElements,
					mscSelectionElements
	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCGenControlAddToGcnLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Augment the dataTypes array with those indicated by the
		hints.

CALLED BY:	MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 4/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCGenControlAddToGcnLists method dynamic MailboxSendControlClass, 
				MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
	;
	; If need be, augment the data types chunkarray.
	;
		call	MSCAugmentDataTypes
	;
	; Let the superclass do what it ought.
	; 
		mov	di, offset MailboxSendControlClass
		GOTO	ObjCallSuperNoLock
MSCGenControlAddToGcnLists endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCAugmentDataTypes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Augment the dataTypes array with those indicated by the
		hints.

CALLED BY:	internal

PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance

RETURN:		nothing

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	4/24/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MSCAugmentDataTypes	proc	near
		class	MailboxSendControlClass
		uses	ax, bx, cx, dx, di, si, bp
		.enter
		
		tst	ds:[di].MSCI_dataTypes
		jz	createArray
	;
	; There's a data types array there already.  If it's dirty, then
	; we've already added to it and can leave.
	;
		mov	ax, ds:[di].MSCI_dataTypes ; ax <- chunk of interest
		call	ObjGetFlags		; al <- flags
		test	al, mask OCF_DIRTY
		jz	haveArray		; jump if not yet augmented
		jmp	done
		
createArray:
		push	si
		clr	si, cx			; si <- alloc please
						; cx <- default header size
		mov	al, mask OCF_DIRTY
		mov	bx, size MailboxSendObjectType
		call	ChunkArrayCreate
		mov_tr	ax, si
		pop	si
		DerefDI	MailboxSendControl
		mov	ds:[di].MSCI_dataTypes, ax

haveArray:
	;
	; Now loop through the list of things we worry about seeing if the
	; controller has any of those attributes set and augmenting the array
	; of data types with the appropriate monikers etc. if so.
	;
		mov	bx, offset mscAugmentTable
		mov	cx, length mscAugmentTable
augmentLoop:
		mov	di, cs:[bx]		; cs:di <- info for next hint
		push	bx
		mov	ax, cs:[di].MSCAI_hint	; ax <- hint to look for
		call	ObjVarFindData
		jnc	augmentNext		; => not found
	;
	; Found a hint. Loop through the elements to add to the array and add
	; them.
	; 
		push	cx, bx
		mov	cx, cs:[di].MSCAI_numElements
		lea	bx, cs:[di].MSCAI_elements	; cs:bx <- next element
elementLoop:
	    ;
	    ; Make sure the element's not already in the array.
	    ; 
		mov	ax, cs:[bx].MSCAE_dataType
		xchg	ax, cx			; cx <- data type, ax <- save cx
		call	MSCFindDataType
		xchg	ax, cx			; ax <- data type, cx <- save cx
		jc	nextElement		; => already there
	    ;
	    ; Add the element to the array, please
	    ; 
		call	MSCAddOneElement

nextElement:
	;
	; Advance to the next element to add.
	; 
		add	bx, size MSCAugmentElement
		loop	elementLoop
		pop	cx, bx

augmentNext:
	;
	; Advance to the next hint to check.
	; 
		pop	bx
		add	bx, type mscAugmentTable
		loop	augmentLoop
	;
	; If no default body type specified, set it to the first in the array.
	;
		DerefDI	MailboxSendControl
		tst	ds:[di].MSCI_defBodyType
		jnz	done
		
		push	si
		mov	si, ds:[di].MSCI_dataTypes
		clr	ax
		call	ChunkArrayElementToPtr
EC <		ERROR_C	NO_DATA_TYPES_SET_FOR_SEND_CONTROL		>
		mov	ax, ds:[di].MSOT_id
		pop	si
		DerefDI	MailboxSendControl
		mov	ds:[di].MSCI_defBodyType, ax
done:
		.leave
		ret
MSCAugmentDataTypes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCRelocOrUnreloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Relocation routine to relocate and unrelocate MSCI_dataTypes
		and any moniker lists it contains.

CALLED BY:	MSG_META_RELOCATE, MSG_META_UNRELOCATE
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
		dx	= VMRelocType
		ss:bp	= frame to pass to ObjRelocOrUnRelocSuper
RETURN:		carry set on error
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 7/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCRelocOrUnreloc method dynamic MailboxSendControlClass, reloc
		.enter
	;
	; If no data types array, nothing to do.
	; 
		tst	ds:[di].MSCI_dataTypes
		jz	callSuper
	;
	; Else relocate all the moniker lists pointed to by the elements of
	; the data types array.
	; 
		push	bp, si
		clr	bp		; assume relocation
		cmp	ax, MSG_META_RELOCATE
		je	processTypes	; yup
		mov	bp, 1		; => unrelocate
processTypes:
		mov	si, ds:[di].MSCI_dataTypes
		mov	bx, cs
		mov	di, offset MSCRelocOrUnrelocCallback
		call	ChunkArrayEnum
		pop	bp, si
		jc	done		; just return if error there

callSuper:
		mov	di, offset MailboxSendControlClass
		call	ObjRelocOrUnRelocSuper
done:
		.leave
		ret
MSCRelocOrUnreloc endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCRelocOrUnrelocCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to relocate or unrelocate a data type's
		moniker list, if it ha a list

CALLED BY:	(INTERNAL) MSCRelocOrUnreloc via ChunkArrayEnum
PASS:		ds:di	= MailboxSendObjectType whose MSOT_desc needs care
		bp	= 0 to relocate, 1 to unrelocate
RETURN:		carry set on error (stop enumerating)
DESTROYED:	dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 7/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
objTypeMonikers	word	uiDocumentMonikers,	; MOT_DOCUMENT
			uiPageRangeMonikers,	; MOT_PAGE_RANGE
			uiCurrentPageMonikers,	; MOT_CURRENT_PAGE
			uiSelectionMonikers,	; MOT_SELECTION
			uiClipboard,		; MOT_CLIPBOARD
			uiFile,			; MOT_FILE
			uiQuickMessage		; MOT_QUICK_MESSAGE
.assert (($-objTypeMonikers)/2) eq (MailboxObjectType - first MailboxObjectType)
MSCRelocOrUnrelocCallback proc	far
		.enter
	;
	; If the entry is for one of our things, we can't actually relocate
	; the list, as the monikers remain within our resource, not copied into
	; the application's, and a handle for something in a library cannot be
	; relocated or unrelocated (only a far pointer to an entry point can).
	;
	; Not to fear, however: if it's one of ours, we simply write over the
	; MSOT_desc chunk with the version for this session.
	; 
		mov	bx, ds:[di].MSOT_id
		cmp	bx, first MailboxObjectType
		jb	straightReloc
		cmp	bx, MailboxObjectType
		jae	straightReloc
	;
	; It's one of ours. If we're unrelocating, we need do nothing, as
	; anything we'd do would just get overwritten when relocating next time.
	; 
		tst_clc	bp
		jnz	done
	;
	; Convert the object type to a moniker list chunk in ROStrings.
	; 
		sub	bx, first MailboxObjectType
		shl	bx
		mov	si, cs:[objTypeMonikers][bx]
	;
	; Deref the moniker list chunk we want to overwrite.
	; 
		mov	di, ds:[di].MSOT_desc
		mov	di, ds:[di]
		push	es
		segmov	es, ds
	;
	; Lock down the ROStrings block, please.
	; 
		mov	bx, handle uiDocumentMonikers
		call	MemLock
		mov	ds, ax
	;
	; Find the size of the source chunk and, to be safe, compare that to
	; the size of the destination chunk. If they don't match, we cannot
	; finish the relocation.
	; 
		mov	si, ds:[si]
		ChunkSizePtr	ds, si, cx
		ChunkSizePtr	es, di, dx
		cmp	cx, dx
		jne	copyErr
	;
	; Overwrite the chunk and release the ROStrings block
	; 
		rep	movsb
		clc
overwriteComplete:
		call	MemUnlock
		segmov	ds, es			; must return ds unchanged
		pop	es
		jmp	done

straightReloc:
		mov	cx, ds:[di].MSOT_desc	; *ds:cx <- moniker list
		mov	dx, ds:[LMBH_handle]
		call	GenRelocMonikerList	; this checks to see if the
						;  thing is actually a list,
						;  so we don't have to
	;
	; return the carry that came back from there as our own, as we need
	; to propagate any error we get back.
	; 
done:
		.leave
		ret

copyErr:
	;
	; Chunk size has changed between when we went to state and now, so
	; we can't relocate the thing.
	; 
		WARNING	MAILBOX_DEFINED_OBJECT_TYPES_MONIKER_LIST_HAS_CHANGED_SIZE
		stc
		jmp	overwriteComplete
MSCRelocOrUnrelocCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCAddOneElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a single element to the array of possible body types

CALLED BY:	(INTERNAL) MSCGenControlAddToGcnLists
PASS:		*ds:si	= MailboxSendControl
		cs:bx	= MSCAugmentElement to add
RETURN:		ds	= fixed up
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 4/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCAddOneElement proc	near
		uses	ax, bx, cx, dx, si, di
		class	MailboxSendControlClass
		.enter
	;
	; Copy the moniker list chunk in. We don't have to mess with the
	; contents of the list or copy the monikers themselves in, as they
	; reside in a sharable block from which anyone can copy them when
	; the need arises.
	; 
		push	bx, si
		mov	si, cs:[bx].MSCAE_monikerList.chunk
		mov	bx, cs:[bx].MSCAE_monikerList.handle
		call	UtilCopyChunk
	;
	; Mark the duplicate as dirty, making sure it's not ignoreDirty, so
	; it's still there when we restore from state.
	; 
		mov_tr	ax, si
		mov	bx, mask OCF_DIRTY or (mask OCF_IGNORE_DIRTY shl 8)
		call	ObjSetFlags
		mov_tr	cx, ax		; cx <- chunk, for safekeeping during
					;  the append

		pop	bx, si
	;
	; Append an entry to the array
	; 
		DerefDI	MailboxSendControl
		mov	si, ds:[di].MSCI_dataTypes
		call	ChunkArrayAppend
	;
	; Store the moniker list chunk and the data type in the entry.
	; 
		mov	ds:[di].MSOT_desc, cx
		mov	ds:[di].MSOT_feature, 0
		mov	ax, cs:[bx].MSCAE_dataType
		mov	ds:[di].MSOT_id, ax
		
		.leave
		ret
MSCAddOneElement endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCSetContents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Choose something else to put in the body of the message

CALLED BY:	MSG_MAILBOX_SEND_CONTROL_SET_CONTENTS
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
		cx	= index into MSCI_dataTypes array
		bp	= number of selections (must be 1)
		dl	= GenItemGroupStateFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCSetContents	method dynamic MailboxSendControlClass, 
				MSG_MAILBOX_SEND_CONTROL_SET_CONTENTS
		.enter
	;
	; Tell the dialog to clear out its data-object UI before switching to
	; the new one.
	; 
		call	MSCGetDialogBlock
		Assert	ne, bx, 0
		push	si, cx
		mov	si, offset MSCSendDialog
		mov	ax, MSG_MSD_RESET_DATA_OBJECT_UI
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		pop	si, cx
		DerefDI	MailboxSendControl
	;
	; Map the index to a MOT and tell ourselves about it.
	; 
		push	si
		DerefDI	MailboxSendControl
		mov	si, ds:[di].MSCI_dataTypes
		Assert	ChunkArray, dssi
		mov_tr	ax, cx
		call	ChunkArrayElementToPtr
EC <		ERROR_C	INVALID_CONTENTS_INDEX_SET			>

   		mov	cx, ds:[di].MSOT_id
		pop	si
		mov	ax, MSG_MAILBOX_SEND_CONTROL_OBJECT_TYPE_SELECTED
		call	ObjCallInstanceNoLock
		.leave
		ret
MSCSetContents	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCObjectTypeSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note that the user (or caller) has chosen a different
		type of data to be in the body of the message.

CALLED BY:	MSG_MAILBOX_SEND_CONTROL_OBJECT_TYPE_SELECTED
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
		cx	= MailboxObjectType
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	Dialog is updated with the selection
		Data object UI might be enabled

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCObjectTypeSelected method dynamic MailboxSendControlClass, 
				MSG_MAILBOX_SEND_CONTROL_OBJECT_TYPE_SELECTED
		.enter
	;
	; Record the body type.
	; 
		mov	ds:[di].MSCI_curBodyType, cx

	;
	; If no current dialog, or not for application message, we have nothing
	; else to do.
	; 
		mov	ax, TEMP_MAILBOX_SEND_CONTROL_CURRENT_DIALOG
		call	ObjVarFindData
		jnc	done
		cmp	ds:[bx].TMDD_type, MDT_APPLICATION
		jne	done
		mov	bx, ds:[bx].TMDD_block

		push	cx

		cmp	cx, MOT_PAGE_RANGE
		jne	setContents
	;
	; Page range selected, so tell ourselves to put up the page range UI
	; 
		mov	cx, bx
		mov	dx, offset MSCPageRangeGroup
		mov	ax, MSG_MAILBOX_SEND_CONTROL_ENABLE_DATA_OBJECT_UI
		call	ObjCallInstanceNoLock

setContents:
		pop	cx
	;
	; Now tell the dialog about the change.
	; 
		mov	dx, cx			; dx <- MOT
		call	MSCFindDataType		; cx <- content index
		mov	si, offset MSCSendDialog
		mov	ax, MSG_MSD_SET_CONTENTS
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
done:
		.leave
		ret
MSCObjectTypeSelected endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCEnableDataObjectUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the dialog to use a new set of UI for narrowing the
		selection of the data object

CALLED BY:	MSG_MAILBOX_SEND_CONTROL_ENABLE_DATA_OBJECT_UI
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
		^lcx:dx	= root of tree to use.
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCEnableDataObjectUI method dynamic MailboxSendControlClass, 
				MSG_MAILBOX_SEND_CONTROL_ENABLE_DATA_OBJECT_UI
if 	_CAN_SELECT_CONTENTS
		mov	ax, MDT_APPLICATION
		call	MSCEnsureDialogBlock
		mov	si, offset MSCSendDialog
		mov	ax, MSG_MSD_ENABLE_DATA_OBJECT_UI
		mov	di, mask MF_FIXUP_DS
		GOTO	ObjMessage
else
	;
	; Do nothing if user isn't allowed to choose the contents of the message
	;
		ret
endif	; _CAN_SELECT_CONTENTS
MSCEnableDataObjectUI endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCSetDataObjectValid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note whether the user has selected a valid data object
		using the data object UI enabled by a previous call to
		MSG_MAILBOX_SEND_CONTROL_ENABLE_DATA_OBJECT_UI

CALLED BY:	MSG_MAILBOX_SEND_CONTROL_SET_DATA_OBJECT_VALID
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
		cx	= TRUE if it's valid, FALSE if it's not
RETURN:		nothing
DESTROYED:	ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/13/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCSetDataObjectValid method dynamic MailboxSendControlClass, 
				MSG_MAILBOX_SEND_CONTROL_SET_DATA_OBJECT_VALID
		.enter
if	_CAN_SELECT_CONTENTS
		tst	cx
		mov	cx, mask MSDVS_DATA_UI	; assume setting bit
		jnz	callDialog
		xchg	cl, ch			; wrong -- clear it
callDialog:
		call	MSCGetDialogBlock
		tst	bx
		jz	done			; => no dialog, so ignore

		mov	si, offset MSCSendDialog
		mov	ax, MSG_MSD_SET_VALID
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
done:
endif	; _CAN_SELECT_CONTENTS
		.leave
		ret
MSCSetDataObjectValid		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCCreateBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ask our output to create the body for the current transaction

CALLED BY:	MSG_MAILBOX_SEND_CONTROL_CREATE_BODY
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
		ds:di.MSCT_transactions = current transaction
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCCreateBody	method dynamic MailboxSendControlClass, 
				MSG_MAILBOX_SEND_CONTROL_CREATE_BODY
		.enter
	;
	; See if the address control wishes to create the message.
	; 
		mov	bp, ds:[di].MSCI_transactions	; bp <- transaction
							;  handle
		Assert	transHandle, bp

		mov	cx, ds:[di].MSCI_curBodyType
		mov	bx, ds:[bp]

		Assert	e, ds:[bx].MSCT_objType, cx

		Assert	bitClear, ds:[bx].MSCT_flags, MSCTF_CREATION_PENDING
		Assert	e, ds:[bx].MSCT_bodyRef, 0

	;
	; Flag creation as pending.
	;
		ornf	ds:[bx].MSCT_flags, mask MSCTF_CREATION_PENDING
	;
	; Tell the dialog about it.
	;
		mov	bx, ds:[bx].MSCT_dataBlock
		
		push	si
		mov	si, offset MSCSendDialog
		mov	dx, ds			; *dx:bp <- transaction
						; cx = body type
		mov	ax, MSG_MSD_CREATE_BODY
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	si
		jc	setReentrant		; => MAC will handle it

		DerefDI	MailboxSendControl
		
	;
	; Now we know the controller output is responsible for creating the
	; thing, please notify it when the message is registered. (Address
	; controls are already notified via other mechanisms...)
	; 
		mov	bx, ds:[bp]
		ornf	ds:[bx].MSCT_flags, mask MSCTF_NOTIFY_AFTER_REGISTER
	;
	; Address control doesn't want to create it. Send notification to our
	; output asking it to create the message and call us back.
	; 
		mov	ax, MSG_META_MAILBOX_CREATE_MESSAGE
		mov	cx, ds:[LMBH_handle]
		mov	dx, si			; ^lcx:dx <- us
		pushdw	ds:[di].GCI_output	; pass output on the stack
		clr	di
		call	GenProcessAction
done:
		.leave
		ret

setReentrant:
EC <		cmp	ax, TRUE					>
EC <		je	flagOK						>
EC <		tst	ax						>
EC <		ERROR_NE INVALID_REENTRANT_FLAG_RETURNED_BY_MAC		>
EC <flagOK:								>
		tst	ax
		jz	done

		Assert	transHandle, bp
		mov	bx, ds:[bp]
		Assert	chunkPtr bx, ds
		ornf	ds:[bx].MSCT_flags, mask MSCTF_NON_REENTRANT
		jmp	done
MSCCreateBody	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCCreateTransaction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and record a transaction chunk for the current
		settings.

CALLED BY:	MSG_MAILBOX_SEND_CONTROL_CREATE_TRANSACTION
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
RETURN:		*ds:ax	= MSCTransaction
DESTROYED:	cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCCreateTransaction method dynamic MailboxSendControlClass,
				MSG_MAILBOX_SEND_CONTROL_CREATE_TRANSACTION
		.enter
	;
	; Allocate a chunk for the transaction.
	; 
		mov	cx, size MSCTransaction
		mov	ax, mask OCF_DIRTY
		call	LMemAlloc
	;
	; Link the new transaction to the head of the chain.
	; 
		DerefDI	MailboxSendControl
		mov	bp, ax			; bp <- transaction (for
						;  dialog box)
		mov	bx, ds:[bp]
		xchg	ax, ds:[di].MSCI_transactions	; ax <- old head
		mov	ds:[bx].MSCT_next, ax

		mov	dx, ds:[di].MSCI_curBodyType	; dx <- body type
							;  while we've got
							;  MSCI...
	;
	; Zero-initialize everything except MSCT_next.
	;
		segmov	es, ds
		mov	di, bx
.assert (offset MSCT_next eq 0)
		add	di, size MSCT_next		; keep MSCT_next
		sub	cx, size MSCT_next
		clr	al
		rep	stosb
	;
	; Initialize the size and object type fields.
	; 
		mov	ds:[bx].MSCT_size, size MSCTransaction
		mov	ds:[bx].MSCT_objType, dx
	;
	; Call the dialog box to set up everything else.
	; 
		call	MSCGetDialogBlock
		Assert	ne, bx, 0
		
		push	bp, si
		mov	si, ds:[bp]			; store dialog
		mov	ds:[si].MSCT_dataBlock, bx	;  block handle
						
		mov	si, offset MSCSendDialog
		mov	ax, MSG_MSD_CREATE_TRANSACTION
		mov	dx, ds			; *dx:bp <- transaction
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
		pop	ax, si			; *ds:ax <- transaction,
						; *ds:si <- MSC
	; all systems are go

		.leave
		ret
MSCCreateTransaction endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCGetPageRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the range of pages selected for the indicated message.

CALLED BY:	MSG_MAILBOX_SEND_CONTROL_GET_PAGE_RANGE
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
		bp	= transaction handle passed by MSG_META_MAILBOX_-
			  CREATE_MESSAGE
RETURN:		cx	= first page
		dx	= last page
DESTROYED:	ax
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCGetPageRange method dynamic MailboxSendControlClass, 
				MSG_MAILBOX_SEND_CONTROL_GET_PAGE_RANGE
		.enter
		Assert	transHandle, bp
   		mov	bx, ds:[bp]
EC <		cmp	ds:[bx].MSCT_objType, MOT_PAGE_RANGE		>
EC <		je	ok						>
EC <		cmp	ds:[bx].MSCT_objType, MOT_CURRENT_PAGE		>
EC <		WARNING_NE ASKING_FOR_PAGE_RANGE_FOR_MESSAGE_THAT_DOESNT_INVOLVE_ONE>
EC <ok:									>
		mov	cx, ds:[bx].MSCT_objData.MSCOD_pageRange.MSCPRD_start
		mov	dx, ds:[bx].MSCT_objData.MSCOD_pageRange.MSCPRD_end
		Destroy	ax
		.leave
		ret
MSCGetPageRange		endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCGetObjectType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the MailboxObjectType for the given transaction

CALLED BY:	MSG_MAILBOX_SEND_CONTROL_GET_OBJECT_TYPE
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
		bp	= transaction handle
RETURN:		ax	= MailboxObjectType
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 9/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCGetObjectType method dynamic MailboxSendControlClass, 
				MSG_MAILBOX_SEND_CONTROL_GET_OBJECT_TYPE
		.enter
		Assert	transHandle, bp
		mov	bx, ds:[bp]
		mov	ax, ds:[bx].MSCT_objType
		.leave
		ret
MSCGetObjectType endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCChooseFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ask the transport driver what format it would like the
		application to use.

CALLED BY:	MSG_MAILBOX_SEND_CONTROL_CHOOSE_FORMAT
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
		cx:dx	= pointer to array of MailboxDataFormat descriptors
		bp	= transaction handle
RETURN:		if format selected:
			cxdx	= MailboxDataFormat to use
		if no format acceptable:
			cx, dx	= 0
			transaction canceled
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCChooseFormat method dynamic MailboxSendControlClass, 
				MSG_MAILBOX_SEND_CONTROL_CHOOSE_FORMAT
		.enter
		Assert	transHandle, bp
		Assert	fptr, cxdx
	;
	; Figure how many entries there are in the passed array, since the
	; driver insists on being told this.
	; 
		movdw	esdi, cxdx
		clr	cx
countLoop:
	CheckHack <MANUFACTURER_ID_GEOWORKS eq 0 and GMDFID_INVALID eq 0>
		mov	ax, es:[di].MDF_manuf
		or	ax, es:[di].MDF_id
		jz	haveCount

		inc	cx
		add	di, size MailboxDataFormat
		jmp	countLoop
haveCount:
	;
	; Now load the transport driver for the transaction.
	; 
		push	ds, si			; save MSC for possible
						;  cancelation
		push	cx			; save count
		pushdw	esdx			; and  format array
		mov	di, ds:[bp]
		movdw	cxdx, ds:[di].MSCT_transport
		call	MailboxLoadTransportDriver
		jc	cannotLoadTD
	;
	; Driver loaded. Set up registers and call the CHOOSE_FORMAT function
	; 
		call	GeodeInfoDriver
		mov_tr	ax, bx
		popdw	cxdx
		pop	bx
		push	ax			; save driver handle
		mov	di, DR_MBTD_CHOOSE_FORMAT
		call	ds:[si].DIS_strategy
	;
	; Regardless of outcome, free the transport driver.
	; 
		pop	bx
		call	MailboxFreeDriver
		pop	ds, si			; *ds:si <- MSC
		mov	bx, offset uiNoFormatAcceptableStr	; assume failure
		cmp	ax, -1
		je	cancelTrans		; => no format acceptable
	;
	; Return the format the caller should use.
	; 
		movdw	esdi, cxdx
			CheckHack <size MailboxDataFormat eq 4>
		shl	ax
		shl	ax
		add	di, ax
		movdw	cxdx, es:[di]
done:
		.leave
		ret

cannotLoadTD:
	;
	; Couldn't load the transport driver: clear the stack of extraneous
	; cruft and tell the user about it.
	; 
		add	sp, 6		; es:dx, cx cleared
		pop	ds, si
		mov	bx, offset uiCannotLoadTransportStr

cancelTrans:
	;
	; Let the user know something's amiss, according to the string handle
	; we've got in BX here.
	; 
		push	ds:[LMBH_handle]
		clr	ax
		pushdw	axax		; SDOP_helpContext
		pushdw	axax		; SDOP_customTriggers
		pushdw	axax		; SDOP_stringArg2
		pushdw	axax		; SDOP_stringArg1
		mov	ax, handle ROStrings
		pushdw	axbx		; SDOP_customString
		mov	ax, CustomDialogBoxFlags <
			0,		; CDBF_SYSTEM_MODAL
			CDT_ERROR,	; CDBF_DIALOG_TYPE
			GIT_NOTIFICATION,
			0		; CDBF_DESTRUCTIVE_ACTION
		>
		push	ax
		call	UserStandardDialogOptr
	;
	; Now cancel the transaction.  Clear the MSCTF_NOTIFY_AFTER_REGISTER
	; bit first because MSCT_bodyRef isn't there yet.
	; 
		pop	bx
		call	MemDerefDS
		mov	di, ds:[bp]	; ds:di = MSCTransaction
		BitClr	ds:[di].MSCT_flags, MSCTF_NOTIFY_AFTER_REGISTER
		mov	ax, MSG_MAILBOX_SEND_CONTROL_CANCEL_MESSAGE
		clr	dx		; notify user
		call	ObjCallInstanceNoLock
	;
	; Return cxdx = 0_0 to signal error
	; 
		clrdw	cxdx
		jmp	done
MSCChooseFormat endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCCancelMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Abort the creation of a message.

CALLED BY:	MSG_MAILBOX_SEND_CONTROL_CANCEL_MESSAGE
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
		dx	= 0 if user should be notified, -1 if not
		bp	= transaction handle
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCCancelMessage method dynamic MailboxSendControlClass, 
					MSG_MAILBOX_SEND_CONTROL_CANCEL_MESSAGE
		.enter
	;
	; If necessary, let the output know of the cancelation
	; so it can biff the thing.
	;
		Assert	transHandle, bp
		mov	ax, ME_USER_CANCELED
		Assert	inList, dx, <0, -1>
		stc
		call	MSCNotifyOutputOfRegistration

		mov	ax, MSG_MSD_CANCEL_TRANSACTION
		call	MSCDeleteTransaction
		.leave
		ret
MSCCancelMessage endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCDeleteTransaction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get rid of a transaction, either successfully or because
		it was canceled. Take care of whatever pending dialog
		nuking etc. is waiting if this is the final transaction

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= MailboxSendControl
		*ds:bp	= MSCTransaction to biff
		ax	= message to call on the MailboxSendDialog to
			  have it clean up
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp
SIDE EFFECTS:	TEMP_MAILBOX_SEND_CONTROL_DESTROY_DIALOG_PENDING may be
     			deleted
		MSG_META_ACK may be sent

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCDeleteTransaction proc	near
		class	MailboxSendControlClass
		.enter
	;
	; Dismiss the dialog box, if it's up and won't be brought down by
	; someone else.
	;
		Assert	transHandle, bp
		mov	bx, ds:[bp]
		test	ds:[bx].MSCT_flags, mask MSCTF_DIALOG_COMPLETE
		jnz	unlinkTrans
		
		mov	bx, ds:[bx].MSCT_dataBlock
		push	si, bp, ax
		mov	si, offset MSCSendDialog
		mov	cx, IC_INTERACTION_COMPLETE
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	si, bp, ax

unlinkTrans:
		DerefDI	MailboxSendControl
	;
	; Find the thing that points to the transaction so we can unlink the
	; beast from the chain.
	; 
			CheckHack <offset MSCT_next eq 0>
		lea	bx, ds:[di].MSCI_transactions
findPrevLoop:
		cmp	ds:[bx].MSCT_next, bp
		je	foundPrev
		mov	bx, ds:[bx].MSCT_next
		mov	bx, ds:[bx]
		jmp	findPrevLoop

foundPrev:
	;
	; Remove the transaction from the chain.
	; 
		mov	di, ds:[bp]
		mov	di, ds:[di].MSCT_next	; *ds:di <- thing that follows
						;  the one being biffed
		mov	ds:[bx].MSCT_next, di
	;
	; Now let the dialog box know what's up.
	; ax = message to send
	; 
		mov	bx, ds:[bp]
		mov	bx, ds:[bx].MSCT_dataBlock

		push	si
		mov	si, offset MSCSendDialog
		mov	dx, ds			; *dx:bp <- transaction
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		push	bp
		call	ObjMessage
		pop	bp
		pop	si
	;
	; If this was the last transaction for the dialog, and the dialog is
	; long since gone, free the block.
	;
		call	MSCMaybeFreeDialogBlock
	;
	; See if there are any more transactions pending -- there's some stuff
	; we have to do if not.
	; 
		DerefDI	MailboxSendControl
		tst	ds:[di].MSCI_transactions
		jnz	freeThings
	;
	; No more transactions pending. Yea! Nuke the dialog if it was waiting
	; for this golden moment.
	; 
		mov	ax, TEMP_MAILBOX_SEND_CONTROL_DESTROY_DIALOG_PENDING
		call	ObjVarFindData
		jnc	freeThings		; can't be detaching if this
						;  vardata not present, so
						;  we're done
		
		call	ObjVarDeleteDataAt
		call	MSCNukeDialog
	;
	; If we attempted to detach, but couldn't because there were pending
	; transactions, send ourselves the MSG_META_ACK for which we wait.
	; 
		mov	ax, DETACH_DATA
		call	ObjVarFindData
		jnc	freeThings

		mov	ax, MSG_META_ACK
		push	bp
		call	ObjCallInstanceNoLock
		pop	bp
freeThings:
	;
	; Finally, free the transaction chunk and the chunks it points to.
	; 
		mov	bx, ds:[bp]
		mov	ax, ds:[bx].MSCT_bodyRef
		tst	ax
		jz	freeSummary
		call	LMemFree
freeSummary:
		mov	ax, ds:[bx].MSCT_summary
		tst	ax
		jz	freeTrans
		call	LMemFree
freeTrans:
		mov_tr	ax, bp
		call	LMemFree
		.leave
		ret
MSCDeleteTransaction endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCTransactionFinished
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that a transaction is complete.

CALLED BY:	MSG_MAILBOX_SEND_CONTROL_TRANSACTION_FINISHED
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
		bp	= transaction chunk
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	transaction chunk is freed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCTransactionFinished method dynamic MailboxSendControlClass, 
				MSG_MAILBOX_SEND_CONTROL_TRANSACTION_FINISHED
		.enter
		mov	ax, MSG_MSD_TRANSACTION_COMPLETE
		call	MSCDeleteTransaction
		.leave
		ret
MSCTransactionFinished endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCRegisterMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register the created message with the outbox.

CALLED BY:	MSG_MAILBOX_SEND_CONTROL_REGISTER_MESSAGE
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
		cx:dx	= MSCRegisterMessageArgs
		bp	= transaction handle
RETURN:		carry set on error:
			ax	= MailboxError
			dx	= 0
		carry clear if ok:
			dxax	= MailboxMessage
DESTROYED:	cx
SIDE EFFECTS:	chunks are allocated for the body reference and summary
     		the transaction is completed if all info is now available

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCRegisterMessage method dynamic MailboxSendControlClass, 
				MSG_MAILBOX_SEND_CONTROL_REGISTER_MESSAGE
		.enter
	;
	; Flag creation complete.
	;
		Assert	transHandle, bp
		mov	bx, ds:[bp]
		andnf	ds:[bx].MSCT_flags, not mask MSCTF_CREATION_PENDING

		push	si
		segmov	es, ds
		movdw	dssi, cxdx
	;
	; Copy all the random fixed-size pieces from the passed arguments into
	; the transaction chunk.
	; 
		CheckHack <MSCRMA_bodyStorage eq 0>
		
		CheckHack <MSCRMA_bodyFormat - MSCRMA_bodyStorage eq \
				MSCT_bodyFormat - MSCT_bodyStorage>
		CheckNextField MSCT_bodyFormat, MSCT_bodyStorage
		CheckHack <type MSCT_bodyFormat eq 4>
		CheckHack <type MSCT_bodyStorage eq 4>

		lea	di, ds:[bx].MSCT_bodyStorage
		movsw		; bodyStorage.id
		movsw		; bodyStorage.manuf
		movsw		; bodyFormat.id
		movsw		; bodyFormat.manuf

			CheckNextField MSCT_messageFlags, MSCT_bodyFormat
		add	si, offset MSCRMA_flags - (offset MSCRMA_bodyFormat + \
				size MSCRMA_bodyFormat)
		movsw		; messageFlags
		
			CheckNextField MSCT_destApp, MSCT_messageFlags
		add	si, offset MSCRMA_destApp - (offset MSCRMA_flags + \
				size MSCRMA_flags)
		movsw		; destApp.GT_chars[0..1]
		movsw		; destApp.GT_chars[2..3]
		movsw		; destApp.GT_manufID

			CheckNextField MSCT_startBound, MSCT_destApp
			CheckNextField MSCRMA_startBound, MSCRMA_destApp
		movsw		; startBound.date
		movsw		; startBound.time

			CheckNextField MSCT_endBound, MSCT_startBound
			CheckNextField MSCRMA_endBound, MSCRMA_startBound
		movsw		; endBound.date
		movsw		; endBound.time

	;
	; Cope with body ref & summary being in the controller's own block.
	;
		mov	si, dx
		movdw	cxdx, ds:[si].MSCRMA_summary
		call	MSCCopeWithLMemPtr
		push	bx, cx, dx

		movdw	cxdx, ds:[si].MSCRMA_bodyRef
		call	MSCCopeWithLMemPtr
	;
	; Copy the body reference into a chunk.
	;
		push	cx, bx			; save ptr info
		mov	cx, ds:[si].MSCRMA_bodyRefLen
		push	ds
		segmov	ds, es
		mov	al, mask OCF_DIRTY
		call	LMemAlloc
		
		mov	bx, ds:[bp]
		mov	ds:[bx].MSCT_bodyRef, ax
		pop	ds
		pop	di, bx			; di <- 0/ref segment
						; bx <- chunk handle/junk
		
		push	ds, si
		movdw	dssi, didx
		tst	di
		jnz	haveBodyRefPtr		
		segmov	ds, es
		add	si, ds:[bx]
haveBodyRefPtr:
		mov_tr	di, ax
		mov	di, es:[di]
		rep	movsb
		pop	ds, si
	;
	; Copy the message summary into a chunk.
	;
		call	MSCGetSummaryAddr
		push	es
		movdw	esdi, cxdx
		call	LocalStringSize
		pop	es

		push	ds
		segmov	ds, es
		inc	cx
DBCS <		inc	cx						>
		mov	al, mask OCF_DIRTY
		call	LMemAlloc
		mov	bx, ds:[bp]
		mov	ds:[bx].MSCT_summary, ax
		pop	ds
		
		mov	di, cx			; di <- summary len
		call	MSCGetSummaryAddr
		movdw	dssi, cxdx
		mov	cx, di
		mov_tr	di, ax
		mov	di, es:[di]
		rep	movsb

		add	sp, 6			; clear summary ptr info
	;
	; Notify the address control that the message body is now available,
	; if the address control exists.
	;
		segmov	ds, es
		pop	si			; *ds:si <- MSC

		mov	ax, ds:[bx].MSCT_addrControl
		tst	ax
		jz	addrCtrlHandled
		
		push	si, bp
		mov	bx, ds:[bx].MSCT_dataBlock
		mov_tr	si, ax
		mov	ax, MSG_MAILBOX_ADDRESS_CONTROL_BODY_AVAILABLE
		mov	dx, ds
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	si, bp

		mov	bx, ds:[bp]

addrCtrlHandled:
if	_OUTBOX_FEEDBACK
		tst	ds:[bx].MSCT_feedback.handle
		jz	checkComplete
		
		call	MSCNotifyFeedbackOfSummary
checkComplete:
endif	; _OUTBOX_FEEDBACK

	;
	; If we have addresses, complete the transaction.
	;
		tst	ds:[bx].MSCT_addresses
		jz	done
		
		mov	ax, MSG_MAILBOX_SEND_CONTROL_COMPLETE_TRANSACTION
		call	ObjCallInstanceNoLock
done:
		.leave
		ret

MSCRegisterMessage endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCNotifyFeedbackOfSummary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the feedback box know ASAP what the message summary
		is, so it can use it in its feedback...

CALLED BY:	(INTERNAL) MSCRegisterMessage, 
			   MSDCreateFeedbackBox
PASS:		ds:bx	= MSCTransaction with MSCT_summary and MSCT_feedback
			  valid
RETURN:		nothing
DESTROYED:	ds:bx may be invalidated
		es if == ds on entry
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/22/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_OUTBOX_FEEDBACK
MSCNotifyFeedbackOfSummary proc	near
		uses	ax, cx, dx, bx, si, di, bp
		.enter
	;
	; Fetch the summary and feedback block from the transaction.
	;
		mov	dx, ds:[bx].MSCT_summary
		push	ds:[bx].MSCT_feedback.chunk
		mov	bx, ds:[bx].MSCT_feedback.handle
	;
	; We need to ask the burden thread of the feedback box to copy the
	; chunk in, since the summary's in an object block that cannot be
	; locked down from another thread, alas.
	;
		mov	ax, MGIT_EXEC_THREAD
		call	MemGetInfo
		xchg	bx, ax			; bx <- burden thread
						; ax <- dest block

		sub	sp, size CopyChunkInFrame
		mov	bp, sp
		mov	ss:[bp].CCIF_destBlock, ax	; set dest of copy
		mov	si, dx
		mov	si, ds:[si]		; ds:si <- src chunk
		movdw	ss:[bp].CCIF_source, dssi
		push	ax
			CheckHack <offset CCF_SIZE eq 0>
		ChunkSizePtr ds, si, ax
		Assert	bitClear, ax, <CopyChunkFlags and not mask CCF_SIZE>
	    ;
	    ; Use FPTR mode for the copy, so it doesn't have to lock down the
	    ; object block.
	    ;
		ornf	ax, (CCM_FPTR shl offset CCF_MODE) or mask CCF_DIRTY
		mov	ss:[bp].CCIF_copyFlags, ax
		mov	ax, MSG_PROCESS_COPY_CHUNK_IN
		mov	dx, size CopyChunkInFrame
		mov	di, mask MF_FIXUP_DS or mask MF_CALL or mask MF_STACK
		call	ObjMessage

	;
	; Now tell the feedback box what the summary is.
	;
		pop	bx			; bx <- feedback block
		add	sp, size CopyChunkInFrame

		mov	cx, bx			; ^lcx:dx <- summary
		mov_tr	dx, ax
		pop	si			; ^lbx:si <- feedback box
		mov	ax, MSG_OFN_SET_SUMMARY
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
		.leave
		ret
MSCNotifyFeedbackOfSummary endp
endif	; _OUTBOX_FEEDBACK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCCopeWithLMemPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cope with having the body reference or the summary for the
		message in an lmem chunk with the controller by figuring at
		what offset in what chunk the thing is located and returning
		stuff so MSCRegisterMessage can find the thing again.

CALLED BY:	(INTERNAL) MSCRegisterMessage
PASS:		cx:dx	= pointer to data
		es	= controller's object block
RETURN:		if cx == 0:
			pointer is in object block
			*es:bx	= base of chunk containing the data
			dx	= offset into chunk where data lie
		if cx != 0:
			cx:dx	= pointer to data
			bx	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/25/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCCopeWithLMemPtr proc near
		uses	di
		.enter
		mov	bx, es
		cmp	bx, cx
		jne	done
		mov	bx, es:[LMBH_offset]
		mov	cx, es:[LMBH_nHandles]
chunkLoop:
		mov	di, es:[bx]
		inc	di			; allocated but empty?
		jz	nextChunk		; => yes, so can't be it
		dec	di			; free handle?
		jz	nextChunk		; => yes
		cmp	di, dx			; chunk starts beyond data?
		ja	nextChunk		; => yes
		add	di, es:[di].LMC_size
		dec	di
		dec	di			; di <- end of chunk
		cmp	di, dx			; chunk ends beyond data?
		ja	found			; => yes, so found our chunk

nextChunk:
		inc	bx			; advance to next chunk handle
		inc	bx
		loop	chunkLoop
EC <		ERROR	POINTER_TO_CONTROLLER_BLOCK_DOESNT_POINT_TO_ANY_CHUNK>
NEC <		mov	cx, es			; pretend not in obj seg>
NEC <		jmp	done						>

found:
		sub	dx, es:[bx]		; dx <- offset w/in chunk
		clr	cx			; cx <- in obj segment
done:
		.leave
		ret
MSCCopeWithLMemPtr endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCGetSummaryAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look at stuff saved for summary from MSCCopeWithLMemPtr
		and return the pointer to the summary

CALLED BY:	(INTERNAL) MSCRegisterMessage
PASS:		ds:si	= MSCRegisterMessageArgs
		on stack (pushed in this order):
			possible chunk handle (bx from MSCCopeWithLMemPtr)
			fptr to data/0:chunk offset (cx:dx from
				MSCCopeWithLMemPtr)
RETURN:		cx:dx	= pointer to summary
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/25/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
.model medium, C
MSCGetSummaryAddr	proc	near	sumPtr:fptr, sumChunk:word
		.enter
		movdw	cxdx, ss:[sumPtr]
		jcxz	inObjSeg
done:
		.leave
		ret

inObjSeg:
		push	si
		mov	si, ss:[sumChunk]
		add	dx, es:[si]
		mov	cx, es		; cx <- cur obj seg
		pop	si
		jmp	done
MSCGetSummaryAddr endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCGetAddresses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the addresses and complete the dialog. If don't have
		message body yet, ask for it.

CALLED BY:	MSG_MAILBOX_SEND_CONTROL_GET_ADDRESSES
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
		ds:[di].MSCI_transactions = current transaction
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/24/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCGetAddresses method dynamic MailboxSendControlClass, 
				MSG_MAILBOX_SEND_CONTROL_GET_ADDRESSES
		.enter
	;
	; Make sure initial transaction is good for us to abuse.
	;
		mov	bp, ds:[di].MSCI_transactions
EC <		Assert	transHandle, bp					>
		mov	bx, ds:[bp]
EC <		Assert	e, ds:[bx].MSCT_addresses, 0			>
	;
	; Call the dialog box to fetch the addresses.
	;
		mov	bx, ds:[bx].MSCT_dataBlock
		
		push	si
		push	bp
		mov	dx, ds			; *dx:bp <- transaction
		mov	ax, MSG_MSD_GET_ADDRESSES
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	si, offset MSCSendDialog
		call	ObjMessage
		pop	bp
		jc	popDone			; => addresses invalid, so
						;  leave dialog up
	;
	; Take down the dialog, please, if necessary.
	;
		mov	di, ds:[bp]
		test	ds:[di].MSCT_flags, mask MSCTF_DIALOG_COMPLETE
		jnz	maybeComplete

		ornf	ds:[di].MSCT_flags, mask MSCTF_DIALOG_COMPLETE
		mov	cx, IC_INTERACTION_COMPLETE
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
maybeComplete:
	;
	; If we don't have the message body and aren't waiting to receive it,
	; start its creation going.
	;
	; If we have the message body, complete the transaction.
	; 
		pop	si

		mov	di, ds:[bp]
		tst	ds:[di].MSCT_bodyRef
		jnz	complete		; => have body, so finish
						;  transaction
		test	ds:[di].MSCT_flags, mask MSCTF_CREATION_PENDING
		jnz	done			; => waiting for body, so
						;  keep waiting
		
		mov	ax, MSG_MAILBOX_SEND_CONTROL_CREATE_BODY
		call	ObjCallInstanceNoLock
		jmp	done
		
popDone:
		pop	si			; *ds:si <- MSC
done:		
		.leave
		ret

complete:
		mov	ax, MSG_MAILBOX_SEND_CONTROL_COMPLETE_TRANSACTION
		call	ObjCallInstanceNoLock
		jmp	done
MSCGetAddresses endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCCompleteTransaction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to register a message from the transaction chunk.

CALLED BY:	MSG_MAILBOX_SEND_CONTROL_COMPLETE_TRANSACTION
PASS:		*ds:si	= MailboxSendControl
		*ds:bp	= MSCTransaction
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/24/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCCompleteTransaction method	MailboxSendControlClass,
	       			MSG_MAILBOX_SEND_CONTROL_COMPLETE_TRANSACTION
		.enter
	;
	; Cheating way to get the number of addresses we need, so I don't have
	; to mess with segment registers more than I have to...
	; 
		mov	bx, ds:[bp]
		mov	bx, ds:[bx].MSCT_dataBlock
		call	ObjLockObjBlock
		mov	es, ax
   		mov	bx, ds:[bp]
		mov	bx, ds:[bx].MSCT_addresses
		mov	bx, es:[bx]
		mov	ax, es:[bx].CAH_count
		mov	cx, ax		; save count for MRA_numTransAddrs
	;
	; Compute the number of bytes needed to hold the trans addrs
	; 
			CheckHack <size MailboxTransAddr eq 10>
		shl	ax
		mov	bx, ax
		shl	ax
		shl	ax
		add	ax, bx
	;
	; Add in the size of the MRMA and allocate that much on the stack
	; XXX: SHOULD THIS JUST BE IN A BLOCK OF MEMORY, TO AVOID WORRIES
	; ABOUT HAVING TOO MANY ADDRESSES?
	; 
		add	ax, size MailboxRegisterMessageArgs
		sub	sp, ax
		mov	bx, bp		; *ds:bx <- transaction
		mov	bp, sp		; ss:bp <- MRMA
		push	ax		; save # bytes allocated on stack for
					;  clearing it at the end
		push	si		; save MSC for later
		mov	di, ds:[bx]	; ds:di <- MSCTransaction
	;
	; Copy all the random pieces from the transaction into the args
	; we'll be giving to MailboxRegisterMessage.
	; 
		movdw	ss:[bp].MRA_bodyStorage, ds:[di].MSCT_bodyStorage, ax

		movdw	ss:[bp].MRA_bodyFormat, ds:[di].MSCT_bodyFormat, ax

		mov	si, ds:[di].MSCT_bodyRef
		mov	si, ds:[si]
		ChunkSizePtr	ds, si, ax
		movdw	ss:[bp].MRA_bodyRef, dssi
		mov	ss:[bp].MRA_bodyRefLen, ax

	;
	; Copy in things from the transaction chunk.
	; 
		movdw	ss:[bp].MRA_transport, ds:[di].MSCT_transport, ax

		mov	ax, ds:[di].MSCT_transOption
		mov	ss:[bp].MRA_transOption, ax
	;
	; Point to where the addresses will be set up.
	; 
		lea	ax, ss:[bp+size MailboxRegisterMessageArgs]
		movdw	ss:[bp].MRA_transAddrs, ssax

		mov	ss:[bp].MRA_numTransAddrs, cx

		movdw	ss:[bp].MRA_transData, ds:[di].MSCT_transData, ax
	;
	; More shme from the passed args
	; 
		mov	ax, ds:[di].MSCT_messageFlags
		mov	ss:[bp].MRA_flags, ax

		mov	si, ds:[di].MSCT_summary
		mov	si, ds:[si]
		movdw	ss:[bp].MRA_summary, dssi

		mov	ax, {word}ds:[di].MSCT_destApp.GT_chars[0]
		mov	{word}ss:[bp].MRA_destApp.GT_chars[0], ax
		mov	ax, {word}ds:[di].MSCT_destApp.GT_chars[2]
		mov	{word}ss:[bp].MRA_destApp.GT_chars[2], ax
		mov	ax, ds:[di].MSCT_destApp.GT_manufID
		mov	ss:[bp].MRA_destApp.GT_manufID, ax

		movdw	ss:[bp].MRA_startBound, ds:[di].MSCT_startBound, ax

		movdw	ss:[bp].MRA_endBound, ds:[di].MSCT_endBound, ax
	;
	; Set up the MailboxTransAddr structures from the array.
	; 
		call	MSCPointToAddresses
	;
	; Call our subclass to adjust the parameters as desired.
	; 
		pop	si		; *ds:si <- MailboxSendControl
		mov	dx, bp
		mov	cx, ss		; cx:dx <- MailboxRegisterMessageArgs
		mov	bp, bx		; *ds:bp <- transaction chunk
		mov	ax, MSG_MAILBOX_SEND_CONTROL_TWEAK_PARAMS
		push	dx, bp		; save params & transaction
		call	ObjCallInstanceNoLockES

		pop	bp, bx		; ss:bp <- params, *ds:bx <- transaction
	;
	; If there's an address controller, give it a shot, now.
	; 
		push	si
		mov	si, ds:[bx]
		mov	si, ds:[si].MSCT_addrControl
		tst	si
		jz	registerItMahn

		segxchg	ds, es		; *ds:si <- addr control. es <- ds so
					;  it can be properly fixed up, if
					;  necessary
		push	bp		; save params
		mov	cx, ss
		mov	dx, bp		; cx:dx <- MailboxRegisterMessageArgs
		mov	ax, MSG_MAILBOX_ADDRESS_CONTROL_TWEAK_PARAMS
		call	ObjCallInstanceNoLockES
		segxchg	ds, es		; ds <- MSC block
					; es <- MSD block
		pop	bp		; ss:bp <- MailboxRegisterMessageArgs
registerItMahn:
		pop	si		; *ds:si <- MSC
		call	MSCPointToAddresses	; in case the block moved or
						;  something
	;
	; Finally, call MailboxRegisterMessage
	; 
		mov	cx, ss
		mov	dx, bp		; cx:dx <- args
		call	MailboxRegisterMessage
	;
	; Clear the stack and unlock the dialog block before we check for an
	; error.
	; 
		pop	di		; di <- # bytes allocated on the stack
		lea	sp, ss:[bp+di]
		mov	bp, bx		; *ds:bp <- transaction
		mov	bx, es:[LMBH_handle]
		call	MemUnlock
		jnc	notify
		mov	dx, 0		; notify user of failure (CF preserved)
notify:
		call	MSCNotifyOutputOfRegistration
		jc	err
	;
	; Registration succeeded, so call ourselves to say the transaction is
	; done.
	; 
		pushdw	dxax
		mov	ax, MSG_MAILBOX_SEND_CONTROL_TRANSACTION_FINISHED
		call	ObjCallInstanceNoLock
		popdw	dxax
		clc
done:
		.leave
		ret
err:
	;
	; Registration failed, so call ourselves to cancel the transaction.
	; 
		push	ax
		mov	ax, MSG_MAILBOX_SEND_CONTROL_CANCEL_MESSAGE
		clr	dx		; notify user
		call	ObjCallInstanceNoLock
		pop	ax
		clr	dx		; return dx 0 so C can figure if there
					;  was an error
		stc
		jmp	done
MSCCompleteTransaction endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCNotifyOutputOfRegistration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the transaction is so marked, let the output know the
		result of the registration.

CALLED BY:	(INTERNAL) MSCCompleteTransaction
PASS:		*ds:bp	= MSCTransaction
		*ds:si	= MailboxSendControl
		carry set:
			dx	= 0 if user should be notified, -1 if not
			ax	= MailboxError
		carry clear:
			dxax	= MailboxMessage
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/26/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCNotifyOutputOfRegistration proc	near
		class	MailboxSendControlClass
		uses	bx, cx, dx, ax, bp, di
		.enter
		pushf
		mov	bx, ds:[bp]
if	_OUTBOX_FEEDBACK
		tst	ds:[bx].MSCT_feedback.handle
		jz	checkNotify
	;
	; Feedback box is up -- tell it of the result of registration.
	;
		push	cx, dx, si
		MovMsg	cxdx, dxax
		mov	si, ds:[bx].MSCT_feedback.chunk
		mov	bx, ds:[bx].MSCT_feedback.handle
		mov	ax, MSG_OFN_SET_MESSAGE
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		MovMsg	dxax, cxdx
		pop	cx, dx, si
		mov	bx, ds:[bp]
checkNotify:
endif	; _OUTBOX_FEEDBACK

	;
	; See if we need to send notification following registration
	;
		test	ds:[bx].MSCT_flags, mask MSCTF_NOTIFY_AFTER_REGISTER
		LONG jz	done
	;
	; See if we've actually received the body.
	;
		tst	ds:[bx].MSCT_bodyRef
		LONG jz done
	;
	; Clear the notification flag so when MSCCompleteTransaction cancels the
	; message, we don't generate another notification.
	;
		andnf	ds:[bx].MSCT_flags, not mask MSCTF_NOTIFY_AFTER_REGISTER
	;
	; We do. Figure how big the body reference is so we can allocate a
	; block to hold it and the other stuff.
	;
		mov	di, ds:[bx].MSCT_bodyRef
		push	ax
		ChunkSizeHandle ds, di, ax
	;
	; Allocate a sharable block to hold the MSCMessageRegisteredArgs and
	; the body reference.
	;
		add	ax, size MSCMessageRegisteredArgs
		mov	cx, mask HF_SHARABLE or ALLOC_DYNAMIC_NO_ERR_LOCK
		push	ax
		call	MemAlloc
		pop	cx			; cx <- allocated size, for
						;  getting body ref size again
	;
	; Copy the body reference to the end of the notification block.
	;
		mov	es, ax			; es <- notification args
		push	si
		mov	si, ds:[di]
		mov	di, offset MSCMRA_bodyRef
		sub	cx, size MSCMessageRegisteredArgs
		mov	es:[MSCMRA_bodyRefLen], cx
		rep	movsb
		pop	si
	;
	; Start the reference count for the block off at 1 so it will be
	; freed by the MSG_META_DEC_BLOCK_REF_COUNT we'll be sending off in
	; a moment.
	;
		mov	ax, 1
		call	MemInitRefCount
		mov	cx, bx			; cx <- handle for notification
	;
	; Copy the other body parameters out of the transaction into the
	; notification block so the recipient has all the info it needs to
	; clean up.
	;
		mov	bx, ds:[bp]
		movdw	es:[MSCMRA_bodyStorage], ds:[bx].MSCT_bodyStorage, ax
		movdw	es:[MSCMRA_bodyFormat], ds:[bx].MSCT_bodyFormat, ax
		pop	ax			; ax <- error or msg.low
	;
	; Figure what to put in the _error and _message fields of the
	; notification data. We end up with dxdi = message (ok) /0 (error), and
	; ax = ME_SUCCESS (ok) / error code (error)
	;
		mov	di, ax			; dxdi <- msg
		popf				; CF <- error indicator
		pushf				; save for popping at the end
		jc	haveErr
			CheckHack <ME_SUCCESS eq 0>
		clr	ax			; error code <- ME_SUCCESS,
						;  since ok
		jmp	setMsgAndErr

haveErr:
		clr	dx, di			; msg <- 0 since error

setMsgAndErr:
		mov	es:[MSCMRA_error], ax
		movdw	es:[MSCMRA_message], dxdi
		mov	bx, cx
		call	MemUnlock
	;
	; Fetch the controller output so we can push it twice, once for each
	; message we're sending out.
	;
		DerefDI	GenControl
		movdw	bxax, ds:[di].GCI_output
		pushdw	bxax			; for DEC_BLOCK_REF_COUNT
		pushdw	bxax			; for MESSAGE_REGISTERED
	;
	; Notify the output that the thing is registered.
	;
		mov	ax, MSG_META_MAILBOX_MESSAGE_REGISTERED
		mov	di, mask MF_FIXUP_DS
		call	GenProcessAction
	;
	; Ask the output (via MetaClass) to free the notification block.
	;
		mov	ax, MSG_META_DEC_BLOCK_REF_COUNT
		clr	dx			; dx <- no second block
		mov	di, mask MF_FIXUP_DS
		call	GenProcessAction
done:
		popf
		.leave
		ret
MSCNotifyOutputOfRegistration endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCPointToAddresses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Point the array of addresses in the MailboxRegisterMessageArgs
		to the proper places within the chunk array of addresses.

CALLED BY:	(INTERNAL) MSCRegisterMessage, PSDSendMessage
PASS:		*ds:bx	= MSCTransaction
		ss:bp	= MailboxRegisterMessageArgs
		es	= segment of dialog block
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCPointToAddresses proc	far
		uses	bx, ds, si, di, bp, ax, es
		.enter
		Assert	stackFrame, bp
		mov	bx, ds:[bx]
		mov	si, ds:[bx].MSCT_addresses
		segmov	ds, es
		mov	es, ss:[bp].MRA_transAddrs.segment
		mov	bp, ss:[bp].MRA_transAddrs.offset
		mov	bx, SEGMENT_CS
		mov	di, offset MSCPointToAddressesCallback
		call	ChunkArrayEnum
		.leave
		ret
MSCPointToAddresses endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCPointToAddressesCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to set up a single address

CALLED BY:	(INTERNAL) MSCPointToAddresses via ChunkArrayEnum
PASS:		ds:di	= MBACAddress to use
		es:bp	= MailboxTransAddr to set
		ax	= size of the address element
RETURN:		carry set to stop enumerating (always clear)
		ss:bp	= next address to set
DESTROYED:	ax (bx, si, di allowed)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCPointToAddressesCallback proc	far
		.enter
		mov	bx, ds:[di].MBACA_opaqueSize
		mov	es:[bp].MTA_transAddrLen, bx

		lea	ax, ds:[di].MBACA_opaque[bx]
		movdw	es:[bp].MTA_userTransAddr, dsax

			CheckHack <offset MBACA_opaque eq 2>
		inc	di
		inc	di
		movdw	es:[bp].MTA_transAddr, dsdi

		add	bp, size MailboxTransAddr
		clc
		.leave
		ret
MSCPointToAddressesCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCReplyToMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Brings up the message-creation dialog based on the transport,
		transport option and addresses bound to the indicated message.

CALLED BY:	MSG_MAILBOX_SEND_CONTROL_REPLY_TO_MESSAGE
PASS:		*ds:si	= MailboxSendControlClass object
		cxdx	= MailboxMessage
RETURN:		carry set if error
			ax	= MailboxError
		carry clear if no error
			ax - destroyed
DESTROYED:	cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	2/ 2/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCReplyToMessage	method dynamic MailboxSendControlClass, 
				MSG_MAILBOX_SEND_CONTROL_REPLY_TO_MESSAGE
selfPtr		local	dword		push	ds, si
msg		local	MailboxMessage	push	cx, dx
mediaTransport	local	MailboxMediaTransport
mapArgs		local	MBTDMediumMapArgs
	.enter

	;
	; See if message has exactly one address.
	;
	call	MessageLockCXDX		; *ds:di = MailboxMessageDesc
	LONG jc	done
	mov	di, ds:[di]
	mov	si, ds:[di].MMD_transAddrs
	call	ChunkArrayGetCount	; cx = # of addrs
EC <	cmp	cx, 1							>
EC <	WARNING_NE MESSAGE_TO_REPLY_TO_DOESNT_HAVE_EXACTLY_ONE_ADDR	>
	mov	ax, ME_REPLY_ADDRESS_NOT_AVAILABLE
	LONG jcxz errorUnlock		; ignore if no address

	;
	; Get transport and transport option.
	;
	mov	ax, ds:[di].MMD_transOption
	mov	ss:[mediaTransport].MMT_transOption, ax
	mov	ss:[mapArgs].MBTDMMA_transOption, ax
	movdw	cxdx, ds:[di].MMD_transData	; transport of inbox message is
						;  stored in MMD_transData
	movdw	ss:[mediaTransport].MMT_transport, cxdx

	call	MailboxLoadTransportDriver	; bx = driver handle
	mov	ax, ME_CANNOT_LOAD_TRANSPORT_DRIVER
	jc	errorUnlock

	;
	; Fill in MBTDMediumMapArgs for calling driver.
	;
	clr	ax			; get first address
	call	ChunkArrayElementToPtr	; ds:di = MailboxInternalTransAddr
	mov	ax, ds:[di].MITA_opaqueLen
	mov	ss:[mapArgs].MBTDMMA_transAddrLen, ax
	lea	ax, ds:[di].MITA_opaque
	movdw	ss:[mapArgs].MBTDMMA_transAddr, dsax

	;
	; Call transport driver to get medium.
	;
	segmov	es, ds			; es = message block
	call	GeodeInfoDriver		; ds:si = MBTDInfo
	mov	di, DR_MBTD_GET_ADDRESS_MEDIUM
	mov	cx, ss
	lea	dx, ss:[mapArgs]
	call	ds:[si].MBTDI_common.DIS_strategy	; CF set if error
	lahf
	call	MailboxFreeDriver
	sahf
	segmov	ds, es			; ds = message block
	call	UtilVMUnlockDS		; unlock message, flags preserved
	mov	ax, ME_ADDRESS_INVALID
	jc	done

	movdw	ss:[mediaTransport].MMT_medium, ss:[mapArgs].MBTDMMA_medium, ax

	;
	; Put up dialog box.
	;
	movdw	dssi, ss:[selfPtr]
	mov	ax, MSG_MAILBOX_SEND_CONTROL_INITIATE_DIALOG_WITH_TRANSPORT
	push	bp
	lea	bp, ss:[mediaTransport]	; ss:bp = MailboxMediaTransport
	call	ObjCallInstanceNoLock
	pop	bp

	;
	; Tell the send dialog to use the address of the original message.
	;
	call	MSCGetDialogBlock	; bx = send dialog hptr
	mov	si, offset MSCSendDialog
	mov	ax, MSG_MSD_SET_ADDRESSES
	movdw	cxdx, ss:[msg]
	clr	di
	call	ObjMessage

	clc

done:
	.leave
	ret

errorUnlock:
	call	UtilVMUnlockDS		; unlock message
	stc
	jmp	done
	
MSCReplyToMessage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCSetAddresses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the current address used in this send control.

CALLED BY:	MSG_MAILBOX_SEND_CONTROL_SET_ADDRESSES
PASS:		*ds:si	= MailboxSendControlClass object
		cx:dx	= MSCSetAddressesArgs
			if MSCSAA_numTransAddrs is 0 then the current addresses
			are deleted.

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	2/22/95   	Initial version
	SH	9/26/95		If MSCSAA_numTransAddrs is zero then delete
				the current addresses.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCSetAddresses	method dynamic MailboxSendControlClass, 
					MSG_MAILBOX_SEND_CONTROL_SET_ADDRESSES
transAddrCount	local	word
transAndOption	local	MailboxTransportAndOption
mbacaArray	local	lptr.ChunkArrayHeader
msdSetAddrs	local	MSDSetAddressesWithTransportArgs
	.enter

	Assert	fptr, cxdx
	movdw	esdi, cxdx
	mov	ax, es:[di].MSCSAA_numTransAddrs		
	mov	ss:[transAddrCount], ax
	movdw	ss:[transAndOption].MTAO_transport, \
			es:[di].MSCSAA_transportAndOption.MTAO_transport, ax
	mov	ax, es:[di].MSCSAA_transportAndOption.MTAO_transOption
	mov	ss:[transAndOption].MTAO_transOption, ax

	;
	; If TEMP_MAILBOX_SEND_CONTROL_ADDRESSES_AND_TRANSPORT already exists,
	; free the MBACAddress array stored in it.
	;
	mov	ax, TEMP_MAILBOX_SEND_CONTROL_ADDRESSES_AND_TRANSPORT
	call	ObjVarFindData		; CF if found, ds:bx =
					;  MSCAddressesAndTransport
	jnc	createArray
	mov	ax, ds:[bx].MSCAAT_addresses	; *ds:ax = MBACAddress array
	call	ObjVarDeleteDataAt	; delete vardata
	call	LMemFree		; delete MBACAddress array

createArray:

	;
	; If the number of transport addresses is zero we take that has a
	; request to delete the current transport addresses.
	;
	tst	ss:[transAddrCount]
	LONG jz	removeAddresses
		
	;
	; Create an MBACAddress chunk array.
	;
	push	si			; save self lptr	
	clr	bx, cx, si		; variable size, default hdr,
					;  alloc chunk
	mov	al, bl			; no flags
	call	ChunkArrayCreate	; *ds:si = array
	mov	ss:[mbacaArray], si

	movdw	dxbx, es:[di].MSCSAA_transAddrs
	Assert	fptr, dxbx

	;
	; Convert each MailboxTransAddr to an MBACAddress.
	;
next:
	; ds = MBACAddress array sptr
	; dx:bx = current MailboxTransAddr

	;
	; Compute size needed for this MBACAddress entry.
	;
	mov	es, dx			; es:bx = MailboxTransAddr
	mov	ax, es:[bx].MTA_transAddrLen
	clr	cx			; assume null string
	tst	es:[bx].MTA_userTransAddr.segment
	jz	hasSize
	les	di, es:[bx].MTA_userTransAddr
	Assert	fptr, esdi
	call	LocalStringSize		; cx = size excl. null
hasSize:
	xchg	cx, ax			; cx = opaque size, ax = user addr size
	add	ax, cx			; ax = opaque + user size excl. null
	add	ax, size MBACAddress + size TCHAR
					; ax = size of this MBACAddress entry
	mov	si, ss:[mbacaArray]	; *ds:si = MBACA array
	call	ChunkArrayAppend	; ds:di = MBACAddress

	;
	; Copy opaque address.
	;
	sub	ax, cx
	sub	ax, size MBACAddress + size TCHAR ; ax = user addr excl. null
	mov	ds:[di].MBACA_opaqueSize, cx
		CheckHack <MBACA_opaque eq 2>
	inc	di
	inc	di			; ds:di = MBACA_opaque
	segmov	es, ds			; es:di = MBACA_opaque
	mov	ds, dx			; ds:bx = MailboxTransAddr
	lds	si, ds:[bx].MTA_transAddr	; ds:bx = opque addr
	rep	movsb			; copy opaque addr, es:di = user addr
					;  dest

	;
	; Copy user-readable address, if any.
	;
	mov_tr	cx, ax			; cx = size of user addr excl. null
	jcxz	addNull
	mov	ds, dx			; ds:bx = MailboxTransAddr
	lds	si, ds:[bx].MTA_userTransAddr
	Assert	fptr, dssi
	rep	movsb

addNull:
	LocalClrChar	ax
	LocalPutChar	esdi, ax

	;
	; Loop to next MailboxTransAddr.
	;
	segmov	ds, es			; ds = MBACAddress array sptr
	add	bx, size MailboxTransAddr
	dec	ss:[transAddrCount]
	jnz	next

	;
	; If send dialog is not on-screen, just store the addr array in our
	; vardata.
	;
	pop	si			; *ds:si = self
	push	si			; save again
	mov	ax, TEMP_MAILBOX_SEND_CONTROL_CURRENT_DIALOG
	call	ObjVarFindData
	jnc	storeAddrs
	cmp	ds:[bx].TMDD_type, MDT_APPLICATION
	jne	storeAddrs		; => system message, so don't do
					;  this...
	mov	bx, ds:[bx].TMDD_block

	mov	si, offset MSCSendDialog	; ^lbx:si = send dialog
	mov	ax, MSG_VIS_GET_ATTRS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	push	bp
	call	ObjMessage		; cl = VisAttrs
	pop	bp
	test	cl, mask VA_REALIZED
	jz	storeAddrs		; store addrs if not on screen

	;
	; Send dialog is on-screen.  Pass the addresses to it.
	;
	push	bp
	mov	dx, size MSDSetAddressesWithTransportArgs
	sub	sp, dx
	mov	di, sp		; ss:di = MSDSetAddressesWithTransportArgs
	mov	ax, ds:[OLMBH_header].LMBH_handle
	mov	cx, ss:[mbacaArray]
	movdw	ss:[di].MSDSAWTA_addresses, axcx
	movdw	ss:[di].MSDSAWTA_transAndOption.MTAO_transport, \
			ss:[transAndOption].MTAO_transport, ax
	mov	ax, ss:[transAndOption].MTAO_transOption
	mov	ss:[di].MSDSAWTA_transAndOption.MTAO_transOption, ax

	mov	ax, MSG_MSD_SET_ADDRESSES_WITH_TRANSPORT
	mov	bp, sp		; ss:bp = MSDSetAddressesWithTransportArgs
	mov	di, mask MF_STACK or mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; CF set if transport + option in send
					;  dialog don't match ours
	lea	sp, ss:[bp + size MSDSetAddressesWithTransportArgs]
	pop	bp
	jc	storeAddrs

	;
	; Send dialog has same transport + option.  We can free our addr
	; array now.
	;
	mov	ax, ss:[mbacaArray]
	call	LMemFree
	pop	si			; *ds:si = self, no use.
	jmp	done

storeAddrs:
	;
	; Store the array and transport+options in vardata.
	;
	pop	si			; *ds:si = self
	mov	ax, TEMP_MAILBOX_SEND_CONTROL_ADDRESSES_AND_TRANSPORT
	mov	cx, size MSCAddressesAndTransport
	call	ObjVarAddData		; ds:bx = MSCAddressesAndTransport
	mov	ax, ss:[mbacaArray]
	mov	ds:[bx].MSCAAT_addresses, ax
	movdw	ds:[bx].MSCAAT_transport.MTAO_transport, \
			ss:[transAndOption].MTAO_transport, ax
	mov	ax, ss:[transAndOption].MTAO_transOption
	mov	ds:[bx].MSCAAT_transport.MTAO_transOption, ax

done:
	.leave
	ret

removeAddresses:
	;
	; Pass an empty address chunk array to the MailboxSendDialog
	;
	push	bp
	clrdw	ss:[msdSetAddrs].MSDSAWTA_addresses

	movdw	ss:[msdSetAddrs].MSDSAWTA_transAndOption.MTAO_transport, \
		ss:[transAndOption].MTAO_transport, ax

	mov	ax, ss:[transAndOption].MTAO_transOption
	mov	ss:[msdSetAddrs].MSDSAWTA_transAndOption.MTAO_transOption, ax

	call	MSCGetDialogBlock		; bx <- block
	tst	bx				; if zero then were done
	jz	done			
	mov	si, offset MSCSendDialog	
	lea	bp, ss:[msdSetAddrs]
	mov	dx, size MSDSetAddressesWithTransportArgs
	mov	ax, MSG_MSD_SET_ADDRESSES_WITH_TRANSPORT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK	
	call	ObjMessage
	pop	bp	
	jmp	done
		
MSCSetAddresses	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCGenInteractionInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up send dialog instead of ourselves if it's single
		transport.

CALLED BY:	MSG_GEN_INTERACTION_INITIATE
PASS:		*ds:si	= MailboxSendControlClass object
		es 	= segment of MailboxSendControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	2/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCGenInteractionInitiate	method dynamic MailboxSendControlClass, 
					MSG_GEN_INTERACTION_INITIATE

	;
	; See if there is ATTR_MAILBOX_SEND_CONTROL_SINGLE_TRANSPORT.
	;
	push	ax			; save MSG_GEN_INTERACTION_INITIATE
	mov	ax, ATTR_MAILBOX_SEND_CONTROL_SINGLE_TRANSPORT
	call	ObjVarFindData		; CF set if found, ds:bx = 
					;  MailboxMediaTransport
	pop	ax			; ax = MSG_GEN_INTERACTION_INITIATE
	jc	found

	;
	; Not found, call superclass to proceed.
	;
	mov	di, offset MailboxSendControlClass
	GOTO	ObjCallSuperNoLock

found:
	mov	di, si		; save self lptr

	;
	; Make sure the media -> transport map knows about this
	; medium/transport combo by now, because we need the medium/transport
	; string when we bring up the send dialog.  The map may not have known
	; of the combo if mailbox still hasn't been notified of the medium's
	; existence by now.
	;
	mov	si, ds:[bx].MMT_transOption
	movdw	cxdx, ds:[bx].MMT_medium
	mov	ax, ds:[bx].MMT_transport.MT_manuf
	mov	bx, ds:[bx].MMT_transport.MT_id
	call	MediaEnsureTransportInfo

	;
	; Tell ourselves to bring up send dialog.  Don't call superclass.
	;
	StructPushBegin	MailboxMediaTransport
	StructPushField	MMT_transOption, si
	StructPushField	MMT_transport, <ax, bx>
	StructPushField	MMT_medium, <cx, dx>
	StructPushEnd

	mov	si, di		; *ds:si = self
	mov	ax, MSG_MAILBOX_SEND_CONTROL_INITIATE_DIALOG_WITH_TRANSPORT
	mov	bp, sp			; ss:bp = MailboxMediaTransport
	call	ObjCallInstanceNoLock
	add	sp, size MailboxMediaTransport

	ret
MSCGenInteractionInitiate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCMetaNotifyWithDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the notifications to which we respond.

CALLED BY:	MSG_META_NOTIFY_WITH_DATA_BLOCK
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
		cx	= Manufacturer ID
		dx	= notification type
		^hbp	= notification data block
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	notification block is freed when we pass control to our
		superclass

PSEUDO CODE/STRATEGY:
		We do this here, rather than waiting for the UPDATE_UI call
		from our superclass, because we don't really have any UI to
		update, and the superclass likes to enable and disable things
		that we don't want enabled or disabled...


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/10/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCMetaNotifyWithDataBlock method dynamic MailboxSendControlClass, 
				MSG_META_NOTIFY_WITH_DATA_BLOCK
	;
	; See if it's one of the types we react to.
	; 
		cmp	cx, MANUFACTURER_ID_GEOWORKS
		jne	toSuper

		push	es, ax
		mov	bx, bp
		cmp	dx, GWNT_MAILBOX_SEND_CONTEXT
		je	setBodyType
		cmp	dx, GWNT_PAGE_STATE_CHANGE
		je	adjustPageRange
popToSuper:
		pop	es, ax
toSuper:
		mov	di, offset MailboxSendControlClass
		GOTO	ObjCallSuperNoLock

setBodyType:
	;
	; Make sure we have a full set of data types.
	;
		call	MSCAugmentDataTypes
	;
	; Set the default body type. This has no effect on the current dialog
	; 
	; ^hbx = MailboxSendContextNotification
	; 
		call	MemLock
		mov	es, ax
		mov	ax, es:[MSCN_objectType]
		mov	ds:[di].MSCI_defBodyType, ax
EC <		xchg	cx, ax						>
EC <		call	MSCFindDataType					>
EC <		ERROR_NC	INVALID_MSC_CONTEXT			>
EC <		xchg	cx, ax						>
	;
	; If the notification has available formats, set them, too. Note that
	; this only affects the transport menu, and has no effect on the current
	; dialog.
	;
		push	cx, dx, bp
		mov	dx, es:[MSCN_formats]
   		tst	dx
		jz	unlockPopToSuper
		mov	cx, es			; cx:dx <- format array
		mov	ax, MSG_MAILBOX_SEND_CONTROL_SET_AVAILABLE_FORMATS
		call	ObjCallInstanceNoLock
		pop	cx, dx, bp

unlockPopToSuper:
		call	MemUnlock
		jmp	popToSuper

adjustPageRange:
	;
	; Adjust the range of pages from which the user can select.
	; 
	; ^hbx = NotifyPageStateChange
	;
		tst	bx
		jz	popToSuper		; => status update, so we do
						;  nothing

		call	MemLock
		mov	es, ax
		push	bx, cx, dx, bp, si
		mov	ax, MDT_APPLICATION
		call	MSCEnsureDialogBlock
		call	ObjSwapLock
	;
	; Set the minimums to the first page
	; 
		mov	dx, es:[NPSC_firstPage]
		mov	ax, MSG_GEN_VALUE_SET_MINIMUM
		call	tweakRangeObjects
	;
	; Set the maximums to the last page
	; 
		mov	dx, es:[NPSC_lastPage]
		mov	ax, MSG_GEN_VALUE_SET_MAXIMUM
		call	tweakRangeObjects
	;
	; Tell the dialog what the current page is.
	;
		mov	dx, es:[NPSC_currentPage]
		mov	ax, MSG_MSD_REMEMBER_CURRENT_PAGE
		mov	si, offset MSCSendDialog
		call	ObjCallInstanceNoLock

		call	ObjSwapUnlock
		pop	bx, cx, dx, bp, si
		jmp	unlockPopToSuper

	;--------------------
	;Adjust the min or max for both range objects.
	;
	;Pass:	ds	= dailog block
	;	dx	= value to set
	;	ax	= MSG_GEN_VALUE_SET_MINIMUM or MSG_GEN_VALUE_SET_MAXIMUM
	;Return:ds	= fixed up
	;Destroyed:	si, cx, dx, ax, bp
	;
tweakRangeObjects:
		clr	cx
		mov	si, offset MSCPageRangeFrom
		push	dx, cx, ax
		call	ObjCallInstanceNoLock
		pop	dx, cx, ax
		push	dx, cx, ax
		mov	si, offset MSCPageRangeTo
		call	ObjCallInstanceNoLock
		pop	dx, cx, ax
	;
	; Now set the value of the from or to range to be the passed min/max
	; depending on whether it's the min (from) or max (to).
	;
		cmp	ax, MSG_GEN_VALUE_SET_MAXIMUM
		je	haveRangeWhoseValueIsToBeSet
		mov	si, offset MSCPageRangeFrom
haveRangeWhoseValueIsToBeSet:
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		clr	bp			; not indeterminate
		call	ObjCallInstanceNoLock
		retn
MSCMetaNotifyWithDataBlock endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCMetaNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the non-block-passing notifications we use.

CALLED BY:	MSG_META_NOTIFY
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
		cx	= Manufacturer ID
		dx	= notification type
		bp	= notification data
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/10/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCMetaNotify	method dynamic MailboxSendControlClass, MSG_META_NOTIFY
		cmp	cx, MANUFACTURER_ID_GEOWORKS
		jne	toSuper
		cmp	dx, GWNT_MAILBOX_SEND_CONTEXT
		jne	toSuper
		
EC <		mov	cx, bp						>
EC <		call	MSCFindDataType					>
EC <		ERROR_NC	INVALID_MSC_CONTEXT			>

		mov	ds:[di].MSCI_defBodyType, bp
		ret
toSuper:
		mov	di, offset MailboxSendControlClass
		GOTO	ObjCallSuperNoLock
MSCMetaNotify	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCGenControlGetNormalFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hacked routine to return a non-zero features mask so we
		don't get marked not user-initiatable. We don't have
		features, but we have children...
		
		This should be able to be dispensed with once the POOF feature
		is implemented

CALLED BY:	MSG_GEN_CONTROL_GET_NORMAL_FEATURES
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
RETURN:		ax	= current normal feature set
		cx	= required normal features
		dx	= prohibited normal features
		bp	= normal features supported by controller
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/11/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCGenControlGetNormalFeatures method dynamic MailboxSendControlClass, 
				MSG_GEN_CONTROL_GET_NORMAL_FEATURES,
				MSG_GEN_CONTROL_GET_TOOLBOX_FEATURES
		.enter
		clr	dx, ax
		dec	ax
		mov	cx, ax
		mov	bp, ax
		.leave
		ret
MSCGenControlGetNormalFeatures endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCSetAvailableFormats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the list of formats in which the body can be created,
		for use in filtering the transports the user can select

CALLED BY:	MSG_MAILBOX_SEND_CONTROL_SET_AVAILABLE_FORMATS
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
		cx:dx	= array of MailboxDataFormat descriptors, ending with
			  MANUFACTURER_ID_GEOWORKS/GMDFID_INVALID
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/17/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCSetAvailableFormats method dynamic MailboxSendControlClass, 
				MSG_MAILBOX_SEND_CONTROL_SET_AVAILABLE_FORMATS
		.enter

		mov	ax, ATTR_MAILBOX_SEND_CONTROL_AVAILABLE_FORMATS
		call	MSCStoreFormats
	;
	; If we've got our UI built, pass the array off to the OTMS, too.
	;
		call	MSCGetChildBlockAndFeatures
		jc	done		; => no ui, yet
		
		mov	si, offset MSCTransportMonikerSource
		mov	ax, MSG_OTMS_SET_AVAILABLE_FORMATS
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
		
		mov	si, offset MSCTransportMenu
		mov	ax, MSG_OTM_REBUILD_LIST
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
done:
		.leave
		ret
MSCSetAvailableFormats endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCStoreFormats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy an array of MailboxDataFormat descriptors into an
		object's vardata.

CALLED BY:	(EXTERNAL) MSCSetAvailableFormats, 
			   OTMSSetAvailableFormats
PASS:		*ds:si	= object in which to store them
		cx:dx	= array of MailboxDataFormat descriptors, ending with
			  MANUFACTURER_ID_GEOWORKS/GMDFID_INVALID
		ax	= vardata tag under which to store it
RETURN:		nothing
DESTROYED:	ax, di, bx, es
SIDE EFFECTS:	object & block may move

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/17/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCStoreFormats	proc	far
		.enter
		push	ax			; save vardata tag
	;
	; Compute the size of the array so we can allocate extra space for it.
	;
		mov	es, cx
		mov	bx, dx
formatCountLoop:
	CheckHack <MANUFACTURER_ID_GEOWORKS eq 0 and GMDFID_INVALID eq 0>
		mov	ax, es:[bx].MDF_manuf
		or	ax, es:[bx].MDF_id
		lea	bx, es:[bx+size MailboxDataFormat]
		jnz	formatCountLoop

		sub	bx, dx			; bx <- # bytes in array
		mov	cx, bx
		pop	ax			; ax <- vardata tag
		or	ax, mask VDF_SAVE_TO_STATE
		call	ObjVarAddData
	;
	; Copy the array into the vardata
	;
		segxchg	ds, es			; ds <- array seg, es <- obj
		xchg	si, dx			; ds:si <- array
						; *ds:dx <- object
		mov	di, bx			; es:di <- vardata
		push	si
		rep	movsb
		pop	si
	;
	; Restore registers properly.
	;
		mov	cx, ds
		xchg	si, dx		; cx:dx <- array, again
		segmov	ds, es		; *ds:si <- us
		.leave
		ret
MSCStoreFormats	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCGenControlTweakDuplicatedUi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the duplicated UI according to our hints, etc.

CALLED BY:	MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI
PASS:		*ds:si	= MailboxSendControl object
		ds:di	= MailboxSendControlInstance
		cx	= child block
		dx	= features
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		if ATTR_MAILBOX_SEND_CONTROL_SAVES_TRANSACTIONS, set filter
			on moniker source
		Set the available formats for the OutboxTransportMonikerSource	
			if we've got any on record.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/17/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCGenControlTweakDuplicatedUi method dynamic MailboxSendControlClass, 
				MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI
		.enter
		mov	ax, ATTR_MAILBOX_SEND_CONTROL_SAVES_TRANSACTIONS
		call	ObjVarFindData
		jnc	checkFormats
	;
	; The attribute is there -- tell the moniker source to filter out
	; those transports that can't restore a transaction.
	;
		mov	bx, cx
		push	si, dx
		mov	ax, MSG_OTMS_SET_TYPE
		mov	cl, OTMST_FILTERED
		mov	dx, mask MBTC_CAN_RESTORE_TRANSACTION
		mov	si, offset MSCTransportMonikerSource
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
		pop	si, dx
		mov	cx, bx
checkFormats:
	;
	; See if we have any formats on record.
	;
		mov	ax, ATTR_MAILBOX_SEND_CONTROL_AVAILABLE_FORMATS
		call	ObjVarFindData
		jnc	done
	;
	; We do -- tell the moniker source what they are so it can filter
	; out those that are picky and can't accept the formats.
	;
		mov	dx, bx
		mov	bx, cx		; ^lbx:si <- OTMS
		mov	si, offset MSCTransportMonikerSource
		mov	cx, ds		; cx:dx <- array
		mov	ax, MSG_OTMS_SET_AVAILABLE_FORMATS
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
done:
		.leave
		ret
MSCGenControlTweakDuplicatedUi endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Utilities ***
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCFindDataType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for the indicated data type in the array of possible
		data types for the controller.

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= MailboxSendControl
		cx	= MailboxObjectType to find
RETURN:		carry set if found:
			cx	= index
		carry clear if not found:
			cx	= unchanged
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 4/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCFindDataType	proc	near
		class	MailboxSendControlClass
		uses	ax, si, di, dx
		.enter
	;
	; Get the array of available body types.
	; 
		DerefDI	MailboxSendControl
		mov	si, ds:[di].MSCI_dataTypes
		Assert	chunk, si, ds
		mov	dx, cx			; dx <- id being sought
		mov	di, ds:[si]
		mov	cx, ds:[di].CAH_count	; cx <- # elements in array
		jcxz	notFound
	;
	; Loop over the elements looking for one whose MSOT_id matches that
	; passed.
	; 
		add	di, ds:[di].CAH_offset	; ds:di <- first element
findLoop:
		cmp	ds:[di].MSOT_id, dx
		je	found
	    ;
	    ; Advance to next element.
	    ; 
		add	di, size MailboxSendObjectType
		loop	findLoop
notFound:
	;
	; Not in the array -- return CX unchanged and carry clear.
	; 
		mov	cx, dx
		clc
done:
		.leave
		ret

found:
	;
	; Return the index # in cx and carry set.
	; 
		mov	di, ds:[si]
		sub	cx, ds:[di].CAH_count
		neg	cx
		stc
		jmp	done
MSCFindDataType	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCGetChildBlockAndFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the child block handle and the MSCFeatures for the
		MailboxSendControl object

CALLED BY:	INTERNAL

PASS:		*DS:SI	= MailboxSendControlClass object

RETURN:		AX	= MSCFeatures
		BX	= Block handle
		Carry	= Clear
			- or -
		Carry	= Set

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MSCGetChildBlockAndFeatures	proc	near
		.enter
	
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarFindData		; TempGenControlInstance=>DS:BX
		cmc				; invert the carry
		jc	done			; if not found, abort
		mov	ax, ds:[bx].TGCI_features
		mov	bx, ds:[bx].TGCI_childBlock
		tst	bx
		jnz	done
		stc				; set carry for no children
done:
		.leave
		ret
MSCGetChildBlockAndFeatures	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMessage_child_send, ObjMessage_child_call
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message (or call) to a child of a controller

CALLED BY:	INTERNAL

PASS:		*DS:SI	= Import/ExportControlClass
		AX	= Message to send
		BX	= Feature flag(s) to check
		DI	= Chunk handle of child

RETURN:		carry	= clear (message sent)
		see message declaration
			- or -
		carry	= set (UI not present or feature turned off)

DESTROYED:	see message declaration (BX, DI, SI preserved)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 	0		; not used 10/30/94

ObjMessage_child_send	proc	near
		push	bx
		mov	bx, mask MF_FIXUP_DS
		jmp	omcCommon
ObjMessage_child_send	endp

ObjMessage_child_call	proc	near
		push	bx
		mov	bx, mask MF_FIXUP_DS or mask MF_CALL
omcCommon	label	near
		push	di, si
		push	ax, bx			; save message, flags
		call	MSCGetChildBlockAndFeatures
		jc	error
		mov	si, sp
		and	ax, ss:[si+8]		; and with flags on stack
		jz	error			; if feature is off, we're done
		pop	ax, si			; restore message, flags
		xchg	di, si			; child's OD => BX:SI
		call	ObjMessage
		clc
done:
		pop	bx, di, si
		ret
error:
		pop	ax, si
		stc
		jmp	done
ObjMessage_child_call	endp

endif	; 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** EC Utilities ***
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	ERROR_CHECK and 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCAssertMailboxSendControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that *DS:SI is indeed a MailboxSendControl object

CALLED BY:	UTILITY

PASS:		*DS:SI	= MailboxSendControlClass object

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MSCAssertMailboxSendControl	proc	near
		.enter
	
		Assert	objectPtr, dssi, MailboxSendControlClass

		.leave
		ret
MSCAssertMailboxSendControl	endp

endif	; if ERROR CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECAssertTransactionHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the transaction handle in BP is a valid one

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= MailboxSendControl
		bp	= transaction handle
RETURN:		only if BP is valid
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 6/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
ECAssertTransactionHandle proc	near
		uses	di
		class	MailboxSendControlClass
		.enter
		DerefDI	MailboxSendControl
			CheckHack <MSCT_next eq 0>
		mov	di, ds:[di].MSCI_transactions
checkLoop:
		tst	di
		ERROR_Z	INVALID_TRANSACTION_HANDLE
		cmp	di, bp
		je	done
		mov	di, ds:[di]
		mov	di, ds:[di].MSCT_next
		jmp	checkLoop
done:
		.leave
		ret
ECAssertTransactionHandle endp
endif	; ERROR_CHECK

SendControlCode	ends

; Local Variables:
; messages-use-class-abbreviation: nil
; End:
