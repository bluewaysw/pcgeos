COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		uiSpoolAddress.asm

AUTHOR:		Adam de Boor, Oct 26, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/26/94	Initial revision


DESCRIPTION:
	Address controller fun
		

	$Id: uiSpoolAddress.asm,v 1.1 97/04/05 01:18:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


MailboxClassStructures	segment	resource
	MailboxSpoolAddressControlClass	mask CLASSF_NEVER_SAVED
MailboxClassStructures	ends

AddressCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSACGenControlGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch info GenControl needs to help us

CALLED BY:	MSG_GEN_CONTROL_GET_INFO
PASS:		*ds:si	= MailboxSpoolAddressControl object
		ds:di	= MailboxSpoolAddressControlInstance
		cx:dx	= GenControlBuildInfo to fill in
RETURN:		nothing
DESTROYED:	cx, di, si, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/26/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSACGenControlGetInfo method dynamic MailboxSpoolAddressControlClass, 
				MSG_GEN_CONTROL_GET_INFO
		.enter
		mov	es, cx
		mov	di, dx			; buffer to fill => ES:DI
		segmov	ds, cs
		mov	si, offset MSAC_dupInfo
		mov	cx, size GenControlBuildInfo
		rep	movsb
		.leave
		ret
MSACGenControlGetInfo endm

MSAC_dupInfo	GenControlBuildInfo		<
		mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST,
						; GCBI_flags
		MSAC_initFileKey,		; GCBI_initFileKey
		0,				; GCBI_gcnList
		0,				; GCBI_gcnCount
		0,				; GCBI_notificationList
		0,				; GCBI_notificationCount
		0,				; GCBI_controllerName

		handle MSACKiddieRepository,	; GCBI_dupBlock
		0,				; GCBI_childList
		0,				; GCBI_childCount
		0,				; GCBI_featuresList
		0,				; GCBI_featuresCount
		0,				; GCBI_features

		0,				; GCBI_toolBlock
		0,				; GCBI_toolList
		0,				; GCBI_toolCount
		0,				; GCBI_toolFeaturesList
		0,				; GCBI_toolFeaturesCount
		0,				; GCBI_toolFeatures
		0,				; GCBI_helpContext
		0>				; GCBI_reserved

if _FXIP
ControlInfoXIP	segment	resource
endif

MSAC_initFileKey		char	"spoolAddressControl", 0

if _FXIP
ControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSACGenControlGenerateUi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the application's PrintControl and make it our child

CALLED BY:	MSG_GEN_CONTROL_GENERATE_UI
PASS:		*ds:si	= MailboxSpoolAddressControl object
		ds:di	= MailboxSpoolAddressControlInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/28/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSACGenControlGenerateUi method dynamic MailboxSpoolAddressControlClass, 
				MSG_GEN_CONTROL_GENERATE_UI
		.enter
		mov	di, offset MailboxSpoolAddressControlClass
		call	ObjCallSuperNoLock
	;
	; Call ourselves to find the driver type we like.
	; 
		mov	ax, MSG_MSAC_GET_DRIVER_TYPE
		call	ObjCallInstanceNoLock
		push	ax			; save the PrinterDriverType
	;
	; Fetch the PrintControl OD from our instance data, it having been
	; placed there by MAC_PROCESS_TRANSPORT_HINT
	; 
		push	si
		mov	si, ds:[si]
		add	si, ds:[si].MailboxSpoolAddressControl_offset

		mov	bx, ds:[si].MSACI_pc.handle
		mov	si, ds:[si].MSACI_pc.chunk
		Assert	objectOD, bxsi, PrintControlClass, fixup
	;
	; Configure the PrintControlAttrs for the PrintControl object,
	; giving our superclass a chance to do as it desires. We need
	; to save the current attrs so that the PrintControl is configured
	; properly when we switch between uses (say between faxing & printing).
	; 
		mov	ax, MSG_PRINT_CONTROL_GET_ATTRS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; cx <- PrintControlAttrs
		pop	di
		mov	bp, ds:[di]
		add	bp, ds:[bp].MailboxSpoolAddressControl_offset
		mov	ds:[bp].MSACI_pcAttrs, cx

		xchg	di, si
		mov	ax, MSG_MSAC_MODIFY_PRINT_CONTROL_ATTRS
		call	ObjCallInstanceNoLock	; cx <- updated PrintControlAttrs
		xchg	di, si			; bx:si <- PrintControl OD

		call	ObjSwapLock
		mov	ax, MSG_PRINT_CONTROL_SET_ATTRS
		call	ObjCallInstanceNoLock
	;
	; Set the vardata on the PrintControl to tell it where we are, and
	; that it should react accordingly.
	; 
		mov	dx, bx
		mov	ax, TEMP_PRINT_CONTROL_ADDRESS_CONTROL
		mov	cx, size TempPrintAddressControlData
		call	ObjVarAddData
		movdw	ds:[bx].TPACD_addrControl, dxdi
		pop	ax			; ax <- requested driver type
		mov	ds:[bx].TPACD_driverType, al
		
		mov	bx, dx
		call	ObjSwapUnlock
	;
	; Attempt to attach the PrintControl to ourselves.
	;
		mov	si, di			; *ds:si <- MSAC
		mov	ax, MSG_MSAC_ATTACH_PRINT_CONTROL
		call	ObjCallInstanceNoLock
		.leave
		ret
