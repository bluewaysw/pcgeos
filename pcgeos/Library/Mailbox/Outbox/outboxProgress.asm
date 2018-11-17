COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Outbox
FILE:		outboxProgress.asm

AUTHOR:		Adam de Boor, May 13, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/13/94		Initial revision


DESCRIPTION:
	Implementation of the outbox progress box.
		

	$Id: outboxProgress.asm,v 1.1 97/04/05 01:21:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	MAILBOX_PERSISTENT_PROGRESS_BOXES

MailboxClassStructures	segment	resource
	OutboxProgressClass
MailboxClassStructures	ends

Outbox	segment	resource

OutboxDerefGen	proc near
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		ret
OutboxDerefGen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OPSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up a progress box, creating the moniker (based on the
		transport & medium), attaching the box to the mailbox
		application object, and bringing the box up on screen

CALLED BY:	MSG_OP_SETUP
PASS:		*ds:si	= OutboxProgress object
		ds:di	= OutboxProgressInstance
		ss:bp	= OPSetupArgs
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	OPI_transport, OPI_medium set
     		vis moniker has its \1 char replaced with the transport
			string

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OPSetup		method dynamic OutboxProgressClass, MSG_MPB_SETUP
if	_TRANSMIT_THREADS_KEYED_BY_MEDIUM
	;
	; Switch moniker to the template before it gets mangled. The thing
	; will update in a moment, anyway, so no fear about not updating
	; after tweaking the moniker chunk.
	;
		mov	ax, ds:[di].OPI_templateMoniker
			CheckHack <OutboxProgress_offset eq Gen_offset>
		xchg	ds:[di].GI_visMoniker, ax
		tst	ax
		jz	monikerDone
		call	LMemFree
monikerDone:
endif	; _TRANSMIT_THREADS_KEYED_BY_MEDIUM
	;
	; Copy the transport, option, and medium into our instance data.
	; We'll use it when getting the moniker string.
	; 
		movdw	ds:[di].OPI_transport, ss:[bp].OPSA_transport, ax
		mov	ax, ss:[bp].OPSA_transOption
		mov	ds:[di].OPI_transOption, ax
		movdw	ds:[di].OPI_medium, ss:[bp].OPSA_medium, ax
	;
	; Let our superclass handle the rest.
	;
		mov	ax, MSG_MPB_SETUP
		mov	di, offset OutboxProgressClass
		GOTO	ObjCallSuperNoLock
OPSetup		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OPMpbGetMonikerString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the transport string to put in our moniker.

CALLED BY:	MSG_MPB_GET_MONIKER_STRING
PASS:		*ds:si	= OutboxProgress object
		ds:di	= OutboxProgressInstance
RETURN:		*ds:ax	= string to use in place of \1 in the moniker
DESTROYED:	cx, dx, bp allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OPMpbGetMonikerString method dynamic OutboxProgressClass, 
					MSG_MPB_GET_MONIKER_STRING
		.enter
		movdw	axbx, ds:[di].OPI_transport
		mov	si, ds:[di].OPI_transOption
		movdw	cxdx, ds:[di].OPI_medium
		call	MediaGetTransportString
EC <		ERROR_C	PROGRESS_SETUP_FOR_INVALID_TRANSPORT_MEDIUM_COMBO>
		.leave
		ret
OPMpbGetMonikerString endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OPSetMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the message & address(es) currently being transmitted
		to.