MSACGenControlGenerateUi		endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSACAttachPrintControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attach the PrintControl as one of our children

CALLED BY:	MSG_MSAC_ATTACH_PRINT_CONTROL
PASS:		*ds:si	= MailboxSpoolAddressControl object
		ds:di	= MailboxSpoolAddressControlInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	PrintControl attached as our last generic child and set usable
     		Address state set valid before PrintControl is set usable

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 5/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSACAttachPrintControl method dynamic MailboxSpoolAddressControlClass, 
				MSG_MSAC_ATTACH_PRINT_CONTROL
		uses	bp
		.enter
	;
	; Attach the PrintControl as our last child. (used to be first, but
	; Fax likes to have it all come at the bottom)
	; 
		movdw	cxdx, ds:[di].MSACI_pc
		mov	ax, MSG_GEN_ADD_CHILD
		mov	bp, CCO_LAST
		call	ObjCallInstanceNoLock
	;
	; Tell our superclass the address is valid. Do this before we set the
	; PrintControl usable so if it decides it can't do anything, it can
	; tell us we're invalid.
	;
		push	cx, dx
		mov	ax, MSG_MAILBOX_ADDRESS_CONTROL_SET_VALID_STATE
		mov	cx, TRUE	
		call	ObjCallInstanceNoLock
		pop	bx, si
	;
	; Set the PrintControl usable.
	; 
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		ret
MSACAttachPrintControl endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSACGetDriverType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the PrinterDriverType we want the PrintControl to
		display printers for.

CALLED BY:	MSG_MSAC_GET_DRIVER_TYPE
PASS:		*ds:si	= MailboxSpoolAddressControl object
		ds:di	= MailboxSpoolAddressControlInstance
RETURN:		al	= PrinterDriverType
DESTROYED:	ah
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 7/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSACGetDriverType method dynamic MailboxSpoolAddressControlClass, 
			MSG_MSAC_GET_DRIVER_TYPE
		.enter
		mov	al, PDT_PRINTER
		.leave
		ret
MSACGetDriverType endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSACModifyPrintControlAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the PrinterDriverType we want the PrintControl to
		display printers for.

CALLED BY:	MSG_MSAC_GET_DRIVER_TYPE
PASS:		*ds:si	= MailboxSpoolAddressControl object
		ds:di	= MailboxSpoolAddressControlInstance
		cx	= PrintControlAttrs (current)
RETURN:		cx	= PrintControlAttrs (desired)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	don	1/21/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSACModifyPrintControlAttrs method dynamic MailboxSpoolAddressControlClass, 
			MSG_MSAC_MODIFY_PRINT_CONTROL_ATTRS
		.enter
		andnf	cx, not mask PCA_PAGE_CONTROLS
		.leave
		ret
MSACModifyPrintControlAttrs endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSACGenControlDestroyUi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unhook the PrintControl from us

CALLED BY:	MSG_GEN_CONTROL_DESTROY_UI
PASS:		*ds:si	= MailboxSpoolAddressControl object
		ds:di	= MailboxSpoolAddressControlInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/28/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSACGenControlDestroyUi method dynamic MailboxSpoolAddressControlClass, 
				MSG_GEN_CONTROL_DESTROY_UI
		uses	si
		.enter
	;
	; Remove the print control from ourselves, please. Also, restore
	; the PrintControlAttrs the PrintControl had originally
	; 
		movdw	bxsi, ds:[di].MSACI_pc
		mov	cx, ds:[di].MSACI_pcAttrs
		mov	ax, MSG_PRINT_CONTROL_SET_ATTRS
;		mov	di, mask MF_FORCE_QUEUE	; don't bother processing now
;do now to keep syncronized with the SET_ATTRS call in GENERATE_UI when
;changing from one MAC (destroy-ui) to another (generate-ui) -- brianc 3/22/96
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		mov	ax, MSG_GEN_REMOVE
		mov	dl, VUM_NOW
		mov	bp, mask CCF_MARK_DIRTY
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; And make sure it has no record of our existence, since we're liable
	; to not, in a moment.
	; 
		mov	ax, MSG_META_DELETE_VAR_DATA
		mov	cx, TEMP_PRINT_CONTROL_ADDRESS_CONTROL
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		mov	ax, MSG_GEN_CONTROL_DESTROY_UI
		mov	di, offset MailboxSpoolAddressControlClass
		GOTO	ObjCallSuperNoLock
MSACGenControlDestroyUi endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSACMailboxAddressControlProcessTransportHint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust our current PrintControl based on what the user
		placed on the SendControl

CALLED BY:	MSG_MAILBOX_ADDRESS_CONTROL_PROCESS_TRANSPORT_HINT
PASS:		*ds:si	= MailboxSpoolAddressControl object
		ds:di	= MailboxSpoolAddressControlInstance
		cx:dx	= MailboxSpoolTransportHint
		bp	= block holding the MSC
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	?

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSACMailboxAddressControlProcessTransportHint method dynamic MailboxSpoolAddressControlClass, MSG_MAILBOX_ADDRESS_CONTROL_PROCESS_TRANSPORT_HINT
		.enter
		movdw	esbx, cxdx
	;
	; Fetch the optr of the PrintControl
	; 
		movdw	cxdx, es:[bx].MSTH_pc
		mov	bx, bp
		mov	al, RELOC_HANDLE
		call	ObjDoRelocation
		
		movdw	ds:[di].MSACI_pc, cxdx
		.leave
		ret
MSACMailboxAddressControlProcessTransportHint		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSACGenControlGetNormalFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hacked routine to return a non-zero features mask so we
		don't get marked not user-initiatable. We don't have
		features, but we have children...
		
CALLED BY:	MSG_GEN_CONTROL_GET_NORMAL_FEATURES
PASS:		*ds:si	= MailboxSpoolAddressControl object
		ds:di	= MailboxSpoolAddressControlInstance
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
MSACGenControlGetNormalFeatures method dynamic MailboxSpoolAddressControlClass, 
				MSG_GEN_CONTROL_GET_NORMAL_FEATURES,
				MSG_GEN_CONTROL_GET_TOOLBOX_FEATURES
		.enter
		clr	dx, ax
		dec	ax
		mov	cx, ax
		mov	bp, ax
		.leave
		ret
MSACGenControlGetNormalFeatures endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSACMailboxAddressControlCreateMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Arrange to create the message

CALLED BY:	MSG_MAILBOX_ADDRESS_CONTROL_CREATE_MESSAGE
PASS:		*ds:si	= MailboxSpoolAddressControl object
		ds:di	= MailboxSpoolAddressControlInstance
		cx	= MailboxObjectType selected
		*dx:bp	= MSCTransaction
RETURN:		carry set if message creation being handled:
			ax	= TRUE if controller is not re-entrant
				= FALSE if controller can handle another
				  transaction
		carry clear if message creation not being handled
		(always return carry set, ax = TRUE)
DESTROYED:	dx
SIDE EFFECTS:	?

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/28/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSACMailboxAddressControlCreateMessage method dynamic MailboxSpoolAddressControlClass, 
				MSG_MAILBOX_ADDRESS_CONTROL_CREATE_MESSAGE
		uses	cx, bp
		.enter
	;
	; Record the current transaction.
	; 
		mov	ds:[di].MSACI_trans, bp
	;
	; Tell the PrintControl to start printing.
	;
	; We force-queue the message to cope with single-threaded apps that
	; would otherwise handle the PRINT_CONTROL_PRINT, issue the
	; PRINTING_COMPLETE, which would register the message and we'd return
	; to our caller with the transaction chunk having been freed. This
	; would not be kosher. -- a&j 3/30/95
	; 
		movdw	bxsi, ds:[di].MSACI_pc
		mov	ax, MSG_PRINT_CONTROL_PRINT
		mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
		call	ObjMessage
	;
	; Signal message creation handled, but we can't be used again until
	; that one is complete.
	; 
		mov	ax, TRUE
		stc
		.leave
		ret
MSACMailboxAddressControlCreateMessage endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSACMailboxAddressControlGetTransmitMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the moniker to use for the Send trigger...

CALLED BY:	MSG_MAILBOX_ADDRESS_CONTROL_GET_TRANSMIT_MONIKER
PASS:		*ds:si	= MailboxSpoolAddressControl object
		ds:di	= MailboxSpoolAddressControlInstance
RETURN:		^lcx:dx	= VisMoniker to use
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/28/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSACMailboxAddressControlGetTransmitMoniker method dynamic MailboxSpoolAddressControlClass, MSG_MAILBOX_ADDRESS_CONTROL_GET_TRANSMIT_MONIKER
		.enter
		mov	cx, handle uiSpoolAddressTransmitMoniker
		mov	dx, offset uiSpoolAddressTransmitMoniker
		.leave
		ret
MSACMailboxAddressControlGetTransmitMoniker endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSACPrintingCanceled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends MSG_MAILBOX_SEND_CONTROL_CANCEL_MESSAGE to OLMBH_ouput,
		cancelling the print job. 

CALLED BY:	MSG_MSAC_PRINTING_CANCELED
PASS:		*ds:si	= MailboxSpoolAddressControlClass object
		ds:di	= MailboxSpoolAddressControlClass instance data
		^ldx:bp	= PrintControl sending the message

RETURN:		nothing
DESTROYED:	ax, cx, dx, bx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	10/23/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSACPrintingCanceled	method dynamic MailboxSpoolAddressControlClass, 
					MSG_MSAC_PRINTING_CANCELED
		.enter
	;
	; Send the transaction to the output with the cancel message.
	;
		mov	bp, ds:[di].MSACI_trans
		movdw	bxsi, ds:[OLMBH_output]
		mov	ax, MSG_MAILBOX_SEND_CONTROL_CANCEL_MESSAGE 
		mov	dx, -1			; don't notify user
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		
		.leave
		ret
MSACPrintingCanceled	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSACPrintingComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the MailboxSendControl to place the message in the
		outbox.

CALLED BY:	MSG_MSAC_PRINTING_COMPLETE
PASS:		*ds:si	= MailboxSpoolAddressControl object
		ds:di	= MailboxSpoolAddressControlInstance
		^hcx	= JobParameters block (to be freed by MSAC)
		^ldx:bp	= PrintControl generating call
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSACRegisterMessageArgs	struct
    MSACRMA_rma	MSCRegisterMessageArgs	<>
    MSACRMA_appRef	FileDDAppRef	<>
SBCS <MSACRMA_fname	char	(length JP_fname) dup (?)		>
DBCS <MSACRMA_fname	wchar	(length JP_fname) dup (?)		>
    ;
    ; The rest of this is already on the stack when this structure is
    ; allocated on the stack.
    ; 
			even
    MSACRMA_onstack	label	byte
    MSACRMA_trans	word		; transaction handle
    MSACRMA_msc		word		; MailboxSendControl
MSACRegisterMessageArgs	ends

MSACPrintingComplete method dynamic MailboxSpoolAddressControlClass, 
				MSG_MSAC_PRINTING_COMPLETE
		.enter
	;
	; Rename the file so it won't get deleted by the spooler on startup
	; 
		call	MSACRenameSpoolFile
	;
	; Now we've got the JobParameters, we can set the real address for
	; the transaction.
	; 
		mov	ax, MSG_MSAC_ADJUST_ADDRESS
		call	ObjCallInstanceNoLock
	;
	; Get what we need out of our object segment & instance so we may
	; destroy ds
	; 
		mov	di, ds:[si]
		add	di, ds:[di].MailboxSpoolAddressControl_offset
		mov	bp, ds:[di].MSACI_trans
		movdw	bxsi, ds:[OLMBH_output]
	;
	; Lock down the JobParameters block
	; 
		xchg	bx, cx		; cx <- MSC.handle, bx <- JP
		call	MemLock
		mov	ds, ax
	;
	; Wheeee. Now we have to create the arguments for registering the
	; message. First the constants (bodyStorage, bodyFormat)
	; 
		push	si, bp		; MSACRMA_msc, MSACRMA_trans
		sub	sp, offset MSACRMA_onstack
		mov	bp, sp
		mov	ss:[bp].MSACRMA_rma.MSCRMA_bodyStorage.MS_manuf,
				MANUFACTURER_ID_GEOWORKS
		mov	ss:[bp].MSACRMA_rma.MSCRMA_bodyStorage.MS_id,
				GMSID_FILE
		
		mov	ss:[bp].MSACRMA_rma.MSCRMA_bodyFormat.MDF_manuf,
				MANUFACTURER_ID_GEOWORKS
		mov	ss:[bp].MSACRMA_rma.MSCRMA_bodyFormat.MDF_id,
				GMDFID_STREAM_GSTRING
	;
	; Point to the appRef we allocated on the stack, too.
	; 
		lea	ax, ss:[bp].MSACRMA_appRef
		movdw	ss:[bp].MSACRMA_rma.MSCRMA_bodyRef, ssax
		mov	ss:[bp].MSACRMA_rma.MSCRMA_bodyRefLen,
				size MSACRMA_appRef + size MSACRMA_fname
	;
	; Set up the flags for the message.
	; 
		mov	ss:[bp].MSACRMA_rma.MSCRMA_flags, 
				mask MMF_DELETE_BODY_AFTER_TRANSMISSION or \
				(MMP_FIRST_CLASS shl offset MMF_PRIORITY) or \
				mask MMF_SEND_WITHOUT_QUERY
	;
	; If the printer is intermittent, remove the MMF_SEND_WITHOUT_QUERY
	; flag.
	; 
		mov	dx, cx			; dx <- MSC.handle
		cmp	ds:[JP_portInfo].PPI_type, PPT_FILE
		je	pointToSubject		; if printing to file, we
						;  don't care if the printer
						;  is present or not

		push	dx		; save MSC.handle
		mov	si, offset JP_printerName	; ds:si <- category
		mov	cx, cs
		mov	dx, offset intermittentKeyStr	; cx:dx <- key
		call	InitFileReadBoolean		; CF, AX <- result
		pop	dx				; dx <- MSC block
		jc	pointToSubject			; => not found, so not
							;  intermittent
		tst	ax
		jz	pointToSubject			; => not intermittent
		andnf	ss:[bp].MSACRMA_rma.MSCRMA_flags, 
				not mask MMF_SEND_WITHOUT_QUERY
pointToSubject:
	;
	; The subject line is just the document name.
	; 
		mov	ss:[bp].MSACRMA_rma.MSCRMA_summary.segment, ds
		mov	ss:[bp].MSACRMA_rma.MSCRMA_summary.offset,
				offset JP_documentName
	;
	; Send the message any time between now and eternity
	; 
		movdw	ss:[bp].MSACRMA_rma.MSCRMA_startBound, MAILBOX_NOW
		movdw	ss:[bp].MSACRMA_rma.MSCRMA_endBound, MAILBOX_ETERNITY
	;
	; Now we need to actually set up the appRef for the body. It's always
	; in SP_SPOOL, then we have to copy JP_fname into our stack frame.
	; 
		mov	ss:[bp].MSACRMA_appRef.FAR_diskHandle, SP_SPOOL
		push	es
		segmov	es, ss
		lea	di, ss:[bp].MSACRMA_fname
		mov	si, offset JP_fname
		mov	cx, size JP_fname
		rep	movsb
		pop	es

	;
	; Call the MailboxSendControl to register the message.
	; 
		push	bx			; save JP block for freeing
		mov	bx, dx
		mov	si, ss:[bp].MSACRMA_msc	; ^lbx:si <- MSC
		mov	dx, bp
		mov	cx, ss			; cx:dx <- register args
		mov	bp, ss:[bp].MSACRMA_trans; bp <- transaction handle
		mov	ax, MSG_MAILBOX_SEND_CONTROL_REGISTER_MESSAGE
		mov	di, mask MF_CALL	; allow ES to get trashed, since
						;  we can't fixup just es...
		call	ObjMessage
		jc	regError
cleanup:
	;
	; Free up the JobParameters block.
	; 
		pop	bx
		call	MemFree
	;
	; Clear off the stack
	; 
		add	sp, size MSACRegisterMessageArgs
		.leave
		ret

regError:
	;
	; Need to nuke the spool file if message couldn't be registered.
	; 
		mov	ax, SP_SPOOL
		call	FilePushDir
		call	FileSetStandardPath
		mov	dx, offset JP_fname
		call	FileDelete
		call	FilePopDir
		jmp	cleanup
MSACPrintingComplete endm

intermittentKeyStr	char	'intermittent', 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSACRenameSpoolFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rename the spool file to something that won't get nuked
		by the spooler on start-up. This allows us to leave the file
		in the spool directory (to avoid moving/copying it when
		printing), while ensuring its viability through crashes.

CALLED BY:	(INTERNAL) MSACPrintingComplete
PASS:		cx	= JobParameters block
RETURN:		carry set if couldn't find a new name for the file.
		carry clear if could:
			ds:[JP_fname] = new name
DESTROYED:	ax
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 4/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBCS <msgExt	char	'msg', 0					>
DBCS <msgExt	wchar	'msg', 0					>

MSACRenameSpoolFile proc	near
newName		local	SpoolFileName
		uses	ds, dx, es, si, di, cx, bx
		.enter
	;
	; Switch to the spool directory so we can mess with the file.
	; 
		call	FilePushDir
		mov	ax, SP_SPOOL
		call	FileSetStandardPath

		mov	bx, cx
		call	MemLock
		mov	ds, ax
		push	bx
	;
	; Copy the name, up to the start of the extension, into our buffer.
	; 
			CheckHack <size SpoolFileName eq size JP_fname>
		mov	si, offset JP_fname
		segmov	es, ss
		lea	di, ss:[newName]
		mov	cx, offset SFN_ext + type SFN_ext
		rep	movsb
	;
	; Copy a new extension in, so the spooler won't find it when nuking
	; files.
	; 
		mov	si, offset msgExt
	CheckHack <length msgExt eq 4>
		movsw	cs:
		movsw	cs:
DBCS <		movsw	cs:						>
DBCS <		movsw	cs:						>
	;
	; Now attempt to rename the file to the same numbered file, but with the
	; different extension. If that fails, we'll move to the next numbered
	; file...
	; 
		sub	di, size newName		; es:di <- new name
		mov	dx, offset JP_fname		; ds:dx <- cur name
renameLoop:
		call	FileRename
		jnc	haveNewName
	;
	; Advance to the next number in the sequence.
	; 
		mov	bx, size SFN_num - type SFN_num
nextNameLoop:
		inc     es:[di].SFN_num[bx]		; increment the digit
		cmp     es:[di].SFN_num[bx], '9'
		jl      renameLoop			; try again if no
							;     rollover
		mov     es:[di].SFN_num[bx], '0'
		dec	bx				; go to the next digit
DBCS <		dec	bx				;  ...		>
		jge	nextNameLoop			; jump if not negative

		stc					; signal failure
		jmp	done

haveNewName:
	;
	; Copy the name from our buffer to the JobParameters block.
	; 
		segxchg	ds, es
		mov	si, di
		mov	di, dx
		mov	cx, size newName
		rep	movsb
done:
		pop	bx
		call	MemUnlock
		call	FilePopDir
		.leave
		ret
MSACRenameSpoolFile endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSACAdjustAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the address recorded for the transaction to match
		what's in the JobParameters block

CALLED BY:	MSG_MSAC_ADJUST_ADDRESS
PASS:		*ds:si	= MailboxSpoolAddressControl object
		ds:di	= MailboxSpoolAddressControlInstance
		^hcx	= JobParameters
RETURN:		nothing
DESTROYED:	ax, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 4/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSACAdjustAddress method dynamic MailboxSpoolAddressControlClass, MSG_MSAC_ADJUST_ADDRESS
		uses	bp
		.enter
	;
	; Compute the size of the address element. The element comes in
	; three conceptual pieces, four actual ones:
	; 	- the MBACAddress header
	; 	- the significant portion of the opaque address, taken from
	;	  JP_printerName and null-padded to MAXIMUM_PRINTER_NAME_LENGTH
	;	- the insignificant portion of the opaque address, being
	;	  the JobParameters block
	;	- the user-readable address, being the JP_printerName with
	;	  its terminating null
	;	
		mov	bx, cx
		mov	ax, MGIT_SIZE
		call	MemGetInfo		; ax <- block size
		add	ax, MAXIMUM_PRINTER_NAME_LENGTH	; room for significant
							;  part of the address
		mov	dx, bx			; dx <- JP block
		mov_tr	cx, ax			; cx <- size so far
		mov	bp, ds:[di].MSACI_trans	; bp <- transaction handle
	    ;
	    ; Compute the size of the null-terminated printer name.
	    ; 
		call	MemLock
		mov	es, ax
		mov	di, offset JP_printerName
		push	cx			; save current size
		LocalStrSize includeNull	; cx <- string size
		pop	ax			; ax <- current size
		xchg	ax, cx			; ax <- string size (need it for
						;  later)
						; cx <- current size
		add	cx, ax		
		add	cx, size MBACAddress	; cx <- total element size
	;
	; Lock down the MSC's block so we can get to the transaction.
	; 
		movdw	bxsi, ds:[OLMBH_output]
		call	ObjSwapLock
		push	ax			; save printer name size
	;
	; Resize element 0 of the address array to hold the true address, now
	; that we've got it.
	; 
		mov	si, ds:[bp]
		mov	si, ds:[si].MSCT_addresses
		call	ObjSwapUnlock
		clr	ax
		call	ChunkArrayElementResize
		call	ChunkArrayElementToPtr
		segxchg	es, ds			; es:di <- element
						; ds <- JobParameters

	;
	; Compute the actual size of the opaque data for storing in the
	; header.
	; 
		pop	ax			; ax <- printer name size
		sub	cx, ax			; remove user-readable size
		sub	cx, size MBACAddress	;  and the header
		mov	es:[di].MBACA_opaqueSize, cx
		mov	si, offset JP_printerName
	;
	; Copy in the null-terminated and -padded printer name to the signifi-
	; cant portion of the address.
	; 
		add	di, offset MBACA_opaque
		sub	cx, MAXIMUM_PRINTER_NAME_LENGTH	; cx <- JobParameters
							;  size
		push	cx			; save JP size
		mov	cx, ax
		rep	movsb			; copy in the name
		mov	cx, MAXIMUM_PRINTER_NAME_LENGTH
		sub	cx, ax			; cx <- # null bytes needed
		push	ax			; save printer name size
		clr	al
		rep	stosb			; null-pad the field
		pop	ax			; ax <- printer name size
	;
	; Copy in the entire JobParameters block
	; 
		pop	cx			; cx <- JobParameters size
		clr	si
		rep	movsb
	;
	; Opaque part complete. Copy in the user-readable part.
	; 
		mov_tr	cx, ax			; cx <- printer name size
		mov	si, offset JP_printerName
		rep	movsb
	;
	; Unlock the JobParameters block, please.
	; 
		mov	bx, dx
		call	MemUnlock
		mov	cx, dx			; return cx unchanged...
		.leave
		ret
MSACAdjustAddress endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSACMailboxAddressControlGetAddresses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the array of addresses for the message

CALLED BY:	MSG_MAILBOX_ADDRESS_CONTROL_GET_ADDRESSES
PASS:		*ds:si	= MailboxSpoolAddressControl object
		ds:di	= MailboxSpoolAddressControlInstance
		cxdx	= transData
RETURN:		if ok:
			*ds:ax	= ChunkArray of MBACAddress structures
		else
			ax	= 0
DESTROYED:	cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We return a single-element array (variable-sized elements,
		of course) with garbage in the first element, as we fill it in
		before registering the message

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSACMailboxAddressControlGetAddresses method dynamic MailboxSpoolAddressControlClass, 
				MSG_MAILBOX_ADDRESS_CONTROL_GET_ADDRESSES
		.enter
		clr	bx, cx, si, ax
		call	ChunkArrayCreate
SBCS <		mov	ax, size MBACAddress + 1			>
DBCS <		mov	ax, size MBACAddress + 2			>
		call	ChunkArrayAppend
	;
	; No opaque data, for now.
	; 
		mov	ds:[di].MBACA_opaqueSize, 0
	;
	; set user-readable part to null-terminated empty string, for now
	;
SBCS <		mov	ds:[di].MBACA_opaque, 0				>
DBCS <		mov	{wchar}ds:[di].MBACA_opaque, 0			>

     		mov_tr	ax, si
		.leave
		ret
MSACMailboxAddressControlGetAddresses endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSACGetPageRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Consult the MailboxSendControl to find the selected page
		range.

CALLED BY:	MSG_MSAC_GET_PAGE_RANGE
PASS:		*ds:si	= MailboxSpoolAddressControl object
		ds:di	= MailboxSpoolAddressControlInstance
RETURN:		cx	= first page
		dx	= last page
DESTROYED:	ax, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 2/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSACGetPageRange method dynamic MailboxSpoolAddressControlClass, MSG_MSAC_GET_PAGE_RANGE
		.enter
	;
	; Ask the send control (which must exist, we assume, since we insist
	; there be a transport hint for us to see, and there can't be one unless
	; OLMBH_output is a send control...)
	; 
		mov	bp, ds:[di].MSACI_trans
		movdw	bxsi, ds:[OLMBH_output]
		mov	ax, MSG_MAILBOX_SEND_CONTROL_GET_PAGE_RANGE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		ret
MSACGetPageRange endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSACGetObjectType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the MailboxObjectType for the current transaction.

CALLED BY:	MSG_MSAC_GET_OBJECT_TYPE
PASS:		*ds:si	= MailboxSpoolAddressControl object
		ds:di	= MailboxSpoolAddressControlInstance
RETURN:		ax	= MailboxObjectType from the transaction
		bp	= transaction handle
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 2/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSACGetObjectType method dynamic MailboxSpoolAddressControlClass, 
				MSG_MSAC_GET_OBJECT_TYPE
		.enter
		mov	bp, ds:[di].MSACI_trans
		mov	bx, ds:[OLMBH_output].handle
		call	ObjSwapLock
		Assert	chunk, bp, ds
		mov	di, ds:[bp]
		mov	ax, ds:[di].MSCT_objType
		call	ObjSwapUnlock
		.leave
		ret
MSACGetObjectType		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSACGetExtraTopSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This takes care of all cases except faxing; where a
		cover page is not relevent.  If the message makes
		it past the sub class to here, then we return zero,
		because that's how much top space you have on no
		cover page.

CALLED BY:	MSG_MSAC_GET_EXTRA_TOP_SPACE
PASS:		*ds:si	= MailboxSpoolAddressControlClass object
		ds:di	= MailboxSpoolAddressControlClass instance data
		ax	= message #
RETURN:		dx	= zero
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	5/ 4/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSACGetExtraTopSpace	method dynamic MailboxSpoolAddressControlClass, 
					MSG_MSAC_GET_EXTRA_TOP_SPACE
		clr	dx
		ret
MSACGetExtraTopSpace	endm



AddressCode	ends