CALLED BY:	MSG_OP_SET_MESSAGE
PASS:		*ds:si	= OutboxProgress object
		cxdx	= MailboxMessage (reference must be removed when
			  we're done with it)
		bp	= TalID of addresses being transmitted to
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	moniker of OutProgMessage object is freed, replaced by a
		newly-constructed one.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OPSetMessage	method dynamic OutboxProgressClass, MSG_OP_SET_MESSAGE
		.enter
		mov	ax, MSG_MG_SET_MESSAGE 	; ax <- don't show dups unless
						;  marked, don't include
						;  transport
		call	OPSetMessageCommon
		.leave
		ret
OPSetMessage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OPSetMessageCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the moniker for OutProgMessage to one generated from
		the passed message

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= OutboxProgress object
		cxdx	= MailboxMessage
		bp	= TalID
		ax	= message to send to glyph
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, bp
SIDE EFFECTS:	block & chunks may move
     		percentage gauge set to 0

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OPSetMessageCommon proc	near
		class	OutboxProgressClass
		push	si, ax
		mov	si, offset OutProgMessage
		call	ObjCallInstanceNoLock
		pop	si, ax
	;
	; Zero the percentage gauge, on the assumption this is the beginning
	; of some operation that may provide percentage feedback...
	; 
		DerefDI	MailboxProgressBox
		mov	si, ds:[di].MPBI_progressGauge
		clr	cx			; assume not a new mode, so
						;  leave indicators there
		cmp	ax, ds:[di].OPI_lastMode
		je	doReset
		mov	cx, TRUE		; nuke everything, please
		mov	ds:[di].OPI_lastMode, ax
doReset:
		mov	ax, MSG_MPG_RESET
		call	ObjCallInstanceNoLock
		ret
OPSetMessageCommon endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OPSetPreparingMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the user know the passed message is being prepared

CALLED BY:	MSG_OP_SET_PREPARING_MESSAGE
PASS:		cxdx	= MailboxMessage (reference must be removed when object
			  is done with it)
		bp	= index of address being prepared
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OPSetPreparingMessage method dynamic OutboxProgressClass, 
		      		MSG_OP_SET_PREPARING_MESSAGE
		.enter
		mov	ax, MSG_MG_SET_MESSAGE_PREPARING
		ornf	bp, mask TID_ADDR_INDEX	; convert to a true TalID
		call	OPSetMessageCommon
		.leave
		ret
OPSetPreparingMessage endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OPSetConnecting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the user know we're attempting to connect.

CALLED BY:	MSG_OP_SET_CONNECTING
PASS:		cxdx	= MailboxMessage
		bp	= index of address being connected to
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OPSetConnecting method dynamic OutboxProgressClass, MSG_OP_SET_CONNECTING
		.enter
		mov	ax, MSG_MG_SET_MESSAGE_CONNECTING
		ornf	bp, mask TID_ADDR_INDEX	; convert to a true TalID
		call	OPSetMessageCommon
		.leave
		ret
OPSetConnecting endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OPSetError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the user of the error that occurred during
		transmission/connect.

CALLED BY:	MSG_OP_SET_ERROR
PASS:		cx	= outbox reason token
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	No need to free the string that OutboxGetReason returns, since the
	whole dialog block will be freed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/26/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OPSetError	method dynamic OutboxProgressClass, 
					MSG_OP_SET_ERROR
	uses	cx, dx, bp
	.enter

	;
	; Bring ourselves up on screen, in case the user has hidden us.
	;
	push	cx			; save outbox reason token
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjCallInstanceNoLock

	;
	; Get the reason string.
	;
	pop	ax			; ax = reason toke
	call	OutboxGetReason		; *ds:ax = string

	;
	; Copy the string onto the stack (because unlike
	; UserStandardDialogOptr, there's no optr version of
	; MSG_GEN_APPLICATION_DO_STANDARD_DIALOG, and chunks in this block
	; may move since we're on the same thread.)
	;
	segmov	es, ds
	mov_tr	di, ax
	mov	di, ds:[di]		; es:di = string
	call	LocalStringSize		; cx = size w/o null
	inc	cx			; cx = size w/ null
DBCS <	inc	cx							>

	mov	bx, sp			; bx = old stack bottom
	sub	sp, cx			; sp might be odd, but who cares
					;  besides swat.
	mov	si, di			; ds:si = string src
	movdw	esdi, sssp		; es:di = string dest
	rep	movsb

	;
	; Put up a dialog.
	;
	mov	dx, size GenAppDoDialogParams
	mov	ax, sp			; ss:ax = string
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GADDP_dialog.SDP_customFlags, \
		CustomDialogBoxFlags <1, CDT_ERROR, GIT_NOTIFICATION, 0>
	movdw	ss:[bp].GADDP_dialog.SDP_customString, ssax
	clr	ax			; just for using czr
	czr	ax, ss:[bp].GADDP_dialog.SDP_stringArg1.segment
	czr	ax, ss:[bp].GADDP_dialog.SDP_stringArg2.segment
	czr	ax, ss:[bp].GADDP_dialog.SDP_customTriggers.segment
	czr	ax, ss:[bp].GADDP_dialog.SDP_helpContext.segment
	czr	ax, ss:[bp].GADDP_finishOD.handle	; don't want ACK

	mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
	mov	di, mask MF_STACK	; no need to fixup
	call	UtilCallMailboxApp	; make it a call jsut to be safe, so
					;  we can pop the string right away.

	mov	sp, bx			; restore stack

	.leave
	ret
OPSetError	endm

Outbox		ends

endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES
